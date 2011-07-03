REBOL [
	Title:		"Red/System ARM code emitter"
	Author:		"Andreas Bolka"
	File:		%ARM.r
	Rights:		"Copyright (C) 2011 Andreas Bolka. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

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

	emit-push-integer: func [value [integer!]] [
		;; @@ we currently store full 32-bit integer immediates directly in the
		;; instruction stream. should probably use a literal pool instead.
		ei32 #{e49f0000}				;-- ldr r0, [pc], #0
		ei32 #{e1a00000}				;-- nop
		emit to-bin32 value				;-- <value>
		ei32 #{e92d0001}				;-- push {r0}
	]

	emit-push: func [
		value [char! logic! integer! word! string! path! get-word! block! tag!]
	] [
		if verbose >= 3 [print [">>>pushing" mold value]]

		switch/default type?/word value [
			integer! [
				emit-push-integer value
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

	emit-call: func [name [word!] args [block!] sub? [logic!] /local spec fspec] [
		if verbose >= 3 [print [">>>calling:" mold name mold args]]

		fspec: select compiler/functions name
		spec: any [select emitter/symbols name next fspec]
		type: first spec

		switch/default type [
			syscall [
				emit-call-syscall last fspec fspec/1
			]
		] [
			compiler/throw-error join "[codegen] nyi call: " type
		]
	]
]
