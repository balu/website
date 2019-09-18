NAME
====

``tak`` - Create presentations that use the Takahashi method.

SYNOPSIS
========
::

    tak [OPTIONS]... [INPUT] [OUTPUT]

DESCRIPTION
===========

The ``tak`` command can be used to create a presentation. The
INPUT is the specification for a presentation. The OUTPUT
specifies the name of the output file. If INPUT is not given or
'-', ``tak`` reads from the standard input. If OUTPUT is not
given or '-', the output is written to the standard output.

**-t TEMPLATE, --template TEMPLATE** 
   The jinja2 template to use for output (See TEMPLATES).

**-n, --no-escape**

   Disable sanitizing content for html. By default, ``tak``
   assumes that the output is in html format and sanitizes
   content using html character entities. For example the text
   slide::

    # <html>

   is written to the output as::

    &lt;html&gt;

SYNTAX
======

The input to ``tak`` must be a UTF-8 encoded text file.

The first non-blank character in a line must start a directive.

An optional title page can be specified at the beginning::

    .title  what
    .author who

A text slide has the following format::

    # A line of text

An image slide has many formats::

    ## [Caption] "path/to/image.jpeg"
    ## (Caption) "path/to/image.jpeg"
    ## <Caption> "path/to/image.jpeg"
    ## {Caption} "path/to/image.jpeg"
    ## |Caption| "path/to/image.jpeg"

    ## <<Caption>> "path/to/image.jpeg"

Caption and path to the image file must be enclosed within
delimiters.  Delimiters must be one of more of one of the opening
brackets ({[< matched with the same number of corresponding
closing bracket or one or more of one of the special characters
\|":' matched with same number of the same character.

The path to the image file is embedded verbatim into the output.
Therefore, this path must be relative to the location of the
output file.

The file may contain comments::

    \ This is a comment.

Blank lines are ignored.

Everything else is a syntax error.

TEMPLATES
=========

If a template file is given as argument using the **-t** option,
``tak`` searches for it in the current directory and then in the
list of builtin templates.

The following templates are distributed with ``tak``.

**dark.html**
   White text on black background (default).

**light.html**
   Black text on white background.

BUGS
====

No known bugs.

AUTHOR
======

Balagopal Komarath <bkomarath@rbgo.in>
