Red/System [
	Title:	"GTK3 css management"
	Author: "bitbegin"
	File: 	%css.reds
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]


create-provider: func [
	widget		[handle!]
	return:		[handle!]
	/local
		style	[handle!]
		prov	[handle!]
][
	prov:	gtk_css_provider_new
	style:	gtk_widget_get_style_context widget
	gtk_style_context_add_provider style prov GTK_STYLE_PROVIDER_PRIORITY_USER
	prov
]

remove-provider: func [
	widget		[handle!]
	prov		[handle!]
	/local
		style	[handle!]
][
	style:	gtk_widget_get_style_context widget
	gtk_style_context_remove_provider style prov
]

apply-provider: func [
	prov		[handle!]
	css			[c-string!]
][
	gtk_css_provider_load_from_data prov css -1 null
]

free-provider: func [
	prov		[handle!]
][
	g_object_unref prov
]

set-app-theme: func [
	path		[c-string!]
	string?		[logic!]
	/local
		succ	[logic!]
		prov	[handle!]
		disp	[handle!]
		screen	[handle!]
][
	prov: gtk_css_provider_new
	succ: either string? [
		gtk_css_provider_load_from_data prov path -1 null
	][
		gtk_css_provider_load_from_path prov path null
	]
	unless succ [exit]
	disp: gdk_display_get_default
	screen: gdk_display_get_default_screen disp
	gtk_style_context_add_provider_for_screen screen prov GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
	g_object_unref prov
]

set-env-theme: func [
	/local
		env		[str-array!]
		strarr	[handle!]
		str		[c-string!]
		found	[logic!]
][
	env: system/env-vars
	found: no
	until [
		strarr: g_strsplit env/item "=" 2
		str: as c-string! strarr/1
		if 0 = g_strcmp0 str "RED_GTK_STYLES" [
			str: as c-string! strarr/2
			set-app-theme str no
			found: yes
		]
		env: env + 1
		g_strfreev strarr
		any [found env/item = null]
	]
]
