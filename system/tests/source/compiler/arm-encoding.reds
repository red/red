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

arm-enc-fptrs/f 41									;-- call through a function pointer: BLX r10
arm-enc-peek
arm-enc-below? as byte! 17
