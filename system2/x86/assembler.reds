Red/System [
	File: 	 %assembler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

x86-regs: context [
	#enum gpr-reg! [
		none
		eax		;- rax
		ecx		;- rcx
		edx		;- rdx
		ebx		;- rbx
		esp		;- rsp
		ebp		;- rbp
		esi		;- rsi
		edi		;- rdi
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
	ref		[val!]
]

#define MOD_DISP0 		00h
#define MOD_DISP8 		40h
#define MOD_DISP32		80h
#define MOD_REG 		C0h
#define MOD_BITS		C0h
#define REX_BYTE		40h
#define REX_W			08h
#define REX_R			04h
#define REX_X			02h
#define REX_B			01h
#define NO_REX			00h
#define PREFIX_W		66h

#define ABS_ADDR		7FFFFFF0h
#define REL_ADDR		7FFFFFF1h
#define ABS_FLAG		F0h
#define REL_FLAG		F1h

#define emit_rex [if rex <> 0 [emit-b REX_BYTE or rex]]

asm: context [

	rex-byte: 0

	#enum basic-op! [
		x86_ADD: 1
		x86_OR
		x86_ADC
		x86_SBB
		x86_AND
		x86_SUB
		x86_XOR
		x86_CMP
	]

	;;opcodes: add  or adc sbb and sub xor cmp
	op-rm-r:  [01h 09h 11h 19h 21h 29h 31h 39h]
	op-r-rm:  [03h 0Bh 13h 1Bh 23h 2Bh 33h 3Bh]
	op-eax-i: [05h 0Dh 15h 1Dh 25h 2Dh 35h 3Dh]

	get-buffer: func [return: [byte-ptr!]][
		program/code-buf/data
	]

	pos: func [return: [integer!]][
		program/code-buf/length
	]

	emit-b: func [b [integer!]][
		put-b program/code-buf b
	]

	emit-bb: func [b1 [integer!] b2 [integer!]][
		put-bb program/code-buf b1 b2
	]

	emit-bbb: func [b1 [integer!] b2 [integer!] b3 [integer!]][
		put-bbb program/code-buf b1 b2 b3
	]

	emit-bw: func [b [integer!] n [integer!]][
		put-b program/code-buf b
		put-16 program/code-buf n
	]

	emit-w: func [w [integer!]][
		put-16 program/code-buf w
	]

	emit-d: func [d [integer!]][put-32 program/code-buf d]

	emit-bd: func [b [integer!] d [integer!]][
		put-b program/code-buf b
		put-32 program/code-buf d
	]

	emit-bbd: func [b1 [integer!] b2 [integer!] d [integer!]][
		put-bb program/code-buf b1 b2
		put-32 program/code-buf d
	]

	rex-r: func [
		r		[integer!]
		rex		[integer!]
		return: [integer!]
	][
		either r > 8 [rex][0]
	]

	rex-m: func [
		m		[x86-addr!]
		rex		[integer!]
		return: [integer!]
		/local
			idx [integer!]
	][
		idx: m/index
		either zero? m/base [
			switch m/scale [
				1 [rex-r idx rex]
				2 [rex-r idx REX_X or rex]
				default [rex-r idx REX_X]
			]
		][
			rex: rex-r m/base rex
			rex or rex-r idx REX_X
		]
	]

	emit-r: func [
		r		[integer!]
		x		[integer!]
	][
		emit-b MOD_REG or (x and 7 << 3) or (r - 1 and 7)
	]

	emit-b-r-rex: func [
		b		[integer!]
		r		[integer!]
		rex		[integer!]
	][
		rex: rex or rex-r r REX_B
		if rex <> 0 [
			emit-b REX_BYTE or rex
			r: r - 8
		]
		emit-b b + (r - 1)
	]

	emit-b-r-x: func [
		b		[integer!]
		r		[integer!]
		x		[integer!]
	][
		emit-b b
		emit-r r x
	]

	emit-b-r-x-rex: func [
		b		[integer!]
		r		[integer!]
		x		[integer!]
		rex		[integer!]
	][
		rex: rex or rex-r r REX_B
		emit_rex
		emit-b-r-x b r x
	]

	emit-bb-r-x: func [
		b1		[integer!]
		b2		[integer!]
		r		[integer!]
		x		[integer!]
	][
		emit-bb b1 b2
		emit-r r x
	]

	emit-bb-m-x: func [
		b1		[integer!]
		b2		[integer!]
		m		[x86-addr!]
		x		[integer!]
	][
		emit-bb b1 b2
		emit-m m x
	]

	emit-bb-rr: func [
		b1		[integer!]
		b2		[integer!]
		r1		[integer!]
		r2		[integer!]
		rex		[integer!]
		/local
			flag [integer!]
	][
		flag: rex-r r2 REX_B
		rex: rex or flag or rex-r r1 REX_R
		emit_rex
		emit-bb-r-x b1 b2 r2 r1 - 1
	]

	emit-bb-rm: func [
		b1		[integer!]
		b2		[integer!]
		r		[integer!]
		m		[x86-addr!]
		rex		[integer!]
		/local
			flag [integer!]
	][
		flag: rex-r r REX_R
		rex: rex or flag or rex-m m REX_B
		emit_rex
		emit-bb-m-x b1 b2 m r - 1
	]

	emit-bbb-rr: func [
		b1		[integer!]
		b2		[integer!]
		b3		[integer!]
		r1		[integer!]
		r2		[integer!]
		rex		[integer!]
		/local
			flag [integer!]
	][
		flag: rex-r r2 REX_B
		rex: rex or flag or rex-r r1 REX_R
		emit_rex
		emit-bb b1 b2
		emit-b-r-x b3 r2 r1 - 1
	]

	emit-bbb-rm: func [
		b1		[integer!]
		b2		[integer!]
		b3		[integer!]
		r		[integer!]
		m		[x86-addr!]
		rex		[integer!]
		/local
			flag [integer!]
	][
		flag: rex-r r REX_R
		rex: rex or flag or rex-m m REX_B
		emit_rex
		emit-bb b1 b2
		emit-b-m b3 m r - 1
	]

	emit-r-i: func [		;-- register, immediate
		r		[integer!]
		i		[integer!]
		op		[basic-op!]
	][
		either any [i < -128 i > 127][
			either r = x86-regs/eax [
				emit-bd op-eax-i/op i
			][
				emit-b-r-x 81h r op - 1
				emit-d i
			]
		][
			emit-b-r-x 83h r op - 1
			emit-b i
		]
	]

	emit-offset: func [
		offset	[integer!]
		x		[integer!]
	][
		x: x and 7 << 3
		either offset = REL_ADDR [
			emit-bd x or 5 offset		;-- relative offset
		][
			emit-bbd x or 4 25h offset	;-- absolute offset
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
		modrm: op or (reg - 1)
		disp: m/disp
		case [
			reg = x86-regs/esp [
				sib: 24h	;-- bits: 00100100
				if zero? disp [
					emit-bb MOD_DISP0 or modrm sib
					exit
				]
				either any [disp < -128 disp > 127][
					emit-bbd MOD_DISP32 or modrm sib disp
				][
					emit-bbb MOD_DISP8 or modrm sib disp
				]
			]
			zero? disp [
				either reg = x86-regs/ebp [
					emit-bb MOD_DISP8 or modrm 0
				][
					emit-b MOD_DISP0 or modrm
				]
			]
			any [disp < -128 disp > 127][
				emit-bd MOD_DISP32 or modrm disp
			]
			true [
				emit-bb MOD_DISP8 or modrm disp
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
					emit-bd x or 5 disp			;-- relative address, EIP-relative
				][
					emit-bbd x or 4 25h disp	;-- absolute address, ESP
					record-abs-ref pos - 4 m/ref
				]
			][
				emit-rm x base m				;-- base register only
			]
			exit
		]

		if zero? base [
			if scale = 1 [
				emit-rm x index m				;-- index register only
				exit
			]
			if scale = 2 [	;-- convert to reg + reg
				scale: 1
				base: index
			]
		]

		modrm: x or (x86-regs/esp - 1)

		sib: index - 1 << 3
		sib: sib or case [
			scale = 2 [40h]
			scale = 4 [80h]
			scale = 8 [C0h]
			true [0]
		]

		either base <> 0 [
			sib: sib or (base - 1)
			modrm: modrm or case [
				any [disp < -128 disp > 127][MOD_DISP32]
				disp <> 0 [MOD_DISP8]
				any [base = x86-regs/ebp base = x86-regs/r13][MOD_DISP8]
				true [0]
			]
		][
			sib: sib or (x86-regs/ebp - 1)
		]

		case [
			any [zero? base disp < -128 disp > 127][
				emit-bbd modrm sib disp
			]
			modrm and C0h = MOD_DISP8 [
				emit-bbb modrm sib disp
			]
			true [emit-bb modrm sib]
		]
	]

	emit-b-m: func [
		b		[integer!]
		m		[x86-addr!]
		x		[integer!]
	][
		emit-b b
		emit-m m x
	]

	emit-b-m-x: func [
		op		[integer!]	;-- byte
		m		[x86-addr!]	;-- memory location
		x		[integer!]	;-- Mod/RM.reg
		rex		[integer!]	;-- rex byte
	][
		rex: rex or rex-m m REX_B
		emit_rex
		emit-b op
		emit-m m x
	]

	emit-b-r-m: func [
		op		[integer!]
		r		[integer!]
		m		[x86-addr!]
		rex		[integer!]	;-- rex byte
		/local
			b	[integer!]
	][
		b: rex-r r REX_R
		b: b or rex-m m REX_B
		rex: rex or b
		emit_rex
		emit-b-m op m r - 1
	]

	emit-b-m-r: func [
		op		[integer!]
		m		[x86-addr!]
		r		[integer!]
		rex		[integer!]	;-- rex byte
		/local
			b	[integer!]
	][
		b: rex-m m REX_B
		b: b or rex-r r REX_R
		rex: rex or b
		emit_rex		
		emit-b-m op m r - 1
	]

	emit-b-r-r: func [
		op		[integer!]
		r1		[integer!]
		r2		[integer!]
		rex		[integer!]	;-- rex byte
		/local
			b	[integer!]
	][
		b: rex-r r1 REX_B
		b: b or rex-r r2 REX_R
		rex: rex or b
		emit_rex
		emit-b-r-x op r1 r2 - 1
	]

	emit-r-r: func [
		r1		[integer!]
		r2		[integer!]
		op		[basic-op!]
		rex		[integer!]
	][
		emit-b-r-r op-rm-r/op r1 r2 rex
	]

	emit-r-m: func [
		r		[integer!]
		m		[x86-addr!]
		op		[basic-op!]
		rex		[integer!]
	][
		emit-b-r-m op-r-rm/op r m rex
	]

	emit-m-r: func [
		m		[x86-addr!]
		r		[integer!]
		op		[basic-op!]
		rex		[integer!]
	][
		emit-b-m-r op-rm-r/op m r rex
	]

	emit-m-i: func [
		m		[x86-addr!]
		i		[integer!]
		op		[basic-op!]
		rex		[integer!]
	][
		either any [i < -128 i > 127][
			emit-b-m-x 81h m op rex
			emit-d i
		][
			emit-b-m-x 83h m op rex
			emit-b i
		]
	]

	leave: does [emit-b C9h]

	ret: does [emit-b C3h]
	retn: func [n [integer!]][emit-bw C2h n]

	pop-r: func [r [integer!]][
		emit-b-r-rex 58h r NO_REX
	]
	pop: func [m [x86-addr!]][
		emit-b-m-x 8Fh m 0 rex-byte
	]

	push: func [m [x86-addr!]][emit-b-m-x FFh m 6 rex-byte]

	push-i: func [i [integer!]][
		either any [i < -128 i > 127][
			emit-bd 68h i
		][
			emit-bb 6Ah i
		]
	]

	push-r: func [r [integer!]][
		emit-b-r-rex 50h r NO_REX
	]

	push-m: func [m [x86-addr!]][
		emit-b-m-x FFh m 6 NO_REX
	]

	lea: func [r [integer!] m [x86-addr!]][
		emit-b-r-m 8Dh r m NO_REX
	]

	leaq: func [r [integer!] m [x86-addr!]][
		emit-b-r-m 8Dh r m REX_W
	]

	jmp-rel: func [
		offset	[integer!]
	][
		either all [offset >= -126 offset <= 129][
			emit-bb EBh offset - 2
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

	jmp-r: func [
		r		[integer!]
		/local
			rex [integer!]
	][
		rex: rex-r r REX_B
		emit_rex
		emit-b-r-x FFh r 4
	]

	jc-rel: func [
		cond	[integer!]
		offset	[integer!]
	][
		either all [offset >= -126 offset <= 129][
			emit-bb 70h + cond offset - 2
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

	setc: func [
		cond	[integer!]
		reg		[integer!]
		/local
			op	[integer!]
			rex [integer!]
	][
		op: 90h + cond
		rex: rex-r reg REX_B
		if reg >= 5 [rex: rex or REX_BYTE]
		emit_rex
		emit-bb-r-x 0Fh op reg 0
	]

	call-rel: func [
		offset	[integer!]
	][
		emit-bd E8h offset
	]

	icall-rel: func [		;-- absolute indirect call
		addr	[integer!]
	][
		emit-b FFh
		emit-offset addr 2
	]

	mov-r-r: func [
		r1		[integer!]	;-- dst
		r2		[integer!]	;-- src
	][
		emit-b-r-r 89h r1 r2 rex-byte
	]

	mov-m-r: func [
		m		[x86-addr!]	;-- dst
		r		[integer!]	;-- src
	][
		emit-b-m-r 89h m r rex-byte		
	]

	mov-r-m: func [
		r		[integer!]
		m		[x86-addr!]
	][
		emit-b-r-m 8Bh r m rex-byte
	]

	mov-r-i: func [
		r		[integer!]
		imm		[integer!]
	][
		if zero? imm [
			xor-r-r r r rex-byte
			exit
		]
		emit-b-r-rex B8h r rex-byte
		emit-d imm
	]

	mov-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b-m-x C7h m 0 rex-byte
		emit-d imm
	]

	movd-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-b-r-m 8Bh r m NO_REX
	]

	movd-m-r: func [
		m		[x86-addr!]
		r		[integer!]
	][
		emit-b-m-r 89h m r NO_REX
	]

	movd-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-b-r-r 89h r1 r2 NO_REX
	]

	movd-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b-m-x C7h m 0 NO_REX
		emit-d imm
	]

	movd-r-i: func [
		r		[integer!]
		imm		[integer!]
	][
		if zero? imm [
			xor-r-r r r NO_REX
			exit
		]
		emit-b-r-rex B8h r NO_REX
		emit-d imm
	]

	movq-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-b-r-r 89h r1 r2 REX_W
	]

	movq-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-b-r-m 8Bh r m REX_W
	]

	movq-m-r: func [
		m		[x86-addr!]
		r		[integer!]
	][
		emit-b-m-r 89h m r REX_W
	]

	movq-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b-m-x C7h m 0 REX_W
		emit-d imm
	]

	movq-r-i: func [
		r		[integer!]
		imm		[integer!]
	][
		if zero? imm [
			xor-r-r r r NO_REX
			exit
		]
		emit-b-r-x-rex C7h r 0 REX_W
		emit-d imm
	]

	movb-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
		/local
			rex [integer!]
	][
		rex: either r > 4 [REX_BYTE][0]
		emit-b-r-m 8Ah r m rex
	]

	movb-m-r: func [
		m		[x86-addr!]
		r		[integer!]
		/local
			rex [integer!]
	][
		rex: either r > 4 [REX_BYTE][0]
		emit-b-m-r 88h m r rex
	]

	movb-r-r: func [
		r1		[integer!]
		r2		[integer!]
		/local
			rex [integer!]
	][
		rex: either any [r1 > 4 r2 > 4][REX_BYTE][0]
		emit-b-r-r 88h r1 r2 rex
	]

	movb-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b-m-x C6h m 0 NO_REX
		emit-b imm
	]

	movb-r-i: func [
		r		[integer!]
		imm		[integer!]
		/local
			rex [integer!]
	][
		rex: either r > 4 [REX_BYTE][0]
		emit-b-r-rex B0h r rex
		emit-b imm
	]

	movbsx-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-bb-rr 0Fh BEh r1 r2 rex-byte
	]

	movbsx-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-bb-rm 0Fh BEh r m rex-byte
	]

	movbzx-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-bb-rr 0Fh B6h r1 r2 rex-byte
	]

	movbzx-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-bb-rm 0Fh B6h r m rex-byte
	]

	movwsx-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-bb-rr 0Fh BFh r1 r2 rex-byte
	]

	movwsx-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-bb-rm 0Fh BFh r m rex-byte
	]

	movwzx-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-bb-rr 0Fh B7h r1 r2 rex-byte
	]

	movwzx-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-bb-rm 0Fh B7h r m rex-byte
	]

	movw-r-m: func [
		r		[integer!]	;-- dst
		m		[x86-addr!]	;-- src
	][
		emit-b PREFIX_W
		emit-b-r-m 8Bh r m NO_REX
	]

	movw-m-r: func [
		m		[x86-addr!]
		r		[integer!]
	][
		emit-b PREFIX_W
		emit-b-m-r 89h m r NO_REX
	]

	movw-r-r: func [
		r1		[integer!]
		r2		[integer!]
	][
		emit-b PREFIX_W
		emit-b-r-r 89h r1 r2 NO_REX
	]

	movw-m-i: func [
		m		[x86-addr!]
		imm		[integer!]
	][
		emit-b PREFIX_W
		emit-b-m-x C7h m 0 NO_REX
		emit-w imm
	]

	movw-r-i: func [
		r		[integer!]
		imm		[integer!]
	][
		emit-b PREFIX_W
		emit-b-r-rex B8h r NO_REX
		emit-w imm
	]

	cdq: func [][emit-b 99h]
	cqo: func [][emit-bb REX_BYTE or REX_W 99h]

	idiv-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex F7h r 7 rex]
	idiv-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x F7h m 7 rex]

	imul-r-i: func [r  [integer!] imm [integer!] rex [integer!]][
		rex: rex or rex-r r REX_B or REX_R
		emit_rex
		either any [imm < -128 imm > 127][
			emit-b-r-x 69h r r - 1
			emit-d imm
		][
			emit-b-r-x 6Bh r r - 1
			emit-b imm
		]
	]
	imul-r-r: func [r1 [integer!] r2 [integer!] rex [integer!]][emit-bb-rr 0Fh AFh r1 r2 rex]
	imul-r-m: func [r  [integer!] m [x86-addr!] rex [integer!]][emit-bb-rm 0Fh AFh r m rex]
	imul-r: func [r [integer!]  rex [integer!]][emit-b-r-x-rex F7h r 5 rex]
	imul-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x F7h m 5 rex]

	and-r-i: func [r [integer!] imm [integer!]  rex [integer!]][emit-r-i r imm x86_AND rex]
	and-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_AND rex]
	and-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_AND rex]
	and-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_AND rex]
	and-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_AND - 1 rex]

	or-r-i: func [r [integer!] imm [integer!]  rex [integer!]][emit-r-i r imm x86_OR rex]
	or-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_OR rex]
	or-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_OR rex]
	or-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_OR rex]
	or-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_OR - 1 rex]

	xor-r-i: func [r [integer!] imm [integer!]  rex [integer!]][emit-r-i r imm x86_XOR rex]
	xor-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_XOR rex]
	xor-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_XOR rex]
	xor-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_XOR rex]
	xor-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_XOR - 1 rex]

	sub-r-i: func [r [integer!] imm [integer!]  rex [integer!]][emit-r-i r imm x86_SUB rex]
	sub-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_SUB rex]
	sub-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_SUB rex]
	sub-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_SUB rex]
	sub-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_SUB - 1 rex]

	add-r-i: func [r  [integer!] imm [integer!] rex [integer!]][emit-r-i r imm x86_ADD rex]
	add-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_ADD rex]
	add-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_ADD rex]
	add-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_ADD rex]
	add-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_ADD - 1 rex]

	adc-r-i: func [r  [integer!] imm [integer!] rex [integer!]][emit-r-i r imm x86_ADC rex]
	adc-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_ADC rex]
	adc-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_ADC rex]
	adc-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_ADC rex]
	adc-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_ADC - 1 rex]

	sbb-r-i: func [r  [integer!] imm [integer!] rex [integer!]][emit-r-i r imm x86_SBB rex]
	sbb-r-r: func [r1 [integer!] r2 [integer!]  rex [integer!]][emit-r-r r1 r2 x86_SBB rex]
	sbb-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_SBB rex]
	sbb-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_SBB rex]
	sbb-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_SBB - 1 rex]

	cmp-r-i: func [r [integer!] imm [integer!] rex [integer!]][emit-r-i r imm x86_CMP rex]
	cmp-r-r: func [r1 [integer!] r2 [integer!] rex [integer!]][emit-r-r r1 r2 x86_CMP rex]
	cmp-r-m: func [r  [integer!] m [x86-addr!]  rex [integer!]][emit-r-m r m x86_CMP rex]
	cmp-m-r: func [m  [x86-addr!] r [integer!]  rex [integer!]][emit-m-r m r x86_CMP rex]
	cmp-m-i: func [m [x86-addr!] imm [integer!] rex [integer!]][emit-m-i m imm x86_CMP - 1 rex]

	cmpb-r-r: func [
		r1		[integer!]
		r2		[integer!]
		/local
			rex [integer!]
	][
		rex: either any [r1 > 4 r2 > 4][REX_BYTE][NO_REX]
		emit-b-r-r 38h r1 r2 rex
	]

	cmpb-r-m: func [
		r		[integer!]
		m		[x86-addr!]
		/local
			rex [integer!]
	][
		rex: either r > 4 [REX_BYTE][NO_REX]
		emit-b-r-m 3Ah r m rex
	]

	cmpb-m-r: func [
		m		[x86-addr!]
		r		[integer!]
		/local
			rex [integer!]
	][
		rex: either r > 4 [REX_BYTE][NO_REX]
		emit-b-m-r 38h m r rex
	]

	cmpb-r-i: func [
		r		[integer!]
		imm		[integer!]
		/local
			rex [integer!]
	][
		either r = x86-regs/eax [
			emit-bb 3Ch imm
		][
			rex: either r > 4 [REX_BYTE][NO_REX]
			emit-b-r-x-rex 80h r 7 rex
			emit-b imm
		]
	]

	cmpb-m-i: func [
		m		[x86-addr!]
		imm		[integer!]	
	][
		emit-b-m-x 80h m 7 NO_REX
		emit-b imm
	]

	btr-r-i: func [r [integer!] i [integer!] rex [integer!]][
		rex: rex or rex-r r REX_B
		emit_rex
		emit-bb-r-x 0Fh BAh r 6
		emit-b i
	]

	btr-m-i: func [m [x86-addr!] i [integer!] rex [integer!]][
		rex: rex or rex-m m REX_B
		emit_rex
		emit-bb-m-x 0Fh BAh m 6
		emit-b i
	]

	bt-r-i: func [r [integer!] i [integer!] rex [integer!]][
		rex: rex or rex-r r REX_B
		emit_rex
		emit-bb-r-x 0Fh BAh r 4
		emit-b i
	]

	bt-m-i: func [m [x86-addr!] i [integer!] rex [integer!]][
		rex: rex or rex-m m REX_B
		emit_rex
		emit-bb-m-x 0Fh BAh m 4
		emit-b i
	]

	not-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex F7h r 2 rex]
	not-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x F7h m 2 rex]
	neg-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex F7h r 3 rex]
	neg-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x F7h m 3 rex]

	shift-r-i: func [r [integer!] i [integer!] op [integer!] rex [integer!]][
		either i = 1 [
			emit-b-r-x-rex D1h r op rex
		][
			emit-b-r-x-rex C1h r op rex
			emit-b i
		]
	]
	shift-m-i: func [m [x86-addr!] i [integer!] op [integer!] rex [integer!]][
		either i = 1 [
			emit-b-m-x D1h m op rex
		][
			emit-b-m-x C1h m op rex
			emit-b i
		]
	]
	
	shl-r-i: func [r [integer!] i [integer!] rex [integer!]][shift-r-i r i 4 rex]
	shr-r-i: func [r [integer!] i [integer!] rex [integer!]][shift-r-i r i 5 rex]
	sar-r-i: func [r [integer!] i [integer!] rex [integer!]][shift-r-i r i 7 rex]

	shl-m-i: func [m [x86-addr!] i [integer!] rex [integer!]][shift-m-i m i 4 rex]
	shr-m-i: func [m [x86-addr!] i [integer!] rex [integer!]][shift-m-i m i 5 rex]
	sar-m-i: func [m [x86-addr!] i [integer!] rex [integer!]][shift-m-i m i 7 rex]

	shl-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex D3h r 4 rex]
	shr-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex D3h r 5 rex]
	sar-r: func [r [integer!] rex [integer!]][emit-b-r-x-rex D3h r 7 rex]

	shl-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x D3h m 4 rex]
	shr-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x D3h m 5 rex]
	sar-m: func [m [x86-addr!] rex [integer!]][emit-b-m-x D3h m 7 rex]

	addss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 58h r1 r2 NO_REX
	]
	addss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 58h r m NO_REX
	]
	addsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 58h r1 r2 NO_REX
	]
	addsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 58h r m NO_REX
	]

	subss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 5Ch r1 r2 NO_REX
	]
	subss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 5Ch r m NO_REX
	]
	subsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 5Ch r1 r2 NO_REX
	]
	subsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 5Ch r m NO_REX
	]

	mulss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 59h r1 r2 NO_REX
	]
	mulss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 59h r m NO_REX
	]
	mulsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 59h r1 r2 NO_REX
	]
	mulsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 59h r m NO_REX
	]

	divss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 5Eh r1 r2 NO_REX
	]
	divss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 5Eh r m NO_REX
	]
	divsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 5Eh r1 r2 NO_REX
	]
	divsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 5Eh r m NO_REX
	]

	sqrtss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 51h r1 r2 NO_REX
	]
	sqrtss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 51h r m NO_REX
	]
	sqrtsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 51h r1 r2 NO_REX
	]
	sqrtsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 51h r m NO_REX
	]

	roundss-s-s: func [r1 [integer!] r2 [integer!] c [x86-rounding!]][
		emit-b 66h
		emit-bbb-rr 0Fh 3Ah 0Ah r1 r2 NO_REX
		emit-b c
	]
	roundss-s-m: func [r [integer!] m [x86-addr!] c [x86-rounding!]][
		emit-b 66h
		emit-bbb-rm 0Fh 3Ah 0Ah r m NO_REX
		emit-b c
	]
	roundsd-s-s: func [r1 [integer!] r2 [integer!] c [x86-rounding!]][
		emit-b 66h
		emit-bbb-rr 0Fh 3Ah 0Bh r1 r2 NO_REX
		emit-b c
	]
	roundsd-s-m: func [r [integer!] m [x86-addr!] c [x86-rounding!]][
		emit-b 66h
		emit-bbb-rm 0Fh 3Ah 0Bh r m NO_REX
		emit-b c
	]

	movss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F3h
		emit-bb-rr 0Fh 10h r1 r2 NO_REX
	]
	movss-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F3h
		emit-bb-rm 0Fh 10h r m NO_REX
	]
	movss-m-s: func [m [x86-addr!] r [integer!]][
		emit-b F3h
		emit-bb-rm 0Fh 11h r m NO_REX
	]
	movsd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b F2h
		emit-bb-rr 0Fh 10h r1 r2 NO_REX
	]
	movsd-s-m: func [r [integer!] m [x86-addr!]][
		emit-b F2h
		emit-bb-rm 0Fh 10h r m NO_REX
	]
	movsd-m-s: func [m [x86-addr!] r [integer!]][
		emit-b F2h
		emit-bb-rm 0Fh 11h r m NO_REX
	]

	movd-s-r: func [s [integer!] r [integer!]][
		emit-b 66h
		emit-bb-rr 0Fh 6Eh s r NO_REX
	]
	movd-r-s: func [r [integer!] s [integer!]][
		emit-b 66h
		emit-bb-rr 0Fh 7Eh s r NO_REX
	]
	movq-s-r: func [s [integer!] r [integer!]][
		emit-b 66h
		emit-bb-rr 0Fh 6Eh s r REX_W
	]
	movq-r-s: func [r [integer!] s [integer!]][
		emit-b 66h
		emit-bb-rr 0Fh 7Eh s r REX_W
	]

	ucomisd-s-s: func [r1 [integer!] r2 [integer!]][
		emit-b 66h
		emit-bb-rr 0Fh 2Eh r1 r2 NO_REX
	]
	ucomisd-s-m: func [r1 [integer!] m [x86-addr!]][
		emit-b 66h
		emit-bb-rm 0Fh 2Eh r1 m NO_REX
	]
	ucomiss-s-s: func [r1 [integer!] r2 [integer!]][
		emit-bb-rr 0Fh 2Eh r1 r2 NO_REX
	]
	ucomiss-s-m: func [r1 [integer!] m [x86-addr!]][
		emit-bb-rm 0Fh 2Eh r1 m NO_REX
	]

	;-- micro assembler
	imod-r: func [r [integer!] rex [integer!] /local off-1 off-2 [integer!] pb p [byte-ptr!]][
		pb: get-buffer
		idiv-r r rex
		; if modulo < 0 [
		;   if divisor < 0 [divisor: negate divisor]
		; 	 modulo: modulo + divisor
		; ]
		bt-r-i x86-regs/edx 31 rex
		off-1: pos + 1
		jc-rel jc_not_carry 0
		bt-r-i r 31 rex
		off-2: pos + 1
		jc-rel jc_not_carry 0
		neg-r r rex
		p: pb + off-2
		p/value: as byte! pos - off-2 - 1
		add-r-r x86-regs/edx r rex
		p: pb + off-1
		p/value: as byte! pos - off-1 - 1
	]

	imod-m: func [m [x86-addr!] rex [integer!] /local off-1 off-2 ra [integer!] pb p [byte-ptr!]][
		pb: get-buffer
		idiv-m m rex
		; if modulo < 0 [
		;   if divisor < 0 [divisor: negate divisor]
		; 	 modulo: modulo + divisor
		; ]
		ra: x86-regs/eax
		bt-r-i x86-regs/edx 31 rex
		off-1: pos + 1
		jc-rel jc_not_carry 0	;-- JNC exit:
		movd-r-m ra m
		bt-r-i ra 31 rex
		jc-rel jc_not_carry 0	;-- JNC add:
		off-2: pos + 1
		neg-r ra rex
		p: pb + off-2
		p/value: as byte! pos - off-2 - 1
		add-r-r x86-regs/edx ra rex		;-- add: 
		p: pb + off-1
		p/value: as byte! pos - off-1 - 1
	]

	;-- x87 FPU
	fstp-d: func [
		m	[x86-addr!]
	][
		emit-b D9h
		emit-m m 03h
	]

	fstp-q: func [
		m	[x86-addr!]
	][
		emit-b DDh
		emit-m m 03h
	]
]

to-loc: func [
	o		[operand!]
	return: [integer!]
	/local
		d	[def!]
		u	[use!]
		w	[overwrite!]
][
	switch o/header and FFh [
		OD_DEF [
			d: as def! o
			d/constraint
		]
		OD_USE OD_REG [
			u: as use! o
			u/constraint
		]
		OD_OVERWRITE [
			w: as overwrite! o
			w/constraint
		]
		default [
			dprint ["wrong operand type: " o/header and FFh]
			0
		]
	]
]

to-xmmr: func [
	o		[operand!]
	return: [integer!]
][
	target/to-xmm-reg to-loc o
]

to-imm: func [
	o		[operand!]
	return: [integer!]
	/local
		i	[immediate!]
		val [cell!]
		int [red-integer!]
		c	[red-char!]
		b	[red-logic!]
		f	[red-float32!]
		p	[int-ptr!]
][
	i: as immediate! o
	val: i/value
	if null? val [return 0]
	switch TYPE_OF(val) [
		TYPE_INTEGER [
			int: as red-integer! val
			int/value
		]
		TYPE_LOGIC [
			b: as red-logic! val
			as-integer b/value
		]
		TYPE_FLOAT [
			f: as red-float32! val
			p: :f/value
			p/value
		]
		TYPE_CHAR [
			c: as red-char! val
			c/value
		]
		TYPE_WORD [		;-- null
			0
		]
		default [dprint ["to-imm: " TYPE_OF(val)] 0]
	]
]

adjust-frame: func [
	frame	[frame!]
	add?	[logic!]
	/local
		n	[integer!]
][
	n: frame/size - (INIT_FRAME_SLOTS * target/addr-size)	;-- minus return addr, ebp, catch value and catch address
	if n > 0 [
		either add? [
			asm/add-r-i x86-regs/esp n REX_W
		][
			asm/sub-r-i x86-regs/esp n REX_W
		]
	]
]

make-addr: func [
	base	[integer!]
	index	[integer!]
	scale	[integer!]
	disp	[integer!]
	return: [x86-addr!]
	/local
		a	[x86-addr!]
][
	a: xmalloc(x86-addr!)
	a/base: base
	a/index: index
	a/scale: scale
	a/disp: disp
	a
]

loc-to-addr: func [						;-- location idx to memory addr
	loc		[integer!]
	addr	[x86-addr!]
	f		[frame!]
	r		[reg-set!]
	/local
		word-sz [integer!]
		offset	[integer!]
		reg		[integer!]
][
	loc: loc and (not FRAME_SLOT_64)	;-- remove flag
	offset: 0
	word-sz: target/addr-size
	reg: x86-regs/ebp
	case [
		loc >= r/callee-base [
			reg: x86-regs/esp
			offset: word-sz * (loc - r/callee-base)
		]
		loc >= r/caller-base [
			offset: word-sz * (loc - r/caller-base + 1)		;-- 1 slot for return address
		]
		loc >= r/spill-start [
			offset: word-sz * (loc - r/frame-start + f/spill-args) - f/size
		]
		true [dprint ["invalid stack location: " loc]]
	]
	addr/base: reg
	addr/index: 0
	addr/scale: 1
	addr/disp: offset
]

rrsd-to-addr: func [
	cg		[codegen!]
	p		[ptr-ptr!]
	addr	[x86-addr!]
	/local
		base	[integer!]
		index	[integer!]
		scale	[integer!]
		disp	[integer!]
		b		[operand!]
		i		[operand!]
		imm		[immediate!]
		pp		[ptr-ptr!]
		val		[cell!]
		int		[red-integer!]
][
	pp: p + 3	;-- disp
	imm: as immediate! pp/value
	val: imm/value
	either null? val [disp: 0][
		switch TYPE_OF(val) [
			TYPE_ADDR [
				disp: ABS_ADDR
			]
			TYPE_INTEGER [
				int: as red-integer! val
				disp: int/value
			]
			TYPE_SLOT [
				int: as red-integer! val
				loc-to-addr int/value addr cg/frame cg/reg-set
				exit
			]
			default [disp: 0]
		]
	]
	b: as operand! p/value
	base: either OPERAND_USE?(b) [to-loc b][0]
	p: p + 1
	i: as operand! p/value
	index: either OPERAND_USE?(i) [to-loc i][0]
	p: p + 1
	scale: to-imm as operand! p/value

	addr/base: base
	addr/index: index
	addr/scale: scale
	addr/disp: disp
	addr/ref: as val! val
]

assemble-op: func [
	cg		[codegen!]
	op		[integer!]
	p		[ptr-ptr!]
	/local
		l	[label!]
		lvp [livepoint!]
		c n [integer!]
		f	[operand!]
		val [val!]
		o	[instr-op!]
		imm [immediate!]
		loc [integer!]
		pp	[int-ptr!]
		pos [integer!]
		t	[rst-type!]
		ft	[fn-type!]
		fn	[fn!]
		rset [reg-set!]
		addr [x86-addr! value]
][
	switch x86_OPCODE(op) [
		I_JMP [
			l: as label! p/value
			either l/pos >= 0 [
				asm/jmp-rel l/pos - asm/pos
			][
				asm/jmp-label l
			]
		]
		I_JC [
			l: as label! p/value
			c: x86_COND(op)
			either l/pos >= 0 [
				asm/jc-rel c l/pos - asm/pos
			][
				asm/jc-rel-label c l
			]
		]
		I_CALL [
			f: as operand! p/value
			switch OPERAND_TYPE(f) [
				OD_IMM [
					imm: as immediate! f
					val: as val! imm/value
					assert val/header = TYPE_FUNCTION

					fn: as fn! val/ptr
					either NODE_FLAGS(fn) and RST_IMPORT_FN = 0 [
						asm/call-rel REL_ADDR
					][
						asm/icall-rel REL_ADDR
					]
					record-fn-call fn asm/pos - 4

					p: p + 1
					lvp: as livepoint! p/value
					if lvp/cc/fpu? [
						ft: as fn-type! fn/type
						t: ft/ret-type
						if FLOAT_TYPE?(t) [
							loc-to-addr CALLEE_SPILL_BASE :addr cg/frame cg/reg-set
							either FLOAT_64?(t) [
								asm/fstp-q :addr
							][
								asm/fstp-d :addr
							]
						]
					]
				]
				default [0]
			]
		]
		I_SETC [
			loc: to-loc as operand! p/value
			c: x86_COND(op)
			asm/setc c loc
		]
		I_IDIVD I_DIVD I_IDIVQ I_DIVQ I_IMODD I_IMODQ [
			p: p + 4
			loc: to-loc as operand! p/value
			either target/gpr-reg? loc [
				assemble-r op loc
			][
				loc-to-addr loc :addr cg/frame cg/reg-set
				assemble-m op :addr
			]
		]
		I_FSTP [
			loc: to-loc as operand! p/value
			loc-to-addr loc :addr cg/frame cg/reg-set
			asm/fstp-q :addr
		]
		I_FUNC_PTR [
			loc: to-loc as operand! p/value
			p: p + 1
			imm: as immediate! p/value
			val: as val! imm/value
			assert val/header = TYPE_FUNCTION

			either target/gpr-reg? loc [
				asm/movd-r-i loc ABS_ADDR
			][
				loc-to-addr loc :addr cg/frame cg/reg-set
				asm/movd-m-i :addr ABS_ADDR
			]
			fn: as fn! val/ptr
			record-fn-ref fn asm/pos - 4
		]
		I_CATCH [
			rset: cg/reg-set
			addr/base: x86-regs/ebp
			addr/index: 0
			addr/scale: 1
			imm: as immediate! p/value
			val: as val! imm/value
			pp: val/ptr

			either zero? pp/value [		;-- open catch
				pp/value: asm/pos

				addr/disp: -4
				asm/mov-r-m x86-regs/eax :addr		;-- mov eax, [ebp - 4]
				loc-to-addr pp/3 :addr cg/frame rset
				asm/mov-m-r :addr x86-regs/eax		;-- mov [ebp - x1], eax

				addr/disp: -8
				asm/mov-r-m x86-regs/eax :addr		;-- mov eax, [ebp - 8]
				loc-to-addr pp/4 :addr cg/frame rset
				asm/mov-m-r :addr x86-regs/eax		;-- mov [ebp - x2], eax
				
				asm/mov-r-i x86-regs/eax pp/2		;-- mov eax, catch filter
				addr/disp: -4
				asm/mov-m-r :addr x86-regs/eax
				asm/call-rel 0						;-- call next
				asm/pop-r x86-regs/eax				;-- pop eax
				asm/add-r-i x86-regs/eax 256 NO_REX	;-- add eax, <offset>
				addr/disp: -8
				asm/mov-m-r :addr x86-regs/eax		;-- mov [ebp - 8], eax
			][
				pos: pp/value
				change-at-32 program/code-buf/data pos + 27 asm/pos - pos - 25

				loc-to-addr pp/3 :addr cg/frame rset				
				asm/mov-r-m x86-regs/edi :addr		;-- mov edi, [ebp - x1]
				addr/disp: -4
				asm/mov-m-r :addr x86-regs/edi		;-- mov [ebp - 4], edi

				loc-to-addr pp/4 :addr cg/frame rset
				asm/mov-r-m x86-regs/edi :addr		;-- mov edi, [ebp - x2]
				addr/disp: -8
				asm/mov-m-r :addr x86-regs/edi		;-- mov [ebp - 8], edi
				asm/mov-r-r x86-regs/esp x86-regs/ebp
				n: cg/frame/size - (2 * target/addr-size)	;-- minus return addr and ebp
				asm/sub-r-i x86-regs/esp n NO_REX
			]
		]
		I_THROW [
			addr/base: x86-regs/ebp
			addr/index: 0
			addr/scale: 1
			n: to-imm as operand! p/value
			asm/mov-r-i x86-regs/eax n				;-- mov eax, throw value
			asm/jmp-rel 3							;--			jmp _1st
			asm/leave								;-- _loop:	leave
			addr/disp: -4
			asm/cmp-m-r :addr x86-regs/eax NO_REX	;-- cmp [ebp - 4], eax
			asm/jc-rel jc_carry -4					;-- jb _loop
			addr/disp: -8
			asm/mov-r-m x86-regs/edi :addr			;-- mov edi, [ebp - 8]
			asm/cmp-r-i x86-regs/edi 0 NO_REX		;-- cmp edi, 0
			asm/jc-rel jc_zero 4					;-- jz _end
			asm/jmp-r x86-regs/edi					;-- jmp edi
													;-- _end
		]
		I_SET_SP [
			n: target/addr-size * to-imm as operand! p/value
			either n > 0 [
				asm/sub-r-i x86-regs/esp n NO_REX
			][
				asm/add-r-i x86-regs/esp 0 - n NO_REX
			]
		]
		I_GET_PC [
			loc: to-loc as operand! p/value
			asm/call-rel 0							;-- call next
			either target/gpr-reg? loc [
				asm/pop-r loc
			][
				asm/pop-r x86-regs/edi
				loc-to-addr loc :addr cg/frame cg/reg-set
				assemble-m-r op :addr x86-regs/edi
			]
		]
		I_PUSH [
			n: to-imm as operand! p/value
			asm/push-i n
		]
		default [0]
	]
]

assemble-r: func [
	op		[integer!]
	r		[integer!]
][
	switch op [
		I_NOTD	[asm/not-r r NO_REX]
		I_NEGD	[asm/neg-r r NO_REX]
		I_MULD	[asm/imul-r r NO_REX]
		I_IDIVD	[asm/idiv-r r NO_REX]
		I_SHLD	[asm/shl-r r NO_REX]
		I_SARD	[asm/sar-r r NO_REX]
		I_SHRD	[asm/shr-r r NO_REX]
		I_IMODD [asm/imod-r r NO_REX]
		I_PUSH	[asm/push-r r]
		default [0]
	]
]

assemble-m: func [
	op		[integer!]
	m		[x86-addr!]
][
	switch op [
		I_NOTD	[asm/not-m m NO_REX]
		I_NEGD	[asm/neg-m m NO_REX]
		I_MULD	[asm/imul-m m NO_REX]
		I_IDIVD	[asm/idiv-m m NO_REX]
		I_SHLD	[asm/shl-m m NO_REX]
		I_SARD	[asm/sar-m m NO_REX]
		I_SHRD	[asm/shr-m m NO_REX]
		I_IMODD [asm/imod-m m NO_REX]
		I_PUSH	[asm/push-m m]
		default [0]
	]
]

assemble-r-r: func [
	op		[integer!]
	a		[integer!]
	b		[integer!]
][
	switch op [
		I_MOVD [asm/movd-r-r a b]
		I_MOVQ [asm/movq-r-r a b]
		I_MOVB [asm/movb-r-r a b]
		I_MOVBSX [asm/movbsx-r-r a b]
		I_MOVBZX [asm/movbzx-r-r a b]
		I_MOVWSX [asm/movwsx-r-r a b]
		I_MOVWZX [asm/movwzx-r-r a b]
		I_ADDD [asm/add-r-r a b NO_REX]
		I_ORD  [asm/or-r-r a b NO_REX]
		I_ADCD [asm/adc-r-r a b NO_REX]
		I_ANDD [asm/and-r-r a b NO_REX]
		I_SUBD [asm/sub-r-r a b NO_REX]
		I_XORD [asm/xor-r-r a b NO_REX]
		I_CMPD [asm/cmp-r-r a b NO_REX]
		I_CMPB [asm/cmpb-r-r a b]
		I_MULD [asm/imul-r-r a b NO_REX]
		I_CDQ  [asm/cdq]
		I_CQO  [asm/cqo]
		default [0]
	]
]

assemble-r-m: func [
	op		[integer!]
	a		[integer!]
	m		[x86-addr!]
][
	switch op [
		I_MOVD [asm/movd-r-m a m]
		I_MOVQ [asm/movq-r-m a m]
		I_MOVB [asm/movb-r-m a m]
		I_MOVBSX [asm/movbsx-r-m a m]
		I_MOVBZX [asm/movbzx-r-m a m]
		I_MOVW	 [asm/movw-r-m a m]
		I_MOVWSX [asm/movwsx-r-m a m]
		I_MOVWZX [asm/movwzx-r-m a m]
		I_ADDD [asm/add-r-m a m NO_REX]
		I_ORD  [asm/or-r-m a m NO_REX]
		I_ADCD [asm/adc-r-m a m NO_REX]
		I_ANDD [asm/and-r-m a m NO_REX]
		I_SUBD [asm/sub-r-m a m NO_REX]
		I_XORD [asm/xor-r-m a m NO_REX]
		I_CMPD [asm/cmp-r-m a m NO_REX]
		I_CMPB [asm/cmpb-r-m a m]
		I_MULD [asm/imul-r-m a m NO_REX]
		I_LEAD [asm/lea a m]
		I_LEAQ [asm/leaq a m]
		default [0]
	]
]

assemble-r-i: func [
	op		[integer!]
	r		[integer!]
	imm		[integer!]
][
	switch op [
		I_MOVD [asm/movd-r-i r imm]
		I_MOVQ [asm/movq-r-i r imm]
		I_ADDD [asm/add-r-i r imm NO_REX]
		I_ORD  [asm/or-r-i r imm NO_REX]
		I_ADCD [asm/adc-r-i r imm NO_REX]
		I_ANDD [asm/and-r-i r imm NO_REX]
		I_SUBD [asm/sub-r-i r imm NO_REX]
		I_XORD [asm/xor-r-i r imm NO_REX]
		I_CMPD [asm/cmp-r-i r imm NO_REX]
		I_CMPB [asm/cmpb-r-i r imm]
		I_MULD [asm/imul-r-i r imm NO_REX]
		I_SHLD [asm/shl-r-i r imm NO_REX]
		I_SARD [asm/sar-r-i r imm NO_REX]
		I_SHRD [asm/shr-r-i r imm NO_REX]
		default [0]
	]
]

assemble-m-i: func [
	op		[integer!]
	m		[x86-addr!]
	imm		[integer!]
][
	switch op [
		I_MOVD [asm/movd-m-i m imm]
		I_MOVQ [asm/movq-m-i m imm]
		I_MOVB [asm/movb-m-i m imm]
		I_MOVW [asm/movw-m-i m imm]
		I_ADDD [asm/add-m-i m imm NO_REX]
		I_ORD  [asm/or-m-i m imm NO_REX]
		I_ADCD [asm/adc-m-i m imm NO_REX]
		I_ANDD [asm/and-m-i m imm NO_REX]
		I_SUBD [asm/sub-m-i m imm NO_REX]
		I_XORD [asm/xor-m-i m imm NO_REX]
		I_CMPD [asm/cmp-m-i m imm NO_REX]
		I_CMPB [asm/cmpb-m-i m imm]
		I_SHLD [asm/shl-m-i m imm NO_REX]
		I_SARD [asm/sar-m-i m imm NO_REX]
		I_SHRD [asm/shr-m-i m imm NO_REX]
		default [0]
	]
]

assemble-m-r: func [
	op		[integer!]
	m		[x86-addr!]
	a		[integer!]
][
	switch op [
		I_MOVD [asm/movd-m-r m a]
		I_MOVQ [asm/movq-m-r m a]
		I_MOVB [asm/movb-m-r m a]
		I_MOVW [asm/movw-m-r m a]
		I_ADDD [asm/add-m-r m a NO_REX]
		I_ORD  [asm/or-m-r m a NO_REX]
		I_ADCD [asm/adc-m-r m a NO_REX]
		I_ANDD [asm/and-m-r m a NO_REX]
		I_SUBD [asm/sub-m-r m a NO_REX]
		I_XORD [asm/xor-m-r m a NO_REX]
		I_CMPD [asm/cmp-m-r m a NO_REX]
		I_CMPB [asm/cmpb-m-r m a]
		default [0]
	]
]

assemble-s-s: func [	;-- sse registers
	op		[integer!]
	a		[integer!]
	b		[integer!]
][
	switch op [
		I_ADDSS 	[asm/addss-s-s a b]
		I_SUBSS 	[asm/subss-s-s a b]
		I_MULSS 	[asm/mulss-s-s a b]
		I_DIVSS 	[asm/divss-s-s a b]
		I_SQRTSS	[asm/sqrtss-s-s a b]
		I_ADDSD 	[asm/addsd-s-s a b]
		I_SUBSD 	[asm/subsd-s-s a b]
		I_MULSD 	[asm/mulsd-s-s a b]
		I_DIVSD 	[asm/divsd-s-s a b]
		I_SQRTSD	[asm/sqrtsd-s-s a b]
		I_MOVSS		[asm/movss-s-s a b]
		I_MOVSD		[asm/movsd-s-s a b]
		I_UCOMISS	[asm/ucomiss-s-s a b]
		I_UCOMISD	[asm/ucomisd-s-s a b]
		default		[0]
	]
]

assemble-s-m: func [	;-- sse register, memory address
	op		[integer!]
	a		[integer!]
	m		[x86-addr!]
][
	switch op [
		I_ADDSS 	[asm/addss-s-m a m]
		I_SUBSS 	[asm/subss-s-m a m]
		I_MULSS 	[asm/mulss-s-m a m]
		I_DIVSS 	[asm/divss-s-m a m]
		I_SQRTSS	[asm/sqrtss-s-m a m]
		I_ADDSD 	[asm/addsd-s-m a m]
		I_SUBSD 	[asm/subsd-s-m a m]
		I_MULSD 	[asm/mulsd-s-m a m]
		I_DIVSD 	[asm/divsd-s-m a m]
		I_SQRTSD	[asm/sqrtsd-s-m a m]
		I_MOVSS		[asm/movss-s-m a m]
		I_MOVSD		[asm/movsd-s-m a m]
		I_UCOMISS	[asm/ucomiss-s-m a m]
		I_UCOMISD	[asm/ucomisd-s-m a m]
		default		[0]
	]
]

assemble-m-s: func [
	op		[integer!]
	m		[x86-addr!]
	a		[integer!]
][
	switch op [
		I_MOVSS		[asm/movss-m-s m a]
		I_MOVSD		[asm/movsd-m-s m a]
		default		[0]
	]
]

assemble-s-r: func [	;-- sse register, gpr
	op		[integer!]
	s		[integer!]
	r		[integer!]
][
	switch op [
		I_MOVSS		[asm/movd-s-r s r]
		I_MOVSD		[asm/movq-s-r s r]
		default		[0]
	]
]

assemble-r-s: func [
	op		[integer!]
	r		[integer!]
	s		[integer!]
][
	switch op [
		I_MOVSS		[asm/movd-r-s r s]
		I_MOVSD		[asm/movq-r-s r s]
		default		[0]
	]
]

assemble: func [
	cg		[codegen!]
	i		[mach-instr!]
	/local
		op	[integer!]
		m	[integer!]
		reg [integer!]
		loc [integer!]
		imm [integer!]
		l	[label!]
		p	[ptr-ptr!]
		ins [integer!]
		rset [reg-set!]
		addr [x86-addr! value]
][
	rset: cg/reg-set
	ins: i/header
	op: x86_OPCODE(ins)
	p: as ptr-ptr! i + 1		;-- point to operands
	if op >= I_NOP [
		switch op [
			I_ENTRY [
				asm/push-r x86-regs/ebp
				asm/mov-r-r x86-regs/ebp x86-regs/esp
				asm/push-i 0	;-- init catch value
				asm/push-i 0	;-- init catch address
				adjust-frame cg/frame no
			]
			I_BLK_BEG [
				l: as label! p/value
				l/pos: asm/pos
			]
			I_RET [
				asm/leave
				asm/ret
			]
			default [0]
		]
		exit
	]

	m: i/header >> AM_SHIFT and 1Fh
	switch m [
		_AM_NONE [assemble-op cg ins p]
		_AM_REG_OP [
			reg: to-loc as operand! p/value
			assert reg <> 0
			p: p + 1
			loc: to-loc as operand! p/value
			either target/gpr-reg? loc [
				assemble-r-r op reg loc
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-r-m op reg :addr
			]
		]
		_AM_RRSD_REG [
			rrsd-to-addr cg p :addr
			p: p + 4
			reg: to-loc as operand! p/value
			assemble-m-r op :addr reg
		]
		_AM_RRSD_IMM [
			rrsd-to-addr cg p :addr
			p: p + 4
			imm: to-imm as operand! p/value
			assemble-m-i op :addr imm
		]
		_AM_REG_RRSD [
			reg: to-loc as operand! p/value
			rrsd-to-addr cg p + 1 :addr
			assemble-r-m op reg :addr
		]
		_AM_OP [
			loc: to-loc as operand! p/value
			either target/gpr-reg? loc [
				assemble-r op loc
			][
				loc-to-addr loc :addr cg/frame rset	
				assemble-m op :addr
			]
		]
		_AM_OP_IMM [
			loc: to-loc as operand! p/value
			p: p + 1
			imm: to-imm as operand! p/value
			either target/gpr-reg? loc [
				assemble-r-i op loc imm
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-m-i op :addr imm
			]
		]
		_AM_OP_REG [
			loc: to-loc as operand! p/value
			p: p + 1
			reg: to-loc as operand! p/value
			either target/gpr-reg? loc [
				assemble-r-r op loc reg
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-m-r op :addr reg
			]
		]
		_AM_XMM_REG [
			reg: to-xmmr as operand! p/value
			p: p + 1
			assemble-s-r op reg to-loc as operand! p/value
		]
		_AM_XMM_OP [
			reg: to-xmmr as operand! p/value
			p: p + 1
			loc: to-loc as operand! p/value
			either target/xmm-reg? loc [
				assemble-s-s op reg target/to-xmm-reg loc
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-s-m op reg :addr
			]
		]
		_AM_OP_XMM [
			loc: to-loc as operand! p/value
			p: p + 1
			reg: to-xmmr as operand! p/value
			either target/xmm-reg? loc [
				assemble-s-s op target/to-xmm-reg loc reg
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-m-s op addr reg
			]
		]
		_AM_XMM_RRSD [
			reg: to-xmmr as operand! p/value
			rrsd-to-addr cg p + 1 :addr
			assemble-s-m op reg :addr
		]
		_AM_RRSD_XMM [
			rrsd-to-addr cg p :addr
			p: p + 4
			reg: to-xmmr as operand! p/value
			assemble-m-s op :addr reg
		]
		_AM_XMM_IMM [
			reg: to-xmmr as operand! p/value
		]
		_AM_REG_XOP [
			reg: to-loc as operand! p/value
			p: p + 1
			loc: to-loc as operand! p/value
			either target/xmm-reg? loc [
				assemble-r-s op reg target/to-xmm-reg loc
			][
				loc-to-addr loc :addr cg/frame rset
				assemble-r-m op reg addr
			]
		]
		_AM_XMM_XMM [
			reg: to-xmmr as operand! p/value
			p: p + 1
			assemble-s-s op reg to-xmmr as operand! p/value
		]
		default [0]
	]
]