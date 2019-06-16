The :code:`cweet` programming language aims to be a safer, more
expressive alternative to the :code:`C` programming language. It
has:

    - Compound expressions to write more expressive code.
    - Stricter typing rules to catch errors at compile time.
    - Sum types to describe data more accurately.
    - Pattern matching to destructure data declaratively.
    - Concise error handling primitives.
    - Packages to enable writing modular code.

Statement Expressions
=====================

Statement expressions allow us to rewrite a sequence of
statements computing a value as an expression.

::

   // if-else as expressions.
   var max = if (a > b) a else b;
   
   // A block of code as an expression.
   var sum: [100][100]int = do {
       var r = undefined;
       loop for (var i; 0 ..^ r.len[0]) {
           loop for (var j; 0 ..^ r.len[1]) {
               r[i][j] = i+j;
           }
       }
       r; // value of the block.
   };

Lambda Syntax
=============

Lambda syntax allows writing short-lived functions without giving
them a name. Lambda functions can access their environment if
they can be inlined into the environment.

::

   alias string_proc = :&fn(: string): void;

   fn with_input_string(inline f: string_proc): void
   {
       var s = readline();
       (*f)(s);
       free(s);
   }

   fn main(): int
   {
       with_input_string(\s => do {
           import io (print, println);
           print("Hello ");
           println(s);
       });
       return 0;
   }

Type Inference
==============

Types of function parameters and return value have to be
explicit. Types of other values are inferred.

::

   fn foo(): int
   {
       var y = undefined;
       with (
           var primes = [2, 3, 5, 7, 11];
           y = 0;
       ) loop for (var p; primes[..]) {
           y += p;
       }
       return y;
   }

Pattern Matching
================

:code:`choice` types provide tagged unions in the language
ensuring that the programmer does not incorrectly access invalid
fields.  The :code:`match` construct can be used to destructure
objects by pattern matching.

::

   // Tagged discriminative unions.
   choice Netstatus {
       Connected{ip: [4]byte},
       Disconnected
   };

   // import data constructors.
   using type Netstatus;
   
   // match expression.
   var desc = match (status) {
       Connected{...} => "connected",
       Disconnected   => "disconnected",
   };

Scope Guards
============

Scope guards allow code that deallocates a resource to be close
to code that allocates the resource and ensures proper cleanup.

::

   fn copy(from, to: string): void
   {
       var f1 = open(from, "r");
       scope (exit) { close(f1); }
       var f2 = open(to, "w");
       scope (exit) { close(f2); }
       with (
           var buf: [1024]char = undefined;
           var n = undefined;
       ) loop while (
           do {
               n = read(f1, buf[..]);
               n > 0;
           }
       ) {
           write(f2, buf[..^n]);
       }
   }


Error Handling
==============

An expression that has type :code:`T|Error` (:code:`T` or
:code:`Error`) may produce a value of type :code:`T` or cause an
error.

::

   extern fn sqrt(a: double): double|Error;

   fn len(v: [2]double): double
   {
       return sqrt(
           v[0]*v[0] +
           v[1]*v[1]
       )!; // Ignore error.
   }

   fn maxsqrt(a, b: double): double|Error
   {
       // Propagate error.
       var aa = sqrt(a)^;
       var bb = sqrt(b)^;
       return if (aa > bb) aa else bb;
   }

   fn maxsqrt1(a, b: double): double
   {
       // Handle errors.
       try {
           var aa = sqrt(a)^;
           var bb = sqrt(b)^;
           return if (aa > bb) aa else bb;
       } else {
           panic("sqrt of a negative number.");
       }
   }

Packages
========

Packages facilitate modularity of code and separate compilation.
A package interface can be optionally specified which ensures
that clients can only use functionality advertised by the
interface. Packages can be organized into a hierarchy using
namespaces.

::

    // The namespace file.
    namespace foo;
    package type BAR;
    package bar: BAR;

    // The package type file specifies an interface.
    package type foo.BAR;
    type t; // An opaque type.
    fn baz(): *t;
    
    // Now the implementation.
    package foo.bar;
    // t is opaque and x is inaccessible.
    alias t = :int;
    var x: int = 0;
    fn baz(): *int {
        return &x;
    }
    
    // Using the package.
    package client;
    
    import foo.bar;
    
    fn client() {
        assert(baz() == baz());
    }

Learn More
==========

    * A learn x in y minutes style `tutorial <learncweet.html>`_.
    * The full `documentation <doc.html>`_.
