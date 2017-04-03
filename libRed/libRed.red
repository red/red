Red [
	Title:   "LibRed API definition"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.red
	Tabs:	 4
	Config:	 [type: 'dll libRed?: yes libRedRT?: yes export-ABI: 'cdecl]
	Needs: 	 'View
	Version: 1.0.0
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system-global [
	#either OS = 'Windows [
		on-unload: func [hInstance [integer!]]
	][
		on-unload: func [[cdecl]]
	][
		if exec/lib-opened? [exec/redClose]
	]
]

#system [
	
	#either OS = 'Windows [
		#define utf16-length? [platform/lstrlen]
	][
		tagVARIANT: alias struct! [
			data1		[integer!]
			data2		[integer!]
			data3		[integer!]
			data4		[integer!]
		]
		
		utf16-length?: func [
			s		[byte-ptr!]
			return: [integer!]
			/local
				p [byte-ptr!]
		][
			p: s
			while [all [p/1 <> null-byte p/2 <> null-byte]][p: p + 2]
			(as-integer p - s) >> 1
		]
	]
	#enum string-encoding! [
		UTF8: 	1
		UTF16
		VARIANT
	]
	
	#define TRAP_ERRORS(name body) [
		last-error: null
		stack/mark-try-all name
		catch RED_THROWN_ERROR body
		stack/adjust-post-try
		res: stack/top - 1
		if all [system/thrown > 0 TYPE_OF(res) = TYPE_ERROR][last-error: res]
		system/thrown: 0
		ring/store res
	]
	
	#define CHECK_LIB_OPENED_RETURN(type) [
		unless lib-opened? [return as type -2]
	]
	
	#define CHECK_LIB_OPENED_RETURN_INT [
		unless lib-opened? [return -2]
	]
	
	#define CHECK_LIB_OPENED [
		unless lib-opened? [exit]
	]
	
	cmd-blk:	 declare red-block!
	extern-blk:  declare red-block!
	last-error:  as red-value! 0
	lib-opened?: no
	
	encoding-in:  UTF8
	encoding-out: UTF8

	names: context [
		action:		word/load "action"
		print:		word/load "print"
		extern:		word/load "extern"
		redDo:		word/load "redDo"
		redDoFile:	word/load "redDoFile"
		redDoBlock:	word/load "redDoBlock"
		redCall:	word/load "redCall"
		redLDPath:	word/load "redLoadPath"
		redSetPath: word/load "redSetPath"
		redGetPath: word/load "redGetPath"
		redRoutine: word/load "redRoutine"
		redString:	word/load "redString"
		redWord:	word/load "redWord"
		redCInt32:	word/load "redCInt32"
		redCDouble:	word/load "redCDouble"
		redCString:	word/load "redCString"
		redVString:	word/load "redVString"
		
		redAppend:	word/load "redAppend"
		redChange:	word/load "redChange"
		redClear:	word/load "redClear"
		redCopy:	word/load "redCopy"
		redFind:	word/load "redFind"
		redIndex?:	word/load "redIndex?"
		redLength?:	word/load "redLength?"
		redMake:	word/load "redMake"
		redMold:	word/load "redMold"
		redPick:	word/load "redPick"
		redPoke:	word/load "redPoke"
		redPut:		word/load "redPut"
		redRemove:	word/load "redRemove"
		redSelect:	word/load "redSelect"
		redSkip:	word/load "redSkip"
		redTo:		word/load "redTo"
		
		redOpenLogFile: word/load "redOpenLogFile"
	]
	
	ring: context [
		head: as cell! 0
		tail: as cell! 0
		pos:  as cell! 0
		size: 50
		
		store: func [
			value	[red-value!]
			return: [red-value!]
		][
			copy-cell value alloc
		]
		
		alloc: func [return: [red-value!]][
			pos: pos + 1
			if pos = tail [pos: head]
			pos
		]
		
		init: does [
			head: as cell! allocate size * size? cell!
			tail: head + size
			pos:  head
		]
		
		destroy: does [free as byte-ptr! head]
	]
	
	make-error: func [
		name	[red-word!]
		return: [red-value!]
	][
		last-error: as red-value! error/create
			TO_ERROR(script lib-invalid-arg)
			as red-value! name
			null null
		last-error
	]
	
	import-string: func [
		src		[c-string!]
		name	[red-word!]
		save?	[logic!]
		return: [red-value!]	"Last value or error! value"
		/local
			str [red-value!]
			res [red-value!]
			v	[tagVARIANT]
	][
		TRAP_ERRORS(name [
			str: as red-value! switch encoding-in [
				UTF8	[string/load src length? src UTF-8]
				UTF16	[string/load src utf16-length? as byte-ptr! src UTF-16LE]
				VARIANT [
					v: as tagVARIANT src
					string/load
						as-c-string v/data3
						utf16-length? as byte-ptr! v/data3
						UTF-16LE
				]
			]
			stack/unwind-last
		])
		either last-error <> null [
			last-error
		][
			either save? [ring/store str][str]
		]
	]
	
	load-string: func [
		src		[c-string!]		"Red code as string"
		name	[red-word!]
		return: [red-value!]	"Last value or error! value"
		/local
			str [red-string!]
			res [red-value!]
	][
		str: as red-string! import-string src name no
		if last-error <> null [return last-error]
		
		TRAP_ERRORS(name [
			#call [system/lexer/transcode str none no]
			stack/unwind-last
		])
	]
	
	do-safe: func [
		code	[red-block!]
		name	[red-word!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		TRAP_ERRORS(name [
			interpreter/eval code yes
			stack/unwind-last
		])
	]
	
	;====================================
	;=========== Exported API ===========
	;====================================

	redOpen: func [
		"Initialize the Red runtime for the current instance"
	][
		unless lib-opened? [
			red/boot
			ring/init
			block/make-at cmd-blk 10
			block/make-at extern-blk 1
			block/rs-append extern-blk as red-value! names/extern
			lib-opened?: yes
		]
	]
	
	redDo: func [
		"Loads and evaluates Red code"
		src		[c-string!]		"Red code as encoded string"
		return: [red-value!]	"Last value or error! value"
		/local
			blk [red-block!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		blk: as red-block! load-string src names/redDo
		if TYPE_OF(blk) = TYPE_BLOCK [do-safe blk names/redDo]
		ring/store stack/arguments
	]
	
	redDoFile: func [
		src		[c-string!]
		return: [red-value!]
		/local
			res	 [red-value!]
			file [red-file!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		file: as red-file! import-string src names/redDoFile yes
		file/header: TYPE_FILE
		if last-error <> null [return last-error]
		
		TRAP_ERRORS(names/redDoFile [
			stack/push as red-value! file
			natives/do* yes -1 -1 -1
			stack/unwind-last
		])
	]
	
	redDoBlock: func [
		"Evaluates Red code"
		code	[red-block!]	"Block to evaluate"
		return: [red-value!]	"Last value or error! value"
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		ring/store do-safe code names/redDoBlock
	]
	
	redClose: func [
		"Releases dynamic memory allocated for the current instance"
	][
		CHECK_LIB_OPENED
		#if OS = 'Windows [#if modules contains 'View [gui/cleanup]]
		
		ring/destroy
		red/cleanup
		lib-opened?: no
	]
	
	redSetEncoding: func [
		in	[string-encoding!]
		out [string-encoding!]
	][
		encoding-in:  in
		encoding-out: out
	]
	
	redOpenLogFile: func [
		name	[c-string!]
		return: [red-value!]
		/local
			script [red-file!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		script: as red-file! import-string name names/redOpenLogFile yes
		script/header: TYPE_FILE
		if last-error <> null [return last-error]

		#if OS = 'Windows [red/platform/dos-console?: no]
		stdout: red/simple-io/open-file file/to-OS-path script red/simple-io/RIO_APPEND yes
		null
	]
	
	redCloseLogFile: does [
		CHECK_LIB_OPENED
		red/simple-io/close-file stdout
		#if OS = 'Windows [red/platform/dos-console?: yes]
	]

	redOpenLogWindow: func [return: [logic!]][
		#if OS = 'Windows [red/platform/open-console]
	]

	redCloseLogWindow: func [return: [logic!]][
		#if OS = 'Windows [red/platform/close-console]
	]
	
	redUnset: func [
		return: [red-unset!]
		/local
			cell [red-unset!]
	][
		CHECK_LIB_OPENED_RETURN(red-unset!)
		cell: as red-unset! ring/alloc
		cell/header: TYPE_UNSET
		cell
	]

	redNone: func [
		return: [red-none!]
		/local
			cell [red-none!]
	][
		CHECK_LIB_OPENED_RETURN(red-none!)
		cell: as red-none! ring/alloc
		cell/header: TYPE_NONE
		cell
	]
	
	redLogic: func [
		bool	[integer!]
		return: [red-logic!]
		/local
			cell [red-logic!]
	][
		CHECK_LIB_OPENED_RETURN(red-logic!)
		cell: as red-logic! ring/alloc
		cell/header: TYPE_LOGIC
		cell/value: as-logic bool
		cell
	]
	
	redDatatype: func [
		type	[integer!]
		return: [red-datatype!]
		/local
			cell [red-datatype!]
	][
		CHECK_LIB_OPENED_RETURN(red-datatype!)
		cell: as red-datatype! ring/alloc
		cell/header: TYPE_DATATYPE
		cell/value: type
		cell
	]
	
	redInteger: func [
		n		[integer!]
		return: [red-integer!]
	][
		CHECK_LIB_OPENED_RETURN(red-integer!)
		integer/make-at ring/alloc n
	]
	
	redFloat: func [
		f		[float!]
		return: [red-float!]
	][
		CHECK_LIB_OPENED_RETURN(red-float!)
		float/make-at ring/alloc f
	]
	
	redString: func [
		s		[c-string!]
		return: [red-value!] "String! or error! value"
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		ring/store import-string s names/redString yes
	]
	
	redPair: func [
		x		[integer!]
		y		[integer!]
		return: [red-pair!]
	][
		CHECK_LIB_OPENED_RETURN(red-pair!)
		pair/make-at ring/alloc x y
	]
	
	redTuple: func [
		r		[integer!]
		g		[integer!]
		b		[integer!]
		return: [red-tuple!]
	][
		CHECK_LIB_OPENED_RETURN(red-tuple!)
		tuple/make-rgba ring/alloc r g b -1
	]
	
	redTuple4: func [
		r		[integer!]
		g		[integer!]
		b		[integer!]
		a		[integer!]
		return: [red-tuple!]
	][
		CHECK_LIB_OPENED_RETURN(red-tuple!)
		tuple/make-rgba ring/alloc r g b a
	]
	
	redSymbol: func [
		s		[c-string!]
		return: [integer!]								;-- symbol ID, -1 if error
		/local
			word [red-word!]
	][
		CHECK_LIB_OPENED_RETURN_INT
		either encoding-in = UTF8 [
			symbol/make s
		][
			word: as red-word! redWord s
			either TYPE_OF(word) = TYPE_WORD [word/symbol][-1]
		]
	]
	
	redWord: func [
		s		[c-string!]
		return: [red-value!]
		/local
			str [red-string!]
			res	[red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		either encoding-in = UTF8 [
			as red-value! word/make-at symbol/make s ring/alloc
		][
			res: load-string s names/redWord
			if last-error <> null [return last-error]
			either TYPE_OF(res) = TYPE_BLOCK [
				ring/store block/rs-head as red-block! res
			][
				last-error: as red-value! error/create
					TO_ERROR(syntax invalid)
					as red-value! datatype/push TYPE_WORD
					res
					null
				last-error
			]
		]
	]
	
	redBlock: func [
		[variadic]
		return: [red-block!]
		/local
			blk	 [red-block!]
			list [int-ptr!]
			p	 [int-ptr!]
	][
		CHECK_LIB_OPENED_RETURN(red-block!)
		list: system/stack/frame
		list: list + 2									;-- jump to 1st argument
		p: list
		
		while [p/value <> 0][p: p + 1]
		blk: block/make-at
			as red-block! ring/alloc
			(as-integer p - list) >> 2
		
		while [list/value <> 0][
			block/rs-append blk as red-value! list/value
			list: list + 1
		]
		blk
	]
	
	redPath: func [
		[variadic]
		return: [red-path!]
		/local
			path [red-path!]
			list [int-ptr!]
			p	 [int-ptr!]
	][
		CHECK_LIB_OPENED_RETURN(red-path!)
		list: system/stack/frame
		list: list + 2									;-- jump to 1st argument
		p: list
		
		while [p/value <> 0][p: p + 1]
		path: as red-path! block/make-at
			as red-block! ring/alloc
			(as-integer p - list) >> 2
		
		while [list/value <> 0][
			block/rs-append as red-block! path as red-value! list/value
			list: list + 1
		]
		path/header: TYPE_PATH
		path
	]
	
	redLoadPath: func [
		src		[c-string!]
		return: [red-value!]
		/local
			blk	[red-block!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		blk: as red-block! load-string src names/redLDPath
		ring/store either TYPE_OF(blk) = TYPE_BLOCK [
			block/rs-head blk
		][
			as red-value! blk
		]
	]
	
	redMakeSeries: func [
		type	[integer!]
		size	[integer!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/action [
			datatype/push type
			integer/push size
			actions/make*
			stack/unwind-last
		])
	]
	
	redCInt32: func [
		int		[red-integer!]
		return: [integer!]
	][
		CHECK_LIB_OPENED_RETURN_INT
		if TYPE_OF(int) <> TYPE_INTEGER [make-error names/redCInt32]
		int/value
	]
	
	redCDouble: func [
		fl		[red-float!]
		return: [float!]
	][
		CHECK_LIB_OPENED_RETURN(float!)
		if TYPE_OF(fl) <> TYPE_FLOAT [make-error names/redCDouble]
		fl/value
	]
	
	redCString: func [
		str		[red-string!]
		return: [c-string!]
		/local
			len [integer!]
			s	[c-string!]
	][
		CHECK_LIB_OPENED_RETURN(c-string!)
		if TYPE_OF(str) <> TYPE_STRING [
			make-error names/redCString
			return null
		]
		switch encoding-out [
			UTF8	[len: -1 s: unicode/to-utf8 str :len]
			UTF16	[s: unicode/to-utf16 str]
			VARIANT [
				;v: declare tagVARIANT
				;v/data1: VT_BSTR
				;v/data3: as-c-string SysAllocString #u16 "Hello!"
				s: null
			]
		]
		s
	]

	#either OS = 'Windows [
		redVString: func [
			str	[red-string!]
			var	[tagVARIANT]
		][
			CHECK_LIB_OPENED
			if TYPE_OF(str) <> TYPE_STRING [
				make-error names/redVString
				exit
			]
			SysFreeString as byte-ptr! var/data3
			;var/data1: VT_BSTR
			var/data3: as-integer SysAllocString unicode/to-utf16 str
		]
	][
		redVString: does []								;-- place-holder
	]
	
	redSet: func [
		"Set a word to a value in global context"
		id		[integer!]	 "symbol ID of the word to set"
		value	[red-value!] "value to be referred to"
		return: [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		_context/set-global id value
	]
	
	redGet: func [
		"Get the value referenced by a word in global context"
		id		[integer!]	 "Symbol ID of the word to get"
		return: [red-value!] "Value referred by the word"
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		_context/get-global id
	]
	
	redSetPath: func [
		path	[red-path!]
		value	[red-value!]
		return: [red-value!]
		/local
			p [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		block/rs-clear cmd-blk
		p: block/rs-append cmd-blk as red-value! path
		p/header: TYPE_SET_PATH
		block/rs-append cmd-blk value
		ring/store do-safe cmd-blk names/redSetPath
	]
	
	redGetPath: func [
		path	[red-path!]
		return: [red-value!]
		/local
			p [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		block/rs-clear cmd-blk
		p: block/rs-append cmd-blk as red-value! path
		ring/store do-safe cmd-blk names/redGetPath
	]
	
	redTypeOf: func [
		value	[red-value!]
		return: [integer!]
	][
		TYPE_OF(value)
	]
	
	redCall: func [
		[variadic]
		return: [red-value!]
		/local
			list [int-ptr!]
			p	 [int-ptr!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		list: system/stack/frame
		list: list + 2									;-- jump to 1st argument
		p: list
		
		block/rs-clear cmd-blk
		
		while [list/value <> 0][
			block/rs-append cmd-blk as red-value! list/value
			list: list + 1
		]
		ring/store do-safe cmd-blk names/redCall
	]
	
	redAppend: func [
		series	[red-series!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redAppend [
			stack/push as red-value! series
			stack/push value
			actions/append* -1 -1 -1
			stack/unwind-last
		])
	]
		
	redChange: func [
		series	[red-series!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redChange [
			stack/push as red-value! series
			stack/push value
			actions/change* -1 -1 -1
			stack/unwind-last
		])
	]
	
	redClear: func [
		series	[red-series!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redClear [
			stack/push as red-value! series
			actions/clear*
			stack/unwind-last
		])
	]
	
	redCopy: func [
		series	[red-series!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redCopy [
			stack/push as red-value! series
			actions/copy* -1 -1 -1
			stack/unwind-last
		])
	]
	
	redFind: func [
		series	[red-series!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redFind [
			stack/push as red-value! series
			stack/push value
			actions/find* -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
			stack/unwind-last
		])
	]

	redIndex: func [
		series	[red-series!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redIndex? [
			stack/push as red-value! series
			actions/index?*
			stack/unwind-last
		])
	]
	
	redLength: func [
		series	[red-series!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redLength? [
			stack/push as red-value! series
			actions/length?*
			stack/unwind-last
		])
	]
	
	redMake: func [
		proto	[red-value!]
		spec	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redMake [
			stack/push proto
			stack/push spec
			actions/make* -1 -1 -1
			stack/unwind-last
		])
	]
	
	redMold: func [
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redMold [
			stack/push value
			actions/mold* -1 -1 -1 -1
			stack/unwind-last
		])
	]

	redPick: func [
		series	[red-series!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redPick [
			stack/push as red-value! series
			stack/push value
			actions/pick*
			stack/unwind-last
		])
	]
	
	redPoke: func [
		series	[red-series!]
		index	[red-value!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redPoke [
			stack/push as red-value! series
			stack/push index
			stack/push value
			actions/poke*
			stack/unwind-last
		])
	]
	
	redPut: func [
		series	[red-series!]
		index	[red-value!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redPut [
			stack/push as red-value! series
			stack/push index
			stack/push value
			actions/put* -1
			stack/unwind-last
		])
	]

	redRemove: func [
		series	[red-series!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redRemove [
			stack/push as red-value! series
			actions/remove* -1
			stack/unwind-last
		])
	]
	
	redSelect: func [
		series	[red-series!]
		value	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redSelect [
			stack/push as red-value! series
			stack/push value
			actions/select* -1 -1 -1 -1 -1 -1 -1 -1 -1
			stack/unwind-last
		])
	]
	
	redSkip: func [
		series	[red-series!]
		offset	[red-integer!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redSkip [
			stack/push as red-value! series
			stack/push as red-value! offset
			actions/skip*
			stack/unwind-last
		])
	]

	redTo: func [
		proto	[red-value!]
		spec	[red-value!]
		return: [red-value!]
		/local
			res [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		TRAP_ERRORS(names/redTo [
			stack/push proto
			stack/push spec
			actions/to*
			stack/unwind-last
		])
	]

	redRoutine: func [
		name	[red-word!]
		desc	[c-string!]
		ptr		[byte-ptr!]
		return: [red-value!]
		/local
			spec [red-block!]
			blk  [red-block!]
			res	 [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		spec: as red-block! load-string desc names/redRoutine
		either TYPE_OF(spec) <> TYPE_BLOCK [
			as red-value! spec
		][
			spec: as red-block! block/rs-head spec
			if TYPE_OF(spec) <> TYPE_BLOCK [
				return as red-value! error/create
					TO_ERROR(script invalid-arg)
					as red-value! spec
					null null
			]
			TRAP_ERRORS(names/redRoutine [
				_function/validate spec
				stack/unwind-last
			])
			if last-error <> null [return last-error]
			
			blk: as red-block! block/rs-head spec
			
			either TYPE_OF(blk) = TYPE_BLOCK [
				block/rs-append blk as red-value! names/extern
			][
				block/insert-value spec as red-value! extern-blk
			]
			_context/set name as red-value! routine/push spec null as-integer ptr 0 true
		]
	]
	
	redPrint: func [
		value [red-value!]
	][
		CHECK_LIB_OPENED
		stack/mark-native names/print
		stack/push value
		natives/print* yes
		stack/unwind-last
	]

	redProbe: func [
		value	[red-value!]
		return: [red-value!]
	][
		CHECK_LIB_OPENED_RETURN(red-value!)
		#call [probe value]
	]
	
	redHasError: func [
		return: [red-value!]
	][
		last-error
	]
	
	redFormError: func [
		return: [c-string!]
	][
		CHECK_LIB_OPENED_RETURN(c-string!)
		either last-error = null [null][
			redCString form-value last-error -1
		]
	]
	
	#either OS = 'Windows [
		redVFormError: func [
			var	[tagVARIANT]
		][
			CHECK_LIB_OPENED
			either last-error = null [null][
				redVString form-value last-error -1 var
			]
		]
	][
		redVFormError: does []
	]
	
	#export [
		redOpen
		redDo
		redDoBlock
		redDoFile
		redClose
		
		redSetEncoding
		redOpenLogFile
		redCloseLogFile
		redOpenLogWindow
		redCloseLogWindow

		redUnset
		redNone
		redLogic
		redDatatype
		redInteger
		redFloat
		redPair
		redTuple
		redTuple4
		redString
		redSymbol
		redWord
		redBlock
		redPath
		redLoadPath
		redMakeSeries
		
		redCInt32
		redCDouble
		redCString
		redVString
		
		redSet
		redGet
		redSetPath
		redGetPath
		redRoutine
		redTypeOf
		redCall
		
		redAppend
		redChange
		redClear
		redCopy
		redFind
		redIndex
		redLength
		redMake
		redMold
		redPick
		redPoke
		redPut
		redRemove
		redSelect
		redSkip
		redTo
		
		redPrint
		redProbe
		redHasError
		redFormError
		redVFormError
	]
]