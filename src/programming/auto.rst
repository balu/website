The Problem
===========

From C++11, the `auto` keyword can be used for automatic type
deduction while declaring variables. For example:

::

  auto i = 25; // i is an int.
  std::vector<int> v;
  auto b = v.cbegin();
  // b is __gnu_cxx::__normal_iterator<...>

As you can see from the type of `b`, `auto` is not just for
mere convenience, it is a necessary feature for writing portable
programs.

Another advantage of `auto` is that it disables implicit
conversions that could happen when writing types explicitly. For
example:
   
::

   long long i = 0xFFFFFFFF; // A very large number.
   ...
   int j = i; // oops. becomes -1.

One of the alleged problems that arise with the pervasive use of
`auto` (called the Almost Always Auto style) in large codebases
is that the documentation provided by writing out types
explicitly is no longer present, which makes reading and
understanding code difficult. Ideally, we would like a feature
that preserves types like the `auto` keyword *and* allow us to
specify the type that we expect the variable to be like.

A Solution
==========

It should be possible to specify types when declaring variables
without forcing conversions. For example, a programmer should be
able to write:
   
::

   long long i = 0xFFFFFFFF;
   ...
   expect<int>::e j = i;
   // long long is convertible to int. 
   // Make j's type long long.

A definition for `expect` could be as follows:

::
  
    template<class T> struct expect {
      template<class U> struct e {
          static_assert(std::is_convertible<U, T>::value);
          U data;
          template<int = 0> e(U d) : data(d) {}
          operator U() { return data; }
	  ...

If a variable is declared and initialized as `expect<T>::e y =
expr;`, then it will compile only if the type of `expr` is
convertible to `T`. But, no actual conversion to `T` is
performed. The type of `y` is almost the same as type of `expr`
(close to what `auto` does). We overload operators for
`expect<T>::e<U>` depending on the operators implemented by `U`
as follows:
  
::
    
    e& operator++()
    {
        return pre_increment<U>();
    }
    private:
        template<class V>
        std::enable_if_t<has_pre_increment_v<V>, e>&
        pre_increment()
        {
            ++data_;
            return *this;
        }


Full source code is given in the appendix.

A case for deduction in alias templates?
========================================

In this section, we describe a hypothetical feature that would
make the above solution cleaner. The feature is template
parameter deduction for alias templates. With such a feature, we
could have simply wrote something like the following for defining
`expect<T>::e`. This should behave exactly like `auto` except for
the additional compatibility check with `T`.

::

   template<class T> struct expect {
       template<class U>
       using e = std::enable_if_t<
           std::is_convertible<U, T>,
           U
       >;
   };

Infact, using template parameter deduction for alias templates,
we can implement the `auto` feature as follows:
   
::

   template<class T> using auto = T;
   auto x = 5; // T = int
   auto msg = "Hello"; // T = const char*

This can be used to check conformance of types to interfaces as
follows:

::

  template<class T> using iterator = std::enable_if_t<
      is_iterator_v<T>,
      T
  >;
  std::vector<int> v;
  iterator p = v.cbegin(); // Ok. is_iterator_v<T> is true.


We could also supply deduction guides as follows:

::

  template<class I> using range = std::pair<I, I>;
  // explicit deduction guide. (1)
  template<class I> range(I, I) -> range<
      std::enable_if_t<is_iterator_v<I>, I>
  >;
  // The following deduction guide (2) disables
  // template<class T> range(T) -> range<T>;
  // which is obviously wrong.
  // is_range_v checks whether 
  // R is a std::pair of iterators (i.e., a range).
  template<class R> range(R) -> range<
      std::enable_if_t<
          is_range_v<R>,
          R::first_type
      >
  >;
  std::vector<int> v;
  range r{v.cbegin(), v.cend()}; // Use (1)
  range s{r}; // Use (2)

See the reddit `discussion <https://redd.it/6vdxx0>`_ for this
article.

Appendix: Full source code
==========================

This is just a proof of concept implementation. The check
`is_convertible` is not right in this context. We should really
check whether all operations supported by the expected type `T`
is supported by the actual type `U`.

::

  #include <iostream>
  #include <type_traits>
  #include <string>
  
  template< class, class T = std::void_t<> >
  struct has_pre_increment : std::false_type { };

  template< class T >
  struct has_pre_increment<
      T,
      std::void_t<
          decltype( ++std::declval<T&>() )
      >
  > : std::true_type { };

  template<class T>
  constexpr bool has_pre_increment_v =
      has_pre_increment<T>::value;

  template<class T> struct expect {
      template<class U> struct e {
          static_assert(std::is_convertible<U, T>::value);
          U data_;
          template<int = 0> e(U d) : data_(d) {}
          operator U() { return data_; }

          e& operator++()
          {
              return pre_increment<U>();
          }
      private:
          template<class V>
          std::enable_if_t<has_pre_increment_v<V>, e>&
          pre_increment()
          {
              ++data_;
              return *this;
          }
      };
  };

  void foo(int x)
  {
      std::cout << "foo(int)" << x << "\n";
  }

  void foo(long long x)
  {
      std::cout << "foo(long) " << x << "\n";
  }

  void bar(const std::string& x)
  {
      std::cout << "bar(string) " << x << "\n";
  }

  void bar(const char* x)
  {
      std::cout << "bar(const char*) " << x << "\n";
  }

  int main()
  {
      long long x = 0xFFFFFFFF;
      expect<int>::e y = x;
      ++y;
      foo(y);
      y = 42;
      foo(y);

      std::string msg = "Hello";
      expect<const char*>::e m = msg.data();
      bar(msg);
      ++m;
      bar(m);

      expect<std::string>::e m1 = msg;
      // ++m1; // compilation error. no pre-increment.
  }

