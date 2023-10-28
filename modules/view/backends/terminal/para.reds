Red/System [
	Title:	"Face/para utils"
	Author: "Xie Qingtian"
	File: 	%para.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
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
	para	[red-object!]
	return: [integer!]
	/local
		values  [red-value!]
		align   [red-word!]
		bool	[red-logic!]
		flags   [integer!]
		left    [integer!]
		center  [integer!]
		right   [integer!]
		top	    [integer!]
		middle  [integer!]
		bottom  [integer!]
		h-sym	[integer!]
		v-sym	[integer!]
][
	values: object/get-values para
	align:  as red-word! values + PARA_OBJ_ALIGN
	h-sym:  either TYPE_OF(align) = TYPE_WORD [symbol/resolve align/symbol][-1]
	align:  as red-word! values + PARA_OBJ_V-ALIGN
	v-sym:  either TYPE_OF(align) = TYPE_WORD [symbol/resolve align/symbol][-1]
	bool:   as red-logic! values + PARA_OBJ_WRAP?
	
	flags:	0
	if all [TYPE_OF(bool) = TYPE_LOGIC bool/value][flags: TEXT_WRAP_FLAG]

	case [
		h-sym = _para/left	 [flags: flags or TEXT_ALIGN_LEFT]
		h-sym = _para/center [flags: flags or TEXT_ALIGN_CENTER]
		h-sym = _para/right	 [flags: flags or TEXT_ALIGN_RIGHT]
		true				 [0]
	]
	case [
		v-sym = _para/top	 [flags: flags or TEXT_ALIGN_TOP]
		v-sym = _para/middle [flags: flags or TEXT_ALIGN_VCENTER]
		v-sym = _para/bottom [flags: flags or TEXT_ALIGN_BOTTOM]
		true				 [0]
	]
	flags
]