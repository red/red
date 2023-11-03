REBOL [
	Title:   "Compilation directives processing"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]
Red []													;-- make it usable by Red too.

preprocessor: context [
	exec:	 do [context [config: none]]				;-- object that captures directive words
	protos:  make block! 10
	macros:  [<none>]
	stack:	 make block! 10
	syms:	 make block! 20
	depth:	 0											;-- track depth of recursive macro calls
	active?: yes
	trace?:  no
	s:		 none
	
	do-quit: does [
		case [
			all [rebol system/options/args][quit/return 1]
			all [not rebol system/console][throw/name 'halt-request 'console]
			'else [halt]
		]
	]
	
	throw-error: func [error [error!] cmd [issue!] code [block!] /local w][
		prin ["*** Preprocessor Error in" mold cmd lf]
		
		#either none? config [							;-- config is none when preprocessor is applied to itself
			error: disarm error
			error/where: new-line/all reduce [cmd] no
			
			foreach w [arg1 arg2 arg3][
				set w either unset? get/any in error w [none][
					get/any in error w
				]
			]
			print [
				"***" system/error/(error/type)/type #":"
				reduce system/error/(error/type)/(error/id) newline
				"*** Where:" mold/flat error/where newline
				"*** Near: " mold/flat error/near newline
			]
			do-quit
		][
			error/where: new-line/all reduce [cmd] no
			print form :error
			either system/console [throw/name 'halt-request 'console][halt]
		]
	]
	
	syntax-error: func [s [block! paren!] e [block! paren!]][
		print [
			"*** Preprocessor Error: Syntax error^/"
			"*** Where:" trim/head mold/only copy/part s next e
		]
		do-quit
	]
	
	do-safe: func [code [block! paren!] /manual /with cmd [issue!] /local res t? src][
		if t?: all [trace? not with][
			print [
				"preproc: matched" mold/flat copy/part get code/2 get code/3 lf
				"preproc: eval macro" copy/part mold/flat body-of first code 80
			]
		]
		#process off
		if error? set/any 'res try code [throw-error :res any [cmd #macro] code]
		#process on
		
		if all [
			manual
			any [
				(type? src: get code/2) <> type? get/any 'res
				not same? head src head get/any 'res
			]
		][
			print [
				"*** Macro Error: [manual] macro not returning a position^/"
				"*** Where:" mold code
			]
			do-quit
		]
		if t? [print ["preproc: ==" mold get/any 'res]]
		either unset? get/any 'res [[]][:res]
	]
	
	do-code: func [code [block! paren!] cmd [issue!] /local p][
		clear syms
		parse code [any [
			p: set-word! (unless in exec p/1 [append syms p/1])
			| skip
		]]
		unless empty? syms [
			exec: make exec append syms none
			rebind-all
		]
		do-safe/with bind to block! code exec cmd
	]
	
	rebind-all: func [/local rule p][
		protos: bind protos exec
		
		parse macros rule: [
			any [p: function! (bind body-of first p exec) | p: [block! | paren!] :p into rule | skip]
		]
	]
	
	count-args: func [spec [block!] /block /local total pos][
		total: either block [copy []][0]
		parse spec [
			any [
				pos: [word! | lit-word! | get-word!] (
					either block [append total type? pos/1] [total: total + 1]
				)
				| refinement! (return total)
				| skip
			]
		]
		total
	]
	
	arg-mode?: func [spec [block!] idx [integer!]][
		pick count-args/block spec idx
	]
	
	func-arity?: func [spec [block!] /with path [path!] /block /local arity pos][
		arity: either block [count-args/block spec] [count-args spec]
		if path [
			foreach word next path	[
				unless pos: find/tail spec to refinement! word [
					print [
						"*** Macro Error: unknown refinement^/"
						"*** Where:" mold path
					]
					do-quit
				]
				either block
					[append arity count-args/block pos]
					[arity: arity + count-args pos]
			]
		]
		arity
	]

	value-path?: func [path [path!] /local value i item selectable] [
		selectable: make typeset! [
			block! paren! path! lit-path! set-path! get-path!
			object! port! error! map!
		]
		repeat i length? path [
			set/any 'value either i = 1 [get/any first path][
				set/any 'item pick path i
				case [
					get-word? :item [set/any 'item get/any to word! item]
					paren?    :item [set/any 'item do item]
				]
				either integer? :item [pick value item][select value :item]
			]
			unless find selectable type? get/any 'value [
				path: copy/part path i
				break
			]
		]
		reduce [path get/any 'value]
	]

	fetch-next: func [code [block! paren!] /local i left item item2 value fn-spec path f-arity at-op? op-mode][
		left: reduce [yes]
		
		while [all [not tail? left not tail? code]][
			either not left/1 [							;-- skip quoted argument
				remove left
			][
				item: first code
				f-arity: any [
					all [								;-- a ...
						word? :item
						any-function? set/any 'value get/any :item
						func-arity?/block fn-spec: spec-of get/any :item
					]
					all [								;-- a/b ...
						path? :item
						set/any [path value] value-path? :item
						any-function? get/any 'value
						func-arity?/block/with
							fn-spec: spec-of :value
							at :item length? :path
					]
				]
				if at-op?: all [						;-- a * b
					1 < length? code
					word? item2: second code
					op? get/any :item2
				][
					if all [f-arity 1 < length? f-arity] [		;-- check if function's lit/get-arg takes priority
						at-op?: word! = arg-mode? fn-spec 1
					] 
				]
				case [
					at-op? [							;-- a * b
						code: next code					;-- skip `a *` part
						left/1: word! = arg-mode? spec-of get/any :item2 2
					]
					f-arity [							;-- a ... / a/b ...
						if op? get/any 'value [return skip code 2]	;-- starting with op is an error
						remove left
						repeat i length? f-arity [insert at left i word! = f-arity/:i]
					]
					not find [set-word! set-path!] type?/word item [	;-- not a: or a/b:
						remove left
					]
				]
			]
			code: next code
		]
		code
	]
	
	eval: func [code [block! paren!] cmd [issue!] /local after expr][
		after: fetch-next code
		expr: copy/part code after
		if trace? [print ["preproc:" mold cmd mold expr]]
		
		expr: do-code expr cmd
		if trace? [print ["preproc: ==" mold expr]]
		
		reduce [expr after]
	]
	
	do-macro: func [name pos [block! paren!] arity [integer!] /local cmd saved p v res][
		depth: depth + 1
		saved: s
		parse next pos [arity [s: macros | skip]]		;-- resolve nested macros first
		
		cmd: make block! 1
		append cmd name
		insert/part tail cmd next pos arity
		if trace? [print ["preproc: eval macro" mold cmd]]
		p: next cmd
		forall p [
			switch type?/word v: p/1 [
				word! [change p to lit-word! v]
				path! [change/only p to lit-path! v]
			]
		]
		
		if unset? set/any 'res do bind cmd exec [
			print ["*** Macro Error: no value returned by" name "macro^/"]
			do-quit
		]
		if trace? [print ["preproc: ==" mold :res]]
		s: saved										;-- restored here as `do cmd` could call expand
		s/1: :res
		
		if positive? depth: depth - 1 [
			saved: s
			parse s [s: macros]							;-- apply macros to result
			s: saved
		]
		s/1
	]
	
	register-macro: func [spec [block!] /local cnt rule p name macro pos valid? named?][
		named?: set-word? spec/1
		cnt: 0
		rule: make block! 10
		valid?: parse spec/3 [
			any [
				opt string!
				opt block!
				[word! (cnt: cnt + 1) | /local any word!]
				opt [
					p: block! :p into [some word!]
						;(append/only rule make block! 1)
						;some [p: word! (append last rule p/1)]
						;(append rule '|)
					;]
				]
			]
		]
		if any [
			not valid?
			all [
				not named?
				any [cnt <> 2 all [block? spec/1 empty? spec/1]]
			]
		][
			print [
				"*** Macro Error: invalid specification^/"
				"*** Where:" mold copy/part spec 3
			]
			do-quit
		]
		either named? [									;-- named macro
			repend rule [
				name: to lit-word! spec/1
				to-paren compose [change/part s do-macro (:name) s (cnt) (cnt + 1)]
				to get-word! 's
			]
			append protos copy/part spec 4
		][												;-- pattern-matching macro
			macro: do bind copy/part next spec 3 exec
			
			repend rule [
				to set-word! 's
				spec/1
				to set-word! 'e
				to-paren compose/deep either all [
					block? spec/3/1 find spec/3/1 'manual
				][
					[s: do-safe/manual [(:macro) s e]]
				][
					[s: change/part s do-safe [(:macro) s e] e]
				]
				to get-word! 's
			]
		]
		
		pos: tail macros
		either tag? macros/1 [remove macros][insert macros '|]
		insert macros rule
		new-line pos yes
		
		exec: make exec protos
		rebind-all
	]

	reset: func [job [object! none!]][
		exec: do [context [config: job]]
		clear protos
		insert clear macros <none>						;-- required to avoid empty rule (causes infinite loop)
	]

	expand: func [
		code [block! paren!] job [object! none!]
		/clean
		/local rule e pos cond value then else cases body keep? expr src saved file
	][	
		either clean [reset job][exec/config: job]

		#process off
		rule: [
			any [
				s: macros
				| 'routine 2 skip						;-- avoid overlapping with R/S preprocessor
				| #system skip
				| #system-global skip
				
				| s: #include (
					if active? [
						either all [not Rebol system/state/interpreted?][
							saved: s
							attempt [expand load s/2 job]	;-- just preprocess it
							s: saved
							s/1: 'do
						][
							attempt [
								src: red/load-source/hidden clean-path join red/main-path s/2
								expand src job				;-- just preprocess it, real inclusion occurs later
							]
						]
					]
				)
				| s: #include-binary [file! | string!] (
					if active? [
						either all [not Rebol system/state/interpreted?][
							s/1: 'read/binary
							if string? s/2 [s/2: to-red-file s/2]
						][
							file: either string? s/2 [to-rebol-file s/2][s/2]
							file: clean-path join red/main-path file
							change/part s read/binary file 2
						]
					]
				)
				| s: #if (set [cond e] eval next s s/1) :e [set then block! | (syntax-error s e)] e: (
					if active? [either cond [change/part s then e][remove/part s e]]
				) :s
				| s: #either (set [cond e] eval next s s/1) :e 
					[set then block! set else block! | (syntax-error s e)] e: (
						if active? [either cond [change/part s then e][change/part s else e]]
				) :s
				| s: #switch (set [cond e] eval next s s/1) :e [set cases block! | (syntax-error s e)] e: (
					if active? [
						body: any [select cases cond select cases #default]
						either body [change/part s body e][remove/part s e]
					]
				) :s
				| s: #case [set cases block! | e: (syntax-error s e)] e: (
					if active? [
						until [
							set [cond cases] eval cases s/1
							any [cond tail? cases: next cases]
						]
						either cond [change/part s cases/1 e][remove/part s e]
					]
				) :s
				| s: #do (keep?: no) opt ['keep (keep?: yes)] [block! | (syntax-error s next s)] e: (
					if active? [
						pos: pick [3 2] keep?
						if trace? [print ["preproc: eval" mold s/:pos]]
						saved: s
						expr: do-code s/:pos s/1
						s: saved
						if all [keep? trace?][print ["preproc: ==" mold expr]]
						either keep? [s: change/part s :expr e][remove/part s e]
					]
				) :s
				| s: #local [block! | (syntax-error s next s)] e: (
					repend stack [negate length? macros tail protos]
					change/part s expand s/2 job e
					clear take/last stack
					remove/part macros skip tail macros take/last stack
					if tail? next macros [macros/1: <none>] ;-- re-inject a value to match (avoids infinite loops)
				)
				| s: #reset (reset job remove s) :s
				| s: #trace [[
					['on (trace?: on) | 'off (trace?: off)] (remove/part s 2) :s
				] | (syntax-error s next s)]
				
				| s: #process [[
					  'on  (active?: yes remove/part s 2) :s
					| 'off (active?: no  remove/part s 2) :s [to #process | to end (active?: yes)]
				] | (syntax-error s next s)]
				
				| s: #macro [
					[set-word! | word! | lit-word! | block!]['func | 'function] block! block! 
					| (syntax-error s skip s 4)
				] e: (
					register-macro next s
					remove/part s e
				) :s
				| pos: [block! | paren!] :pos into rule
				| skip
			]
		]
		#process on
		
		unless Rebol [rule/1: 'while]					;-- avoid no-forward premature exit in Red (#3771)
		parse code rule
		code
	]
	
	set 'expand-directives func [						;-- to be called from Red only
		"Invokes the preprocessor on argument list, modifying and returning it"
		code [block! paren!] "List of Red values to preprocess"
		/clean 				 "Clear all previously created macros and words"
		/local job saved
	][
		saved: s
		job: system/build/config
		also 
			either clean [expand/clean code job][expand code job]
			s: saved
	]
]