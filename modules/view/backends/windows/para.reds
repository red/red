Red/System [
	Title:	"Windows para object management"
	Author: "Nenad Rakocevic"
	File: 	%para.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

update-area-para: func [
	hWnd	[handle!]
	face	[red-object!]
	/local
		parent [handle!]
		h	   [red-handle!]
][
	parent: GetParent hWnd
	DestroyWindow hWnd
	hWnd: as handle! OS-make-view face as-integer parent

	h: as red-handle! block/rs-head as red-block! (get-face-values hWnd) + FACE_OBJ_STATE
	h/header: TYPE_HANDLE
	h/value:  as-integer hWnd
]

update-para: func [
	face	[red-object!]
	fields	[integer!]
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
	state:	as red-block! values + FACE_OBJ_TYPE
	if TYPE_OF(state) <> TYPE_BLOCK [exit]
	
	type:	as red-word! values + FACE_OBJ_TYPE
	sym:	symbol/resolve type/symbol
	para: 	as red-object! values + FACE_OBJ_PARA
	
	unless TYPE_OF(type) = TYPE_WORD [exit]				;@@ make it an error message
	
	case [
		sym = base [mask: not 002Fh]
		any [
			sym = button
			sym = toggle
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
			mask: not 000040C3h
		]
		true [0]
	]
	hWnd: get-face-handle face
	either sym = area [
		update-area-para hWnd face
		values: object/get-values face
	][
		style: GetWindowLong hWnd GWL_STYLE
		style: style and mask or get-para-flags sym para
		SetWindowLong hWnd GWL_STYLE style
	]
	
	int: as red-integer! (block/rs-head state) + 1
	if TYPE_OF(int) = TYPE_INTEGER [
		int/value: int/value or FACET_FLAG_PARA			;-- set the change flag in bit array
	]
]

get-para-flags: func [
	type	[integer!]
	para	[red-object!]
	return: [integer!]
	/local
		values   [red-value!]
		align    [red-word!]
		bool	 [red-logic!]
		wrap?	 [logic!]
		flags    [integer!]
		left     [integer!]
		center   [integer!]
		right    [integer!]
		top	     [integer!]
		middle   [integer!]
		bottom   [integer!]
		default  [integer!]
		vdefault [integer!]
		h-sym	 [integer!]
		v-sym	 [integer!]
][
	if TYPE_OF(para) <> TYPE_OBJECT [return 0]

	values: object/get-values para
	align:  as red-word! values + PARA_OBJ_ALIGN
	h-sym:  either TYPE_OF(align) = TYPE_WORD [symbol/resolve align/symbol][-1]
	align:  as red-word! values + PARA_OBJ_V-ALIGN
	v-sym:  either TYPE_OF(align) = TYPE_WORD [symbol/resolve align/symbol][-1]
	bool:   as red-logic! values + PARA_OBJ_WRAP?
	
	wrap?:	any [
		TYPE_OF(bool) = TYPE_NONE
		all [TYPE_OF(bool) = TYPE_LOGIC bool/value]
	]
	
	left:	  0
	center:   0
	right:	  0
	top:	  0
	middle:	  0
	bottom:	  0
	default:  0
	vdefault: 0
	flags:	  0
	
	case [
		any [type = base type = rich-text][
			left:	0000h								;-- DT_LEFT
			center: 0001h								;-- DT_CENTER
			right:  0002h								;-- DT_RIGHT
			top:	0000h								;-- DT_TOP
			middle: 0004h								;-- DT_VCENTER
			bottom: 0008h								;-- DT_BOTTOM
			either type = rich-text [default: left vdefault: top][
				default: center vdefault: middle
			]
			if wrap? [flags: DT_WORDBREAK]
		]
		any [
			type = button
			type = toggle
			type = check
			type = radio
		][
			left:	00000100h							;-- BS_LEFT
			center: 00000300h							;-- BS_CENTER
			right:	00000200h							;-- BS_RIGHT
			top:	00000400h							;-- BS_TOP
			middle: 00000C00h							;-- BS_VCENTER
			bottom: 00000800h							;-- BS_BOTTOM

			vdefault: middle
			default: either any [type = button type = toggle][center][left]
		]
		any [
			type = field
			type = area
			type = text
		][
			left:	0000h								;-- ES_LEFT / SS_LEFT
			center: 0001h								;-- ES_CENTER / SS_CENTER
			right:  0002h								;-- ES_RIGHT / SS_RIGHT
			middle: 0200h								;-- SS_CENTERIMAGE
			default: left
			
			unless wrap? [
				flags: either type = text [
					00004000h							;-- SS_ENDELLIPSIS
				][
					00C0h								;-- ES_AUTOHSCROLL or ES_AUTOVSCROLL
				]
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
		true				 [flags: flags or vdefault]
	]
	flags
]