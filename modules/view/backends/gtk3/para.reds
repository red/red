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
	sym			[integer!]
	return:		[logic!]
	/local
		para	[red-object!]
		pvalues	[red-value!]
		wrap?	[logic!]
		hsym	[integer!]
		vsym	[integer!]
		label	[handle!]
][
	para: as red-object! values + FACE_OBJ_PARA
	either TYPE_OF(para) = TYPE_OBJECT [
		pvalues: object/get-values para
		wrap?: get-para-wrap pvalues
		hsym: get-para-hsym pvalues
		vsym: get-para-vsym pvalues
	][
		case [
			any [
				sym = button
				sym = toggle
				sym = base
			][
				wrap?: yes
				hsym: _para/middle
				vsym: _para/middle
			]
			true [
				wrap?: yes
				hsym: _para/left
				vsym: _para/middle
			]
		]
	]
	case [
		sym = text [
			set-label-para widget hsym vsym wrap?
		]
		any [
			sym = button
			sym = check
			sym = radio
		][
			label: gtk_bin_get_child widget
			;-- some button maybe have empty label
			if g_type_check_instance_is_a label gtk_label_get_type [
				set-label-para label hsym vsym wrap?
			]
		]
		sym = field [
			set-entry-para widget hsym vsym wrap?
		]
		sym = area [
			set-textview-para widget hsym vsym wrap?
		]
		sym = text-list [
			set-text-list-para widget hsym vsym wrap?
		]
		true [0]
	]
	yes
]

set-label-para: func [
	label		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
	/local
		f		[float32!]
][
	case [
		hsym = _para/left [
			f: as float32! 0.0
		]
		hsym = _para/right [
			f: as float32! 1.0
		]
		true [
			f: as float32! 0.5
		]
	]
	gtk_label_set_xalign label f
	case [
		vsym = _para/top [
			f: as float32! 0.0
		]
		vsym = _para/bottom [
			f: as float32! 1.0
		]
		true [
			f: as float32! 0.5
		]
	]
	gtk_label_set_yalign label f
	gtk_label_set_line_wrap label wrap?
]

set-entry-para: func [
	entry		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
	/local
		f		[float32!]
][
	case [
		hsym = _para/left [
			f: as float32! 0.0
		]
		hsym = _para/right [
			f: as float32! 1.0
		]
		true [
			f: as float32! 0.5
		]
	]
	gtk_entry_set_alignment entry f
]

set-textview-para: func [
	widget		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
][
	case [
		hsym = _para/left [
			gtk_text_view_set_justification widget GTK_JUSTIFY_LEFT
		]
		hsym = _para/right [
			gtk_text_view_set_justification widget GTK_JUSTIFY_RIGHT
		]
		true [
			gtk_text_view_set_justification widget GTK_JUSTIFY_CENTER
		]
	]

	gtk_text_view_set_wrap_mode widget
		either wrap? [GTK_WRAP_WORD][GTK_WRAP_NONE]
]

set-text-list-para: func [
	widget		[handle!]
	hsym		[integer!]
	vsym		[integer!]
	wrap?		[logic!]
	/local
		list	[GList!]
		child	[GList!]
		label	[handle!]
][
	list: gtk_container_get_children widget
	child: list
	while [not null? child][
		label: gtk_bin_get_child child/data
		set-label-para label hsym vsym wrap?
		child: child/next
	]
	unless null? list [
		g_list_free list
	]
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
