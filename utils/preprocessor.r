REBOL [
	Title:   "Compilation directives processing"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [

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
		parse code rule: [
			any [
				s: #if set name word! set op skip set value any-type! set then block! e: (
					either check-condition job 'if reduce [name op get/any 'value][
						change/part s then e
					][
						remove/part s e
					]
				) :s
				| s: #either set name word! set op skip set value any-type! set then block! set else block! e: (
					either check-condition 'either reduce [name op get/any 'value][
						change/part s then e
					][
						change/part s else e
					]
				) :s
				| s: #switch set name word! set cases block! e: (
					either body: check-condition 'switch reduce [name cases][
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
				| pos: [block! | paren!] :pos into rule
				| skip
			]
		]
		code
	]
	
	set 'expand-directives func [						;-- to be called from Red
		code [block!]
	][
		expand code system/options/build
	]
]