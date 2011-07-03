Red Programming Language
------------------------

**Red** is a new programming language strongly inspired by [REBOL](http://rebol.com), but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing a modern support for concurrency and multi-core CPU.

The language is in its early bootstrapping phase. The **Red/System** low-level DSL is the first focus. It is a limited C-level language with a REBOL look'n feel, required to build Red's runtime library. More information on [red-lang.org](http://www.red-lang.org).

Running the Hello script
------------------------
The compiler and linker are currently written in REBOL and produce PE (Windows) or ELF (Linux) executables. So, for now, a REBOL/Core binary is required to run them. Follow the instructions:

1. Download a REBOL interpreter suitable for your OS: [Windows](http://www.rebol.com/downloads/v278/rebol-core-278-3-1.exe), [Linux](http://www.rebol.com/downloads/v278/rebol-core-278-4-2.tar.gz), [Mac OS X](http://www.rebol.com/downloads/v278/rebol-core-278-2-5.tar.gz), [FreeBSD](http://www.rebol.com/downloads/v278/rebol-core-278-7-2.tar.gz), [OpenBSD](http://www.rebol.com/downloads/v278/rebol-core-278-9-4.tar.gz), [Solaris](http://www.rebol.com/downloads/v276/rebol-core-276-10-1.gz)

1. Extract the `rebol` binary, put it in `red-system/` folder and run it, you'll see a `>>` prompt appear

1. Type: `do/args %rsc.r "%tests/hello.reds"`

1. The resulting binary is in `red-system/builds/`. Windows users need to open a DOS console and run `hello.exe` from there.

The `%rsc.r` script is only a wrapper script around the compiler, for testing purpose. It accepts a `-v <integer!>` option for verbose logs. Try it with:

    >> do/args %rsc.r "-v 5 %tests/hello.reds"

Cross-compilation support
-------------------------

Cross-compilation is easily achieved by using a `-t` command line option followed by a target ID.

Currently supported targets are:

<table>
	<tr><th>Target ID</th><th>Description</th></tr>
	<tr><td><pre>MSDOS</pre></td><td>Windows x86, console-only applications</td></tr>
	<tr><td><pre>WinGUI</pre></td><td>Windows x86, native applications</td></tr>
	<tr><td><pre>Linux</pre></td><td>GNU/Linux x86 platform</td></tr>
	<tr><td><pre>Syllable</pre></td><td><a href="http://web.syllable.org/pages/index.html">Syllable OS</a> x86 platform</td></tr>
</table>
<i>Mac OS X support is pending.</i>

For example, from Windows, to emit Linux executables:

    >> do/args %rsc.r "-t Linux %tests/hello.reds"

From Linux, to emit Windows console executables:

    >> do/args %rsc.r "-t MSDOS %tests/hello.reds"
