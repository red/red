Red/System [
	Title:   "Red runtime utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#either OS = 'Windows [
	get-cmdline-args: func [
		return: [red-value!]
		/local
			args [byte-ptr!]
	][
		args: GetCommandLine
		as red-value! string/load as-c-string args lstrlen args UTF-16LE
	]

	list-env: func [
		return: [red-value!]							;-- return a map!
		/local
			env		[c-string!]
			str		[c-string!]
			p		[c-string!]
			blk		[red-block!]
			len		[integer!]
	][
		env: GetEnvironmentStrings
		blk: null
		len: 0

		if env <> null [
			blk: block/push-only* 100
			str: env
			p: str
			while [true][
				if all [len <> 0 str/1 = #"=" str/2 = #"^@"][
					string/load-in p len blk UTF-16LE
					p: str + 2
					len: lstrlen as byte-ptr! p
					string/load-in p len blk UTF-16LE
					str: p + (len * 2)
					if all [str/3 = #"^@" str/4 = #"^@"][break]
					p: str + 2
					len: -1
				]
				str: str + 2
				len: len + 1
			]
			len: block/rs-length? blk
			FreeEnvironmentStrings env
		]
		as red-value! map/make-at as red-value! blk blk len
	]
][
	get-cmdline-args: func [
		return: [red-value!]
		/local
			str		[red-string!]
			args	[str-array!]
			src		[c-string!]
			s		[series!]
			cnt		[integer!]
			size	[integer!]
			cp		[integer!]
			quote 	[integer!]
			end?	[logic!]
	][
		cnt: 0
		size: 4'000									;-- enough?
		quote: as-integer #"'"
		str: string/rs-make-at ALLOC_TAIL(root) size
		s: GET_BUFFER(str)
		args: system/args-list
		
		until [
			src: args/item

			;-- see PR #3870 on quoting details
			s: string/append-char s quote
			until [
				cnt: unicode/utf8-char-size? as-integer src/1
				cp: unicode/decode-utf8-char src :cnt
				either cp <> as-integer #"'" [
					s: string/append-char s cp
				][
					s: string/append-char s quote
					s: string/append-char s as-integer #"\"
					s: string/append-char s quote
					s: string/append-char s quote
				]
				src: src + cnt
				size: size - 1
				any [src/1 = null-byte zero? size]
			]
			s: string/append-char s quote
			
			args: args + 1
			end?: null? args/item
			unless end? [s: string/append-char s as-integer #" "] ;-- add a space as separation
			end?
		]
		as red-value! str
	]

	list-env: func [
		return: [red-value!]							;-- return a map!
		/local
			handle	[integer!]
			p-int	[int-ptr!]
			env		[int-ptr!]
			str		[c-string!]
			p		[c-string!]
			blk		[red-block!]
			len		[integer!]
	][
		env: as int-ptr! platform/environ
		#if target = 'ARM [env: as int-ptr! env/value] ;@@ ???

		blk: null
		len: 0

		if env <> null [
			blk: block/push-only* 100
			while [
				str: as c-string! env/1
				str <> null
			][
				len: 0
				p: str
				while [true][
					if p/1 = #"=" [
						string/load-in str len blk UTF-8
						str: p + 1
						string/load-in str length? str blk UTF-8
						break
					]
					len: len + 1
					p: p + 1
				]
				env: env + 1
			]
			len: block/rs-length? blk
		]
		as red-value! map/make-at as red-value! blk blk len
	]
]

check-arg-type: func [
	arg		[red-value!]
	type	[integer!]
][
	if TYPE_OF(arg) <> type [
		fire [TO_ERROR(script invalid-arg) arg]
	]
]

#switch OS [
	Windows [

	SYSTEM_INFO!: alias struct! [
		dwOemId						[integer!]
		dwPageSize					[integer!]
		lpMinimumApplicationAddress [byte-ptr!]
		lpMaximumApplicationAddress [byte-ptr!]
		dwActiveProcessorMask		[int-ptr!]
		dwNumberOfProcessors		[integer!]
		dwProcessorType				[integer!]
		dwAllocationGranularity		[integer!]
		wProcessorLevel				[integer!]
		;wProcessorRevision
	]

	#import [
		"kernel32.dll" stdcall [
			GetNativeSystemInfo: "GetNativeSystemInfo" [
				lpSystemInfo [SYSTEM_INFO!]
			]
		]
	]

	__get-OS-info: func [
		/local
			obj		[red-object!]
			ctx		[red-context!]
			str		[red-string!]
			val		[red-value!]
			int		[red-integer!]
			arch	[c-string!]
			name	[c-string!]
			info	[SYSTEM_INFO! value]
			ver		[OSVERSIONINFO value]
			build	[integer!]
			server? [logic!]
	][
		obj: object/make-at as red-object! stack/push* 8
		val: stack/push*
		ctx: GET_CTX(obj)

		ver/dwOSVersionInfoSize: size? OSVERSIONINFO
		ver/szCSDVersion: 0
		GetVersionEx :ver

		build: ver/dwBuildNumber
		server?: ver/wProductType <> #"^(01)"
		str: string/load-at "Windows " 8 val UTF-8
		name: switch ver/dwMajorVersion [
			5 [
				switch ver/dwMinorVersion [
					0 ["2000"]
					1 ["XP"]
					2 [either server? ["Server 2003 R2"]["Server 2003"]]
				]
			]
			6 [
				switch ver/dwMinorVersion [
					0 [either server? ["Server 2008"]["Vista"]]
					1 [either server? ["Server 2008 R1"]["7"]]
					2 [either server? ["Server 2012"]["8"]]
					3 [either server? ["Server 2012 R2"]["8.1"]]
				]
			]
			default [	;-- Windows 10+
				either server? [
					case [
						build >= 20285	["Server 2022"]
						build >= 17134	["Server 2019"]
						true			["Server 2016"]
					]
				][
					case [
						build >= 22000	["11"]
						true			["10"]
					]
				]
			]
		]
		string/concatenate-literal str name
		if ver/szCSDVersion <> 0 [
			string/append-char GET_BUFFER(str) as-integer #" "
			string/concatenate-literal str as c-string! :ver/szCSDVersion
		]
		_context/add-with ctx _context/add-global symbol/make "name" val

		GetNativeSystemInfo :info
		arch: switch info/dwOemId and FFFFh [		;-- wProcessorArchitecture
			0  ["x86-32"]
			5  ["ARM"]
			6  ["IA-64"]
			9  ["x86-64"]
			12 ["ARM64"]
			default ["Unknown"]
		]
		word/make-at symbol/make arch val
		_context/add-with ctx _context/add-global symbol/make "arch" val

		val/header: TYPE_TUPLE or (3 << 19)
		val/data1: ver/dwMajorVersion
			or (ver/dwMinorVersion << 8)
			or (ver/wServicePack and FFFFh << 16)
		_context/add-with ctx _context/add-global symbol/make "version" val

		int: as red-integer! val
		int/header: TYPE_INTEGER
		int/value:  build
		_context/add-with ctx _context/add-global symbol/make "build" val
		stack/pop 2
	]]
	macOS [
	#import [
		"/System/Library/Frameworks/CoreServices.framework/CoreServices" cdecl [
			Gestalt: "Gestalt" [
				selector	[integer!]
				response	[int-ptr!]
				return:		[integer!]
			]
		]
	]
	__get-OS-info: func [
		/local
			obj		[red-object!]
			ctx		[red-context!]
			val		[red-value!]
			int		[red-integer!]
			str		[red-string!]
			arch	[c-string!]
			name	[c-string!]
			mib2	[integer!]
			mib		[integer!]
			len		[integer!]
			major	[integer!]
			minor	[integer!]
			bugfix	[integer!]
			s		[series!]
	][
		obj: object/make-at as red-object! stack/push* 8
		val: stack/push*
		ctx: GET_CTX(obj)

		major: 0 minor: 0 bugfix: 0
		Gestalt gestaltSystemVersionMajor :major
		Gestalt gestaltSystemVersionMinor :minor
		Gestalt gestaltSystemVersionBugFix :bugfix

		str: string/load-at "macOS " 6 val UTF-8
		name: switch major [
			10 [
				switch minor [
					14 ["Mojave"]
					13 ["High Sierra"]
					12 ["Sierra"]
					11 ["El Capitan"]
					10 ["Yosemite"]
					 9 ["Mavericks"]
					 8 ["Mountain Lion"]
					 7 ["Lion"]
					 default ["Unsupported Version"]
				]
			]
			default ["Unrecognized"]
		]
		string/concatenate-literal str name
		_context/add-with ctx _context/add-global symbol/make "name" val

		arch: "x86-64"
		word/make-at symbol/make arch val
		_context/add-with ctx _context/add-global symbol/make "arch" val

		val/header: TYPE_TUPLE or (3 << 19)
		val/data1: bugfix << 16 or (minor << 8) or major
		_context/add-with ctx _context/add-global symbol/make "version" val

		len: 0
		mib: 1		;-- CTL_KERN
		mib2: 65	;-- KERN_OSVERSION
		sysctl :mib 2 null :len null 0

		str: string/make-at val len 1
		s: GET_BUFFER(str)
		sysctl :mib 2 as byte-ptr! s/offset :len null 0
		s/tail: as red-value! (as byte-ptr! s/offset) + len - 1
		_context/add-with ctx _context/add-global symbol/make "build" val
		stack/pop 2
	]]

	NetBSD [
	utsname!: alias struct! [
		sysname		[c-string!]
		nodename	[c-string!]
		release		[c-string!]
		version		[c-string!]
		machine		[c-string!]
	]

	#import [
		LIBC-file cdecl [
			uname: "uname" [
				buf		[utsname!]
				return: [integer!]
			]
		]
	]

	__get-OS-info: func [
		/local
			obj		[red-object!]
			ctx		[red-context!]
			val		[red-value!]
			int		[red-integer!]
			pbuf	[byte-ptr!]
			str		[c-string!]
			p		[c-string!]
			err		[integer!]
			major	[integer!]
			minor	[integer!]
			bugfix	[integer!]
			file	[integer!]
			len		[integer!]
			buf		[utsname!]
	][
		obj: object/make-at as red-object! stack/push* 8
		val: stack/push*
		ctx: GET_CTX(obj)

		buf: as utsname! allocate size? utsname!
		uname buf

		str: (as c-string! buf) + 256
		string/load-at str length? str val UTF-8
		_context/add-with ctx _context/add-global symbol/make "name" val

		str: as c-string! buf
		word/make-at symbol/make str + (256 * 4) val
		_context/add-with ctx _context/add-global symbol/make "arch" val

		err: 0
		str: str + (256 * 2)
		p: strchr str #"."
		major: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		str: p + 1
		p: strchr str #"."
		minor: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		either p <> null [
			str: p + 1
			p: strchr str #"_"
			bugfix: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err
		][
			bugfix: 0
		]

		either bugfix <> 0 [
			val/header: TYPE_TUPLE or (3 << 19)
			val/data1: bugfix << 16 or (minor << 8) or major
		][
			val/header: TYPE_TUPLE or (2 << 19)
			val/data1: minor << 8 or major
		]
		_context/add-with ctx _context/add-global symbol/make "version" val

		str: (as c-string! buf) + (256 * 3)
		string/load-at str length? str val UTF-8
		_context/add-with ctx _context/add-global symbol/make "build" val

		stack/pop 2
		free as byte-ptr! buf
	]]

	FreeBSD [
	utsname!: alias struct! [
		sysname		[c-string!]
		nodename	[c-string!]
		release		[c-string!]
		version		[c-string!]
		machine		[c-string!]
	]

	#import [
		LIBC-file cdecl [
			uname: "uname" [
				buf		[utsname!]
				return: [integer!]
			]
		]
	]

	__get-OS-info: func [
		/local
			obj		[red-object!]
			ctx		[red-context!]
			val		[red-value!]
			int		[red-integer!]
			pbuf	[byte-ptr!]
			str		[c-string!]
			p		[c-string!]
			err		[integer!]
			major	[integer!]
			minor	[integer!]
			bugfix	[integer!]
			file	[integer!]
			len		[integer!]
			buf		[utsname!]
	][
		obj: object/make-at as red-object! stack/push* 8
		val: stack/push*
		ctx: GET_CTX(obj)

		buf: as utsname! allocate size? utsname!
		uname buf

		str: (as c-string! buf) + 32
		string/load-at str length? str val UTF-8
		_context/add-with ctx _context/add-global symbol/make "name" val

		str: as c-string! buf
		word/make-at symbol/make str + (32 * 4) val
		_context/add-with ctx _context/add-global symbol/make "arch" val

		err: 0
		str: str + (32 * 2)
		p: strchr str #"."
		major: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		str: p + 1
		p: strchr str #"-"
		minor: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err
		bugfix: 0		

		val/header: TYPE_TUPLE or (2 << 19)
		val/data1: minor << 8 or major
		_context/add-with ctx _context/add-global symbol/make "version" val

		str: (as c-string! buf) + (32 * 3)
		string/load-at str length? str val UTF-8
		_context/add-with ctx _context/add-global symbol/make "build" val

		stack/pop 2
		free as byte-ptr! buf
	]]

	#default [
	utsname!: alias struct! [
		_pad0	[float!]
		_pad1	[float!]
		_pad2	[float!]
		_pad3	[float!]
		_pad4	[float!]
		_pad5	[float!]
		_pad6	[float!]
		_pad7	[float!]
		_pad8	[float!]
		_pad9	[float!]
		_pad10	[float!]
		_pad11	[float!]
		_pad12	[float!]
		_pad13	[float!]
		_pad14	[float!]
		_pad15	[float!]
		_pad16	[float!]
		_pad17	[float!]
		_pad18	[float!]
		_pad19	[float!]
		_pad20	[float!]
		_pad21	[float!]
		_pad22	[float!]
		_pad23	[float!]
		_pad24	[float!]
		_pad25	[float!]
		_pad26	[float!]
		_pad27	[float!]
		_pad28	[float!]
		_pad29	[float!]
		_pad30	[float!]
		_pad31	[float!]
		_pad32	[float!]
		_pad33	[float!]
		_pad34	[float!]
		_pad35	[float!]
		_pad36	[float!]
		_pad37	[float!]
		_pad38	[float!]
		_pad39	[float!]
		_pad40	[float!]
		_pad41	[float!]
		_pad42	[float!]
		_pad43	[float!]
		_pad44	[float!]
		_pad45	[float!]
		_pad46	[float!]
		_pad47	[float!]
		_pad48	[float!]
	]

	#import [
		LIBC-file cdecl [
			uname: "uname" [
				buf		[utsname!]
				return: [integer!]
			]
		]
	]

	__get-OS-info: func [
		/local
			obj		[red-object!]
			ctx		[red-context!]
			val		[red-value!]
			int		[red-integer!]
			pbuf	[byte-ptr!]
			str		[c-string!]
			p		[c-string!]
			err		[integer!]
			major	[integer!]
			minor	[integer!]
			bugfix	[integer!]
			file	[integer!]
			len		[integer!]
			buf		[utsname!]
	][
		obj: object/make-at as red-object! stack/push* 8
		val: stack/push*
		ctx: GET_CTX(obj)

		buf: as utsname! allocate size? utsname!
		uname buf

		file: simple-io/open-file "/etc/os-release" simple-io/RIO_READ no
		either file > 0 [
			len: simple-io/file-size? file
			pbuf: allocate len
			simple-io/read-data file pbuf len
			simple-io/close-file file
			str: strstr as c-string! pbuf {PRETTY_NAME=}
			str: str + 12
			either str/1 = #"^"" [
				str: str + 1
				p: strchr str #"^""
			][
				p: strchr str lf
			]
			p/1: null-byte
		][
			str: (as c-string! buf) + 65
		]
		string/load-at str length? str val UTF-8
		if file > 0 [free pbuf]
		_context/add-with ctx _context/add-global symbol/make "name" val

		str: as c-string! buf
		word/make-at symbol/make str + (65 * 4) val
		_context/add-with ctx _context/add-global symbol/make "arch" val

		err: 0
		str: str + (65 * 2)
		p: strchr str #"."
		major: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		str: p + 1
		p: strchr str #"."
		minor: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		str: p + 1
		p: strchr str #"-"
		bugfix: tokenizer/scan-integer as byte-ptr! str as-integer p - str 1 :err

		val/header: TYPE_TUPLE or (3 << 19)
		val/data1: bugfix << 16 or (minor << 8) or major
		_context/add-with ctx _context/add-global symbol/make "version" val

		str: (as c-string! buf) + (65 * 3)
		string/load-at str length? str val UTF-8
		_context/add-with ctx _context/add-global symbol/make "build" val

		stack/pop 2
		free as byte-ptr! buf
	]]
]