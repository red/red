Red [
	Title:	"Red system/console object"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%console-object.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
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

system/console: context [

	prompt: "red>> "
	history: make block! 200
	limit:	 67
	catch?:	 no											;-- YES: force script to fallback into the console

	gui?: #system [logic/box #either gui-console? = 'yes [yes][no]]
	
	read-argument: function [][
		if args: system/options/args [
			--catch: "--catch"
			if system/console/catch?: make logic! pos: find args --catch [
				remove/part pos 1 + length? --catch		;-- remove extra space too
			]

			quote-arg: [{"} any [ahead [#"^""] break | skip] {"}]
			normal-arg: complement charset space
			rule: [quote-arg | normal-arg]
			args: parse args [collect [any [keep copy value some rule | skip]]]
			while [all [not tail? args find/match args/1 "--"]][args: next args] ;-- skip options

			unless tail? args [
				file: args/1
				if file/1 = dbl-quote [
					remove file
					remove back tail file
				]
				unless src: attempt [read to file! file][
					print "*** Error: cannot access argument file"
					;quit/return -1
				]
			]
			src
		]
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
	
	try-do: func [code /local result return: [any-type!]][
		set/any 'result try/all [
			either 'halt-request = catch/name [set/any 'result do code] 'console [
				print "(halted)"						;-- return an unset value
			][
				:result
			]
		]
		:result
	]

	line:   make string! 100
	buffer: make string! 10000
	cue:    none
	mode:   'mono

	eval-command: function [line [string!] /extern cue mode][
		switch-mode: [
			mode: case [
				cnt/1 > 0 ['block]
				cnt/2 > 0 ['string]
				'else 	  [
					do eval
					'mono
				]
			]
			cue: switch mode [
				block  ["[    "]
				string ["{    "]
				mono   [none]
			]
		]

		eval: [
			if error? code: try [load/all buffer][print code]
			
			unless any [error? code tail? code][
				set/any 'result try-do code
				
				case [
					error? :result [
						print result
					]
					not unset? :result [
						if limit = length? result: mold/part :result limit [	;-- optimized for width = 72
							clear back tail result
							append result "..."
						]
						print ["==" result]
					]
				]
				unless last-lf? [prin lf]
			]
			clear buffer
		]
	
		unless tail? line [
			either all [not empty? line escape = last line][
				cue: none
				clear buffer
				mode: 'mono							;-- force exit from multiline mode
				print "(escape)"
			][
				append buffer line
				cnt: count-delimiters buffer
				append buffer lf					;-- needed for multiline modes

				switch mode [
					block  [if cnt/1 <= 0 [do switch-mode]]
					string [if cnt/2 <= 0 [do switch-mode]]
					mono   [do either any [cnt/1 > 0 cnt/2 > 0][switch-mode][eval]]
				]
			]
		]
	]

	run: function [][
		print [
			"--== Red" system/version "==--" lf
			"Type HELP for starting information." lf
		]
		forever [eval-command ask any [cue prompt]]
	]

	launch: function [][
		if script: read-argument [
			either not all [
				script: attempt [load script]
				script: find script 'Red
				block? script/2 
			][
				print "*** Error: not a Red program!"
				;quit/return -2
			][
				set/any 'result try-do skip script 2
				if error? :result [print result]
				if catch? [run]
			]
			;quit
			exit
		]
		run
	]
]

halt: does [throw/name 'halt-request 'console]
q: :quit
