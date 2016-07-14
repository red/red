Call for Red and Red/System
------------------------

This binding implements a **call** function for Red (similar to rebol's **[call](http://rebol.com/docs/shell.html)** function).

POSIX version uses [wordexp](http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html) function to perform word expansion.

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

    Windows users run **console-call.exe**.

Syntax
------------------------

		USAGE:
			call cmd /wait /console /shell /input in /output out /error err

		DESCRIPTION:
			Executes a shell command to run another process..
			call is type: function!

		ARGUMENTS:
			cmd [string! block!] => A shell command, an executable file or a block.

		REFINEMENTS:
			/wait => Runs command and waits for exit.
			/console => Runs command with I/O redirected to console.
			/shell => Forces command to be run from shell.
			/input
				in [string! block!] => Redirects in to stdin.
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
		red>> data: "" call/output "ls" data call/input/console "grep red" data
		boot.red
		lexer.red
		red.exe
		red.r
		== 0
		red>>


Windows examples
------------------------

        C:\Red>console-call.exe
        -=== Call added to Red console ===-
        -=== Red Console alpha version ===-
        Type HELP for starting information.

        red>> call/wait/console "dir /w"
        Volume in drive C is System
        Volume Serial Number is 9DBC-C994

        Directory of C:\Red

        [.]                 [..]                Red                 [bridges]           boot.red
        lexer.r             README.md           [runtime]           compiler.r          call-example
        run-all.r           version.r           console-call.exe    console             test
        [tests]             [docs]              BSD-3-License.txt   ls.txt              BSL-License.txt
        [system]            console-call        red-041.exe         [quick-test]        red.r
        usage.txt           [build]             [utils]
                      18 File(s)      2 247 911 bytes
                      10 Dir(s) 200 888 594 432 bytes free
        == 0
        red>> call "explorer"
        == 0

        red>> ; Output redirection
        red>> out: ""
        == ""
        red>> call/output "dir /w" out
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
		red>> data: "" call/output {findstr "Nenad" *.r} data
		== 0
		red>> print data
		lexer.r:        Author:  "Nenad Rakocevic"
		lexer.r:        Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
		compiler.r:     Author:  "Nenad Rakocevic"
		compiler.r:     Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
		red.r:  Author:  "Nenad Rakocevic, Andreas Bolka"
		red.r:  Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic, Andreas Bolka. All rights reserved."
        red>>
		red>> data: "" call/output "dir" data
		red>> call/input/console "findstr red" data		;-- redirect data as input for findstr
		red>> 14/03/2014  08:38            27 510 boot.red
		05/03/2014  09:25           659 182 red.exe
		14/03/2014  08:38             9 517 red.r
		14/03/2014  08:38            11 438 lexer.red
		== 0
		red>>
        red>> call/wait/console "cmd"              ; enter Windows console
        C:\Red>
