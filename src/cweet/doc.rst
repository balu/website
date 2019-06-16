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

The prefixes :code:`0x`, :code:`0X` (hex), :code:`0b`, :code:`0B`
(binary), :code:`0c`, :code:`0C` (octal) are recognized. The
:code:`_` character may be used as a separator.

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

The letters :code:`p` and :code:`P` may be used for scientific
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

A character literal has type :code:`char` and is exactly one
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
literals are represented by a :code:`[]char` type where the
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

The following is the complete list of keywords.

::

   var fn type struct union choice enum const exception
   when if else case match
   loop for while break continue
   try catch
   return
   package namespace include import hiding
   using cast alias extern scope do inline with
   undefined Null Ref true false unreachable

Identifiers
-----------

Identifiers follow the same rule as :code:`C` identifiers. A
keyword can be made an identifier by enclosing within vertical
bars.

::

   foo
   _bar
   foo_bar
   foo123
   |match|

Operators
---------

Separate operators are used for pointer arithmetic. Range
operators can be used to specify ranges for iteration or pattern
matching. The xor operator is :code:`+^` and the character
:code:`^` is used for error propagation.

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

Punctutation
------------

Punctuation characters are delimiters, separators, or markers.

::

   ( ) { } ; : , => \ ...

Special Tokens
--------------

The following are special tokens.

::

   _ // Underscore for unnamed identifiers etc.
   ... // Ignore tail in patterns, varargs etc.
   @ // Attribute marker.
   # // Directive marker.

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
* Pointer Arithmetic
* Indexing
* Slicing
* Access
* Pipe
* Call
* Construct
* Annotate
* Error
* Cast
* Pointer Access
* Choice
* Block
* Term

Statements
----------

* Assignment
* Update
* Loops
* Control Flow
* Expression

Patterns
--------

A pattern matches a value with another value or range of values
and binds component data to identifiers.

* Identifier
* Type
* Field
* Expression
* Range
* Array
* Pointer
* Struct
* Choice

Declarations
------------

A declaration binds a name to a definition.

* Type
* Constant
* Variable
* Function
* Symbol Alias
* Type Alias

The effect of the following declarations are local to the lexical
scope or the file.

* extern
* import
* using

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
* char
* repr
* any
* none
* void
* string
* Error
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

Package Typing
--------------

When a package ascribed with a package type in the namespace file
is imported, the compiler may read only the package type file to
typecheck the code in the importing package.

Evaluation
----------

* signed integers trap on overflow or underflow.
* unsigned integers wrap around.
* :code:`match` patterns are evaluated only when needed. The
  :code:`<|>` operator is short circuiting.

Undefined Behaviour
-------------------

ABI
===

We strive to stay as close to the platform's :code:`C` ABI as
possible.
