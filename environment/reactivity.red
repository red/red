Red [
	Title:	"Reactive programming support"
	Author: "Nenad Rakocevic"
	File: 	%reactivity.red
	Tabs: 	4
	Rights: "Copyright (C) 2016-2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#local [
#macro REL-PERIOD: func [][3]
#macro IDX-PERIOD: func [][2]

system/reactivity: context [
	;-- index format: [reaction [reactors..] ...]        -- required by react/unlink 'all, dump-reactions, clear-reactions, stop-reactor
	index:       make hash! 1000						;-- hash speeds up unlinking noticeably

	;-- queue format: [reactor reaction target done]
	queue:		 make hash! 100

	debug?: 	 no
	metrics?:    no
	source:		 []		;-- contains the initial [reactor reaction] that triggered a chain of subsequent reactions

	metrics: context [
		max-queue: max-index: max-reactors: max-relations: 0
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
			print ["    maximum queue size: " max-queue]
			print ["    maximum index size: " max-index]
			print ["    biggest relation:   " max-reactors "reactors"]
			print ["    most used reactor:  " max-relations "relations"]
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
				if 1 < overshoot: (length? s: form blk) / limit [	;-- trim longest parts equally
					foreach x next blk [							;-- don't trim the prefix
						if 15 < n: length? x [
							clear skip x to integer! n / overshoot
						]
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

	relations-of: func [reactor [object!]] [select body-of :reactor/on-change* 'relations]
	reactors-for:  func [reaction [block! function!]] [select/same/only/skip index :reaction IDX-PERIOD]

	unique-objects: function [] [						;-- used by debug funcs only
		unique collect [foreach [_ list] index [keep list]]
	]
	
	relations-count: function [] [
		sum: 0
		foreach obj unique-objects [sum: (length? relations-of obj) / REL-PERIOD + sum]
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
		relations: relations-of obj
		unless find/same/skip relations new-rel REL-PERIOD [
			append relations new-rel
			unless objs: reactors-for :reaction [
				reduce/into [:reaction objs: make block! 10] tail index
			]
			unless find/same objs obj [append objs obj]
			if block? targets [							;-- react/link func .. [func objects..] case
				foreach obj next targets [
					unless find/same objs obj [append objs obj]
				]
			]
			--measure-- [
				peak max-relations (length? relations) / REL-PERIOD
				peak max-reactors   length? objs
				peak max-index     (length? index) / IDX-PERIOD
			]
			--debug-print-- ["-- react: added --" :reaction "FOR" word "IN" obj]
		]
		--measure-- [time/save]
	]
	
	eval: function [code [block!] /safe /local result saved][
		--measure-- [
			time/count in-eval
			incr fired
		]
		--debug-print--/full ["-- react: firing --" either function? first code [body-of first code][code]]
		either safe [
			if error? error: try/all [set/any 'result do code  'ok] [
				print :error
				prin "*** Near: "
				print mold/part/flat code 80
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
		pattern: head reduce/into [reactor :reaction] clear []
		none <> find/same/skip queue pattern 4
	]

	check: function [reactor [object!] field [word! set-word!] /local word reaction target][
		--debug-print--/full/no-gui ["-- react: checking --" field "IN" reactor]
		--measure-- [time/count in-check]
		pos: relations-of reactor
		unless pos: find/skip pos field REL-PERIOD [exit]
		if initial?: tail? source [reduce/into [reactor field] source]
		until [
			set [word reaction target] pos
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
			none? pos: find/skip skip pos REL-PERIOD field REL-PERIOD
		]
		if initial? [clear source]
		--measure-- [peak longest-flush time/save]
	]
	
	set 'stop-reactor function [
		"Forget all relations involving reactor OBJ"
		obj [object!] "Face or reactor"
		/deep "Deeply remove all relations from child faces"
	][
		--measure-- [time/count in-remove]
		relations: relations-of obj
		reactions: unique extract/into next relations REL-PERIOD clear []	;-- same reaction may be repeated many times for different words
		foreach reaction reactions [
			--debug-print-- ["-- react: removed --" :reaction "FROM" obj]
			pos: find/same/only/skip index :reaction IDX-PERIOD
			remove find/same pos/2 obj
			if tail? pos/2 [remove-part pos IDX-PERIOD]
		]
		clear relations
		--measure-- [time/save]

		if all [deep  block? :obj/pane] [
			foreach f obj/pane [stop-reactor/deep f]
		]
	]

	set 'clear-reactions function ["Remove all reactive relations"][
		foreach obj unique-objects [
			--debug-print-- ["-- react: clearing all relations -- FROM" obj]
			relations: relations-of obj
			clear relations
		]
		clear index
	]
	
	set 'dump-reactions function [
		"Output all the current reactive relations for debugging purpose"
	][
		limit: (any [all [system/console system/console/size/x] 72]) - 10
		count: 0
		
		foreach reactor unique-objects [
			foreach [field reaction target] relations-of reactor [
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
		return: [block! function! word! none!] "Returns reaction, type or NONE"
	][
		pos: relations-of reactor
		either target [
			pos: at pos 3
			if pos: find/skip pos field REL-PERIOD [reaction: :pos/-1]	;-- looks for a set-word
		][
			if pos: find/skip pos field REL-PERIOD [reaction: :pos/2]
		]
		all [				;-- have to verify that on-change* block wasn't just copied into this object from other reactor
			:reaction
			objs: reactors-for :reaction
			find/same objs reactor
			return :reaction
		]
		none
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
		pos: next relations-of reactor
		while [pos: find/same/only/skip pos :reaction REL-PERIOD][
			--debug-print-- ["-- react: removed --" :reaction "FOR" pos/-1 "IN" reactor]
			remove-part back found?: pos REL-PERIOD
		]
		found?
	]

	set 'reactor? function ["Check if object is a reactor" obj [any-type!]] [
		all [
			object? :obj
			oc: in obj 'on-change*
			function? get/any oc						;-- can be unset when `is` is used in global context
			any-block? relations-of obj					;-- is a reactor, not other object with on-change*
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
		return:		[block! function! none!] "The reactive relation or NONE if no relation was processed"
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
						if found?: unlink-reaction src :reaction [
							remove find/same reactors-for :reaction src
						]
					]
					block? src [
						objs: reactors-for :reaction
						foreach obj src [
							if unlink-reaction obj :reaction [
								remove find/same objs obj
								found?: yes
							]
						]
					]
					src = 'all [
						if pos: find/only/same/skip index :reaction IDX-PERIOD [
							foreach obj pos/2 [
								if unlink-reaction obj :reaction [found?: yes]
							]
							clear pos/2					;-- dissociate from all objects
							remove-part pos IDX-PERIOD
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
	on-change*: function [word old [any-type!] new [any-type!]] [
		;-- relations format: [reactor word reaction targets]
		;;  src-word [reaction] set-word            	 -- used by `is` (evaluates reaction, assigns to target)
		;;  src-word function [func obj1 obj2...]   	 -- used by react/link (evaluates target), one relation for every reactor in both list and func's body
		;;  src-word [reaction] none                	 -- used by react (evaluates reaction)
		;;  src-word [reaction] set-word/object     	 -- used by react/with (evaluates reaction, assigns to a set-word only)
		relations: []									;-- relations placeholder (hash is ~10x times slower)

		sr: system/reactivity		
		sr/--debug-print--/full ["-- react: on-change --" word "FROM" type? :old "TO" type? :new]
		sr/--measure-- [incr events]
		if all [
			not empty? srs: sr/source
			srs/1 =? self
			srs/2 = word
		][
			set-quiet in self word :old					;-- force the old value
			sr/--measure-- [incr skipped]
			sr/--debug-print-- ["-- react: protected --" word "VALUE" :old "IN" self]
			exit
		]
		unless all [series? :old series? :new same? head :old head :new][
			if any [series? :old object? :old][modify old 'owned none]
			if any [series? :new object? :new][modify new 'owned reduce [self word]]
		]
		sr/check self word
	]
]

deep-reactor!: make reactor! [
	on-deep-change*: function [owner word target action new [any-type!] index part][
		system/reactivity/check owner word
	]
]

reactor:	  function [spec [block!]][make reactor!      spec]
deep-reactor: function [spec [block!]][make deep-reactor! spec]

];; #local
