Memory Safety
=============

A memory-safe program should not

  - Have buffer overflows.
  - Dereference a null pointer.
  - Dereference a dangling pointer.

A program is memory-safe if in any possible execution of the
program , all expressions `e` in the program that refer to an
object of type `T` resolve to an object of type `T` that has been
initialized and not yet deallocated.

There are different ways to guarantee memory safety for all
programs. One is to restrict the programming language and
disallow pointers. But, this forces most programs to make
unnecessary copies of data. Another strategy, called garbage
collection, embeds a garbage collector with every program. The
garbage collector periodically looks for objects in memory that
cannot be accessed from the program and reclaims this memory. The
drawbacks of this are the overhead of garbage collection and that
deallocation of memory is no longer under the control of the
programmer.

Lifetimes
=========

The lifetime of an object in an execution of the program is the
span of time from when memory for the object is initialized to
when the memory for the object is deallocated.

::
		
    void foo(bool b)
    {
        int *ip = new int;
	if (b) {
	    delete ip;
	    // (1)
	} else {
	    *ip = 0;
	}
	delete ip;
	// (2)
    }

In any execution of a program calling `foo`, the lifetime of the
`int` allocated on the heap starts immediately after `foo` is
called and ends at the point marked (1) if `b` is true and at the
point marked (2) otherwise. This example shows that the lifetime
of an object is a dynamic property.

If a garbage collection strategy is being used, then the
programmer cannot explicitly call `delete` to release memory.
Instead, a garbage collector stops the program during execution
and checks whether the lifetime of all objects currently in
memory have expired or not. The garbage collector considers the
lifetime of an object to be expired if there are no more active
references to it. This is a conservative estimate because if
there are no references to the object, then it cannot be accessed
anymore.

::

    void foo()
    {
        int* i = new int;
        int* j = new int;
    	*i = 0;
	*j = 0;
    	bar(i, j);
	// (1)
    	baz(i);
    }

In the above program, the lifetime of the `int` pointed to by the
variable `j` can be considered over at (1). But, if the garbage
collector stops the program just before the call to `baz`, then
it has to consider that object to be alive because the reference
`j` is still active. On the other hand, if garbage collection is
not being used, then the programmer can call `delete` at (1) to
relase memory before calling `baz`.

Lexical Lifetimes in Rust
=========================

In the rust programming language, lifetimes are compile-time
values that are used to ensure memory safety. To make use of
lifetimes, rust provides an enhanced pointer type called a
reference. A reference is a non-nullable pointer type that is
parameterized by two things -- a lifetime and the type of the
referrent. On the contrary, a raw pointer is parameterized only
by the type of the referrent as in other languages.

::
		
    template <lifetime a, typename T> class Ref { ... };

In rust, the reference type gets special syntax. `Ref<'a, T>` is
written as `&'a T`.

Lifetime Inference
==================

Rust lifetimes are associated with lexical scopes in the source
code of the program. A programmer cannot explicitly pass the
lifetime argument while instantiating references. Instead, the
compiler automatically infers the lifetime parameter in a
conservative fashion. We will use `'r1, 'r2` etc. to denote
lifetimes in a program and use scopes delimited using curly
braces to specify their extent. Note that rust does not allow the
programmer to directly specify lifetimes in this fashion.

::

    struct Foo {}
    fn foo() {
        'r1 {
	    let x = Foo{};
	    'r2 {
	        let y = &x; // (1)
	    }
	    let z = x; // (2)
	}
    }

An assignment from `&'a  T` to `&'b  T` is valid if and only if
the lifetime `'a` is at least as large as the lifetime `'b`. In
(1), the expression `&x` has type `&'r1  Foo` and `y` is
automatically inferred to have type `&'r2  Foo`. Since `'r1 >=
'r2`, this assigment is valid. In (2), the object is moved out of
`x`. This is valid because `x` is the only variable referring to
that object.

::

    struct Foo {}
    fn foo() {
        let x = Foo{};
	let y = &x;
	let z = x;
    }

The above code will not compile because the reference `y` is
still active when the object is moved out of `x`.

Let us look an example of lifetimes in action when passing
references in and out of functions.

::

    struct Foo {}

    fn foo<'a>(x: &'a Foo) -> &'a Foo {
        return x;
    }

    fn main() {
        'r1 {
            let x = Foo{};
	    'r2 {
                let y = foo(&x); // (1)
                let z = x; // (2)
	    }
	}
    }

Here the rust compiler will disallow the move in (2). We can see
that `y` is referring to the same object as `x` by looking at the
body of `foo`. Let us look at how rust proves this. The signature
tells that `foo` is a templated function that accepts a lifetime
value as a template parameter. The variable `'a` is a
compile-time variable of type `lifetime`. When `foo` is called,
the compiler automatically infers the value for `'a` to be the
smallest lifetime possible. The expression `&x` has type `&'r1
Foo` implying `'r1 >= 'a` because the function call is assigning
a `&'r1 Foo` to `&'a Foo`. In (1), the assignment is from a value
of type `&'a Foo` to a variable of type `&'r2 Foo` which is valid
only when `'a >= 'r2`. Therefore, `'r2 <= 'a <= 'r1` and the
smallest lifetime that can be assigned to `'a` is `'r2`. The
expression `&x` has type `&'r2 Foo` indicating that `x` is
borrowed for the scope `'r2`. This prevents the move in (2).
    
::

    struct Foo {}
    
    static z : Foo = Foo{};
    
    fn foo<'a>(x: &'a Foo) -> &'a Foo {
        return &z;
    }
    
    fn main() {
        'r1 {
            let y;
            'r2 {
                let x = Foo{};
                y = foo(&x);
            }
	}
    }
    
The above code will fail to compile even though it is memory safe
because rust cannot assign a valid value to `'a`. The expression
`&x` has type `&'r2  Foo` implying `'r2 >= 'a`. But, the variable
`y` has type `&'r1  Foo` implying `'a >= 'r1`. These two
constraints cannot be satisfied simultaneosly and the program
fails to compile.

We can make the program compile by changing the return type of
`foo` to `&'static Foo`.

::

    struct Foo {}
    
    static z : Foo = Foo{};
    
    fn foo<'a>(x: &'a Foo) -> &'static Foo {
        return &z;
    }
    
    fn main() {
        let y;
        {
            let x = Foo{};
            y = foo(&x);
            let w = x; // (1)
        }
    }
    
The lifetime `'static` is a special lifetime that stands for the
entirety of program execution and `'static >= 'a` for any
lifetime `'a`. Once this change is made there is only one
constraint, which is `'a <= 'r2`. Therefore, the compiler is free
to choose a lifetime that is as small as possible. Here, the
compiler will choose `'a = 'r3` where `'r3` is a lifetime that
spans only the function call expression. Therefore, the move in
(1) remains valid.

    
::

    struct Foo {}
    
    static z : Foo = Foo{};
    
    fn foo<'a>(x: &'a Foo) -> &'static Foo {
        return &x; // (1)
    }
    
    fn main() {
        'r1 {
            let y;
            'r2 {
                let x = Foo{};
                y = foo(&x);
            }
	}
    }

The above program will fail to compile because the return
statement in (1) is trying to convert a `&'a  Foo` to `&'static
Foo` which is only possible when `'a = 'static`.

The rules remain the same when your function takes multiple
references as input. As an exercise, try and figure out the
values of lifetimes `'a` and `'b` in both calls to `foo` and
explain why the second call fails to compile.

::
		
    struct Foo {}
    
    fn foo<'a, 'b>(x : &'a Foo, y : &'b Foo) -> &'a Foo {
        return x;
    }
    
    fn main() {
        {
            let x = Foo{};
            let mut z;
            {
                let y = Foo{};
                z = foo(&x, &y);
            }
            {
                let y = Foo{};
                z = foo(&y, &x);
            }
        }
    }
    

Datatypes Parameterized by Lifetimes
====================================

Let us look at a rust datatype that contains a reference. Here,
rust enforces the rule that an object with lifetime `'r1` can
contain a reference of lifetime `'r2` if and only if `'r2 >=
'r1`. This ensures that all references contained within the
object are valid until the object is deallocated.

::
		
    struct Foo<'c> { x : &'c u64 }
    
    fn foo<'a, 'b>(x : &'a Foo<'a>, y : &'b Foo<'b>)
        -> &'a Foo<'a>
    {
        return x;
    }
    
    fn main() {
        let i : u64 = 3;
        let x;
        let z;
        let w;
        'r2 {
            let j : u64 = 4;
            x = Foo {x : &i}; // (1)
            let y = Foo {x : &j}; // (2)
            z = foo(&x, &y); // (3)
            w = Foo {x : &j}; // (4)
        }
    }
    
Line (4) will fail to compile because rust infers that `'c <=
'r2` and the lifetime of `w` is larger than `'r2`. Lines (1) and
(2) are fine since `i` and `j` live longer than `x` and `y`
respectively. In line (3), rust infers `'a <= lt(x)` from the
argument and `lt(z) <= 'a` from the assignment of the return
value implying `'a = lt(z)` and `'b` is set to the lifetime
limited to the function call expression according to rules
previously discussed. The rules for references apply recursively
to `Foo` too. i.e., a `Foo<'a>` can be assigned to `Foo<'b>` only
when `'a >= 'b`.

Mutable References
==================

Rust has a second non-nullable reference type that tracks
lifetimes. An `&'a mut T`, called a mutable reference to an
object of type `T` with lifetime `'a`. An object can only have
atmost one mutable reference referring to it at any point of
time.

::

    struct Foo { a : u32 }
    
    fn main() {
        let mut x = Foo{ a : 0 };
        {
            let y = &mut x;
            let w = &x; // (1)
        }
        let z = &x; // (2)
	assert!(x.a == 0 && z.a == 0);
    }

Note that `x` is a mutable object. Mutable references can only
point to mutable objects. Line (1) fails to compile because `y`
is a mutable reference to `x` and this prevents using any other
reference (including `x`) to the object while `y` is active. In
line (2), the mutable reference `y` to `x` has gone away making
the code valid. Note that after (2), the `Foo` object cannot be
modified through `x` because it is borrowed by `z`. However, one
can read the object using `x` or through `z`. i.e., the mutable
object is downgraded to an immutable one while `z` is active.

The lifetime constraints are the same as that for immutable
references. An object with type `&'a mut T` can be assigned to
`&'b mut T` if and only if `'a >= 'b`.

References to Internal Objects
==============================

Things get complicated when referring to parts of aggregate
objects. Rust can figure out that references are disjoint when
they refer to distinct struct members (1). But disallows mutable
references to distinct array elements (2) because it is not
verifiable in general.

::

    struct Foo { x : u64, y : u64 }
    
    fn main() {
        let mut x = Foo{x:0, y:1};
        let y = &mut x.x;
        let z = &mut x.y; // (1)
        
        let mut v = vec![0, 1, 2];
        let u = &mut v[1];
        let w = &mut v[2]; // (2)
    }

These restrictions impose some constraints when designing
interfaces.

::

    struct Foo { x : u64, y : u64 }
    
    fn foo<'a>(s : &'a Foo) -> &'a u64 {
        return &s.x;
    }
    
    fn main() {
        let mut x = Foo{x:0, y:1};
        let y = foo(&x);
        let z = &mut x.y; // (1)
    }

Line (1) fails to compile even though the code is safe. To work
around this, functions that accept references to object should
only take references to subobjects that are necessary.

For taking references to disjoint parts of a vector, rust
provides `split` and `split_at_mut` functions as part of the
interface to a vector.

::

    fn main() {
        let mut x = vec![0, 1, 2, 3, 4];
        let (y, z) = x.split_at_mut(2);
        y[0] = 1;
        z[0] = 3;
        print!("{:?} {:?}", y, z); // [1, 1] [3, 3, 4]
     }

.. topic:: Summary

   - `&'a T` can be assigned to `&'b T` only when `'a >= 'b`.
   - The lifetime `'static >= 'a` for all lifetimes `'a`.
   - When there is an `&mut` referring an object, there can be no
     other references to it.
   - The values of lifetime parameters in function and struct
     templates are always inferred by the compiler. The inferred
     lifetime value is the smallest possible lifetime that
     satisfies all constraints imposed on the lifetime variable
     by the context.
   - An object containing references must have a lifetime that is
     larger than all the lifetimes of references contained in it.

See the reddit `discussion <https://redd.it/8818cc>`_ for this
article.
