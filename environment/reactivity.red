Red [
	Title:	"Reactive programming support"
	Author: ["Nenad Rakocevic" "hiiamboris"]
	File: 	%reactivity.red
	Tabs: 	4
	Rights: "Copyright (C) 2016-2021 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#local [												;-- keep macros from flowing out
#macro REACTORS-PERIOD:  func [][2]
#macro RELATIONS-PERIOD: func [][3]
#macro REACTIONS-PERIOD: func [][2]

system/reactivity: context [
	;-- reactors format: [reactor [records] ...]
	;-- each record format: [reactor word reaction targets] - a block (hash is ~10x times slower)
	;;  src-word [reaction] set-word            	 -- used by `is` (evaluates reaction, assigns to target)
	;;  src-word function [func obj1 obj2...]   	 -- used by react/link (evaluates target), one relation for every reactor in both list and func's body
	;;  src-word [reaction] none                	 -- used by react (evaluates reaction)
	;;  src-word [reaction] set-word/object     	 -- used by react/with (evaluates reaction, assigns to a set-word only)
	reactors:	 make hash! 500

	;-- reactions format: [reaction [reactors..] ...]
	;-- (used by react/unlink 'all, dump-reactions, clear-reactions, stop-reactor)
	reactions:   make hash! 1000						;-- hash speeds up unlinking noticeably

	;-- queue format: [reactor reaction target done]
	queue:		 make hash! 100

	debug?: 	 no
	metrics?:    no
	source:		 []		;-- contains the initial [reactor reaction] that triggered a chain of subsequent reactions

	metrics: context [
		max-queue: max-reactions: max-reactors: biggest-relation: biggest-reactor: 0
		events: fired: queued: skipped: 0
		in-add: in-remove: in-react: in-check: in-eval: longest-flush: 0:0

		reset: does [
			set self 0
			in-add: in-remove: in-react: in-check: in-eval: longest-flush: 0:0
		]

		show: does [
			print "^/***** REACTIVITY METRICS REPORT *****"
			print ["Metrics collection enabled?:" metrics?]
			print  "Statistical counts:"
			print ["    events triggered:   " events]
			print ["    reactions fired:    " fired "(immediately:" fired - queued ", queued:" queued ")" ]
			print ["    reactions skipped:  " skipped]
			print ["Time spent in reactions:" in-eval]
			print  "Time spent in reactivity:"
			print ["    total:              " in-add + in-remove + in-react + in-check]
			print ["    adding relations:   " in-add + in-react "(preparations:" in-react ")"]
			print ["    removing relations: " in-remove]
			print ["    dispatching:        " in-check]
			print ["    longest queue flush:" longest-flush]
			print  "Peak values:"
			print ["    max queue size:     " max-queue]
			print ["    max reactors count: " max-reactors]
			print ["    max reactions count:" max-reactions]
			print ["    biggest relation:   " biggest-relation "reactors"]
			print ["    biggest reactor:    " biggest-reactor "relations"]
		]
		
		start: target: none
		time: func [/count 'into [word!] /save /local t] [
			t: now/precise
			case [
				save  [set target (get target) + t: difference t start  t]
				count [start: t  target: into]
			]
		]

		incr: func ['word]       [set word 1 + get word]
		peak: func ['word value] [set word max get word value]

		register: func ['counter value] [set counter max get counter value]
	]

	--measure--: func [code] [
		if metrics? [do bind code metrics]
	]

	--debug-print--: function [blk [block!] /full /no-gui] [
		all [
			debug?
			any [not full  debug? = 'full]
			not all [no-gui  attempt [system/console/gui?]]			;-- print in GUI console overflows stack in some places
			(
				limit: (any [all [system/console system/console/size/x] 72]) - 10
				blk: reduce blk
				forall blk [
					x: :blk/1										;@@ workaround for #4517
					unless string? :x [
						if function? :x [x: body-of :x]
						all [
							object? :x
							pos: find/same values-of system/words x
							x: pick words-of system/words index? pos
						]
						change blk
							replace/all
								mold/flat/part :x limit
								"make object!" "object"
					]
				]
				if (length? s: form blk) > limit [					;-- trim longest parts equally
					long: 0  count: 0
					foreach x next blk [							;-- don't trim the prefix
						if 15 < len: length? x [					;-- don't trim short values
							long: long + len
							count: count + 1
						]
					]
					short: (len: length? s) - long
					ratio: max 0 limit - short / (len - short)
					foreach x next blk [
						clear skip x max 15 to integer! ratio * length? x
					]
					clear skip s: form blk limit
				]
				print s
			)
		]
	]

	remove-part: function [where [series!] part [integer!]] [	;-- O(1) anywhere
		change where end: skip tail where 0 - part
		clear end
	]

	find-reactor: func [reactor [object!]] [
		find/same/skip reactors reactor REACTORS-PERIOD
	]
	relations-of: func [reactor [object!]] [
		select/same/skip reactors reactor REACTORS-PERIOD
	]

	find-reaction: func [reaction [block! function!]] [
		find/same/only/skip reactions :reaction REACTIONS-PERIOD
	]
	reactors-for: func [reaction [block! function!]] [
		select/same/only/skip reactions :reaction REACTIONS-PERIOD
	]

	unique-objects: func [] [							;-- used by debug funcs only
		extract reactors 2
	]
	
	relations-count: function [] [
		sum: 0
		foreach obj unique-objects [
			sum: (length? relations-of obj) / RELATIONS-PERIOD + sum
		]
		sum
	]

	add-relation: function [
		obj		 [object!]
		word     [word!]
		reaction [block! function!]
		targets  [set-word! block! object! none!]
	][
		--measure-- [time/count in-add]
		new-rel: head reduce/into [:word :reaction targets] clear []
		either relations: relations-of obj [
			found: find/same/skip relations new-rel RELATIONS-PERIOD
		][
			reduce/into [obj  relations: make block! 12] tail reactors
		]
		unless found [
			append relations new-rel
			unless objs: reactors-for :reaction [
				reduce/into [:reaction  objs: make block! 10] tail reactions
			]
			unless find/same objs obj [append objs obj]	;-- only source object should be kept, not targets
			--measure-- [
				peak biggest-reactor (length? relations) / RELATIONS-PERIOD
				peak biggest-relation length? objs
				peak max-reactions   (length? reactions) / REACTIONS-PERIOD
				peak max-reactors    (length? reactors)  / REACTORS-PERIOD
			]
			--debug-print-- ["-- react: added --" :reaction "FOR" word "IN" obj]
		]
		--measure-- [time/save]
	]
	
	eval: function [code [block!] /safe /local result][
		--measure-- [
			time/count in-eval
			incr fired
		]
		--debug-print--/full ["-- react: firing --" either function? :code/1 [body-of :code/1][code]]
		either safe [
			if error? error: try/all [set/any 'result do code  'ok] [
				print :error
				prin "*** Near: "
				limit: (any [all [system/console system/console/size/x] 72]) - 11
				print mold/part/flat code limit
			]
		][
			set/any 'result do code
		]
		--measure-- [time/save]
		:result
	]
	
	eval-reaction: func [reactor [object!] reaction [block! function!] target [set-word! block! object! none!]][
		case [
			set-word? target [set/any target eval/safe :reaction]
			block? :reaction [eval/safe reaction]
			'linked          [eval/safe target]
		]
	]
	
	pending?: function [reactor [object!] reaction [block! function!]][
		reduce/into [reactor :reaction] clear pattern: []
		none <> find/same/skip queue pattern 4
	]

	check: function [reactor [object!] field [word! set-word!]][
		unless pos: relations-of reactor [exit]			;-- immediate return for reactors without defined relations
		--debug-print--/full/no-gui ["-- react: checking --" field "IN" reactor]
		--measure-- [time/count in-check]
		unless pos: find/skip pos field RELATIONS-PERIOD [exit]

		if initial?: tail? source [reduce/into [reactor field] source]
		until [
			set [word: reaction: target:] pos
			case [
				pending? reactor :reaction [			;-- don't allow cycles
					--measure-- [incr skipped]
					--debug-print--/no-gui ["-- react: skipped --" :reaction "FOR" field "IN" reactor]
					'idle
				]
				not tail? queue [						;-- entered while another reaction is running
					reduce/into [reactor :reaction target no] tail queue
					--measure-- [
						incr queued
						peak max-queue (length? queue) / 4
					]
					--debug-print--/no-gui ["-- react: queued --" :reaction "FOR" field "IN" reactor]
				]
				'else [
					reduce/into [reactor :reaction target yes] queue
					--measure-- [peak max-queue 1  time/save]
					eval-reaction reactor :reaction target
					q: tail queue
					while [not head? q] [
						q: skip q': q -4
						either q/4 [ 					;-- was already executed?
							clear q 					;-- allow requeueing of it
						][
							eval-reaction q/1 :q/2 q/3
							either tail? q' [ 			;-- queue wasn't extended
								clear q 				;-- allow requeueing
							][
								q/4: yes 				;-- mark as executed
								q: tail q	 			;-- jump to recently queued reactions
							]
						]
					]
					--measure-- [time/count in-check]
				]
			]
			none? pos: find/skip (skip pos RELATIONS-PERIOD) field RELATIONS-PERIOD
		]
		if initial? [clear source]
		--measure-- [peak longest-flush time/save]
	]

	;-- kept separately to minimize reactor's RAM size
	on-change-handler: function [owner [object!] word [word! set-word!] old [any-type!] new [any-type!]] [
		--debug-print--/full ["-- react: on-change --" word "FROM" type? :old "TO" type? :new]
		--measure-- [incr events]
		if all [
			not empty? source
			source/1 =? owner
			source/2 = word
		][
			set-quiet in owner word :old				;-- force the old value
			--measure-- [incr skipped]
			--debug-print-- ["-- react: protected --" word "VALUE" :old "IN" owner]
			exit
		]
		all [
			in owner 'on-deep-change*					;-- only deep reactors take ownership
			not all [series? :old series? :new same? head :old head :new]
			case/all [
				any [series? :old object? :old] [modify old 'owned none]
				any [series? :new object? :new] [modify new 'owned reduce [owner word]]
			]
		]
		check owner word
	]

	set 'stop-reactor function [
		"Forget all relations involving reactor OBJ"
		obj [object!] "Face or reactor"
		/deep "Deeply remove all relations from child faces"
	][
		unless found: find-reactor obj [exit]
		--measure-- [time/count in-remove]
		relations: found/2
		obj-reacs: unique extract/into next relations RELATIONS-PERIOD clear []	;-- same reaction may be repeated many times for different words
		foreach reaction obj-reacs [
			--debug-print-- ["-- react: removed --" :reaction "FROM" obj]
			pos: find-reaction :reaction
			remove find/same pos/2 obj
			if tail? pos/2 [remove-part pos REACTIONS-PERIOD]
		]
		remove-part found REACTORS-PERIOD
		--measure-- [time/save]

		if all [deep  block? :obj/pane] [
			foreach f obj/pane [stop-reactor/deep f]
		]
	]

	set 'clear-reactions function ["Remove all reactive relations"][
		--debug-print-- ["-- react: clearing ALL relations --"]
		clear reactions
		clear reactors
	]
	
	set 'dump-reactions function [
		"Output all the current reactive relations for debugging purpose"
	][
		limit: (any [all [system/console system/console/size/x] 72]) - 10
		count: 0
		
		foreach [reactor relations] reactors [
			foreach [field reaction target] relations [
				prin count: count + 1
				prin ":---^/"
				prin "  Source: object "
				list: words-of reactor
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
						print copy/part replace/all mold/flat/part next target limit + 20 "make object!" "object" limit
					]
					set-word? target [
						prin "  Target: "
						print form target
					]
				]
			]
		]
		()												;-- avoids returning anything in the console
	]

	;-- `is` should support non-object paths, like `pair/x`, `time/second`, `block/3`
	;;  as well as in-path references: `anything/(pair/x)`, `any/:x/thing`...
	;;  parsing summary:
	;;    word:     as first item in a path only (including inner paths)
	;;    get-word: anywhere in a path, inside parens (including inner paths) e.g. `object/:x`
	;;    get-words in lit-paths and set-paths? for now they are accepted; e.g. `obj/:x: y`
	;;    lit-word: should be ignored? as it's a way to get around reactivity e.g. `set 'y get 'x`
	;;    interop with react: react catches words after the object, not get-words; is - only first word in path
	is~: function [
		"Defines a reactive relation whose result is assigned to a word"
		'field	 [set-word!]	"Set-word which will get set to the result of the reaction"
		reaction [block!]		"Reactive relation"
		/local item
	][
		--measure-- [time/count in-react]
		obj: context? field
		if reactor? obj [								;-- skip global context (which would contain ALL words) and other normal objects -- let react handle them
			words: clear []
			=add=:       [(if in obj item [append words to word! item])]
			=path=:      [[set item word! =add= | skip] =path-rest=]
			=set-path=:  [skip =path-rest=]
			=path-rest=: [
				any [
					set item get-word! =add=
				|	ahead paren! into =block=			;-- no literal paths, strings, blocks in paths (can't be constructed lexically)
				|	skip
				]
			]
			parse reaction =block=: [
				any [
					set item [word! | get-word!] =add=
				|	any-string!
				|	ahead [path! | get-path! | lit-path!] into =path=
				|	ahead set-path! into =set-path=
				|	into =block=
				|	skip
				]
			]
			--measure-- [time/save]
			foreach w words [add-relation obj w reaction field]
		]
		react/later/with reaction field
		set field either block? :reaction/1 [do reaction/1][eval reaction]
	]
	
	set 'is make op! :is~
	
	for-all-paths: function ['word [word!] reaction [block!] code [block!]] [
		parse reaction rule: [
			any [
				item: [path! | lit-path! | get-path!] (
					set word item/1
					do code
					parse item/1 rule					;-- process paren & inner paths
				)
			|	any-string!
			|	into rule								;-- also enters set-path
			|	skip
			]
		]
	]

	set 'react? function [
		"Returns a reactive relation if an object's field is a reactive source"
		reactor	[object!]	"Object to check"
		field	[word!]		"Field to check"
		/target				"Check if it's a target instead of a source"
		; return: [block! function! word! none!] "Returns reaction, type or NONE"
	][
		if pos: relations-of reactor [
			either target [
				pos: at pos 3
				if pos: find/skip pos field RELATIONS-PERIOD [:pos/-1]	;-- looks for a set-word
			][
				if pos: find/skip pos field RELATIONS-PERIOD [:pos/2]
			]
		]
	]

	get-object-path-length: function [path [any-path!] obj [word!]] [
		either 2 = length? path [
			set/any obj get/any path/1
			1
		][
			part: length? path
			set obj none
			until [							;-- search for an object (deep first)
				part: part - 1
				path: copy/part path part
				any [
					object? set obj attempt [get path]
					part = 1
				]
			]
			part
		]
	]

	unlink-reaction: function [reactor [object!] reaction [function! block!]] [
		unless at-reactor: find-reactor reactor [return none]
		pos: next relations: at-reactor/2
		while [pos: find/same/only/skip pos :reaction RELATIONS-PERIOD] [
			--debug-print-- ["-- react: removed --" :reaction "FOR" pos/-1 "IN" reactor]
			remove-part back found?: pos RELATIONS-PERIOD
		]
		if empty? relations [remove-part at-reactor REACTORS-PERIOD]	;-- don't lock it from GC

		at-reaction: find-reaction :reaction
		remove find/same objs: at-reaction/2 reactor
		remove find/same at-reaction/2 reactor
		remove find/same at-reaction/2 reactor
		if empty? objs [remove-part at-reaction REACTIONS-PERIOD]		;-- don't lock it from GC
		found?
	]

	;-- used by `react` to determine valid reactive sources (should also support custom ones)
	;-- which are: objects that define on-change* and eventually call `check`
	;-- but last condition can't be verified, because check may be buried in other function calls, so..
	set 'reactor? function ["Check if object is a reactor" obj [any-type!]] [
		all [
			object? :obj
			oc: in obj 'on-change*
			function? get/any oc						;-- can be unset when `is` is used in global context
		]
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
		; return:		[block! function! none!] "The reactive relation or NONE if no relation was processed"
		/local item
	][
		case [
			link [
				--measure-- [time/count in-react]
				unless function? :reaction [cause-error 'script 'react-bad-func []]
				args: clear []
				parse spec-of :reaction [
					collect into args some [keep word! | [refinement! | set-word!] break | skip]
				]
				if empty? args [cause-error 'script 'react-not-enough []]
				objects: reduce objects
				
				if (length? objects) <> length? args [cause-error 'script 'react-no-match []]
				unless parse objects [some object!][cause-error 'script 'react-bad-obj []]
				
				insert objects :reaction
				plan: clear []
				for-all-paths item body-of :reaction [
					all [
						word? :item/2
						pos: find args item/1
						obj: pick objects 1 + index? pos
						reactor? :obj
						found?: repend plan [obj item/2]
					]
				]
				--measure-- [time/save]
				foreach [obj word] plan [add-relation obj word :reaction objects]
				if all [found? not later] [eval objects]
			]
			unlink [
				--measure-- [time/count in-remove]
				case [
					object? src [
						found?: unlink-reaction src :reaction
					]
					block? src [
						objs: reactors-for :reaction
						foreach obj src [
							if unlink-reaction obj :reaction [found?: yes]
						]
					]
					src = 'all [
						if pos: find-reaction :reaction [
							objs: pos/2					;-- save it; unlink may change `pos` content
							while [not empty? objs] [
								if unlink-reaction objs/1 :reaction [found?: yes]
							]
						]
					]
					'else [cause-error 'script 'invalid-arg [src]]
				]
				--measure-- [time/save]
			]
			'else [
				--measure-- [time/count in-react]
				unless block? :reaction [cause-error 'script 'invalid-arg [:reaction]]
				plan: clear []
				for-all-paths item reaction [
					if unset? attempt [get/any item][
						cause-error 'script 'no-value [item]
					]
					part: get-object-path-length item 'obj
					all [
						reactor? :obj
						word? word: :item/(part + 1)
						found?: repend plan [obj word]
					]
				]
				--measure-- [time/save]
				foreach [obj word] plan [add-relation obj word reaction ctx]
				if all [found? not later] [eval reaction]
			]
		]
		either found? [:reaction][none]					;-- returns NONE if no relation was processed
	];; set 'react

];; system/reactivity

reactor!: context [
	on-change*: func [word [word! set-word!] old [any-type!] new [any-type!]] [
		system/reactivity/on-change-handler self word :old :new
	]
]

deep-reactor!: make reactor! [
	on-deep-change*: func [owner word target action new [any-type!] index part][
		system/reactivity/check owner word
	]
]

reactor:	  function [spec [block!]][make reactor!      spec]
deep-reactor: function [spec [block!]][make deep-reactor! spec]

];; #local
