Curses library for Red/System
------------------------

This is a low level binding for Curses library.

Requirements
------------

*   **Linux**

    *libncurses 5.9* : avaliable with your favorite distro.

*   **Windows**

    *pdcurses.dll* :  [Public Domain Curses for windows](http://sourceforge.net/projects/pdcurses/files/), version 3.4 : [pdc34dllw.zip](http://sourceforge.net/projects/pdcurses/files/pdcurses/3.4/pdc34dllw.zip/download)

*   **MacOSX**

    Help needed to check the right library name, write `%curses-macosx.reds` (may be identical to `%curses-linux.reds`) and test.

Running the Red/System curses-example
------------------------

1. From the REBOL console type :

    `change-dir %red-system`

    `do/args %rsc.r "%library/curses/examples/curses-example.reds"`, the compilation process should finish with a `...output file size` message.

1. From command line, use the REBOL compilation script :

    `cd red-system/library/builds/curses/examples`

    `rebol -s compile-curses-example.r`  Linux

    or

    `rebol.exe -s compile-curses-example.r`  Windows


1. The resulting binary is in `red-system/builds/`, go try it!

    Linux users run `curses-example` from command line.

    Windows users need to open a DOS console and run `curses-example.exe` from there.

