Red/System [
	Title:   "Red/System testdynamic link library"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %test-dll1.reds
	Rights:  "Copyright (C) 2012-2015 Nenad Rakoceivc & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

i: 56
add-one: func [a [integer!] return: [integer!]][a + 1]

#export [add-one i]
