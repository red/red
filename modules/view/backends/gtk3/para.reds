Red/System [
	Title:	"GTK3 para object management"
	Author: "Qingtian Xie, RCqls"
	File: 	%para.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

change-para: func [
	widget		[handle!]
	face		[red-object!]
	values		[red-value!]
	return:		[logic!]
	/local
		para	[red-object!]
][
	para: as red-object! values + FACE_OBJ_PARA
	if TYPE_OF(para) <> TYPE_OBJECT [return no]
	set-font widget face values
	yes
]

update-para: func [
	face		[red-object!]
	fields		[integer!]
	/local
		values	[red-value!]
		type	[red-word!]
		state	[red-block!]
		int		[red-integer!]
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

get-para-wrap: func [
	values		[red-value!]
	return:		[logic!]
	/local
		bool	[red-logic!]
][
	bool: as red-logic! values + PARA_OBJ_WRAP?
	any [
		TYPE_OF(bool) = TYPE_NONE
		all [TYPE_OF(bool) = TYPE_LOGIC bool/value]
	]
]

get-para-hsym: func [
	values		[red-value!]
	return:		[integer!]
	/local
		align	[red-word!]
][
	align: as red-word! values + PARA_OBJ_ALIGN
	if TYPE_OF(align) = TYPE_NONE [return _para/left]
	symbol/resolve align/symbol
]

get-para-vsym: func [
	values		[red-value!]
	return:		[integer!]
	/local
		align	[red-word!]
][
	align: as red-word! values + PARA_OBJ_V-ALIGN
	if TYPE_OF(align) = TYPE_NONE [return _para/middle]
	symbol/resolve align/symbol
]
