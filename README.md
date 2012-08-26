Red Programming Language
------------------------

**Red** is a new programming language strongly inspired by [REBOL](http://rebol.com), but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing a modern support for concurrency and multi-core CPU.

The language is in its early bootstrapping phase. The **Red/System** low-level DSL is the first focus. It is a limited C-level language with a REBOL look'n feel, required to build Red's runtime library. More information on [red-lang.org](http://www.red-lang.org).

Running the Red/System hello script
------------------------
The compiler and linker are currently written in REBOL and can produce Windows, Linux, Syllable, Android and Mac OS X executables. So, for now, a REBOL/Core binary is required to compile Red/System programs. Please follow the instructions for installing the compiler tool-chain:

1. Clone this git repository or download an archive (`Downloads` menu).

1. Download a REBOL interpreter suitable for your OS: [Windows](http://www.rebol.com/downloads/v278/rebol-core-278-3-1.exe), [Linux](http://www.rebol.com/downloads/v278/rebol-core-278-4-2.tar.gz), [Mac OS X](http://www.rebol.com/downloads/v278/rebol-core-278-2-5.tar.gz), [FreeBSD](http://www.rebol.com/downloads/v278/rebol-core-278-7-2.tar.gz), [OpenBSD](http://www.rebol.com/downloads/v278/rebol-core-278-9-4.tar.gz), [Solaris](http://www.rebol.com/downloads/v276/rebol-core-276-10-1.gz)

1. Extract the `rebol` binary, put it in `red-system/` folder, that's all!

1. Let's test it: run `./rebol`, you'll see a `>>` prompt appear. Windows users need to click on the `rebol.exe` file to run it.

1. Type: `do/args %rsc.r "%tests/hello.reds"`, the compilation process should finish with a `...output file size` message.

1. The resulting binary is in `red-system/builds/`, go try it! Windows users need to open a DOS console and run `hello.exe` from there.


The `%rsc.r` script is only a wrapper script around the compiler, for testing purpose. It accepts a `-v <integer!>` option for verbose logs. Try it with:

    >> do/args %rsc.r "-v 5 %tests/hello.reds"

Cross-compilation support
-------------------------

Cross-compilation is easily achieved by using a `-t` command line option followed by a target ID.

Currently supported targets are:

<table>
	<tr><th>Target ID</th><th>Description</th></tr>
	<tr><td><pre>MSDOS</pre></td><td>Windows, x86, console-only applications</td></tr>
	<tr><td><pre>Windows</pre></td><td>Windows, x86, native applications</td></tr>
	<tr><td><pre>Linux</pre></td><td>GNU/Linux, x86</td></tr>
	<tr><td><pre>Linux-ARM</pre></td><td>GNU/Linux, ARMv5</td></tr>
	<tr><td><pre>Darwin</pre></td><td>Mac OS X Intel, console-only applications</td></tr>
	<tr><td><pre>Syllable</pre></td><td><a href="http://web.syllable.org/pages/index.html">Syllable 
	OS</a>, x86 </td></tr>
	<tr><td><pre>Android</pre></td><td>Android, ARMv5</td></tr>
</table>

For example, from Windows, to emit Linux executables:

    >> do/args %rsc.r "-t Linux %tests/hello.reds"

From Linux, to emit Windows console executables:

    >> do/args %rsc.r "-t MSDOS %tests/hello.reds"

License
-------------------------

[BSD](http://www.opensource.org/licenses/bsd-3-clause) license, runtime under [BSL](http://www.boost.org/users/license.html) license. BSL is a bit more permissive license than BSD, so more suitable for the runtime parts.