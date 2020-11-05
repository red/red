Red/System [
	Title:	"GTK Menu widget"
	Author: "RCqls, Nenad Rakocevic, Qingtian Xie"
	File: 	%menu.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

menu-x:			0
menu-y:			0

build-menu: func [
	menu	[red-block!]
	hMenu	[handle!]
	target	[handle!]
	return:	[handle!]
	/local
		item		[handle!]
		sub-menu	[handle!]
		value		[red-value!]
		tail		[red-value!]
		next		[red-value!]
		str			[red-string!]
		w			[red-word!]
		v			[handle!]
		len			[integer!]
		title	 	[c-string!]
][
	if TYPE_OF(menu) <> TYPE_BLOCK [return null]

	value: block/rs-head menu
	tail:  block/rs-tail menu

	while [value < tail][
		switch TYPE_OF(value) [
			TYPE_STRING [
				str: as red-string! value
				next: value + 1

				len: -1
				title: unicode/to-utf8 str :len

				item: gtk_menu_item_new_with_label title
				gtk_widget_show item
				gobj_signal_connect(item "activate" :menu-item-activate target)

				if next < tail [
					switch TYPE_OF(next) [
						TYPE_BLOCK [
							sub-menu: gtk_menu_new
							gtk_widget_show sub-menu
							build-menu as red-block! next sub-menu target
							gtk_menu_item_set_submenu item sub-menu
							value: value + 1
						]
						TYPE_WORD [
							w: as red-word! next
							v: as handle! w/symbol
							SET-MENU-KEY(item v)
							value: value + 1
						]
						default [0]
					]
				]
			]
			TYPE_WORD [
				w: as red-word! value
				if w/symbol = --- [
					item: gtk_separator_menu_item_new
				]
			]
			default [0]
		]
		gtk_menu_shell_append hMenu item
		value: value + 1
	]
	hMenu
]

build-context-menu: func [
	widget	[handle!]
	menu	[red-block!]
	/local
		hMenu		[handle!]
][
	;; DEBUG: print ["build menu for " widget lf]
	if TYPE_OF(menu) = TYPE_BLOCK [
		hMenu: gtk_menu_new
		;; DEBUG: print ["hMenu " hMenu lf]
		build-menu menu hMenu widget
		SET-MENU-KEY(widget hMenu)
	]
]

append-context-menu: func [
	menu	[red-block!]
	hMenu	[handle!]
	widget	[handle!]
	/local
		item 	[handle!]
][
	item: gtk_separator_menu_item_new
	gtk_widget_show item
	gtk_menu_shell_append hMenu item
	build-menu menu hMenu widget
]

menu-bar?: func [
	spec	[red-block!]
	type	[integer!]
	return: [logic!]
	/local
		w	[red-word!]
][
	if all [
		TYPE_OF(spec) = TYPE_BLOCK
		not block/rs-tail? spec
		type = window
	][
		w: as red-word! block/rs-head spec
		return not all [
			TYPE_OF(w) = TYPE_WORD
			popup = symbol/resolve w/symbol
		]
	]
	no
]