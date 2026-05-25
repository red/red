Red/System [
	Title:   "Red/System int64!/uint64! datatype test script"
	Author:  "Red Foundation"
	File: 	 %int64-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

#if any [target = 'IA-32 target = 'ARM] [

i64-parts!: alias struct! [lo [integer!] hi [integer!]]

i64-add-one: func [
	value	[int64!]
	return: [int64!]
][
	value + 1
]

u64-id: func [
	value	[uint64!]
	return: [uint64!]
][
	value
]

]

#if target = 'IA-32 [

i64-zero?: func [
	value	[int64!]
	return: [logic!]
][
	value = 0000000000000000h
]

]

~~~start-file~~~ "int64"

#if target = 'IA-32 [

===start-group=== "64-bit literal and assignment tests"

	--test-- "i64-lit-1"
		--assert 0000000100000000h = 4294967296

	--test-- "i64-lit-2"
		--assert 7FFFFFFFFFFFFFFFh = 9223372036854775807

	--test-- "i64-lit-3"
		i64-a: 4294967296
		--assert i64-a = 0000000100000000h

	--test-- "u64-lit-1"
		u64-a: FFFFFFFFFFFFFFFFh
		--assert u64-a = FFFFFFFFFFFFFFFFh

	--test-- "u64-lit-2"
		u64-b: 18446744073709551615
		--assert u64-b = FFFFFFFFFFFFFFFFh

===end-group===

===start-group=== "64-bit function argument and return tests"

	--test-- "i64-func-1"
		i64-res-1: i64-add-one 4294967296
		--assert i64-res-1 = 0000000100000001h

	--test-- "i64-func-2"
		i64-b: 0000000100000000h
		i64-res-2: i64-add-one i64-b
		--assert i64-res-2 = 0000000100000001h

	--test-- "u64-func-1"
		u64-res-1: u64-id FFFFFFFFFFFFFFFFh
		--assert u64-res-1 = FFFFFFFFFFFFFFFFh

	--test-- "u64-func-2"
		u64-c: FFFFFFFFFFFFFFFFh
		u64-res-2: u64-id u64-c
		--assert u64-c = u64-res-2

===end-group===

===start-group=== "64-bit math and bitwise tests"

	--test-- "i64-math-1"
		i64-c: 0000000100000001h
		i64-res-3: i64-c * 2
		--assert i64-res-3 = 0000000200000002h

	--test-- "i64-math-2"
		i64-d: 0000000200000002h
		i64-res-4: i64-d - 0000000100000001h
		--assert i64-res-4 = 0000000100000001h

	--test-- "i64-bit-1"
		i64-e: 0000000300000003h
		i64-res-5: i64-e and 0000000100000001h
		--assert i64-res-5 = 0000000100000001h

	--test-- "i64-bit-2"
		i64-f: 0000000100000000h
		i64-res-6: i64-f or 0000000200000002h
		--assert i64-res-6 = 0000000300000002h

	--test-- "i64-bit-3"
		i64-g: 0000000300000003h
		i64-res-7: i64-g xor 0000000100000001h
		--assert i64-res-7 = 0000000200000002h

	--test-- "i64-not-1"
		i64-h: as int64! 0
		i64-res-8: not i64-h
		--assert i64-res-8 = as int64! FFFFFFFFFFFFFFFFh

===end-group===

===start-group=== "64-bit shift tests"

	--test-- "i64-shift-1"
		i64-i: as int64! 1
		i64-res-9: i64-i << 32
		--assert i64-res-9 = 0000000100000000h

	--test-- "i64-shift-2"
		i64-j: 0000000100000000h
		i64-res-10: i64-j >> 32
		--assert i64-res-10 = 0000000000000001h

	--test-- "u64-shift-1"
		u64-d: 8000000000000000h
		u64-res-3: u64-d >>> 32
		--assert u64-res-3 = as uint64! 0000000080000000h

===end-group===

===start-group=== "64-bit cast and logic tests"

	--test-- "i64-cast-1"
		i64-k: as int64! 1
		--assert i64-k = 0000000000000001h

	--test-- "u64-cast-1"
		u64-e: as uint64! 1
		--assert u64-e = as uint64! 0000000000000001h

	--test-- "i64-logic-1"
		--assert i64-zero? as int64! 0

	--test-- "i64-logic-2"
		--assert not i64-zero? as int64! 1

	--test-- "i64-logic-3"
		--assert false = as logic! as int64! 0

	--test-- "i64-logic-4"
		i64-l: 0000000100000000h
		i64-l?: as logic! i64-l
		--assert i64-l?

===end-group===

]

#if target = 'ARM [

===start-group=== "ARM 64-bit literal and assignment tests"

	--test-- "arm-i64-lit-1"
		arm-i64-a: 4294967296
		arm-parts: as i64-parts! :arm-i64-a
		--assert arm-parts/lo = 00000000h
		--assert arm-parts/hi = 00000001h

	--test-- "arm-u64-lit-1"
		arm-u64-a: FFFFFFFFFFFFFFFFh
		arm-parts: as i64-parts! :arm-u64-a
		--assert arm-parts/lo = FFFFFFFFh
		--assert arm-parts/hi = FFFFFFFFh

	--test-- "arm-u64-lit-2"
		arm-u64-b: 18446744073709551615
		arm-parts: as i64-parts! :arm-u64-b
		--assert arm-parts/lo = FFFFFFFFh
		--assert arm-parts/hi = FFFFFFFFh

===end-group===

===start-group=== "ARM 64-bit function argument and return tests"

	--test-- "arm-i64-func-1"
		arm-i64-b: i64-add-one 4294967296
		arm-parts: as i64-parts! :arm-i64-b
		--assert arm-parts/lo = 00000001h
		--assert arm-parts/hi = 00000001h

	--test-- "arm-u64-func-1"
		arm-u64-c: u64-id FFFFFFFFFFFFFFFFh
		arm-parts: as i64-parts! :arm-u64-c
		--assert arm-parts/lo = FFFFFFFFh
		--assert arm-parts/hi = FFFFFFFFh

===end-group===

===start-group=== "ARM 64-bit math and bitwise tests"

	--test-- "arm-i64-math-1"
		arm-i64-c: 0000000100000001h
		arm-i64-c: arm-i64-c + 0000000100000001h
		arm-parts: as i64-parts! :arm-i64-c
		--assert arm-parts/lo = 00000002h
		--assert arm-parts/hi = 00000002h

	--test-- "arm-i64-math-2"
		arm-i64-d: 0000000200000002h
		arm-i64-d: arm-i64-d - 0000000100000001h
		arm-parts: as i64-parts! :arm-i64-d
		--assert arm-parts/lo = 00000001h
		--assert arm-parts/hi = 00000001h

	--test-- "arm-i64-bit-1"
		arm-i64-e: 0000000300000003h
		arm-i64-e: arm-i64-e and 0000000100000001h
		arm-parts: as i64-parts! :arm-i64-e
		--assert arm-parts/lo = 00000001h
		--assert arm-parts/hi = 00000001h

	--test-- "arm-i64-bit-2"
		arm-i64-f: 0000000100000000h
		arm-i64-f: arm-i64-f or 0000000200000002h
		arm-parts: as i64-parts! :arm-i64-f
		--assert arm-parts/lo = 00000002h
		--assert arm-parts/hi = 00000003h

	--test-- "arm-i64-bit-3"
		arm-i64-g: 0000000300000003h
		arm-i64-g: arm-i64-g xor 0000000100000001h
		arm-parts: as i64-parts! :arm-i64-g
		--assert arm-parts/lo = 00000002h
		--assert arm-parts/hi = 00000002h

===end-group===

===start-group=== "ARM 64-bit cast tests"

	--test-- "arm-i64-cast-1"
		arm-i64-h: as int64! 1
		arm-parts: as i64-parts! :arm-i64-h
		--assert arm-parts/lo = 00000001h
		--assert arm-parts/hi = 00000000h

	--test-- "arm-u64-cast-1"
		arm-u64-d: as uint64! 1
		arm-parts: as i64-parts! :arm-u64-d
		--assert arm-parts/lo = 00000001h
		--assert arm-parts/hi = 00000000h

===end-group===

]

~~~end-file~~~
