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
		data	[red-block!]
		str		[red-string!]
		len		[integer!]
		title	[c-string!]
		label	[handle!]
][
	index: gtk_notebook_get_n_pages parent
	data: get-widget-data parent
	if TYPE_OF(data) = TYPE_BLOCK [
		str: as red-string! block/rs-abs-at data index
		len: -1
		title: unicode/to-utf8 str :len
		label: gtk_label_new title
		gtk_notebook_insert_page parent widget label index
		return true
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

set-tabs: func [
	widget		[handle!]
	facets		[red-value!]
	/local
		data	[red-block!]
		pane	[red-block!]
		str		[red-string!]
		tail	[red-string!]
		int		[red-integer!]
		nb		[integer!]
		len		[integer!]
		title	[c-string!]
		panel	[handle!]
		label	[handle!]
		face	[red-object!]
		end		[red-object!]
][
	nb: gtk_notebook_get_n_pages widget
	loop nb [							;-- remove all tabs
		gtk_notebook_remove_page widget -1
	]

	data: as red-block! facets + FACE_OBJ_DATA
	pane: as red-block! facets + FACE_OBJ_PANE

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		face: as red-object! block/rs-head pane
		end:  as red-object! block/rs-tail pane
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				if face < end [
					len: -1
					title: unicode/to-utf8 str :len
					label: gtk_label_new title
					panel: get-face-handle face
					gtk_notebook_append_page widget panel label
					face: face + 1
				]
			]
			str: str + 1
		]
	]
	int: as red-integer! facets + FACE_OBJ_SELECTED

	either TYPE_OF(int) <> TYPE_INTEGER [
		int/header: TYPE_INTEGER		;-- force selection on first tab
		int/value:  1
	][
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
						gtk_notebook_remove_page widget index - 1
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
							gtk_notebook_remove_page widget index - 1
						]
						;insert-tab widget str index
						str: str + 1
					]
				]
				true [0]
			]
		]
		TYPE_STRING [
			0
		]
		default [assert false]			;@@ raise a runtime error
	]
]
