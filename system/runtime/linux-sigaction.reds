Red/System [
	Title:   "Red/System Linux based systems signal structs"
	Author:  "Nenad Rakocevic"
	File: 	 %linux-sigaction.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#either OS = 'Android [						;-- Damn FrankenSystem!
	sigaction!: alias struct! [
		sigaction	[integer!]				;-- Warning: compiled as C union on most UNIX
		mask		[integer!]				;-- bit array
		flags		[integer!]
		;... remaining fields skipped
	]
][
	sigaction!: alias struct! [
		sigaction	[integer!]				;-- Warning: compiled as union on most UNIX
		mask0		[integer!]				;-- glibc/Hurd insane inheritage...
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
	]
]

siginfo!: alias struct! [
	signal		[integer!]
	error		[integer!]
	code		[integer!]
	address		[integer!]					;-- this field is a C union, dependent on signal
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
	]
]

#define UCTX_INSTRUCTION(ctx) [
	#switch target [
		IA-32 [ctx/eip]
		ARM	  [ctx/arm_pc]
	]
]

#define UCTX_GET_STACK_TOP(ctx) [
	#switch target [
		IA-32 [ctx/esp]
		ARM	  [ctx/arm_sp]
	]
]

#define UCTX_GET_STACK_FRAME(ctx) [
	#switch target [
		IA-32 [ctx/ebp]
		ARM	  [ctx/arm_fp]
	]
]
