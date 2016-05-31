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
				tab "old  :" type? old	lf
				tab "new  :" type? new
			]
		]
		unless all [block? old block? new same? head old head new][
			if any [series? old object? old][modify old 'owned none]
			if any [series? new object? new][modify new 'owned reduce [self word]]
		]
		system/reactivity/check/only self word
	]
]

system/reactivity: context [
	relations:	make block! 1000		;@@ change it to hash! once stable
	stack:		make block! 100			;@@ change it to hash! once stable ???
	debug?: 	no
	
	do-safe: func [code [block!] /local result][
		if error? set/any 'result try/all code [
			print :result								;@@ improve error reporting
			result: none
		]
		get/any 'result
	]
	
	check: function [reactor [object!] /only field [word!]][
		unless empty? pos: relations [
			while [pos: find/skip pos reactor 4][
				if all [
					any [not only pos/2 = field]
					not find/same stack reaction: pos/3
				][
					append/only stack :reaction
					do-safe any [all [block? :reaction reaction] pos/4]
					take/last stack
				]
				pos: skip pos 4
			]
		]
	]
	
	set 'clear-relations function ["Removes all reactive relations"][clear relations]
	
	set 'react function [
		"Defines a new reactive relation between two or more objects"
		reaction	[block! function!]	"Reactive relation"
		/link							"Link objects together using a reactive relation"
			target	[block!]			"Target objects to link together"
		/unlink							"Removes an existing reactive relation"
			src		[word! object! block!]
		/with							"Specifies an optional face object (internal use)"
			ctx		[object! none!]		"Optional face context"
		return:		[block!]			"List of faces causing a reaction"
	][
		case [
			link [
				;unless function? :reaction [cause-error...]
				objs: parse spec-of :reaction [
					collect some [keep word! | [refinement! | set-word!] break | skip]
				]
				;if 2 <= length objs [cause-error...]
				target: reduce target
				;if (length? target) <> length? objs [cause-error ...]
				;unless parse target [some object!][cause-error ...]
				insert target :reaction
				
				parse body-of :reaction rule: [
					any [
						item: [path! | lit-path! | get-path!] (
							item: item/1
							if pos: find objs item/1 [
								obj: pick target 1 + index? pos
								repend relations [obj item/2 :reaction target]
							]
						)
						| set-path! | any-string!
						| into rule
						| skip
					]
				]
			]
			unlink [
				pos: relations
				while [pos: find pos :reaction][
					obj: pos/-2
					if any [src = 'all src = obj all [block? src find src obj]][
						pos: remove/part skip pos -2 4
					]
				]
			]
			'else [
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
		:reaction
	]
]

