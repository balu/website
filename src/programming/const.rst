The :code:`const` type qualifier is used (in `C`, `C++`, `D`,
`rust` among others) to declare that a piece of data will not be
modified through the binding being declared. For pointers, the
pointer and the data pointed to can be declared :code:`const`
independently.

::

   int x = 42;
   int y = 21;
   const int* p = &x;
   *p = 5; // error
   p = &y; // Ok
   int *const q = &x;
   *q = 5; // Ok
   q = &y; // error
   const int * const r = &x;
   *r = 5; // error
   r = &y; // error

Pointers to :code:`const` are commonly used as arguments to
functions that promise that the data will not be modified through
that pointer. This helps the caller of a function to infer what
arguments will not be modified by the function. Consider the
:code:`strchr` function in `C` standard library that takes a
null-terminated string and a character as argument and returns a
pointer to the first matching character in the string. It is
declared as follows:

::

   char *strchr(const char *str, int c);

The argument is :code:`const char *` because this function does
not modify the input string. On the other hand, the return value
is :code:`char *` because the input string could actually be
mutable and the caller of the function may want to mutate the
string through the returned value.

::

   char a[] = "Hello world";
   char *p = strchr(a, 'w');
   *p = 'W';

This magic is achieved by casting away the :code:`const` in the
function. The problem with this approach is that the input string
could actually be :code:`const` in which case the return value
should not be mutable.

The `C++` standard library solves this problem by declaring two
overloads for this function.

::

   char* strchr(char* str, int c);
   const char* strchr(const char* str, int c);

This solution has two problems: First, overloads are a mechanism
that should only be used when you want to provide different
implementations based on the types of arguments. Here, the
implementation of both functions are the same. Second,
implementing overloading requires name mangling making the
function un-callable from `C`.

Using templates, we can combine the two equivalent function
definitions into a single definition.

::

   template <class T>
   // Hire a template guru to ensure that
   // T = char or T = const char
   T* strchr(T* str, int c) { }

This solution also does not solve the issue of name mangling.
Templates are also too powerful for this purpose as they are
usually used to map a single function definition in source code
into multiple functions in the object file.

This problem of distinguishing between :code:`const` and
:code:`mut` also arises in :code:`rust`. For example, here are
two methods of :code:`slice`.

::

   pub fn split_at(&self, mid: usize) -> (&[T], &[T])
   pub fn split_at_mut(&mut self, mid: usize) -> (&mut [T], &mut [T])

In fact, the :code:`slice` API is filled with :code:`f` and
:code:`f_mut` for various values of :code:`f`.

The `D` programming language provides a solution to this problem
by providing the :code:`inout` keyword that allows functions to
be generic over :code:`const` qualifiers.

::

   inout(char)* strchr(inout(char)* str, int c) { return str; }

This function can be compiled without name mangling and be called
from `C`. The exported declaration can be the same as the
original declaration for :code:`strchr` in `C`.

If there are multiple :code:`inout` in the parameters, the
:code:`inout` is set to the most restrictive of all the
corresponding qualifiers in arguments.

The `D` compiler does not properly handle :code:`inout` appearing
in higher-order functions. A more fundamental problem is that the
:code:`inout` is a single variable that gets assigned to a
concrete :code:`const` or :code:`mutable` value upon
instantiation. The following valid example does not compile.

::

   inout(int)* foo(
       inout(int)* a,
       inout(int)* function (inout(int)*) b)
   {
       return b(a);
   }

   int global = 0;

   int* f(const(int)* x) { return &global; }
   

   const int w = 0;
   int *x = foo(&w, &f); // error
   *x = 5;

Here, the :code:`inout` in return type of :code:`foo` must match
the :code:`inout` in the return type of parameter :code:`b` and
the :code:`inout` in parameter :code:`a` must match the
:code:`inout` in parameter of :code:`b`.

:code:`const` generic functions
===============================

Ideally, one should be able to specify multiple :code:`inout`
variables and the relations between them in the function
declaration. An illuminating example is the following function
used for iterating over intrusive linked lists:

::

   void for_each(
       list_head* lh,
       void* (*entry)(list_head *),
       void (*process)(void *)
   );

The :code:`entry` function does the casting magic that is
required to convert a :code:`list_head*` into a pointer to the
actual structure and the :code:`process` function processes a
single structure in the list. As written, all data is assumed to
be mutable. This is too strict. The only requirements are that if
the :code:`process` function requires a pointer to mutable as
input, then the :code:`entry` function should produce one and if
the :code:`entry` function requires a pointer to mutable then
:code:`lh` should be one.

For simplicity, let us assume that the only type qualifiers are
:code:`const` and :code:`mut` and they are totally ordered by the
relation :code:`:` given by :code:`const : mut`. The above
function can be declared much more precisely using the following
declaration. The syntax is a mix of `rust` and `D`.

::

   fn for_each!(
     inout!3 : inout!2
   , inout!1 : inout!0
   )
   (
     lh : *inout!0 list_head
   , entry : *fn(*inout!1 list_head) -> *inout!2 void
   , process : *fn(*inout!3 void) -> void
   ) -> void;

Here, the :code:`!()` block specifies constraints on generic
parameters. The speicification :code:`inout!3 : inout!2` means
that :code:`inout!2` is :code:`const` implies that so is
:code:`inout!3`. Indeed, the code generated for the function
remains the same irrespective of the actual values of
:code:`inout` variables. Therefore, this function can be exported
to `C` as there is no need for name mangling. The following
declaration should be used in `C`.

::

   void for_each(
       const list_head* lh,
       const void *(*entry)(list_head *),
       void (*process)(void *)
   );

i.e, an :code:`inout!i` is replaced with :code:`const` in
contravariant positions and with :code:`mut` in covariant
positions.

:code:`const` generic datatypes
===============================

One of the central concepts in `D` is that of ranges. A range is
a generalization of the slice type :code:`T[]` which is a pair
:code:`(T*, int)`. One can iterate over the elements of a range
by making the pointer point to the next element and decrementing
the length. A very common datatype in `D` is a slice that points
to :code:`const` elements providing a read-only view of a range
of elements.

A problem commonly encountered in `D` while working with ranges
is that there is no way for the compiler to obtain a tail-const
version of a user-defined range. For slices, which are the most
common range types, the compiler knows that it can obtain the
tail-const version of :code:`const(T[])` by transforming it to
:code:`const(T)[]`. But, for a user-defined range, the compiler
has no way to obtain this type.

The problem here is that a range (like a pointer) is generic over
two things: the type of the elements and their mutability. Slices
allow the programmer to specify the mutability of elements
separately in its datatype specification. But, the `D`
programming language considers a range as a generic type with
only the type parameter. One can solve this problem by allowing
generic :code:`inout` parameters in datatype definitions. For
example, here is the definition of slice.

::

   struct slice!(T)
   {
       inout!1(T)* ptr;
       int len;
   }

   struct range!(T)
   {
       // Some declarations that use inout!1
   }


In the above definitions, we assume that :code:`inout!0` refers
to the qualifier on the actual :code:`struct`. By default, all
members of a :code:`struct` can be recursively qualified
:code:`inout!0` giving us transitive :code:`const` as the
default.

To make this work, the use of :code:`inout!i` variables at places
other than qualifiers (For example, it should not be possible to
test its value in a :code:`static if`) has to be disallowed. The
compiler can decide whether a :code:`const range!(T, const)` is
copy-able to :code:`range!(T, const)`. The compiler can also
infer the values of :code:`inout` variables by using rules that
are similar to the inference rules for lifetime variables in
`rust`.

For full generality, we can allow the use of any number of
:code:`inout!i` variables and specification of constraints on
them inside the :code:`!()` block as was the case for functions.

See the reddit `discussion <https://redd.it/8m0nor>`_ for this
article.
