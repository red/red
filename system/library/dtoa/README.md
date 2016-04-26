Double conversion library for Red/System
------------------------

This file partially port dtoa.c (by David M. Gay, downloaded from http://www.netlib.org/fp/dtoa.c) to the Red runtime.

Please remember to check http://www.netlib.org/fp regularly (and especially before any Red release) for bugfixes and updates.

FYI: a more readable version from Python, in %Python/dtoa.c (http://hg.python.org/cpython)

!! For `dtoa`, only support mode 0 (the most commonly used mode) now !!

Functions
------------------------

* `float-to-ascii` which corresponding to `dtoa` in dtoa.c
* `string-to-float` which corresponding to `strtod` in dtoa.c
* `form-float` a wrapper for `float-to-ascii` for human-friendly output.

Examples
------------------------
Please check the tests file (tests/source/library/dtoa-test.red) to see how to use it. ;-)

Running tests
------------------------
1. Compile with Red
    `$ red -c tests/source/library/dtoa-test.red`

1. From the REBOL console type :

    `do/args %red.r "%tests/source/library/dtoa-test.red"`, the compilation process should finish with a `...output file size` message.

1. The resulting binaries are in Red main directory, go try them!

    Linux users run `dtoa-test` from command line.

    Windows users need to open a DOS console and run `dtoa-test.exe` from there.
