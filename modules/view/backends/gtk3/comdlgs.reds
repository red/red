Red/System [
	Title:	"Common Dialogs"
	Author: "Xie Qingtian"
	File: 	%comdlgs.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
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
		window	[handle!]
		widget 	[handle!]
		resp	[integer!]
		cstr	[c-string!]
		size	[integer!]
		str		[red-string!]
		ret		[red-value!]
][
	ret: as red-value! none-value
	widget: gtk_file_chooser_dialog_new ["FileChooserDialog" null either dir? [GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER][GTK_FILE_CHOOSER_ACTION_OPEN] "Cancel" 5 "Open" 2 null]
	resp: gtk_dialog_run widget
	if resp = 2 [
		cstr: gtk_file_chooser_get_filename widget 
		size: length? cstr
		str: string/load cstr size UTF-8
 		ret: as red-value! str
		set-type ret TYPE_FILE
	]
	gtk_widget_destroy widget
	; This trick really matters to end the loop when in the red-console 
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