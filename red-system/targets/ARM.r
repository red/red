REBOL [
	Title:		"Red/System ARM code emitter"
	Author:		"Andreas Bolka, Nenad Rakocevic"
	File:		%ARM.r
	Rights:		"Copyright (C) 2011 Andreas Bolka, Nenad Rakocevic. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; AAPCS (for external calls & callbacks only)
;;
;;	15 = pc
;;	14 = lr
;;	13 = sp									(callee saved: fun must preserve)
;;	12 = "ip" (scratch)
;;	4-11 = variable register 1-8			(callee saved: fun must preserve)
;;		11 = "fp"
;;	2-3 = argument 3-4
;;  0-1	= argument 1-2 / result
;;
;;	stack (sp) at function call must be 8-byte (dword) aligned!
;;
;;	c widths: char = i8, short = i16, int & long = i32, long long = i64
;;	alignment: == size (so char==1, short==2, int/long==4, ptr==4)
;;	structs aligned at max aligned, padded to multiple of alignment

make target-class [
	target:				'ARM
	little-endian?:		yes
	struct-align-size:	4
	ptr-size:			4
	default-align:		4
	stack-width:		4
	branch-offset-size:	4							;-- size of branch instruction
	
	byte-flag: 			#{00400000}					;-- trigger byte access in opcode
	
	pools: context [								;-- literals pools management
		values:		  make block! 2000				;-- [value instruction-pos sym-spec ...]
		entry-points: make block! 100				;-- insertion points candidates for pools
		;jmp-points:  make block! 100				;-- relative jumps positions
		pools:		  make block! 1					;-- [pool-pos [value-ref ...] inline? ...]
		
		;-- Collect a literal value to be stored in a pool
		collect: func [value [integer!] /spec s [word! get-word! block!] /local pos][
			insert pos: tail values reduce [value emitter/tail-ptr s]
			pos
		]
		
		;-- Collect a possible position in code for a literals pool
		mark-entry-point: does [
			append entry-points emitter/tail-ptr
		]
		
		get-pool: does [skip tail pools -3]
		
		make-pool: does [
			repend pools [entry-points/1 make block! 16 no]	;-- create a new pool entry
			entry-points: next entry-points			;-- move to next possible position
			get-pool								;-- get a reference on the last pool structure
		]
		
		;-- Update code addresses after a pool insertion
		update-entry-points: func [pool-idx [integer!] offset [integer!]][
			ep: entry-points
			forall ep [if ep/1 > pool-idx [ep/1: ep/1 + offset]]
			;TBD: update all impacted function entry-points
		]
		
		populate-pools: has [index pos offset pool][
			until [
				index: values/2
				if empty? pools [make-pool]

				pool: get-pool
				pos: pool/1 + (4 * length? pool/2)	;-- pos: offset of value entry in the pool buffer

				either positive? offset: pos - index [	;-- test if pool is before or after caller
					if 4092 <= offset [
						compiler/throw-error "[ARM emitter] pool too far!"
						;pool/3: yes				;-- set "inlined" flag
						;TBD: handle pool in the middle of code case
					]
				][
					if 4092 <= abs offset [			;-- if pool too far behind,
						pool: make-pool				;-- make a new pool at next possible position @@ > 4092 case
						pos: pool/1 + (4 * length? pool/2)
					]
				]
				
				append/only pool/2 values			;-- insert literal value in the pool
				tail? values: skip values 3
			]
			values: head values
		]
		
		commit-pools: has [buffer value ins-idx spec entry-pos offset code][
			buffer: make binary! 400				;-- reserve pool buffer for 100 values
			
			foreach [pool-idx value-refs inline?] pools [
				clear buffer
				until [			
					set [value ins-idx spec] value-refs/1
					
					append buffer reverse debase/base to-hex value 16
					
					entry-pos: 4 * (-1 + index? value-refs)			;-- offset of value entry in the pool
					offset: pool-idx + entry-pos - (ins-idx + 8)	;-- relative jump offset to the entry
					offset: reverse #{000003FF} and debase/base to-hex offset 16	;-- create 12-bit offset
					
					code: at emitter/code-buf ins-idx
					change code offset or copy/part code 4	;-- add relative jump offset to instruction
					
					if spec [
						spec: switch type?/word spec [
							get-word! [emitter/get-func-ref]
							word!	  [emitter/symbols/:spec]
							block!	  [spec]
						]
						append spec/3 pool-idx + entry-pos	;-- add symbol back-reference for linker
					]
					
					tail? value-refs: next value-refs
				]
				insert at emitter/code-buf pool-idx buffer	;-- insert pool in code buffer
				update-entry-points pool-idx length? buffer	;-- update code entry points accordingly
			]
		]
		
		process: does [	
			populate-pools
			commit-pools
			
			clear entry-points: head entry-points
			clear values
			clear pools
		]
	]
	
	on-finalize: does [pools/process]				;-- trigger pools processing on end of code generation
	
	on-global-epilog: does [pools/mark-entry-point]	;-- add end of global code section as pool entry-point
	
	;-- Convert a 12-bit integer offset to a 32-bit hexa
	to-12-bit: func [offset [integer!]][
		#{000003FF} and debase/base to-hex offset 16
	]

	instruction-buffer: make binary! 4

	emit-i32: func [bin [binary! char! block!]] [
		;; To allow more natural emission of 32-bit instructions, "emit-i32"
		;; collects data in big-endian and emits it as 32-bit chunks in the
		;; target's native endianness.
		insert tail instruction-buffer bin
		if 4 <= length? instruction-buffer [
			emit to-bin32 to integer! take/part instruction-buffer 4
		]
	]
	
	;-- Polymorphic code generation
	emit-poly: func [opcode [binary!] /with offset [integer!]][
		if with 	 [opcode: opcode or to-12-bit offset]
		if width = 1 [opcode: opcode or byte-flag]	;-- 16-bit access not supported
		emit-i32 opcode
	]
	
	rotate-left: func [value [integer!] bits [integer!]][
		either bits < 4 [
			switch bits [
				0 [value]
				1 [(shift/left value and 255 2) or shift/logical value 30]
				2 [(shift/left value and 16 4) or shift/logical value 28]
				3 [(shift/left value and 3 6) or shift/logical value 26]
			]
		][
			shift/logical value 32 - (bits * 2)		;-- * 2 => rotation on even positions
		]
	]
	
	ror-position?: func [value [integer!] /local c][
		;-- Test if an integer can be represented using the 8-bit + 4-bit-ROR format
		c: 0
		foreach mask [
			255  									;-- 2#{00000000000000000000000011111111}
			-1073741761								;-- 2#{11000000000000000000000000111111}
			-268435441								;-- 2#{11110000000000000000000000001111}
			-67108861								;-- 2#{11111100000000000000000000000011}
			-16777216								;-- 2#{11111111000000000000000000000000}
			1069547520								;-- 2#{00111111110000000000000000000000}
			267386880								;-- 2#{00001111111100000000000000000000}
			66846720								;-- 2#{00000011111111000000000000000000}
			16711680								;-- 2#{00000000111111110000000000000000}
			4177920									;-- 2#{00000000001111111100000000000000}
			1044480									;-- 2#{00000000000011111111000000000000}
			261120									;-- 2#{00000000000000111111110000000000}
			65280									;-- 2#{00000000000000001111111100000000}
			16320									;-- 2#{00000000000000000011111111000000}
			4080									;-- 2#{00000000000000000000111111110000}
			1020									;-- 2#{00000000000000000000001111111100}
		][
			if value and mask = value [return c]
			c: c + 1
		]
		none
	]

	emit-load-imm32: func [value [integer!] /reg n [integer!] /local neg? bits opcode][
		if neg?: negative? value [value: complement value]

		either bits: ror-position? value [	
			opcode: rejoin [						;-- MOV r0, #imm8, bits		; v = imm8 (ROR bits)x2
				#{e3} 
				pick [#{e0} #{a0}] neg?				;-- emit MVN instead, if required
				to char! shift/left bits 8
				to char! rotate-left value bits
			]
		
		][
			opcode: #{e59f0000}						;-- LDR r0|rN, [pc, #offset]
			pools/collect value
		]
		if reg [opcode: opcode or debase/base to-hex shift/left n 12 16]
		emit-i32 opcode
	]
	
	emit-variable: func [
		name [word! object!] gcode [binary! block! none!] lcode [binary! block!]
		/byte										;-- force byte-size access
		/alt										;-- use alternative register (r1)
		/local offset spec load-rel
	][
		if object? name [name: compiler/unbox name]

		either offset: select emitter/stack name [	;-- local variable case
			offset: to-12-bit offset
			if byte [offset: offset or byte-flag]
			emit-i32 lcode or offset
		][											;-- global variable case
			spec: emitter/symbols/:name
			pools/collect/spec 0 name
			
			load-rel: #{e59f0000}
			if byte [load-rel: load-rel or byte-flag]
			
			if any [alt not all [gcode zero? gcode/3 and 16]][
				load-rel: load-rel or #{00001000}	;-- use r1 instead of r0
			]
			emit-i32 load-rel						;-- LDR[B] r0|r1, [pc, #offset]
			if gcode [emit-i32 gcode]
		]
	]
	
	emit-variable-poly: func [						;-- polymorphic variable access generation
		name [word! object!]
		global [binary!]							;-- opcodes for global variables
		local [binary! block!]						;-- opcodes for local variables
	][
		with-width-of name [
			switch width [
				1 [emit-variable/byte name global local]	;-- 8-bit
				;2 []										;-- 16-bit (unsupported)
				4 [emit-variable name global local]			;-- 32-bit
			]
		]
	]
	
	emit-load-literal: func [type [block! none!] value /local spec][	
		unless type [type: compiler/get-type value]
		spec: emitter/store-value none value type
		pools/collect/spec 0 spec/2
		emit-i32 #{e59f0000}						;-- LDR r0, [pc, #offset]	; r0: value
	]
	
	emit-get-pc: does [
		emit-i32 #{e1a0f000}						;-- MOV r0, pc
	]

	emit-set-stack: func [value /frame][
		if verbose >= 3 [print [">>>emitting SET-STACK" mold value]]
		emit-load value
		either frame [
			emit-i32 #{e1ab0000}					;-- MOV fp, r0
		][
			emit-i32 #{e1ad0000}					;-- MOV sp, r0
		]
	]

	emit-get-stack: func [/frame][
		if verbose >= 3 [print ">>>emitting GET-STACK"]
		either frame [
			emit-i32 #{e1a0b000}					;-- MOV eax, fp
		][
			emit-i32 #{e1a0d000}					;-- MOV eax, sp
		]
	]

	emit-pop: does [
		if verbose >= 3 [print ">>>emitting POP"]
		emit-i32 #{e8bd0000}						;-- POP {r0}
	]
	
	emit-not: func [value [word! char! tag! integer! logic! path! string! object!] /local opcodes type boxed][
		if verbose >= 3 [print [">>>emitting NOT" mold value]]

		if object? value [boxed: value]
		value: compiler/unbox value
		if block? value [value: <last>]

		opcodes: [
			logic!	 [emit-i32 #{e2200001}]			;-- EOR r0, #1		; invert 0<=>1
			byte!	 [emit-i32 #{e1e00000}]			;-- MVN r0, r0
			integer! [emit-i32 #{e1e00000}]			;-- MVN r0, r0
		]
		switch type?/word value [
			logic! [
				emit-load not value
			]
			char! [
				emit-load value
				do opcodes/byte!
			]
			integer! [
				emit-load value
				do opcodes/integer!
			]
			word! [
				emit-load value
				if boxed [emit-casting boxed no]
				type: first compiler/resolve-aliased compiler/get-variable-spec value
				if find [pointer! c-string! struct!] type [ ;-- type casting trap
					type: 'logic!
				]
				switch type opcodes
			]
			tag! [
				if boxed [emit-casting boxed no]
				switch compiler/last-type/1 opcodes
			]
			string! [								;-- type casting trap
				emit-load value
				if boxed [emit-casting boxed no]
				do opcodes/logic!
			]
			path! [
				emitter/access-path value none
				either boxed [
					emit-casting boxed no
					switch boxed/type/1 opcodes 
				][
					do opcodes/integer!
				]
			]
		]
	]
	
	emit-boolean-switch: does [
		emit-i32 #{e3a00000}						;--		  MOV r0, #0	; (FALSE)
		emit-i32 #{ea000001}						;--		  B _exit
		emit-i32 #{e3a00001}						;--		  MOV r0, #1	; (TRUE)
													;-- _exit:
		reduce [4 24]								;-- [offset-TRUE offset-FALSE]
	]

	emit-load: func [
		value [char! logic! integer! word! string! path! paren! get-word! object!]
		/alt
	][
		if verbose >= 3 [print [">>>loading" mold value]]

		switch type?/word value [
			char! [
				emit-load-imm32 to integer! value
			]
			logic! [
				emit-load-imm32 to integer! value
			]
			integer! [
				emit-load-imm32 value
			]
			word! [
				either alt [
					emit-variable-poly value
						#{e5911000}					;-- LDR r1, [r1]		; global
						#{e51b1000}					;-- LDR r1, [fp, #n]	; local
				][
					emit-variable-poly value
						#{e5900000} 				;-- LDR r0, [r0]		; global
						#{e51b0000}					;-- LDR r0, [fp, #n]	; local
				]
			]
			get-word! [
				pools/collect/spec 0 value
				emit-i32 #{e59f0000}				;-- LDR r0, [pc, #offset]	; symbol address
			]
			string! [
				emit-load-literal [c-string!] value
			]
			path! [
				emitter/access-path value none
			]
			paren! [
				emit-load-literal none value
			]
			object! [
				unless any [block? value/data value/data = <last>][
					either alt [emit-load/alt value/data][emit-load value/data]
				]
			]
		]
	]
	
	emit-store: func [
		name [word!] value [char! logic! integer! word! string! paren! tag! get-word!] spec [block! none!]
		/local load-address store-word
	][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]			;-- force word! code path in switch block
		if logic? value [value: to integer! value]	;-- TRUE -> 1, FALSE -> 0

		load-address: [
			emit-variable/alt name
				none								;-- LDR r1, [pc, #name]	; global
				#{e51b1000}							;-- LDR r1, [fp, #n]	; local
		]
		store-word: [
			emit-i32 #{e5010000}					;-- STR r0, [r1]
		]

		switch type?/word value [
			char! [
				do load-address						;-- r1: name
				emit-i32 #{e5410000}				;-- STRB r0, [r1]
			]
			integer! [
				do load-address						;-- r1: name
				do store-word
			]
			word! [
				set-width name
				do load-address						;-- r1: name
				do store-word
			]
			get-word! [
				pools/collect/spec 0 value
				emit-i32 #{e59f0000}				;-- LDR r0, [pc, #offset]
				do load-address						;-- r1: name
				do store-word
			]
			string! paren! [
				;pools/collect/spec 0 spec/2
				;emit-i32 #{e59f0000}				;-- LDR r0, [pc, #offset]
				do load-address						;-- r1: name
				do store-word
			]
		]
	]

	emit-access-path: func [
		path [path! set-path!] spec [block! none!] /short /local offset type saved
	][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			spec: second compiler/resolve-type path/1
			emit-load path/1
		]
		if short [return spec]

		saved: width
		type: first compiler/resolve-type/with path/2 spec
		set-width/type type							;-- adjust operations width to member value size

		offset: emitter/member-offset? spec path/2
		emit-poly/with #{e5900000} offset			;-- LDR[B] r0, [r0, #offset]
		width: saved
	]
	
	emit-load-index: func [idx [word!]][
		emit-variable idx
			#{e5903000}								;-- LDR r3, [r0]		; global
			#{e51b3000}								;-- LDR r3, [fp, #n]	; local
		emit-i32 #{e24dd008}						;-- SUB r3, r3, #1		; one-based index
	]

	emit-c-string-path: func [path [path! set-path!] parent [block! none!] /local opcodes idx][
		either parent [
			emit-i32 #{e1a02000}					;-- MOV r2, r0			; nested access
		][
			emit-variable path/1
				#{e5902000}							;-- LDR r2, [r0]		; global
				#{e51b2000}							;-- LDR r2, [fp, #n]	; local
		]
		opcodes: pick [[							;-- store path opcodes --
			#{e5421000}								;-- STRB r1, [r2]		; first
			#{e7c21003}								;-- STRB r1, [r2, r3] 	; nth | variable index
		][											;-- load path opcodes --
			#{e5520000}								;-- LDRB r0, [r2]		; first
			#{e7d20003}								;-- LDRB r0, [r2, r3]	; nth | variable index
		]] set-path? path

		either integer? idx: path/2 [
			either zero? idx: idx - 1 [				;-- indexes are one-based
				emit-i32 opcodes/1
			][
				emit-load-imm32/reg idx 3			;-- LDR r3, #idx
				emit-i32 opcodes/2
			]
		][
			emit-load-index idx
			emit opcodes/2
		]
	]
	
	emit-pointer-path: func [
		path [path! set-path!] parent [block! none!] /local opcodes idx type scale
	][
		opcodes: pick [[							;-- store path opcodes --
			#{e5401000}								;-- STR[B] r1, [r0]
			#{e5401000}								;-- STR[B] r1, [r0, r3]
		][											;-- load path opcodes --
			#{e5500000}								;-- LDR[B] r0, [r0]
			#{e7d00003}								;-- LDR[B] r0, [r0, r3]
		]] set-path? path

		type: either parent [
			compiler/resolve-type/with path/1 parent
		][
			emit-init-path path/1
			type: compiler/resolve-type path/1
		]
		set-width/type type/2/1						;-- adjust operations width to pointed value size
		idx: either path/2 = 'value [1][path/2]
		scale: emitter/size-of? type/2/1

		either integer? idx [
			either zero? idx: idx - 1 [				;-- indexes are one-based
				emit-poly opcodes/1
			][
				emit-load-imm32/reg idx * scale 3	;-- LDR r3, #idx
				emit-poly opcodes/2
			]
		][
			emit-load-index idx
			if scale > 1 [
				emit-i32 #{e0d03003}				;-- LSL r3, #log2(scale)
					or shift/left power-of-2? scale 7
			]
			emit-poly opcodes/2
		]
	]
	
	emit-load-path: func [path [path!] type [word!] parent [block! none!] /local idx][
		if verbose >= 3 [print [">>>loading path:" mold path]]

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [emit-access-path   path parent]
		]
	]
	
	emit-swap-regs: does [
		emit-i32 #{e1a0c001}						;-- MOV r12, r1
		emit-i32 #{e1a01000}						;-- MOV r1, r0
		emit-i32 #{e1a0000c}						;-- MOV r0, r12
	]
	
	emit-store-path: func [path [set-path!] type [word!] value parent [block! none!] /local idx offset][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]

		if parent [emit-i32 #{e1a01000}]			;-- MOV r1, r0		; save value/address
		unless value = <last> [emit-load value]
		emit-swap-regs								;-- save value/restore address

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [
				unless parent [parent: emit-access-path/short path parent]
				type: first compiler/resolve-type/with path/2 parent
				set-width/type type					;-- adjust operations width to member value size

				either zero? offset: emitter/member-offset? parent path/2 [
					emit-i32 #{e5401000}			;-- STR r1, [r0]
				][
					emit-load-index offset
					emit-i32 #{e5401000}			;-- STR r1, [r0, r3]
				]
			]
		]
	]
	
	emit-push: func [
		value [char! logic! integer! word! block! string! tag! path! get-word! object!]
		/with cast [object!]
		/local spec type
	][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if block? value [value: <last>]
		
		push-last: [emit-i32 #{e92d0001}]			;-- PUSH {r0}

		switch type?/word value [
			tag! [									;-- == <last>
				do push-last
			]
			logic! [
				emit-load-imm32 to integer! value	;-- MOV r0, #0|#1
				do push-last
			]
			char! [
				emit-load-imm32 to integer! value	;-- MOV r0, #imm8
				do push-last
			]
			integer! [
				emit-load-imm32 value
				do push-last
			]
			word! [
				type: first compiler/get-variable-spec value
				emit-variable value
					#{e5900000} 					;-- LDR r0, [r0]		; global
					#{e51b0000}						;-- LDR r0, [fp, #n]	; local
				do push-last
			]
			get-word! [
				pools/collect/spec 0 value
				emit-i32 #{e59f0000}				;-- LDR r0, [pc, #offset]
				do push-last						;-- PUSH &value
			]
			string! [
				spec: emitter/store-value none value [c-string!]
				pools/collect/spec 0 spec/2
				emit-i32 #{e59f0000}				;-- LDR r0, [pc, #offset]
				do push-last						;-- PUSH value
			]
			path! [
				emitter/access-path value none
				if cast [emit-casting cast no]
				emit-push <last>
			]
			object! [
				either path? value/data [
					emit-push/with value/data value
				][
					emit-push value/data
				]
			]
		]
	]

	emit-call-syscall: func [number nargs] [
		emit-i32 #{e8bd00}							;-- POP {r0, .., r<nargs>}
		emit-i32 shift #{ff} 8 - nargs
		emit-i32 #{e3a070}							;-- MOV r7, <number>
		emit-i32 to-bin8 number
		emit-i32 #{ef000000}						;-- SVC 0		; @@ EABI syscall
	]

	emit-call-native: func [spec] [
		add-native-reloc spec :reloc-bl
		emit-i32 #{eb000000}						;-- BL <disp>
	]

	add-native-reloc: func [spec callback] [
		repend/only spec/3 [emitter/tail-ptr :callback]
	]

	reloc-bl: func [code-buf rel-ptr dst-ptr] [
		;; @@ check bounds, @@ to-bin24
		change
			at code-buf rel-ptr
			copy/part to-bin32 shift (dst-ptr - rel-ptr - (2 * ptr-size)) 2 3
	]
	
	emit-argument: func [arg func-type [word!]][
		either all [
			object? arg
			any [arg/type = 'logic! 'byte! = first compiler/get-type arg/data]
			not path? arg/data
		][
			unless block? arg [emit-load arg]		;-- block! means last value is already in r0 (func call)
			emit-casting arg no
			emit-push <last>
			compiler/last-type: arg/type			;-- for inline unary functions
		][
			emit-push either block? arg [<last>][arg]
		]
	]

	emit-call: func [name [word!] args [block!] sub? [logic!] /local spec fspec] [
		if verbose >= 3 [print [">>>calling:" mold name mold args]]

		fspec: select compiler/functions name
		spec: any [select emitter/symbols name next fspec]
		type: first spec

		switch/default type [
			syscall [
				emit-call-syscall last fspec fspec/1
			]
			native [
				emit-call-native spec
			]
		] [
			compiler/throw-error join "[codegen] nyi call: " type
		]
	]

	emit-prolog: func [name locals [block!] args-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]
		
		pools/mark-entry-point

		;; we use a simple prolog, which maintains ABI compliance: args 0-3 are
		;; passed via regs r0-r3, further args are passed on the stack (pushed
		;; right-to-left; i.e. the leftmost argument is at top-of-stack).
		;;
		;; our prolog pushes the first <=4 args right-to-left to the stack as
		;; well and makes fp point to arg0 on the stack.
		;;
		;; after that, all callee-saved registers and the return address are
		;; pushed on the stack. sp will point to the return address on the
		;; stack.
		;;
		;; that's where the prolog ends. locals, if any, will be pushed on the
		;; stack immediately afterwards. all other reds-generated code is
		;; required to be stack neutral.
	;	repeat i args-size [
	;		emit-i32 #{e92d00}							;-- push {r<n>}
	;		emit-i32 shift/left #{01} (args-size - i)
	;	]
	;	unless zero? args-size [
	;		emit-i32 #{e1a0c00d}						;-- mov ip, sp
	;	]
	;	emit-i32 #{e92d4ff0}							;-- stmfd sp!, {r4-r11, lr}
	;	unless zero? args-size [
	;		emit-i32 #{e1a0b00c}						;-- mov fp, ip
	;	]
	]

	emit-epilog: func [name locals [block!] locals-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]

	;	unless zero? locals-size [
	;		;; Restore sp to where we saved our 9 callee-saved registers.
	;		emit-i32 #{e28bd024}						;-- add sp, fp, #36
	;	]
	;	emit-i32 #{e8bd8ff0}							;-- ldmfd sp!, {r4-r11, pc}
	]
]
