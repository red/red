Red/System [
	Title:   "Red/System testdynamic link library"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %dll-test.reds
	Rights:  "Copyright (C) 2012 Nenad Rakoceivc & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

i: 56
add-one: func [a [integer!] return: [integer!]][a + 1]

#export [add-one i]
