REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

libRed: context [
	funcs: vars: none
	
	set [funcs vars] load-cache %system/utils/libRed-exports.r
		
	imports: make block! 100
	template: make string! 100'000
	obj-path: 'red/objects
	
	include-file: %libRed-include.red
	defs-file:	  %libRed-defs.red
	root-dir:	  %./
	
	get-path: func [file][
		either all [system/version/4 = 3 root-dir/1 = %.][
			file
		][
			root-dir/:file
		]
	]
	
	get-include-file: func [job][
		data: read get-path include-file
		replace/all data "$ROOT-PATH$" form job/build-prefix
		load data
	]
	
	get-definitions: func [/local data][
		data: load get-path defs-file
		foreach part [1 7 8][
			replace/all data/:part %"" to word! "%"
			replace/all data/:part ">>>" to word! ">>>"
		]
		data
	]
	
	make-exports: func [functions exports /local name][
		foreach [name spec] functions [
			if all [
				pos: find/match form name "exec/"
				not find pos slash
			][
				append/only funcs load form name
			]
		]
		foreach def funcs [
			name: to word! form def
			append exports name
			unless select/only functions name [
				print ["*** libRed Error: definition not found for" def]
				halt
			]
			system-dialect/compiler/flag-callback name none
		]
		foreach [def type] vars [
			name: to word! form def
			append exports name
		]
	]
	
	obj-to-path: func [list tree /local pos o][
		foreach [sym obj ctx id proto opt] list [
			if 2 < length? obj-path [
				pos: find tree obj
				change/only pos to paren! reduce [append copy obj-path sym]
			]
			if object? obj [
				foreach w next first obj [
					if object? o: get in obj w [
						append obj-path load mold/flat sym	;-- clean-up unwanted newlines hints
						obj-to-path reduce [w o none none none none] tree
						remove back tail obj-path
					]
				]
			]
		]
		tree
	]
	
	process: func [job functions exports /local name list pos tmpl words lits file base-dir][
		make-exports functions exports
		if job/OS = 'Windows [append/only funcs 'red/image/push]
		
		clear imports
		clear template
		append template "^/red: context "
		
		append imports [
			#define series!	series-buffer!
			#define node! int-ptr!
			#define get-unit-mask	31
			
			#include %$ROOT-PATH$runtime/macros.reds
			#include %$ROOT-PATH$runtime/datatypes/structures.reds
				
			cell!: alias struct! [
				header	[integer!]						;-- cell's header flags
				data1	[integer!]						;-- placeholders to make a 128-bit cell
				data2	[integer!]
				data3	[integer!]
			]
			series-buffer!: alias struct! [
				flags	[integer!]						;-- series flags
				node	[int-ptr!]						;-- point back to referring node
				size	[integer!]						;-- usable buffer size (series-buffer! struct excluded)
				offset	[cell!]							;-- series buffer offset pointer (insert at head optimization)
				tail	[cell!]							;-- series buffer tail pointer 
			]
			
			root-base: as cell! 0
			
			get-root: func [
				idx		[integer!]
				return: [red-block!]
			][
				as red-block! root-base + idx
			]
			
			get-root-node: func [
				idx		[integer!]
				return: [node!]
				/local
					obj [red-object!]
			][
				obj: as red-object! get-root idx
				obj/ctx
			]

		]
		foreach def funcs [
			ctx: next def
			list: imports
			
			while [not tail? next ctx][
				unless pos: find list name: to set-word! ctx/1 [
					pos: tail list
					repend list [
						name 'context
						make block! 10
					]
					new-line skip tail list -3 yes
				]
				list: pos/3
				ctx: next ctx
			]
			either pos: find list #import [pos: pos/2/3][
				append list copy/deep [
					#import [LIBRED-file stdcall]
				]
				append/only last list pos: make block! 20
			]
			name: last ctx
			append pos to set-word! name
			new-line back tail pos yes
			name: to word! form def
			append pos mold name
			
			spec: copy/deep functions/:name/4
			clear find spec /local
			append/only pos spec
		]
		
		foreach [def type] vars [
			list: either 2 < length? def [
				pos: find imports to set-word! def/2
				pos/3/2/3
			][
				pos: find imports #import
				pos/2/3
			]
			repend list [
				to set-word! last def form def reduce [type]
			]
			new-line skip tail list -3 yes
		]
		list: find imports to set-word! 'stack
		append list/3 [
			#enum flags! [FRAME_FUNCTION: 16777216]				;-- 01000000h
		]
		append imports [
			words: context [
				_body:	red/word/load "<body>"
				_anon:	red/word/load "<anon>"
			]
		]
		
		append template mold imports
		tmpl: load replace/all mold template "[red/" "["
		
		base-dir: either encap? [%""][%../]
		file: get-path include-file
		write clean-path base-dir/:file tmpl
		
		words: to-block extract red/symbols 2
		remove-each w words [find form w #"~"]
		
		lits: copy red/literals
		while [pos: find lits 'get-root][
			remove/part skip pos -3 5
		]
		replace/all lits 'get-root-node 'get-root-node2
		
		tmpl: mold/all reduce [
			new-line/all/skip to-block red/functions yes 2
			red/redbin/index
			red/globals
			obj-to-path list: copy/deep red/objects list
			red/contexts
			red/actions
			red/op-actions
			words
			lits
			red/s-counter
		]
		replace/all tmpl "% " {%"" }
		replace/all tmpl ">>>" {">>>"}
		replace/all tmpl "red/red-" "red-"

		file: get-path defs-file
		write clean-path base-dir/:file tmpl
	]
	
]