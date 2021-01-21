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

		tagMSG: alias struct! [							;-- used to work around #4284
			hWnd	[handle!]
			msg		[integer!]
			wParam	[integer!]
			lParam	[integer!]
			time	[integer!]
			x		[integer!]							;@@ POINT struct
			y		[integer!]	
		]

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
				RegisterClipboardFormat: "RegisterClipboardFormatA" [
					lpszFormat	[c-string!]
					return:		[integer!]
				]
				PeekMessage: "PeekMessageW" [			;-- used to work around #4284
					msg			[tagMSG]
					hWnd		[handle!]
					msgMin		[integer!]
					msgMax		[integer!]
					removeMsg	[integer!]
					return: 	[integer!]
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
				GlobalSize: "GlobalSize" [
					hMem		[integer!]
					return:		[integer!]				;-- valid for 32bit exe only
				]
				lstrlen: "lstrlenW" [
					str			[byte-ptr!]
					return:		[integer!]
				]
				Sleep: "Sleep" [
					dwMilliseconds	[integer!]
				]
			]
			"Shell32.dll" stdcall [
				DragQueryFile: "DragQueryFileW" [
					hDrop		[integer!]
					iFile		[integer!]
					lpszFile	[byte-ptr!]
					cch			[integer!]
					return:		[integer!]
				]
			]
		]

		DROPFILES!: alias struct! [
			pFiles				[integer!]
			pt					[tagPOINT value]
			fNC					[logic!]
			fWide				[logic!]
		]

		BITMAPV5HEADER!: alias struct! [
  			Size			[integer!]
  			Width			[integer!]
  			Height			[integer!]
  			PlanesBitCount	[integer!]
  			Compression		[integer!]
  			SizeImage		[integer!]
  			XPelsPerMeter	[integer!]
  			YPelsPerMeter	[integer!]
  			ClrUsed			[integer!]
  			ClrImportant	[integer!]
  			RedMask			[integer!]
  			GreenMask		[integer!]
  			BlueMask		[integer!]
  			AlphaMask		[integer!]
  			CSType			[integer!]
  			EndpointsRedX	[integer!]
  			EndpointsRedY	[integer!]
  			EndpointsRedZ	[integer!]
  			EndpointsGreenX	[integer!]
  			EndpointsGreenY	[integer!]
  			EndpointsGreenZ	[integer!]
  			EndpointsBlueX	[integer!]
  			EndpointsBlueY	[integer!]
  			EndpointsBlueZ	[integer!]
			GammaRed		[integer!]
			GammaGreen		[integer!]
			GammaBlue		[integer!]
			Intent			[integer!]
			ProfileData		[integer!]
			ProfileSize		[integer!]
			Reserved		[integer!]
		]

		#define CF_TEXT				1
		#define CF_BITMAP			2
		#define CF_TIFF				6					;; TBD
		#define CF_OEMTEXT			7
		#define CF_DIB				8
		#define CF_RIFF				11					;; TBD
		#define CF_WAVE				12					;; TBD
		#define CF_UNICODETEXT		13
		#define CF_HDROP			15
		#define CF_DIBV5			17

		main-hWnd: as int-ptr! 0

		read: func [
			return:		[red-value!]
			/local
				hMem	[integer!]
				p		[byte-ptr!]
				p1		[byte-ptr!]
				p2		[byte-ptr!]
				bufsz	[integer!]
				ok		[logic!]
				val		[red-value!]
				blk		[red-block!]
				str		[red-string!]
				bmp		[integer!]
				fmts	[int-ptr!]
				count	[integer!]
				i		[integer!]
				len		[integer!]
				hdr		[BITMAPV5HEADER!]
				msg		[tagMSG value]
		][
			val: none-value
			p: null
			i: 0

			;-- OpenClipboard often fails on W7 after an EmptyClipboard call, so be persistent
			ok: yes
			loop 3 [
				unless ok [Sleep 1]
				ok: OpenClipboard main-hWnd
				if ok [break]
				PeekMessage :msg null 0 0 0				;-- magic workaround for #4284
			]
			unless ok [return as red-value! false-value]

			loop 1 [									;-- trick for `break` to work

				;-- test text first
				hMem: GetClipboardData CF_UNICODETEXT
				if hMem <> 0 [
					p: GlobalLock hMem
					unless null? p [
						str: as red-string! stack/push*
						str/header: TYPE_UNSET
						str/head: 0
						str/cache: null
						str/node: unicode/load-utf16 as-c-string p lstrlen p null yes
						str/header: TYPE_STRING
						val: as red-value! str
						GlobalUnlock hMem
					]
					break
				]

				;-- test for a list of files
				hMem: GetClipboardData CF_HDROP
				if hMem <> 0 [
					p: GlobalLock hMem
					unless null? p [
						;-- files can be in ANSI codepage; DragQueryFileW func deals with that
						count: DragQueryFile hMem FFFFFFFFh null 0
						assert count >= 0
						blk: block/push-only* count
						str: string/make-at stack/push* 64 Latin1
						i: 0 bufsz: 0 p1: null
						loop count [
							len: DragQueryFile hMem i null 0
							if len > bufsz [
								bufsz: either len > 260 [len][260]
								p2: realloc p1 bufsz * 2
								if null? p2 [free p1 p1: null break]
								p1: p2
							]
							DragQueryFile hMem i p1 bufsz
							string/load-at as-c-string p1 lstrlen p1 as red-value! str UTF-16LE
							stack/mark-native words/_body 
							#call [to-red-file str]
							block/rs-append blk stack/arguments
							stack/unwind
							string/rs-reset str
							i: i + 1
						]
						stack/pop 1						;-- get rid of `str`
						unless null? p1 [free p1 p1: null]
						val: as red-value! blk
						GlobalUnlock hMem
					]
					break
				]

				;-- test for images: first for raw data; then for standard DIB

				;-- these formats are supported by *some* programs
				;; see https://stackoverflow.com/a/6565158
				fmts: [0 0 0]
				fmts/1: RegisterClipboardFormat "PNG"
				fmts/2: RegisterClipboardFormat "JFIF"
				fmts/3: RegisterClipboardFormat "GIF"
				assert all [fmts/1 <> 0 fmts/2 <> 0 fmts/3 <> 0]

				loop size? fmts [
					hMem: GetClipboardData fmts/1
					if hMem <> 0 [break]
					fmts: fmts + 1
				]
				if hMem <> 0 [
					p: GlobalLock hMem
					unless null? p [
						val: as red-value! image/load-binary binary/load p GlobalSize hMem
						GlobalUnlock hMem
					]
					break
				]

				;-- finally try the standard DIB: supports the alpha-channel unless it's messed with
				;; see on the transparency support: https://stackoverflow.com/a/46400011
				hMem: GetClipboardData CF_DIBV5
				if hMem <> 0 [
					p: GlobalLock hMem
					unless null? p [
						hdr: as BITMAPV5HEADER! p
						bmp: 0
						either all [					;-- is format compatible with Red GDI+ image?
							hdr/PlanesBitCount >> 16 = 32
							hdr/Compression = 3			;-- BI_BITFIELDS
							hdr/AlphaMask = FF000000h
							hdr/RedMask   = 00FF0000h
							hdr/GreenMask = 0000FF00h
							hdr/BlueMask  = 000000FFh
						][								;-- can copy the data directly
							if hdr/Height < 0 [hdr/Height: 0 - hdr/Height]
							assert all [0 = OS-image/get-pixel-format bmp :i  OS-image/fixed-format? i]
							OS-image/create-bitmap-from-scan0 hdr/Width hdr/Height 0 OS-image/fixed-format p :bmp
						][								;-- will have to convert, losing the alpha data if any
							#either draw-engine = 'GDI+ [
								OS-image/create-bitmap-from-gdidib
									p  p + hdr/Size + (hdr/ClrUsed * 4) + hdr/ProfileSize :bmp
							][
								GlobalUnlock hMem
								hMem: GetClipboardData CF_BITMAP
								val: as red-value! OS-image/from-HBITMAP hMem 2	;-- WICBitmapIgnoreAlpha
								hMem: 0
							]
						]
						if hMem <> 0 [
							if zero? bmp [return as red-value! none-value]
							val: as red-value! image/init-image as red-image! stack/push* as int-ptr! bmp
							GlobalUnlock hMem
						]
					]
					break
				]

			];; loop 1

			CloseClipboard

			;-- none = general success but empty or unsupported data
			;-- false = failure during data retrieval
			if all [hMem <> 0 null? p] [return as red-value! false-value]
			val
		];; read

		write: func [
			data		[red-value!]
			return:		[logic!]
			/local
				res		[int-ptr!]
				fmts	[int-ptr!]
				hMem	[int-ptr!]
				ok		[logic!]
				len		[integer!]
				p		[byte-ptr!]
				p1		[byte-ptr!]
				value	[red-value!]
				tail	[red-value!]
				str		[red-string!]
				bin		[red-binary!]
				blk		[red-block!]
				img		[red-image!]
				df		[DROPFILES!]
				bmdata	[integer!]
				w		[integer!]
				h		[integer!]
				s		[integer!]
				scan0	[byte-ptr!]
				format	[integer!]
				hdr		[BITMAPV5HEADER!]
				msg		[tagMSG value]
		][
			hMem: [0 0]  hMem/1: 0  hMem/2: 0
			fmts: [0 0]  fmts/1: 0  fmts/2: 0

			;-- let the memory stuff come before OpenClipboard
			;; this delays OpenClipboard an extra bit, resulting in lesser failure rate
			;; plus, it can throw an error from this block
			switch TYPE_OF(data) [

				TYPE_NONE	[0]							;-- allow `none` to empty the clipboard

				TYPE_STRING [
					fmts/1: CF_UNICODETEXT
					len: -1
					p1: as byte-ptr! unicode/to-utf16-len as red-string! data :len yes
					hMem/1: GlobalAlloc 2 len * 2 + 2
					if hMem/1 <> 0 [
						p: GlobalLock hMem/1
						unless null? p [
							copy-memory p p1 len * 2 + 2
							GlobalUnlock hMem/1
						]
					]
				]

				TYPE_BLOCK	[							;-- block of files in native format
					fmts/1: CF_HDROP

					;-- count the total characters for the DROPFILES data, also convert files to OS format
					len: 2								;-- always have 2 trailing null chars, even for an empty block
					value: block/rs-head as red-block! data
					tail:  block/rs-tail as red-block! data
					blk: block/push-only* (as-integer tail - value) / size? cell!
					while [value < tail] [
						assert any [TYPE_OF(value) = TYPE_FILE  TYPE_OF(value) = TYPE_STRING]
						str: string/make-at ALLOC_TAIL(blk) 64 Latin1
						file/to-local-path as red-file! value str no
						len: len + 1 + string/rs-length? str
						value: value + 1
					]

					;-- conservatively allocate 4 bytes for each char
					hMem/1: GlobalAlloc 2 len * 4 + size? DROPFILES!
					if hMem/1 <> 0 [
						p: GlobalLock hMem/1
						unless null? p [
							;-- construct the DROPFILES data
							set-memory p #"^@" size? DROPFILES!
							df: as DROPFILES! p
							df/pFiles: size? DROPFILES!
							df/fWide: yes
							p: p + df/pFiles
							str: as red-string! block/rs-head blk
							tail: block/rs-tail blk
							while [str < as red-string! tail] [
								len: -1
								p1: as byte-ptr! unicode/to-utf16-len str :len yes
								len: len * 2 + 2
								copy-memory p p1 len
								p: p + len
								str: str + 1
							]
							p/1: #"^@" p/2: #"^@"
							GlobalUnlock hMem/1
						]
					]
					stack/pop 1							;-- get rid of `blk`
				];; TYPE_BLOCK

				TYPE_IMAGE	[
					img: as red-image! data
					len: IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size)
					case [
						len > 0 [
							;-- put image in the "PNG" format for it's better portability
							;; see https://stackoverflow.com/a/15691001 on rationale
							fmts/1: RegisterClipboardFormat "PNG"
							assert fmts/1 <> 0
							bin: as red-binary! image/encode img none-value IMAGE_PNG
							len: binary/rs-length? bin
							hMem/1: GlobalAlloc 2 len
							if hMem/1 <> 0 [
								p1: GlobalLock hMem/1
								unless null? p1 [
									copy-memory p1 binary/rs-head bin len
									GlobalUnlock hMem/1
								]
							]

							;-- also put the image in DIB format for compatibility
							fmts/2: CF_DIBV5
							bmdata: OS-image/lock-bitmap img no
							assert 0 <> bmdata
							w: OS-image/width? img/node
							h: OS-image/height? img/node
							s: 0
							scan0: as byte-ptr! OS-image/get-data bmdata :s
							len: w * h * 4
							format: 0
							OS-image/get-data-pixel-format bmdata :format
							hMem/2: GlobalAlloc 2 len + size? BITMAPV5HEADER!
							if hMem/2 <> 0 [
								p: GlobalLock hMem/2
								unless null? p [
									set-memory p #"^@" size? BITMAPV5HEADER!
									hdr: as BITMAPV5HEADER! p
									hdr/Size: size? BITMAPV5HEADER!
									hdr/Width: w
									hdr/Height: 0 - h				;-- top-down image
									hdr/PlanesBitCount: 00200001h	;-- 32 bpp, 1 plane
									hdr/Compression: 3				;-- BI_BITFIELDS
									hdr/SizeImage: len
									hdr/AlphaMask: FF000000h
									hdr/RedMask:   00FF0000h
									hdr/GreenMask: 0000FF00h
									hdr/BlueMask:  000000FFh
									hdr/CSType: 57696E20h			;-- "Win " = LCS_WINDOWS_COLOR_SPACE
									hdr/Intent: 4					;-- 4 = LCS_GM_IMAGES
									assert OS-image/fixed-format? format
									copy-memory p + hdr/Size scan0 len
									GlobalUnlock hMem/2
								]
							]
							OS-image/unlock-bitmap img bmdata
						];; if IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) > 0
						zero? len [p: as byte-ptr! 1] ;-- empty clipboard in case of empty image
						true [fire [TO_ERROR(script invalid-arg) data]]
					]
				];; TYPE_IMAGE

				default		[fire [TO_ERROR(script invalid-arg) data]]
			]

			;-- OpenClipboard often fails on W7 after an EmptyClipboard call, so be persistent
			ok: yes
			loop 3 [
				unless ok [Sleep 1]
				ok: OpenClipboard main-hWnd
				if ok [break]
				PeekMessage :msg null 0 0 0				;-- magic workaround for #4284
			]
			unless ok [									;-- clean up after a (rare) failure
				unless hMem/1 = 0 [
					GlobalLock hMem/1
					GlobalFree hMem/1
					GlobalUnlock hMem/1
				]
				unless hMem/2 = 0 [
					GlobalLock hMem/2
					GlobalFree hMem/2
					GlobalUnlock hMem/2
				]
				return false
			]

			res: [1 1]  res/1: 1  res/2: 1
			if TYPE_OF(data) = TYPE_NONE [p: as byte-ptr! 1]	;-- empty clipboard in case of `none` argument
			unless null? p [									;-- but not in case of a failed allocation/lock
				EmptyClipboard
				if fmts/1 <> 0 [res/1: SetClipboardData fmts/1 hMem/1]
				if fmts/2 <> 0 [res/2: SetClipboardData fmts/2 hMem/2]
			]
			CloseClipboard
			;-- false if:
			;; - failed to prepare or set text or file list
			;; - failed to prepare image in DIB format, or set it in either format
			all [res/1 <> 0 res/2 <> 0 not null? p]
		];; write
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
	#either modules contains 'View [
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
	][
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
