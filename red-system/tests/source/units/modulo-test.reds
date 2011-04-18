Red/System [
	Title:   "Red/System modulo operator (//) test script"
	Author:  "Nenad Rakocevic"
	File: 	 %modulo-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds
qt-start-file "modulo"
qt-assert "mod-1"  10 //  7 = 3
qt-assert "mod-2"   5 //  3 = 2
qt-assert "mod-3"  15 //  8 = 7
qt-assert "mod-4"   2 //  2 = 0
qt-assert "mod-5" -10 // -7 = -3
qt-assert "mod-6" -10 //  7 = -3
qt-assert "mod-7"  10 // -7 = 3
qt-end-file

