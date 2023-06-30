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
	
		emit: :print									;-- overridden by the tests suite
		
		;; yet another incarnation of this func
		;@@ remove it when we have smarter `ellipsize` func in runtime
		opening-marker: charset "([{<^""
		closing-markers: "()[]{}<>^"^""
		mold-part: function [value [any-type!] part [integer!] /only] [
			r: mold/flat/part/:only :value part + 1
			if part < length? r [
				open: find/part r opening-marker skip tail r -5
				clear either open [
					close: select closing-markers open/1 
					change change skip tail r -5 "..." close 
				][
					change skip tail r -4 "..."
				]
				clear skip r part						;-- when part < 3-4
			]
			r
		]		
				
		dumper: function [
			event  [word!]
			code   [any-block! none!]
			offset [integer!]
			value  [any-type!]
			ref	   [any-type!]
			frame  [pair!]
		][
			do [emit [uppercase form event offset mold-part :ref 30 mold-part :value 30 frame]]
		]
		
		;; helpers to keep code readable, unlike `change/only back back tail series last series`
		push:   func [s [series!] i [any-type!] /dup n [integer!]] [append/only/dup s :i any [n 1]]
		drop:   func [s [series!] n [integer!]] [clear skip tail s negate n]
		pop:    func [s [series!]] [take/last s]
		top-of: func [s [series!]] [back tail s]
		step:   func [s [series!] /down][change s s/1 + pick [-1 1] down]
		
		;; to display all fetched data in its original unmodified state it is molded
		;; this controls max molded length of every single value before it gets ellipsized
		mold-size: 30
		
		;; free list of blocks to minimize tracer's side effects
		free: context [
			list: make block! 20
			put:  func [block [block!]] [if 100 > length? block [push list clear head block]]
			get:  does [any [pop list  make block! 10]]
			loop 20 [put make block! 10]
		]
		
		;; context for trace data collected by 'collector' tracer and its options
		data: context [
			;; input of collector:
			debug?:          no							;-- /debug refinement (raw events output)
			inspect:         none						;-- inspect function to call
			event-filter:    none						;-- events accepted by this inspect function (none = unfiltered)
			scope-filter:    none						;-- list of scopes accepted by this inspect fn (none = unfiltered)
			inspect-sub-exprs?: none					;-- whether to call inspect on subexpressions
			;; tracked parameters:
			func-depth:      0							;-- function call depth (prolog to epilog)
			expr-depth:      0							;-- nesting level of expressions in each block ('open to return)
			path:            []							;-- path of refs up to current scope (starts empty)
			fetched:         []							;-- original fetched values list
			fetched':        []							;-- same as 'fetched' but everything molded to preserve it
			pushed:          []							;-- pushed and returned values list, making partially evaluated exprs
			pushed':         []							;-- same as 'pushed' but everything molded to preserve it
			subexprs:        []							;-- offsets within pushed/pushed' of last subexpr start (a stack)
			;; saved states to unroll on exception:
			stack:           []							;-- stack of internal call frame (pairs)
			saved:           [func-depth expr-depth fetched fetched' pushed pushed' subexprs]
			stack-period:    2 + length? saved			;-- +frame +path size
			
			save-level: function ["Save current nesting level on the stack" frame [pair!]] [
				push stack frame
				push stack length? path
				foreach word saved [
					push stack value: get word
					set word either block? value [free/get][0] 
				]
			]
			unroll-level: function ["Unroll last nesting level from the stack"] [
				repeat i n: length? saved [				;@@ needs foreach/reverse
					value: get word: pick saved n - i + 1
					if block? value [free/put value]
					set word pop stack 
				]
				clear skip path pop stack				;-- cut path
				pop stack								;-- forget frame
			]
	
			reset: function ["Reset collector's data"] [
				clear path
				clear stack
				set [func-depth expr-depth] 0
				foreach block-name skip saved 2 [clear get block-name]
			]
			
			collector: function [
				"Generic tracer that collects high-level tracing info"
				event  [word!]							;-- Event name
				code   [default!]						;-- Currently evaluated block
				offset [integer!]						;-- Offset in evaluated block
				value  [any-type!]						;-- Value currently processed
				ref	   [any-type!]						;-- Reference of current call
				frame  [pair!]							;-- Stack frame start/top positions
				/extern func-depth expr-depth pushed pushed'
			][
				call: [
					all [								;-- filtering by events, scope, expression level:
						any [none? event-filter  find event-filter event]
						any [none? scope-filter  none? code  find/same/only scope-filter code]
						any [
							inspect-sub-exprs?
							find [error throw] event 
							0 = expr-depth
							all [1 = expr-depth  find [call return] event]
						]
						inspect system/tools/tracers/data event code offset :value :ref frame
					]
				]
				
				;; unroll multiple enter/exit levels at once, after throw/error ('return' from try or 'catch' from catch only)
				;; must be done before 'call', otherwise it may filter out the event by (wrong) expr-depth
				if find [return catch] event [
					saved-frame: pick tail stack negate stack-period
					while [unless tail? stack [saved-frame/1 > frame/1]] [ 
						unroll-level
						saved-frame: pick tail stack negate stack-period
					]
				]
				
				;; report finishing events before removing relevant data
				if find [return epilog exit expr error throw] event [do call]
				
				switch event [
					prolog [func-depth: func-depth + 1]
					epilog [func-depth: func-depth - 1]
					
					fetch [								;-- save fetched values (part of source code interpreter has "seen" so far)
						if any [inspect-sub-exprs? not path? code] [
							push fetched :value
							push fetched' mold-part :value mold-size
						]
					]
					push  [								;-- save evaluated values
						if any [inspect-sub-exprs? not path? code] [
							push pushed :value
							push pushed' mold-part :value mold-size
						]
					]
					
					open [								;-- mark start of a sub-expression
						;; remember previous subexpr start & start a new subexpr
						isop?: any [op? :value op? if word? :value [attempt [get/any value]]]	;@@ REP #113; word may not have context
						push subexprs index? pushed	
						pushed:  either isop? [top-of pushed][tail pushed]
						pushed': either isop? [top-of pushed'][tail pushed']
						;; put function/op name into the subexpr
						push pushed  :value
						push pushed' mold-part :value mold-size
						expr-depth: expr-depth + 1
					]
					call [								;-- collect evaluation path
						push path any [if path? ref [:ref/1] ref <anon>]	;-- simplify path calls to just function names
					]
					return [							;-- revert both
						pop path
						expr-depth: expr-depth - 1
						;; restore previous subexpr and clear the current one
						bgn: any [pop subexprs 1]
						pushed:  at head clear pushed bgn 
						pushed': at head clear pushed' bgn
						;; put returned value into subexpr
						push pushed  :value
						push pushed' mold-part :value mold-size
					]
					enter [								;-- mark start of an inner block of top-level exprs
						unless path? code [save-level frame]
					]
					exit [								;-- revert it
						unless path? code [unroll-level]
						if paren? code [				;-- paren result will be reused
							push pushed  :value
							push pushed' mold-part :value mold-size
						]
					]
					expr [								;-- remove finished expressions from the stack
						foreach word [fetched fetched' pushed pushed'] [
							clear get word
						]
					]
				]
				
				;; report starting events after removing relevant data
				unless find [return epilog exit expr error throw] event [do call]
				
				;; print out event info for debugging
				if debug? [
					do [emit [							;@@ without 'do' emit is hardcoded
						uppercase pad event 7
						pad type? code 6
						pad :ref 12
						pad frame 6
						pad mold-part :value 20 22
						pad form/part fetched' 60 62
						pad func-depth 3
						pad expr-depth 3
						subexprs
					]]
				]
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
		
			fixed-width:    none								;-- used in tests to remove environment effects
			last-path:      []									;-- cached, reported only when changed
			constants:      [yes no on off true false none]		;-- common constant names
			type-names:     to [] any-type!						;-- common type names defined in runtime
			ignored-words:  make hash! compose [(constants) (type-names)]
			fetched-index:  (index? find data/saved 'fetched)  - (length? data/saved) - 1 
			fetched'-index: (index? find data/saved 'fetched') - (length? data/saved) - 1 
						
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
						data/expr-depth = 0				;-- don't report sub-exprs
						not paren? code					;-- don't report paren as top-level, even if it technically is
					]
					error [true]
					throw [true]
					push [
						data/inspect-sub-exprs?
						set/any 'word last data/fetched
						any [word? :word get-word? :word]
						not find ignored-words word
						word <> last data/pushed		;-- lit/get-args preserve the word - no need to report it
					]
					return [data/inspect-sub-exprs?] 
				] event
				any [report? exit]
				
				full:    any [fixed-width attempt [system/console/size/1] 80]
				width:   full - 7						;-- last column(1) + " => "(4) + min. indent(2)
				left:    min 60 to integer! width / 2	;-- cap at 60 as we don't want it to be huge
				right:   width - left
				indent:  append/dup clear ""          " " full - 1		;-- indent for code
				indent2: append/dup clear skip "  " 2 "`" full - 3		;-- indent for paths: prefixed by "  "
				level:   (length? data/stack) / data/stack-period - 1
				level:   level % 10 + 1 * 2				;-- cap at 20 as we don't want indent to occupy whole column
				
				expr: case [
					not data/inspect-sub-exprs? [data/fetched']
					event = 'push [top-of data/fetched']
					'else [data/pushed']
				]
				if paren? expr [expr: as [] expr]		;-- otherwise /only won't remove brackets
				if path?  code [expr: as path! expr]
				
				;; print current path, only works in non-/all mode
				unless any [data/inspect-sub-exprs?  data/path == last-path] [
					path: uppercase mold-part as path! data/path full - 1 - level
					p: change skip indent2 level path			;-- add path of refs 
					
					unless empty? pexpr: pick tail data/stack fetched'-index [
						orig-expr: pick tail data/stack fetched-index 
						name: either path? :orig-expr/1 [:orig-expr/1/1][:orig-expr/1]
						if :name = last data/path [				;-- don't duplicate last path item if orig expr starts with it
							pexpr: next pexpr
						]
						change change p " " form/part pexpr (length? p) - 1		;-- add parent expr to path
					]
					do [emit indent2]							;@@ without 'do' emit is hardcoded
					
					append clear last-path data/path			;-- remember last displayed path
				]
				
				;; print expression and result
				change        skip indent level       form/part expr left - level
				change change skip indent left " => " mold-part :value right
				do [emit indent]								;@@ without 'do' emit is hardcoded
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
		"Runs argument code and prints an evaluation trace; also turns on/off tracing"
		code [any-type!] "Code to trace or tracing mode (logic!)"
		/raw   "Switch to raw interpreter events tracing (incompatible with other modes)"
		/deep  "Trace into functions and natives"
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
