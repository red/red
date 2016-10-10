Red/System [
	Title:	"GTK3 fonts management"
	Author: "Qingtian Xie"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-font: func [
	face	[red-object!]
	font	[red-object!]
	return: [handle!]
][
	null
]

get-font-handle: func [
	font	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		int	   [red-integer!]
][
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		if TYPE_OF(int) = TYPE_INTEGER [
			return as handle! int/value
		]
	]
	null
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		hFont [handle!]
][
	hFont: get-font-handle font
	if hFont <> null [
		state: as red-block! (object/get-values font) + FONT_OBJ_STATE
		state/header: TYPE_NONE
	]
]

update-font: func [
	font [red-object!]
	flag [integer!]
][
	switch flag [
		FONT_OBJ_NAME
		FONT_OBJ_SIZE
		FONT_OBJ_STYLE
		FONT_OBJ_ANGLE
		FONT_OBJ_ANTI-ALIAS? [
			free-font font
			make-font null font
		]
		default [0]
	]
]

OS-request-font: func [
	font	[red-object!]
	mono?	[logic!]
	return: [red-object!]
][
	font
]