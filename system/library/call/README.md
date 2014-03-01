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

Console commands like **dir** needs further investigation and help to implement window's stdio redirections.

Files
------------------------

>*call.reds* : low-level binding for Red/System

>*call.red* : binding for Red

>*console-call.red* : Call Red binding added to console

Running the Red console call example
------------------------

1. This binding is provided with an example adding **call** feature to the console.

1. Compile with Red from Red main directory

    `$ red -c system/library/call/examples/console-call.red`

1. Or compile it from the REBOL console :

    `do/args %red.r "%system/library/call/examples/console-call.red"`

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

