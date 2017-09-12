Red/System [
	Title:   "Red/System testdynamic link library"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %test-dll2.reds
	Rights:  "Copyright (C) 2012-2015 Nenad Rakoceivc & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

neg: func [
	i 				[integer!]
	return:			[integer!]
][
	i: i * -1
	i
]


negf: func [
	f				[float!]
	return:			[float!]
][
	f: f * -1.0
	f
]

negf32: func [
	f32				[float32!]
	return:			[float32!]
][
	f32: f32 * (as float32! -1.0)
	f32
]

true-false: func [
	l				[logic!]
	return: 		[logic!]
][
	either l [l: false] [l: true]
	l
]

odd-or-even: func [
	s				[c-string!]
	return:			[c-string!]
	/local
		len			[integer!]
		answer		[c-string!]
][
	len: length? s
	either 0 = (len % 2) [answer: "even"][answer: "odd"]
	answer	
]

;callbacki: func [
;	i				[integer!]
;	f				[function! [i [integer!]]]
;][
;	f i	
;]
	
#export [neg negf negf32 true-false odd-or-even]
