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
	#if OS = 'Windows [
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
			]
		]
	]
]

#include %../devices/console/input.red
#include %help.red

read-argument: routine [
	/local
		args [str-array!]
		str	 [red-string!]
][
	if system/args-count <> 2 [
		SET_RETURN(none-value)
		exit
	]
	args: system/args-list + 1							;-- skip binary filename
	str: simple-io/read-txt args/item
	SET_RETURN(str)
]

init-console: routine [
	str [string!]
	/local
		ret
][
	#if OS = 'Windows [
		;ret: AttachConsole -1
		;if zero? ret [print-line "ReadConsole failed!" halt]
		
		ret: SetConsoleTitle as c-string! string/rs-head str
		if zero? ret [print-line "SetConsoleTitle failed!" halt]
	]
]

count-delimiters: function [
	buffer	[string!]
	return: [block!]
][
	list: copy [0 0]
	c: none
	
	foreach c buffer [
		case [
			escaped?	[escaped?: no]
			in-comment? [if c = #"^/" [in-comment?: no]]
			'else [
				switch c [
					#"^^" [escaped?: yes]
					#";"  [if all [zero? list/2 not in-string?][in-comment?: yes]]
					#"["  [unless in-string? [list/1: list/1 + 1]]
					#"]"  [unless in-string? [list/1: list/1 - 1]]
					#"^"" [if zero? list/2 [in-string?: not in-string?]]
					#"{"  [if zero? list/2 [in-string?: yes] list/2: list/2 + 1]
					#"}"  [if 1 = list/2   [in-string?: no]  list/2: list/2 - 1]
				]
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
			block  ["[    "]
			string ["{    "]
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
		unless tail? line: ask prompt [
			append buffer line
			cnt: count-delimiters buffer
			append buffer lf							;-- needed for multiline modes
			
			switch mode [
				block  [if cnt/1 <= 0 [do switch-mode]]
				string [if cnt/2 <= 0 [do switch-mode]]
				mono   [do either any [cnt/1 > 0 cnt/2 > 0][switch-mode][eval]]
			]
		]
	]
]

q: :quit

if script: read-argument [
	script: load script
	either any [
		not script/1 == 'Red
		not block? script/2 
	][
		print "*** Error: not a Red program!"
	][
		do skip script 2
	]
	quit
]
init-console "Red Console"

print {
-=== Red Console alpha version ===-
Type HELP for starting information.
}

do-console