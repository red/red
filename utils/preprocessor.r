REBOL [
	Title:   "Compilation directives preprocessing"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Notes: 	 {}
]

context [

	check-condition: func [job [object!] type [word!] payload [block!]][
		if any [
			not any [word? payload/1 lit-word? payload/1]
			not in job payload/1
			all [type <> 'switch not find [= <> < > <= >= contains] payload/2]
		][
			throw-error rejoin ["invalid #" type " condition"]
		]
		either type = 'switch [
			any [
				select payload/2 job/(payload/1)
				select payload/2 #default
			]
		][
			payload: either payload/2 = 'contains [
				compose/deep [all [(payload/1) find (payload/1) (payload/3)]]
			][
				copy/part payload 3
			]
			do bind payload job
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
	]

]