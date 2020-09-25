Red/System [
	Title:	"Common Dialogs"
	Author: "Xie Qingtian, RCqls"
	File: 	%comdlgs.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

request-file-double-clicked: func [
	[cdecl]
	widget	[handle!]
	ctx		[node!]
][
	gtk_dialog_response widget GTK_RESPONSE_ACCEPT
]

_request-file: func [
	title		[red-string!]
	path		[red-file!]
	filter		[red-block!]
	save?		[logic!]
	multi?		[logic!]
	dir?		[logic!]
	return:		[red-value!]
	/local
		widget 	[handle!]
		window	[handle!]
		new?	[logic!]
		resp	[integer!]
		cstr	[c-string!]
		size	[integer!]
		str		[red-string!]
		ret		[red-value!]
][
	ret: as red-value! none-value
	widget: gtk_file_chooser_dialog_new [
		"FileChooserDialog"
		null
		either dir? [GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER][GTK_FILE_CHOOSER_ACTION_OPEN]
		"Cancel"
		GTK_RESPONSE_CANCEL
		"Open"
		GTK_RESPONSE_ACCEPT
		null
	]
	gobj_signal_connect(widget "file-activated" :request-file-double-clicked null)
	window: find-active-window
	new?: false
	if null? window [
		window: gtk_window_new 0
		gtk_widget_hide window
		new?: true
	]
	gtk_window_set_transient_for widget window
	resp: gtk_dialog_run widget
	if resp = GTK_RESPONSE_ACCEPT [
		cstr: gtk_file_chooser_get_filename widget
		size: length? cstr
		str: string/load cstr size UTF-8
		if dir? [string/append-char GET_BUFFER(str) as-integer #"/"]
 		ret: as red-value! str
		set-type ret TYPE_FILE
	]
	gtk_widget_destroy widget
	if new? [
		gtk_widget_destroy window
	]
	while [gtk_events_pending][gtk_main_iteration]
	ret
]

OS-request-dir: func [
	title	[red-string!]
	dir		[red-file!]
	filter	[red-block!]
	keep?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	_request-file title dir filter keep? multi? yes
]

OS-request-file: func [
	title	[red-string!]
	name	[red-file!]
	filter	[red-block!]
	save?	[logic!]
	multi?	[logic!]
	return: [red-value!]
][
	_request-file title name filter save? multi? no
]

OS-request-font: func [
	font		[red-object!]
	selected	[red-object!]
	mono?		[logic!]
	return:		[red-object!]
	/local
		widget	[handle!]
		window	[handle!]
		new?	[logic!]
		fd		[handle!]
		resp	[integer!]
		cstr	[c-string!]
		size	[integer!]
		values	[red-value!]
		str		[red-string!]
		style	[red-block!]
		bold?	[logic!]
][
	widget: gtk_font_chooser_dialog_new "Font" null
	if TYPE_OF(selected) = TYPE_OBJECT [
		fd: create-pango-font selected
		gtk_font_chooser_set_font_desc widget fd
		free-pango-font fd
	]
	window: find-active-window
	new?: false
	if null? window [
		window: gtk_window_new 0
		gtk_widget_hide window
		new?: true
	]
	gtk_window_set_transient_for widget window
	resp: gtk_dialog_run widget
	either resp = -5 [
		fd: gtk_font_chooser_get_font_desc widget
		cstr: pango_font_description_get_family fd
		size: length? cstr
		values: object/get-values font
		str: string/make-at values + FONT_OBJ_NAME size Latin1
		unicode/load-utf8-stream cstr size str null

		size: pango_font_description_get_size fd
		integer/make-at values + FONT_OBJ_SIZE size / PANGO_SCALE

		style: as red-block! values + FONT_OBJ_STYLE
		bold?: no
		if PANGO_WEIGHT_NORMAL < pango_font_description_get_weight fd [
			word/make-at _bold as red-value! style
			bold?: yes
		]
		if PANGO_STYLE_ITALIC = pango_font_description_get_style fd [
			either bold? [
				block/make-at style 4
				word/push-in _bold style
				word/push-in _italic style
			][
				word/make-at _italic as red-value! style
			]
		]
	][
		font/header: TYPE_NONE
	]
	gtk_widget_destroy widget
	if new? [
		gtk_widget_destroy window
	]
	; This trick really matters to end the loop when in the red-console
	while [gtk_events_pending][gtk_main_iteration]

	font
]