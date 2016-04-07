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
		copy-cell
		get-root
		get-root-node
		type-check-alt
		type-check
		set-int-path*
		eval-int-path*
		set-path*
		eval-path*
		eval-int-path
		eval-path
			
		stack/mark
		stack/unwind
		stack/unwind-last
		stack/reset
		stack/push
		stack/check-call
		stack/unroll
		stack/revert
		stack/adjust-post-try
		
		interpreter/eval-path
		
		none/push-last
		
		logic/false?
		logic/true?
		
		;*/push-local
		refinement/push-local
		lit-word/push-local
		
		action/push
		binary/push
		block/push
		char/push
		datatype/push
		error/push
		event/push
		file/push
		float/push
		_function/push
		get-path/push
		get-word/push
		hash/push
		image/push
		integer/push
		issue/push
		lit-path/push
		lit-word/push
		logic/push
		map/push
		native/push
		none/push
		object/push
		op/push
		pair/push
		paren/push
		path/push
		percent/push
		point/push
		refinement/push
		routine/push
		set-path/push
		set-word/push
		string/push
		tuple/push
		typeset/push
		unset/push
		url/push
		vector/push
		word/push
		
		block/push-only*
		block/insert-thru
		block/append-thru
		
		percent/push64
		float/push64
		
		word/get
		word/get-local
		word/get-any
		word/get-in
		word/set-in
		word/replace
		word/from
		
		get-word/get
		
		_context/get
		_context/clone
		_context/set-integer
		
		object/duplicate
		object/transfer
		object/init-push
		object/init-events
		object/loc-fire-on-set*
		object/fire-on-set*
		
		integer/get-any*
		integer/get*
		integer/get
		logic/get
		float/get
		
		integer/box
		logic/box
		float/box
		
		_function/init-locals
		
		object/unchanged?
		object/unchanged2?
		
		natives/repeat-init*
		natives/repeat-set
		natives/foreach-next-block
		natives/foreach-next
		natives/forall-loop
		natives/forall-next
		natives/forall-end

		actions/make*
		actions/random*
		actions/reflect*
		actions/to*
		actions/form*
		actions/mold*
		actions/eval-path*
		actions/compare
		actions/absolute*
		actions/add*
		actions/divide*
		actions/multiply*
		actions/negate*
		actions/power*
		actions/remainder*
		actions/round*
		actions/subtract*
		actions/even?*
		actions/odd?*
		actions/and~*
		actions/complement*
		actions/or~*
		actions/xor~*
		actions/append*
		actions/at*
		actions/back*
		actions/clear*
		actions/copy*
		actions/find*
		actions/head*
		actions/head?*
		actions/index?*
		actions/insert*
		actions/length?*
		actions/next*
		actions/pick*
		actions/poke*
		actions/put*
		actions/remove*
		actions/reverse*
		actions/select*
		actions/sort*
		actions/skip*
		actions/swap*
		actions/tail*
		actions/tail?*
		actions/take*
		actions/trim*
		actions/modify*
		actions/read*
		actions/write*

		natives/if*
		natives/unless*
		natives/either*
		natives/any*
		natives/all*
		natives/while*
		natives/until*
		natives/loop*
		natives/repeat*
		natives/forever*
		natives/foreach*
		natives/forall*
		natives/func*
		natives/function*
		natives/does*
		natives/has*
		natives/switch*
		natives/case*
		natives/do*
		natives/get*
		natives/set*
		natives/print*
		natives/prin*
		natives/equal?*
		natives/not-equal?*
		natives/strict-equal?*
		natives/lesser?*
		natives/greater?*
		natives/lesser-or-equal?*
		natives/greater-or-equal?*
		natives/same?*
		natives/not*
		natives/type?*
		natives/reduce*
		natives/compose*
		natives/stats*
		natives/bind*
		natives/in*
		natives/parse*
		natives/union*
		natives/intersect*
		natives/unique*
		natives/difference*
		natives/exclude*
		natives/complement?*
		natives/dehex*
		natives/negative?*
		natives/positive?*
		natives/max*
		natives/min*
		natives/shift*
		natives/to-hex*
		natives/sine*
		natives/cosine*
		natives/tangent*
		natives/arcsine*
		natives/arccosine*
		natives/arctangent*
		natives/arctangent2*
		natives/NaN?*
		natives/log-2*
		natives/log-10*
		natives/log-e*
		natives/exp*
		natives/square-root*
		natives/construct*
		natives/value?*
		natives/try*
		natives/uppercase*
		natives/lowercase*
		natives/as-pair*
		natives/break*
		natives/continue*
		natives/exit*
		natives/return*
		natives/throw*
		natives/catch*
		natives/extend*
		natives/debase*
		natives/to-local-file*
		natives/request-file*
		natives/wait*
		natives/request-dir*
		natives/checksum*
		natives/unset*
	]
	
	vars: [
		stack/arguments
		stack/top
	]
	
	exports: make block! 300
	imports: make block! 100
	
	template: make string! 50'000
	
	extract: func [functions][
		clear template 
		
		foreach def funcs [
			def: to word! form either word? def [append to path! 'red def][head insert def 'red]
?? def			
			spec: select functions def
			unless spec [print ["*** libRed Error: definition not found for" def] halt]
		]
halt		
	]
	
]