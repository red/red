Red/System [
	Title:	"Windows fonts management"
	Author: "Xie Qingtian"
	File: 	%font.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

OS-make-font: func [
	font		[red-object!]
	return:		[handle!]
][
	null
]

get-font-handle: func [
	font	[red-object!]
	return: [handle!]
	/local
		handle [red-handle!]
][
	handle: as red-handle! (object/get-values font) + FONT_OBJ_STATE
	if TYPE_OF(handle) = TYPE_HANDLE [
		return as handle! handle/value
	]
	null
]

free-font: func [
	font [red-object!]
	/local
		state [red-block!]
		handle [handle!]
][
	handle: get-font-handle font
	;TODO free handle
	state: as red-block! (object/get-values font) + FONT_OBJ_STATE
	state/header: TYPE_NONE
]

OS-request-font: func [
	font	 [red-object!]
	selected [red-object!]
	mono?	 [logic!]
	return:  [red-object!]
][
	font
]

get-font-color: func [
	font	[red-object!]
	return: [integer!]
	/local
		clr [red-tuple!]
][
	clr: as red-tuple! (object/get-values font) + FONT_OBJ_COLOR
	either TYPE_OF(clr) = TYPE_TUPLE [
		get-tuple-color clr
	][0]
]