Red/System [
	File: 	 %assembler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

x86-regs: context [
	#enum gpr-reg! [
		eax
		ecx
		edx
		ebx
		esp
		ebp
		esi
		edi
		r8
		r9
		r10
		r11
		r12
		r13
		r14
		r15
	]

	#enum sse-reg! [
		xmm0
		xmm1
		xmm2
		xmm3
		xmm4
		xmm5
		xmm6
		xmm7
		xmm8
		xmm9
		xmm10
		xmm11
		xmm12
		xmm13
		xmm14
		xmm15
	]
]

x86-addr!: alias struct! [
	base	[integer!]
	index	[integer!]
	scale	[integer!]
	disp	[integer!]
]

#define MOD_DISP0 		00h
#define MOD_DISP8 		40h
#define MOD_DISP32		80h
#define MOD_REG 		C0h
#define MOD_BITS		C0h

#define ABS_ADDR		7FFFFFF0h
#define REL_ADDR		7FFFFFF1h
#define ABS_FLAG		F0h
#define REL_FLAG		F1h

asm: context [

	#enum basic-op! [
		OP_ADD: 1
		OP_OR
		OP_ADC
		OP_SBB
		OP_AND
		OP_SUB
		OP_XOR
		OP_CMP
	]

	;;opcodes:	add  or adc sbb and sub xor cmp
	x86-rm-r:  [01h 09h 11h 19h 21h 29h 31h 39h]
	x86-r-rm:  [03h 0Bh 13h 1Bh 23h 2Bh 33h 3Bh]
	x86-eax-i: [05h 0Dh 15h 1Dh 25h 2Dh 35h 3Dh]

	pos: func [return: [integer!]][
		program/code-buf/length
	]

	emit-d: func [d [integer!]][put-32 d]

	emit-bd: func [b [integer!] d [integer!]][
		put-b b
		put-32 d
	]

	emit-bbd: func [b1 [integer!] b2 [integer!] d [integer!]][
		put-bb b1 b2
		put-32 d
	]

	emit-r: func [
		r		[integer!]
		x		[integer!]
	][
		put-b MOD_REG or (x and 7 << 3) or (r and 7)
	]

	emit-b-r: func [
		b		[integer!]
		r		[integer!]
		x		[integer!]
	][
		put-b b
		emit-r r x
	]

	emit-r-i: func [		;-- register, immediate
		r		[integer!]
		i		[integer!]
		op		[basic-op!]
	][
		either any [i < -128 i > 127][
			either r = x86-regs/eax [
				emit-bd x86-eax-i/op i
			][
				emit-b-r 81h r op - 1
				emit-d i
			]
		][
			emit-b-r 83h r op - 1
			put-b i
		]
	]

	emit-offset: func [
		offset	[integer!]
		x		[integer!]
	][
		x: x and 7 << 3
		either offset = REL_ADDR [
			emit-bd x or 5 offset					;-- relative offset
		][
			emit-bbd x or x86-regs/esp 25h offset	;-- absolute offset
		]
	]

	emit-rm: func [			;-- [register + disp], memory address via register
		op		[integer!]
		reg		[integer!]
		m		[x86-addr!]
		/local
			modrm	[integer!]
			disp	[integer!]
			sib		[integer!]
	][
		modrm: op or reg
		disp: m/disp
		case [
			reg = x86-regs/esp [
				sib: 24h	;-- bits: 00100100
				if zero? disp [
					put-bb MOD_DISP0 or modrm sib
					exit
				]
				either any [disp < -128 disp > 127][
					emit-bbd MOD_DISP32 or modrm sib disp
				][
					put-bbb MOD_DISP8 or modrm sib disp
				]
			]
			zero? disp [
				either reg = x86-regs/ebp [
					put-bb MOD_DISP8 or modrm 0
				][
					put-b MOD_DISP0 or modrm
				]
			]
			any [disp < -128 disp > 127][
				emit-bd MOD_DISP32 or modrm disp
			]
			true [
				put-bb MOD_DISP8 or modrm disp
			]
		]
	]

	emit-m: func [
		m		[x86-addr!]	;-- memory location
		x		[integer!]	;-- ModR/M.reg
		/local
			base scale index disp modrm sib [integer!]
	][
		x: x and 7 << 3
		base: m/base
		index: m/index
		scale: m/scale
		disp: m/disp

		if zero? index [
			either zero? base [
				either disp = REL_ADDR [
					emit-bd x or 5 disp					;-- relative address
				][
					emit-bbd x or x86-regs/esp 25h disp	;-- absolute address
				]
			][
				emit-rm x base m
			]
			exit
		]

		if zero? base [
			if scale = 1 [
				emit-rm x index m
				exit
			]
			if scale = 2 [	;-- convert to reg + reg
				scale: 1
				base: index
			]
		]

		modrm: x or x86-regs/esp

		sib: index << 3
		sib: sib or case [
			scale = 2 [40h]
			scale = 4 [80h]
			scale = 8 [C0h]
			true [0]
		]

		either base <> 0 [
			sib: sib or base
			modrm: modrm or case [
				any [disp < -128 disp > 127][MOD_DISP32]
				disp <> 0 [MOD_DISP8]
				any [base = x86-regs/ebp base = x86-regs/r13][MOD_DISP8]
				true [0]
			]
		][
			sib: sib or x86-regs/ebp
		]

		case [
			any [zero? base disp < -128 disp > 127][
				emit-bbd modrm sib disp
			]
			modrm and C0h = MOD_DISP8 [
				put-bbb modrm sib disp
			]
			true [put-bb modrm sib]
		]
	]

	emit-b-m-x: func [
		op		[integer!]	;-- byte
		m		[x86-addr!]	;-- memory location
		x		[integer!]	;-- Mod/RM.reg
	][
		put-b op
		emit-m m x
	]

	emit-b-r-m: func [
		op		[integer!]
		r		[integer!]
		m		[x86-addr!]
	][
		emit-b-m-x op m r
	]

	emit-b-m-r: func [
		op		[integer!]
		m		[x86-addr!]
		r		[integer!]
	][
		emit-b-m-x op m r
	]

	emit-b-r-r: func [
		op		[integer!]
		r1		[integer!]
		r2		[integer!]
	][
		emit-b-r op r1 r2
	]

	ret: does [put-b C3h]

	jmp-rel: func [
		offset	[integer!]
	][
		either all [offset >= -126 offset <= 129][
			put-bb EBh offset - 2
		][
			emit-bd E9h offset - 5
		]
	]

	jmp-label: func [
		l		[label!]
	][
		emit-bd E9h REL_ADDR
		record-label l pos - 4
	]

	jc-rel: func [
		cond	[integer!]
		offset	[integer!]
	][
		either all [offset >= -126 offset <= 129][
			put-bb 70h + cond offset - 2
		][
			emit-bbd 0Fh 80h + cond offset - 6
		]	
	]

	jc-rel-label: func [
		cond	[integer!]
		l		[label!]
	][
		emit-bbd 0Fh 80h + cond REL_ADDR
		record-label l pos - 4
	]

	call-rel: func [
		offset	[integer!]
	][
		emit-bd E8h offset
	]

	icall-rel: func [		;-- absolute indirect call
		addr	[integer!]
	][
		put-b FFh
		emit-offset addr 2
	]

	movd-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-b-r-m 8Bh r m
	]

	movd-m-r: func [
		m		[x86-addr!]
		r		[integer!]
	][
		emit-b-m-r 89h m r
	]

	movd-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-b-r-r 89h r1 r2
	]

	movd-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b-m-x C7h m 0
		put-32 imm
	]

	movd-r-i: func [
		r		[integer!]
		imm		[integer!]
	][
		put-b B8h + r
		put-32 imm
	]
]