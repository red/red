Call for Red/System
------------------------

This is a low level binding.

POSIX version

Requirements
------------

*   **Linux**

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
