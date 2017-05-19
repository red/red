REBOL [
	Title:   "Red/System code emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %emitter.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do-cache %system/targets/target-class.r

emitter: make-profilable context [
	code-buf:  make binary! 100'000
	data-buf:  make binary! 100'000
	symbols:   make hash! 1000			;-- [name [type address [relocs]] ...]
	stack: 	   make block! 40			;-- [name offset ...]
	exits:	   make block! 1			;-- [offset ...]	(funcs exits points)
	breaks:	   make block! 1			;-- [[offset ...] [...] ...] (break jump points)
	cont-next: make block! 1			;-- [[offset ...] [...] ...] (break jump points)
	cont-back: make block! 1			;-- [[offset ...] [...] ...] (break jump points)
	verbose:   0						;-- logs verbosity level
	
	target:	  none						;-- target code emitter object placeholder
	compiler: none						;-- just a short-cut
	libc-init?:		 none				;-- TRUE if currently processing libc init part

		
	pointer: make-struct [
		value [integer!]				;-- 32/64-bit, watch out for endianess!!
	] none
	
	datatypes: to-hash [
		;int8!		1	signed
		byte!		1	unsigned
		;int16!		2	signed
		;int32!		4	signed
		integer!	4	signed
		;int64!		8	signed
		;uint8!		1	unsigned
		;uint16!	2	unsigned
		;uint32!	4	unsigned
		;uint64!	8	unsigned
		float32!	4	signed
		float64!	8	signed
		float!		8	signed
		logic!		4	-
		pointer!	4	-				;-- 32-bit, 8 for 64-bit
		c-string!	4	-				;-- 32-bit, 8 for 64-bit
		struct!		4	-				;-- 32-bit, 8 for 64-bit ; struct! passed by reference
		function!	4	-				;-- 32-bit, 8 for 64-bit
	]
	
	datatype-ID: [
		logic!		1
		integer!	2
		byte!	    3
		float32!	4
		float!		5
		float64!	5
		c-string!   6
		byte-ptr!   7
		int-ptr!	8
		function!	9
		struct!		1000
	]
	
	chunks: context [
		queue: make block! 10
		
		empty: does [copy/deep [#{} []]]
		
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
				target/emit-branch/back? chunk/1 cond offset
			]
		]
	]
	
	set-signed-state: func [expr][
		unless all [block? expr 3 <= length? expr][exit]
		target/set-width expr/2							;-- set signed? (and width too as a side-effect)
	]

	merge: func [chunk [block!]][
		either empty? chunks/queue [
			append code-buf chunk/1
		][
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
	
	get-symbol-ref: func [name [word!] /local spec][
		case [
			find compiler/functions name [get-func-ref name]	;-- function case
			spec: select symbols name [spec]					;-- global variable case
			'else [
				compiler/throw-error ["attempt to get a reference on unknown symbol" name]
			]
		]
	]
	
	get-func-ref: func [name [word!] /local entry][
		entry: find/last symbols name
		if entry/2/1 = 'native [
			repend symbols [							;-- copy 'native entry to a 'global entry
				name reduce ['native-ref all [entry/2/2 entry/2/2 - 1] make block! 1]
			]
			entry: skip tail symbols -2 
		]		
		entry/2
	]
	
	local-offset?: func [var [word! tag!] /local pos][
		all [
			pos: select/skip stack var 2
			pos/1
		]
	]

	logic-to-integer: func [op [word! block!] /with chunk [block!] /local offset body][
		if all [with block? op][op: op/1]
		
		if find target/comparison-op op [
			set [offset body] chunks/make-boolean
			branch/over/on/adjust body reduce [op] offset/1
			either with [chunks/join chunk body][merge body]
		]
	]
	
	add-symbol: func [
		name [word! tag!] ptr [integer!] /with refs [block! word! none!] /local spec
	][
		spec: reduce [name reduce ['global ptr make block! 1 any [refs '-]]]
		append symbols new-line spec yes
		spec
	]

	store-global: func [value type [word!] spec [block! word! none!] /local size ptr by-val?][
		if any [find [logic! function!] type logic? value][
			type: 'integer!
			if logic? value [value: to integer! value]	;-- TRUE => 1, FALSE => 0
		]
		if all [value = <last> not find [float! float64!] type][
			type: 'integer!								; @@ not accurate for float32!
			value: 0
		]
		if find compiler/enumerations type [type: 'integer!]
		
		size: size-of? type
		ptr: tail data-buf
		
	
		switch/default type [
			integer! [
				case [
					decimal? value [value: to integer! value]
					not integer? value [value: 0]
				]
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
				either integer? value [
					value: to char! value and 255		;-- truncate if required
				][
					unless char? value [value: #"^@"]
				]
				append ptr value
			]
			float! float64! [
				pad-data-buf 8							;-- align 64-bit floats on 64-bit
				ptr: tail data-buf
				unless decimal? value [value: 0.0]
				append ptr IEEE-754/to-binary64/rev value	;-- stored in little-endian
			]
			float32! [	
				pad-data-buf target/default-align			
				ptr: tail data-buf
				value: compiler/unbox value
				unless decimal? value [value: 0.0]
				append ptr IEEE-754/to-binary32/rev value	;-- stored in little-endian
			]
			c-string! [
				either string? value [
					if all [							;-- heuristic to detect wide strings (UTF-16LE)
						value/2 = null
						null = last value
					][
						pad-data-buf 2					;-- ensures it is aligned on 16-bit
						ptr: tail data-buf
					]
					repend ptr [value null]
				][
					pad-data-buf target/ptr-size		;-- pointer alignment can be <> of integer
					ptr: tail data-buf	
					store-global value 'integer! none
				]
			]
			pointer! [
				pad-data-buf target/ptr-size			;-- pointer alignment can be <> of integer
				ptr: tail data-buf	
				type: either all [
					paren? value
					value/1 = 'pointer!
					find [float! float64!] value/2/1 
				]['float!]['integer!]
				store-global value type none
			]
			struct! [
				ptr: tail data-buf
				foreach [var type] spec [
					by-val?: 'value = last type
					if spec: compiler/find-aliased type/1 [type: spec]
					either all [by-val? type/1 = 'struct!][
						store-global value type/1 type/2
					][
						type: either find [struct! c-string!] type/1 ['pointer!][type/1]
						store-global value type spec
					]
				]
				pad-data-buf target/struct-align-size
			]
			array! [
				type: first compiler/get-type value/1
				store-global length? value 'integer! none	;-- store array size first
				if any [type = 'float! type = 'float64!] [pad-data-buf 8]
				ptr: tail data-buf							;-- ensure array pointer skips size info
				foreach item value [store-global item type none]
			]
			binary! [
				pad-data-buf 8								;-- forces 64-bit alignment
				ptr: tail data-buf
				append ptr value
				pad-data-buf target/ptr-size
			]
		][
			compiler/throw-error ["store-global unexpected type:" type]
		]
		(index? ptr) - 1								;-- offset of stored value
	]
		
	store-value: func [
		name [word! none!]
		value
		type [block!]
		/ref ref-ptr
		/local ptr new
	][
		if new: compiler/find-aliased type/1 [
			type: new
		]
		ptr: store-global value type/1 all [			;-- allocate value slot
			type/1 = 'struct!
			type/2
		]
		add-symbol/with any [name <data>] ptr ref-ptr	;-- add variable/value to globals table
	]
	
	store: func [
		name [word!] value type [block!]
		/local new new-global? ptr refs n-spec spec literal? saved slots
	][
		if new: compiler/find-aliased type/1 [
			type: new
		]
		new-global?: not any [							;-- TRUE if unknown global symbol
			local-offset? name							;-- local variable
			find symbols name 							;-- known symbol
		]
		either all [
			literal?: compiler/literal? value			;-- literal values only
			compiler/any-pointer? type					;-- complex types only
		][
			if new-global? [
				ptr: store-global value 'pointer! none	;-- allocate separate variable slot
				n-spec: add-symbol name ptr				;-- add variable to globals table
				refs: reduce [ptr + 1]					;-- reference value from variable slot
				saved: name
				name: none								;-- anonymous data storing
			]
			if all [paren? value not word? value/1][
				type: [array!]
			]
			if any [not new-global?	string? value paren? value][
				if string? value [type: [c-string!]]	;-- force c-string! in case of type casting
				spec: store-value/ref name value type refs  ;-- store it with hardcoded pointer address
			]
			if all [spec compiler/job/PIC? not libc-init?][
				target/emit-load-literal-ptr spec/2
				if new-global? [
					target/emit-store saved value n-spec ;-- store it in pointer variable
				]
			]
			if n-spec [spec: n-spec]
		][
			if new-global? [spec: store-value name value type] ;-- store new variable with value
		]
		if all [name not all [new-global? literal?]][	;-- emit dynamic loading code when required
			either all [
				value = <last>
				'value = last type: compiler/last-type
				any [
					'struct! = type/1
					'struct! = first type: compiler/resolve-aliased type
				]
			][
				slots: struct-slots?/direct type/2
				target/emit-store/by-value name value type slots ;-- struct-by-value case
			][
				target/emit-store name value spec
			]
		]
	]
		
	member-offset?: func [spec [block!] name [word! none!] /local offset over][
		offset: 0
		foreach [var type] spec [
			all [
				find [integer! c-string! pointer! struct! logic!] type/1
				not zero? over: offset // target/struct-align-size 
				offset: offset + target/struct-align-size - over ;-- properly account for alignment
			]
			if var = name [return offset]
			offset: offset + size-of? type
		]
		unless zero? over: offset // target/struct-align-size [
			offset: offset + target/struct-align-size - over	 ;-- properly account for alignment
		]
		offset
	]
	
	system-path?: func [path [path! set-path!] value /local set?][
		either path/1 = 'system [
			set?: set-path? path
			switch/default path/2 [
				stack [
					if all [2 = length? path set?][
						compiler/backtrack path
						compiler/throw-error "cannot modify system/stack"
					]
					if 3 < length? path [
						compiler/backtrack path
						compiler/throw-error "invalid system/stack access"
					]
					switch path/3 [
						top [
							either set? [
								target/emit-set-stack value
							][
								target/emit-get-stack
							]
						]
						frame [
							either set? [
								target/emit-set-stack/frame value
							][
								target/emit-get-stack/frame
							]
						]
						align [
							if set? [
								compiler/backtrack path
								compiler/throw-error "cannot modify system/stack/align"
							]
							target/emit-stack-align
						]
					]
				]
				pc [
					if set? [
						compiler/backtrack path
						compiler/throw-error "cannot modify system/pc"
					]
					target/emit-get-pc
				]
				cpu [
					switch/default path/3 [
						overflow? [target/emit-get-overflow]
					][target/emit-access-register path/3 set? value]
				]
				fpu [
					if 2 = length? path [
						compiler/backtrack path
						compiler/throw-error "invalid system/fpu access"
					]
					switch path/3 [
						type [
							either set? [
								compiler/backtrack path
								compiler/throw-error "cannot modify system/fpu/type"
							][
								target/emit-fpu-get/type
							]
						]
						option [
							if 3 = length? path [
								compiler/backtrack path
								compiler/throw-error "invalid system/fpu/option access"
							]
							either set? [
								target/emit-fpu-set/options value path/4 
							][
								target/emit-fpu-get/options path/4
							]
						]
						mask [
							if 3 = length? path [
								compiler/backtrack path
								compiler/throw-error "invalid system/fpu/mask access"
							]
							either set? [
								target/emit-fpu-set/masks value path/4
							][
								target/emit-fpu-get/masks path/4
							]
						]
						control-word [
							either set? [
								target/emit-fpu-set/cword value
							][
								target/emit-fpu-get/cword
							]
						]
						update [
							either set? [
								compiler/backtrack path
								compiler/throw-error "system/fpu/update is an action"
							][
								target/emit-fpu-update
							]
						]
						init [
							either set? [
								compiler/backtrack path
								compiler/throw-error "system/fpu/init is an action"
							][
								target/emit-fpu-init
							]
						]
					]
				]
				; add here implicit system getters/setters
			][return false]
			true
		][
			false
		]
	]
	
	resolve-path-head: func [path [path! set-path!] parent [block! none!]][
		second either head? path [
			compiler/resolve-type path/1
		][
			compiler/resolve-type/with path/1 parent
		]
	]
	
	access-path: func [path [path! set-path!] value /with parent [block!] /local type][
		if all [not with system-path? path value][exit]

		either 2 = length? path [
			type: first either parent [
				compiler/resolve-type/with path/1 parent
			][
				compiler/resolve-type path/1
			]
			
			if all [type = 'struct! parent][
				parent: resolve-path-head path parent
			]
			either set-path? path [
				target/emit-store-path path type value parent
			][
				target/emit-load-path path type parent
			]
		][
			if head? path [
				either all [
					compiler/locals
					type: select compiler/locals to word! path/1
					'value = last type
				][
					target/emit-load path/1
				][
					target/emit-init-path path/1
				]
			]
			parent: resolve-path-head path parent
			target/emit-access-path path parent
			access-path/with next path value parent
		]
	]

	size-of?: func [type [word! block!] /local t][
		if all [
			block? type
			'value = last type
			any [
				'struct! = type/1
				'struct! = first t: compiler/find-aliased type/1
			]
		][
			if t [type: t]
			return member-offset? type/2 none
		]
		if block? type [type: type/1]
		
		any [
			select datatypes type						;-- search in base types
			all [										;-- search if it's enumeration
				find compiler/enumerations type
				select datatypes 'integer!
			]
			all [										;-- search in user-aliased types
				type: compiler/find-aliased type
				select datatypes type/1
			]
		]
	]
	
	signed?: func [type [word! block!]][
		if block? type [type: type/1]
		'signed = third any [find datatypes type [- - -]] ;-- force unsigned result for aliased types
	]
	
	get-size: func [type [block! word!] value][
		either word? type [
			datatypes/:type
		][
			either 'array! = first head type [
				second head type
			][
				switch/default type/1 [
					c-string! [reduce ['+ 1 reduce ['length? value]]]
					struct!   [member-offset? type/2 none]
				][
					select datatypes type/1
				]
			]
		]
	]
	
	struct-slots?: func [spec [block!] /direct /check][
		if check [
			unless all [
				spec: select spec compiler/return-def
				'value = last spec
			][
				return none
			]
		]
		unless direct [
			if 'struct! <> spec/1 [
				spec: compiler/find-aliased spec/1
				if 'struct! <> spec/1 [return none]
			]
			spec: spec/2
		]
		round/ceiling (member-offset? spec none) / target/stack-width
	]
	
	arguments-size?: func [locals [block!] /push /local size name type width offset struct-ptr?][
		size: pick [4 0] to logic! struct-ptr?: all [
			ret: select locals compiler/return-def
			'value = last ret
			2 < struct-slots? ret
		]
		if push [
			clear stack
			if struct-ptr? [repend stack [<ret-ptr> target/args-offset]]
		]
		width: target/stack-width
		offset: target/args-offset
		
		parse locals [opt block! any [set name word! set type block! (
			if push [repend stack [name size + offset]]
			size: size + max size-of? type width
		)]]
		if push [repend stack [<top> size + target/args-offset]] ;-- frame's top ptr
		size
	]
	
	push-struct: func [expr spec [block!]][
		target/emit-load expr
		target/emit-push-struct struct-slots?/direct spec/2
	]
	
	init-loop-jumps: does [
		append/only breaks	  make block! 1
		append/only cont-next make block! 1
		append/only cont-back make block! 1
	]
	
	resolve-loop-jumps: func [chunk [block!] type [word!] /local list end len buffer][
		list: emitter/:type
		buffer: chunk/1
		len: (last chunk) - 1
		
		either type = 'cont-back [
			foreach ptr last list [target/patch-jump-back buffer ptr - len]
		][
			end: index? tail buffer
			foreach ptr last list [target/patch-jump-point buffer ptr - len end]
		]
		remove back tail list
	]
	
	resolve-exit-points: has [end][
		end: tail-ptr
		foreach ptr exits [target/patch-jump-point code-buf ptr end]
	]
	
	calc-locals-offsets: func [spec [block!] /local total var sz extra][
		total: negate extra: target/locals-offset
		while [not tail? spec: next spec][
			var: spec/1
			either block? spec/2 [
				sz: max size-of? spec/2 target/stack-width	;-- type declared
				spec: next spec
			][
				sz: target/stack-slot-max				;-- type to be inferred
			]
			repend stack [var (total: total - sz)] 		;-- store stack offsets
		]
		(abs total) - extra
	]
	
	enter: func [name [word!] locals [block!] /local ret args-sz locals-sz pos][
		symbols/:name/2: tail-ptr						;-- store function's entry point
		all [
			spec: find/last symbols name
			spec/2/1 = 'native-ref						;-- function's address references
			spec/2/2: tail-ptr - 1						;-- store zero-based entry point here too
		]
		clear exits										;-- reset exit-points list

		;-- Implements Red/System calling convention -- (STDCALL)
		args-sz: arguments-size?/push locals
		
		locals-sz: either pos: find locals /local [calc-locals-offsets pos][0]
		if verbose >= 2 [print ["args+locals stack:" mold stack]]
		
		target/emit-prolog name locals locals-sz
		reduce [args-sz locals-sz]
	]
	
	leave: func [
		name [word!] locals [block!] args-sz [integer!] locals-sz [integer!] rspec [block! none!]
		/local slots
	][
		if rspec [
			if verbose >= 2 [print ["returns struct-by-value:" mold rspec]]
			slots: struct-slots?/direct rspec
		]
		unless empty? exits [resolve-exit-points]
		target/emit-epilog/with name locals args-sz locals-sz slots
	]
	
	import: func [name [word!] reloc [block!] /var /local type][
		type: pick [import-var import] to logic! var
		repend symbols [name reduce [type none reloc]]
	]
	
	add-native: func [name [word!] /local spec][
		repend symbols [name spec: reduce ['native none make block! 5]]
		spec
	]
	
	reloc-native-calls: has [ptr][
		foreach [name spec] symbols [
			if all [
				spec/1 = 'native
				not empty? spec/3
			][
				ptr: spec/2
				foreach ref spec/3 [
					target/patch-call code-buf ref ptr	;-- target-specific func call
				]
				clear spec/3
			]
		]
	]
	
	start-prolog: has [args][							;-- libc init prolog
		args: pick [6 7] system-dialect/job/OS = 'Syllable
		append compiler/functions compose/deep [		;-- create a fake function to
			***_start [(args) native cdecl [] callback]	;-- let the linker write the entry point
		]
		append symbols [
			***_start [native 0 []]
		]
	]
	
	start-epilog: does [								;-- libc init epilog
		poke second find/last symbols '***_start 2 tail-ptr - 1	;-- save the "main" entry point
		target/emit-prolog '***_start [] 0
	]
	
	init: func [link? [logic!] job [object!] /local path][
		if link? [
			clear code-buf
			clear data-buf
			clear symbols
		]
		clear stack
		path: pick [%system/targets/ %targets/] encap?
		target: do-cache rejoin [path job/target %.r]
		target/compiler: compiler: system-dialect/compiler
		target/PIC?: job/PIC?
		target/void-ptr: head insert/dup copy #{} null target/ptr-size
		int-to-bin/little-endian?: target/little-endian?
	]
]
