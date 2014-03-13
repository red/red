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
			/console => Runs command with I/O redirected to console.
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

		red>> call "ls"                                 ;-- process launched in background, returns process id
		== 31558
		red>> call/wait "ls"                            ;-- wait for end of process
		== 0
		red>> call/wait/console "ls -l *.r"             ;-- output redirected into console
		-rw-rw-r-- 1 user  user  57836 Mar  5 08:14 compiler.r
		-rw-rw-r-- 1 user  user  13202 Mar  5 08:14 lexer.r
		-rw-rw-r-- 1 user  user   9517 Mar 13 08:29 red.r
		-rw-rw-r-- 1 user  user   2419 Feb 12 11:13 run-all.r
		-rw-rw-r-- 1 user  user      5 Feb 12 11:13 version.r
		== 0
		red>> out: "" call/output "ls *.r" out          ;-- output redirection
		== 0
		red>> probe out
		{compiler.r^/lexer.r^/red.r^/run-all.r^/version.r^/}
		== {compiler.r^/lexer.r^/red.r^/run-all.r^/version.r^/}
		red>>
		red>> inp: "This is a Red world...^/"
		== "This is a Red world...^/"                   ;-- input redirection
		red>> call/input "cat" inp
		== 0
		red>> err: "" call/error "ls -" err             ;-- error redirection
		== 0
		red>>


Windows problems
------------------------

If you want to launch a GUI application just write : `call "explorer"`

To launch a command like **type** or **dir** you need to call the command line interpreter **cmd** with this option :

> **/c** : Execute command line

If you need output redirection add this option :

> **/u** : Ask for unicode chars

Example : `out: "" call/output "cmd /u /c dir" out` to execute **dir** and get the result into *out*

Even if you ask **cmd** for unicode, some commands will return ansi chars. To force **call** to read ansi chars, use the
**/ascii** refinement. **Call** will not wait for wide-chars but for one byte chars.
Chars greater than #"^(7F)" are translated to #"^(7F)".
The **dir** command returns wide-char, the **tree** or **ping** command returns ansi chars, so if you have problems with
output redirections, try with this refinement.

To get the output from a **dir** command, you can use either `out: "" call/output "cmd /u /c dir" out`
or `out: "" call/ascii/output "cmd /c dir" out`.

Example : `out: "" call/output/ascii "cmd /c tree /a" out`

The **/ascii** refinement applies on both **/output** and **/error** refinements.


Windows examples
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
