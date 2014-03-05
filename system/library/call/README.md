Call for Red and Red/System
------------------------

This binding is still work in progress.

It implements a **call** function for Red (similar to rebol's **[call](http://rebol.com/docs/shell.html)** function).

POSIX version uses [wordexp](http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html) function to perform word expansion.

Windows version performs home made string parsing (no expansion or substitution).

Any proposal to improve this parsing (with native Windows functions) is welcome.

Current limits
------------------------

The windows' call function can launch only GUI apps such as **notepad**, **explorer**.

Windows : no stdio redirections implemented, see Windows example below.

Files
------------------------

>*call.reds* : low-level binding for Red/System

>*call.red* : binding for Red

>*console-call.red* : Call Red binding added to console

Running the Red console call example
------------------------

1. This binding is provided with an example adding **call** feature to the console.

1. Compile with Red from Red main directory

    `$ red -c tests/console-call.red`

1. Or compile it from the REBOL console :

    `do/args %red.r "%tests/console-call.red"`

1. The resulting binary is in Red main directory.

    Linux users run **console-call** from command line.

    Windows users need to open a DOS console and run **console-call.exe** from there.

Syntax
------------------------

      USAGE:
          call cmd /input in /output out /error err /wait
      DESCRIPTION:
          Executes a shell command to run another process.
      ARGUMENTS:
          cmd -- The shell command or file (Type: string)
      REFINEMENTS:
            /input -- Redirects in to stdin
                in -- (Type: string)
            /output -- Redirects stdout to out
                out -- (Type: string block)
            /error -- Redirects stderr to err
                err -- (Type: string block)
            /wait -- Runs command and waits for exit
      RETURNS:
            a process ID or 0

When you use the /input, /output, or /error refinements you automatically set the /wait refinement.

Windows example
------------------------

If you want to launch a GUI application just write : `call "explorer"`

To launch a command like **type** or **dir** you need to call the command line interpreter with the **/c** option : `call/wait "cmd /c dir"`

    C:\Red>console-call.exe
    -=== Call added to Red console ===-
    -=== Red Console alpha version ===-
    (only ASCII input supported)

    red>> call/wait "cmd /c dir /w"
    Volume in drive C is System
    Volume Serial Number is 9DBC-C994

    Directory of C:\Red

    [.]                 [..]                red041              [bridges]           boot.red
    lexer.r             README.md           [runtime]           compiler.r          call-example
    run-all.r           version.r           console-call.exe    console             test
    [tests]             [docs]              BSD-3-License.txt   ls.txt              BSL-License.txt
    [system]            console-call        red-041.exe         [quick-test]        red.r
    usage.txt           [build]             [utils]
                  18 File(s)      2 247 911 bytes
                  10 Dir(s) 200 888 594 432 bytes free
    == 0
    red>> call/wait "cmd /c explorer"
    == 1
    red>> call/wait "explorer"
    == 1
    red>> call/wait "cmd"              ; enter Windows'terminal
    red>>

Linux examples
------------------------

        $ ./console-call
        -=== Call added to Red console ===-
        -=== Red Console alpha version ===-
        (only ASCII input supported)

        red>> call "ls /"
        == 16139
        red>> bin   dev  home    lib      lost+found  mnt  proc  run   srv  tmp  var
        boot  etc  initrd  lib64  media       opt  root  sbin  sys  usr

        red>> call/wait "ls /"
        bin   dev  home    lib    lost+found  mnt  proc  run   srv  tmp  var
        boot  etc  initrd  lib64  media       opt  root  sbin  sys  usr
        == 0
        red>> out: "" call/output "ls /" out
        == 0
        red>> probe out
        {bin^/boot^/dev^/etc^/home^/initrd^/lib^/lib64^/lost+found^/media^/mnt^/opt^/proc^/root^/run^/sbin^/srv^/sys^/tmp^/usr^/var^/}
        == {bin^/boot^/dev^/etc^/home^/initrd^/lib^/lib64^/lost+found^/media^/mnt^/opt^/pr
        red>> inp: "This is a Red world...^/"
        == "This is a Red world...^/"
        red>> call/input "cat" inp
        This is a Red world...
        == 0

Known bug
------------------------

Outputs redirection can loose data (end of buffer).

Access to C system variable **[errno](http://en.wikipedia.org/wiki/Errno.h)** required.
