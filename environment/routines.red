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
	natives/cosine* 1
]

sin: routine [
	"Returns the trigonometric sine"
	angle [float!] "Angle in radians"
][
	natives/sine* 1
]

tan: routine [
	"Returns the trigonometric tangent"
	angle [float!] "Angle in radians"
][
	natives/tangent* 1
]

acos: routine [
	"Returns the trigonometric arccosine"
	angle [float!] "Angle in radians"
][
	natives/arccosine* 1
]

asin: routine [
	"Returns the trigonometric arcsine"
	angle [float!] "Angle in radians"
][
	natives/arcsine* 1
]

atan: routine [
	"Returns the trigonometric arctangent"
	angle [float!] "Angle in radians"
][
	natives/arctangent* 1
]

quit-return: routine [
	"Stops evaluation and exits the program with a given status"
	status			[integer!] "Process termination value to return"
][
	quit status
]

;-- Following definitions are used to create op! corresponding operators
shift-right:   routine [][natives/shift* -1 -1]
shift-left:	   routine [][natives/shift* 1 -1]
shift-logical: routine [][natives/shift* -1 1]

;-- Helping routine for console, returns true if last output character was a LF
last-lf?: routine [/local bool [red-logic!]][
	bool: as red-logic! stack/arguments
	bool/header: TYPE_LOGIC
	bool/value:	 natives/last-lf?
]

get-current-dir: routine [/local len [integer!] path [c-string!]][
	len: 0
	path: platform/get-current-dir :len
	#either OS = 'Windows [
		stack/set-last as cell! string/load path len UTF-16LE
	][
		stack/set-last as cell! string/load path len UTF-8
	]
	free as byte-ptr! path
]

read-decode: routine [filename [file!]][
	#either OS = 'Windows [
		either TYPE_OF(filename) = TYPE_URL [
			stack/set-last as cell! image/load-binary as red-binary!
				simple-io/request-http HTTP_GET as red-url! filename null null yes no
		][
			image/make-at stack/arguments as red-string! filename
		]
	][
		--NOT_IMPLEMENTED--
	]
]
