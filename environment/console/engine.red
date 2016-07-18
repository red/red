Red [
	Title:	"Red system/console object"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%engine.red
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

system/state/trace?: no									;-- disable stack trace in console by default

system/console: context [

	prompt: "red>> "
	history: make block! 200
	limit:	 67
	catch?:	 no											;-- YES: force script to fallback into the console
	count:	 [0 0 0]									;-- multiline counters for [squared curly parens]

	gui?: #system [logic/box #either gui-console? = yes [yes][no]]
	
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
				file: to-red-file file
				unless src: attempt [read file][
					print "*** Error: cannot access argument file"
					;quit/return -1
				]
				change-dir first split-path file
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
		/extern count
		return: [block!]
	][
		escaped: [#"^^" skip]
		
		parse buffer [
			any [
				escaped
				| pos: #";" if (zero? count/2) :pos remove [skip [thru lf | to end]]
				| #"[" (if zero? count/2 [count/1: count/1 + 1])
				| #"]" (if zero? count/2 [count/1: count/1 - 1])
				| #"(" (if zero? count/2 [count/3: count/3 + 1])
				| #")" (if zero? count/2 [count/3: count/3 - 1])
				| dbl-quote any [escaped | dbl-quote break | skip]
				| #"{" (count/2: count/2 + 1) any [
					escaped
					| #"{" (count/2: count/2 + 1)
					| #"}" (count/2: count/2 - 1) break
					| skip
				]
				| #"}" (count/2: count/2 - 1)
				| skip
			]
		]
		count
	]
	
	try-do: func [code /local result return: [any-type!]][
		set/any 'result try/all [
			either 'halt-request = set/any 'result catch/name code 'console [
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
	
	switch-mode: func [cnt][
		mode: case [
			cnt/1 > 0 ['block]
			cnt/2 > 0 ['string]
			cnt/3 > 0 ['paren]
			'else 	  [do-command 'mono]
		]
		cue: switch mode [
			block  ["[    "]
			string ["{    "]
			paren  ["(    "]
			mono   [none]
		]
	]

	do-command: function [][
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
	
	eval-command: function [line [string!] /extern cue mode][
		if mode = 'mono [change/dup count 0 3]			;-- reset delimiter counters to zero
		
		if any [not tail? line mode <> 'mono][
			either all [not empty? line escape = last line][
				cue: none
				clear buffer
				mode: 'mono								;-- force exit from multiline mode
				print "(escape)"
			][
				cnt: count-delimiters line
				append buffer line
				append buffer lf						;-- needed for multiline modes

				switch mode [
					block  [if cnt/1 <= 0 [switch-mode cnt]]
					string [if cnt/2 <= 0 [switch-mode cnt]]
					paren  [if cnt/3 <= 0 [switch-mode cnt]]
					mono   [either any [cnt/1 > 0 cnt/2 > 0 cnt/3 > 0][switch-mode cnt][do-command]]
				]
			]
		]
	]

	run: function [/no-banner /local p][
		unless no-banner [
			print [
				"--== Red" system/version "==--" lf
				"Type HELP for starting information." lf
			]
		]
		forever [
			eval-command ask any [
				cue
				all [string? set/any 'p do [prompt] :p]
				form :p
			]
		]
	]

	launch: function [/local result][
		either script: read-argument [
			either error? script: try-do [load script][
				print :script
			][
				either not all [
					block? script
					script: find script 'Red
					block? script/2 
				][
					print "*** Error: not a Red program!"
					;quit/return -2
				][
					set/any 'result try-do skip script 2
					if error? :result [print result]
				]
			]
			if any [catch? gui?][run/no-banner]
		][
			run
		]
	]
]

;-- Console-oriented function definitions

ls:		func ['dir [any-type!]][list-dir :dir]
ll:		func ['dir [any-type!]][list-dir/col :dir 1]
pwd:	does [prin mold system/options/path]
halt:	does [throw/name 'halt-request 'console]

cd:	function [
	"Changes the active directory path"
	:dir [file! word! path!] "New active directory of relative path to the new one"
][
	change-dir :dir
]

dir:	:ls
q: 		:quit