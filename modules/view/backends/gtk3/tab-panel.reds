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
		item	[integer!]
		len		[integer!]
		title	[c-string!]
		label	[handle!]
		panel	[handle!]
		face	[red-object!]
		end		[red-object!]
][
	nb: gtk_notebook_get_n_pages widget
	loop nb [
		gtk_notebook_remove_page widget -1
	]

	data: as red-block! facets + FACE_OBJ_DATA
	pane: as red-block! facets + FACE_OBJ_PANE
	nb: 0

	if TYPE_OF(data) = TYPE_BLOCK [
		str:  as red-string! block/rs-head data
		tail: as red-string! block/rs-tail data
		face: as red-object! block/rs-head pane
		end:  as red-object! block/rs-tail pane
		nb: 0
		while [str < tail][
			if TYPE_OF(str) = TYPE_STRING [
				len: -1
				title: unicode/to-utf8 str :len
				label: gtk_label_new title
				if face < end [
					panel: as handle! get-face-handle face
					gtk_notebook_append_page widget panel label
					face: face + 1
				]
				nb: nb + 1
			]
			str: str + 1
		]
	]
	int: as red-integer! facets + FACE_OBJ_SELECTED

	if TYPE_OF(int) <> TYPE_INTEGER [
		int/header: TYPE_INTEGER						;-- force selection on first tab
		int/value:  1
	]
	gtk_notebook_set_current_page widget int/value
]
