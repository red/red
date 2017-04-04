Red/System [
	Title:	"macOS Menu widget"
	Author: "Qingtian Xie"
	File: 	%menu.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

red-menu-action: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		id	[integer!]
][
	id: objc_msgSend [sender sel_getUid "tag"]
	make-event self id EVT_MENU
]

create-main-menu: func [
	/local
		app-name	[integer!]
		empty-str	[integer!]
		item		[integer!]
		title		[integer!]
		main-menu	[integer!]
		apple-menu	[integer!]
		srv-menu	[integer!]
		app-item	[integer!]
][
	empty-str: NSString("")
	main-menu: objc_msgSend [objc_getClass "NSMenu" sel_getUid "alloc"]
	main-menu: objc_msgSend [main-menu sel_getUid "initWithTitle:" NSString("NSAppleMenu")]
	
	apple-menu: objc_msgSend [objc_getClass "NSMenu" sel_getUid "alloc"]
	apple-menu: objc_msgSend [apple-menu sel_getUid "initWithTitle:" NSString("Apple")]
	objc_msgSend [NSApp sel_getUid "setAppleMenu:" apple-menu]

	title: NSString("About %@")
	app-name: NSString("Me")					;@@ TBD change it to real app-name
	title: objc_msgSend [objc_getClass "NSString" sel_getUid "stringWithFormat:" title app-name]
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title sel_getUid "orderFrontStandardAboutPanel:" empty-str
	]
	objc_msgSend [item sel_getUid "setTarget:" NSApp]
	objc_msgSend [apple-menu sel_getUid "addItem:" objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "separatorItem"]]

	title: NSString("Preferences...")
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title 0 NSString(",")
	]
	objc_msgSend [item sel_getUid "setTag:" 42]
	objc_msgSend [apple-menu sel_getUid "addItem:" objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "separatorItem"]]

	title: NSString("Services")
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title 0 empty-str
	]
	srv-menu: objc_msgSend [objc_getClass "NSMenu" sel_getUid "alloc"]
	srv-menu: objc_msgSend [srv-menu sel_getUid "initWithTitle:" empty-str]
	objc_msgSend [apple-menu sel_getUid "setSubmenu:forItem:" srv-menu item]
	objc_msgSend [srv-menu sel_getUid "release"]
	objc_msgSend [NSApp sel_getUid "setServicesMenu:" srv-menu]
	objc_msgSend [apple-menu sel_getUid "addItem:" objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "separatorItem"]]

	title: NSString("Hide %@")
	app-name: NSString("Me")					;@@ TBD change it to real app-name
	title: objc_msgSend [objc_getClass "NSString" sel_getUid "stringWithFormat:" title app-name]
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title sel_getUid "hide:" NSString("h")
	]
	objc_msgSend [item sel_getUid "setTarget:" NSApp]

	title: NSString("Hide Others")
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title sel_getUid "hideOtherApplications:" NSString("h")
	]
	objc_msgSend [item sel_getUid "setKeyEquivalentModifierMask:" NSCommandKeyMask or NSAlternateKeyMask]
	objc_msgSend [item sel_getUid "setTarget:" NSApp]

	title: NSString("Show All")
	item: objc_msgSend [
		apple-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		title sel_getUid "unhideAllApplications:" empty-str
	]
	objc_msgSend [item sel_getUid "setTarget:" NSApp]
	objc_msgSend [apple-menu sel_getUid "addItem:" objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "separatorItem"]]

	app-item: objc_msgSend [
		main-menu sel_getUid "addItemWithTitle:action:keyEquivalent:"
		empty-str 0 empty-str
	]
	objc_msgSend [main-menu sel_getUid "setSubmenu:forItem:" apple-menu app-item]
	objc_msgSend [apple-menu sel_getUid "release"]
	objc_msgSend [NSApp sel_getUid "setMainMenu:" main-menu]
	objc_msgSend [main-menu sel_getUid "release"]
]

build-menu: func [
	menu	[red-block!]
	hMenu	[integer!]
	target	[integer!]
	return: [integer!]
	/local
		item	 [integer!]
		sub-menu [integer!]
		value	 [red-value!]
		tail	 [red-value!]
		next	 [red-value!]
		str		 [red-string!]
		w		 [red-word!]
		title	 [integer!]
		key		 [integer!]
		action	 [integer!]
][
	if TYPE_OF(menu) <> TYPE_BLOCK [return null] 

	value: block/rs-head menu
	tail:  block/rs-tail menu

	key: NSString("")
	action: sel_getUid "red-menu-action:"
	while [value < tail][
		switch TYPE_OF(value) [
			TYPE_STRING [
				str: as red-string! value
				next: value + 1

				title: to-NSString str
				item: objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "alloc"]
				item: objc_msgSend [
					item sel_getUid "initWithTitle:action:keyEquivalent:"
					title 0 key
				]
				objc_msgSend [item sel_getUid "setTarget:" target]
				if next < tail [
					switch TYPE_OF(next) [
						TYPE_BLOCK [
							sub-menu: objc_msgSend [objc_getClass "NSMenu" sel_getUid "alloc"]
							sub-menu: objc_msgSend [sub-menu sel_getUid "initWithTitle:" title]
							build-menu as red-block! next sub-menu
							objc_msgSend [item sel_getUid "setSubmenu:" sub-menu]
							value: value + 1
						]
						TYPE_WORD [
							w: as red-word! next
							objc_msgSend [item sel_getUid "setTag:" w/symbol]
							objc_msgSend [item sel_getUid "setAction:" action]
							value: value + 1
						]
						default [0]
					]
				]
			]
			TYPE_WORD [
				w: as red-word! value
				if w/symbol = --- [
					item: objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "separatorItem"]
				]
			]
			default [0]
		]
		objc_msgSend [hMenu sel_getUid "addItem:" item]
		value: value + 1
	]
	hMenu
]

set-context-menu: func [
	obj		[integer!]
	menu	[red-block!]
	/local
		hMenu		[integer!]
		empty-str	[integer!]
][
	empty-str: NSString("")
	hMenu: objc_msgSend [objc_getClass "NSMenu" sel_getUid "alloc"]
	hMenu: objc_msgSend [hMenu sel_getUid "initWithTitle:" empty-str]
	build-menu menu hMenu obj
	objc_msgSend [obj sel_getUid "setMenu:" hMenu]
	objc_msgSend [hMenu sel_getUid "release"]
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