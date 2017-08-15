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
	window: gtk_window_new GTKApp
	;print "GTKApp"
	;if GTKApp = (as handle! 0) [print  " not"] 
	;print [" alive" lf]
	widget: gtk_file_chooser_dialog_new ["FileChooserDialog" null either dir? [GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER][GTK_FILE_CHOOSER_ACTION_OPEN] "Cancel" 5 "Open" 2 null]
    ;gtk_application_add_window GTKApp window
	;gtk_window_set_modal widget yes
	;gtk_window_set_transient_for widget window
	;gtk_window_set_destroy_with_parent widget yes
	
	;gobj_signal_connect(widget "response" :dialog-response-clicked null);
	resp: gtk_dialog_run widget
	print ["resp: " resp lf]
	if resp = 2 [
		cstr: gtk_file_chooser_get_filename widget 
		size: length? cstr
		print ["Selected file: " cstr lf]
		str: string/load cstr size UTF-8
        ;unicode/load-utf8-stream cstr size str null
		ret: as red-value! str
		set-type ret TYPE_FILE
	]
	;gtk_window_iconify widget
    ;gtk_application_remove_window GTKApp window
	;gtk_window_close widget
	;gtk_window_close window		
	gtk_widget_destroy widget
	;gtk_widget_destroy window
	;as red-value! none-value
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

dialog-response-clicked: func [
	[cdecl]
	widget	[handle!]
	ctx		[node!]
][
	gtk_widget_destroy widget
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