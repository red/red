Red [
	Title:	"Red console"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%console.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#system-global [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				AttachConsole: 	 "AttachConsole" [
					processID		[integer!]
					return:			[integer!]
				]
				SetConsoleTitle: "SetConsoleTitleA" [
					title			[c-string!]
					return:			[integer!]
				]
				ReadConsole: 	 "ReadConsoleA" [
					consoleInput	[integer!]
					buffer			[byte-ptr!]
					charsToRead		[integer!]
					numberOfChars	[int-ptr!]
					inputControl	[int-ptr!]
					return:			[integer!]
				]
			]
		]
	][
		#switch OS [
			MacOSX [
				#define ReadLine-library "libreadline.dylib"
			]
			#default [
				#define ReadLine-library "libreadline.so.6"
				#define History-library  "libhistory.so.6"
			]
		]
		#import [
			ReadLine-library cdecl [
				read-line: "readline" [  ; Read a line from the console.
					prompt			[c-string!]
					return:			[c-string!]
				]
				rl-bind-key: "rl_bind_key" [
					key				[integer!]
					command			[integer!]
					return:			[integer!]
				]
				rl-insert:	 "rl_insert" [
					count			[integer!]
					key				[integer!]
					return:			[integer!]
				]
			]
			#if OS <> 'MacOSX [
				History-library cdecl [
					add-history: "add_history" [  ; Add line to the history.
						line		[c-string!]
					]
				]
			]
		]

		rl-insert-wrapper: func [
			[cdecl]
			count   [integer!]
			key	    [integer!]
			return: [integer!]
		][
			rl-insert count key
		]
		
	]
]

Windows?: system/platform = 'Windows

init-console: routine [
	str [string!]
	/local
		ret
][
	#either OS = 'Windows [
		;ret: AttachConsole -1
		;if zero? ret [print-line "ReadConsole failed!" halt]
		
		ret: SetConsoleTitle as c-string! string/rs-head str
		if zero? ret [print-line "SetConsoleTitle failed!" halt]
	][
		rl-bind-key as-integer tab as-integer :rl-insert-wrapper
	]
]

input: routine [
	prompt [string!]
	/local
		len ret str buffer line
][
	#either OS = 'Windows [
		len: 0
		buffer: allocate 128
		print as c-string! string/rs-head prompt
		ret: ReadConsole stdin buffer 127 :len null
		if zero? ret [print-line "ReadConsole failed!" halt]
		len: len + 1
		buffer/len: null-byte
		str: string/load as c-string! buffer len
;		free buffer
	][
		line: read-line as c-string! string/rs-head prompt
		if line = null [halt]  ; EOF

		 #if OS <> 'MacOSX [add-history line]

		str: string/load line  1 + length? line
;		free as byte-ptr! line
	]
	SET_RETURN(str)
]

count-delimiters: function [
	buffer	[string!]
	return: [block!]
][
	list: copy [0 0]
	c: none
	
	foreach c buffer [
		either in-comment? [
			switch c [
				#"^/" [in-comment?: false]
			]
		][
			switch c [
				#";" [in-comment?: true]
				#"[" [list/1: list/1 + 1]
				#"]" [list/1: list/1 - 1]
				#"{" [list/2: list/2 + 1]
				#"}" [list/2: list/2 - 1]
			]
		]
	]
	list
]

do-console: function [][
	buffer: make string! 10000
	prompt: red-prompt: "red>> "
	mode:  'mono
	
	switch-mode: [
		mode: case [
			cnt/1 > 0 ['block]
			cnt/2 > 0 ['string]
			'else 	  [
				prompt: red-prompt
				do eval
				'mono
			]
		]
		prompt: switch mode [
			block  ["[^-"]
			string ["{^-"]
			mono   [red-prompt]
		]
	]
	
	eval: [
		code: load/all buffer
		
		unless tail? code [
			set/any 'result do code
			
			unless unset? :result [
				if 67 = length? result: mold/part :result 67 [	;-- optimized for width = 72
					clear back tail result
					append result "..."
				]
				print ["==" result]
			]
		]
		clear buffer
	]

	while [true][
		unless tail? line: input prompt [
			append buffer line
			cnt: count-delimiters buffer

			either Windows? [
				remove skip tail buffer -2			;-- clear extra CR (Windows)
			][
				append buffer lf					;-- Unix
			]
			
			switch mode [
				block  [if cnt/1 <= 0 [do switch-mode]]
				string [if cnt/2 <= 0 [do switch-mode]]
				mono   [do either any [cnt/1 > 0 cnt/2 > 0][switch-mode][eval]]
			]
		]
	]
]

q: :quit

init-console "Red Console"

print {
-=== Red Console alpha version ===-
(only Latin-1 input supported)
}

do-console