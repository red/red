### LibRed tests and demo files

Download `test.xlsm` and `libRed.dll` files and put them in a folder together, then you can run the Excel demos.

The `libRed.dll` precompiled library (using `stdcall` ABI) provided in this folder is required for the `text.xlsm` demo. That Excel file contains three Excel/libRed integration demos:

* **Pong**: shows how to integrate a VBA form with a Red window and handle all events in a common event loop. This demo is optimized for Windows 7, using display font size of 100% and Aero activated. Other Windows settings and versions would need some code tweaking to get the VB form window position and size adjusted (a contributed general solution for that is welcome).

* **Extractor**: shows how to invoke Parse DSL from VBA in order to process a cell text content.

* **Console**: simple Red console made from Excel cells, shows how to create VBA callbacks in Red.

The `test.c` file just contains some raw tests for libRed integration with C language. It requires a libRed binary compiled using `cdecl` ABI (using `red build libRed` command-line), it cannot run properly with the provided `libRed.dll` file (which is compiled for `stdcall` ABI).

