Red/System [
	Title:	"gtk3 text-list widget"
	Author: "bitbegin"
	File: 	%text-list.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

select-text-list: func [
	widget		[handle!]
	int			[integer!]
	return:		[logic!]
	/local
		item	[handle!]
][
	either int < 0 [
		gtk_list_box_unselect_all widget
		false
	][
		item: gtk_list_box_get_row_at_index widget int
		either null? item [
			gtk_list_box_unselect_all widget
			false
		][
			gtk_list_box_select_row widget item
			gtk_widget_grab_focus item					;-- scroll the row into view (GtkScrolledWindow scroll-to-focus)
			true
		]
	]
]

init-text-list: func [
	widget		[handle!]
	data		[red-block!]
	selected	[red-integer!]
	/local
		str		[red-string!]
		tail	[red-string!]
		val		[c-string!]
		len		[integer!]
		label	[handle!]
		type	[integer!]
		idx		[integer!]
][
	if any [
		TYPE_OF(data) = TYPE_BLOCK
		TYPE_OF(data) = TYPE_HASH
		TYPE_OF(data) = TYPE_MAP
	][
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data

		while [str < tail][
			type: TYPE_OF(str)
			if ANY_STRING?(type) [
				len: -1
				val: unicode/to-utf8 str :len
				label: gtk_label_new val
				gtk_widget_show label
				gtk_widget_set_halign label 1				;-- GTK_ALIGN_START
				gtk_container_add widget label
			]
			str: str + 1
		]
	]

	either TYPE_OF(selected) = TYPE_INTEGER [
		idx: selected/value - 1
		unless select-text-list widget idx [
			selected/value: -1
		]
	][
		selected/header: TYPE_INTEGER
		selected/value: -1
		select-text-list widget -1
	]
]
