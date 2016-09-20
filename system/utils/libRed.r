REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Notes: {
		These utility functions extract types ID and function definitions from Red
		runtime source code and make it available to the compiler, before the Red runtime
		is actually compiled.
		
		This procedure is required during bootstrapping, as the REBOL compiler can't
		examine loaded Red data in memory at runtime.
	}
]

libRed: context [

	funcs: [
		red/copy-cell
		;red/get-root
		red/get-root-node2
		red/type-check-alt
		red/type-check
		red/set-int-path*
		red/eval-int-path*
		red/set-path*
		red/eval-path*
		red/eval-int-path
		red/eval-path
		red/select-key*
		
		red/redbin/boot-load
		
		red/platform/prin*
		red/platform/prin-int*
		red/platform/prin-hex*
		red/platform/prin-2hex*
		red/platform/prin-float*
		red/platform/prin-float32*
		
		red/stack/mark
		red/stack/mark-native
		red/stack/mark-func
		red/stack/mark-loop
		red/stack/mark-try
		red/stack/mark-try-all
		red/stack/mark-catch
		red/stack/mark-func-body
		red/stack/unwind
		red/stack/unwind-last
		red/stack/reset
		red/stack/keep
		red/stack/push
		red/stack/check-call
		red/stack/unroll
		red/stack/unroll-loop
		red/stack/revert
		red/stack/adjust-post-try
		red/stack/pop
		
		red/interpreter/eval-path
		
		red/none/push-last
		
		red/logic/false?
		red/logic/true?
		
		;*/push-local
		red/refinement/push-local
		red/lit-word/push-local
		
		red/action/push
		red/binary/push
		red/block/push
		red/char/push
		red/datatype/push
		;red/event/push
		red/file/push
		red/float/push
		red/_function/push
		red/get-path/push
		red/get-word/push
		red/image/push
		red/integer/push
		red/issue/push
		red/lit-path/push
		red/lit-word/push
		red/logic/push
		red/map/push
		red/native/push
		red/none/push
		red/object/push
		red/op/push
		red/pair/push
		red/paren/push
		red/path/push
		red/percent/push
		red/refinement/push
		red/routine/push
		red/set-path/push
		red/set-word/push
		red/string/push
		red/tuple/push
		red/typeset/push
		red/unset/push
		red/url/push
		red/vector/push
		red/word/push
		
		red/block/push-only*
		red/block/insert-thru
		red/block/append-thru
		
		red/percent/push64
		red/float/push64
		
		red/word/get
		red/word/get-local
		red/word/get-any
		red/word/get-in
		red/word/set-in
		red/word/set
		red/word/replace
		red/word/from
		red/word/load
		red/word/push-local
		
		red/get-word/get
		red/set-word/push-local
		
		red/_context/get
		red/_context/clone
		red/_context/set-integer
		
		red/object/duplicate
		red/object/transfer
		red/object/init-push
		red/object/init-events
		red/object/loc-fire-on-set*
		red/object/fire-on-set*
		
		red/integer/get-any*
		red/integer/get*
		red/integer/get
		red/logic/get
		red/float/get
		
		red/integer/box
		red/logic/box
		red/float/box
		
		red/_function/init-locals
		
		;-- console.red dependencies
		red/block/rs-head
		red/block/rs-next
		red/block/rs-tail?
		red/block/rs-length?
		red/block/rs-abs-at
		red/block/rs-append
		red/string/rs-head
		red/string/rs-tail?
		red/string/equal?
		red/string/rs-make-at
		red/string/get-char
		red/string/rs-reset
		red/string/concatenate
		red/string/rs-length?
		red/string/concatenate-literal
		red/string/append-char
		red/string/insert-char
		red/string/rs-abs-length?
		red/string/remove-char
		red/string/poke-char
		red/string/remove-part
		red/_series/copy
		;--
		
		red/unicode/load-utf8
		
		red/object/unchanged?
		red/object/unchanged2?
		
		red/natives/repeat-init*
		red/natives/repeat-set
		red/natives/foreach-next-block
		red/natives/foreach-next
		red/natives/forall-loop
		red/natives/forall-next
		red/natives/forall-end

		red/actions/make*
		red/actions/random*
		red/actions/reflect*
		red/actions/to*
		red/actions/form*
		red/actions/mold*
		red/actions/eval-path*
		red/actions/compare
		red/actions/absolute*
		red/actions/add*
		red/actions/divide*
		red/actions/multiply*
		red/actions/negate*
		red/actions/power*
		red/actions/remainder*
		red/actions/round*
		red/actions/subtract*
		red/actions/even?*
		red/actions/odd?*
		red/actions/and~*
		red/actions/complement*
		red/actions/or~*
		red/actions/xor~*
		red/actions/append*
		red/actions/at*
		red/actions/back*
		red/actions/change*
		red/actions/clear*
		red/actions/copy*
		red/actions/find*
		red/actions/head*
		red/actions/head?*
		red/actions/index?*
		red/actions/insert*
		red/actions/move*
		red/actions/length?*
		red/actions/next*
		red/actions/pick*
		red/actions/poke*
		red/actions/put*
		red/actions/remove*
		red/actions/reverse*
		red/actions/select*
		red/actions/sort*
		red/actions/skip*
		red/actions/swap*
		red/actions/tail*
		red/actions/tail?*
		red/actions/take*
		red/actions/trim*
		red/actions/modify*
		red/actions/read*
		red/actions/write*

		red/natives/if*
		red/natives/unless*
		red/natives/either*
		red/natives/any*
		red/natives/all*
		red/natives/while*
		red/natives/until*
		red/natives/loop*
		red/natives/repeat*
		red/natives/forever*
		red/natives/foreach*
		red/natives/forall*
		red/natives/func*
		red/natives/function*
		red/natives/does*
		red/natives/has*
		red/natives/switch*
		red/natives/case*
		red/natives/do*
		red/natives/get*
		red/natives/set*
		red/natives/print*
		red/natives/prin*
		red/natives/equal?*
		red/natives/not-equal?*
		red/natives/strict-equal?*
		red/natives/lesser?*
		red/natives/greater?*
		red/natives/lesser-or-equal?*
		red/natives/greater-or-equal?*
		red/natives/same?*
		red/natives/not*
		red/natives/type?*
		red/natives/reduce*
		red/natives/compose*
		red/natives/stats*
		red/natives/bind*
		red/natives/in*
		red/natives/parse*
		red/natives/union*
		red/natives/intersect*
		red/natives/unique*
		red/natives/difference*
		red/natives/exclude*
		red/natives/complement?*
		red/natives/dehex*
		red/natives/negative?*
		red/natives/positive?*
		red/natives/max*
		red/natives/min*
		red/natives/shift*
		red/natives/to-hex*
		red/natives/sine*
		red/natives/cosine*
		red/natives/tangent*
		red/natives/arcsine*
		red/natives/arccosine*
		red/natives/arctangent*
		red/natives/arctangent2*
		red/natives/NaN?*
		red/natives/log-2*
		red/natives/log-10*
		red/natives/log-e*
		red/natives/exp*
		red/natives/square-root*
		red/natives/construct*
		red/natives/value?*
		red/natives/try*
		red/natives/uppercase*
		red/natives/lowercase*
		red/natives/as-pair*
		red/natives/break*
		red/natives/continue*
		red/natives/exit*
		red/natives/return*
		red/natives/throw*
		red/natives/catch*
		red/natives/extend*
		red/natives/debase*
		red/natives/to-local-file*
		red/natives/request-file*
		red/natives/wait*
		red/natives/request-dir*
		red/natives/checksum*
		red/natives/unset*
		red/natives/handle-thrown-error
	]
	
	vars: [
		red/stack/arguments		cell!
		red/stack/top			cell!
		red/stack/bottom		cell!
		red/unset-value			cell!
		red/none-value			cell!
		red/true-value			cell!
		red/false-value			cell!
	]
	
	imports: make block! 100
	template: make string! 50'000
	obj-path: 'red/objects
	
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
	
	process: func [functions /local name list pos tmpl words lits][
		clear imports
		clear template
		append template "^/red: context "
		
		append imports [
			#define series!	series-buffer!
			#define node! int-ptr!
			#define get-unit-mask	31
			
			#include %/c/dev/red/runtime/macros.reds
			#include %/c/dev/red/runtime/datatypes/structures.reds
				
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
					#import ["libRed.dll" stdcall]
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
		write %/c/dev/red/libred-include.red tmpl
		
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
		write %/c/dev/red/libred-defs.red tmpl
	]
	
]