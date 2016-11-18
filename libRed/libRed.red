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
		#call [system/lexer/transcode str none none]
		interpreter/eval as red-block! stack/arguments + 1 yes
		stack/arguments
	]
	
	redQuit: func [
		
	][
		
	]
	
	#export cdecl [redBoot redDo redQuit]
]