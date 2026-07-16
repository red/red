Red/System [
	Title:   "Red/System Linux based systems signal structs"
	Author:  "Nenad Rakocevic"
	File: 	 %linux-sigaction.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#either OS = 'Android [						;-- Damn FrankenSystem!
	sigaction!: alias struct! [
		sigaction	[byte-ptr!]				;-- Warning: compiled as C union on most UNIX
		mask		[integer!]				;-- bit array
		flags		[integer!]
		;... remaining fields skipped
	]
][
	sigaction!: alias struct! [
		sigaction	[byte-ptr!]				;-- Warning: compiled as union on most UNIX
		mask		[integer!]				;-- glibc/Hurd insane inheritage...
		mask1		[integer!]
		mask2		[integer!]
		mask3		[integer!]
		mask4		[integer!]
		mask5		[integer!]
		mask6		[integer!]
		mask7		[integer!]
		mask8		[integer!]
		mask9		[integer!]
		mask10		[integer!]
		mask11		[integer!]
		mask12		[integer!]
		mask13		[integer!]
		mask14		[integer!]
		mask15		[integer!]
		mask16		[integer!]
		mask17		[integer!]
		mask18		[integer!]
		mask19		[integer!]
		mask20		[integer!]
		mask21		[integer!]
		mask22		[integer!]
		mask23		[integer!]
		mask24		[integer!]
		mask25		[integer!]
		mask26		[integer!]
		mask27		[integer!]
		mask28		[integer!]
		mask29		[integer!]
		mask30		[integer!]
		mask31		[integer!]
		flags		[integer!]
		restorer	[byte-ptr!]
	]
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	address		[byte-ptr!]					;-- this field is a C union, dependent on signal
]

#define UCTX_DEFINITION [
	#switch target [
		IA-32 [
			_ucontext!: alias struct! [
				flags 		[integer!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_flags	[integer!]
				ss_size		[integer!]
				gs			[integer!]			;-- sigcontext struct inlined
				fs			[integer!]
				es			[integer!]
				ds			[integer!]
				edi			[integer!]
				esi			[integer!]
				ebp			[integer!]
				esp			[integer!]
				ebx			[integer!]
				edx			[integer!]
				ecx			[integer!]
				eax			[integer!]
				trapno		[integer!]
				err			[integer!]
				eip			[integer!]
				cs			[integer!]
				eflags		[integer!]
				esp_at_sig	[integer!]
				ss			[integer!]
				fpstate		[int-ptr!]
				oldmask		[integer!]
				cr2			[integer!]
				;sigmask	[...]				;-- 128 byte array ignored
			]
		]
		X86-64 [
			_ucontext!: alias struct! [
				flags 		[int-ptr!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_flags	[integer!]
				ss_pad		[integer!]			;-- align ss_size on 64-bit
				ss_size		[int-ptr!]
				r8			[int-ptr!]			;-- sigcontext gregset inlined
				r9			[int-ptr!]
				r10			[int-ptr!]
				r11			[int-ptr!]
				r12			[int-ptr!]
				r13			[int-ptr!]
				r14			[int-ptr!]
				r15			[int-ptr!]
				rdi			[int-ptr!]
				rsi			[int-ptr!]
				rbp			[int-ptr!]
				rbx			[int-ptr!]
				rdx			[int-ptr!]
				rax			[int-ptr!]
				rcx			[int-ptr!]
				rsp			[int-ptr!]
				rip			[int-ptr!]
				eflags		[int-ptr!]
				cs			[int-ptr!]
				gs			[int-ptr!]
				fs			[int-ptr!]
				err			[int-ptr!]
				trapno		[int-ptr!]
				oldmask		[int-ptr!]
				cr2			[int-ptr!]
				fpstate		[int-ptr!]
				;sigmask	[...]				;-- 128 byte array ignored
			]
		]
		ARM [
			_ucontext!: alias struct! [
				flags 		[integer!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]			;-- stack_t struct inlined
				ss_flags	[integer!]
				ss_size		[integer!]
				trap_no		[integer!]
				error_code	[integer!]
				oldmask		[integer!]
				arm_r0		[integer!]
				arm_r1		[integer!]
				arm_r2		[integer!]
				arm_r3		[integer!]
				arm_r4		[integer!]
				arm_r5		[integer!]
				arm_r6		[integer!]
				arm_r7		[integer!]
				arm_r8		[integer!]
				arm_r9		[integer!]
				arm_r10		[integer!]
				arm_fp		[integer!]
				arm_ip		[integer!]
				arm_sp		[integer!]
				arm_lr		[integer!]
				arm_pc		[integer!]
				arm_cpsr	[integer!]
				fault_address [integer!]
				;sigmask	[...]				;-- 128 byte array ignored
			]
		]
		ARM64 [
			_a64-sigset!: alias struct! [
				m0 [integer!] m1 [integer!] m2 [integer!] m3 [integer!]
				m4 [integer!] m5 [integer!] m6 [integer!] m7 [integer!]
				m8 [integer!] m9 [integer!] m10 [integer!] m11 [integer!]
				m12 [integer!] m13 [integer!] m14 [integer!] m15 [integer!]
				m16 [integer!] m17 [integer!] m18 [integer!] m19 [integer!]
				m20 [integer!] m21 [integer!] m22 [integer!] m23 [integer!]
				m24 [integer!] m25 [integer!] m26 [integer!] m27 [integer!]
				m28 [integer!] m29 [integer!] m30 [integer!] m31 [integer!]
			]
			_ucontext!: alias struct! [
				flags		[int-ptr!]
				link		[_ucontext!]
				ss_sp		[byte-ptr!]
				ss_flags	[integer!]
				ss_pad		[integer!]
				ss_size		[int-ptr!]
				sigmask		[_a64-sigset!]
				mc_pad0		[integer!]
				mc_pad1		[integer!]
				fault_address [int-ptr!]
				x0 [int-ptr!] x1 [int-ptr!] x2 [int-ptr!] x3 [int-ptr!]
				x4 [int-ptr!] x5 [int-ptr!] x6 [int-ptr!] x7 [int-ptr!]
				x8 [int-ptr!] x9 [int-ptr!] x10 [int-ptr!] x11 [int-ptr!]
				x12 [int-ptr!] x13 [int-ptr!] x14 [int-ptr!] x15 [int-ptr!]
				x16 [int-ptr!] x17 [int-ptr!] x18 [int-ptr!] x19 [int-ptr!]
				x20 [int-ptr!] x21 [int-ptr!] x22 [int-ptr!] x23 [int-ptr!]
				x24 [int-ptr!] x25 [int-ptr!] x26 [int-ptr!] x27 [int-ptr!]
				x28 [int-ptr!] x29 [int-ptr!] x30 [int-ptr!]
				sp [int-ptr!]
				pc [int-ptr!]
				pstate [int-ptr!]
			]
		]
	]
]

#define UCTX_INSTRUCTION(ctx) [
	#switch target [
		IA-32 [ctx/eip]
		X86-64 [ctx/rip]
		ARM	  [ctx/arm_pc]
		ARM64  [ctx/pc]
	]
]

#define UCTX_GET_STACK_TOP(ctx) [
	#switch target [
		IA-32 [ctx/esp]
		X86-64 [ctx/rsp]
		ARM	  [ctx/arm_sp]
		ARM64  [ctx/sp]
	]
]

#define UCTX_GET_STACK_FRAME(ctx) [
	#switch target [
		IA-32 [ctx/ebp]
		X86-64 [ctx/rbp]
		ARM	  [ctx/arm_fp]
		ARM64  [ctx/x29]
	]
]
