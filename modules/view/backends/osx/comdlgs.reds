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
		file		[integer!]
		res			[integer!]
][
	quit-modal-loop?: no
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
		res: objc_msgSend [panel sel_getUid "runModalForDirectory:file:" dir file]
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