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

	redBoot: does [red/boot]
	
	redDo: func [
		src		[c-string!]
		return: [red-value!]
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
	
	redQuit: does [
		free as byte-ptr! natives/table
		free as byte-ptr! actions/table
		free as byte-ptr! _random/table
		free as byte-ptr! name-table
		free as byte-ptr! action-table
		free as byte-ptr! cycles/stack
		free as byte-ptr! crypto/crc32-table
	]
	
	#export cdecl [redBoot redDo redQuit]
]