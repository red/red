Red/System [
	Title:	"gtk3 Tab-panel widget"
	Author: "bitbegin"
	File: 	%tab-panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


append-tab: func [
	parent		[handle!]
	widget		[handle!]
	return:		[logic!]
	/local
		index	[integer!]
		values	[red-value!]
		data	[red-block!]
		pane	[red-block!]
		str		[red-string!]
		face	[red-object!]
		tail	[red-object!]
		child	[red-object!]
		len		[integer!]
		title	[c-string!]
		label	[handle!]
][
	values: get-face-values parent
	data: as red-block! values + FACE_OBJ_DATA
	pane: as red-block! values + FACE_OBJ_PANE
	if all [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(pane) = TYPE_BLOCK
	][
		child: get-face-obj widget
		face: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		index: 0
		while [face < tail][
			if face/ctx = child/ctx [
				if index < block/rs-length? data [
					str: as red-string! block/rs-abs-at data index
					if TYPE_OF(str) = TYPE_STRING [
						len: -1
						title: unicode/to-utf8 str :len
						label: gtk_label_new title
						gtk_notebook_insert_page parent widget label index
						return true
					]
				]
			]
			index: index + 1
			face: face + 1
		]
	]
	false
]

select-tab: func [
	widget		[handle!]
	int			[red-integer!]
	/local
		nb		[integer!]
		idx		[integer!]
][
	nb: gtk_notebook_get_n_pages widget
	idx: int/value
	if any [idx < 1 idx > nb][exit]

	gtk_notebook_set_current_page widget idx - 1
]

insert-tab: func [
	parent		[handle!]
	str			[red-string!]
	index		[integer!]
	/local
		widget	[handle!]
		len		[integer!]
		title	[c-string!]
		label	[handle!]
][
	widget: gtk_layout_new null null
	len: -1
	title: unicode/to-utf8 str :len
	label: gtk_label_new title
	gtk_notebook_insert_page parent widget label index
]

remove-tab-page: func [
	widget		[handle!]
	/local
		parent	[handle!]
		page	[handle!]
		nb		[integer!]
		index	[integer!]
][
	unless g_type_check_instance_is_a widget gtk_widget_get_type [exit]
	parent: gtk_widget_get_parent widget
	if all [
		not null? parent
		null <> g_object_get_qdata parent red-face-id
		tab-panel = get-widget-symbol parent
	][
		nb: gtk_notebook_get_n_pages parent
		index: 0
		while [index < nb][
			page: gtk_notebook_get_nth_page parent index
			if page = widget [
				gtk_notebook_remove_page parent index
				exit
			]
			index: index + 1
		]
	]
]

set-tabs: func [
	widget		[handle!]
	facets		[red-value!]
	/local
		data	[red-block!]
		str		[red-string!]
		tail	[red-string!]
		int		[red-integer!]
		nb		[integer!]
		index	[integer!]
		len		[integer!]
		title	[c-string!]
		page	[handle!]
][
	nb: gtk_notebook_get_n_pages widget
	data: as red-block! facets + FACE_OBJ_DATA

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		index: 0
		while [all [str < tail index < nb]][
			if TYPE_OF(str) = TYPE_STRING [
				page: gtk_notebook_get_nth_page widget index
				unless null? page [
					len: -1
					title: unicode/to-utf8 str :len
					gtk_notebook_set_tab_label_text widget page title
				]
				index: index + 1
			]
			str: str + 1
		]
	]

	int: as red-integer! facets + FACE_OBJ_SELECTED
	either TYPE_OF(int) <> TYPE_INTEGER [
		int/header: TYPE_INTEGER
		int/value: 1
	][
		case [
			nb = 0			[int/value: 0]
			int/value < 1	[int/value: 1]
			int/value > nb	[int/value: nb]
			true			[0]
		]
		select-tab widget int
	]
]

update-tabs: func [
	face		[red-object!]
	value		[red-value!]
	sym			[integer!]
	new			[red-value!]
	index		[integer!]
	part		[integer!]
	/local
		widget	[handle!]
		str		[red-string!]
][
	widget: get-face-handle face
	switch TYPE_OF(value) [
		TYPE_BLOCK [
			case [
				any [
					sym = words/_remove/symbol
					sym = words/_take/symbol
					sym = words/_clear/symbol
				][
					ownership/unbind-each as red-block! value index part
					loop part [
						gtk_notebook_remove_page widget index
					]
				]
				any [
					sym = words/_insert/symbol
					sym = words/_poke/symbol
					sym = words/_put/symbol
				][
					str: as red-string! either null? new [
						block/rs-abs-at as red-block! value index
					][
						new
					]
					loop part [
						if sym <> words/_insert/symbol [
							ownership/unbind-each as red-block! value index part
							gtk_notebook_remove_page widget index
						]
						insert-tab widget str index
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			insert-tab widget as red-string! value index
		]
		default [assert false]			;@@ raise a runtime error
	]
]
