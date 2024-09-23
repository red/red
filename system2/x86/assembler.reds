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

#define ABS_ADDR		44332211h
#define REL_ADDR		66554433h

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
		op		[basic-op!]
	][
		put-b MOD_REG or (op - 1 and 7 << 3) or (r and 7)
	]

	emit-b-r: func [
		b		[integer!]
		r		[integer!]
		op		[basic-op!]
	][
		put-b b
		emit-r r op
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
				emit-b-r 81h r op
				emit-d i
			]
		][
			emit-b-r 83h r op
			put-b i
		]
	]

	emit-m: func [
		m		[integer!]
		x		[integer!]
	][
		x: x and 7 << 3
		emit-bd x or 5 m
	]

	emit-b-m-x: func [
		b		[integer!]	;-- byte
		m		[integer!]	;-- memory
		x		[integer!]	;-- ext
	][
		put-b b
		emit-m m x
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
		emit-b-m-x FFh addr 2
	]
]