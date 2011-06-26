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

	emit-push-integer: func [value [integer!]] [
		;; @@ we currently store full 32-bit integer immediates directly in the
		;; instruction stream. should probably use a literal pool instead.
		emit #{00009fe4}				;-- ldr r0, [pc], #0
		emit #{0000a0e1}				;-- nop
		emit to-bin32 value
		emit #{01002de9}				;-- push {r0}
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
		emit shift #{FF} 8 - nargs
		emit #{00bde8}					;-- pop {r0, .., r<nargs>}
		emit to-bin8 number
		emit #{70a0e3}					;-- mov r7, <number>
		emit #{000000ef}				;-- svc 0			; @@ EABI syscall
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
