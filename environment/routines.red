Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %routines.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


cos: routine [
	"Returns the trigonometric cosine"
	angle [float!] "Angle in radians"
][
	natives/cosine* no 1
]

sin: routine [
	"Returns the trigonometric sine"
	angle [float!] "Angle in radians"
][
	natives/sine* no 1
]

tan: routine [
	"Returns the trigonometric tangent"
	angle [float!] "Angle in radians"
][
	natives/tangent* no 1
]

acos: routine [
	"Returns the trigonometric arccosine"
	angle [float!] "Angle in radians"
][
	natives/arccosine* no 1
]

asin: routine [
	"Returns the trigonometric arcsine"
	angle [float!] "Angle in radians"
][
	natives/arcsine* no 1
]

atan: routine [
	"Returns the trigonometric arctangent"
	angle [float!] "Angle in radians"
][
	natives/arctangent* no 1
]

quit-return: routine [
	"Stops evaluation and exits the program with a given status"
	status			[integer!] "Process termination value to return"
][
	quit status
]

set-quiet: routine [
	"Set an object's field to a value without triggering object's events"
	word  [word!]
	value [any-type!]
][
	_context/set word stack/arguments + 1
]

;-- Following definitions are used to create op! corresponding operators
shift-right:   routine [data [integer!] bits [integer!]][natives/shift* no -1 -1]
shift-left:	   routine [data [integer!] bits [integer!]][natives/shift* no 1 -1]
shift-logical: routine [data [integer!] bits [integer!]][natives/shift* no -1 1]

;-- Helping routine for console, returns true if last output character was a LF
last-lf?: routine [/local bool [red-logic!]][
	bool: as red-logic! stack/arguments
	bool/header: TYPE_LOGIC
	bool/value:	 natives/last-lf?
]

get-current-dir: routine [][
	stack/set-last as red-value! file/get-current-dir
]

set-current-dir: routine [path [string!] /local dir [red-file!]][
	dir: as red-file! stack/arguments
	unless platform/set-current-dir file/to-OS-path dir [
		fire [TO_ERROR(access cannot-open) dir]
	]
]

create-dir: routine [path [file!]][			;@@ temporary, user should use `make-dir`
	simple-io/make-dir file/to-OS-path path
]

exists?: routine [path [file!] return: [logic!]][
	simple-io/file-exists? file/to-OS-path path
]

as-color: routine [
	r [integer!]
	g [integer!]
	b [integer!]
	/local
		arr1 [integer!]
][
	arr1: (b << 16) or (g << 8) or r
	stack/set-last as red-value! tuple/push 3 arr1 0 0
]

as-ipv4: routine [
	a [integer!]
	b [integer!]
	c [integer!]
	d [integer!]
	/local
		arr1 [integer!]
][
	arr1: (d << 24) or (c << 16) or (b << 8) or a
	stack/set-last as red-value! tuple/push 4 arr1 0 0
]

as-rgba: :as-ipv4