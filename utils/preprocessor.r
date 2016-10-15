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
	
	quit-on-error: does [
		if system/options/args [quit/return 1]
		halt
	]
	
	do-code: func [code [block!] /local p res w][
		clear syms
		parse code/2 [any [
			p: set-word! (unless in exec p/1 [append syms p/1])
			| skip
		]]
		unless empty? syms [
			append syms none
			exec: make exec compose [(syms) (macros)]
		]
		if error? set 'res try [do bind code/2 exec][
			prin "*** #DO Evaluation Error^/"
			either rebol [
				res: disarm res
				res/where: rejoin ["#do " copy/part mold code/2 100]
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
				res/where: rejoin ["#do " mold/part code/2 100]
				print form :res
			]
			quit-on-error
		]
		:res
	]

	check-condition: func [job [object!] type [word!] expr [block!]][
		if any [
			not any [word? expr/1 lit-word? expr/1]
			not in job expr/1
			all [type <> 'switch not find [= <> < > <= >= contains] expr/2]
		][
			print rejoin ["invalid #" type " condition"]
		]
		either type = 'switch [
			any [
				select expr/2 job/(expr/1)
				select expr/2 #default
			]
		][
			expr: either expr/2 = 'contains [
				compose/deep [all [(expr/1) find (expr/1) (expr/3)]]
			][
				copy/part expr 3
			]
			do bind expr job
		]
	]
	
	expand: func [
		code [block!] job [object!]
		/local rule s e name op value then else cases body
	][
		exec: context []
		clear macros
		
		parse code rule: [
			any [
				s: #include (
					if all [not Rebol system/state/interpreted?][s/1: 'do]
				)
				| s: #if set name word! set op skip set value any-type! set then block! e: (
					either check-condition job 'if reduce [name op get/any 'value][
						change/part s then e
					][
						remove/part s e
					]
				) :s
				| s: #either set name word! set op skip set value any-type! set then block! set else block! e: (
					either check-condition job 'either reduce [name op get/any 'value][
						change/part s then e
					][
						change/part s else e
					]
				) :s
				| s: #switch set name word! set cases block! e: (
					either body: check-condition job 'switch reduce [name cases][
						change/part s body e
					][
						remove/part s e
					]
				) :s
				| s: #case set cases block! e: (
					either body: select reduce bind cases job true [
						change/part s body e
					][
						remove/part s e
					]
				) :s
				| s: #do block! e: (change/part s do-code s e)
				| pos: [block! | paren!] :pos into rule
				| skip
			]
		]
		code
	]
	
	set 'expand-directives func [						;-- to be called from Red only
		code [block!]
	][
		expand code system/build/config
	]
]