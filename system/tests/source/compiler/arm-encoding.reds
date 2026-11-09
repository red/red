Red/System [
	Title:   "Red/System ARM instruction encoding test source"
	File: 	 %arm-encoding.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;-- Compiled for Linux-ARM by arm-encoding-test.r, which checks the emitted code; never run.

arm-enc-fn!: alias function! [a [integer!] return: [integer!]]

arm-enc-inc: func [a [integer!] return: [integer!]][a + 1]

arm-enc-fptrs: declare struct! [f [arm-enc-fn!]]
arm-enc-fptrs/f: as arm-enc-fn! :arm-enc-inc

arm-enc-peek: func [
	return: [integer!]
	/local
		x	[integer!]
		p	[int-ptr!]
][
	x: 5
	p: :x											;-- address of a local: no MOVW below cpu-version 7.0
	p/value
]

arm-enc-below?: func [
	b		[byte!]
	return: [logic!]
][
	b < as byte! 65									;-- byte! comparison: CMP r3, r1, LSL #24
]

arm-enc-is-a?: func [
	b		[byte!]
	return: [logic!]
][
	b = #"A"										;-- with a literal: CMP r3, #41000000h
]

#syscall [
	arm-enc-sys: 300 [return: [integer!]]			;-- number above 255
]

arm-enc-state: 0

arm-enc-fptrs/f 41									;-- call through a function pointer: BLX r10
arm-enc-peek
arm-enc-below? as byte! 17
system/atomic/store :arm-enc-state 1				;-- memory fence: no DMB below cpu-version 7.0
arm-enc-is-a? as byte! 66
arm-enc-sys
system/fpu/mask/zero-divide: yes					;-- masked: BIC of the trap-enable bit
system/fpu/mask/overflow: no						;-- unmasked: ORR
arm-enc-state: system/fpu/status
system/stack/push-all
system/stack/pop-all
