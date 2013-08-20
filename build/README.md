Building Red binaries
------------------------

_Prerequisite_

_You need a [Rebol SDK](http://www.rebol.com/sdk.html) copy with a valid license file in order to rebuild the Red binary, this is a constraint from using Rebol2 for the bootstrapping. Once selfhosted, Red will not have such constraint._

In order to build a Red binary:

1. Place a copy of one of the [encappers](http://www.rebol.com/docs/sdk/kernels.html) ( **enpro** would be a right choice) along with a copy of **license.key** file into the **%build/** folder.

2. Make a copy of **encap-paths.r.sample** file and name it **encap-paths.r**.

3. Edit **encap-paths.r** file and adjust the paths to your Rebol SDK folders.

4. Open a Rebol console, and CD to the **%build/** folder.

        >> change-dir %<path-to-Red>/build/

5. Run the build script from the console:

        >> do %build.r
        
6. After a few seconds, a new **red** binary will be available in the **build/bin/** folder.

7. Enjoy!


Red Command-Line Usage
------------------------

Usage: 

    red [options] [file]

**[file]**

Any Red or Red/System source file. If no file and no option is provided, the REPL will be launched.

**[options]**

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

    MSDOS        : Windows, x86, console-only applications
    Windows      : Windows, x86, native applications
    Linux        : GNU/Linux, x86
    Linux-ARM    : GNU/Linux, ARMv5
    Darwin       : Mac OS X Intel, console-only applications
    Syllable     : Syllable OS, x86
    Android      : Android, ARMv5
    Android-x86	 : Android, x86