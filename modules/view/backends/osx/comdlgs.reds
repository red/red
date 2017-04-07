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

quit-modal-loop?: no
font-changed?: no

dialog-proc: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	arg0	[integer!]
][
	case [
		cmd = sel_changeFont [
			font-changed?: yes
		]
		cmd = sel_windowWillClose [
			objc_msgSend [NSApp sel_getUid "stopModal"]
		]
		true [0]
	]
]

do-modal-loop: func [
	/local
		state	[integer!]
		pool	[integer!]
		timeout [integer!]
		event	[integer!]
][
	timeout: objc_msgSend [objc_getClass "NSDate" sel_getUid "distantFuture"]
	until [
		pool: objc_msgSend [objc_getClass "NSAutoreleasePool" sel_getUid "alloc"]
		objc_msgSend [pool sel_getUid "init"]

		event: objc_msgSend [
			NSApp sel_getUid "nextEventMatchingMask:untilDate:inMode:dequeue:"
			NSAnyEventMask
			timeout
			NSModalPanelRunLoopMode
			true
		]
		if event <> 0 [objc_msgSend [NSApp sel_getUid "sendEvent:" event]]
		objc_msgSend [pool sel_getUid "drain"]

		quit-modal-loop?
	]
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

filter-filetype-action: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	sender	[integer!]
	/local
		idx		[integer!]
		p-int	[integer!]
		filters [red-block!]
][
	p-int: 0
	object_getInstanceVariable self IVAR_RED_DATA :p-int
	filters: as red-block! p-int
	idx: objc_msgSend [sender sel_getUid "indexOfSelectedItem"]
	set-file-filter self as red-string! (block/rs-head filters) + (idx * 2 + 1)
	objc_msgSend [self sel_getUid "validateVisibleColumns"]
]

request-file-handler: func [
	[cdecl]
	_blk		[int-ptr!]
	result		[integer!]
	/local
		panel	[integer!]
		multi?	[logic!]
		save?	[logic!]
		dir?	[logic!]
		file	[integer!]
		files	[integer!]
		i		[integer!]
		count	[integer!]
		ret		[red-value!]
		blk		[red-block!]
		str		[red-string!]
][
	panel:	_blk/6
	multi?:	as logic! _blk/7
	save?:	as logic! _blk/8
	dir?:	as logic! _blk/9
	ret:	as red-value! _blk/10
	either result = 1 [							;-- NSFileHandlingPanelOKButton
		either any [not multi? save?][
			str: to-red-string objc_msgSend [panel sel_getUid "filename"] ret
			set-type ret TYPE_FILE
			if dir? [string/append-char GET_BUFFER(str) as-integer #"/"]
		][
			files: objc_msgSend [panel sel_getUid "filenames"]
			count: objc_msgSend [files sel_getUid "count"]
			blk: block/make-at as red-block! ret count
			i: 0
			while [i < count][
				file: objc_msgSend [files sel_getUid "objectAtIndex:" i]
				str: to-red-string file ALLOC_TAIL(blk)
				set-type as red-value! str TYPE_FILE
				if dir? [string/append-char GET_BUFFER(str) as-integer #"/"]
				i: i + 1
			]
		]
	][
		set-type ret TYPE_NONE
	]
	quit-modal-loop?: yes
]

setup-filter-button: func [
	panel		[integer!]
	filter		[red-block!]
	/local
		obj		[integer!]
		rc		[NSRect!]
		menu	[integer!]
		head	[red-value!]
		tail	[red-value!]
		str		[red-value!]
		item	[integer!]
		key		[integer!]
		type	[integer!]
][
	object_setInstanceVariable panel IVAR_RED_DATA as-integer filter

	rc: make-rect 0 0 0 0
	obj: objc_msgSend [
		objc_msgSend [objc_getClass "NSPopUpButton" sel_getUid "alloc"]
		sel_getUid "initWithFrame:pullsDown:" rc/x rc/y rc/w rc/h false
	]
	objc_msgSend [obj sel_getUid "setTarget:" panel]
	objc_msgSend [obj sel_getUid "setAction:" sel_getUid "filter-filetype:"]

	menu: objc_msgSend [obj sel_getUid "menu"]
	objc_msgSend [menu sel_getUid "setAutoenablesItems:" false]

	head: block/rs-head filter
	tail: block/rs-tail filter
	key: NSString("")
	until [
		str: head + 1
		if TYPE_OF(head) <> TYPE_STRING [fire [TO_ERROR(script invalid-arg) head]]
		if TYPE_OF(str) <> TYPE_STRING [fire [TO_ERROR(script invalid-arg) str]]

		if 0 <> string/rs-length? as red-string! head [str: head]
		item: objc_msgSend [objc_getClass "NSMenuItem" sel_getUid "alloc"]
		item: objc_msgSend [
			item sel_getUid "initWithTitle:action:keyEquivalent:"
			to-NSString as red-string! str 0 key
		]
		objc_msgSend [menu sel_getUid "addItem:" item]
		objc_msgSend [item sel_release]
		head: head + 2
		head >= tail
	]
	objc_msgSend [obj sel_getUid "selectItemAtIndex:" 0]
	objc_msgSend [obj sel_getUid "sizeToFit"]
	objc_msgSend [panel sel_getUid "setAccessoryView:" obj]

	set-file-filter panel as red-string! (block/rs-head filter) + 1
	objc_msgSend [panel sel_getUid "setAllowsOtherFileTypes:" true]
]

_request-file: func [
	title			[red-string!]
	path			[red-file!]
	filter			[red-block!]
	save?			[logic!]
	multi?			[logic!]
	dir?			[logic!]
	return:			[red-value!]
	/local
		ret			[integer!]
		value4		[integer!]
		value3		[integer!]
		value2		[integer!]
		value1		[integer!]
		descriptor	[integer!]
		invoke		[integer!]
		reserved	[integer!]
		flags		[integer!]
		isa			[integer!]
		panel		[integer!]
		parent		[integer!]
		dir			[integer!]
		res			[integer!]
		exist?		[logic!]
][
	quit-modal-loop?: no
	either any [dir? not save?][
		panel: objc_msgSend [objc_getClass "RedOpenPanel" sel_getUid "openPanel"]
		if multi? [
			objc_msgSend [panel sel_getUid "setAllowsMultipleSelection:" true]
		]
		if dir? [
			objc_msgSend [panel sel_getUid "setCanChooseFiles:" false]
			objc_msgSend [panel sel_getUid "setCanChooseDirectories:" true]
			objc_msgSend [panel sel_getUid "setTreatsFilePackagesAsDirectories:" true]
		]
	][
		panel: objc_msgSend [objc_getClass "RedSavePanel" sel_getUid "savePanel"]
		if TYPE_OF(path) = TYPE_FILE [
			dir: to-NSString path
			if zero? objc_msgSend [dir sel_getUid "hasSuffix:" NSString("/")][
				objc_msgSend [
					panel sel_getUid "setNameFieldStringValue:"
					objc_msgSend [dir sel_getUid "lastPathComponent"]
				]
			]
		]
	]

	objc_msgSend [panel sel_getUid "setDelegate:" panel]

	if TYPE_OF(title) = TYPE_STRING [
		objc_msgSend [panel sel_getUid "setTitle:" to-NSString title]
	]
	objc_msgSend [panel sel_getUid "setCanCreateDirectories:" true]

	if all [
		TYPE_OF(filter) = TYPE_BLOCK
		0 <> block/rs-length? filter
	][
		setup-filter-button panel filter
	]

	if TYPE_OF(path) = TYPE_FILE [
		dir: to-NSString path
		dir: objc_msgSend [dir sel_getUid "stringByExpandingTildeInPath"]
		exist?: 0 <> objc_msgSend [
			objc_msgSend [objc_getClass "NSFileManager" sel_getUid "defaultManager"]
			sel_getUid "fileExistsAtPath:" dir
		]
		if all [
			any [save? not exist?]
			not dir?
			zero? objc_msgSend [dir sel_getUid "hasSuffix:" NSString("/")]
		][
			dir: objc_msgSend [dir sel_getUid "stringByDeletingLastPathComponent"]
		]
		if any [dir? 0 <> objc_msgSend [dir sel_getUid "containsString:" NSString("/")]][
			objc_msgSend [
				panel sel_getUid "setDirectoryURL:"
				objc_msgSend [objc_getClass "NSURL" sel_getUid "fileURLWithPath:" dir]
			]
		]
	]

	objc_block_descriptor/reserved: 0
	objc_block_descriptor/size: 4 * 10

	isa: _NSConcreteStackBlock
	flags: 1 << 29				;-- BLOCK_HAS_DESCRIPTOR, no copy and dispose helpers
	reserved: 0
	invoke: as-integer :request-file-handler
	descriptor: as-integer objc_block_descriptor
	value1: panel
	value2: as-integer multi?
	value3: as-integer save?
	value4: as-integer dir?
	ret:	as-integer stack/push*

	parent: objc_msgSend [NSApp sel_getUid "mainWindow"]
	either parent <> 0 [
		objc_msgSend [
			panel sel_getUid "beginSheetModalForWindow:completionHandler:"
			parent :isa
		]
		do-modal-loop
		objc_msgSend [parent sel_getUid "makeKeyWindow"]
	][
		res: objc_msgSend [panel sel_getUid "runModal"]
		request-file-handler :isa res
	]
	as red-value! ret
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
	font			[red-object!]
	selected		[red-object!]
	mono?			[logic!]
	return:			[red-object!]
	/local
		panel		[integer!]
		delegate	[integer!]
		nsfont		[integer!]
		values		[red-value!]
		style		[red-block!]
		size		[float32!]
		manager		[integer!]
		trait		[integer!]
		bold?		[logic!]
		pool		[integer!]
][
	font-changed?: no
	nsfont: as-integer get-font null selected
	if zero? nsfont [nsfont: default-font]
	delegate: objc_msgSend [objc_getClass "RedPanelDelegate" sel_getUid "alloc"]
	delegate: objc_msgSend [delegate sel_getUid "init"]

	panel: objc_msgSend [objc_getClass "NSFontPanel" sel_getUid "sharedFontPanel"]
	objc_msgSend [panel sel_getUid "setPanelFont:isMultiple:" nsfont no]
	objc_msgSend [panel sel_getUid "setDelegate:" delegate]
	objc_msgSend [panel sel_getUid "orderFront:" 0]
	objc_msgSend [NSApp sel_getUid "runModalForWindow:" panel]
	either font-changed? [
		nsfont: objc_msgSend [panel sel_getUid "panelConvertFont:" nsfont]
		pool: either zero? objc_msgSend [objc_getClass "NSThread" sel_getUid "isMainThread"][
			objc_msgSend [
				objc_msgSend [objc_getClass "NSAutoreleasePool" sel_getUid "alloc"]
				sel_getUid "init"
			]
		][0]
		values: object/get-values font
		to-red-string
			objc_msgSend [nsfont sel_getUid "familyName"]
			values + FONT_OBJ_NAME

		size: objc_msgSend_f32 [nsfont sel_getUid "pointSize"]
		integer/make-at values + FONT_OBJ_SIZE as-integer size

		manager: objc_msgSend [objc_getClass "NSFontManager" sel_getUid "sharedFontManager"]
		trait: objc_msgSend [manager sel_getUid "traitsOfFont:" nsfont]
		style: as red-block! values + FONT_OBJ_STYLE
		bold?: no
		if trait and NSBoldFontMask <> 0 [
			word/make-at _bold as red-value! style
			bold?: yes
		]
		if trait and NSItalicFontMask <> 0 [
			either bold? [
				block/make-at style 4
				word/push-in _bold style
				word/push-in _italic style
			][
				word/make-at _italic as red-value! style
			]
		]
		if pool <> 0 [objc_msgSend [pool sel_release]]
	][
		font/header: TYPE_NONE
	]
	objc_msgSend [panel sel_getUid "setDelegate:" 0]
	objc_msgSend [delegate sel_release]
	font
]