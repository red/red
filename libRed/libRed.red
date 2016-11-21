Red [
	Title:   "LibRed API definition"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.red
	Tabs:	 4
	Config:	 [type: 'dll libRedRT?: yes]
	Needs: 	 'View
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [

	cmd-blk:	as red-block! 0
	extern-blk: as red-block! 0

	names: context [
		print:	word/load "print"
		extern:	word/load "extern"
	]
	
	load-string: func [
		src		[c-string!]		"Red code encoded in UTF-8"
		return: [red-value!]	"Last value or error! value"
		/local
			str [red-string!]
	][
		str: string/load src length? src UTF-8
		stack/mark-eval words/_body
		#call [system/lexer/transcode str none none]
		stack/unwind-last
		stack/arguments
	]
	
	;=== Exported API ===

	redBoot: func [
		"Initialize the Red runtime"
	][
		red/boot
		
		cmd-blk: block/push* 10
		extern-blk: block/push* 1
		block/rs-append extern-blk as red-value! names/extern
	]
	
	redDo: func [
		"Evaluates Red code"
		src		[c-string!]		"Red code encoded in UTF-8"
		return: [red-value!]	"Last value or error! value"
	][
		interpreter/eval as red-block! load-string src yes
		stack/arguments
	]
	
	redQuit: func [
		"Releases dynamic memory allocated by Red runtime"
	][
		;@@ Free the main buffers
		free as byte-ptr! natives/table
		free as byte-ptr! actions/table
		free as byte-ptr! _random/table
		free as byte-ptr! name-table
		free as byte-ptr! action-table
		free as byte-ptr! cycles/stack
		free as byte-ptr! crypto/crc32-table
	]
	
	redInteger: func [
		n		[integer!]
		return: [red-integer!]
	][
		integer/push n
	]
	
	redFloat: func [
		f		[float!]
		return: [red-float!]
	][
		float/push f
	]
	
	redString: func [
		s		[c-string!]
		return: [red-string!]
	][
		string/load s length? s UTF-8
	]
	
	redSymbol: func [
		s		[c-string!]
		return: [integer!]								;-- symbol ID
	][
		symbol/make s
	]
	
	redWord: func [
		s		[c-string!]
		return: [red-word!]
	][
		word/load s
	]
	
	redBlock: func [
		[variadic]
		return: [red-block!]
		/local
			blk	 [red-block!]
			list [int-ptr!]
			p	 [int-ptr!]
	][
		list: system/stack/frame
		list: list + 2									;-- jump to 1st argument
		p: list
		
		while [p/value <> 0][p: p + 1]
		blk: block/push* (as-integer p - list) >> 2
		
		while [list/value <> 0][
			block/rs-append blk as red-value! list/value
			list: list + 1
		]
		blk
	]
	
	redCInt32: func [
		int		[red-integer!]
		return: [integer!]
	][
		int/value
	]
	
	redCDouble: func [
		fl		[red-float!]
		return: [float!]
	][
		fl/value
	]
	
	redCString: func [
		str		[red-string!]
		return: [c-string!]								;-- caller needs to free it
		/local
			len [integer!]
			s	[c-string!]
	][
		len: -1
		s: unicode/to-utf8 str :len
		str/cache: null									;-- detach buffer
		s
	]
	
	redSetGlobalWord: func [
		"Set a word to a value in global context"
		id		[integer!]	 "symbol ID of the word to set"
		value	[red-value!] "value to be referred to"
		return: [red-value!]
	][
		_context/set-global id value
	]
	
	redGetGlobalWord: func [
		"Get the value referenced by a word in global context"
		id		[integer!]	 "Symbol ID of the word to get"
		return: [red-value!] "Value referred by the word"
	][
		_context/get-global id
	]
	
	redTypeOf: func [
		value [red-value!]
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
		list: system/stack/frame
		list: list + 2									;-- jump to 1st argument
		p: list
		
		block/rs-clear cmd-blk
		
		while [list/value <> 0][
			block/rs-append cmd-blk as red-value! list/value
			list: list + 1
		]
		interpreter/eval cmd-blk yes
		stack/arguments
	]
	
	redRoutine: func [
		name	[red-word!]
		desc	[c-string!]
		ptr		[byte-ptr!]
		return: [integer!]								;-- 0: ok, <>0: error
		/local
			spec [red-block!]
			blk  [red-block!]
	][
		spec: as red-block! load-string desc
		either TYPE_OF(spec) <> TYPE_BLOCK [
			1
		][
			spec: as red-block! block/rs-head spec
			if TYPE_OF(spec) <> TYPE_BLOCK [return 1]
			
			_function/validate spec						;@@ catch errors
			blk: as red-block! block/rs-head spec
			
			either TYPE_OF(blk) = TYPE_BLOCK [
				block/rs-append blk as red-value! names/extern
			][
				block/insert-value spec as red-value! extern-blk
			]
			_context/set name as red-value! routine/push spec null as-integer ptr 0 true
			0
		]
	]
	
	redPrint: func [
		value [red-value!]
	][
		stack/mark-native names/print
		stack/push value
		natives/print* yes
		stack/unwind
	]

	redProbe: func [
		value [red-value!]
	][
		#call [probe value]
	]
		
	#export cdecl [
		redBoot
		redDo
		redQuit
		
		redInteger
		redFloat
		redString
		redSymbol
		redWord
		redBlock
		
		redCInt32
		redCDouble
		redCString
		
		redSetGlobalWord
		redGetGlobalWord
		redRoutine
		redTypeOf
		redCall
		
		redPrint
		redProbe
	]
]