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
		red/get-root
		red/get-root-node
		red/type-check-alt
		red/type-check
		red/set-int-path*
		red/eval-int-path*
		red/set-path*
		red/eval-path*
		red/eval-int-path
		red/eval-path
			
		red/stack/mark
		red/stack/unwind
		red/stack/unwind-last
		red/stack/reset
		red/stack/push
		red/stack/check-call
		red/stack/unroll
		red/stack/revert
		red/stack/adjust-post-try
		
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
		red/word/replace
		red/word/from
		
		red/get-word/get
		
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
		red/actions/clear*
		red/actions/copy*
		red/actions/find*
		red/actions/head*
		red/actions/head?*
		red/actions/index?*
		red/actions/insert*
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
	]
	
	vars: [
		red/stack/arguments
		red/stack/top
	]
	
	imports: make block! 100
	
	template: make string! 50'000
	
	make-exports: func [functions exports][
		foreach def funcs [
			def: to word! form def
			append exports def		
			unless select functions def [
				print ["*** libRed Error: definition not found for" def]
				halt
			]
		]
	]
	
	process: func [functions][
		clear template 
		
		foreach def funcs [
			def: to word! form def
			append exports def
			spec: functions/:def
?? spec			
			unless spec [print ["*** libRed Error: definition not found for" def] halt]
		]		
	]
	
]