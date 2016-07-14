Red [
	Title:	"Reactive programming support"
	Author: "Nenad Rakocevic"
	File: 	%reactivity.red
	Tabs: 	4
	Rights: "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

reactor!: context [
	on-change*: function [word old new][
		if system/reactivity/debug? [
			print [
				"-- on-change event --" lf
				tab "word :" word		lf
				tab "old  :" type? :old	lf
				tab "new  :" type? :new
			]
		]
		unless all [block? :old block? :new same? head :old head :new][
			if any [series? :old object? :old][modify old 'owned none]
			if any [series? :new object? :new][modify new 'owned reduce [self word]]
		]
		system/reactivity/check/only self word
	]
]

deep-reactor!: make reactor! [
	on-deep-change*: function [owner word target action new index part][
		system/reactivity/check/only owner word
	]
]

;reactor:	  function [spec [block!]][make reactor! spec]
;deep-reactor: function [spec [block!]][make deep-reactor! spec]


system/reactivity: context [
	relations:	make block! 1000		;@@ change it to hash! once stable
	stack:		make block! 100			;@@ change it to hash! once stable ???
	queue:		make block! 100
	debug?: 	no
	
	do-safe: function [code [block!]][
		if error? set/any 'result try/all code [
			print :result
			prin "*** Near: "
			probe code
			result: none
		]
		get/any 'result
	]
	
	eval-reaction: function [reactor [object!] reaction [block! function!] target][
		append stack reactor
		append/only stack :reaction
		either set-word? target [
			set/any target do-safe :reaction
		][
			do-safe any [all [block? :reaction reaction] target]
		]
		clear back back tail stack
	]
	
	on-stack?: function [reactor [object!] reaction [block! function!]][
		p: stack
		while [p: find/same/skip p reactor 2][
			if same? p/2 reaction [return yes]
			p: skip p 2
		]
		no
	]
	
	check: function [reactor [object!] /only field [word! set-word!]][
		unless empty? pos: relations [
			while [pos: find/same/skip pos reactor 4][
				reaction: pos/3
				
				if all [
					any [not only pos/2 = field]
					any [empty? stack not on-stack? reactor :reaction]
				][
					either empty? stack [
						eval-reaction reactor :reaction pos/4
						
						unless empty? queue [
							q: tail queue
							while [not head? q][
								q: skip q -3
								eval-reaction q/1 q/2 q/3
								q: tail remove/part q 3	;-- new reactions could have been queued
							]
						]
					][
						append queue reactor
						append/only queue :reaction
						append/only queue pos/4
					]
				]
				pos: skip pos 4
			]
		]
	]
	
	set 'clear-reactions function ["Removes all reactive relations"][clear relations]
	
	set 'dump-reactions function [
		"Output all the current reactive relations for debugging purpose"
	][
		limit: any [all [system/console system/console/limit] 72] - 10
		count: 0
		
		foreach [obj field reaction target] relations [
			prin count: count + 1
			prin ":---^/"
			prin "  Source: object "
			list: words-of obj
			remove find list 'on-change*
			remove find list 'on-deep-change*
			print mold/part list limit - 5
			prin "   Field: "
			print form field
			prin "  Action: "
			print mold/flat/part :reaction limit
			case [
				block? target [
					prin "    Args: "
					print copy/part replace/all mold/flat next target "make object!" "object" limit
				]
				set-word? target [
					prin "  Target: "
					print form target
				]
			]
		]
		()												;-- avoids returning anything in the console
	]
	
	is~: function [
		"Defines a reactive relation which result is assigned to a word"
		'field	 [set-word!]	"Set-word which will get set to the result of the reaction"
		reaction [block!]		"Reactive relation"
	][
		words: words-of obj: context? field
		parse reaction rule: [
			any [
				item: word! (
					if find words item/1 [repend relations [obj item/1 reaction field]]
				)
				| set-path! | any-string!
				| into rule
				| skip
			]
		]
		react/later/with reaction field
		set field either block? reaction/1 [do reaction/1][do-safe reaction]
	]
	
	set 'is make op! :is~
	
	set 'react? function [
		"Returns a reactive relation if an object's field is a reactive source"
		reactor	[object!]	"Object to check"
		field	[word!]		"Field to check"
		/target				"Check if it's a target instead of a source"
		return: [block! function! word! none!] "Returns reaction, type or NONE"
	][
		either target [
			pos: skip relations 3
			while [pos: find/skip pos field 4][
				if reactor = context? pos/1 [return pos/-1]
				pos: skip pos 4
			]
		][
			pos: relations
			while [pos: find/same/skip pos reactor 4][
				if pos/2 = field [return pos/3]
				pos: skip pos 4
			]
		]
		none
	]
	
	set 'react function [
		"Defines a new reactive relation between two or more objects"
		reaction	[block! function!]	"Reactive relation"
		/link							"Link objects together using a reactive relation"
			objects	[block!]			"Objects to link together"
		/unlink							"Removes an existing reactive relation"
			src		[word! object! block!] "'all word, or a reactor or a list of reactors"
		/later							"Run the reaction on next change instead of now"
		/with							"Specifies an optional face object (internal use)"
			ctx		[object! set-word! none!] "Optional context for VID faces or target set-word"
		return:		[block! function! none!] "The reactive relation or NONE if no relation was processed"
	][
		case [
			link [
				unless function? :reaction [cause-error 'script 'react-bad-func []]
				objs: parse spec-of :reaction [
					collect some [keep word! | [refinement! | set-word!] break | skip]
				]
				if 2 > length? objs [cause-error 'script 'react-not-enough []]
				objects: reduce objects
				
				if (length? objects) <> length? objs [cause-error 'script 'react-no-match []]
				unless parse objects [some object!][cause-error 'script 'react-bad-obj []]
				
				insert objects :reaction
				
				found?: no
				parse body-of :reaction rule: [
					any [
						item: [path! | lit-path! | get-path!] (
							item: item/1
							if pos: find objs item/1 [
								obj: pick objects 1 + index? pos
								repend relations [obj item/2 :reaction objects]
								unless later [do-safe objects]
								found?: yes
							]
						)
						| set-path! | any-string!
						| into rule
						| skip
					]
				]
			]
			unlink [
				if block? src [src: reduce src]
				pos: relations
				found?: no
				while [pos: find/same/only pos :reaction][
					obj: pos/-2
					if any [src = 'all src = obj all [block? src find/same src obj]][
						pos: remove/part skip pos -2 4
						found?: yes
					]
				]
			]
			'else [
				found?: no
				parse reaction rule: [
					any [
						item: [path! | lit-path! | get-path!] (
							saved: item/1
							if unset? attempt [get/any item: saved][
								cause-error 'script 'no-value [item]
							]
							obj: none
							part: (length? item) - 1
	
							unless all [				;-- search for an object (deep first)
								2 = length? item
								object? obj: get item/1
							][
								until [
									path: copy/part item part
									part: part - 1
									any [
										tail? path
										object? obj: attempt [get path]
										part = 1
									]
								]
							]
	
							if all [
								object? obj				;-- rough checks for reactive object
								in obj 'on-change*
							][
								part: part + 1
								repend relations [obj item/:part reaction ctx]
								unless later [do-safe reaction]
								found?: yes
							]
							parse saved rule
						)
						| set-path! | any-string!
						| into rule
						| skip
					]
				]
			]
		]
		either found? [:reaction][none]					;-- returns NONE if no relation was processed
	]
]

