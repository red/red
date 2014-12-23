Curses library for Red/System
------------------------

This is a low level binding for Curses and Panel libraries.

Curses for Red/System now uses wide-characters library (libncursesw.so).

Requirements
------------

*   **Linux**

    *libncursesw 5.9* : available with your favorite distro.

    *libpanelw 5.9* : available with your favorite distro.

*   **Windows**

    *pdcurses.dll* :  [Public Domain Curses for windows](http://sourceforge.net/projects/pdcurses/files/), version 3.4 : [pdc34dllu.zip](http://sourceforge.net/projects/pdcurses/files/pdcurses/3.4/pdc34dllu.zip/download)

    The panel library is include in PDCurses.

*   **MacOSX**

    Help needed to check the right library name, write `%curses-macosx.reds` (may be identical to `%curses-linux.reds`) and test.

Running the Red/System curses examples
------------------------

1. This binding is provided with two examples for curses and panel libraries.

1. Compile with Red
    `$ red -c system/library/curses/examples/curses-example.reds`

    `$ red -c system/library/curses/examples/panel-example.reds`

1. From the REBOL console type :

    `do/args %red.r "%system/library/curses/examples/curses-example.reds"`, the compilation process should finish with a `...output file size` message.

    `do/args %red.r "%system/library/curses/examples/panel-example.reds"`, the compilation process should finish with a `...output file size` message.

1. The resulting binaries are in Red main directory, go try them!

    Linux users run `curses-example` or `panel-example` from command line.

    Windows users need to open a DOS console and run `curses-example.exe` or `panel-example.exe` from there.

