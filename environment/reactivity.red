Red [
	Title:	"Reactive programming support"
	Author: "Nenad Rakocevic"
	File: 	%reactivity.red
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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
		system/reactivity/check/only self word
	]
]

deep-reactor!: context [
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
			if find system/reactivity/types! type? :old [modify old 'owned none]
			if find system/reactivity/types! type? :new [modify new 'owned reduce [self word]]
		]
		system/reactivity/check/only self word
	]
	on-deep-change*: function [owner word target action new index part][
		system/reactivity/check/only owner word
	]
]

reactor:	  function [spec [block!]][make reactor! spec]
deep-reactor: function [spec [block!]][make deep-reactor! spec]


system/reactivity: context [
	relations:	 make block! 1000		;@@ change it to hash! once stable
	;-- queue format: [reactor reaction target done]
	queue:		 make block! 100
	eat-events?: yes
	debug?: 	 no
	
	types!: union series! make typeset! [object! bitset!]
	not-safe!: union any-function! make typeset! [unset! error!]

	add-relation: func [
		obj		 [object!]
		word
		reaction [block! function!]
		targets  [set-word! block! object! none!]
		/local new-rel
	][
		new-rel: reduce [obj :word :reaction targets]
		unless find/same/skip relations new-rel 4 [append relations new-rel]
	]
	
	identify-sources: function [path [any-path!] reaction ctx return: [logic!]][
		p: path
		found?: no
		if any [not word? p/1 find not-safe! type? get/any p/1][return no]

		until [
			if all [not tail? next p not word? p/2][return no] ;-- accessor not a word
			slice: copy/part path next p
			obj: try [get/any :slice]
			if find not-safe! type? :obj [return no]
			if all [
				word? p/2
				object? :obj							;-- rough checks for reactive object
				in obj 'on-change*
			][
				add-relation obj p/2 :reaction ctx
				found?: yes
			]
			tail? p: next p
		]
		found?
	]

	eval: function [code [block!] /safe][
		either safe [
			if error? set/any 'result try/all code [
				print :result
				prin "*** Near: "
				print mold/part/flat code 80
				result: none
			]
			get/any 'result
		][
			do code
		]
	]
	
	eval-reaction: func [reactor [object!] reaction [block! function!] target /mark][
		if mark [repend queue [reactor :reaction target yes]]
		
		either set-word? target [
			set/any target eval/safe :reaction
		][
			eval/safe any [all [block? :reaction reaction] target]
		]
	]
	
	pending?: function [reactor [object!] reaction [block! function!]][
		q: queue
		while [q: find/same/skip q reactor 4][
			if same? :q/2 :reaction [return yes]
			q: skip q 4
		]
		no
	]
	
	check: function [reactor [object!] /only field [word! set-word!]][
		unless tail? pos: relations [
			while [pos: find/same/skip pos reactor 4][
				reaction: :pos/3
				if all [
					any [not only pos/2 = field]
					any [empty? queue  not pending? reactor :reaction]
				][
					either empty? queue [
						eval-reaction/mark reactor :reaction pos/4
						
						q: tail queue
						until [
							q: skip q': q -4
							either q/4 [ 				;-- was already executed?
								clear q 				;-- allow requeueing of it
							][
								eval-reaction q/1 :q/2 q/3
								either tail? q' [ 		;-- queue wasn't extended
									clear q 			;-- allow requeueing
								][
									q/4: yes 			;-- mark as executed
									q: tail queue 		;-- jump to recently queued reactions
								]
							]
							head? q
						]
						clear queue
					][
						unless all [
							eat-events?
							pending? reactor :reaction
						][
							repend queue [reactor :reaction pos/4 no]
						]
					]
				]
				pos: skip pos 4
			]
		]
	]
	
	
	set 'no-react func [
		"Evaluates a block with all previously defined reactions disabled"
		body [block!] "Code block to evaluate"
		/local result
	][
		relations: tail relations
		set/any 'result eval/safe body
		relations: head relations
		:result
	]
	
	set 'stop-reactor function [
		face [object!]
		/deep
	][
		if system/reactivity/debug? [
			print ["-- reactivity: stopping, face:" face/type "/deep:" deep]
		]
		list: relations
		while [not tail? list][
			either any [
				same? list/1 face
				all [
					block? list/4
					pos: find/same list/4 face
					empty? head remove pos
				]
			][
				remove/part list 4
			][
				list: skip list 4
			]
		]
		if all [deep block? face/pane][foreach f face/pane [stop-reactor/deep f]]
	]
	
	set 'clear-reactions function ["Removes all reactive relations"][
		if system/reactivity/debug? [print "-- reactivity: clear all"]
		clear relations
	]
	
	set 'dump-reactions function [
		"Outputs all the current reactive relations for debugging purpose"
	][
		limit: (any [all [system/console system/console/size/x] 72]) - 10
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
					print replace/all (mold/flat/part next target limit) "make object!" "object"
				]
				set-word? target [
					prin "  Target: "
					print form target
				]
			]
		]
		if empty? relations [print "-- no reactions --"]
		()												;-- avoids returning anything in the console
	]
	
	set 'relate function [
		"Defines a reactive relation whose result is assigned to a word"
		'field	 [set-word!]	"Set-word which will get set to the result of the reaction"
		reaction [block!]		"Reactive relation"
	][
		obj: context? field
		parse reaction rule: [
			any [
				item: word! (if in obj item/1 [add-relation obj item/1 reaction field])
				| [path! | lit-path! | get-path!] (
					item: item/1
					if all [in obj item/1 not same? obj system/words][ ;-- avoid double registration
						add-relation obj item/1 reaction field
					]
				) | set-path! | any-string! | into rule | skip
			]
		]
		react/later/with reaction field
		set field either block? :reaction/1 [do :reaction/1][eval reaction]
	]

	set 'is does [cause-error 'internal 'deprecated ["IS" "RELATE word: [reaction]"]]
	
	set 'react? function [
		"Returns a reactive relation if an object's field is a reactive source"
		reactor	[object!]	"Object to check"
		field	[word!]		"Field to check"
		/target				"Check if it's a target of an `is` reaction instead of a source"
		return: [block! function! word! none!] "Returns reaction, type or NONE"
	][
		either target [
			pos: skip relations 3
			while [pos: find/skip pos field 4][
				if same? reactor context? pos/1 [return pos/-1]
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
							if all [pos: find objs item/1 word? item/2][
								obj: pick objects 1 + index? pos
								add-relation obj item/2 :reaction objects
								found?: yes
							]
						)
						| set-path! | any-string!
						| into rule
						| skip
					]
				]
				if all [not later found?][eval objects]
			]
			unlink [
				if block? src [src: reduce src]
				pos: relations
				found?: no
				while [pos: find/same/only pos :reaction][
					obj: pos/-2
					either any [src = 'all same? src obj all [block? src find/same src obj]][
						pos: remove/part skip pos -2 4
						found?: yes
					][
						pos: next pos
					]
				]
			]
			'else [
				found?: no
				parse reaction rule: [
					any [
						item: [path! | lit-path! | get-path!] (
							found?: identify-sources item/1 :reaction ctx
							parse item/1 rule
						)
						| set-path! | any-string!
						| into rule
						| skip
					]
				]
				if all [not later found?][eval reaction]
			]
		]
		either found? [:reaction][none]					;-- returns NONE if no relation was processed
	]
]

