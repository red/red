REBOL [
	Title:   "Compilation directives processing"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]
Red []													;-- make it usable by Red too.

unless value? 'disarm [disarm: none]

context [
	exec:	none										;-- object that captures preproc symbols
	macros: make block! 10
	syms:	make block! 20
	active?: yes
	
	quit-on-error: does [
		if system/options/args [quit/return 1]
		halt
	]
	
	do-code: func [code [block!] cmd [issue!] /local p res w][
		clear syms
		parse code [any [
			p: set-word! (unless in exec p/1 [append syms p/1])
			| skip
		]]
		unless empty? syms [
			append syms none
			exec: make exec compose [(syms) (macros)]
		]
		if error? set 'res try bind code exec [
			prin ["***" uppercase mold cmd "Evaluation Error^/"]
			either rebol [
				res: disarm res
				res/where: rejoin [mold cmd #" " copy/part mold code 100]
				foreach w [arg1 arg2 arg3][
					set w either unset? get/any in res w [none][
						get/any in res w
					]
				]
				print [
					"***" system/error/(res/type)/type #":"
					reduce system/error/(res/type)/(res/id) newline
					"*** Where:" mold/flat res/where newline
					"*** Near: " mold/flat res/near newline
				]
			][
				res/where: rejoin [mold cmd #" " mold/part code 100]
				print form :res
			]
			quit-on-error
		]
		:res
	]
	
	count-args: func [spec [block!] /local total][
		total: 0
		parse spec [
			any [
				[word! | lit-word! | get-word!] (total: total + 1)
				| refinement! (return total)
			]
		]
		total
	]
	
	func-arity?: func [spec [block!] /with path [path!] /local arity pos][
		arity: count-args spec
		if path [
			foreach word next path	[
				unless pos: find/tail spec to refinement! word [
					;throw-error
					print "error!"
				]
				arity: arity + count-args pos
			]
		]
		arity
	]
	
	fetch-next: func [code [block!] /local base arity value][
		base: code
		arity: 1
		
		while [arity > 0][
			arity: arity + either all [
				not tail? next code
				word? value: code/2
				op? get/any value
			][
				code: next code
				1
			][
				either all [
					find [word! path!] type? value: code/1
					value: either word? value [value][first value]
					any-function? get/any value
				][
					func-arity? first get value
				][0]
			]
			code: next code
			arity: arity - 1
		]
		code
	]
	
	eval: func [code [block!] cmd [issue!] /local after][
		expr: copy/part code after: fetch-next code
		expr: do-code expr cmd
		reduce [expr after]
	]
	
	expand: func [
		code [block!] job [object!]
		/local rule s e name cond expr value then else cases body
	][
		exec: context [config: job]
		clear macros
		
		#process off
		parse code rule: [
			any [
				'routine 2 skip							;-- avoid overlapping with R/S preprocessor
				| #system skip
				| #system-global skip
				
				| s: #include (
					if all [active? not Rebol system/state/interpreted?][s/1: 'do]
				)
				| s: #if (set [cond e] eval next s s/1) :e set then block! e: (
					if active? [either cond [change/part s then e][remove/part s e]]
				) :s
				| s: #either (set [cond e] eval next s s/1) :e set then block! set else block! e: (
					if active? [either cond [change/part s then e][change/part s else e]]
				) :s
				| s: #switch (set [expr e] eval next s s/1) :e set cases block! e: (
					if active? [
						body: any [select cases expr select cases #default]
						either body [change/part s body e][remove/part s e]
					]
				) :s
				| s: #case set cases block! e: (
					if active? [
						until [
							set [cond cases] eval cases s/1
							any [cond tail? cases: next cases]
						]
						either cond [change/part s cases/1 e][remove/part s e]
					]
				) :s
				| s: #do block! e: (if active? [s: change/part s do-code s/2 s/1 e]) :s
				
				| s: #process ['on (active?: yes) | 'off (active?: no) [to #process | to end]]
				  (remove/part s 2)
				  
				| pos: [block! | paren!] :pos into rule
				| skip
			]
		]
		#process on
		code
	]
	
	set 'expand-directives func [						;-- to be called from Red only
		code [block!]
	][
		expand code system/build/config
	]
]