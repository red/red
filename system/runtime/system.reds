Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %system.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- FPU types returned by system/fpu/type
#define FPU_TYPE_X87	1					;-- Intel x87 unit
#define FPU_TYPE_SSE	2					;-- Intel SSE floating point unit
#define FPU_TYPE_VFP	3					;-- ARM Vector Floating Point unit

;-- FPU values for system/fpu/option/rounding
#define FPU_X87_ROUNDING_NEAREST	 0		;-- (even) rounded result is the closest to the infinitely precise result
#define FPU_X87_ROUNDING_DOWN		 1		;-- (toward -INF) rounded result is the closest to but no greater than the infinitely precise result
#define FPU_X87_ROUNDING_UP			 2		;-- (toward +INF) rounded result is the closest to but no less than the infinitely precise result
#define FPU_X87_ROUNDING_ZERO		 3		;-- (truncate) rounded result is the closest to but no greater in absolute value than the infinitely precise result

#define FPU_VFP_ROUNDING_NEAREST	 0		;-- (even) rounded result is the closest to the infinitely precise result
#define FPU_VFP_ROUNDING_UP			 1		;-- (toward +INF) rounded result is the closest to but no less than the infinitely precise result
#define FPU_VFP_ROUNDING_DOWN		 2		;-- (toward -INF) rounded result is the closest to but no greater than the infinitely precise result
#define FPU_VFP_ROUNDING_ZERO		 3		;-- (truncate) rounded result is the closest to but no greater in absolute value than the infinitely precise result

;-- FPU values for system/fpu/option/precision
#define FPU_X87_PRECISION_SINGLE	 0		;-- 32-bit float, 24-bit mantissa
#define FPU_X87_PRECISION_DOUBLE	 2		;-- 64-bit float, 53-bit mantissa
#define FPU_X87_PRECISION_DOUBLE_EXT 3		;-- 80-bit float, 64-bit mantissa

__stack!: alias struct! [
	top		[int-ptr!]
	frame	[int-ptr!]
	align	[int-ptr!]
]

FPU-exceptions-mask!: alias struct! [		;-- standard exception mask (true => mask exception)
	precision	[logic!]
	underflow	[logic!]
	overflow	[logic!]
	zero-divide [logic!]
	denormal	[logic!]
	invalid-op  [logic!]
]

#switch target [
	IA-32 [
		x87-option!: alias struct! [
			rounding	[integer!]
			precision	[integer!]
		]
		
		__fpu-struct!: alias struct! [
			type		 [integer!]
			option		 [x87-option!]
			mask		 [FPU-exceptions-mask!]
			control-word [integer!]			;-- direct access to whole control word
			epsilon		 [integer!]			;-- Ulp threshold for almost-equal op (not used yet)
			update		 [integer!]			;-- action simulated using a read-only member
			init		 [integer!]			;-- action simulated using a read-only member
		]
		
		__cpu-struct!: alias struct! [
			eax			[integer!]
			ebx			[integer!]
			ecx			[integer!]
			edx			[integer!]
			esp			[integer!]
			ebp			[integer!]
			esi			[integer!]
			edi			[integer!]
			overflow?	[logic!]
		]
	]
	ARM [	
		VFP-option!: alias struct! [
			rounding		[integer!]
			flush-to-zero	[logic!]
			NaN-mode		[logic!]
		]
		
		__fpu-struct!: alias struct! [
			type		 [integer!]
			option		 [VFP-option!]
			mask		 [FPU-exceptions-mask!]
			control-word [integer!]			;-- direct access to whole control word
			epsilon		 [integer!]			;-- Ulp threshold for almost-equal op (not used yet)
			update		 [integer!]			;-- action simulated using a read-only member
			init		 [integer!]			;-- action simulated using a read-only member
		]
		
		__cpu-struct!: alias struct! [
			r0			[integer!]
			r1			[integer!]
			r2			[integer!]
			r3			[integer!]
			r4			[integer!]
			r5			[integer!]
			r6			[integer!]
			r7			[integer!]
			r8			[integer!]
			r9			[integer!]
			r10			[integer!]
			r11			[integer!]
			r12			[integer!]
			r13			[integer!]
			r14			[integer!]
			r15			[integer!]
			overflow?	[logic!]
		]

	]
]

system!: alias struct! [					;-- store runtime accessible system values
	args-count	[integer!]					;-- command-line arguments count (do not move member)
	args-list	[str-array!]				;-- command-line arguments array pointer (do not move member)
	env-vars 	[str-array!]				;-- environment variables array pointer (always null for Windows)
	stack		[__stack!]					;-- stack virtual access
	pc			[byte-ptr!]					;-- CPU program counter value
	cpu			[__cpu-struct!]				;-- CPU registers
	fpu			[__fpu-struct!]				;-- FPU settings
	alias		[integer!]					;-- aliases ID virtual access
	words		[integer!]					;-- global context accessor (dummy type)
	thrown		[integer!]					;-- last THROWn value
	boot-data	[byte-ptr!]					;-- Redbin encoded boot data (only for Red programs)
	debug		[__stack!]					;-- stack info for debugging (set on runtime error only, internal use)
]

#either libRedRT? = yes [
	system: declare system!
	#if dev-mode? = yes [#export [system]]	;-- exclude it from libRed
][
	#either dev-mode? = no [
		system: declare system!
	][
		#either red-pass? = no [
			system: declare system!
		][
			#import [LIBREDRT-file stdcall [system: "system" [system!]]]
		]
	]
]
