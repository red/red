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
	target:	  none						;-- target code emitter object placeholder
	compiler: none						;-- just a short-cut
	verbose:  0							;-- logs verbosity level
	
	OS-calling-type: 'stdcall			;-- Windows (TBD: refactor this!)
	
	pointer: make struct! [
		value [integer!]				;-- 32/64-bit, watch out for endianess!!
	] none
	
	datatypes: to-hash [
		int8!		1	signed
		int16!		2	signed
		int32!		4	signed
		integer!	4	signed
		int64!		8	signed
		uint8!		1	unsigned
		uint16!		2	unsigned
		uint32!		4	unsigned
		uint64!		8	unsigned
		hexa!		4	unsigned
		pointer!	4	-				;-- 32-bit, 8 for 64-bit
		binary!		4	-				;-- 32-bit, 8 for 64-bit
		string!		4	-				;-- 32-bit, 8 for 64-bit
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
			foreach ptr b/2 [ptr/1: ptr/1 + bytes]				;-- adjust relocs
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
			append code-buf chunk/1							;-- replace obsolete buffer														
			append second last chunks/queue chunk/2		
		]
	]
	
	tail-ptr: does [index? tail code-buf] 	;-- one-based addressing
		
	pad-global-struct: has [sz][
		unless empty? data-buf [			;-- don't pad at beginning, already aligned
			sz: target/struct-align-size
			insert/dup tail data-buf null sz - ((length? data-buf) // sz)
		]
	]
	
	make-noname: has [cnt][
		cnt: [0]
		to-word join "no-name-" cnt/1: cnt/1 + 1
	]
	
	get-symbol-spec: func [name][
		any [
			all [compiler/locals select compiler/locals name]
			select compiler/globals name
		]
	]

	store-global: func [value size /local ptr][
		ptr: tail data-buf
		case [
			number? value [
				value: debase/base to-hex value 16
				either target/little-endian? [
					value: tail value
					loop size [append ptr to char! (first value: skip value -1)]
				][
					append ptr skip tail value negate size		;-- truncate if required
				]
			]
			any [string? value binary? value][				
				repend ptr [value null]
			]
			'else [
				insert/dup ptr null size
			]
		]
		ptr
	]
	
	set-global: func [spec [block!] value /local type base][
		either 'struct! = type: spec/2/1 [
			pad-global-struct
			base: tail data-buf
			foreach [var type] spec/2/2 [
				store-global 0 size-of? type/1
			]
			;TBD: pad end for next values ??
		][
			base: tail data-buf
			store-global value select datatypes type
		]
		spec: reduce [spec/1 reduce ['global (index? base) - 1 make block! 5]] ;-- zero-based
		append symbols new-line spec yes
		spec
	]
	
	member-offset?: func [spec [block!] name [word!] /local offset][
		offset: 0
		foreach [var type] spec [
			if var = name [break]
			offset: offset + size-of? type/1
		]
		offset
	]
	
	access-path: func [path [path! set-path!] /store value /local emit type idx offset][	
		emit: get in target 'emit-path-access
		
		while [not tail? path][
			type: either head? path [
				compiler/resolve-type path/1
			][
				compiler/resolve-type/with path/1 parent-type
			]
			idx: pick [2 1] head? path
			switch/default type/1 [
				pointer! [
					if path/:idx <> 'value [
						;TBD throw error "invalid pointer path"
					]
					case [
						all [value head? path][emit/head/store path/1 value]
						value 				  [emit/store value]
						head? path 			  [emit/head path/1]
						'else 				  [emit]
					]
				]
				struct! [
					unless offset: member-offset? type/2 path/:idx [
						;TBD throw error "invalid struct member"
					]
					case [
						all [value head? path][emit/head/store/struct path/1 value offset]
						value 				  [emit/store/struct value offset]
						head? path 			  [emit/head/struct path/1 offset]
						'else 				  [emit/struct offset]
					]
				]
			][
				;TBD throw error
			]
			parent-type: type
			path: either head? path [skip path 2][next path]
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
	
	arguments-size?: func [locals /push /local pos ret size][
		pos: find locals /local
		ret: to-set-word 'return
		if push [clear stack]
		size: 0
		foreach [name type] any [all [pos copy/part locals pos] copy locals][
			if name <> ret [
				if push [repend stack [name size + 8]]	;-- account for esp + ebp storage
				size: size + size-of? type/1			;TBD: make it target-independent
			]
		]
		size
	]
	
	enter: func [name [word!] locals [block!] /local ret args-sz locals-sz pos][
		symbols/:name/2: index? tail code-buf			;-- store function's entry point
		
		;-- Implements Red/System calling convention -- (STDCALL without reversing)		
		args-sz: arguments-size?/push locals
		
		locals-sz: 0
		if pos: find locals /local [		
			foreach [name type] next pos [
				repend stack [
					name locals-sz: locals-sz - size-of? type/1
				]
			]
			locals-sz: abs locals-sz
		]
		if verbose >= 3 [print ["args+locals stack:" mold to-block stack]]
		target/emit-prolog name locals locals-sz
		args-sz
	]
	
	leave: func [name [word!] locals [block!] locals-sz [integer!]][
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
	
	init: func [link? job][
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