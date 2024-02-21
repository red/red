Red [
	Title:	"Red system/console object"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%engine.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2018 Red Foundation. All rights reserved."
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

	def-prompt: ">> "
	def-result: "=="
	prompt:		def-prompt
	result:		def-result
	history:	make block! 200
	size:		0x0
	catch?:		no										;-- YES: force script to fallback into the console
	delimiters:	[]										;-- multiline delimiters for [squared curly parens]
	ws:			charset " ^/^M^-"

	gui?:	#system [logic/box #either gui-console? = yes [yes][no]]
	
	read-argument: function [/local value][
		if args: system/script/args [

			args: system/options/args
			--catch: "--catch"
			while [
				all [
					not tail? args
					find/match args/1 "--"	 			;-- skip options
					args/-1 <> "--"						;-- stop after "--"
				]
			][
				either --catch <> args/1 [
					args: next args
				][
					remove args
					system/console/catch?: yes
				]
			]

			unless tail? args [
				file: to-red-file args/1
				
				either error? set/any 'src try/keep [read file][
					print src
					src: none
					;quit/return -1
				][
					system/options/script: file
					remove/part system/options/args next args 	;-- remove options & script name
					#either config/OS = 'Windows [=quote=: {"}][=quote=: {'}]
					=quoted-switch=: [=quote= {--} s: thru [e: =quote= any ws | end]]
					=normal-switch=: ["--" s: thru [e: some ws | end]]
					parse system/script/args [
						any ws args: any [							;-- skip switches
							[ =quoted-switch= | =normal-switch= ]
							args: not if (same? s e) 				;-- stop after "--"
						]
					]
					#either config/OS = 'Windows [
						parse args [any [=quote= thru [=quote= | end] | not ws skip] any ws args:]
					][
						;-- this relies on `get-cmdline-args` logic:
						parse args [any [=quote= thru [=quote= | end] | "\'" | not ws skip] any ws args:]
					]
					remove/part head args args 			;-- remove options & script name
				]
				path: first split-path file
				if path <> %./ [change-dir path]
			]
			src
		]
	]

	init: routine [					;-- only used by CLI console
		str [string!]
		/local
			ret  [integer!]
			size [red-pair!]
	][
		#either OS = 'Windows [
			;ret: AttachConsole -1
			;if zero? ret [print-line "ReadConsole failed!" halt]

			ret: SetConsoleTitle as c-string! string/rs-head str
			if zero? ret [print-line "SetConsoleTitle failed!" halt]
		][
			#if gui-console? = no [terminal/pasting?: no]
		]
		#if gui-console? = no [
			terminal/init
			terminal/init-globals
			size: as red-pair! #get system/console/size
			if any [zero? size/x zero? size/y][
				size/x: 80			;-- set defaults when working with stdout
				size/y: 50			;   as many output funcs rely on it
			]
		]
	]

	delimiter-map: reduce [
		block!		#"["
		paren!		#"("
		string!		#"{"
		map!		#"("
		point2D!	#"("
		path!		#"/"
		lit-path!	#"/"
		get-path!	#"/"
		set-path!	#"/"
	]
	
	count: function [s [string!] c [char!] /reverse return: [integer!]][
		cnt: 0
		step: pick [-1 1] reverse
		loop length? head s [either s/1 = c [cnt: cnt + 1 s: skip s step][return cnt]]
		cnt
	]
	
	delimiter-lex: function [
		event	[word!]
		input	[string! binary!]
		type	[datatype! word! none!]
		line	[integer!]
		token
		return:	[logic!]
	][
		[open close error]
		switch event [
			open [
				append delimiters delimiter-map/:type
				true
			]
			close [
				if delimiter-map/:type <> last delimiters [throw 'stop]	;-- unmatched ")" "]"
				take/last delimiters
				true
			]
			error [
				if type = error! [throw 'stop]			;-- unmatched "}"
				if all [								;-- block! paren! map! have open-event, so just match delimiters
					find [block! paren! map! point2D!] to-word type
					delimiter-map/:type = last delimiters
					not find input #")"
					not find input #"]"
				][
					throw 'break
				]
				back2: back back tail delimiters
				
				if all [type = paren! #"/" = back2/1][	;-- paren! in path
					remove back2
					throw 'break
				]
				if type = tag! [						;-- tag! haven't open-event
					append delimiters #"<"
					throw 'break
				]
				if all [
					type = binary!						;-- binary! haven't open-event
					#"}" <> pick tail input -2
				][
					append delimiters #"{"
					throw 'break
				]
				if type = string! [
					either input/(token/x - token/y) = #"%" [ ;-- raw-string! haven't open-event
						begin: count head input #"%"
						end: count/reverse back back tail input #"%" ;-- skip ending LF
						if begin > end [
							append delimiters #"{"
							throw 'break
						]
					][
						if delimiter-map/:type = last delimiters [ ;-- other string! if have open-event, do match
							throw 'break
						]
					]
				]
				throw 'stop
			]
		]
	]
	
	check-delimiters: function [
		buffer	[string!]
		return: [logic!]
	][
		clear delimiters
		'stop <> catch [transcode/trace buffer :delimiter-lex] ;-- catches 'stop and 'break
	]
	
	try-do: func [code /local result return: [any-type!]][
		set/any 'result try/all/keep [
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

	do-command: function [/local result err p][
		if error? code: try/keep [load/all buffer][print code]

		unless any [error? code tail? code][
			set/any 'result try-do code
			case [
				error? :result [
					print [result lf]
				]
				not unset? :result [
					if error? set/any 'err try/keep [	;-- catch eventual MOLD errors
						limit: size/x - 3
						result: either float? :result [
							form/part :result limit + 5 ;-- form a bit more than needed
						][
							mold/part :result limit + 5 ;-- mold a bit more than needed
						]
						if limit < length? result [
							clear change at result limit - length? prompt "..."
						]
						prefix: any [
							all [string? set/any 'p try/all [do [system/console/result]] :p]
							all [error? :p p/where: "system/console/result" print form :p def-result]
						]
						print [prefix result]
					][
						print :err
					]
				]
			]
			if all [not last-lf? not gui?][prin lf]
		]
		clear buffer
	]
	
	eval-command: function [line [string!] /extern cue mode][
		if mode = 'mono [clear delimiters]				;-- reset delimiter stack
		
		if any [not tail? line mode <> 'mono][
			either all [not empty? line escape = last line][
				cue: none
				clear buffer
				mode: 'mono								;-- force exit from multiline mode
				print "(escape)"
			][
				cue: none
				append buffer line
				append buffer lf						;-- needed for multiline modes
				either check-delimiters buffer [
					either empty? delimiters [
						do-command						;-- no delimiters error
						mode: 'mono
					][
						mode: 'other
						cue: rejoin [last delimiters "    "]
					]
				][
					do-command							;-- lexer will throw error
					mode: 'mono
				]
			]
		]
	]

	run: function [/no-banner /local p /extern prompt][
		unless no-banner [
			print [
				"--== Red" system/version "==--" lf
				"Type HELP for starting information." lf
			]
		]
		forever [
			eval-command ask any [
				cue
				all [string? set/any 'p try/all [do [prompt]] :p]
				all [error? :p p/where: "system/console/prompt" print :p prompt: def-prompt]
				form :p
			]
		]
	]

	launch: function [/local result found?][
		either script: src: read-argument [
			parse/case script [some [pos: "Red" opt "/System" any ws #"[" (found?: yes) break | skip]]
			either all [found? script: pos][
				either error? script: try-do [load script][
					print :script
				][
					either not all [
						block? script
						script: find/case script 'Red
						block? script/2 
					][
						print [
							"*** Error:"
							either find src "Red/System" [
								"contains Red/System code which requires compilation!"
							][
								"not a Red program!"
							]
						]
						;quit/return -2
					][
						expand-directives script
						set/any 'result try-do skip script 2
						if error? :result [print result]
					]
				]
			][
				print "*** Error: Red header not found!"
			]
			if any [catch? all [gui? gui-console-ctx/win/visible?]][
				if all [catch? gui?][gui-console-ctx/win/visible?: yes]
				run/no-banner
			]
		][
			run
		]
	]
]

;-- Console-oriented function definitions

list-dir: function [
	"Displays a list of files and directories from given folder or current one"
	dir [any-type!]  "Folder to list"
	/col			 "Forces the display in a given number of columns"
		n [integer!] "Number of columns"
][
	unless value? 'dir [dir: %.]
	
	unless find [file! word! path!] type?/word :dir [
		cause-error 'script 'expect-arg ['list-dir type? :dir 'dir]
	]
	list: read normalize-dir dir
	limit: system/console/size/x - 13
	max-sz: to-integer either n [
		limit / n - n									;-- account for n extra spaces
	][
		n: max 1 limit / 22								;-- account for n extra spaces
		22 - n
	]

	while [not tail? list][
		loop n [
			if max-sz <= length? name: list/1 [
				name: append copy/part name max-sz - 4 "..."
			]
			prin tab
			prin pad form name max-sz
			prin " "
			if tail? list: next list [break]
		]
		prin lf
	]
	()
]

expand: func [
	"Preprocess the argument block and display the output (console only)"
	blk [block!] "Block to expand"
][
	probe expand-directives/clean blk
]

ls:		func ["Display a directory listing, for the current dir if none is given" 'dir [any-type!]][list-dir :dir]
ll:		func ["Display a single column directory listing, for the current dir if none is given" 'dir [any-type!]][list-dir/col :dir 1]
pwd:	func ["Displays the active directory path (Print Working Dir)"][prin mold system/options/path]
halt:	func ["Stops evaluation and returns to the input prompt"][throw/name 'halt-request 'console]

cd:	function [
	"Changes the active directory path"
	:dir [file! word! path!] "New active directory of relative path to the new one"
][
	change-dir :dir
]

dir:	:ls
q: 		:quit
