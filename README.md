[![Join the chat at https://gitter.im/red/red](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/red/red?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Travis build](https://travis-ci.org/red/red.svg?branch=master)](https://travis-ci.org/red/red)
[![Build status](https://ci.appveyor.com/api/projects/status/mie736c6x4268boo/branch/master?svg=true)](https://ci.appveyor.com/project/red/red/branch/master)

Red Programming Language
------------------------

**Red** is a new programming language strongly inspired by [Rebol](http://rebol.com), but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing modern support for concurrency and multi-core CPUs.

Red has its own complete cross-platform toolchain, featuring two compilers, an interpreter and a linker, not depending on any third-party library, except for a Rebol2 interpreter, required during the bootstrap phase. Once complete, Red will be [self-hosted](http://en.wikipedia.org/wiki/Self-hosting).

The Red software stack also contains another language, **Red/System**, which is a low-level dialect of Red. It is a limited C-level language with a Red look'n feel, required to build Red's runtime library and be the target language of Red's compiler. More information at [red-lang.org](http://www.red-lang.org).

Making a Red "Hello World"
------------------------
The Red toolchain comes as a single **one-megabyte** executable file that you can download from [here](http://www.red-lang.org/p/download.html) for the big-3 platforms.

1. Put the downloaded **red** binary in the working folder.

2. In a code or text editor, write the following Hello World program:

        Red [
        	Title: "Simple hello world script"
        ]

        print "Hello World!"

3. Save it under the name: **hello.red**

4. From a terminal (works from DOS too), run it with:

        $ red hello.red

5. You should see the Hello World! output.

6. Want to generate a compiled executable from that program?

        $ red -c hello.red
        $ ./hello

7. Want to cross-compile to another supported platform?

        $ red -c -t Windows hello.red
        $ red -c -t Darwin hello.red
        $ red -c -t Linux-ARM hello.red

**The command-line options are:**

    red [options] [file]

**[file]**

Any Red or Red/System source file. If no file and no option is provided, the graphical console will be launched. If a file with no option is provided, the file will be simply run by the interpreter (*it is expected to be a Red script with no Red/System code*).

**[options]**

    --cli                          : Run the command-line REPL instead of the
                                     graphical console.

    -c, --compile                  : Forces generation of an executable in
                                     the working folder.

    -d, --debug, --debug-stabs     : Compile source file in debug mode. STABS
                                     is supported for Linux targets.

    -dlib, --dynamic-lib           : Generate a shared library from the source
                                     file.

    -h, --help                     : Output this help text.

    -o <file>, --output <file>     : Specify a non-default [path/][name] for
                                     the generated binary file.

    -r, --no-runtime               : Do not include runtime during Red/System
                                     source compilation.

    -t <ID>, --target <ID>         : Cross-compile to a different platform
                                     target than the current one (see targets
                                     table below).

    -v <level>, --verbose <level>  : Set compilation verbosity level, 1-3 for
                                     Red, 4-11 for Red/System.

    -V, --version                  : Output binary version string.

    --red-only                     : Stop just after Red-level compilation.
                                     Use higher verbose level to see compiler
                                     output. (internal debugging purpose)

Cross-compilation targets:

    MSDOS        : Windows, x86, console (+ GUI) applications
    Windows      : Windows, x86, GUI applications
    WindowsXP    : Windows, x86, GUI applications, no touch API
    Linux        : GNU/Linux, x86
    Linux-ARM    : GNU/Linux, ARMv5, armel (soft-float)
    RPi          : GNU/Linux, ARMv5, armhf (hard-float)
    Darwin       : MacOSX Intel, console-only applications
    Syllable     : Syllable OS, x86
    FreeBSD		 : FreeBSD, x86
    Android      : Android, ARMv5
    Android-x86	 : Android, x86

_Note_: Running the Red toolchain binary from a $PATH currently requires a wrapping shell script (see relevant tickets: [#543](https://github.com/red/red/issues/543) and [#1547](https://github.com/red/red/issues/1547).

Running the Red REPL
-----------------------

1. Just run the `red` binary with no option to access the [REPL](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop).

        -=== Red Console alpha version ===-
        (only ASCII input supported)

        red>>

1. You can use it to test rapidly some Red code:

        red>> 1 + 2
        == 3

        red>> inc: func [n][n + 1]
        == func [n][n + 1]

        red>> inc 123
        == 124

  
Notes:

- On Windows, the REPL runs by default in GUI mode. To run it in the command line, invoke the red binary as `red --cli`.
- Wine has some [issues](https://github.com/red/red/issues/1618) with the GUI-Console. Install the `Consolas` font to fix the problem.


Running Red from the sources
------------------------
The compiler and linker are currently written in Rebol. Please follow the instructions for installing the compiler toolchain in order to run it from sources:

1. Clone this git repository or download an archive (`ZIP` button above or from [tagged packages](https://github.com/red/red/tags)).

1. Download a Rebol interpreter suitable for your OS: [Windows](http://www.rebol.com/downloads/v278/rebol-core-278-3-1.exe), [Linux](http://www.maxvessi.net/rebsite/Linux/) (or [Linux](http://www.rebol.com/downloads/v278/rebol-core-278-4-2.tar.gz)), [Mac OS X](http://www.rebol.com/downloads/v278/rebol-core-278-2-5.tar.gz), [FreeBSD](http://www.rebol.com/downloads/v278/rebol-core-278-7-2.tar.gz), [OpenBSD](http://www.rebol.com/downloads/v278/rebol-core-278-9-4.tar.gz), [Solaris](http://www.rebol.com/downloads/v276/rebol-core-276-10-1.gz)

1. Extract the `rebol` binary, put it in root folder, that's all!

1. Let's test it: run `./rebol`, you'll see a `>>` prompt appear. Windows users need to double-click on the `rebol.exe` file to run it.

1. From the REBOL console type:

        >> do/args %red.r "%tests/hello.red"

The compilation process should finish with a `...output file size` message. The resulting binary is in the working folder. Windows users need to open a DOS console and run `hello.exe` from there.

To see the intermediary Red/System code generated by the compiler, use:

        >> do/args %red.r "-v 2 %tests/hello.red"

You can also compile the Red console from source:

        >> do/args %red.r "%environment/console/console.red"

Note: the `-c` argument is not necessary when launching the Red toolchain from sources, as the default action is to compile the input script (the binary form default action is run the input script through the interpretor).

Contributing
-------------------------
If you want to contribute code to the Red project be sure to read the [guidelines](https://github.com/red/red/wiki/Contributor-Guidelines) first.

It is usually a good idea to inform the Red team about what changes you are going to make in order to ensure that someone is not already working on the same thing. You can reach us through the [mailing-list](https://groups.google.com/forum/?hl=en#!forum/red-lang) or our [chat room](https://gitter.im/red/red).

Satisfied with the results of your change and want to issue a pull request on Github?

Make sure the changes pass all the existing tests, add relevant tests to the test-suite and please test on as many platforms as you can. You can run all the tests using (from Rebol console, at repository root):

        >> do %run-all.r

Anti-virus false positive
-------------------------
Some anti-virus programs are a bit too sensitive and can wrongly report an alert on some binaries generated by Red, if that happens to you, please fill a ticket [here](https://github.com/red/red/issues), so we can report the false positive.

License
-------------------------
Both Red and Red/System are published under [BSD](http://www.opensource.org/licenses/bsd-3-clause) license, runtime is under [BSL](http://www.boost.org/users/license.html) license. BSL is a bit more permissive license than BSD, more suitable for the runtime parts.
