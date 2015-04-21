Red [
	Title:   "Red base environment definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %routines.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
