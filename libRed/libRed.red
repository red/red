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

	redBoot: func [
		"Initialize the Red runtime"
	][
		red/boot
	]
	
	redDo: func [
		"Evaluates Red code"
		src		[c-string!]		"Red code encoded in UTF-8"
		return: [red-value!]	"Last value or error! value"
		/local
			str [red-string!]
	][
		str: string/load src length? src UTF-8
		stack/mark-eval words/_body
		#call [system/lexer/transcode str none none]
		stack/unwind-last
		interpreter/eval as red-block! stack/arguments yes
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
	
	redWord: func [
		s		[c-string!]
		return: [integer!]								;-- symbol ID
	][
		symbol/make s
	]
	
	redCInt32: func [									;@@ make a macro instead?
		int		[red-integer!]
		return: [integer!]
	][
		int/value
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
	
	
	#export cdecl [
		redBoot
		redDo
		redQuit
		redInteger
		redFloat
		redString
		redWord
		redCInt32
		redCString
		redSetGlobalWord
		redGetGlobalWord
	]
]