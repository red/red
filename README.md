[![Join the chat at https://gitter.im/red/red](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/red/red?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Windows build 2](https://github.com/red/red/workflows/Windows/badge.svg)](https://github.com/red/red/actions?query=workflow%3AWindows)
[![Linux build 2](https://github.com/red/red/workflows/Linux-x86/badge.svg)](https://github.com/red/red/actions?query=workflow%3ALinux-x86)
[![ARMhf build 2](https://github.com/red/red/workflows/RPi/badge.svg)](https://github.com/red/red/actions?query=workflow%3ARPi)
[![macOS build 2](https://github.com/red/red/workflows/macOS-x86/badge.svg)](https://github.com/red/red/actions?query=workflow%3AmacOS-x86)

# Red Programming Language

<p align="center">
  <img src="https://static.red-lang.org/images/GUI.png">
</p>


**Red** is a programming language strongly inspired by [Rebol](http://rebol.com), but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing modern support for concurrency and multi-core CPUs.

Red tackles the software building complexity using a DSL-oriented approach (we call them _dialects_) . The following dialects are built-in:

* [Red/System](https://static.red-lang.org/red-system-specs-light.html): a C-level system programming language compiled to native code
* [Parse](http://www.red-lang.org/2013/11/041-introducing-parse.html): a powerful PEG parser
* [VID](https://github.com/red/docs/blob/master/en/vid.adoc): a simple GUI layout creation dialect
* [Draw](https://github.com/red/docs/blob/master/en/draw.adoc): a vector 2D drawing dialect
* [Rich-text](https://github.com/red/docs/blob/master/en/rtd.adoc): a rich-text description dialect


Red has its own complete cross-platform toolchain, featuring an encapper, a native compiler, an interpreter, and a linker, not depending on any third-party library, except for a Rebol2 interpreter, required during the alpha stage. Once 1.0 is reached, Red will be [self-hosted](http://en.wikipedia.org/wiki/Self-hosting). Currently, Red is still at <u>alpha stage</u> and <u>32-bit only</u>.

Red's main features are:

* Human-friendly [syntax](http://www.rebol.com/rebolsteps.html)
* [Homoiconic](http://en.wikipedia.org/wiki/Homoiconicity) (Red is its own meta-language and own [data-format](http://www.rebol.com/rebolsteps.html))
* Functional, imperative, [reactive](http://www.red-lang.org/2016/06/061-reactive-programming.html) and symbolic programming
* Prototype-based object support
* Multi-typing
* Powerful pattern-matching [Macros](http://www.red-lang.org/2016/12/entering-world-of-macros.html) system
* Rich set of built-in datatypes (50+)
* Both statically and JIT-compiled(*) to native code
* Cross-compilation [done](https://github.com/red/red/blob/master/encapper/usage.txt) [right](https://github.com/red/red/blob/master/system/config.r)
* Produces executables of less than 1MB, with no dependencies
* Concurrency and parallelism strong support (actors, parallel collections)(*)
* Low-level system programming abilities through the built-in Red/System [DSL](http://en.wikipedia.org/wiki/Domain-specific_language)
* Powerful [PEG parser DSL](http://www.red-lang.org/2013/11/041-introducing-parse.html) built-in
* Fast and compacting Garbage Collector
* Instrumentation built-in for the interpreter, [lexer](https://github.com/red/docs/blob/master/en/lexer.adoc#instrumenting-the-lexer) and parser.
* Cross-platform native [GUI system](http://www.red-lang.org/2016/03/060-red-gui-system.html), with a [UI layout DSL](http://doc.red-lang.org/gui/VID.html) and a [drawing DSL](http://doc.red-lang.org/gui/Draw.html)
* Bridging [to the JVM](https://github.com/red/red/blob/master/bridges/java/hello.red)
* High-level scripting and [REPL](http://en.wikipedia.org/wiki/Read-eval-print_loop) GUI and CLI consoles included
* Visual Studio Code [plugin](https://marketplace.visualstudio.com/items?itemName=red-auto.red), with many helpful features
* Highly [embeddable](http://www.red-lang.org/2017/03/062-libred-and-macros.html)
* Low memory footprint
* Single-file (~1MB) contains whole toolchain, full standard library and REPL (**)
* No install, no setup
* Fun guaranteed!

(*) Not implemented yet.
(**) Temporarily split in two binaries

More information at [red-lang.org](https://www.red-lang.org).

# Running the Red REPL

[Download](https://www.red-lang.org/p/download.html) a GUI or CLI console binary suitable for your operating system, rename it at your convenience, then run it from shell or by double-clicking on it (Windows). You should see the following output:

        ---== Red 0.6.4 ==--
        Type HELP for starting information.

        >>

A simple Hello World would look like:

        >> print "Hello World!"
        Hello World!

If you are on the GUI console, a GUI Hello World (prompt omitted):

        view [text "Hello World!"]
        
<p align="center">
  <img width="97" height="52" src="https://static.red-lang.org/images/helloworld.png">
</p>

A more [sophisticated example](https://github.com/red/code/blob/master/Showcase/last-commits2.red) that retrieves the last commits from this repo and displays their log messages in a scrollable list:

        view [
            text-list data collect [
                foreach event load https://api.github.com/repos/red/red/commits [
                    keep event/commit/message
                ]
            ]
        ]

<p align="center">
  <img width="439" height="139" src="https://static.red-lang.org/images/commits.png">
</p>

Note: check also the following [improved version](https://github.com/red/code/blob/master/Showcase/last-commits3.red) allowing you to click on a given commit log and open the commit page on github.


You can now head to see and try some showcasing scripts [here](https://github.com/red/code/tree/master/Showcase) and [there](https://github.com/red/code/tree/master/Scripts). You can run those examples from the console directly using Github's "raw" link. E.g.:

        >> do https://raw.githubusercontent.com/red/code/master/Showcase/calculator.red

Note: If you are using the Wine emulator, it has some [issues](https://github.com/red/red/issues/1618) with the GUI-Console. Install the `Consolas` font to fix the problem.


# Generating a standalone executable

The Red toolchain comes as a single executable file that you can [download](https://www.red-lang.org/p/download.html) for the big-3 platforms (32-bit only for now). Rename the file to `redc` (or `redc.exe` under Windows).

1. Put the downloaded **redc** binary in the working folder.

2. In a code or text editor, write the following Hello World program:

        Red [
            Title: "Simple hello world script"
        ]

        print "Hello World!"

3. Save it under the name: **hello.red**

6. Generate a compiled executable from that program: (first run will pre-compile libRedRT library)

        $ redc -c hello.red
        $ ./hello

7. Want to generate a compiled executable from that program with no dependencies?

        $ redc -r hello.red
        $ ./hello

8. Want to cross-compile to another supported platform?

        $ redc -t Windows hello.red
        $ redc -t Darwin hello.red
        $ redc -t Linux-ARM hello.red

**The full command-line syntax is:**

    redc [command] [options] [file]

`[file]` any Red or Red/System source file.

* The -c, -r and -u options are mutually exclusive.

`[options]`

    -c, --compile                  : Generate an executable in the working
                                     folder, using libRedRT. (development mode)

    -d, --debug, --debug-stabs     : Compile source file in debug mode. STABS
                                     is supported for Linux targets.

    -dlib, --dynamic-lib           : Generate a shared library from the source
                                     file.

    -e, --encap                    : Compile in encap mode, so code is interpreted
                                     at runtime. Avoids compiler issues. Required
                                     for some dynamic code.

    -h, --help                     : Output this help text.

    -o <file>, --output <file>     : Specify a non-default [path/][name] for
                                     the generated binary file.

    -r, --release                  : Compile in release mode, linking everything
                                     together (default: development mode).

    -s, --show-expanded            : Output result of Red source code expansion by
                                     the preprocessor.

    -t <ID>, --target <ID>         : Cross-compile to a different platform
                                     target than the current one (see targets
                                     table below).

    -u, --update-libRedRT          : Rebuild libRedRT and compile the input script
                                      (only for Red scripts with R/S code).

    -v <level>, --verbose <level>  : Set compilation verbosity level, 1-3 for
                                     Red, 4-11 for Red/System.

    -V, --version                  : Output Red's executable version in x.y.z
                                     format.

    --config [...]                 : Provides compilation settings as a block
                                     of `name: value` pairs.

    --no-compress                  : Omit Redbin format compression.

    --no-runtime                   : Do not include runtime during Red/System
                                     source compilation.

    --no-view                      : Do not include VIEW module in the CLI console
                                     and the libRedRT.

    --red-only                     : Stop just after Red-level compilation.
                                     Use higher verbose level to see compiler
                                     output. (internal debugging purpose)

    --show-func-map                : Output an address/name map of Red/System
                                     functions, for debugging purposes.

`[command]`

    build libRed [stdcall]         : Builds libRed library and unpacks the
                                     libRed/ folder locally.

    clear [<path>]                 : Delete all temporary files from current
                                     or target <path> folder.

Cross-compilation targets:

    MSDOS        : Windows, x86, console (+ GUI) applications
    Windows      : Windows, x86, GUI applications
    WindowsXP    : Windows, x86, GUI applications, no touch API
    Linux        : GNU/Linux, x86, console (+ GUI) applications
    Linux-GTK    : GNU/Linux, x86, GUI only applications
    Linux-musl   : GNU/Linux, x86, musl libc
    Linux-ARM    : GNU/Linux, ARMv5, armel (soft-float)
    RPi          : GNU/Linux, ARMv7, armhf (hard-float)
    RPi-GTK      : GNU/Linux, ARMv7, armhf (hard-float), GUI only applications
    Pico         : GNU/Linux, ARMv7, armhf (hard-float), uClibc
    Darwin       : macOS Intel, console-only applications
    macOS        : macOS Intel, applications bundles
    Syllable     : Syllable OS, x86
    FreeBSD      : FreeBSD, x86
    NetBSD       : NetBSD, x86
    Android      : Android, ARMv5
    Android-x86  : Android, x86

_Note_: The toolchain executable (`redc.exe`) relies on Rebol encapper which does not support being run from a location specified in `PATH` environment variable and you get `PROGRAM ERROR: Invalid encapsulated data` error. If you are on Windows try using PowerShell instead of CMD. You can also provide the full path to the executable, put a copy of it in your working folder or wrap a shell script (see relevant tickets: [#543](https://github.com/red/red/issues/543) and [#1547](https://github.com/red/red/issues/1547)).


# Running Red from the sources (for contributors)

The compiler and linker are currently written in Rebol. Please follow the instructions for installing the compiler toolchain in order to run it from sources:

1. Clone this git repository or download an archive (`ZIP` button above or from [tagged packages](https://github.com/red/red/tags)).

1. Download a Rebol interpreter suitable for your OS: [Windows](http://www.rebol.com/downloads/v278/rebol-core-278-3-1.exe), [Linux](http://www.maxvessi.net/rebsite/Linux/) (or [Linux](http://www.rebol.com/downloads/v278/rebol-core-278-4-2.tar.gz)), [Mac OS X](http://www.rebol.com/downloads/v278/rebol-core-278-2-5.tar.gz), [FreeBSD](http://www.rebol.com/downloads/v278/rebol-core-278-7-2.tar.gz), [OpenBSD](http://www.rebol.com/downloads/v278/rebol-core-278-9-4.tar.gz), [Solaris](http://www.rebol.com/downloads/v276/rebol-core-276-10-1.gz).

1. Extract the `rebol` binary, put it in the root folder, that's all!

1. Let's test it: run `./rebol`, you'll see a `>>` prompt appear. Windows users need to double-click on the `rebol.exe` file to run it.

1. From the REBOL console type:

        >> do/args %red.r "%tests/hello.red"

The compilation process should finish with a `...output file size` message. The resulting binary is in the working folder. Windows users need to open a DOS console and run `hello.exe` from there.

You can compile the Red console from source:

        >> do/args %red.r "-r %environment/console/CLI/console.red"

To compile the Windows GUI console from source:

        >> do/args %red.r "-r -t Windows %environment/console/GUI/gui-console.red"

Note: the `-c` argument is not necessary when launching the Red toolchain from sources, as the default action is to compile the input script (the toolchain in binary form default action is to run the input script through the interpreter).
The `-r` argument is needed when compiling the Red console to make additional runtime functions available.

Note: The red git repository does not include a `.gitignore` file. If you run the automated tests, several files will be created that are not stored in the repository. Installing and renaming a copy of [`.git/.gitignore-sample`](https://github.com/red/red/blob/master/.gitignore-sample) file will ignore these generated files.

# Contributing

If you want to contribute code to the Red project be sure to read the [guidelines](https://github.com/red/red/wiki/%5BDOC%5D-Contributor-Guidelines) first.

It is usually a good idea to inform the Red team about what changes you are going to make in order to ensure that someone is not already working on the same thing. You can reach us through our [chat room](https://gitter.im/red/red).

Satisfied with the results of your change and want to issue a pull request on Github?

Make sure the changes pass all the existing tests, add relevant tests to the test-suite, and please test on as many platforms as you can. You can run all the tests using (from Rebol console, at repository root):

        >> do %run-all-tests.r

# Git integration with console built from sources

If you want git version included in your Red console built from sources, use this command:
```Red
call/show ""                                              ;-- patch call bug on Windows
save %build/git.r do %build/git-version.r                 ;-- lookup git version if available
do/args %red.r "-r %environment/console/CLI/console.red"  ;-- build Console
write %build/git.r "none^/"                               ;-- restore git repo status
```

# Anti-virus false positive

Some anti-virus programs are a bit too sensitive and can wrongly report an alert on some binaries generated by Red (see [here](https://github.com/red/red/wiki/%5BNOTE%5D-Anti-virus-false-positives) for the details). If that happens to you, please report it to your anti-virus vendor as a false positive.

# License

Both Red and Red/System are published under [BSD](http://www.opensource.org/licenses/bsd-3-clause) license, runtime is under [BSL](http://www.boost.org/users/license.html) license. BSL is a bit more permissive license than BSD, more suitable for the runtime parts.
