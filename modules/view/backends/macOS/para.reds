Red/System [
	Title:	"Cocoa para object management"
	Author: "Qingtian Xie"
	File: 	%para.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

change-para: func [
	hWnd	[integer!]
	face	[red-object!]
	para	[red-object!]
	font	[red-object!]
	type	[integer!]
	return: [logic!]
	/local
		flags [integer!]
		cell  [integer!]
][
	if TYPE_OF(para) <> TYPE_OBJECT [return no]

	case [
		any [type = base type = panel][
			objc_msgSend [hWnd sel_getUid "setNeedsDisplay:" yes]
		]
		any [
			type = button
			type = check
			type = radio
			type = field
			type = text
		][
			either TYPE_OF(font) = TYPE_OBJECT [
				change-font hWnd face font type
			][
				flags: get-para-flags type para
				objc_msgSend [hWnd sel_getUid "setAlignment:" flags and 3]
			]
		]
		true [0]
	]
	if any [type = field type = text][
		cell: objc_msgSend [hWnd sel_getUid "cell"]
		objc_msgSend [cell sel_getUid "setWraps:" flags and 20h <> 0]
	]
	yes
]

update-para: func [
	face	[red-object!]
	fields	[integer!]
	/local
		type   [red-word!]
		state  [red-block!]
		int	   [red-integer!]
		values [red-value!]
][
	values: object/get-values face
	type:	as red-word! values + FACE_OBJ_TYPE

	unless TYPE_OF(type) = TYPE_WORD [exit]				;@@ make it an error message
	state: as red-block! values + FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! (block/rs-head state) + 1
		if TYPE_OF(int) = TYPE_INTEGER [
			int/value: int/value or FACET_FLAG_PARA		;-- set the change flag in bit array
		]
	]
]

get-para-flags: func [
	type	[integer!]
	para	[red-object!]
	return: [integer!]
	/local
		values  [red-value!]
		align   [red-word!]
		bool	[red-logic!]
		wrap?	[logic!]
		flags   [integer!]
		left    [integer!]
		center  [integer!]
		right   [integer!]
		top	    [integer!]
		middle  [integer!]
		bottom  [integer!]
		default [integer!]
		h-sym	[integer!]
		v-sym	[integer!]
][
	values: object/get-values para
	align:  as red-word! values + PARA_OBJ_ALIGN
	h-sym:  symbol/resolve align/symbol
	align:  as red-word! values + PARA_OBJ_V-ALIGN
	v-sym:  symbol/resolve align/symbol
	bool:   as red-logic! values + PARA_OBJ_WRAP?
	
	wrap?:	any [
		TYPE_OF(bool) = TYPE_NONE
		all [TYPE_OF(bool) = TYPE_LOGIC not bool/value]
	]

	flags:	0
	left:	0000h								;-- DT_LEFT
	right:  0001h								;-- DT_RIGHT
	center: 0002h								;-- DT_CENTER
	top:	0000h								;-- DT_TOP
	middle: 0004h								;-- DT_VCENTER
	bottom: 0008h								;-- DT_BOTTOM
	
	unless wrap? [flags: 20h]					;-- DT_SINGLELINE
	either any [type = base type = button][
		default: center
	][
		default: left
	]

	case [
		h-sym = _para/left	 [flags: flags or left]
		h-sym = _para/center [flags: flags or center]
		h-sym = _para/right	 [flags: flags or right]
		true				 [flags: flags or default]
	]
	case [
		v-sym = _para/top	 [flags: flags or top]
		v-sym = _para/middle [flags: flags or middle]
		v-sym = _para/bottom [flags: flags or bottom]
		true				 [0]
	]
	flags
]