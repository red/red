Red/System [
	Title:	"Clipboard functions"
	Author: "Xie Qingtian"
	File: 	%clipboard.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

clipboard: context [
#switch OS [
	Windows [
		#import [
			"User32.dll" stdcall [
				OpenClipboard: "OpenClipboard" [
					hWnd		[int-ptr!]
					return:		[logic!]
				]
				SetClipboardData: "SetClipboardData" [
					uFormat		[integer!]
					hMem		[integer!]
					return:		[integer!]
				]
				GetClipboardData: "GetClipboardData" [
					uFormat		[integer!]
					return:		[integer!]
				]
				EnumClipboardFormats: "EnumClipboardFormats" [
					uFormat		[integer!]
					return:		[integer!]
				]
				EmptyClipboard: "EmptyClipboard" [
					return:		[integer!]
				]
				CloseClipboard: "CloseClipboard" [
					return:		[integer!]
				]
				GetForegroundWindow: "GetForegroundWindow" [
					return:		[integer!]
				]
			]
			"kernel32.dll" stdcall [
				GlobalAlloc: "GlobalAlloc" [
					flags		[integer!]
					size		[integer!]
					return:		[integer!]
				]
				GlobalFree: "GlobalFree" [
					hMem		[integer!]
					return:		[integer!]
				]
				GlobalLock: "GlobalLock" [
					hMem		[integer!]
					return:		[byte-ptr!]
				]
				GlobalUnlock: "GlobalUnlock" [
					hMem		[integer!]
					return:		[integer!]
				]
				lstrlen: "lstrlenW" [
					str			[byte-ptr!]
					return:		[integer!]
				]
			]
		]

		#define CF_TEXT				1
		#define CF_BITMAP			2
		#define CF_OEMTEXT			7
		#define CF_DIB				8
		#define CF_UNICODETEXT		13
		#define CF_DIBV5			17

		main-hWnd: as int-ptr! 0

		read: func [
			return:		[red-value!]
			/local
				hMem	[integer!]
				p		[byte-ptr!]
				cp		[integer!]
				val		[red-value!]
		][
			p: null
			val: as red-value! none-value

			unless OpenClipboard main-hWnd [return as red-value! false-value]

			hMem: GetClipboardData CF_UNICODETEXT
			if hMem <> 0 [
				p: GlobalLock hMem
				if p <> null [
					val: as red-value! string/load as-c-string p lstrlen p UTF-16LE
				]
				GlobalUnlock hMem
			]
			CloseClipboard
			val
		]

		write: func [
			data		[red-value!]
			return:		[logic!]
			/local
				res		[integer!]
				len		[integer!]
				hMem	[integer!]
				p		[byte-ptr!]
				p1		[byte-ptr!]
		][
			unless OpenClipboard main-hWnd [return false]
			EmptyClipboard

			switch TYPE_OF(data) [
				TYPE_STRING [
					len: -1
					p1: as byte-ptr! unicode/to-utf16-len as red-string! data :len yes
					hMem: GlobalAlloc 2 len * 2 + 2
					p: GlobalLock hMem
					copy-memory p p1 len * 2 + 2
					GlobalUnlock hMem
				]
				TYPE_IMAGE	[0]
				default		[0]
			]

			res: SetClipboardData CF_UNICODETEXT hMem
			CloseClipboard
			as logic! res
		]
	]
	macOS [
		#import [
			LIBC-file cdecl [
				objc_getClass: "objc_getClass" [
					class		[c-string!]
					return:		[integer!]
				]
				sel_getUid: "sel_getUid" [
					name		[c-string!]
					return:		[integer!]
				]
				objc_msgSend: "objc_msgSend" [[variadic] return: [integer!]]
			]
			"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit" cdecl [
				NSBeep: "NSBeep" []
			]
		]

		to-red-string: func [
			nsstr	[integer!]
			slot	[red-value!]
			return: [red-string!]
			/local
				str  [red-string!]
				size [integer!]
				cstr [c-string!]
		][
			size: objc_msgSend [nsstr sel_getUid "lengthOfBytesUsingEncoding:" 4]
			cstr: as c-string! objc_msgSend [nsstr sel_getUid "UTF8String"]
			if null? slot [slot: stack/push*]
			str: string/make-at slot size Latin1
			unicode/load-utf8-stream cstr size str null
			str
		]

		to-NSString: func [str [red-string!] return: [integer!] /local len][
			len: -1
			objc_msgSend [
				objc_getClass "NSString"
				sel_getUid "stringWithUTF8String:"
				unicode/to-utf8 str :len
			]
		]

		read: func [
			return:		[red-value!]
			/local
				pasteboard	[integer!]
				classes		[integer!]
				obj			[integer!]
				options		[integer!]
		][
			pasteboard: objc_msgSend [objc_getClass "NSPasteboard" sel_getUid "generalPasteboard"]
			classes: objc_msgSend [objc_getClass "NSArray" sel_getUid "arrayWithObject:" objc_getClass "NSString"]
			options: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "dictionary"]
			obj: objc_msgSend [pasteboard sel_getUid "readObjectsForClasses:options:" classes options]
			either zero? obj [none-value][
				as red-value! to-red-string objc_msgSend [obj sel_getUid "firstObject"] null
			]
		]

		write: func [
			data		[red-value!]
			return:		[logic!]
			/local
				pasteboard	[integer!]
				arr			[integer!]
				obj			[integer!]
				res			[integer!]
		][
			res: 0
			obj: switch TYPE_OF(data) [
				TYPE_STRING [to-NSString as red-string! data]
				TYPE_IMAGE	[0]
				default		[0]
			]

			if obj <> 0 [
				pasteboard: objc_msgSend [objc_getClass "NSPasteboard" sel_getUid "generalPasteboard"]
				objc_msgSend [pasteboard sel_getUid "clearContents"]
				arr: objc_msgSend [objc_getClass "NSArray" sel_getUid "arrayWithObject:" obj]
				res: objc_msgSend [pasteboard sel_getUid "writeObjects:" arr]
			]
			as logic! res
		]
	]
	Linux [
		;; Depends on GTK
		#import [
			"libgtk-3.so.0" cdecl [
				gdk_atom_intern_static_string: "gdk_atom_intern_static_string" [
					name 		[c-string!]
					return:		[handle!]
				]
				gtk_clipboard_get: "gtk_clipboard_get" [
					atom 		[handle!]
					return: 	[handle!]
				]
				gtk_clipboard_set_text: "gtk_clipboard_set_text" [
					clipboard 	[handle!]
					text 		[c-string!]
					len 		[integer!]
				]
				gtk_clipboard_set_image: "gtk_clipboard_set_image" [
					clipboard 	[handle!]
					img 		[handle!]
				]
				gtk_clipboard_wait_for_text: "gtk_clipboard_wait_for_text" [
					clipboard 	[handle!]
					return: 	[c-string!]
				]
				gtk_clipboard_wait_for_image: "gtk_clipboard_wait_for_image" [
					clipboard 	[handle!]
					return: 	[handle!]
				]
			]
		]

		to-red-string: func [
			cstr	[c-string!]
			slot	[red-value!]
			return:	[red-string!]
			/local
				str		[red-string!]
				size	[integer!]
		][
			size: length? cstr
			if null? slot [slot: stack/push*]
			str: string/make-at slot size Latin1
			unicode/load-utf8-stream cstr size str null
			str
		]

		read: func [
			return:		[red-value!]
			/local
				clipboard 	[handle!]
				str 		[c-string!]
		][
			clipboard: gtk_clipboard_get gdk_atom_intern_static_string "CLIPBOARD"
			str: gtk_clipboard_wait_for_text clipboard
			as red-value! to-red-string str null
		]

		write: func [
			data		[red-value!]
			return:		[logic!]
			/local
				clipboard 	[handle!]
				text		[red-string!]
				str 		[c-string!]
				strlen 		[integer!]
		][
			clipboard: gtk_clipboard_get gdk_atom_intern_static_string "CLIPBOARD"
			switch TYPE_OF(data) [
				TYPE_STRING [ 
					text: as red-string! data
					strlen: -1
					str: unicode/to-utf8 text :strlen
					gtk_clipboard_set_text clipboard str strlen
				]
				TYPE_IMAGE	[0]
				default		[0]
			]
			true
		]
	]
	#default [
		read: func [
			return:		[red-value!]
		][
			none-value
		]

		write: func [
			data		[red-value!]
			return:		[logic!]
		][
			true
		]
	]
]]
