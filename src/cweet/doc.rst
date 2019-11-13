This page is the official documentation for the cweet programming
language.

Lexical
=======

This section describes the lexical elements.

Comments
--------

Comments are ignored by the compiler.

::

   // Only single-line comments are supported.


Integer Literals
----------------

The prefixes ``0x``, ``0X`` (hex), ``0b``, ``0B``
(binary), ``0c``, ``0C`` (octal) are recognized. The
``_`` character may be used as a separator.

An integer literal can have an integral or floating point type.

::

   0
   123
   100_000
   0xabcd
   0c777
   0b00100011

Floating Point Literals
-----------------------

The letters ``p`` and ``P`` may be used for scientific
notation.

Decimal, hexadecimal, octal, or binary notation may be used.

A floating point literal is inferred to have one of the floating
point types.

::

   0.0
   1p6
   1p-6
   0xde.ed
   0b1.11

Character Literals
------------------

A character literal has type ``char`` and is exactly one
byte.

::

   'a'
   '\n' // newline. All C escapes are supported.
   '\xff' // Hex.
   '\c377' // Octal.
   '\B11111111' // Binary.


String Literals
---------------

A null byte is appended automatically to a string literal. String
literals are represented by a ``[]char`` type where the
length excludes the terminating null byte.

::

   "hello"
   "hello\n\0" // Two null characters at end.
   #{A raw string}#
   ##{Another raw string}##
   #####{Upto 5 hash characters can be used as delimiters.}#####
   #format{
       In a format string, everything upto the first vertical
       bar is ignored. At least one vertical bar should be
       present.
       |first

       Thereafter, after each newline, everything upto vertical
       bar is ignored.

       |second
   (3) |third

       To end the string, put a closing brace as the first
       non-whitespace character on a newline.

       These strings are used for inline assembly etc.
   }
   // The above string is the same as:
   "first\nsecond\nthird\n"
   // MMIX hello world.
   #format{
        Set the address of the program
        initially to 0x100.
        |        LOC    #100

        Put the address of the string
        into register 255.
        |Main    GETA   $255,string

        Write the string pointed to by
        register 255 to the standard
        output file.
        |TRAP    0,Fputs,StdOut

        End process.
        |TRAP  0,Halt,0

        String to be printed.  #a is
        newline, 0 terminates the
        string.
        |string  BYTE  "Hello, world!",#a,0
   }

Keywords
--------

The following is the complete list containing all forty-five
keywords.

::

   var fn type struct union choice enum const exception
   when if else case match
   loop for while break continue reverse
   try catch
   return
   package namespace include import hiding as
   using implicit cast ann alias extern scope do inline with
   undefined Null true false unreachable
   _

Identifiers
-----------

Identifiers follow the same rule as ``C`` identifiers.
Identifiers with a double underscore are reserved.

::

   foo
   _bar
   foo_bar
   foo123

Operators
---------

Range operators can be used to specify ranges for iteration or
pattern matching. The xor operator is ``+^`` and the
character ``^`` is used for error propagation.

::

   + - * / %
   ! && ||
   & | +^ ~
   . ->
   .. ^.. ..^ ^..^
   ^
   < > <= >= == !=
   ++ --
   [] () {}
   <|>
   cast
   ann
   type

Punctutation
------------

Punctuation characters are delimiters, separators, or markers.

::

   ( ) { } ; : , => \ ... @ #

Grammar
=======

This section gives an informal overview of the various major
grammatical components. A formal grammar is given in the
appendix.

Expressions
-----------

An expression computes a value.

* Arithmetic
* Boolean
* Bitwise
* Comparison
* Indexing
* Slicing
* Access
* Pipe
* Lambda
* Call
* Construct
* Annotate
* Error
* Cast
* Dereference
* Control Flow
* Block
* Term

Statements
----------

* Assignment
* Update

  Only expressions classified as lvalues can appear on the lhs of
  an assignment or as an operand to the address of operator. The
  set ``e`` of lvalue expressions are recursively defined based
  on syntax as follows:

    - ``p.q.x`` where ``x`` is declared as a ``var`` in package
      ``p.q``.
    - ``*f`` where ``f`` is any expression.
    - ``e[i]``
    - ``e.n``
    - ``e!``
    - ``e^``

* Loop
* Control Flow
* Expression
* Declaration

Patterns
--------

A pattern matches a value with another value or range of values
and binds component data to identifiers.

* Identifier
* Type
* Field
* Index
* Expression
* Range
* Array
* Pointer
* Struct
* Choice
* Enum

Declarations
------------

A declaration binds a name to a definition.

* Type

  A type may be parametric over zero or more types.

  ::

     struct Node[t] {
         head: *t;
         tail: *Node[t];
     }

* Constant
* Variable
* Function

  A function declaration must specify the types of all arguments
  and the return type. A function may be parametric over zero or
  more types.

  ::

     fn len[t](xs: []t): size
     {
         return xs.len;
     }

* Symbol Alias
* Type Alias

  A type alias may be parametric over zero or more types.

  ::

     type List[t] = :*Node[t];

The effect of the following declarations are local to the lexical
scope or the file.

* extern
* import
* using

  A ``using`` declaration is used to bring nested symbols into
  scope.
  
  ::
  
     enum Color { black, white, red, blue, green }
     using type Color; // Bring all members into scope.
     var fg = red;
  
  A ``using implicit`` declaration is used to bring objects into
  implicit scope.
  
  ::
  
     fn skip(:*Lexer, :&fn(:char): bool): void;
     fn skip_char(:*Lexer, :char): bool;
      
     using implicit lexer;
     skip(&isspace);
     if (skip_char('.')) { return Token.Dot; }
     else                { return Token.Err; }

  When ``_`` is used as an expression, it takes the value of the
  implicit argument of the required type.

  ::

     loop for (var i; 0..^10) {
         using implicit i;
         a[_+1] += a[_];
     }
      
     fn foo(i: int, f: float, d: double);
     using implicit d;
     foo(i, f, _);
     foo(.i = i, .f = f);

  Implicit arguments to functions may be left out or can be
  passed by explicitly specifying the ``_``.  It is an error if
  two objects in implicit scope can be implicitly converted to an
  implicit argument. In particular, multiple objects with the
  same type are not allowed to be in implicit scope. Also,
  ambiguity between explicit arguments and implicit arguments
  results in a compiler error.

  ::

    using implicit ann(int)(42);
    fn sum(x, y: int): int { return 0; }
    sum(1); // Error. Is 1 the first argument or the second?
    sum(_, 1); // Ok.
    fn fsum(x: int, y: float): int { return 0; }
    fsum(1.0); // Ok. fsum(42, 1.0);
    fn fsum1(x: float, y: int): int { return 0; }
    fsum1(1); // Ok. fsum1(1, 42);

Attributes
----------

An attribute enriches a declaration with additional information.

::

   struct int_align16 { a: @alignTo(16) int }

   @doc("Return the sum of two integers.")
   fn sum(a, b: int): int { return a + b; }

Namespaces
----------

A namespace file declares packages, namespaces, and interfaces
contained within the namespace. A declared package can be
optionally ascribed with an interface.

::

   namespace foo;
   package type BAR;
   package bar: BAR;

Interfaces
----------

An interface specifies types of symbols that have to be exported
by any package implementing the interface. A symbol can be one of
the following:

* Opaque Type
* Manifest Type
* Type Alias
* Function
* Variable
* Constant
* Symbol Alias

Packages
--------

A package contains a sequence of declarations.

Semantics
=========

Types
-----

The following are the builtin types.

* Signed Integers
* Unsigned Integers
* Floating Point Numbers
* ``char``
* ``repr``
* ``any``
* ``none``
* ``void``
* ``string``

  A ``string`` is a ``[]char`` which encodes the assumption that
  a null byte follows the last ``char`` in the range.  For
  example, the ``string`` ``"hello"`` has length ``5`` and takes
  up 6 bytes of storage. A slicing operation on a string where
  the end of the range is ommitted yields another ``string``.
  Other slicing operations yield only a ``[]char``. The
  ``string`` module defines functions ``from_slice`` and
  ``to_slice`` to convert between ``string`` and ``[]char``.

* ``Error``
* Arrays
* Pointers
* References
* Slices
* Tuples
* Anonymous Sums

Users can define types using one of the following constructs.

* struct
* union
* choice
* exception
* enum
* C-style enum
* Wrapper Types

Packages and Package Types
--------------------------

The package system is designed to aid fast parallel and serial
compilation. If N is the average time to compile a package and M
is the average time to compile a package type file, then a
package that imports K packages can be compiled (including code
generation) in time N + K*M. In addition, package type files need
only be compiled once and can be reused for subsequent imports of
packages with the same package type. Together, these two
guarantees ensure low latency and high throughput. The key
assumption behind this design is that M is much smaller than N
and therefore the time to compile a package is independent of the
size of the imported packages.

Evaluation
----------

* signed integers trap on overflow or underflow.
* unsigned integers wrap around.
* ``match`` patterns are evaluated only when needed. The
  ``<|>`` operator is short circuiting.

Undefined Behaviour
-------------------

ABI
===

We strive to stay as close to the platform's ``C`` ABI as
possible.
