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

set-file-filter: func [
	panel		[integer!]
	filter		[red-string!]
	/local
		sep		[integer!]
		str		[integer!]
		types	[integer!]
		e		[integer!]
		t		[integer!]
		idx		[integer!]
		any1	[integer!]
		any2	[integer!]
		pre1	[integer!]
		pre2	[integer!]
		allowed [integer!]
		s_equal [integer!]
		s_start [integer!]
][
	sep:	NSString(";"  )
	pre1:	NSString("*." )
	pre2:	NSString("."  )
	any1:	NSString("*"  )
	any2:	NSString("*.*")

	str:	to-NSString filter
	types:	objc_msgSend [str sel_getUid "componentsSeparatedByString:" sep]
	allowed: objc_msgSend [
		objc_getClass "NSMutableArray"
		sel_getUid "arrayWithCapacity:"
		objc_msgSend [types sel_getUid "count"]
	]

	s_equal: sel_getUid "isEqualToString:"
	s_start: sel_getUid "hasPrefix:"
	e: objc_msgSend [types sel_getUid "objectEnumerator"]
	while [
		t: objc_msgSend [e sel_getUid "nextObject"]
		t <> 0
	][
		if any [
			0 <> objc_msgSend [t s_equal any1]			;-- "*"
			0 <> objc_msgSend [t s_equal any2]			;-- "*.*"
		][
			objc_msgSend [panel sel_getUid "setAllowedFileTypes:" 0]
			exit
		]
		case [
			0 <> objc_msgSend [t s_start pre1] [		;-- "*."
				idx: 2
			]
			0 <> objc_msgSend [t s_start pre2] [		;-- "."
				idx: 1
			]
			true [idx: 0]
		]
		if idx <> 0 [t: objc_msgSend [t sel_getUid "substringFromIndex:" idx]]
		objc_msgSend [allowed sel_getUid "addObject:" t]
	]

	objc_msgSend [panel sel_getUid "setAllowedFileTypes:" allowed]
]

_request-file: func [
	title	[red-string!]
	path	[red-file!]
	filter	[red-block!]
	save?	[logic!]
	multi?	[logic!]
	dir?	[logic!]
	return: [red-value!]
	/local
		panel	[integer!]
		parent	[integer!]
		dir		[integer!]
		file	[integer!]
		files	[integer!]
		i		[integer!]
		count	[integer!]
		res		[integer!]
		blk		[red-block!]
		str		[red-string!]
][
	either any [dir? not save?][
		panel: objc_msgSend [objc_getClass "NSOpenPanel" sel_getUid "openPanel"]
		if multi? [
			objc_msgSend [panel sel_getUid "setAllowsMultipleSelection:" true]
		]
		if dir? [
			objc_msgSend [panel sel_getUid "setCanChooseFiles:" false]
			objc_msgSend [panel sel_getUid "setCanChooseDirectories:" true]
			objc_msgSend [panel sel_getUid "setTreatsFilePackagesAsDirectories:" true]
		]
	][
		panel: objc_msgSend [objc_getClass "NSSavePanel" sel_getUid "savePanel"]
	]

	if TYPE_OF(title) = TYPE_STRING [
		objc_msgSend [panel sel_getUid "setTitle:" to-NSString title]
	]
	objc_msgSend [panel sel_getUid "setCanCreateDirectories:" true]

	dir: 0
	file: 0
	if TYPE_OF(path) = TYPE_FILE [
		dir: to-NSString path
		if all [
			not dir?
			zero? objc_msgSend [dir sel_getUid "hasSuffix:" NSString("/")]
		][
			dir: objc_msgSend [dir sel_getUid "stringByDeletingLastPathComponent"]
			file: objc_msgSend [dir sel_getUid "lastPathComponent"]
		]
	]

	parent: objc_msgSend [NSApp sel_getUid "mainWindow"]
	if parent <> 0 [
		objc_msgSend [
			NSApp sel_getUid "beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:"
			panel parent 0 0 0
		]
	]
	res: objc_msgSend [panel sel_getUid "runModalForDirectory:file:" dir file]
	if parent <> 0 [
		objc_msgSend [NSApp sel_getUid "endSheet:returnCode:" panel 0]
	]

	either res = 1 [							;-- NSFileHandlingPanelOKButton
		either any [not multi? save?][
			str: to-red-string objc_msgSend [panel sel_getUid "filename"] null
			set-type as red-value! str TYPE_FILE
			if dir? [string/append-char GET_BUFFER(str) as-integer #"/"]
			as red-value! str
		][
			files: objc_msgSend [panel sel_getUid "filenames"]
			count: objc_msgSend [files sel_getUid "count"]
			blk: block/push-only* count
			i: 0
			while [i < count][
				file: objc_msgSend [files sel_getUid "objectAtIndex:" i]
				str: to-red-string file as red-string! ALLOC_TAIL(blk)
				set-type as red-value! str TYPE_FILE
				if dir? [string/append-char GET_BUFFER(str) as-integer #"/"]
				i: i + 1
			]
			as red-value! blk
		]
	][
		as red-value! none-value
	]
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