Red/System [
	Title:	"Cocoa para object management"
	Author: "Qingtian Xie"
	File: 	%para.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

update-para: func [
	face	[red-object!]
	flags	[integer!]
	/local
		para   [red-object!]
		type   [red-word!]
		state  [red-block!]
		int	   [red-integer!]
		values [red-value!]
		hWnd   [handle!]
		sym	   [integer!]
		style  [integer!]
		mask   [integer!]
][
	values: object/get-values face
	type:	as red-word! values + FACE_OBJ_TYPE
	sym:	symbol/resolve type/symbol
	para: 	as red-object! values + FACE_OBJ_PARA
	
	unless TYPE_OF(type) = TYPE_WORD [exit]				;@@ make it an error message
	
	case [
		sym = base [mask: not 002Fh]
		any [
			sym = button
			sym = check
			sym = radio
		][
			mask: not 00000F00h
		]
		any [
			sym = field
			sym = area
			sym = text
		][
			mask: not 00004003h
		]
		true [0]
	]
	
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
	
	left:	 0
	center:  0
	right:	 0
	top:	 0
	middle:	 0
	bottom:	 0
	default: 0
	flags:	 0
	
	case [
		type = base [
			left:	0000h								;-- DT_LEFT
			center: 0001h								;-- DT_CENTER
			right:  0002h								;-- DT_RIGHT
			top:	0000h								;-- DT_TOP
			middle: 0004h								;-- DT_VCENTER
			bottom: 0008h								;-- DT_BOTTOM
			default: center
			
			unless wrap? [flags: 00000020h]				;-- DT_SINGLELINE
		]
		any [
			type = button
			type = check
			type = radio
		][
			left:	00000100h							;-- BS_LEFT
			center: 00000300h							;-- BS_CENTER
			right:	00000200h							;-- BS_RIGHT
			top:	00000400h							;-- BS_TOP
			middle: 00000C00h							;-- BS_VCENTER
			bottom: 00000800h							;-- BS_BOTTOM
			
			default: either type = button [center][left]
		]
		any [
			type = field
			type = area
			type = text
		][
			left:	0000h								;-- ES_LEFT / SS_LEFT
			center: 0001h								;-- ES_CENTER / SS_CENTER
			right:  0002h								;-- ES_RIGHT / SS_RIGHT
			default: left
			
			if all [not wrap? type = text][
				flags: 00004000h						;-- SS_ENDELLIPSIS
			]
		]
		true [0]
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