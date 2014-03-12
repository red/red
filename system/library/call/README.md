Call for Red and Red/System
------------------------

This binding is still work in progress.

It implements a **call** function for Red (similar to rebol's **[call](http://rebol.com/docs/shell.html)** function).

POSIX version uses [wordexp](http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html) function to perform word expansion.

Windows version performs home made string parsing (no expansion or substitution).

Any proposal to improve this parsing (with native Windows functions) is welcome.

Current limits
------------------------

Windows : output redirection returns wrong char encoding.

Files
------------------------

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
			call cmd /wait /console /ascii /input in /output out /error err

		DESCRIPTION:
			Executes a shell command to run another process..
			call is type: function!

		ARGUMENTS:
			cmd [string!] => The shell command or file.

		REFINEMENTS:
			/wait => Runs command and waits for exit.
			/console => Runs command with I/O redirected to console (TODO).
			/ascii => Read output as ascii (Windows only).
			/input
				in [string!] => Redirects in to stdin.
			/output
				out [string! block!] => Redirects stdout to out.
			/error
				err [string! block!] => Redirects stderr to err.
		RETURNS:
			a process ID, 0 if finished or -1 if error

When you use the /input, /output, or /error refinements you automatically set the /wait refinement.

Linux examples
------------------------

        $ ./console-call
        -=== Call added to Red console ===-
        -=== Red Console alpha version ===-
        Type HELP for starting information.

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

Windows problems
------------------------

If you want to launch a GUI application just write : `call "explorer"`

To launch a command like **type** or **dir** you need to call the command line interpreter with this option :

> **/c** : Execute command line

If you need output redirection add this option :

> **/u** : Ask for unicode chars

Example : `out: "" call/output "cmd /u /c dir" out` to execute **dir** and get the result into *out*

Even if you ask **cmd** for unicode, some commands will return ansi chars. To force **call** to read ansi chars, use the
/ascii refinement. **Call** will not wait for wide-chars but for one byte chars.
Chars greater than #"^(7F)" are translated to #"^(7F)".
The **dir** command returns wide-char, the **tree** or **ping** command returns ansi, so if you have problem with
output redirection, try with this refinement or not.

To get the output from a **dir** command, you can use either `out: "" call/output "cmd /u /c dir" out`
or `out: "" call/ascii/output "cmd /c dir" out`.

Example : `out: "" call/output/ascii "cmd /c tree /a" out`


Windows example
------------------------



        C:\Red>console-call.exe
        -=== Call added to Red console ===-
        -=== Red Console alpha version ===-
        Type HELP for starting information.

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
                      18 File(s)      2 247 911 bytes
                      10 Dir(s) 200 888 594 432 bytes free
        == 0
        red>> call/wait "explorer"
        == 0

        red>> ; Output redirection
        red>> out: ""
        == ""
        red>> call/output "cmd /u /c dir /w" out
        == 0
        red>> out
        == { Volume in drive C is System^M^/ Volume Serial Number is 9DBC-C994
        red>> print out
        Volume in drive C is System
        Volume Serial Number is 9DBC-C994

        Directory of C:\Red

        [.]                 [..]                [bridges]           boot.red
        lexer.r             README.md           [runtime]           compiler.r
        call-example        run-all.r           version.r           console-call.exe
        console             test                [tests]             [docs]
        BSD-3-License.txt   ls.txt              BSL-License.txt     [system]
        console-call        red.exe             [quick-test]        red.r
        Red                 usage.txt           lexer.red           [build]
        [utils]
                      19 File(s)       2 407 679 bytes
                      10 Dir(s)  200 327 868 416 bytes free

        red>>
        red>> call/wait "cmd"              ; enter Windows'terminal
        red>>


Known bugs
------------------------

Outputs redirection can loose data (end of buffer).

Access to C system variable **[errno](http://en.wikipedia.org/wiki/Errno.h)** required.
