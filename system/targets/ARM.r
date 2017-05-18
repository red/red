REBOL [
	Title:	 "Red/System ARM code emitter"
	Author:	 "Andreas Bolka, Nenad Rakocevic"
	File:	 %ARM.r
	Tabs:	 4
	Rights:	 "Copyright (C) 2011-2017 Andreas Bolka, Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

make-profilable make target-class [
	target:				'ARM
	little-endian?:		yes
	struct-align-size:	4
	ptr-size:			4
	default-align:		4
	stack-width:		4
	stack-slot-max:		8							;-- size of biggest datatype on stack (float64!)
	args-offset:		8							;-- stack frame offset to arguments (fp + lr)
	branch-offset-size:	4							;-- size of branch instruction
	locals-offset:		8							;-- offset from frame pointer to local variables (catch ID + addr)
	insn-size:			4
	last-math-op:		none						;-- save last math op type for overflow checking

	
	need-divide?: 		none						;-- if TRUE, include division routine in code
	div-sym:			'_div_
	
	conditions: make hash! [
	;-- name ----------- signed --- unsigned --
		overflow?		 #{60}		-
		not-overflow?	 #{70}		-	
		=				 #{00}		-
		<>				 #{10}		-
		signed?			 -			-
		unsigned?		 -			-
		even?			 -			-
		odd?			 -			-
		<				 #{b0}		#{30}
		>=				 #{a0}		#{20}
		<=				 #{d0}		#{90}
		>				 #{c0}		#{80}
	]
	
	byte-flag: 			#{00400000}					;-- trigger byte access in opcode
	
	pools: context [								;-- literals pools management
		active?:	  no							;-- yes => store in pools, no => store inlined
		values:		  make block! 2000				;-- [value instruction-pos sym-spec ...]
		entry-points: make block! 100				;-- insertion points candidates for pools between functions
		ins-points:	  make block! 100				;-- insertion points candidates for pools inlined in code
		pools:		  make block! 1					;-- [pool-pos [value-ref ...] inline? ...]
		limit:		  4088							;-- reachability max distance (insn<->pool, 4092 - insn - branching)
		verbose:	  0								;-- if > 0, output debug logs
		
		pools-stats: has [list][
			print "--- Pools:"
			list: pools
			forskip list 3 [
				print ["pos:" list/1 ", literals:" length? list/2]
			]
			print "---"
		]
		
		;-- Collect a literal value to be stored in a pool
		collect: func [value [integer!] /spec s [word! get-word! block!] /with opcode [binary!] /local pos][
			either active? [
				insert pos: tail values reduce [value emitter/tail-ptr s]
				emit-reloc-addr/only next pos
				emit-i32 any [opcode #{e59f0000}]
				pos
			][
				emit-i32 any [opcode #{e59f0000}]	;-- LDR r0, [pc, #0]	; offset 0 => value
				emit-i32 #{ea000000}				;-- B <after_value>
				if spec [
					spec: switch type?/word s [
						get-word! [emitter/get-symbol-ref to word! s]
						word!	  [emitter/symbols/:s]
						block!	  [s]
					]
					
					emit-reloc-addr spec/3
				]				
				emit to-bin32 value					;-- emit value
			]
		]
		
		;-- Collect a possible position in code for a literals pool
		mark-entry-point: func [name][
			if verbose > 0 [print ["new entry-point:" emitter/tail-ptr "(after" name #")"]]
			
			append entry-points emitter/tail-ptr
		]
		
		mark-ins-point: has [pos][
			pos: emitter/tail-ptr
			if pos <> pick tail ins-points -1 [append ins-points pos]
		]
		
		insert-jmp-point: func [idx [integer!] offset [integer!]][			
			update-values-index idx 4				;-- move values references by 4 bytes
			update-entry-points idx 4				;-- move entry-points by 4 bytes
		]
		
		get-pool: does [all [not empty? pools skip tail pools -3]]
		
		make-pool: func [/ins /local bound base list pool refs][
			if all [
				not ins
				(entry-points/1 - first any [get-pool [1]]) >= limit
			][
				ins: true
			]
			list: either ins [ins-points][entry-points]
			
			if all [
				not empty? pools
				empty? second pool: get-pool	;-- remove last pool if empty
			][
				clear pool
			]
			either ins [
				base: ins-points/1				;-- start search on first available insertion point
				while [list/1 - base < limit][	;-- search farthest reachable point (accounting for fake entry)
					list: next list
				]
				list: back list					;-- limit exceeded, back to last reachable
			][
				unless empty? pools [
					bound: second last second get-pool	;-- start search after last stored literal entry position in code
					while [list/1 < bound][
						list: next list
					]
					if tail? list [
						compiler/throw-error "[ARM emitter] suitable pool position not found!"
					]
				]
			]
				
			if verbose > 0 [print ["^/* making a new pool, at:" list/1 ", inlined?:" ins]]
			
			repend pools [list/1 refs: make block! 50 to logic! ins]	;-- create a new pool entry
			
			either ins [
				remove/part ins-points next list	;-- clear all ins-points before pool position
				repend/only refs [0 0 none]			;-- insert fake literal in pool (place-holder for B insn) 
			][
				entry-points: next list				;-- move to next possible position
			]
			get-pool								;-- return a reference on the last pool structure
		]
				
		update-values-index: func [idx [integer!] offset [integer!]][		
			forskip values 3 [			
				if values/2 >= idx [values/2: values/2 + offset]
			]			
		]
		
		;-- Update functions entry points after a pool insertion
		update-entry-points: func [pool-idx [integer!] offset [integer!] /strict /local refs comp ep][
			comp: get pick [greater? greater-or-equal?] to logic! strict
			
			ep: head entry-points
			forall ep [if comp ep/1 pool-idx [ep/1: ep/1 + offset]]
			
			forskip pools 3 [if comp pools/1 pool-idx [pools/1: pools/1 + offset]]

			foreach [name spec] emitter/symbols [	;-- move functions entry-points and references
				if find [native native-ref] spec/1 [
					if all [spec/2 spec/2 >= pool-idx][spec/2: spec/2 + offset]
					unless empty? refs: spec/3 [
						forall refs [if refs/1 >= pool-idx [refs/1: refs/1 + offset]]
					]
				]
			]
		]

		;-- Update functions entry points after a pool insertion
		update-refs-part: func [floor [integer!] ceil [integer!] offset [integer!] /local refs ep ip][
			forskip values 3 [
				if values/2 - 4 > ceil [break]
				if values/2 - 4 >= floor [values/2: values/2 + offset]
			]
			values: head values
			
			ep: head entry-points
			forall ep [
				if ep/1 - 4 > ceil [break]
				if ep/1 - 4 > floor [ep/1: ep/1 + offset]
			]

			ip: head ins-points
			forall ip [
				if ip/1 - 4 > ceil [break]
				if ip/1 - 4 > floor [ip/1: ip/1 + offset]
			]

			forskip pools 3 [
				if pools/1 - 4 > ceil [break]
				if pools/1 - 4 > floor [pools/1: pools/1 + offset]
			]
			pools: head pools

			foreach [name spec] emitter/symbols [	;-- move functions entry-points and references
				if find [native native-ref] spec/1 [
					if all [spec/2 spec/2 >= floor spec/2 - 4 < ceil][spec/2: spec/2 + offset]
					unless empty? refs: spec/3 [
						forall refs [
							if refs/1 - 4 > ceil [break]
							if refs/1 - 4 >= floor [refs/1: refs/1 + offset]
						]
					]
				]
			]
		]
		
		find-close-pool: func [pool-idx [integer!] ins-idx [integer!] /local pool][
			pool: find/skip pools pool-idx 3
			until [
				pool: skip pool 3
				if tail? pool [
					if limit > entry-points/1 [return make-pool]	;-- see if next entry-point is reachable
					return make-pool/ins							; @@ temp change
					;compiler/throw-error "[ARM emitter] unable to find a reachable pool!"
				]
				limit > (abs pool/1 + (4 * length? pool/2) - (ins-idx + 8))
			]
			pool
		]
		
		;-- Create literal pools lists and put literals pointers inside according to their distance
		populate-pools: has [index pos offset pool][
			if verbose > 0 [print "^/=== Populate stage ==="]
			
			forskip values 3 [
				index: values/2
				if empty? pools [make-pool]

				pool: get-pool
				pos: pool/1 + (4 * length? pool/2)	;-- pos: offset of value entry in the pool buffer

				offset: pos - index
				if verbose > 0 [prin [offset #" "]]

				either positive? offset [			;-- test if pool is before or after caller
					if limit <= offset [				;-- if pool is too far ahead
						pool: make-pool/ins			;-- make a new pool at next possible insertion position
					]
				][
					if limit <= abs offset [			;-- if pool too far behind,
						pool: make-pool				;-- make a new pool at next possible position @@ > 4088 case
						pos: pool/1
					]
				]
				append/only pool/2 values			;-- insert literal value in the pool
			]
			sort/skip pools 3
		]
		
		;-- Move literal values that became out-of-range to a closer pool
		adjust-pools: has [pool-size value ins-idx spec entry-pos offset][
			if verbose > 0 [print "^/=== Adjust stage ===" pools-stats]
			
			foreach [pool-idx value-refs inline?] pools [
				pool-size: 4 * length? value-refs
				update-values-index pool-idx pool-size
				update-entry-points/strict pool-idx pool-size
			]
		
			foreach [pool-idx value-refs inline?] pools [
				if verbose > 0 [print ["^/processing pool:" pool-idx]]
				if inline? [value-refs: next value-refs]	;-- skip first fake entry (for branch insn)
				
				forall value-refs [		
					set [value ins-idx spec] value-refs/1
					
					entry-pos: 4 * (-1 + index? value-refs)	;-- offset of value entry in the pool
					offset: pool-idx + entry-pos - (ins-idx + 8)	;-- relative jump offset to the entry				
					if verbose > 0 [prin [offset #" "]]
				
					offset:	abs offset

					if offset >= limit [
						pool: find-close-pool pool-idx ins-idx
						if verbose > 0 [print ["^/* out-of-range:" offset ", moving to pool:" pool/1]]
						append/only pool/2 value-refs/1
						remove value-refs
						value-refs: back value-refs

						update-refs-part pool-idx pool/1 -4

						;update-values-index pool-idx -4
						;update-entry-points/strict pool-idx -4
						;
						;update-values-index pool/1 4
						;update-entry-points/strict pool/1 4
					]
				]
			]
		]
		
		;-- Build pools buffers and insert them in native code buffer
		commit-pools: has [buffer value ins-idx spec entry-pos offset code back? buf-size][
			if verbose > 0 [print "^/=== Commit stage ===" pools-stats]
			buffer: make binary! 800						;-- reserve pool buffer for 200 values (average estimate)

			foreach [pool-idx value-refs inline?] pools [
				if verbose > 0 [print ["^/- pool:" pool-idx ", len:" length? value-refs]]
				clear buffer
				
				buf-size: 4 * length? value-refs
				if inline? [
					append buffer reverse rejoin [			;-- B <buf-size>	; branch over the pool buffer
						#{ea} to-bin24 shift buf-size - 8 2
					]
					value-refs: next value-refs				;-- skip place-holder value				
				]
				insert/dup at emitter/code-buf pool-idx null buf-size
				
				forall value-refs [		
					set [value ins-idx spec] value-refs/1
					
					append buffer reverse debase/base to-hex value 16
										
					entry-pos: 4 * (-1 + index? value-refs)	;-- offset of value entry in the pool
					offset: pool-idx + entry-pos - (ins-idx + 8)	;-- relative jump offset to the entry				
					back?: negative? offset 
					if verbose > 0 [prin [offset #" "]]
					
					offset:	abs offset

					if offset >= limit [
						compiler/throw-error "[ARM emitter] adjusting failed!"
					]
					offset: reverse to-12-bit offset
					
					code: at emitter/code-buf ins-idx
					change code offset or copy/part code 4	;-- add relative jump offset to instruction
					if back? [code/3: #"^(7F)" and code/3]	;-- encode a negative offset

					if spec [
						spec: switch type?/word spec [
							get-word! [emitter/get-func-ref to word! spec]
							word!	  [emitter/symbols/:spec]
							block!	  [spec]
						]
						append spec/3 pool-idx + entry-pos	;-- add symbol back-reference for linker
					]
				]
				change at emitter/code-buf pool-idx buffer	;-- insert pool in code buffer
			]
		]
		
		process: does [
			unless empty? values [
				populate-pools
				adjust-pools
				commit-pools
			]	
			clear entry-points: head entry-points
			clear ins-points
			clear values
			clear pools
		]
	]
	
	emit-reloc-addr: func [spec [block!] /only][
		unless only [append spec emitter/tail-ptr]	;-- save reloc position
		unless empty? emitter/chunks/queue [				
			append/only 							;-- record reloc reference
				second last emitter/chunks/queue
				either only [spec][back tail spec]
		]
	]
	
	emit-divide: has [base][
		;-- Unsigned division code is from http://www.virag.si/2010/02/simple-division-algorithm-for-arm-assembler/
		;-- Original routine extended to handle signed division using code from:
		;-- "ARM System Developer's Guide", p.238, ISBN: 1-55860-874-5
		;-- registers usage:
		;-- 	- on entering: r0: dividend, r1: divisor, r4: mode (0: division, 1: modulo, 2: remainder)
		;--		- on exit: r0: quotient, r1: remainder or r0: modulo/remainder
		;--		- registers modified: r0-r3, r5, ip
		
		if verbose >= 3 [print "^/>>>emitting DIVIDE intrinsic"]
		
		base: emitter/tail-ptr
		
		foreach opcode [	
							; .divide	
			#{e3510000}			; CMP r1, #0			; if divisor = 0
			#{092d4000}			; PUSHEQ {lr}			; push calling address for error location
			#{03a0000d}			; MOVEQ r0, #13			; integer divide by zero error code
			#{092d0001}			; PUSHEQ {r0}
			#{0a000000}			; BEQ ***-on-div-error	; call runtime error handler
			#{e1500001}			; CMP r0, r1			; if dividend = divisor
			#{0a00000b}			; BEQ .equal
			#{e1a03000}			; MOV r3, r0			; r3: dividend
			#{e1a05001}			; MOV r5, r1			; r5: divisor
			#{e3500000}			; CMP r0, #0			; if dividend < 0
			#{42603000}			; RSBMI r3, r0, #0		;	r3: -dividend
			#{e3510000}			; CMP r1, #0			; if divisor < 0
			#{42615000}			; RSBMI r5, r1, #0		;	r5: -divisor
			#{e3500102}			; CMP r0, #1<<31		; if r3 = -2^31 (special case for -2^31)
			#{0a000006}			; BEQ .ispowerof2		; or
			#{e1530005}			; CMP r3, r5			; if r3 <= divisor
			#{8a000004}			; BHI .ispowerof2			
			#{e1a01000}			; MOV r1, r0			; remainder: dividend
			#{e3a00000}			; MOV r0, #0			; quotient: 0
							; .equal
			#{03a00001}			; MOVEQ r0, #1			; if dividend = divisor, quotient: 1
			#{03a01000}			; MOVEQ r1, #0			;	remainder: 0
			#{ea000024}			; B .divide_end			; jump to remainder epilog
							; .ispowerof2
			#{e2413001}			; SUB r3, r1, #1		; r3: divisor - 1
			#{e1130001}			; TST r3, r1			; if divisor is a power of 2 (divisor & (divisor - 1))
			#{1a00000c}			; BNE .notpowerof2
			#{e1a03000}			; MOV r3, r0			; save dividend
			#{e1a02001}			; MOV r2, r1			; save divisor
							; .powerof2
			#{31a000c0}			; MOVCC r0, r0, ASR#1	; divide by 2 (but not on first pass)
			#{e1b010a1}			; MOVS r1, r1, LSR#1	; until power of 2 reached (carry set)
			#{3afffffc}			; BCC .powerof2
			#{e2621000}			; RSB r1, r2, #0		; 2's complement of divisor
			#{e0031001}			; AND r1, r3, r1		; r1: dividend and -divisor
			#{e0431001}			; SUB r1, r3, r1		; compute remainder = (dividend - (dividend and -divisor))
			#{e3530102}			; CMP r3, #1<<31		; if r3 = -2^31 (special case for -2^31)
			#{0a000017}			; BEQ .divide_end		; 	jump to end
			#{e3530000}			; CMP r3, #0			; if dividend < 0
			#{40411002}			; SUBMI r1, r1, r2		;	adjust remainder (remainder = remainder - divisor)
			#{ea000014}			; B .divide_end
							; .notpowerof2
			#{e1b02001}			; MOVS r2, r1			; r2: divisor
			#{e212c102}			; ANDS ip, r2, #1<<31	; if r2 < 0, ip: #80000000
			#{42622000}			; RSBMI r2, r2, #0		; if r2 < 0, r2: -r2 (2's complement)
			#{e1b01000}			; MOVS r1, r0			; r1: dividend
			#{e03cc041}			; EORS ip, ip, r1 ASR#32 ; if r1 < 0, ip: ip xor r1>>32
			#{22611000}			; RSBCS r1, r1, #0		; if r1 < 0, r1: -r1 (2's complement)
			
			#{e3a00000}			; MOV r0, #0     		; clear R0 to accumulate result
			#{e3a03001}			; MOV r3, #1     		; set bit 0 in R3, which will be shifted left then right
							; .start
			#{e1520001}			; CMP r2, r1
			#{91a02082}			; MOVLS r2, r2, LSL#1	; shift R2 left until it is about to be bigger than R1
			#{91a03083}			; MOVLS r3, r3, LSL#1	; shift R3 left in parallel in order to flag how far we have to go
			#{9afffffb}			; BLS      start
							; .next
			#{e1510002}			; CMP r1, r2      		; carry set if R1>R2 (don't ask why)
			#{20411002}			; SUBCS r1, r1, r2      ; subtract R2 from R1 if this would
														; give a positive answer
			#{20800003}			; ADDCS r0, r0, r3   	; and add the current bit in R3 to
											  			; the accumulating answer in R0.
			#{e1b030a3}			; MOVS r3, r3, LSR#1	; Shift R3 right into carry flag
			#{31a020a2}			; MOVCC r2, r2, LSR#1	; and if bit 0 of R3 was zero, also
												   		; shift R2 right.
			#{3afffff9}			; BCC next				; If carry not clear, R3 has shifted
			
							; .epilog					; back to where it started, and we can end
			#{e1b0c08c}			; MOVS ip, ip, LSL#1	; C: bit 31, N: bit 30
			#{22600000}			; RSBCS	r0, r0, #0		; if C = 1, r0: -r0 (2's complement)
			#{42611000}			; RSBMI	r1, r1, #0		; if N = 1, r1: -r1 (2's complement)								
							; .divide_end				; r0: quotient, r1: remainder
			#{e3340000}			; TEQ r4, #0			; if not modulo/remainder op,
			#{01a0f00e}			; MOVEQ pc, lr			; 	return from sub-routine
			
			;-- Adjust modulo result to be mathematically correct:
			;-- 	if modulo < 0 [
			;--			if divisor < 0 [divisor: negate divisor]
			;--			modulo: modulo + divisor
			;--		]
			#{e1b00001}			; MOVS r0, r1			; r0: modulo or remainder
			#{e3340002}			; TEQ r4, #2			; if r1 <> rem,
			#{01a0f00e}			; MOVEQ pc, lr			; 	return from sub-routine
			#{e3500000}			; CMP r0, #0	 		; if r0 >= 0, (modulo)
			#{51a0f00e}			; MOVPL pc, lr			; 	return from sub-routine
			#{e3520000}			; CMP r2, #0	 		; if r2 < 0 (divisor)
			#{41e00000}			; RSBMI	r0, r0, #0		;	r0: -r0 (2's complement)
			#{e0800002}			; ADD r0, r0, r2		; r0: r0 + r2
			#{e1a0f00e}			; MOV pc, lr			; return from sub-routine
 		][
 			emit-i32 opcode
 		]
 		;-- link it with runtime error handler
 		append emitter/symbols/***-on-div-error/3 base + (4 * insn-size)
	]
	
	;-- Check if div-sym is not user-defined, else provide a unique replacement symbol
	make-div-sym: has [retry][
		if select emitter/symbols div-sym [
			retry: 3								;-- try 3 times, then spit an error to user face ;)
			until [
				div-sym: to word! rejoin ["_div_" random "0123456798"]
				if zero? retry: retry - 1 [
					compiler/throw-error "Unable to create divide symbol!"
				]
				none? emitter/symbols/:div-sym
			]
		]
		div-sym
	]
	
	call-divide: func [mod? [word! none!] /local refs][
		refs: third either need-divide? [
			emitter/symbols/:div-sym
		][
			div-sym: make-div-sym
			need-divide?: yes
			emitter/add-native div-sym				;-- add an entry for the divide pseudo-function
		]
		
		emit-i32 join #{e3a040} switch/default mod? [ ;-- MOV r4, #0|1|2
			mod [#"^(01)"]							;-- modulo
			rem [#"^(02)"]							;-- remainder
		][null]										;-- division
		
		emit-reloc-addr refs
		emit-i32 #{eb000000}						;-- BL .divide
	]
	
	on-init: does [
		if PIC? [
			emit-i32 #{e1a0900f}					;-- MOV sb, pc
			emit-i32 #{e2499008}					;-- SUB sb, #8
		]
	]
	
	on-finalize: does [
		if need-divide? [
			emitter/symbols/:div-sym/2: emitter/tail-ptr
			emit-divide
		]
		if pools/active? [pools/process]			;-- trigger pools processing on end of code generation
	]
	
	on-global-prolog: func [runtime? [logic!]][
		pools/active?: compiler/job/literal-pool?
		if runtime? [need-divide?: no]
	]
	
	on-global-epilog: func [runtime? [logic!]][
		if all [
			not runtime?
			compiler/job/runtime?
			compiler/job/need-main?
		][
			emit-i32 #{e1a0d00b}					;-- MOV sp, fp		; unwind root frame
			emit-pop								;-- pop exceptions threshold slot
			emit-pop								;-- pop exceptions address slot
			emit-i32 #{e8bd0800}					;-- POP {fp}
			emit-epilog '***_start [] 7 * 4 0		;-- restore all before returning in __libc_start_main()
		]
		unless runtime? [
			pools/mark-entry-point 'global			;-- add end of global code section as pool entry-point
		]
	]
	
	on-root-level-entry: does [
		pools/mark-ins-point
	]
	
	count-floats: func [spec [block!] /local cnt][
		cnt: 0
		parse spec [any [into ['float! | 'float64! | 'float32!] (cnt: cnt + 1) | skip]]		
		cnt
	]
	
	extract-arguments: func [spec [block!] /local cnt][
		spec: copy spec
		clear find spec first [return:]
		clear find spec /local
		if string? spec/1 [remove spec]
		if block?  spec/1 [remove spec]
		remove-each value spec [not block? value]
		head reverse spec
	]
	
	hidden-ptr?: func [fspec [block!] /local ret][
		all [
			fspec/2 = 'import
			fspec/3 = 'cdecl
			ret: select fspec/4 compiler/return-def
			'value = last ret
			1 < emitter/struct-slots? ret
		]
	]
	
	to-bin24: func [v [integer! char!]][
		copy skip debase/base to-hex to integer! v 16 1
	]
	
	;-- Convert a 12-bit integer offset to a 32-bit hexa LE
	to-12-bit: func [offset [integer!]][
		#{00000FFF} and debase/base to-hex offset 16
	]
	
	to-shift-imm: func [value [integer!]][
		reverse to-bin32 shift/left value 7
	]

	instruction-buffer: make binary! 4
	
	f-inc: func [op [binary!] idx [integer!]][
		either zero? idx [op][op or debase/base to-hex shift/left idx 12 16]
	]
	
	;-- Overloaded emit to print reversed binary series for easier reading
	emit: func [bin [binary! char! block!]][
		if verbose >= 4 [print [">>>emitting code:" mold reverse copy bin]]
		append emitter/code-buf bin
	]

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

	emit-load-imm32: func [value [integer! char!] /reg n [integer!] /local neg? bits opcode][
		value: to integer! value
		if neg?: negative? value [value: complement value]

		either bits: ror-position? value [	
			opcode: rejoin [						;-- MOVS r0|rN, #imm8, bits	; v = imm8 (ROR bits)x2
				#{e3} 
				pick [#{f0} #{b0}] neg?				;-- emit MVNS instead, if required
				to char! bits
				to char! rotate-left value bits
			]
			if reg [opcode: opcode or debase/base to-hex shift/left n 12 16]
			emit-i32 opcode
		][
			opcode: #{e59f0000}						;-- LDR r0|rN, [pc, #offset]
			if reg [opcode: opcode or debase/base to-hex shift/left n 12 16]
			
			pools/collect/with either neg? [complement value][value] opcode
		]
	]
	
	emit-op-imm32: func [opcode [binary!] value [integer! char!] /local bits][
		opcode: copy opcode
		either bits: ror-position? value: to integer! value [
			opcode/3: (to char! opcode/3) or to char! bits
			opcode/4: to char! rotate-left value bits
		][
			pools/collect/with value #{e59f3000}	;-- LDR r3, [pc, #offset]
			opcode/1: #"^(FD)" and to char! opcode/1
			opcode/4: #"^(03)"
		]
		emit-i32 opcode
	]
	
	emit-float: func [d-code [binary!] s-code [binary!]][
		emit-i32 either width = 8 [d-code][s-code]
	]
	
	emit-load-local: func [opcode [binary!] offset [integer!] /float][
		if negative? offset [
			opcode: copy opcode
			opcode/2: #"^(7F)" and opcode/2			;-- clear bit 23 (U)
		]
		if float [offset: offset / 4]
		offset: to-12-bit abs offset
		;if alt [opcode: opcode or #{00001000}]		;-- use r1 instead of r0 
		emit-i32 opcode or offset
	]
	
	emit-float-variable: func [
		name [word! object!] gcode [binary!] lcode [binary!]
		/local offset
	][
		if object? name [name: compiler/unbox name]

		either offset: emitter/local-offset? name [	;-- local variable case
			emit-load-local/float lcode offset
		][											;-- global variable case
			pools/collect/spec/with 0 name #{e59f3000}	;-- LDR r3, [pc, #offset]
			if PIC? [emit-i32 #{e0833009}]				;-- ADD r3, sb
			emit-i32 gcode
		]
	]

	emit-variable: func [
		name  [word! object!]
		gcode [binary! block! none!]
		pcode [binary! block! none!]
		lcode [binary! block!]
		/alt										;-- use alternative register (r1)
		/local offset opcode Rn
	][
		if object? name [name: compiler/unbox name]

		either offset: emitter/local-offset? name [	;-- local variable case
			emit-load-local lcode offset
		][											;-- global variable case
			opcode: #{e59f0000}
			
			either alt [
				opcode: opcode or #{00001000}		;-- use r1 instead of r0
			][
				if all [gcode not zero? Rn: gcode/3 and #"^(F0)"][
					opcode: copy opcode
					opcode/3: to char! Rn			;-- use same Rn
				]
			]
			pools/collect/spec/with 0 name opcode	;-- LDR r0|r1|Rn, [pc, #offset]
			opcode: get pick [pcode gcode] PIC?
			if opcode [emit-i32 opcode]
		]
	]
	
	emit-variable-64: func [
		name [word!] gcode [binary!] l-low [binary!] l-high [binary!]
	][
		if object? name [name: compiler/unbox name]
		
		either offset: emitter/local-offset? name [	;-- local variable case
			emit-load-local l-low offset
			emit-load-local l-high offset + 4
		][
			pools/collect/spec/with 0 name #{e59f2000}	;-- LDR r2, [pc, #offset]
			if PIC? [emit-i32 #{e0822009}]				;-- ADD r2, sb
			emit-i32 gcode
		]
	]
	
	emit-variable-poly: func [						;-- polymorphic variable access generation
		name [word! object!]
		g-code [binary!]							;-- opcodes for global variables
		p-code [binary! none!]						;-- opcodes for global variables
		l-code [binary! block!]						;-- opcodes for local variables
		/alt
	][
		with-width-of name [
			if width = 1 [
				g-code: g-code or byte-flag
				if p-code [p-code: p-code or byte-flag]
				l-code: l-code or byte-flag
			]
			either alt [
				emit-variable/alt name g-code p-code l-code
			][
				emit-variable name g-code p-code l-code
			]
			if all [
				PIC?
				none? p-code
				none? emitter/local-offset? name
			][										;-- no specific PIC opcode case (LDM/STM)
				emit-i32 pick [
					#{e0811009}						;-- ADD r1, sb
					#{e0800009}						;-- ADD r0, sb
				] to logic! alt
				emit-i32 g-code
			]
		]
	]
	
	emit-load-symbol: func [name [word!]][
		emit-variable name
			#{e5900000}								;-- LDR r0, [r0]		; global
			#{e7900009}								;-- LDR r0, [r0, sb]	; PIC
			#{e59b0000}								;-- LDR r0, [fp, #[-]n]	; local
	]
	
	emit-move-alt: does [emit-i32 #{e1a01000}]		;-- MOV r1, r0

	emit-swap-regs: func [/alt][
		either alt [
			emit-i32 #{e1a0c002}					;-- MOV r12, r2
			emit-i32 #{e1a02000}					;-- MOV r2, r0
			emit-i32 #{e1a0000c}					;-- MOV r0, r12	
		][
			emit-i32 #{e1a0c001}					;-- MOV r12, r1
			emit-move-alt
			emit-i32 #{e1a0000c}					;-- MOV r0, r12
		]
	]
	
	emit-move-path-alt: does [
		emit-i32 #{e1a02000}						;-- MOV r2, r0
	]
	
	emit-save-last: does [
		last-saved?: yes
		either find [float! float64!] compiler/last-type/1 [
			emit-i32 #{e92d0003}					;-- PUSH {r0,r1}
		][
			emit-i32 #{e92d0001}					;-- PUSH {r0}
		]
	]

	emit-restore-last: does [
		unless find [float! float64! float32!] compiler/last-type/1 [
			emit-i32 #{e8bd0002}		   			;-- POP {r1}
		]
	]
	
	emit-alloc-stack: does [
		emit-i32 #{e240d000}						;-- SUB sp, r0
		emit-i32 #{e20dd0fc}						;-- AND sp, #-4 ; align to lower bound
	]

	emit-free-stack: does [
		emit-i32 #{e1e00000}						;-- NEG r0			; MVN r0, r0
		emit-i32 #{e3c00003}						;-- AND r0, #-4
		emit-i32 #{e1e00000}						;-- NEG r0			; align to upper bound
		emit-i32 #{e08dd000}						;-- ADD sp, sp, r0
	]

	emit-reserve-stack: func [slots [integer!] /local size][
		size: slots * stack-width
		either size > 255 [
			emit-load-imm32/reg size 4
			emit-i32 #{e04dd004}					;-- SUB sp, sp, r4	; 32-bit displacement
		][
			emit-i32 join #{e24dd0}	to-bin8 size	;-- SUB sp, sp, size ; 8-bit displacement
		]
	]

	emit-release-stack: func [slots [integer!] /bytes /local size][
		size: either bytes [slots][slots * stack-width]
		either size > 255 [
			emit-load-imm32/reg size 4
			emit-i32 #{e08dd004}					;-- ADD sp, sp, r4	; 32-bit displacement
		][
			emit-i32 join #{e28dd0}	to-bin8 size	;-- ADD sp, sp, size ; 8-bit displacement
		]
	]

	emit-casting: func [value [object!] alt? [logic!] /local old type][
		type: compiler/get-type value/data	
		case [
			value/type/1 = 'logic! [
				if verbose >= 3 [print [">>>converting from" mold/flat type/1 "to logic!"]]
				old: width
				set-width/type type/1
				either alt? [
					if width = 1 [										; 16-bit not supported
						emit-i32 #{e20110ff}		;-- AND r1, r1, #ff
					]
					emit-i32 #{e3510000}			;-- CMP r1, 0
					emit-i32 #{13a01001}			;-- MOVNE r1, #1
				][
					if width = 1 [										; 16-bit not supported
						emit-i32 #{e20000ff}		;-- AND r0, r0, #FF
					]
					emit-i32 #{e3500000}			;-- CMP r0, 0
					emit-i32 #{13a00001}			;-- MOVNE r0, #1
				]
				width: old
			]
			all [value/type/1 = 'integer! type/1 = 'byte!][
				if verbose >= 3 [print ">>>converting from byte! to integer! "]
				emit-i32 pick [
					#{e20110ff}						;-- AND r1, r1, #ff				
					#{e20000ff}						;-- AND r0, r0, #ff
				] alt?
			]
			all [value/type/1 = 'integer! find [float! float64! float32!] type/1][
				if verbose >= 3 [print [">>>converting from" type/1 "to integer!"]]
				either type/1 = 'float32! [
					either alt? [
						emit-i32 #{ee011a10}		;-- FMSR   s2, r1
						emit-i32 #{eebd1ac1}		;-- FTOSIS s2, s2
					][
						emit-i32 #{ee000a10}		;-- FMSR   s0, r0
						emit-i32 #{eebd0ac0}		;-- FTOSIS s0, s0
					]
				][
					emit-i32 #{ec410b10}			;-- FMDRR d0, r1, r0
					either alt? [
						emit-i32 #{eebd1bc0}		;-- FTOSID s2, d0
					][
						emit-i32 #{eebd0bc0}		;-- FTOSID s0, d0
					]
				]
				either alt? [
					emit-i32 #{ee111a10}			;-- FMRS   r1, s2
				][
					emit-i32 #{ee100a10}			;-- FMRS   r0, s0
				]
			]
			all [find [float! float64! float32!] value/type/1 type/1 = 'integer!][
				if verbose >= 3 [print [">>>converting from integer! to" value/type/1]]
				either alt? [
					emit-i32 #{ee011a10}			;-- FMSR s1, r1
				][
					emit-i32 #{ee000a10}			;-- FMSR s0, r0
				]
				either value/type/1 = 'float32! [
					either alt? [
						emit-i32 #{eeb81ac1}		;-- FSITOS s1, s1
						emit-i32 #{ee111a10}		;-- FMRS r1, s1
					][
						emit-i32 #{eeb80ac0}		;-- FSITOS s0, s0
						emit-i32 #{ee100a10}		;-- FMRS r0, s0
					]
				][
					either alt? [
						emit-i32 #{eeb80bc1}		;-- FSITOD d0, s1
					][
						emit-i32 #{eeb80bc0}		;-- FSITOD d0, s0
					]
					emit-i32 #{ec510b10}			;-- FMRRD r0, r1, d0
				]
			]
			all [find [float! float64!] value/type/1 type/1 = 'float32!][
				if verbose >= 3 [print ">>>converting from float32! to float!"]
				either alt? [
					emit-i32 #{ee001a10}			;-- FMSR s0, r1
				][
					emit-i32 #{ee000a10}			;-- FMSR s0, r0
				]
				emit-i32 #{eeb70ac0}				;-- FCVTDS d0, s0
				emit-i32 #{ec510b10}				;-- FMRRD r0, r1, d0
			]
			all [value/type/1 = 'float32! find [float! float64!] type/1][
				if verbose >= 3 [print [">>>converting from float! to float32!"]]
				; @@ handle alt case?
				emit-i32 #{ec410b10}				;-- FMDRR d0, r1, r0
				emit-i32 #{eeb70bc0}				;-- FCVTSD s0, d0
				emit-i32 #{ee100a10}				;-- FMRS r0, s0
			]
		]
	]
	
	emit-load-literal: func [type [block! none!] value][
		unless type [type: compiler/get-type value]
		emit-load-literal-ptr second emitter/store-value none value type
	]
	
	emit-load-literal-ptr: func [spec [block!]][
		pools/collect/spec 0 spec					;-- r0: value
		if PIC? [emit-i32 #{e0800009}]				;-- ADD r0, sb
	]
	
	emit-access-register: func [reg [word!] set? [logic!] value /local opcode][
		if verbose >= 3 [print [">>>emitting ACCESS-REGISTER" mold value]]
		if all [set? not tag? value][emit-load value]

		unless reg = 'r0 [
			opcode: copy #{e1a00000}
			reg: to integer! next form reg
			either set? [
				opcode/3: to char! shift/left reg 4
			][
				opcode/4: to char! reg
			]
			emit-i32 opcode							;-- MOV <reg>, r0	; set
		]											;-- MOV r0, <reg>	; get
	]
	
	emit-fpu-get: func [
		/type
		/options option [word!]
		/masks mask [word!]
		/cword
		/local value bit 
	][
		unless type [
			emit-i32 #{eef10a10}					;-- FMRX r0, FPSCR
		]
		case [
			type [
				; hardcoded value for now (FPU_VFP)
				emit-load-imm32 3					;-- MOV r0, <FPU_TYPE_VFP>
			]
			options [
				set [value bit] switch/default option [
					rounding  		[[#{00C00000} 22]]
					flush-to-zero	[[#{01000000} 24]]
					NaN-mode		[[#{02000000} 25]]
				][
					compiler/throw-error ["invalid FPU option name:" option]
				]
				emit-op-imm32 #{e2000000} to integer! value  ;-- AND r0, r0, #mask
			]
			masks [
				bit: switch/default mask [
					precision	[12]
					underflow	[11]
					overflow	[10]
					zero-divide [9]
					denormal	[15]
					invalid-op  [8]
				][
					compiler/throw-error ["invalid FPU mask name:" mask]
				]
				emit-op-imm32 #{e2000000} shift/left 1 bit  ;-- AND r0, r0, #mask
			]
			;cword []									;-- control word is already in eax
		]
		unless any [type cword][						;-- align result on right side
			emit-i32 #{e1a00020} or to-shift-imm bit	;-- LSR r0, r0, #bit
			if masks [emit-i32 #{e2200001}]				;-- EOR r0, #1		; invert 0<=>1
		]
	]

	emit-fpu-set: func [
		value
		/options option [word!]
		/masks mask [word!]
		/cword
		/local bit
	][
		value: to integer! value
		unless cword [emit-i32 #{eef10a10}]			;-- FMRX r0, FPSCR
		
		case [
			options [
				set [mask bit] switch/default option [
					rounding  		[[#{00C00000} 22]]
					flush-to-zero	[[#{01000000} 24]]
					NaN-mode		[[#{02000000} 25]]
				][
					compiler/throw-error ["invalid FPU option name:" option]
				]
				emit-op-imm32 #{e2000000} complement to integer! mask  ;-- AND r0, r0, #mask
				emit-op-imm32 #{e3800000} shift/left to integer! value bit	;-- OR r0, r0, LSL #value, #bit
			]
			masks [
				bit: switch/default mask [
					precision	[12]
					underflow	[11]
					overflow	[10]
					zero-divide [9]
					denormal	[15]
					invalid-op  [8]
				][
					compiler/throw-error ["invalid FPU mask name:" mask]
				]
				emit-op-imm32 #{e3800000} shift/left 1 bit  ;-- OR r0, r0, #mask
			]
		]
		emit-i32 #{eee10a10}						;-- FMXR FPSCR, r0
	]
	
	emit-fpu-update: emit-fpu-init: none			;-- not used for now
	
	emit-get-overflow: does [
		either last-math-op = '* [
			emit-i32 #{e3550000}					;-- CMP   r5, #0
			emit-i32 #{13a00001}					;-- MOVNE r0, #1
			emit-i32 #{03a00000}					;-- MOVE  r0, #0
		][
			emit-i32 #{63a00001}					;-- MOVVS r0, #1
			emit-i32 #{73a00000}					;-- MOVVC r0, #0
		]
	]
	
	emit-get-pc: does [
		emit-i32 #{e1a0000f}						;-- MOV r0, pc
	]

	emit-set-stack: func [value /frame][
		if verbose >= 3 [print [">>>emitting SET-STACK" mold value]]
		unless tag? value [emit-load value]
		either frame [
			emit-i32 #{e1a0b000}					;-- MOV fp, r0
		][
			emit-i32 #{e1a0d000}					;-- MOV sp, r0
		]
	]

	emit-get-stack: func [/frame][
		if verbose >= 3 [print ">>>emitting GET-STACK"]
		either frame [
			emit-i32 #{e1a0000b}					;-- MOV r0, fp
		][
			emit-i32 #{e1a0000d}					;-- MOV r0, sp
		]
	]

	emit-pop: does [
		if verbose >= 3 [print ">>>emitting POP"]
		emit-i32 #{e8bd0001}						;-- POP {r0}
	]

	emit-log-b: func [type][
		emit-i32 #{e16f0f10}						;-- CLZ r0, r0
		emit-i32 #{e260001f}						;-- RSB r0, r0, #31
	]

	emit-pop-float: func [idx [integer!] /with type [block!]][
		if with [width: select emitter/datatypes type/1]
		emit-float
			f-inc #{ed9d0b00} idx	;-- FLDD d<idx>, [sp]		; double precision float
			f-inc #{ed9d0a00} idx	;-- FLDS s<idx>, [sp]		; single precision float
			
		emit-i32 join #{e28dd0}		;-- ADD sp, sp, width		; adjust stack pointer
			to char! width
	]
	
	emit-push-float: func [idx [integer!] type [block!]][
		width: select emitter/datatypes type/1
		emit-i32 join #{e24dd0}		;-- SUB sp, sp, width		; adjust stack pointer
			to char! width
		emit-float
			f-inc #{ed8d0b00} idx	;-- FSTD [sp], d<idx>		; double precision float
			f-inc #{ed8d0a00} idx	;-- FSTS [sp], s<idx>		; single precision float
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
				type: either boxed [
					emit-casting boxed no
					boxed/type/1
				][
					first compiler/resolve-aliased compiler/get-variable-spec value
				]
				if find [pointer! c-string! struct!] type [ ;-- type casting trap
					type: 'logic!
				]
				switch type opcodes
			]
			tag! [
				if boxed [
					emit-casting boxed no
					compiler/last-type: boxed/type
				]
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
					type: compiler/resolve-path-type value
					compiler/last-type: type
					switch type/1 opcodes
				]
			]
		]
	]
	
	emit-boolean-switch: does [
		emit-i32 #{e3a00000}						;--		  MOV r0, #0	; (FALSE)
		emit-i32 #{ea000000}						;--		  B _exit
		emit-i32 #{e3a00001}						;--		  MOV r0, #1	; (TRUE)
													;-- _exit:
		reduce [4 12]								;-- [offset-TRUE offset-FALSE]
	]

	emit-load: func [
		value [char! logic! integer! word! string! path! paren! get-word! object! decimal!]
		/alt
		/with cast [object!]
		/local type offset spec original opcode
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
			decimal! [
				either all [cast cast/type/1 = 'float32!][
					emit-load-imm32 to integer! IEEE-754/to-binary32 value
				][
					spec: emitter/store-value none value [float!]
					pools/collect/spec/with 0 spec/2 #{e59f3000}	;-- LDR r3, [pc, #offset]
					if PIC? [emit-i32 #{e0833009}]					;-- ADD r3, sb
					emit-i32 #{e8930003} 							;-- LDM r3, {r0,r1}
				]
			]
			word! [
				type: compiler/get-variable-spec value
				case [
					find [float! float64!] type/1 [
						emit-variable-poly value
							#{e8900003} 				;-- LDM r0, {r0,r1}		; global
							none
							#{e59b0000}					;-- LDR r0, [fp, #[-]n]	; local, low bits @@ test!!

						if offset: emitter/local-offset? value [
							emit-load-local #{e59b1000} offset + 4	;-- LDR r1, [fp, #[-]n+4]	; local, high bits
						]
					]
					all [
						offset: emitter/local-offset? value
						'value = last select compiler/locals value
					][									;-- struct on stack case
						either 255 < abs offset [
							emit-load-imm32/reg offset 4
							emit-i32 pick [
								#{e04b0004}				;-- SUB r0, fp, r4	; local, 32-bit displacement
								#{e08b0004}				;-- ADD r0, fp, r4	; arg, 32-bit displacement
							] offset < 0
						][
							opcode: pick [#{e24b00} #{e28b00}] offset < 0
							emit-i32 join opcode to-bin8 abs offset	;-- ADD/SUB r0, fp, size ; 8-bit displacement
						]
					]
					'else [
						either alt [
							emit-variable-poly/alt value
								#{e5911000}				;-- LDR r1, [r1]		; global
								#{e7911009}				;-- LDR r1, [r1, sb]	; PIC
								#{e59b1000}				;-- LDR r1, [fp, #[-]n]	; local
						][
							emit-variable-poly value
								#{e5900000} 			;-- LDR r0, [r0]		; global
								#{e7900009}				;-- LDR r0, [r0, sb]	; PIC
								#{e59b0000}				;-- LDR r0, [fp, #[-]n]	; local
						]
					]
				]
			]
			get-word! [
				value: to word! original: value
				either any [
					all [
						spec: select compiler/functions value
						spec/2 = 'routine
					]
					all [
						emitter/local-offset? value
						'function! = first compiler/get-type value
					]
				][
					either alt [
						emit-variable-poly/alt value
							#{e5911000}				;-- LDR r1, [r1]		; global
							#{e7911009}				;-- LDR r1, [r1, sb]	; PIC
							#{e59b1000}				;-- LDR r1, [fp, #[-]n]	; local
					][
						emit-variable-poly value
							#{e5900000} 			;-- LDR r0, [r0]		; global
							#{e7900009}				;-- LDR r0, [r0, sb]	; PIC
							#{e59b0000}				;-- LDR r0, [fp, #[-]n]	; local
					]
				][
					either offset: emitter/local-offset? value [
						emit-i32 either negative? offset [
							#{e24b00}					;-- SUB r0, fp, n
						][
							#{e28b00}					;-- ADD r0, fp, n
						]
						emit-i32 to-bin8 abs offset
					][
						pools/collect/spec 0 original
						if PIC? [emit-i32 #{e0800009}]	;-- ADD r0, sb
					]
				]
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
					either alt [
						emit-load/alt/with value/data value
					][
						emit-load/with value/data value
					]
					set-width value
				]
			]
		]
	]
	
	emit-store: func [
		name [word!] value [char! logic! integer! word! string! paren! tag! get-word! decimal!]
		spec [block! none!]
		/by-value slots [integer!]
		/local store-qword store-word store-byte type opcode
	][
		if verbose >= 3 [print [">>>storing" mold name mold value]]
		if value = <last> [value: 'last]			;-- force word! code path in switch block
		if logic? value [value: to integer! value]	;-- TRUE -> 1, FALSE -> 0

		store-qword: [
			emit-variable-64 name
				#{e8820003}							;-- STM r2, {r0,r1}			; global, low + high
				#{e58b0000}							;-- STR r0, [fp, #[-]n]		; local, low bits
				#{e58b1000}							;-- STR r1, [fp, #[-]n]		; local, high bits
		]
		store-word: [
			emit-variable/alt name
				#{e5010000}							;-- STR r0, [r1]			; global
				#{e7810009}							;-- STR r0, [r1, sb]		; PIC
				#{e58b0000}							;-- STR r0, [fp, #[-]n]		; local
		]
		store-byte: [
			emit-variable/alt name
				#{e5410000}							;-- STRB r0, [r1]			; global
				#{e7c10009}							;-- STRB r0, [r1, sb]		; PIC
				#{e5cb0000}							;-- STRB r0, [fp, #[-]n]	; local
		]

		switch type?/word value [
			char! [
				do store-byte
			]
			integer! [
				do store-word
			]
			decimal! [
				type: compiler/get-variable-spec name
				either type/1 = 'float32! [
					do store-word
				][
					do store-qword
				]
			]
			word! [
				either by-value [
					if slots <= 2 [				 	;-- if > 2, copied already, do nothing
						either offset: emitter/local-offset? name [
							if slots = 2 [
								set-width/type last spec/2
								opcode: pick [#{e58b1000} #{e50b1000}] offset > 0
								emit-poly/with opcode abs offset + 4 ;-- STR r1, [fp, #[-]n]
							]
							set-width/type spec/2/2
							opcode: pick [#{e58b0000} #{e50b0000}] offset > 0
							emit-poly/with opcode abs offset	;-- STR r0, [fp, #[-]n]
						][
							emit-variable name
								#{e5933000}			;-- LDR r3, [r3]		; global
								#{e7933009}			;-- LDR r3, [r3, sb]	; PIC
								#{e59b3000}			;-- LDR r3, [fp, #[-]n]	; local
								
							if slots = 2 [
								set-width/type last spec/2
								emit-poly #{e5831004} ;-- STR r1, [r3,#4]
							]
							set-width/type spec/2/2
							emit-poly #{e5830000}	;-- STR r0, [r3]
						]
					]
				][
					set-width name
					switch width [
						1 [do store-byte]
						4 [do store-word]
						8 [do store-qword]
					]
				]
			]
			get-word! [
				unless emitter/local-offset? to word! value [
					pools/collect/spec 0 value
					if PIC? [emit-i32 #{e0800009}]	;-- ADD r0, sb
				]
				do store-word
			]
			string! paren! [
				if spec [emit-load-literal-ptr spec/2]
				do store-word
			]
		]
	]
	
	emit-init-path: func [name [word! get-word!]][
		emit-load-symbol to word! name
	]

	emit-access-path: func [
		path [path! set-path!] spec [block! none!] /short /local offset type saved name
	][
		if verbose >= 3 [print [">>>accessing path:" mold path]]

		unless spec [
			name: to word! path/1
			spec: second compiler/resolve-type name
			emit-load name
		]
		if short [return spec]

		saved: width
		type: compiler/resolve-type/with path/2 spec
		set-width/type type/1						;-- adjust operations width to member value size

		offset: emitter/member-offset? spec path/2
		
		either any [
			all [type/1 = 'struct! 'value = last spec/(path/2)]
			all [
				get-word? first head path
				tail? skip path 2
			]
		][
			if offset <> 0 [
				emit-op-imm32 #{e2800000} offset	  ;-- ADD r0, r0, #offset
			]
		][
			if width = 8 [							  ;-- 64-bit value case
				emit-poly/with #{e5901000} offset + 4 ;-- LDR r1, [r0, offset+4]	; high bits
			]
			emit-poly/with #{e5900000} offset		  ;-- LDR[B] r0, [r0, offset]
		]
		width: saved
	]
	
	emit-load-index: func [idx [word!]][
		unless compiler/local-variable? idx [idx: compiler/resolve-ns idx]
		emit-variable idx
			#{e5933000}								;-- LDR r3, [r3]		; global
			#{e7933009}								;-- LDR r3, [r3, sb]	; PIC
			#{e59b3000}								;-- LDR r3, [fp, #[-]n]	; local
		emit-i32 #{e2433001}						;-- SUB r3, r3, #1		; one-based index
	]

	emit-c-string-path: func [path [path! set-path!] parent [block! none!] /local opcodes idx][
		unless parent [emit-init-path path/1]
		opcodes: pick [[							;-- store path opcodes --
			#{e5402000}								;-- STRB r2, [r0]		; first
			#{e7c02003}								;-- STRB r2, [r0, r3] 	; nth | variable index
		][											;-- load path opcodes --
			#{e5500000}								;-- LDRB r0, [r0]		; first
			#{e7d00003}								;-- LDRB r0, [r0, r3]	; nth | variable index
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
			emit-i32 opcodes/2
		]
	]
	
	emit-pointer-path: func [
		path [path! set-path!] parent [block! none!] /local opcodes idx type scale
	][
		opcodes: pick [[							;-- store path opcodes --
			#{e5002000}								;-- STR[B] r2, [r0]
			#{e7802003}								;-- STR[B] r2, [r0, r3]
			#{e0822003}								;-- ADD r2, r2, r3
			#{e8820003}								;-- STM r2, {r0,r1}
		][											;-- load path opcodes --
			#{e5900000}								;-- LDR[B] r0, [r0]
			#{e7900003}								;-- LDR[B] r0, [r0, r3]
			#{e0800003}								;-- ADD r0, r0, r3
			#{e8900003} 							;-- LDM r0, {r0,r1}
		]] set-path? path

		type: either parent [
			compiler/resolve-type/with path/1 parent
		][
			emit-init-path path/1
			compiler/resolve-type path/1
		]
		set-width/type type/2/1						;-- adjust operations width to pointed value size
		idx: either path/2 = 'value [1][path/2]
		scale: emitter/size-of? type/2/1

		if all [set-path? path not parent width = 8][
			emit-swap-regs/alt
		]

		either integer? idx [
			either zero? idx: idx - 1 [				;-- indexes are one-based
				either width = 8 [
					emit-i32 opcodes/4
				][
					emit-poly opcodes/1
				]
			][
				emit-load-imm32/reg idx * scale 3	;-- LDR r3, #idx
				either width = 8 [
					emit-i32 opcodes/3
					emit-i32 opcodes/4
				][
					emit-poly opcodes/2
				]
			]
		][
			emit-load-index idx
			if scale > 1 [
				emit-i32 #{e1a03003}				;-- LSL r3, r3, #log2(scale)
					or debase/base to-hex shift/left power-of-2? scale 7 16
			]
			either width = 8 [
				emit-i32 opcodes/3
				emit-i32 opcodes/4
			][
				emit-poly opcodes/2
			]
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
	
	emit-store-path: func [
		path [set-path!] type [word!] value parent [block! none!]
		/local idx offset size slots
	][
		if verbose >= 3 [print [">>>storing path:" mold path mold value]]
		
		size: emitter/size-of? compiler/get-type value
													;-- @@ separate 64/32-bit conventions, too messy...
		either value = <last> [
			if 'value = last compiler/last-type [
				slots: emitter/struct-slots? compiler/last-type
				if slots > 2  [exit]				;-- big struct by value do not need post-processing
				emit-i32 #{e1a02000}				;-- MOV r2, r0
				unless parent [parent: emit-access-path/short path parent]
				type: compiler/resolve-type/with path/2 parent
				offset: emitter/member-offset? parent path/2
				
				case [
					all [type/1 = 'struct! 'value = last parent/(path/2)][
						if offset <> 0 [
							emit-op-imm32 #{e2800000} offset ;-- ADD r0, r0, #offset
						]
					]
					offset < 255 [
						emit-i32 join #{e59000} 	;-- LDR r0, [r0, #offset]	; 8-bit disp
							to-bin8 offset
					]
					'else [
						emit-load-imm32/reg offset 4
						emit-i32 #{e7900004}		;-- LDR r0, [r0, r4]	; 32-bit displacement
					]
				]
				if slots = 2 [
					set-width/type last type/2
					emit-poly #{e5801004}			;-- STR r1, [r0,#4]		; r1 = 2nd struct member
				]
				set-width/type type/2/2
				emit-poly #{e5802000}				;-- STR r2, [r0]		; r1 = 1st struct member
			]
		][
			if parent [emit-i32 #{e1a02000}]		;-- MOV r2, r0		; save value/address
			emit-load value							; @@ generates duplicate value loading sometimes
			all [
				object? value
				not all [decimal? value/data 'float32! = value/type/1]
				emit-casting value no
			]
			if all [not parent size = 8][
				emit-i32 #{e1a02000}				;-- MOV r2, r0		; save value/address
			]
			if size <> 8 [emit-swap-regs/alt]		;-- save value/restore address
		]

		switch type [
			c-string! [emit-c-string-path path parent]
			pointer!  [emit-pointer-path  path parent]
			struct!   [
				unless parent [
					parent: emit-access-path/short path parent
					if size = 8 [emit-swap-regs/alt] ;-- save value/restore address
				]
				type: compiler/resolve-type/with path/2 parent
				set-width/type type/1				;-- adjust operations width to member value size
				offset: emitter/member-offset? parent path/2

				either zero? offset [
					either width = 8 [
						emit-i32 #{e8820003}		;-- STM r2, {r0,r1}		; r2 = address
					][
						emit-poly #{e5002000}		;-- STR r2, [r0]		; r2 = value
					]
				][
					emit-load-imm32/reg offset 3
					either width = 8 [
						emit-i32 #{e0822003}		;-- ADD r2, r2, r3
						emit-i32 #{e8820003}		;-- STM r2, {r0,r1}		; r2 = address
					][
						emit-poly #{e7802003}		;-- STR r2, [r0, r3]	; r2 = value
					]
				]
			]
		]
	]
	
	emit-start-loop: does [
		emit-i32 #{e92d0001}						;-- PUSH {r0}
	]

	emit-end-loop: does [
		emit-i32 #{e8bd0001}						;-- POP {r0}
		emit-i32 #{e2500001}		 				;-- SUBS r0, r0, #1	; update Z flag
	]
	
	patch-jump-back: func [buffer [binary!] offset [integer!]][
		change 
			at buffer offset
			reverse to-bin24 shift negate offset + 4 2
	]
	
	patch-jump-point: func [buffer [binary!] ptr [integer!] exit-point [integer!]][
		change 
			at buffer ptr
			reverse to-bin24 shift exit-point - ptr - (2 * branch-offset-size) 2
	]
	
	emit-jump-point: func [type [block!]][
		if verbose >= 3 [print ">>>emitting jump point"]
		emit-reloc-addr type
		emit-i32 #{ea000000}						;-- B <disp>
	]
	
	emit-branch: func [
		code 	[binary!]
		op 		[word! block! logic! none!]
		offset  [integer! none!]
		/back?
		/local distance opcode jmp
	][
		distance: (length? code) - (any [offset 0]) - 4	;-- offset from the code's head
		if back? [distance: negate distance + 12]	;-- 8 (PC offset) + one instruction
		
		op: either not none? op [					;-- explicitly test for none
			op: case [
				block? op [							;-- [cc] => keep
					op: op/1
					either logic? op [pick [= <>] op][op]	;-- [logic!] or [cc]
				]
				logic? op [pick [= <>] op]			;-- test for TRUE/FALSE
				'else 	  [opposite? op]			;-- 'cc => invert condition
			]
			either '- = third op: find conditions op [	;-- lookup the code for the condition
				op/2								;-- condition defined only for signed
			][
				pick op pick [2 3] signed?			;-- choose code between signed and unsigned
			]
		][
			#{e0}									;-- unconditional jump
		]
		unless back? [
			if same? head code emitter/code-buf [
				pools/insert-jmp-point emitter/tail-ptr distance	;-- update code indexes affected by the insertion
			]
		]
		opcode: reverse rejoin [
			op or #{0a} to-bin24 shift distance 2
		]		
		insert any [all [back? tail code] code] opcode
		4											;-- opcode length
	]
	
	emit-copy-mem: func [slots [integer!] /local bits][ ;-- r0: src, ip: dst, 32-bit slots
		either slots <= 8 [							;-- 8 is max number of regs usable for the copy
			bits: skip debase/base to-hex shift/logical 1020 (8 - slots) 16 2
			bits: bits and #{FFFC}
			emit-i32 join #{e890} bits				;-- LDM r0, {r2,rN}
			emit-i32 join #{e88c} bits				;-- STM <dst>, {r2,rN}
		][
			emit-i32 #{e1a03000}					;-- MOV r3, r0		; src
			emit-load-imm32/reg slots 5				;-- MOV r5, <size>
			emit-i32 #{e4931001}					;-- .loop:	LDR r1, [r3!], #1
			emit-i32 #{e48c1001}					;--			STR r1, [ip!], #1
			emit-i32 #{e2555001}					;-- 		SUBS r5, r5, 1
			emit-i32 #{1afffffb}					;-- 		BNE .loop
		]
	]
	
	emit-push-struct: func [slots [integer!]][		;-- number of 32-bit slots
		emit-reserve-stack slots
		emit-i32 #{e1a0c00d}						;-- MOV ip, sp	; dst
		emit-copy-mem slots
	]

	emit-push: func [
		value [char! logic! integer! word! block! string! tag! path! get-word! object! decimal!]
		/with cast [object!]
		/cdecl
		/local push-last push-last64 spec type conv-int-float? float?
	][
		if verbose >= 3 [print [">>>pushing" mold value]]
		if block? value [value: <last>]
		
		push-last:  [emit-i32 #{e92d0001}]			;-- PUSH {r0}
		push-last64: [emit-i32 #{e92d0003}]			;-- PUSH {r0,r1}

		switch type?/word value [
			tag! [									;-- == <last>
				type: either cast [cast/type][compiler/last-type]
				either value = <last> [
					do either find [float! float64!] type/1 [
						push-last64
					][
						push-last
					]
				][
					either value = <ret-ptr> [
						emit-op-imm32 #{e28b0000} args-offset ;-- ADD r0, fp, <args-top>
					][
						emit-op-imm32 #{e28d0000} to integer! value ;-- ADD r0, sp, <offset>
					]
					do push-last
				]
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
				emit-load-imm32/reg value 3
				emit-i32 #{e92d0008}				;-- PUSH {r3}
			]
			decimal! [
				either all [cast cast/type/1 = 'float32! not cdecl][
					emit-load-imm32 to integer! IEEE-754/to-binary32 value
					do push-last
				][
					spec: emitter/store-value none value [float!]
					pools/collect/spec/with 0 spec/2 #{e59f2000}	;-- LDR r2, [pc, #offset]
					if PIC? [emit-i32 #{e0822009}]	;-- ADD r2, sb
					emit-i32 #{e8920003} 			;-- LDM r2, {r0,r1}
					emit-i32 #{e92d0003}			;-- PUSH {r0,r1}
				]
			]
			word! [
				type: compiler/get-variable-spec value
				case [
					all [
						'value = last type
						offset: emitter/local-offset? value
					][
						emit-load to get-word! value
						do push-last				;-- PUSH &value
					]
					any [
						find [float! float64!] type/1 
						all [cast find [float! float64!] cast/type/1]
					][
						emit-load value
						do push-last64
					]
					'else [
						emit-load-symbol value
						do push-last
					]
				]
			]
			get-word! [
				emit-load value
				do push-last						;-- PUSH &value
			]
			string! [
				emit-load-literal [c-string!] value
				do push-last						;-- PUSH value
			]
			path! [
				emitter/access-path value none
				compiler/last-type: either cast [
					emit-casting cast no
					cast/type
				][
					compiler/resolve-path-type value
				]
				emit-push <last>
			]
			object! [
				type: compiler/get-type value/data
				float?: find [float! float64! float32!] value/type/1
				
				conv-int-float?: any [
					all [float? type/1 = 'integer!]
					all [
						find [float! float64! float32!] type/1
						value/type/1 = 'integer!
					]
				]
				all [
					conv-int-float?
					not find [block! tag!] type?/word value/data
					emit-load value/data
				]
				unless all [float? decimal? value/data][
					emit-casting value no
				]

				either conv-int-float? [
					either find [float! float64!] value/type/1 [
						do push-last64
					][
						do push-last
					]
				][
					either cdecl [
						emit-push/with/cdecl value/data value
					][
						emit-push/with value/data value
					]
				]
			]
		]
	]
	
	emit-bitshift-op: func [name [word!] a [word!] b [word!] args [block!] /local c value][
		switch b [
			ref [
				emit-variable args/2
					#{e5d03000}						;-- LDRB r3, [r0]			; global
					#{e7d03009}						;-- LDRB r3, [r0, sb]		; PIC
					#{e5db3000}						;-- LDRB r3, [fp, #[-]n]	; local
			]
			reg [emit-i32 #{e1a03001}]				;-- MOV r3, r1
		]
		opcode: select [
			<<  [
				#{e1a00000}							;-- LSL r0, r0, #b
				#{e1a00310}							;-- LSL r0, r0, r3
			]
			>>  [
				#{e1a00040}							;-- ASR r0, r0, #b
				#{e1a00350}							;-- ASR r0, r0, r3
			]
			-** [
				#{e1a00020}							;-- LSR r0, r0, #b
				#{e1a00330}							;-- LSR r0, r0, r3
			]
		] name
	
		emit-i32 either b = 'imm [
			opcode/1 or to-shift-imm args/2
		][
			opcode/2
		]
		
		if b = 'imm [
			c: select [1 7 2 15 4 31] width
			value: compiler/unbox args/2		
			unless all [0 <= value value <= c][		
				compiler/backtrack name
				compiler/throw-error rejoin [
					"a value in 0-" c " range is required for this shift operation"
				]
			]
		]
	]
	
	emit-bitwise-op: func [name [word!] a [word!] b [word!] args [block!] /local code][		
		code: select [
			and [#{e0000001}]						;-- AND r0, r0, r1	; commutable op
			or  [#{e1800001}]						;-- OR  r0, r0, r1	; commutable op
			xor [#{e0200001}]						;-- EOR r0, r0, r1	; commutable op
		] name

		switch b [
			imm [
				emit-load-imm32/reg compiler/unbox args/2 1	;-- MOV r1, #value
				emit-i32 code						;-- <OP> r0, r0, r1
			]
			ref [
				emit-load/alt args/2
				if object? args/2 [emit-casting args/2 yes]
				emit-i32 code
			]
			reg [emit-i32 code]						;-- <OP> r0, r0, r1		; commutable op
		]
	]
	
	emit-comparison-op: func [name [word!] a [word!] b [word!] args [block!] /local op-poly arg2][
		op-poly: [
			switch width [
				1 [
					emit-i32 #{e1a03c00}			;-- MOV r3, r0, LSL #24
					emit-i32 #{e1533c01}			;-- CMP r3, r1, LSL #24
				]
				;2 []								;-- 16-bit not supported
				4 [emit-i32 #{e1500001}]			;-- CMP r0, r1		; not commutable op
			]
		]		
		arg2: either object? args/2 [compiler/cast args/2][args/2]
		
		switch b [
			imm [
				switch width [
					1 [
						emit-i32 join #{e35000}		;-- CMP r0, #imm8
							to char! arg2
					]
					;2 []							;-- 16-bit not supported
					4 [
						emit-load-imm32/reg arg2 1	;-- r1: arg2
						emit-i32 #{e1500001}		;-- CMP r0, r1		; not commutable op
					]
				]
			]
			ref [
				emit-i32 #{e92d0001}				;-- PUSH {r0}
				emit-load/alt args/2
				if object? args/2 [emit-casting args/2 yes]
				emit-pop
				do op-poly
			]
			reg [
				do op-poly
			]
		]
	]
	
	emit-math-op: func [
		name [word!] a [word!] b [word!] args [block!]
		/local mod? scale c type arg2 op-poly
	][
		;-- r0 = a, r1 = b
		if find mod-rem-op name [					;-- work around unaccepted '// and '%
			mod?: select mod-rem-func name			;-- convert operators to words (easier to handle)
			name: first [/]							;-- work around unaccepted '/ 
		]
		arg2: compiler/unbox args/2

		if all [
			find [+ -] name							;-- pointer arithmetic only allowed for + & -
			type: compiler/resolve-aliased compiler/resolve-expr-type args/1
			not compiler/any-pointer? compiler/resolve-expr-type args/2	;-- no scaling if both operands are pointers		
			scale: switch type/1 [
				pointer! [emitter/size-of? type/2/1]		  ;-- scale factor: size of pointed value
				struct!  [emitter/member-offset? type/2 none] ;-- scale factor: total size of the struct
			]
			scale > 1
		][
			either compiler/literal? arg2 [
				arg2: arg2 * scale					;-- 'b is a literal, so scale it directly
			][
				either b = 'reg [
					emit-swap-regs					;-- swap r0, r1		; put operands in right order
					emit-i32 #{e92d0002}			;-- PUSH {r1}		; save r1 (a) from corruption
				][									;-- 'b will now be stored in reg, so save 'a
					emit-i32 #{e92d0001}			;-- PUSH {r0}		; save r0 (a) from corruption
					emit-move-alt					;-- MOV r1, r0
					emit-load args/2
				]
				emit-math-op '* 'reg 'imm reduce [arg2 scale]	;@@ refactor that using barrel shifter
				emit-i32 #{e8bd0002}				;-- POP {r1}		; restore pointer in r1
				if name = '- [emit-swap-regs]		;-- swap r0, r1		; put operands in right order
				b: 'reg
			]
		]
		;-- r0 = a, r1 = b
		switch last-math-op: name [
			+ [
				op-poly: [emit-i32 #{e0900001}]		;-- ADDS r0, r0, r1	; commutable op
				switch b [
					imm [
						emit-op-imm32 #{e2900000} arg2 ;-- ADDS r0, r0, #value
					]
					ref [
						emit-load/alt arg2
						do op-poly
					]
					reg [do op-poly]
				]
			]
			- [
				op-poly: [emit-i32 #{e0500001}] 	;-- SUBS r0, r0, r1	; not commutable op
				switch b [
					imm [
						emit-op-imm32 #{e2500000} arg2 ;-- SUBS r0, r0, #value
					]
					ref [
						emit-load/alt arg2
						do op-poly
					]
					reg [do op-poly]
				]
			]
			* [
				op-poly: [emit-i32 #{e0d50091}]		;-- SMULLS r0, r5, r0, r1 ; commutable op
				switch b [
					imm [
						either all [
							not zero? arg2
							c: power-of-2? arg2		;-- trivial optimization for b=2^n
						][
							emit-i32 #{e1b00000}	;-- LSLS r0, r0, #log2(b)
								or to-shift-imm c
						][
							emit-load-imm32/reg args/2 1	;-- MOV r1, #value
							do op-poly
						]
					]
					ref [
						emit-i32 #{e92d0002}		;-- PUSH {r1}	; save r1 from corruption
						emit-load/alt args/2
						do op-poly
						emit-i32 #{e8bd0002}		;-- POP {r1}
					]
					reg [do op-poly]
				]
			]
			/ [
				switch b [
					imm [
						emit-i32 #{e92d0002}		;-- PUSH {r1}	; save r1 from corruption
						emit-load-imm32/reg args/2 1 ;-- MOV r1, #value
					]
					ref [
						emit-i32 #{e92d0002}		;-- PUSH {r1}	; save r1 from corruption
						emit-load/alt args/2
					]
				]
				call-divide mod?
				
				if any [							;-- in case r1 was saved on stack
					all [b = 'imm any [mod? not c]]
					b = 'ref
				][
					emit-i32 #{e8bd0002}			;-- POP {r1}
				]
			]
		]
	]
	
	emit-integer-operation: func [name [word!] args [block!] /local a b sorted? left right][
		if verbose >= 3 [print [">>>inlining integer op:" mold name mold args]]

		set-width args/1							;-- set reg/mem access width
		set [a b] get-arguments-class args
		last-saved?: no								;-- reset flag

		;-- First operand processing
		left:  compiler/unbox args/1
		right: compiler/unbox args/2

		switch to path! reduce [a b] [
			imm/imm	[emit-load-imm32 left]			;-- MOV r0, a
			imm/ref [emit-load args/1]				;-- r0 = a
			imm/reg [								;-- r0 = b
				if path? right [
					emit-load args/2				;-- late path loading
				]
				emit-move-alt						;-- MOV r1, r0
				emit-load-imm32 left				;-- MOV r0, a		; r0 = a, r1 = b
			]
			ref/imm [emit-load args/1]
			ref/ref [emit-load args/1]
			ref/reg [								;-- r0 = b
				if path? right [
					emit-load args/2				;-- late path loading
				]
				emit-move-alt						;-- MOV r1, r0
				emit-load args/1					;-- r0 = a, r1 = b
			]
			reg/imm [								;-- r0 = a (or r1 = a if last-saved)
				if path? left [
					emit-load args/1				;-- late path loading
				]
				if last-saved? [emit-swap-regs]		;-- swap r0, r1	; r0 = a
			]
			reg/ref [								;-- r0 = a (or r1 = a if last-saved)
				if path? left [
					emit-load args/1				;-- late path loading
				]
				if last-saved? [emit-swap-regs]		;-- swap r0, r1	; r0 = a
			]
			reg/reg [								;-- r0 = b, r1 = a
				if path? left [
					if any [
						args/2 = <last>				;-- inlined statement
						block? right				;-- function call
					][				 				;-- r1 = b
						emit-swap-regs				;-- swap r0, r1
						sorted?: yes				;-- r0 = a, r1 = b
					]
					emit-load args/1				;-- late path loading
				]
				if path? right [
					emit-swap-regs					;-- swap r0, r1	; r0 = b, r1 = a
					emit-load args/2
				]
				unless sorted? [emit-swap-regs]		;-- swap r0, r1	; r0 = a, r1 = b
			]
		]
		if object? args/1 [emit-casting args/1 no]	;-- do runtime conversion if required

		;-- Operator and second operand processing
		unless all [
			object? args/2
			find [imm reg] b
			args/2/type/1 <> 'integer!				;-- skip explicit casting to integer! (implicit)
		][
			implicit-cast right
		]
		case [
			find comparison-op name [emit-comparison-op name a b args]
			find math-op	   name	[emit-math-op		name a b args]
			find bitwise-op	   name	[emit-bitwise-op	name a b args]
			find bitshift-op   name [emit-bitshift-op   name a b args]
		]
	]
	
	emit-vfp-casting: func [value [object!] /right [logic!] /local type][
		type: compiler/get-type value/data	
		case [
			all [find [float! float64!] value/type/1 type/1 = 'integer!][
				either right [
					emit-i32 #{eeb81bc1}			;-- FSITOD d1, s2
				][
					emit-i32 #{eeb80bc0}			;-- FSITOD d0, s0
				]
			]
			all [value/type/1 = 'float32! type/1 = 'integer!][
				either right [
					emit-i32 #{eeb81ac1}			;-- FSITOS s2, s2
				][
					emit-i32 #{eeb80ac0}			;-- FSITOS s0, s0
				]
			]
			all [find [float! float64!] value/type/1 type/1 = 'float32!][
				either right [
					emit-i32 #{eeb71ac1}			;-- FCVTDS d1, s2
				][
					emit-i32 #{eeb70ac0}			;-- FCVTDS d0, s0
				]
			]
			all [value/type/1 = 'float32! find [float! float64!] type/1][
				either right [
					emit-i32 #{eeb71bc1}			;-- FCVTSD s2, d1
				][
					emit-i32 #{eeb70bc0}			;-- FCVTSD s0, d0
				]
			]
		]
	]

	emit-float-operation: func [name [word!] args [block!] /local a b left right spec size saved][
		if verbose >= 3 [print [">>>inlining float op:" mold name mold args]]
		
		set [a b] get-arguments-class args

		;-- First operand processing
		left:  compiler/unbox args/1
		right: compiler/unbox args/2
		set-width args/1
		saved: width

		switch a [									;-- load left operand in d0 or s0
			imm [
				either width = 4 [
					emit-load-imm32/reg to integer! IEEE-754/to-binary32 left 3
					emit-i32 #{ee003a10}			;-- FMSR s0, r3
				][
					spec: emitter/store-value none args/1 compiler/get-type args/1
					pools/collect/spec/with 0 spec/2 #{e59f3000}	;-- LDR r3, [pc, #offset]
					if PIC? [emit-i32 #{e0833009}]	;-- ADD r3, sb
					emit-i32 #{ed930b00}			;-- FLDD d0, [r3]
				]
			]
			ref [
				set-width left
				either width = 8 [
					emit-float-variable args/1
						#{ed930b00} 				;-- FLDD d0, [r3]			; global
						#{ed9b0b00}					;-- FLDD d0, [fp, #[-]n]	; local
				][
					emit-float-variable args/1
						#{ed930a00} 				;-- FLDS s0, [r3]			; global
						#{ed9b0a00}					;-- FLDS s0, [fp, #[-]n]	; local
				]
				if object? args/1 [emit-vfp-casting args/1]
			]
			reg [
				if block? left [
					either b = 'reg [
						emit-pop-float 0
					][
					 	emit-float 
					 		#{ec410b10}				;-- FMDRR d0, r1, r0
					 		#{ee000a10}				;-- FMSR s0, r0
					]
				]
				if path? left [
					if all [b = 'reg not path? right][
						emit-push <last>			;-- push right result on stack
					]
					emit-load args/1				;-- late path loading
					emit-float 
						#{ec410b10}					;-- FMDRR d0, r1, r0
						#{ee000a10}					;-- FMSR s0, r0
				]
				if object? args/1 [emit-vfp-casting args/1]
			]
		]
	
		switch b [									;-- load right operand in d1 or s2
			imm [
				set-width args/2
				either width = 4 [
					emit-load-imm32/reg to integer! IEEE-754/to-binary32 right 3
					emit-i32 #{ee013a10}			;-- FMSR s2, r3
				][
					spec: emitter/store-value none args/2 compiler/get-type args/2
					pools/collect/spec/with 0 spec/2 #{e59f3000}	;-- LDR r3, [pc, #offset]
					if PIC? [emit-i32 #{e0833009}]	;-- ADD r3, sb
					emit-i32 #{ed931b00}			;-- FLDD d1, [r3]
				]
			]
			ref [
				set-width right
				either width = 8 [
					emit-float-variable args/2
						#{ed931b00} 				;-- FLDD d1, [r3]			; global
						#{ed9b1b00}					;-- FLDD d1, [fp, #[-]n]	; local
				][
					emit-float-variable args/2
						#{ed931a00} 				;-- FLDS s2, [r3]			; global
						#{ed9b1a00}					;-- FLDS s2, [fp, #[-]n]	; local
				]
				if object? args/2 [emit-vfp-casting/right args/2]
			]
			reg [
				set-width right
				if path? right [
					emit-load args/2
					emit-float 
						#{ec410b11}					;-- FMDRR d1, r1, r0
						#{ee010a10}					;-- FMSR s2, r0
				]
				if block? right [
					if path? left [emit-pop-float 0]
					emit-float 
						#{ec410b11}					;-- FMDRR d1, r1, r0
						#{ee010a10}					;-- FMSR s2, r0
				]
				if object? args/2 [emit-vfp-casting/right args/2]
			]
		]
		width: saved
		
		if any [
			all [b = 'reg all [path? left block? right]]
			;all [a = 'reg b = 'ref path? left]
		][											;-- exchange s0/s2 or d0/d1
			either width = 4 [
				emit-i32 #{eeb02a40}				;-- FCPYS  s4, s0
				emit-i32 #{eeb00a41}				;-- FCPYS  s0, s2
				emit-i32 #{eeb01a42}				;-- FCPYS  s2, s4
			][
				emit-i32 #{eeb02b40}				;-- FCPYD  d2, d0
				emit-i32 #{eeb00b41}				;-- FCPYD  d0, d1
				emit-i32 #{eeb01b42}				;-- FCPYD  d1, d2
			]
		]
		
		case [
			find comparison-op name [
				emit-float 							;-- load immediate from data segment
					#{eeb40b41}						;-- FCMPD d0, d1
					#{eeb40a41}						;-- FCMPS s0, s2
				emit-i32 #{eef1fa10}				;-- FMSTAT				; transfer flags to CPU
			]
			find math-op name [
				either width = 8 [
					either find mod-rem-op name [
						emit-i32 #{ee802b01}		;-- FDIVD  d2, d0, d1
						emit-i32 #{eebd4bc2}		;-- FTOSID s8, d2		; round towards 0
						emit-i32 #{eeb02b40}		;-- FCPYD  d2, d0		; d2 = dividend
						emit-i32 #{eeb80bc4}		;-- FSITOD d0, s8		; d0 = INT(q)
						emit-i32 #{ee002b41}		;-- FNMACD d2, d0, d1	; d2 = d2 - d0 * d1
					][
						emit-i32 switch name [		;-- double precision math
							+ [#{ee302b01}]			;-- FADDD d2, d0, d1
							- [#{ee302b41}]			;-- FSUBD d2, d0, d1
							* [#{ee202b01}]			;-- FMULD d2, d0, d1
							/ [#{ee802b01}]			;-- FDIVD d2, d0, d1
						]
					]
					emit-i32 #{ec510b12}			;-- FMRRD r0, r1, d2	; move result to CPU
				][
					either find mod-rem-op name [
						emit-i32 #{ee802a01}		;-- FDIVS  s4, s0, s2
						emit-i32 #{eebd4ac2}		;-- FTOSIS s8, s4		; round towards 0
						emit-i32 #{eeb02a40}		;-- FCPYS  s4, s0		; s4 = dividend
						emit-i32 #{eeb80ac4}		;-- FSITOS s0, s8		; s0 = INT(q)
						emit-i32 #{ee002a41}		;-- FNMACS s4, s0, s2	; s4 = s4 - s0 * s2
					][
						emit-i32 switch name [		;-- single precision math
							+ [#{ee302a01}]			;-- FADDS s4, s0, s2
							- [#{ee302a41}]			;-- FSUBS s4, s0, s2
							* [#{ee202a01}]			;-- FMULS s4, s0, s2
							/ [#{ee802a01}]			;-- FDIVS s4, s0, s2
						]
					]
					emit-i32 #{ee120a10}			;-- FMRS r0, s4			; move result to CPU
				]
			]
			true [
				compiler/throw-error "unsupported operation on floats"
			]
		]
	]
	
	emit-AAPCS-header: func [
		args [block!] fspec [block!] attribs [block! none!]
		/calc
		/local reg bits offset type size stk freg cconv types
	][
		either args/1 = #custom [
			unless calc [
				repeat reg min args/2/1 4 [
					emit-i32 #{e8bd00}				;-- POP {rn[,rn+1]}
					emit-i32 to char! shift/left 1 reg - 1
				]
			]
			stack-width * max 0 args/2/1 - 4		;-- return extra args on stack count
		][
			if issue? args/1 [args: args/2]
			reg: freg: stk: 0
			cconv: fspec/3
			types: fspec/4
			args: reverse copy args					;-- arguments are on stack in reverse order
			
			if block? types/1 [types: next types]
			
			if hidden-ptr? fspec [
				args: next args
				unless calc [emit-i32 #{e8bd0001}]	;-- POP {r0}
				reg: 1
			]

			foreach arg args [
				if arg <> #_ [						;-- bypass place-holder marker
					type: any [
						types/2
						compiler/get-type arg		;-- fallback for [variadic]
					]
					either all [
						compiler/job/ABI = 'hard-float
						find [float! float64! float32!] type/1
						any [none? attribs not find attribs 'variadic]	;-- 'typed is not using hf ABI
					][
						unless calc [emit-pop-float/with freg type]
						freg: freg + 1
					][
						foreach-member type [
							size: either all [
								cconv = 'cdecl
								type/1 = 'float32!
							][
								8					;-- promote to C double
							][
								emitter/size-of? type
							]
							either reg >= 4 [			;-- account for extra args on stack
								stk: stk + any [size 4] ;-- ANY: workaround special variables from start.reds
							][
								set [bits offset] either 8 = size [
									either reg <= 2 [
										if odd? reg [
											unless calc [emit-load-imm32/reg 0 1]
											reg: reg + 1 ;-- start 64-bit value on even register
										]
										[3 2]		;-- use 2 regs
									][
										stk: stk + 8
										[0 2]		;-- no space in regs to store a 64-bit value
									]
								][
									[1 1]			;-- use 1 reg
								]
								unless any [calc zero? bits][
									emit-i32 #{e8bd00}		;-- POP {rn[,rn+1]}
									emit-i32 to char! shift/left bits reg
								]
								reg: reg + offset
							]
						]
					]
					types: skip types 2
				]
			]
			stk										;-- return extra args on stack count
		]
	]
	
	emit-hf-return: func [spec [block!] /reverse /local type][
		if all [
			compiler/job/ABI = 'hard-float
			find [float! float64! float32!] type: select spec first [return:]
		][
			width: select emitter/datatypes type/1
			either reverse [
				emit-float
					#{ec410b10}						;-- FMDRR d0, r0, r1, d0
					#{ee000a10}						;-- FMSR s0, r0
			][
				emit-float
					#{ec510b10}						;-- FMRRD r0, r1, d0
					#{ee100a10}						;-- FMRS r0, s0
			]
		]
	]

	emit-call-syscall: func [args [block!] fspec [block!] attribs [block! none!] /local extra][	; @@ check if it needs stack alignment too
		extra: emit-AAPCS-header args fspec attribs
		emit-i32 #{e3a070}							;-- MOV r7, <syscall>
		emit-i32 to-bin8 last fspec
		emit-i32 #{ef000000}						;-- SVC 0		; @@ EABI syscall
		unless zero? extra [
			emit-op-imm32 #{e28dd000} extra			;-- ADD sp, sp, extra	; skip extra stack arguments
		]
		emit-hf-return fspec/4
	]
	
	emit-variadic-data: func [args [block!] /local total][
		emit-push call-arguments-size? args/2		;-- push arguments total size in bytes 
													;-- (required to clear stack on stdcall return)
		emit-i32 #{e28dc004}						;-- ADD ip, sp, #4	; skip last pushed value
		emit-i32 #{e92d1000}						;-- PUSH {ip}		; push arguments list pointer
		total: length? args/2
		if args/1 = #typed [total: total / 3]		;-- typed args have 3 components
		emit-push total								;-- push arguments count
	]
	
	emit-call-import: func [args [block!] fspec [block!] spec [block!] attribs [block! none!] /local extra type][
		if all [issue? args/1 args/1 <> #custom fspec/3 <> 'cdecl][
			emit-variadic-data args
		]
		extra: emit-AAPCS-header args fspec attribs
		pools/collect/spec/with 0 spec #{e59fc000}	;-- MOV ip, #(.data.rel.ro + symbol_offset)
		if PIC? [emit-i32 #{e08cc009}]				;-- ADD ip, sb
		emit-i32 #{e59cc000}						;-- LDR ip, [ip]
		emit-i32 #{e12fff3c}						;-- BLX ip
		unless zero? extra [						;-- _next:
			emit-op-imm32 #{e28dd000} extra			;-- ADD sp, sp, extra	; skip extra stack arguments
		]
		emit-hf-return fspec/4
	]
	
	emit-call-native: func [
		args [block!] fspec [block!] spec [block!] attribs [block! none!] /routine name [word!]
		/local extra cb?
	][
		either routine [							;-- test for function! pointer case
			if cb?: any [
				fspec/5 = 'callback
				all [attribs any [find attribs 'cdecl find attribs 'stdcall]]
			][
				extra: emit-AAPCS-header args fspec attribs
			]
			name: pick tail fspec -2
			
			emit-i32 #{e1a0c000}					;-- MOV r12, r0
			either all [
				'local = last fspec
				find form name slash 
			][
				emitter/access-path load form name none
			][
				emit-load-symbol name
			]
			emit-i32 #{e1a0a000}					;-- MOV r10, r0
			emit-i32 #{e1a0000c}					;-- MOV r0, r12
			emit-i32 #{e120003a}					;-- BLX r10
			if all [extra positive? extra][
				emit-op-imm32 #{e28dd000} extra		;-- ADD sp, sp, extra	; skip extra stack arguments
			]
			if cb? [emit-hf-return fspec/4]
		][
			if all [issue? args/1 fspec/3 <> 'cdecl][emit-variadic-data args]
			emit-reloc-addr spec/3
			emit-i32 #{eb000000}					;-- BL <disp>
		]
	]

	patch-call: func [code-buf rel-ptr dst-ptr] [
		;; @@ to-bin24
		change
			at code-buf rel-ptr
			copy/part to-bin32 shift (dst-ptr - rel-ptr - (2 * ptr-size)) 2 3
	]
	
	emit-argument: func [arg fspec [block!]][
		if arg = #_ [exit]							;-- place-holder, no code to emit
		
		either all [
			object? arg
			any [arg/type = 'logic! 'byte! = first compiler/get-type arg/data]
			not path? arg/data
		][
			unless block? arg [emit-load arg]		;-- block! means last value is already in r0 (func call)
			emit-casting arg no
			compiler/last-type: arg/type			;-- for inline unary functions
			emit-push <last>
		][
			if block? arg [arg: <last>]
			either all [
				fspec/3 = 'cdecl 
				compiler/find-attribute fspec/4 'variadic	;-- only for vararg C functions
			][
				emit-push/cdecl arg					;-- promote float32! to float!
			][
				emit-push arg
			]
		]
	]
	
	emit-stack-align: does [
		emit-i32 #{e1a0c00d}						;-- MOV ip, sp
		emit-i32 #{e3cdd007}						;-- BIC sp, sp, #7		; align sp to 8 bytes
		emit-i32 #{e1a0000c}						;-- MOV r0, ip
	]
	
	emit-stack-align-prolog: func [args [block!] fspec [block!] /local size tag blk][
		;-- EABI stack 8 bytes alignment: http://infocenter.arm.com/help/topic/com.arm.doc.ihi0046b/IHI0046B_ABI_Advisory_1.pdf
		; @@ to be optimized: infer stack alignment if possible, to avoid this overhead.
		
		emit-i32 #{e1a0c00d}						;-- MOV ip, sp
		emit-i32 #{e3cdd007}						;-- BIC sp, sp, #7		; align sp to 8 bytes
		if issue? tag: args/1 [args: args/2]
		size: max 16 emit-AAPCS-header/calc args fspec all [block? blk: fspec/4/1 blk]
		unless zero? size // 8 [emit-i32 #{e24dd004}] ;-- SUB sp, sp, #4	; ensure call will be 8-bytes aligned
		emit-i32 #{e92d5000}						;-- PUSH {ip,lr}		; save previous sp and lr value
	]

	emit-stack-align-epilog: func [args [block!]][
		emit-i32 #{e8bd5000}						;-- POP {ip,lr}			; use ip as replacement to sp
		emit-i32 #{e1a0d00c}						;-- MOV sp, ip			; to workaround SIGILLs on ARMv7
	]
	
	emit-throw: func [value [integer! word!] /thru][
		emit-load value
		unless thru [
			emit-i32 #{e1a0d00b}					;-- 		MOV sp, fp		; unwind 1st frame
			emit-i32 #{e8bd4800}					;-- 		POP {fp,lr}
		]
		emit-i32 #{e24bd004}						;-- _loop:	SUB sp, fp, #4
		emit-i32 #{e8bd0002}						;-- 		POP {r1} 		; get flag
		emit-i32 #{e1510000}						;-- 		CMP r1, r0
		emit-i32 #{38bd4800}						;-- 		POPLO {fp,lr} 	; unwind frame if r2 < r0
		emit-i32 #{3afffffa}						;-- 		BLO _loop		; next frame
		emit-i32 #{e1a02000}						;--			MOV r2, r0		; save r0

		emitter/access-path to set-path! 'system/thrown <last>
		emit-i32 #{e3710001}						;--			CMN r1, 1		; compare with 2's complement
		emit-i32 #{1a000003}						;--			BNE _next
		emit-load-local #{e59b1000} 0				;--			LDR r1, [fp, 0]
		emit-i32 #{e1510002}						;-- 		CMP r1, r2
		emit-load-local #{259b1000} 4				;--			LDRHS r1, [fp, 4]
		emit-i32 #{21a0f001}						;--			MOVHS pc, r1
		emit-load-local #{e59b1000} -8				;--	_next:	LDR r1, [fp, -8]
		emit-i32 #{e3510000}						;--			CMP r1, 0
		emit-i32 #{11a0f001}						;--			MOVNE pc, r1
		emit-i32 #{e35e0000}						;--			CMP lr, 0
		emit-i32 #{11a0f00e}						;--			MOVNE pc, lr
	]
	
	emit-open-catch: func [body-size [integer!] global? [logic!]][
		either global? [
			emit-op-imm32 #{e28f2000} body-size	+ 4	;-- ADD r2, pc, #value
			emit-i32 #{e58b2004}					;-- STR r2, [fp, 4]
			emit-i32 #{e58b0000}					;-- STR r0, [fp, 0]
			12
		][
			emit-i32 #{e50b0004}					;-- STR r0, [fp, -4]
			emit-op-imm32 #{e28f0000} body-size		;-- ADD r0, pc, #value
			emit-i32 #{e50b0008}					;-- STR r0, [fp, -8]
			12
		]
	]

	emit-close-catch: func [offset [integer!] global? [logic!] callback? [logic!]][
		either global? [
			emit-i32 #{e3a00000}					;-- MOV r0, 0
			emit-i32 #{e58b0000}					;-- STR r0, [fp, 0]
			emit-i32 #{e58b0004}					;-- STR r0, [fp, 4]
			emit-i32 #{e24bd008}					;-- SUB sp, fp, 8
		][
			emit-i32 #{e3a00000}					;-- MOV r0, 0
			emit-i32 #{e50b0004}					;-- STR r0, [fp, -4]
			emit-i32 #{e50b0008}					;-- STR r0, [fp, -8]
			;offset: offset + 8						;-- account for the 2 catch slots on stack 
			emit-i32 #{e1a0d00b}					;-- MOV sp, fp
			
			if callback? [offset: offset + (9 * 4) + (8 * 8)] ;-- skip saved regs: {r4-r11, lr}, {d8-d15}
			offset: offset + (2 * 8)				;-- account for the 2 catch slots + 2 saved slots
			
			either offset > 255 [
				emit-load-imm32/reg offset 4
				emit-i32 #{e04dd004}				;-- SUB sp, sp, r4
			][
				emit-i32 join #{e24dd0}	to char! offset ;-- SUB sp, sp, locals-size
			]
		]
	]

	emit-prolog: func [
		name locals [block!] locals-size [integer!]
		/local args-nb attribs args reg freg fargs-nb
	][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "prolog"]]
		
		fspec: select compiler/functions name
		attribs: compiler/get-attributes fspec/4
		
		if any [
			fspec/5 = 'callback
			all [attribs any [find attribs 'cdecl find attribs 'stdcall]]
		][
			;; we use a simple prolog, which maintains ABI compliance: args 0-3 are
			;; passed via regs r0-r3, further args are passed on the stack (pushed
			;; right-to-left; i.e. the leftmost argument is at top-of-stack).
			;;
			;; our prolog pushes the first <=4 args right-to-left to the stack
			;;
			;; AAPCS (for external calls & callbacks only)
			;;
			;;	15 = pc
			;;	14 = lr
			;;	13 = sp									(callee saved: fun must preserve)
			;;	12 = "ip" (scratch)
			;;	4-11 = variable register 1-8			(callee saved: fun must preserve)
			;;	11 = "fp"
			;;	2-3 = argument 3-4
			;;  0-1	= argument 1-2 / result
			;;
			;;	stack (sp) at function call must be 8-byte (dword) aligned!
			;;
			;;	c widths: char = i8, short = i16, int & long = i32, long long = i64
			;;	alignment: == size (so char==1, short==2, int/long==4, ptr==4)
			;;	structs aligned at max aligned, padded to multiple of alignment
			
			args-nb: fspec/1
			
			if all [4 < args-nb name <> '***_start][
				compiler/throw-error "[ARM emitter] more than 4 arguments in callbacks, not yet supported"
			]
			emit-i32 #{e92d4ff0}					;-- STMFD sp!, {r4-r11, lr}
			emit-i32 #{ed2d8b10}					;-- FSTMD sp!, {d8-d15}

			args: fspec/4
			either all [compiler/job/ABI = 'hard-float not empty? args][
				reg: freg: 1
				args: extract-arguments args		;-- cleanup and reverse arguments order
				fargs-nb: count-floats args
				
				foreach arg args [					;-- process in reverse order
					either find [float! float64! float32!] arg/1 [
						emit-push-float fargs-nb - freg arg 		 ;-- push in reverse order
						freg: freg + 1
					][
						emit-i32 #{e92d00}			;-- PUSH {r<n>}
						emit-i32 to char! shift/left 1 args-nb - reg ;-- push in reverse order
						reg: reg + 1
					]
				]
			][
				repeat i args-nb [
					emit-i32 #{e92d00}				;-- PUSH {r<n>}
					emit-i32 to char! shift/left 1 args-nb - i	;-- push in reverse order
				]
			]
			if PIC? [
				emit-i32 #{e1a0900f}				;-- MOV sb, pc
				pools/collect emitter/tail-ptr + 1 + 2 ;-- +1 adjustment for CALL first opcode
				emit-i32 #{e0499000}				;-- SUB sb, r0
			]
		]
			
		;-- Red/System standard function prolog --	
		
		emit-i32 #{e92d4800}						;-- PUSH {fp,lr}
		emit-i32 #{e1a0b00d}						;-- MOV fp, sp
		
		emit-push pick [-2 0] to logic! all [attribs find attribs 'catch]	;-- push catch flag
		emit-push 0									;-- reserve slot for catch resume address
		
		unless zero? locals-size [
			emit-reserve-stack (round/to/ceiling locals-size stack-width) / stack-width
		]
	]

	emit-epilog: func [
		name [word! path!] locals [block!] args-size [integer!] locals-size [integer!]
		 /with slots [integer! none!]
		/local fspec attribs
	][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]
		
		if slots [
			case [
				slots = 1 [emit-i32 #{e5900000}]	;-- LDR r0, [r0]
				slots = 2 [
					emit-i32 #{e5901004}			;-- LDR r1, [r0, 4]
					emit-i32 #{e5900000}			;-- LDR r0, [r0]
				]
				'else [
					vars: emitter/stack
					unless tag? vars/1 [
						compiler/throw-error ["Function" name "has no return pointer in" mold locals]
					]
					emit-i32 join #{e59bc0} to-bin8 vars/2 ;-- LDR ip, [fp, 8]
					emit-copy-mem slots
				]
			]
		]
		
		emit-i32 #{e1a0d00b}						;-- MOV sp, fp		; catch flag is skipped
		emit-i32 #{e8bd4800}						;-- POP {fp,lr}

		either compiler/check-variable-arity? locals [
			emit-i32 #{e8bd0004}					;-- POP {r2}		; skip arguments count
			emit-i32 #{e8bd0004}					;-- POP {r2}		; skip arguments pointer
			emit-i32 #{e8bd0004}					;-- POP {r2}		; get stack offset
			emit-i32 #{e08dd002}					;-- ADD sp, sp, r2	; skip arguments list (clears stack)
		][
			unless zero? args-size [
				emit-op-imm32
					#{e28dd000}						;-- ADD sp, sp, args-size
					round/to/ceiling args-size 4
			]
		]
		
		fspec: select/only compiler/functions name
		
		either any [
			fspec/5 = 'callback
			all [
				attribs: compiler/get-attributes fspec/4
				any [find attribs 'cdecl find attribs 'stdcall]
			]
		][
			emit-hf-return/reverse fspec/4
			emit-i32 #{ecbd8b10}					;-- FLDMIAD sp!, {d8-d15}
			emit-i32 #{e8bd4ff0}					;-- LDMFD sp!, {r4-r11, lr}
			emit-i32 #{e12fff1e}					;-- BX lr
		][
			emit-i32 #{e1a0f00e}					;-- MOV pc, lr
		]

		pools/mark-entry-point name
	]
]
