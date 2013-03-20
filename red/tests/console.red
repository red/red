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
				AttachConsole: "AttachConsole" [
					processID		[integer!]
					return:			[integer!]
				]
				SetConsoleTitle: "SetConsoleTitleA" [
					title			[c-string!]
					return:			[integer!]
				]
				ReadConsole: "ReadConsoleA" [
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
			MacOSX [  ; TODO: check this
				#define ReadLine-library "libreadline.dylib"
				#define History-library "libhistory.dylib"
			]
			#default [
				#define ReadLine-library "libreadline.so.6"
				#define History-library "libhistory.so.6"
			]
		]
		#import [
			ReadLine-library cdecl [
				read-line: "readline" [  ; Read a line from the console.
					prompt			[c-string!]
					return:			[c-string!]
				]
			]
			History-library cdecl [
				add-history: "add_history" [  ; Add line to the history.
					line			[c-string!]
				]
			]
		]
	]
]

init-console: routine [
	str [string!]
	/local
		ret
][
	#either OS = 'Windows [
		;ret: AttachConsole -1
		;if zero? ret [print-line "ReadConsole failed!" halt]
		
		ret: SetConsoleTitle as c-string! string/rs-head str
		if zero? ret [print-line "ReadConsole failed!" halt]
	][
		print-line as-c-string string/rs-head str
	]
]

input: routine [
	/local
		len ret str buffer
		line
][
	#either OS = 'Windows [
		prin "red>> "

		len: 0
		buffer: allocate 128
		ret: ReadConsole stdin buffer 127 :len null
		if zero? ret [print-line "ReadConsole failed!" halt]
		len: len + 1
		buffer/len: null-byte
		str: string/load as c-string! buffer len
;		free buffer
	][
		line: read-line "red>> "
		if line = null [halt]  ; EOF

		add-history line

		str: string/load line  1 + length? line
;		free as byte-ptr! line
	]
	SET_RETURN(str)
]

q: :quit

init-console "Red Console (Xmas demo edition!)"

print {
-=== Red Console pre-alpha version ===-
(only Latin-1 input supported)
}

while [true][
	unless tail? line: input [
		code: load/all line	
		unless tail? code [
			set/any 'result do code
			unless unset? :result [
				prin "== "
				probe result
			]
		]
	]
]
