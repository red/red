Call for Red/System
------------------------

This binding implements a **call** function for Red/System (similar to rebol's **[call](http://rebol.com/docs/shell.html)** function).

POSIX version uses [wordexp](http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html) function to perform word expansion.

Windows version performs home made string parsing (no expansion nor substitution).

Any proposal to improve this parsing (with native Windows functions) is welcome.


Running the Red/System call example
------------------------

1. This binding is provided with an example calling some basic unix commands.

1. Compile with Red

    `$ red -c system/library/call/examples/call-example.reds`

1. From the REBOL console type :

    `do/args %red.r "%system/library/call/examples/call-example.reds"`


1. The resulting binaries are in Red main directory.

    Linux users run `call-example` from command line.

    Windows users need to open a DOS console and run `call-example.exe` from there.
