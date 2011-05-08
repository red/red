REBOL [
	Title:   "Red/System code emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %emitter.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %targets/target-class.r

emitter: context [
	code-buf: make binary! 10'000
	data-buf: make binary! 10'000
	symbols:  make hash! 200			;-- [name [type address [relocs]] ...]
	stack: 	  make hash! 40				;-- [name offset ...]
	exits:	  make block! 1				;-- [offset ...]	(funcs exits points)
	verbose:  0							;-- logs verbosity level
	
	target:	  none						;-- target code emitter object placeholder
	compiler: none						;-- just a short-cut

		
	pointer: make struct! [
		value [integer!]				;-- 32/64-bit, watch out for endianess!!
	] none
	
	datatypes: to-hash [
		int8!		1	signed
		byte!		1	unsigned
		int16!		2	signed
		int32!		4	signed
		integer!	4	signed
		int64!		8	signed
		uint8!		1	unsigned
		uint16!		2	unsigned
		uint32!		4	unsigned
		uint64!		8	unsigned
		logic!		4	-
		pointer!	4	-				;-- 32-bit, 8 for 64-bit
		binary!		4	-				;-- 32-bit, 8 for 64-bit
		c-string!	4	-				;-- 32-bit, 8 for 64-bit
		struct!		4	-				;-- 32-bit, 8 for 64-bit ; struct! passed by reference
	]
	
	chunks: context [
		queue: make block! 10
		
		start: has [s][
			repend/only queue [
				s: tail code-buf
				make block! 10
			]
			index? s
		]
		
		stop: has [entry blk][
			entry: last queue
			remove back tail queue
			blk: reduce [copy entry/1 entry/2 index? entry/1]
			clear entry/1
			blk
		]
	
		make-boolean: does [
			start
			reduce [
				target/emit-boolean-switch
				stop
			]
		]

		join: func [a [block!] b [block!] /local bytes][
			bytes: length? a/1
			foreach ptr b/2 [ptr/1: ptr/1 + bytes]		;-- adjust relocs
			append a/1 b/1
			append a/2 b/2		
			a
		]
	]
	
	branch: func [
		chunk [block!]
		/over
		/back
		/on cond [word! block! logic!]
		/adjust offset [integer!]
		/local size
	][
		case [
			over [
				size: target/emit-branch chunk/1 cond offset			
				foreach ptr chunk/2 [ptr/1: ptr/1 + size]	;-- adjust relocs
				size
			]
			back [
				target/emit-branch/back chunk/1 cond offset
			]
		]
	]

	merge: func [chunk [block!]][
		either empty? chunks/queue [
			append code-buf chunk/1			
		][
			clear at code-buf chunk/3
			append code-buf chunk/1						;-- replace obsolete buffer
			append second last chunks/queue chunk/2		
		]
	]
	
	tail-ptr: does [index? tail code-buf] 				;-- one-based addressing
	 
	pad-data-buf: func [sz [integer!] /local over][
		unless zero? over: (length? data-buf) // sz [
			insert/dup tail data-buf null sz - over
		]
	]
	
	make-name: has [cnt][
		cnt: [0]										;-- persistent counter
		to-word join "no-name-" cnt/1: cnt/1 + 1
	]
	
	get-symbol-spec: func [name [word!]][
		any [
			all [compiler/locals select compiler/locals name]
			select compiler/globals name
		]
	]
	
	get-func-ref: func [name [word!] /local entry][
		entry: find/last symbols name
		if entry/2/1 = 'native [
			repend symbols [		;-- copy 'native entry to a 'global entry
				name reduce ['native-ref entry/2/2 make block! 1]
			]
			entry: skip tail symbols -2 
		]		
		entry/2
	]

	logic-to-integer: func [op [word!]][
		if find target/comparison-op op [
			set [offset body] chunks/make-boolean
			branch/over/on/adjust body reduce [op] offset/1
			merge body
		]
	]
	
	add-symbol: func [
		name [word! tag!] ptr [integer!] /with refs [block! word! none!] /local spec
	][
		spec: reduce [name reduce ['global ptr make block! 1 any [refs '-]]]
		append symbols new-line spec yes
		spec
	]

	store-global: func [value type [word!] spec [block! word! none!] /local size ptr][
		if logic? value [
			type: 'integer!
			value: to integer! value					;-- TRUE => 1, FALSE => 0
		]
		if value = <last> [
			type: 'integer!
			value: 0
		]
		size: size-of? type
		ptr: tail data-buf
	
		switch/default type [
			integer! [
				unless integer? value [value: 0]
				pad-data-buf target/default-align
				ptr: tail data-buf			
				value: debase/base to-hex value 16
				either target/little-endian? [
					value: tail value
					loop size [append ptr to char! (first value: skip value -1)]
				][
					append ptr skip tail value negate size		;-- truncate if required
				]
			]
			byte! [
				unless char? value [value: #"^@"]
				append ptr value
			]
			c-string! [
				either string? value [
					repend ptr [value null]
				][
					pad-data-buf target/ptr-size		;-- pointer alignment can be <> of integer
					ptr: tail data-buf	
					store-global 0 'integer! none
				]
			]
			pointer! [
				pad-data-buf target/ptr-size			;-- pointer alignment can be <> of integer
				ptr: tail data-buf	
				store-global 0 'integer! none
			]
			struct! [
				pad-data-buf target/struct-align-size
				ptr: tail data-buf
				foreach [var type] spec [
					type: either find [struct! c-string!] type/1 ['pointer!][type/1]
					store-global 0 type none
				]
			]
		][
			make error! "store-global unexpected type!"
		]
		(index? ptr) - 1								;-- offset of stored value
	]
		
	store-value: func [
		name [word! none!]
		value
		type [block!]
		/ref ref-ptr
		/local ptr
	][
		ptr: store-global value type/1 all [			;-- allocate value slot
			type/1 = 'struct!
			type/2
		]
		add-symbol/with any [name <data>] ptr ref-ptr	;-- add variable/value to globals table
	]
	
	store: func [
		name [word!] value type [block!]
		/local new-global? ptr refs n-spec spec
	][
		new-global?: not any [							;-- TRUE if unknown global symbol
			find stack name								;-- local variable
			find symbols name 							;-- known symbol
		]
		
		either all [
			compiler/literal? value						;-- literal values only
			find [c-string! struct!] type/1				;-- complex types only
		][
			if new-global? [
				ptr: store-global 0 'pointer! none		;-- allocate separate variable slot
				n-spec: add-symbol name ptr				;-- add variable to globals table
				refs: reduce [ptr + 1]					;-- reference value from variable slot
				name: none								;-- anonymous data storing
			]
			spec: store-value/ref name value type refs  ;-- store new value in data buffer
			if n-spec [spec: n-spec]
		][
			if new-global? [spec: store-value name value type] ;-- store new variable with value
		]
		if name [target/emit-store name value spec]
	]
		
	member-offset?: func [spec [block!] name [word! none!] /local offset][
		offset: 0
		foreach [var type] spec [
			if var = name [break]
			offset: offset + max size-of? type/1 target/struct-align-size
		]
		offset
	]
	
	resolve-path-head: func [path [path! set-path!] parent [block! none!]][
		second either head? path [
			compiler/resolve-type path/1
		][
			compiler/resolve-type/with path/1 parent
		]
	]
	
	access-path: func [path [path! set-path!] value /with parent [block!] /local type][
		either 2 = length? path [
			type: first compiler/resolve-type/with path/1 parent
			if all [type = 'struct! parent][
				parent: resolve-path-head path parent
			]
			either set-path? path [
				target/emit-store-path path type value parent
			][
				target/emit-load-path path type parent
			]
		][
			if head? path [target/emit-init-path path/1]
			parent: resolve-path-head path parent
			target/emit-access-path path parent
			access-path/with next path value parent
		]
	]

	size-of?: func [type [word!]][
		any [
			select datatypes type						;-- search in core types
			all [										;-- search in user-aliased types
				type: select compiler/aliased-types type
				select datatypes type/1
			]
		]
	]
	
	arguments-size?: func [locals [block!] /push /local pos ret size][
		pos: find locals /local
		ret: to-set-word 'return
		if push [clear stack]
		size: 0
		foreach [name type] any [all [pos copy/part locals pos] copy locals][
			if name <> ret [
				if push [repend stack [name size + 8]]	;-- account for esp + ebp storage ;TBD: make it target-independent
				size: size + max size-of? type/1 target/stack-width		
			]
		]
		size
	]
	
	resolve-exit-points: has [end offset][
		end: tail-ptr
		offset: target/branch-offset-size
		foreach ptr exits [
			change at code-buf ptr target/to-bin32 end - ptr - offset
		]
	]
	
	enter: func [name [word!] locals [block!] /local ret args-sz locals-sz pos][
		symbols/:name/2: tail-ptr						;-- store function's entry point
		all [
			spec: find/last symbols name
			spec/2/1 = 'native-ref						;-- function's address references
			spec/2/2: tail-ptr							;-- store entry point here too
		]
		clear exits										;-- reset exit-points list

		;-- Implements Red/System calling convention -- (STDCALL without reversing)		
		args-sz: arguments-size?/push locals
		
		locals-sz: 0
		if pos: find locals /local [		
			foreach [name type] next pos [
				repend stack [
					name locals-sz: locals-sz - max size-of? type/1 target/stack-width
				]
			]
			locals-sz: abs locals-sz
		]
		if verbose >= 3 [print ["args+locals stack:" mold to-block stack]]
		target/emit-prolog name locals locals-sz
		args-sz
	]
	
	leave: func [name [word!] locals [block!] locals-sz [integer!]][
		unless empty? exits [resolve-exit-points]
		target/emit-epilog name locals locals-sz
	]
	
	import-function: func [name [word!] reloc [block!]][
		repend symbols [name reduce ['import none reloc]]
	]
	
	add-native: func [name [word!]][
		repend symbols [name reduce ['native none make block! 5]]
	]
	
	reloc-native-calls: has [ptr][
		foreach [name spec] symbols [
			if all [
				spec/1 = 'native
				not empty? spec/3
			][
				ptr: spec/2
				foreach ref spec/3 [
					pointer/value: ptr - ref - target/ptr-size	;-- CALL NEAR disp size
					change at code-buf ref third pointer
				]
			]
		]
	]
	
	init: func [link? [logic!] job [object!]][
		if link? [
			clear code-buf
			clear data-buf
			clear symbols
		]
		clear stack
		target: do rejoin [%targets/ job/target %.r]
		target/compiler: compiler: system-dialect/compiler
		target/void-ptr: head insert/dup copy #{} null target/ptr-size
	]
]