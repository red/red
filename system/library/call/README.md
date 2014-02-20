Call for Red/System
------------------------

This binding is still work in progress.

It implements a **call** function for Red/System (similar to rebol's **[call](http://rebol.com/docs/shell.html)** function).

POSIX version uses [wordexp](http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html) function to perform word expansion.

Windows version performs home made string parsing (no expansion or substitution).

Any proposal to improve this parsing (with native Windows functions) is welcome.

Current limits
------------------------

The windows' call function can launch only GUI apps such as **notepad**, **explorer**.

Console commands like **dir** needs further investigation and help to implement window's stdio redirections.

Implementation
------------------------

* POSIX, two functions are avaliable :

**call** : execute command line, with only a waitend parameter.

* Syntax :

       call cmd [c-string!] waitend [logic!]

* Example :

       pid: syscall/call "ls -l" true

> If waitend = false, **call** returns a child process number else returns 0.

**call-io** : execute command line with IOs redirection. Waitend is implicit.

* Syntax :
      call-io cmd [c-string!] in-buf [byte-ptr!] in-count [integer!] out-count [int-ptr!]

* Output redirection example :

      str        [c-string!]
      str: null
      syscall/call-io "cat /proc/cpuinfo"

Running the Red/System call example
------------------------

1. This binding is provided with an example calling some basic unix or windows commands.

1. Compile with Red

    `$ red -c system/library/call/examples/call-example.reds`

1. From the REBOL console type :

    `do/args %red.r "%system/library/call/examples/call-example.reds"`


1. The resulting binaries are in Red main directory.

    Linux users run `call-example` from command line.

    Windows users need to open a DOS console and run `call-example.exe` from there.

1. Edit the source code to test it with other commands.
