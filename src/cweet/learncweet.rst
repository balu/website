::

    // Comments start with "//" and span to the end of the line.

    //////////////
    // Variables /
    //////////////

    // Variables are declared using `var'.
    var i = 42; // Infer the type.
    var lakh = 100_000; // _ as a digit separator.
    var i: int = 42; // Specify type of variable.
    var i = ann(int)(42); // Specify type of initializer.

    //////////
    // Types /
    //////////

    // All common fundamental types from C.
    var b = true || false; // bool
    var i: int = 42; // signed integers
    var u: uint = 0; // unsigned integers
    var d = 3.14; // floating point numbers

    // Operators on fundamental types.
    // Arithmetic operators on numbers: + - * / %
    // Bitwise operators on unsigned integrals: & | +^ ~
    // Boolean logic operators on bool: && || !

    // Implicit type conversions are not allowed.
    var i: u8 = 4;
    var j: u16 = 5;
    // var k = i + j; // Error. modulo 2^8 or modulo 2^16?

    // Compound Types are types constructed from other types.

    // Pointers:
    //   - nullable (pointers)
    //   - non-nullable (references).
    var x: &int = &i; // &T is a reference to T.
    var y = *x + 1; // Dereferencing is same as in C.
    var y: *int = Null;
    // x = y; // Error. Cannot assign a pointer to a reference.

    // Arrays have a fixed-size known at compile time.
    var primes: [_]int = [2, 3, 5, 7, 11, 13]; // _ deduces size.
    var sum = primes[0] + primes[1]; // Arrays support indexing.
    var nprimes = primes.len; // Also carry length with them.

    // Slices are {ptr, len} pairs.
    var s = primes[..]; // Constuction.
    var t = s[1..]; // A slice can be sliced further.
    var r = s[1..3]; // s[1] to s[3] all inclusive.
    var u = s[0..^s.len]; // All elements

    // Only `size' type can be used for indexing.
    // Like `word' where wraparound aborts the program.
    var i: size = 1;
    var a = [1, 2, 3][i];

    // User-defined Types.

    // structs.
    struct Point { x, y: int }

    var origin = Point{0, 0}; // Construction.

    // Type alias creates new names for existing types.
    alias II = :{int, int};
    var p = {2, 3};
    var s = p.a + p.b; // Members are a, b, ...

    // choices are sum types.
    choice NetStatus {
        Disconnected,
        Connected{ ip: [4]byte }
    }

    using type NetStatus; // Expose data constructors.

    var ns = Disconnected; // Construction.
    var ns1 = Connected{[127, 0, 0, 1]};

    // A match statement can be used to pattern match.
    var is_connected = match (ns) {
        |Disconnected => false,
        _             => true, // Catch-all pattern.
    };

    // Anonymous choices.
    alias IoF = :int|float;
    var x: IoF = 0.0; // Implicit conversion from float
    match (x) { // match on types.
        :int   => { print("int"); },
        :float => { print("float"); },
    }

    // enums
    enum Colour { red, green, blue, white, black }

    var fg = Colour.black;
    var bg = Colour.white;
    // fg.black is true when fg == Colour.black.
    var is_light_theme = fg.black && bg.white;

    // C like unions are also supported.

    /////////////////
    // Conditionals /
    /////////////////

    // if-else as an expression.
    var max = if (i > j) i else j;

    // or a statement.
    if (i > j) { // braces required.
        max = i;
    } else {
        max = j;
    }

    // A when conditionally executes a block of statements.
    when (i > j) {
        ++i;
    }

    // A case selects from multiple choices.
    var abs = case {
        n > 0  => n,
        n == 0 => 1,
        true   => -n // Catch-all clause
    };

    // A `match' pattern matches.
    match (i) {
        `-50..50 => { print("small"); },
        _        => { print("large"); }
    }

    //////////
    // Loops /
    //////////

    // Infinite loop with a label.
    loop infty {
        print("forever.\n");
        when (false) { break infty; } // Labelled break.
    }

    // `for' loops over slices or ranges.
    loop for (var x; [2, 3, 5, 7][..]) {
        print(x);
    }

    // `reverse' allows iteration in reverse.
    loop for (var i; reverse a.len^..0) {
        print(a[i]);
    }

    // Iterating by reference.
    loop for (var &x; xs) { ++*x; }

    // Iterating using index.
    loop for (var &x, var i; xs) {
        assert(&xs[i] == x);
    }

    // `while' loops conditionally iterate.
    loop while (x > 0) {
        sum += x;
        --x;
    }

    var p = undefined;
    loop for   (p; 100..) // uses existing variable p.
         while (!is_prime(p))
    {
        // Empty
    }
    // p is the first prime larger than 100.

    ///////////////////
    // Lexical Scopes /
    ///////////////////

    // All symbol bindings are lexically scoped.
    var x = 0;
    { // A new scope.
        var x = 1; // Shadowing
        print(x); // 1
    }
    print(x); // 0

    var a = 4;
    var s = a + do { // A block expression.
        var a = [1, 2, 3, 4, 5];
        var sum = 0;
        loop for (var e; a[..]) { sum += e; }
        sum;
    };

    // A with expression/statement introduces a new scope.
    with (var sum = a + b;) if (sum > 0) {
        // use sum.
    } else {
        // use sum.
    }
    // sum is not available here.

    //////////////
    // Functions /
    //////////////

    // Defined using fn keyword.
    // Full type specification required.
    fn inc(n: int): int { return n + 1; }

    // `inline' implies all calls can be inlined.
    fn transform(xs: []int, inline f: &fn(:int):int): void
    {
        loop for (var &x; xs) {
            *x = (*f)(*x);
        }
    }

    // The following call is inlined.
    transform(xs, \x => do { sum += x; sum; });

    // The pipe operator is just syntax sugar for data pipelines.
    len = sqrt(
            fold(
              map(v, \x => x * x),
              \(x, y) => x + y,
              0
            )
    );
    // is better expressed as
    len = v
          ->map(\x => x * x)
          ->fold(\(x, y) => x + y, 0)
          ->sqrt();

    // Named arguments.
    transform(.f = \x => x * x, .xs = xs);

    // `implicit' arguments.
    using implicit ann(int)(1);
    fn id(x: int): int { return x; }
    print(id()); // prints 1.
    fn sub(x, y: int): int { return a-b; }
    // implicit values can be accessed by _.
    print(sub(_, 2)); // prints -1.

    ///////////////////
    // Error Handling /
    ///////////////////

    // Types marked as `exception' are error signalling types.
    // Error is the standard exception type.
    exception struct Error { a: int }
    var error: Error = Error{0};

    // The type of the if-else expression is int|Error.
    var q = if (y != 0) x/y else error;

    // The postfix ^ propagates errors.
    fn min(x, y: *int): int|Error
    {
        var xx = *x^;
        var yy = *y^;

        return if (xx < yy) xx else yy;
    }

    // We can unpack choice types in an error inducing way.
    // Bang ! ignores errors.
    var ip = ns.Connected!.ip;

    // Scope guards
    fn file_copy(in, out: string): void|Error
    {
        var inf = open(in, "r")^;
        scope (exit) { close(inf); }

        var outf = open(out, "w")^;
        scope (exit) { close(outf); }

        with (
            var buf: [1024]char = undefined;
            var n = undefined;
        ) loop while (do { n = read(inf, buf[..]); n; } > 0) {
            import util (ensure);
            ensure(write(outf, buf[..^n]) == n)^;
        }
    }

    // scope (error) executes when error is returned.
    // scope (success) executes when non-error is returned.

    // try catch

    fn deref_or(x: *int, d: int): int
    {
        return try *x^ else d; // expression
    }

    try { // Statement
        n.prev^ = x.prev^;
        x.prev^ = n;
        n.next^ = x;
    } else {
        panic("Null pointer dereference.");
    }

    // Exits the block on first error.
    try {
        power = assemble(matter, antimatter)^;
        power->distribute(conduit)^;
        set_warp_factor(3)^;
    } catch {
        :PowerError        => { panic("Power failure."); },
        :DistributionError => { panic("Dist. failure."); },
        _                  => { use_impulse_power(); }
    }

    ////////////////////////////
    // Parametric Polymorphism /
    ////////////////////////////

    // A parametric function over two types t and u.
    fn second[t, u](x: *t, y: *u): *u { return y; }
    var x: *int = &i;
    var y: *float = &f;
    var z = second(x, y); // z has type *float

    // The C interface to `second' is:
    // extern void *second(void *x, void *y);


    // A parametric type.
    struct Node[t] {
        x: *t; // x: t; is an error.
        xs: *Node[t];
    }

    // C:
    //    struct Node {
    //        void *x;
    //        Node *xs;
    //    };

    // A parametric type alias.
    alias List[t] = :*Node[t];

    fn len[t](xs: List[t]): size
    {
        var s = 0;
        loop while (xs != Null) {
            xs = xs.xs;
        }
        return s;
    }

    // C:
    //    typedef Node *List;
    //    extern size_t len(List xs);

    ////////////////////
    // Low-level Stuff /
    ////////////////////

    // *any is like void*
    var a: &any = &i;

    // *T is convertible to *repr for reinterpretation.
    var i: i32 = 1;
    var irep: []repr = {&i, @sizeOf(type(i32))};
    var f: f32 = undefined;
    var frep: []repr = {&f, @sizeOf(type(f32))};
    memcpy(frep, irep);

    // Can also be done using a cast.
    var f = cast(f32)(i);


    // The `ptr' package provides many polymorphic
    // operators that work on pointers.
    import ptr;
    var left  = add(p, n); // p + n
    var right = sub(p, n); // p - n
    var d = dist(right, left); // |right - left|
    inc(&p); // p++
    dec(&p); // p--
    front(&p, n); // p += n
    back(&p, n); // p -= n
    next(p); // p + 1
    prev(p); // p - 1

    // @alignTo() specifies alignment.
    struct sse { sse_data: @alignTo(16) [4]float }

    // No strict type aliasing.
    // Wrap around (unsigned) or trap/wrap (signed and size).
    // Indices are checked for overflow at runtime.
    // Functions and types follow C layout.
    // Functions follow C calling convention.
    // Slices passed like ptr and len arguments.
    // &T, *T has same ABI as T*.

    ////////////////////////////
    // Namespaces and Packages /
    ////////////////////////////

    // Code is organized into non-nestable packages.
    // Packages (and package types) are organized
    // into nestable namespaces.

    // A namespace file (for foo) specifies contents
    // of the namespace.
    namespace foo;
    package type BAR;
    package bar: BAR;

    // A package type file specifies an interface.
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

    import foo.bar as b (baz as bax);

    fn client() {
        assert(b.bax() == b.bax());
    }
