Red [
	Title:	 "Red run-time debugging and helping tools"
	Author:	 "Nenad Rakocevic"
	File:	 %tools.red
	Tabs:	 4
	Rights:	 "Copyright (C) 2021 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

system/tools: context [
	fun-stk:   make block! 10
	expr-stk:  make block! 10
	watching:  make block! 10
	profiling: make block! 10
	
	indent: 0
	hist-length: none
	
	dbg-usage: next {
	`help` or `?`: print a list of debugger's commands.
	`next` or `n` or just ENTER: evaluate next value.
	`continue` or `c`: exit debugging console but continue evaluation.
	`quit` or `q`: exit debugger and stop evaluation.
	`stack` or `s`: display the current calls and expression stack.
	`parents` or `p`: display the parents call stack.
	`:word`: outputs the value of `word`. If it is a `function!`, outputs the local context.
	`:a/b/c`: outputs the value of `a/b/c` path.
	`watch <word1> <word2>...`: watch one or more words. `w` can be used as shortcut for `watch`.
	`-watch <word1> <word2>...`: stop watching one or more words. `-w` can be used as shortcut for `-watch`.
	`+stack`  or `+s`: outputs expression stack on each new event.
	`-stack`  or `-s`: do not output expression stack on each new event.
	`+locals` or `+l`: output local context for each entry in the callstack.
	`-locals` or `-l`: do not output local context for each entry in the callstack.
	`+indent` or `+i`: indent the output of the expression stack.
	`-indent` or `-i`: do not indent the output of the expression stack.
	}
	
	options: context [
		debug: context [
			active?:		no
			show-stack?:	yes
			show-parents?:	no
			show-locals?:	no
			stack-indent?:	no
		]
		trace: context [
			indent?:		yes
		]
		profile: context [
			sort-by: 		'count
			types:			make typeset! [function! action! native! op!]
		]
	]
	
	calc-max: func [used [integer!] return: [integer!]][
		either system/console [system/console/size/x - used][72 - used]
	]
	
	show-context: function [ctx [function! object!]][
		foreach w words-of :ctx [
			prin out: rejoin ["  > " pad mold :w 10 ": "]
			prin mold/flat/part try [get/any :w] calc-max length? out
			either find [none true false unset] :w [print " (word!)"][prin lf]
		]
	]
	
	show-parents: function [event [word!]][
		collect-calls list: make block! 10
		unless empty? fun-stk [
			remove/part list find list first first skip tail fun-stk pick -2x-1 event = 'call
		]
		foreach [w pos] reverse/skip list 2 [
			if all [not unset? get/any w function? get/any w][
				if :w = 'debug [exit]					;-- avoid showing debugger's own call stack
				print ["Call:" w]
				if options/debug/show-locals? [show-context get :w]
			]
		]
	]
	
	show-stack: function [][
		prin either empty? head expr-stk ["^/-empty stack-"][lf]
		indent: 0
		foreach frame head expr-stk [
			unless integer? frame [
				forall frame [
					prin "Stack: "
					if options/debug/stack-indent? [loop indent [prin "  "]]
					print mold/part/flat first frame calc-max 7 + (indent * 2)
					if head? frame [indent: indent + 1]
				]
			]
		]
		prin lf
	]
	
	show-watching: function [][
		foreach w watching [
			prin out: rejoin ["Watch: " mold w ": "]
			print mold/flat/part get/any w calc-max length? out
		]
	]
	
	do-command: function [event [word!]][
		if value? 'ask [								;-- `ask` needs a console sub-system
			watch: [
				list: next list
				either add? [append watching list][
					foreach w list [try [remove find watching to-word w]]
				]
			]
			do [										;-- prevents `ask` from being compiled
				until [
					cmd: trim ask "debug> "
					case [
						cmd/1 = #":" [
							print ["==" mold get/any load next cmd]
						]
						find "+-" cmd/1 [
							add?: cmd/1 = #"+"
							switch first list: load/all next cmd [
								watch w	  [do watch]
								parents p [options/debug/show-parents?: add?]
								stack   s [options/debug/show-stack?:   add?]
								locals  l [options/debug/show-locals?:  add?]
								indent  i [options/debug/stack-indent?: add?]
							]
						]
						'else [
							unless empty? list: load/all cmd [
								switch/default list/1 [
									watch w	  	[add?: yes do watch]
									parents p	[show-parents event]
									stack s		[show-stack]
									next n		[clear cmd]
									continue c  [options/debug/active?: no clear cmd]
									quit q		[halt]
									help ?		[print dbg-usage]
								][
									print "Unknown command!"
								]
							]
						]
					]
					empty? cmd
				]
			]
		]
	]

	debugger: function [
		event  [word!]
		code   [any-block! none!]
		offset [integer!]
		value  [any-type!]
		ref	   [any-type!]
		frame  [pair!]
		/extern expr-stk hist-length
	][
		store: [
			either empty? expr-stk [
				append/only expr-stk to-paren reduce [:value]
			][
				append/only last expr-stk :value
			]
		]
		switch event [
			fetch [
				switch :value [@stop [options/debug/active?: yes] @go [options/debug/active?: no]]
				if paren? expr-stk/1 [remove expr-stk]
			]
			enter [
				unless empty? head expr-stk [
					append expr-stk index? expr-stk
					expr-stk: tail expr-stk
				]
			]
			exit [
				either head? expr-stk [clear expr-stk][
					if paren? expr-stk/1 [set/any 'value expr-stk/1/1]
					idx: first pos: find/reverse tail expr-stk integer!
					clear pos
					expr-stk: at head expr-stk idx
					do store
				]
			]
			open [
				append/only expr-stk reduce [:value]
			]
			push [
				either find [set-word! set-path!] type?/word :value [
					append/only expr-stk reduce [:value]
				][
					do store
				]
			]
			prolog [append/only fun-stk last expr-stk]
			epilog [unless empty? fun-stk [take/last fun-stk]]
			set 
			return [
				take/last expr-stk
				do store
			]
			error [options/debug/active?: yes]			;-- forces debug console activation
			init end  [
				clear fun-stk
				clear expr-stk: head expr-stk
				indent: 0
				sch: system/console/history
				if event = 'init [hist-length: length? sch]
				if event = 'end [
					options/debug/active?: no
					remove/part sch (length? sch) - hist-length
				]
			]
		]
		if all [
			options/debug/active?
			not find [init end enter exit prolog epilog expr] event
		][
			if event = 'fetch [event: 'eval]
			prin out: rejoin ["-----> " uppercase mold event space]
			if event = 'set [
				append out set-ref: rejoin [ref space]
				prin set-ref
			]
			limit: calc-max (length? out) + 1
			print either all [any-function? :value not find [set return push] event][
				prin mold/part/flat :ref limit
				rejoin [" (" mold type? :value #")"]
			][
				mold/part/flat :value limit
			]
			if :code [print ["Input:" mold/only/part/flat skip :code offset calc-max 8]]
			
			unless empty? watching			[show-watching]
			if options/debug/show-parents?	[show-parents event]
			if options/debug/show-stack?	[show-stack]
			
			do-command event
			if event = 'error [options/debug/active?: no]
		]
	]
	
	tracers: context [
	
		dumper: function [
			event  [word!]
			code   [any-block! none!]
			offset [integer!]
			value  [any-type!]
			ref	   [any-type!]
			frame  [pair!]
		][
			print [uppercase form event offset mold/part/flat :ref 30 mold/part/flat :value 30 frame]
		]
		
		;; helpers to keep code readable, unlike `change/only back back tail series last series`
		push:   func [s [series!] i [any-type!] /dup n [integer!]] [append/only/dup s i any [n 1]]
		drop:   func [s [series!] n [integer!]] [clear skip tail s negate n]
		pop:    func [s [series!]] [take/last s]
		top-of: func [s [series!]] [back tail s]

		step: func [s [word! series!] /by value [integer!]][change s s/1 + any [value 1]]
		
		;; context for trace data collected by 'collector' tracer and it's options
		data: context [
			;; input of collector:
			debug?:        no							;-- /debug refinement (raw events output)
			inspect:       none							;-- inspect function to call
			event-filter:  none							;-- events accepted by this inspect function (none = unfiltered)
			scope-filter:  none							;-- list of scopes accepted by this inspect fn (none = unfiltered)
			inspect-sub-exprs?: none					;-- whether to call inspect on subexpressions
			;; entered blocks/parens/paths stack:
			copied-blocks: []							;-- copied
			orig-blocks:   []							;-- original
			;; depth tracking:
			func-depth:    0							;-- function call depth (prologs/epilogs only)
			expr-levels:   []							;-- nesting level of expressions in each block (last 0 = top lvl)
			path:          []							;-- path of refs up to current scope (starts empty)
			;; mirrors of Red stack (of values):
			stack:         []							;-- closer to code (words left alone, series copied)
			eval'd-stack:  []							;-- after evaluation, raw values
			;; entered expression lists:
			copied-top-exprs: []						;-- top-only, inside code copy
			copied-exprs:  []							;-- all exprs, inside code copy
			orig-exprs:    []							;-- all exprs, inside original code
			stack-exprs:   []							;-- all exprs, inside the stack (partially evaluated)
	
			reset: function ["Reset collector's data"] [
				; set [debug? inspect scope-filter event-filter inspect-sub-exprs?] none
				blks: [
					copied-blocks orig-blocks expr-levels path stack eval'd-stack
					copied-top-exprs copied-exprs orig-exprs stack-exprs
				]
				foreach b blks [clear get b]
				self/func-depth: 0
			]

			collector: function [
				"Generic tracer that collects high-level tracing info"
				event  [word!]							;-- Event name
				code   [default!]						;-- Currently evaluated block
				offset [integer!]						;-- Offset in evaluated block
				value  [any-type!]						;-- Value currently processed
				ref	   [any-type!]						;-- Reference of current call
				frame  [pair!]							;-- Stack frame start/top positions
				/extern func-depth
			][
				;; print out event info for debugging
				if debug? [
					code2: any [
						if all [
							code
							not tail? p: skip copy code offset
						][
							p: head change p as tag! uppercase form p/1
							if s: pick tail copied-top-exprs -2 [p: at p index? s]
							p
						]
						code
					]
					print [
						uppercase pad event 7
						pad :ref 10
						pad mold/flat/part :value 20 22
						pad mold/flat/part code2 60 62
						pad expr-levels 8
					]
				]
				
				call: [
					all [								;-- filtering by events, scope, expression level:
						any [none? event-filter  find event-filter event]
						any [none? scope-filter  none? code  find/same/only scope-filter code]
						any [
							inspect-sub-exprs?
							0 = last expr-levels
							all [1 = last expr-levels  find [open call return] event]
						]
						inspect system/tools/tracers/data event code offset :value :ref frame
					]
				]
				
				;; update last top level expression end
				unless any [
					offset < 0
					find [prolog epilog enter exit init end] event
				][
					code-copy: skip last copied-blocks offset
					push drop copied-top-exprs 1 code-copy
					push drop copied-exprs     1 code-copy
					if code [push drop orig-exprs 1 skip code offset]
				]
						
				;; report finishing events before removing relevant data
				if find [return epilog exit expr] event [do call]
				
				switch event [
					prolog [func-depth: func-depth + 1]
					epilog [func-depth: func-depth -1]
					
					fetch [								;-- save original values pushed to the stack
						;; series are copied to report as they appear in code
						;; this should be safe unless we expect literal series to be huge or cyclic
						push stack either series? :value [copy/deep value][:value]
					]
					push [push eval'd-stack :value]		;-- save evaluated values pushed to the stack
					
					open [								;-- mark start of a sub-expression
						unless code [exit]				;@@ temp workaround for do/next
						stkpos: top-of stack			;-- back because func name is already on the stack
						if all [						;@@ workaround for ops but it won't work in `op op op` situation
							word? :value
							op? get/any value
						][
							either value =? pick code offset + 1 [
								reverse stkpos: back stkpos
							][
								offset: offset + 1
							]
						]								;@@ need a more reliable solution
						offset: offset - 1				;-- -1 because open happens after the function name
						push stack-exprs stkpos
						
						push/dup orig-exprs skip code offset 2
						push/dup copied-exprs skip last copied-blocks offset 2
						step top-of expr-levels
					]
					call [push path any [ref <anon>]]	;-- collect evaluation path
					return [							;-- revert both
						unless code [exit]				;@@ temp workaround for do/next
						step/by top-of expr-levels -1
						stkpos: pop stack-exprs			;-- update stack with new value
						push drop eval'd-stack length? stkpos :value
						push clear stkpos :value
						
						drop orig-exprs   2
						drop copied-exprs 2
						pop path
					]
					; error []	;@@
					
					enter [								;-- mark start of an inner block of top-level exprs
						push stack-exprs   tail stack
						push copied-blocks c2: copy/deep code
						push orig-blocks   code
						push expr-levels   0
						
						push/dup copied-top-exprs c2 2
						push/dup orig-exprs       code 2
						push/dup copied-exprs     c2 2
					]
					exit [								;-- revert it
						stkpos: pop stack-exprs
						drop eval'd-stack length? stkpos 
						clear stkpos
						pop copied-blocks
						pop orig-blocks
						pop expr-levels
						
						drop copied-top-exprs 2
						drop orig-exprs       2
						drop copied-exprs     2
					]
					expr [								;-- remove unused expressions from the stack
						stkpos: last stack-exprs
						drop eval'd-stack length? stkpos 
						clear stkpos
						
						if 0 = last expr-levels [
							change/only back top-of copied-top-exprs last copied-top-exprs
						]
						change/only back top-of copied-exprs last copied-exprs
						change/only back top-of orig-exprs   last orig-exprs
					]
				]
				
				;; report starting events after removing relevant data
				unless find [return epilog exit expr] event [do call]
			];; collector function
		];; data context
	
		guided-trace: function [
			"Trace a block of code, providing 'inspect' tracer with collected data"
			inspect [function!] "func [data [object!] event code offset value ref frame]"
			code    [any-type!]
			all?    [logic!]    "Trace all sub-expressions of each expression"
			deep?   [logic!]    "Enter functions and natives"
			debug?  [logic!]    "Dump all events encountered"
		][
			if tracing? [exit]							;-- impossible to hot-swap tracers atm
			data/reset
			data/debug?:       debug?
			data/inspect:      :inspect
			data/inspect-sub-exprs?: all?
			data/event-filter: if block? b: first body-of :inspect [b]
			data/scope-filter: if all [not deep?  any-list? :code] [
				to hash! collect [
					keep/only head code
					parse code rule: [any [
						ahead set b any-block! (keep/only head b) into rule | skip
					]]
				] 
			] 
			do-handler :code :data/collector
		]

		inspector: context [
		
			;; yet another incarnation of this func
			;@@ remove it when we have smarter `ellipsize` func in runtime
			mold-part: function [value [any-type!] part [integer!] /only] [
				r: either only [
					mold/flat/part/only :value part + 1
				][
					mold/flat/part      :value part + 1
				]
				if part < length? r [
					either all [
						any [any-object? :value  block? :value  hash? :value]
						find :r #"["					;-- has opening bracket but no closing one
					][
						clear change skip tail r -5 "...]"
					][
						clear change skip tail r -4 "..."
					]
					clear skip r part					;-- when part < 3-4
				]
				r
			]		
				
			last-path: []								;-- cached, reported only when changed
			
		 	inspect: function [
		 		data   [object!]						;-- collector's stats
				event  [word!]							;-- Event name
				code   [default!]						;-- Currently evaluated block
				offset [integer!]						;-- Offset in evaluated block
				value  [any-type!]						;-- Value currently processed
				ref	   [any-type!]						;-- Reference of current call
				/local word
			][
				[expr error throw push return]
				report?: all select [
					expr [
						not data/inspect-sub-exprs?
						0 = last data/expr-levels				;-- don't report sub-exprs
						not paren? last data/copied-top-exprs	;-- don't report paren as top-level, even if it technically is
					]
					error [true]
					throw [true]
					push [
						data/inspect-sub-exprs?
						any-word? set/any 'word last data/stack
						not same? word last data/eval'd-stack
						not find [yes no on off true false none] word
						not find to [] any-type! word
					]
					return [
						data/inspect-sub-exprs?
					] 
				] event
				any [report? exit]
				
				full:    any [attempt [system/console/size/1] 80]
				width:   full - 7						;-- last column(1) + " => "(4) + min. indent(2)
				left:    min 60 to integer! width / 2	;-- cap at 60 as we don't want it to be huge
				right:   width - left
				indent:  append/dup clear ""          " " full - 1			;-- indent for code
				indent2: append/dup clear skip "  " 2 "`" full - 3			;-- indent for paths: prefixed by "  "
				level:   (length? data/expr-levels) - pick [1 0] 'call = event	;-- 'call' level is deeper by 1
				level:   level % 10 + 1 * 2				;-- cap at 20 as we don't want indent to occupy whole column
				
				either data/inspect-sub-exprs? [
					expr: last data/stack-exprs
					isop?: all [
						3 = length? expr
						word? :expr/1
						op? get/any :expr/1
					]
					either event = 'push [
						expr: back tail expr
					][
						while [set-word? :expr/-1] [expr: back expr]
					]
					if isop? [							;-- locally reorder op calls for more readability
						expr: copy expr
						move p: skip tail expr -3 next p
					]
				][
					p: tail data/copied-top-exprs
					expr: either 'error = event [p/-2][copy/part p/-2 p/-1]
				]
				if empty? expr [exit]					;@@ workaround for [a: 1] vs [a: 1 + 1] issue
				if paren? expr [expr: as [] expr]		;-- otherwise /only won't remove brackets
				if path?  code [expr: as path! expr]
				
				;; print current path, only works in non-/all mode
				unless any [data/inspect-sub-exprs?  data/path == last-path] [
					p: change skip indent2 level 
						uppercase mold-part as path! data/path full - 1 - level
					t: tail data/copied-top-exprs
					pexpr: any [if t/-4 [copy/part t/-4 t/-3] []]		;-- -4..-3 is the parent expression
					if :pexpr/1 == last data/path [pexpr: next pexpr]	;-- don't duplicate last path item
					unless empty? pexpr [
						change change p " " mold-part/only pexpr (length? p) - 1
					]
					print indent2
					append clear last-path data/path
				]
				
				;; print expression and result
				change        skip indent level       mold-part/only expr left - level
				change change skip indent left " => " mold-part :value right
				print indent
			];; inspect function
		];; inspector context
	];; tracers context

	profiler: function [
		event  [word!]
		code   [any-block! none!]
		offset [integer!]
		value  [any-type!]
		ref	   [any-type!]
		frame  [pair!]
	][
		[init call return prolog epilog]				;-- request only those events
		anon: [0]
		
		switch event [
			prolog [									;-- entering a function!
				time: now/precise
				poke skip tail fun-stk -2 1 time		;-- update start-time
			]
			epilog [									;-- exiting a function!
				poke back tail fun-stk 1 now/precise	;-- update start-time
			]
			call   [
				if all [typeset? opt: options/profile/types find opt type? :value][
					if any-function? :ref [ref: append copy <anon> anon/1: anon/1 + 1]
					either pos: find/only/skip profiling ref 3 [
						pos/2: pos/2 + 1
					][
						repend profiling [ref 1 0]
					]
					repend fun-stk [ref now/precise none] ;-- [name start-time end-time]
				]
			]
			return [
				time: now/precise
				unless empty? fun-stk [
					entry: skip tail fun-stk -3
					pos: find/only/skip profiling first entry 3
					pos/3: pos/3 + difference any [entry/3 time] entry/2
					clear entry
				]
			]
			init [
				clear profiling
				clear fun-stk
			]
		]
	]
	
	do-handler: func [code [any-type!] handler [function!]][
		either find [file! url!] type?/word :code [
			do-file code :handler						;-- delay handler triggering once resource is acquired
		][
			do/trace :code :handler
		]
	]
	
	set 'profile function [
		"Profile the argument code, counting calls and their cumulative duration, then print a report"
		code [any-type!] "Code to profile"
		/by
			cat [word!]	 "Sort by: 'name, 'count, 'time"
	][
		saved: values-of options/profile
		options/profile/sort-by: any [cat 'count]
		
		set/any 'res do-handler :code :profiler
		if value? 'res [print ["==" mold/part :res calc-max 2 lf]]
		
		by: select [name 1 count 2 time 3] options/profile/sort-by
		either by = 1 [
			sort/skip/compare profiling 3 by			;-- sort in alphabetical order
		][
			sort/skip/reverse/compare profiling 3 by	;-- sort count/time in decreasing order
		]
		rank: 1
		foreach [name cnt duration] profiling [			;-- generate report
			if unset? name [name: "<anonymous>"]
			print [pad append copy "#" rank 4 pad name 16 #"|" pad cnt 10 #"|" pad duration 10]
			rank: rank + 1
		]
		set options/profile saved
		()
	]
	
	set 'trace function [
		[no-trace]
		"Runs argument code and prints an evaluation trace; also turns on/off tracing"
		code [any-type!] "Code to trace or tracing mode (logic!)"
		/raw   "Switch to raw interpreter events tracing"
		/deep  "Trace into functions and natives (incompatible with /here)"
		/all   "Trace all sub-expressions of each expression"
		/debug "Used internally to debug the tracer itself (outputs all events)"
	][
		either logic? :code [
			#system [
				use [bool [red-logic!]][
					bool: as red-logic! ~code			;@@ implement a clean way to access locals from R/S code
					assert TYPE_OF(bool) = TYPE_LOGIC
					interpreter/tracing?: bool/value and interpreter/trace?
				]
			]
		][
			either raw [
				do-handler :code :tracers/dumper
			][
				tracers/guided-trace :tracers/inspector/inspect :code all deep debug
			]
		]
	]
	
	set 'debug func [
		"Runs argument code through an interactive debugger"
		code [any-type!] "Code to debug"
		/later			 "Enters the interactive debugger later, on reading @stop value"
	][
		saved: values-of options/debug
		options/debug/active?: not later
		do-handler :code :debugger
		set options/debug saved
		()
	]
]
