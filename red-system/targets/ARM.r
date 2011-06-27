REBOL [
	Title:		"Red/System ARM code emitter"
	Author:		"Andreas Bolka"
	File:		%ARM.r
	Rights:		"Copyright (C) 2011 Andreas Bolka. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; AAPCS:
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
	branch-offset-size:	4				;-- @@ ?

	instruction-buffer: make binary! 4

	ei32: func [bin [binary! char! block!]] [
		;; To allow more natural emission of 32-bit instructions, "ei32"
		;; collects data in big-endian and emits it as 32-bit chunks in the
		;; target's native endianness.
		append instruction-buffer bin
		if (length? instruction-buffer) >= 4 [
			emit to-bin32 to-integer take/part instruction-buffer 4
		]
	]

	emit-load-integer: func [value [integer!]] [
		;; @@ we currently store full 32-bit integer immediates directly in the
		;; instruction stream. should probably use a literal pool instead.
		ei32 #{e49f0000}				;-- ldr r0, [pc], #0
		ei32 #{e1a00000}				;-- nop
		emit to-bin32 value				;-- <value>
	]

	emit-load: func [
		value [char! logic! integer! word! string! path! get-word! struct! paren!]
	] [
		if verbose >= 3 [print [">>>loading" mold value]]

		switch/default type?/word value [
			integer! [
				emit-load-integer value
			]
		] [
			compiler/throw-error join "[codegen] nyi load: " type?/word value
		]
	]

	emit-push: func [
		value [char! logic! integer! word! string! path! get-word! block! tag!]
	] [
		if verbose >= 3 [print [">>>pushing" mold value]]

		switch/default type?/word value [
			integer! [
				emit-load-integer value
				ei32 #{e92d0001}				;-- push {r0}
			]
		] [
			compiler/throw-error join "[codegen] nyi push: " type?/word value
		]
	]

	emit-call-syscall: func [number nargs] [
		ei32 #{e8bd00}					;-- pop {r0, .., r<nargs>}
		ei32 shift #{ff} 8 - nargs
		ei32 #{e3a070}					;-- mov r7, <number>
		ei32 to-bin8 number
		ei32 #{ef000000}				;-- svc 0			; @@ EABI syscall
	]

	emit-call-native: func [spec] [
		add-native-reloc spec :reloc-bl
		ei32 #{eb000000}				;-- bl <disp>
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
		repeat i args-size [
			ei32 #{e92d00}							;-- push {r<n>}
			ei32 shift/left #{01} (args-size - i)
		]
		unless zero? args-size [
			ei32 #{e1a0c00d}						;-- mov ip, sp
		]
		ei32 #{e92d4ff0}							;-- stmfd sp!, {r4-r11, lr}
		unless zero? args-size [
			ei32 #{e1a0b00c}						;-- mov fp, ip
		]
	]

	emit-epilog: func [name locals [block!] locals-size [integer!]][
		if verbose >= 3 [print [">>>building:" uppercase mold to-word name "epilog"]]

		unless zero? locals-size [
			;; Restore sp to where we saved our 9 callee-saved registers.
			ei32 #{e28bd024}						;-- add sp, fp, #36
		]
		ei32 #{e8bd8ff0}							;-- ldmfd sp!, {r4-r11, pc}
	]
]
