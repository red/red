Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %system.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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

;-- FPU values for system/fpu/status
#either target = 'ARM [
	#define FPU_EXCEPTION_INVALID_OP	 1		;-- Invalid Operation
	#define FPU_EXCEPTION_ZERO_DIVIDE	 2		;-- Zero Divide
	#define FPU_EXCEPTION_OVERFLOW		 4		;-- Overflow
	#define FPU_EXCEPTION_UNDERFLOW		 8		;-- Underflow
	#define FPU_EXCEPTION_PRECISION		 16		;-- Precision
	#define FPU_EXCEPTION_DENORMAL_OP	 128	;-- Denormalized Operand
][
	#define FPU_EXCEPTION_INVALID_OP	 1		;-- Invalid Operation
	#define FPU_EXCEPTION_DENORMAL_OP	 2		;-- Denormalized Operand
	#define FPU_EXCEPTION_ZERO_DIVIDE	 4		;-- Zero Divide
	#define FPU_EXCEPTION_OVERFLOW		 8		;-- Overflow
	#define FPU_EXCEPTION_UNDERFLOW		 16		;-- Underflow
	#define FPU_EXCEPTION_PRECISION		 32		;-- Precision
]

heap-frame!: alias struct! [				;-- LibC malloc frame header
	prev	[heap-frame!]					;-- previous frame or null
	next	[heap-frame!]					;-- next frame or null
	size	[integer!]						;-- size of allocated buffer in bytes
	padding [integer!]						;-- preserve eventual 128-bit alignment 
]

__heap!: alias struct! [
	head	[heap-frame!]					;-- first element of heap-allocated frames list
	tail	[heap-frame!]					;-- last  element of heap-allocated frames list
]

__stack!: alias struct! [
	top		[int-ptr!]
	frame	[int-ptr!]
	align	[int-ptr!]
]

__image!: alias struct! [
	base	  [byte-ptr!]					;-- base image address in memory
	code	  [integer!]					;-- code segment offset
	code-size [integer!]					;-- code segment size
	data	  [integer!]					;-- data segment offset
	data-size [integer!]					;-- data segment size
	bitarray  [integer!]					;-- offset for function args+locals pointer! bitmaps
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
			status		 [integer!]
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
			status		 [integer!]
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
	image		[__image!]					;-- executable image memory layout info
	heap		[__heap!]					;-- dynamically allocated memory frames
	stk-root	[int-ptr!]
]

#either any [libRedRT? = yes dev-mode? = no red-pass? = no][
	system: declare system!
	#if all [libRedRT? = yes dev-mode? = yes][#export [system]]	;-- exclude it from libRed
][
	#import [LIBREDRT-file stdcall [system: "system" [system!]]]
]

***-exec-image: declare __image!			;-- reference ***-exec-image used by compiler to fill the slots

#if any [red-pass? = no all [type = 'exe dev-mode? = no]][
	system/image: ***-exec-image			;-- set /image fields for standalone exe only (no libRedRT)
]											;-- for libraries, it's set at library loading time.

system/heap: declare __heap!
system/heap/head: null
system/heap/tail: null