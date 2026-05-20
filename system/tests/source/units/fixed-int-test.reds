Red/System [
	Title:   "Red/System fixed-width integer datatype test script"
	Author:  "Red Foundation"
	File: 	 %fixed-int-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

#if any [target = 'IA-32 target = 'ARM] [

fixed-int-pair!: alias struct! [
	s16 [int16!]
	u16 [uint16!]
	u32 [uint32!]
]

fixed-int64-parts!: alias struct! [
	lo [integer!]
	hi [integer!]
]

fi-i8-to-i32: func [value [int8!] return: [int32!] /local out [int32!]][
	out: value
	out
]

fi-u16-to-i32: func [value [uint16!] return: [int32!] /local out [int32!]][
	out: value
	out
]

fi-i32-id: func [value [int32!] return: [integer!]][value]

fi-u32-low: func [value [uint32!] return: [integer!]][
	as integer! value
]

fi-abi-mix: func [
	a [int8!] b [uint8!] c [int16!] d [uint16!]
	e [int32!] f [uint32!] g [int64!] h [uint64!]
	return: [integer!]
	/local score [integer!]
][
	score: 0
	if (as int32! a) = -2 [score: score + 1]
	if (as int32! b) = 250 [score: score + 1]
	if (as int32! c) = -300 [score: score + 1]
	if (as int32! d) = 60000 [score: score + 1]
	if e = -123456 [score: score + 1]
	if (as integer! f) = -1 [score: score + 1]
	if (as integer! g) = -3 [score: score + 1]
	if (as integer! h) = -1 [score: score + 1]
	score
]

fi-cdecl-mix: func [
	[cdecl]
	a [int8!] b [uint8!] c [int16!] d [uint16!]
	e [int32!] f [uint32!] g [int64!] h [uint64!]
	return: [integer!]
][
	fi-abi-mix a b c d e f g h
]

fi-stdcall-mix: func [
	[stdcall]
	a [int8!] b [uint8!] c [int16!] d [uint16!]
	e [int32!] f [uint32!] g [int64!] h [uint64!]
	return: [integer!]
][
	fi-abi-mix a b c d e f g h
]

fi-callback-mix: func [
	[callback]
	a [int8!] b [uint8!] c [int16!] d [uint16!]
	e [int32!] f [uint32!] g [int64!] h [uint64!]
	return: [integer!]
][
	fi-abi-mix a b c d e f g h
]

fi-cdecl-ret-i8: func [[cdecl] return: [int8!]][as int8! -2]
fi-stdcall-ret-u16: func [[stdcall] return: [uint16!]][as uint16! 60000]
fi-callback-ret-i16: func [[callback] return: [int16!]][as int16! -300]

fi-ret-i64: func [return: [int64!]][0000000100000002h]
fi-ret-u64: func [return: [uint64!]][FFFFFFFFFFFFFFFFh]
fi-cdecl-ret-i64: func [[cdecl] return: [int64!]][0000000100000002h]
fi-cdecl-ret-u64: func [[cdecl] return: [uint64!]][FFFFFFFFFFFFFFFFh]
fi-stdcall-ret-i64: func [[stdcall] return: [int64!]][0000000100000002h]
fi-stdcall-ret-u64: func [[stdcall] return: [uint64!]][FFFFFFFFFFFFFFFFh]
fi-callback-ret-i64: func [[callback] return: [int64!]][0000000100000002h]
fi-callback-ret-u64: func [[callback] return: [uint64!]][FFFFFFFFFFFFFFFFh]

fi-variadic-score: func [
	[variadic]
	count [integer!] list [int-ptr!]
	return: [integer!]
	/local score [integer!]
][
	score: 0
	if 4 = count [score: score + 1]
	if -2 = list/1 [score: score + 1]
	if 250 = list/2 [score: score + 1]
	if -300 = list/3 [score: score + 1]
	if 60000 = list/4 [score: score + 1]
	score
]

fi-typed-score: func [
	[typed]
	count [integer!] list [typed-value!]
	return: [integer!]
	/local score [integer!]
][
	score: 0
	if 8 = count [score: score + 1]
	if all [type-int8! = list/type -2 = list/value] [score: score + 1]
	list: list + 1
	if all [type-uint8! = list/type 250 = list/value] [score: score + 1]
	list: list + 1
	if all [type-int16! = list/type -300 = list/value] [score: score + 1]
	list: list + 1
	if all [type-uint16! = list/type 60000 = list/value] [score: score + 1]
	list: list + 1
	if all [type-int32! = list/type -123456 = list/value] [score: score + 1]
	list: list + 1
	if all [type-uint32! = list/type -1 = list/value] [score: score + 1]
	list: list + 1
	if all [type-int64! = list/type -3 = list/value -1 = list/_padding] [score: score + 1]
	list: list + 1
	if all [type-uint64! = list/type -1 = list/value 0 = list/_padding] [score: score + 1]
	score
]

fi-cdecl-variadic-sink: func [[cdecl variadic] return: [integer!]][1]

]

~~~start-file~~~ "fixed-int"

#if any [target = 'IA-32 target = 'ARM] [

===start-group=== "fixed integer sizes and aliases"

	--test-- "fixed-int-size-1"
		--assert 1 = (size? int8!)
		--assert 1 = (size? uint8!)
		--assert 2 = (size? int16!)
		--assert 2 = (size? uint16!)
		--assert 4 = (size? int32!)
		--assert 4 = (size? uint32!)
		--assert (size? integer!) = (size? int32!)

	--test-- "fixed-int-alias-1"
		fi32-a: as int32! -123456
		fi32-b: fi-i32-id fi32-a
		--assert fi32-b = -123456

===end-group===

===start-group=== "fixed integer casts and widening"

	--test-- "fixed-int-cast-1"
		fi-i8: as int8! -2
		fi-i32: fi-i8-to-i32 fi-i8
		--assert fi-i32 = -2

	--test-- "fixed-int-cast-2"
		fi-u8: as uint8! 250
		fi-u16: as uint16! 250
		fi-i32: fi-u16-to-i32 fi-u16
		--assert fi-i32 = 250

	--test-- "fixed-int-cast-3"
		fi-u16: as uint16! 60000
		fi-i32: fi-u16-to-i32 fi-u16
		--assert fi-i32 = 60000

	--test-- "fixed-int-cast-4"
		fi-u32: as uint32! 4294967295
		--assert -1 = fi-u32-low fi-u32

===end-group===

===start-group=== "fixed integer storage and operations"

	--test-- "fixed-int-op-1"
		fi-a: as int16! -300
		fi-b: as int16! 20
		fi-c: fi-a + fi-b
		--assert fi-c = as int16! -280

	--test-- "fixed-int-op-2"
		fi-u16-a: as uint16! 60000
		fi-u16-b: as uint16! 200
		fi-u16-c: fi-u16-a + fi-u16-b
		--assert fi-u16-c = as uint16! 60200

	--test-- "fixed-int-op-3"
		fi-u8-a: as uint8! 240
		fi-u8-b: as uint8! 15
		fi-u8-c: fi-u8-a and fi-u8-b
		--assert fi-u8-c = as uint8! 0

	--test-- "fixed-int-op-4"
		fi-i8-a: as int8! -2
		fi-i8-b: as int8! -1
		--assert fi-i8-a < fi-i8-b

	--test-- "fixed-int-op-int8"
		fi-i8-a: as int8! -100
		fi-i8-b: as int8! 7
		fi-i8-c: fi-i8-a + fi-i8-b
		--assert fi-i8-c = as int8! -93
		fi-i8-c: fi-i8-a - fi-i8-b
		--assert fi-i8-c = as int8! -107
		fi-i8-c: fi-i8-a * fi-i8-b
		--assert fi-i8-c = as int8! 68
		fi-i8-c: fi-i8-a / fi-i8-b
		--assert fi-i8-c = as int8! -14
		fi-i8-c: fi-i8-a % fi-i8-b
		--assert fi-i8-c = as int8! -2
		fi-i8-c: fi-i8-a // fi-i8-b
		--assert fi-i8-c = as int8! 5
		fi-i8-c: (as int8! -86) and (as int8! 15)
		--assert fi-i8-c = as int8! 10
		fi-i8-c: (as int8! -86) or (as int8! 15)
		--assert fi-i8-c = as int8! -81
		fi-i8-c: (as int8! -86) xor (as int8! 15)
		--assert fi-i8-c = as int8! -91
		fi-i8-c: as int8! 3
		fi-i8-c: fi-i8-c << 2
		--assert fi-i8-c = as int8! 12
		fi-i8-c: as int8! -64
		fi-i8-c: fi-i8-c >> 2
		--assert fi-i8-c = as int8! -16
		fi-i8-c: as int8! -64
		fi-i8-c: fi-i8-c -** 2
		--assert fi-i8-c = as int8! 48
		fi-i8-c: not as int8! -1
		--assert fi-i8-c = as int8! 0
		fi-i8-a: as int8! -100
		fi-i8-b: as int8! 7
		--assert fi-i8-a < fi-i8-b
		--assert fi-i8-b > fi-i8-a
		--assert fi-i8-a <= fi-i8-a
		--assert fi-i8-b >= fi-i8-b
		--assert fi-i8-b <> fi-i8-a

	--test-- "fixed-int-op-uint8"
		fi-u8-a: as uint8! 250
		fi-u8-b: as uint8! 10
		fi-u8-c: fi-u8-a + fi-u8-b
		--assert fi-u8-c = as uint8! 4
		fi-u8-c: fi-u8-a - fi-u8-b
		--assert fi-u8-c = as uint8! 240
		fi-u8-c: (as uint8! 25) * (as uint8! 11)
		--assert fi-u8-c = as uint8! 19
		fi-u8-c: fi-u8-a / fi-u8-b
		--assert fi-u8-c = as uint8! 25
		fi-u8-c: fi-u8-a % (as uint8! 11)
		--assert fi-u8-c = as uint8! 8
		fi-u8-c: fi-u8-a // (as uint8! 11)
		--assert fi-u8-c = as uint8! 8
		fi-u8-c: fi-u8-a and (as uint8! 15)
		--assert fi-u8-c = as uint8! 10
		fi-u8-c: fi-u8-a or (as uint8! 15)
		--assert fi-u8-c = as uint8! 255
		fi-u8-c: fi-u8-a xor (as uint8! 15)
		--assert fi-u8-c = as uint8! 245
		fi-u8-c: as uint8! 3
		fi-u8-c: fi-u8-c << 2
		--assert fi-u8-c = as uint8! 12
		fi-u8-c: as uint8! 240
		fi-u8-c: fi-u8-c -** 4
		--assert fi-u8-c = as uint8! 15
		fi-u8-c: not as uint8! 240
		--assert fi-u8-c = as uint8! 15
		--assert (as uint8! 250) > (as uint8! 10)
		--assert (as uint8! 10) < (as uint8! 250)
		--assert (as uint8! 250) >= (as uint8! 250)
		--assert (as uint8! 10) <= (as uint8! 10)
		--assert (as uint8! 10) <> (as uint8! 250)

	--test-- "fixed-int-op-int16"
		fi-i16-a: as int16! -30000
		fi-i16-b: as int16! 7
		fi-i16-c: fi-i16-a + fi-i16-b
		--assert fi-i16-c = as int16! -29993
		fi-i16-c: fi-i16-a - fi-i16-b
		--assert fi-i16-c = as int16! -30007
		fi-i16-c: (as int16! -300) * fi-i16-b
		--assert fi-i16-c = as int16! -2100
		fi-i16-c: fi-i16-a / fi-i16-b
		--assert fi-i16-c = as int16! -4285
		fi-i16-c: fi-i16-a % fi-i16-b
		--assert fi-i16-c = as int16! -5
		fi-i16-c: fi-i16-a // fi-i16-b
		--assert fi-i16-c = as int16! 2
		fi-i16-c: (as int16! -21846) and (as int16! 3855)
		--assert fi-i16-c = as int16! 2570
		fi-i16-c: (as int16! -21846) or (as int16! 3855)
		--assert fi-i16-c = as int16! -20561
		fi-i16-c: (as int16! -21846) xor (as int16! 3855)
		--assert fi-i16-c = as int16! -23131
		fi-i16-c: as int16! 3
		fi-i16-c: fi-i16-c << 4
		--assert fi-i16-c = as int16! 48
		fi-i16-c: as int16! -1024
		fi-i16-c: fi-i16-c >> 3
		--assert fi-i16-c = as int16! -128
		fi-i16-c: as int16! -1024
		fi-i16-c: fi-i16-c -** 4
		--assert fi-i16-c = as int16! 4032
		fi-i16-c: not as int16! -1
		--assert fi-i16-c = as int16! 0
		--assert (as int16! -30000) < (as int16! 7)
		--assert (as int16! 7) > (as int16! -30000)
		--assert (as int16! -30000) <= (as int16! -30000)
		--assert (as int16! 7) >= (as int16! 7)
		--assert (as int16! 7) <> (as int16! -30000)

	--test-- "fixed-int-op-uint16"
		fi-u16-a: as uint16! 60000
		fi-u16-b: as uint16! 7
		fi-u16-c: fi-u16-a + (as uint16! 6000)
		--assert fi-u16-c = as uint16! 464
		fi-u16-c: fi-u16-a - (as uint16! 1000)
		--assert fi-u16-c = as uint16! 59000
		fi-u16-c: fi-u16-a * (as uint16! 2)
		--assert fi-u16-c = as uint16! 54464
		fi-u16-c: fi-u16-a / fi-u16-b
		--assert fi-u16-c = as uint16! 8571
		fi-u16-c: fi-u16-a % fi-u16-b
		--assert fi-u16-c = as uint16! 3
		fi-u16-c: fi-u16-a // fi-u16-b
		--assert fi-u16-c = as uint16! 3
		fi-u16-c: fi-u16-a and (as uint16! 3855)
		--assert fi-u16-c = as uint16! 2560
		fi-u16-c: fi-u16-a or (as uint16! 3855)
		--assert fi-u16-c = as uint16! 61295
		fi-u16-c: fi-u16-a xor (as uint16! 3855)
		--assert fi-u16-c = as uint16! 58735
		fi-u16-c: as uint16! 3
		fi-u16-c: fi-u16-c << 4
		--assert fi-u16-c = as uint16! 48
		fi-u16-c: as uint16! 61440
		fi-u16-c: fi-u16-c -** 8
		--assert fi-u16-c = as uint16! 240
		fi-u16-c: not as uint16! 61440
		--assert fi-u16-c = as uint16! 4095
		--assert (as uint16! 60000) > (as uint16! 7)
		--assert (as uint16! 7) < (as uint16! 60000)
		--assert (as uint16! 60000) >= (as uint16! 60000)
		--assert (as uint16! 7) <= (as uint16! 7)
		--assert (as uint16! 7) <> (as uint16! 60000)

	--test-- "fixed-int-op-int32"
		fi-i32-a: as int32! -123456
		fi-i32-b: as int32! 100
		fi-i32-c: fi-i32-a + fi-i32-b
		--assert fi-i32-c = as int32! -123356
		fi-i32-c: fi-i32-a - fi-i32-b
		--assert fi-i32-c = as int32! -123556
		fi-i32-c: (as int32! -30000) * fi-i32-b
		--assert fi-i32-c = as int32! -3000000
		fi-i32-c: fi-i32-a / fi-i32-b
		--assert fi-i32-c = as int32! -1234
		fi-i32-c: fi-i32-a % fi-i32-b
		--assert fi-i32-c = as int32! -56
		fi-i32-c: fi-i32-a // fi-i32-b
		--assert fi-i32-c = as int32! 44
		fi-i32-c: (as int32! -1431655766) and (as int32! 252645135)
		--assert fi-i32-c = as int32! 168430090
		fi-i32-c: as int32! 3
		fi-i32-c: fi-i32-c << 8
		--assert fi-i32-c = as int32! 768
		fi-i32-c: as int32! -1024
		fi-i32-c: fi-i32-c >> 4
		--assert fi-i32-c = as int32! -64
		fi-i32-c: as int32! -1024
		fi-i32-c: fi-i32-c -** 8
		--assert fi-i32-c = as int32! 16777212
		fi-i32-c: not as int32! -1
		--assert fi-i32-c = as int32! 0
		--assert (as int32! -123456) < (as int32! 100)
		--assert (as int32! 100) > (as int32! -123456)
		--assert (as int32! -123456) <= (as int32! -123456)
		--assert (as int32! 100) >= (as int32! 100)
		--assert (as int32! 100) <> (as int32! -123456)

	--test-- "fixed-int-op-uint32"
		fi-u32-a: as uint32! EE6B2800h
		fi-u32-b: as uint32! 100000
		fi-u32-c: fi-u32-a + (as uint32! 300000000)
		--assert fi-u32-c = as uint32! 5032704
		fi-u32-c: fi-u32-a - fi-u32-b
		--assert fi-u32-c = as uint32! EE69A160h
		fi-u32-c: (as uint32! 70000) * (as uint32! 70000)
		--assert fi-u32-c = as uint32! 605032704
		fi-u32-c: fi-u32-a / fi-u32-b
		--assert fi-u32-c = as uint32! 40000
		fi-u32-c: fi-u32-a % (as uint32! 65537)
		--assert fi-u32-c = as uint32! 14742
		fi-u32-c: fi-u32-a // (as uint32! 65537)
		--assert fi-u32-c = as uint32! 14742
		fi-u32-c: fi-u32-a and (as uint32! 252645135)
		--assert fi-u32-c = as uint32! 235603968
		fi-u32-c: fi-u32-a or (as uint32! 252645135)
		--assert fi-u32-c = as uint32! EF6F2F0Fh
		fi-u32-c: fi-u32-a xor (as uint32! 252645135)
		--assert fi-u32-c = as uint32! E164270Fh
		fi-u32-c: as uint32! 3
		fi-u32-c: fi-u32-c << 8
		--assert fi-u32-c = as uint32! 768
		fi-u32-c: as uint32! F0000000h
		fi-u32-c: fi-u32-c -** 24
		--assert fi-u32-c = as uint32! 240
		fi-u32-c: not as uint32! F0000000h
		--assert fi-u32-c = as uint32! 268435455
		--assert (as uint32! EE6B2800h) > (as uint32! 100000)
		--assert (as uint32! 100000) < (as uint32! EE6B2800h)
		--assert (as uint32! EE6B2800h) >= (as uint32! EE6B2800h)
		--assert (as uint32! 100000) <= (as uint32! 100000)
		--assert (as uint32! 100000) <> (as uint32! EE6B2800h)

	--test-- "fixed-int-op-int64"
		fi-i64-a: as int64! 0000000100000000h
		fi-i64-b: as int64! 0000000000000003h
		fi-i64-c: fi-i64-a + fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 00000003h
		--assert fi-i64-parts/hi = 00000001h
		fi-i64-c: fi-i64-a - fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = -3
		--assert fi-i64-parts/hi = 0
		fi-i64-c: fi-i64-a * fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 0
		--assert fi-i64-parts/hi = 3
		fi-i64-c: (as int64! 00FF00FF00FF00FFh) and (as int64! 0000FFFF0000FFFFh)
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 000000FFh
		--assert fi-i64-parts/hi = 000000FFh
		fi-i64-c: (as int64! 00FF000000000000h) or (as int64! 00000000000000FFh)
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 000000FFh
		--assert fi-i64-parts/hi = 00FF0000h
		fi-i64-c: (as int64! 00FF00FF00FF00FFh) xor (as int64! 0000FFFF0000FFFFh)
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 00FFFF00h
		--assert fi-i64-parts/hi = 00FFFF00h
		fi-i64-c: as int64! 1
		fi-i64-c: fi-i64-c << 33
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 0
		--assert fi-i64-parts/hi = 2
		fi-shift-count: 33
		fi-i64-c: as int64! 1
		fi-i64-c: fi-i64-c << fi-shift-count
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 0
		--assert fi-i64-parts/hi = 2
		fi-i64-c: as int64! 8000000000000000h
		fi-i64-c: fi-i64-c >> 63
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = -1
		--assert fi-i64-parts/hi = -1
		fi-i64-c: as int64! 00000000FFFFFFFFh
		fi-i64-c: not fi-i64-c
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 0
		--assert fi-i64-parts/hi = -1
		fi-i64-a: as int64! -5
		fi-i64-b: as int64! 3
		--assert fi-i64-a < fi-i64-b
		--assert fi-i64-b > fi-i64-a
		--assert fi-i64-a <= fi-i64-a
		--assert fi-i64-b >= fi-i64-b
		--assert fi-i64-b <> fi-i64-a

	--test-- "fixed-int-op-uint64"
		fi-u64-a: as uint64! 0000000100000000h
		fi-u64-b: as uint64! 0000000000000003h
		fi-u64-c: fi-u64-a + fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 00000003h
		--assert fi-u64-parts/hi = 00000001h
		fi-u64-c: fi-u64-a * fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 0
		--assert fi-u64-parts/hi = 3
		fi-u64-c: as uint64! F000000000000000h
		fi-u64-c: fi-u64-c -** 60
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 15
		--assert fi-u64-parts/hi = 0
		fi-shift-count: 60
		fi-u64-c: as uint64! F000000000000000h
		fi-u64-c: fi-u64-c -** fi-shift-count
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 15
		--assert fi-u64-parts/hi = 0
		fi-u64-c: as uint64! 00000000FFFFFFFFh
		fi-u64-c: not fi-u64-c
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 0
		--assert fi-u64-parts/hi = -1
		fi-u64-a: as uint64! FFFFFFFFFFFFFFFFh
		fi-u64-b: as uint64! 0000000100000000h
		--assert fi-u64-a > fi-u64-b
		--assert fi-u64-b < fi-u64-a
		--assert fi-u64-a >= fi-u64-a
		--assert fi-u64-b <= fi-u64-b
		--assert fi-u64-b <> fi-u64-a

#if target = 'IA-32 [

	--test-- "fixed-int-struct-1"
		fi-pair: declare fixed-int-pair!
		fi-pair/s16: as int16! -1234
		fi-pair/u16: as uint16! 54321
		fi-pair/u32: as uint32! 4294967295
		fi-s16-wide: as int32! fi-pair/s16
		--assert fi-s16-wide = -1234
		fi-u16-wide: as int32! fi-pair/u16
		--assert fi-u16-wide = 54321
		--assert -1 = as integer! fi-pair/u32

]

===end-group===

===start-group=== "fixed integer ABI"

	--test-- "fixed-int-abi-internal"
		--assert 8 = fi-abi-mix
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
			as int64! -3
			as uint64! 4294967295

	--test-- "fixed-int-abi-cdecl"
		--assert 8 = fi-cdecl-mix
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
			as int64! -3
			as uint64! 4294967295
		--assert (as int32! fi-cdecl-ret-i8) = -2

	--test-- "fixed-int-abi-return64"
		fi-i64-ret: fi-ret-i64
		fi-i64-parts: as fixed-int64-parts! :fi-i64-ret
		--assert fi-i64-parts/lo = 00000002h
		--assert fi-i64-parts/hi = 00000001h
		fi-u64-ret: fi-ret-u64
		fi-u64-parts: as fixed-int64-parts! :fi-u64-ret
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = -1
		fi-cdecl-i64-ret: fi-cdecl-ret-i64
		fi-i64-parts: as fixed-int64-parts! :fi-cdecl-i64-ret
		--assert fi-i64-parts/lo = 00000002h
		--assert fi-i64-parts/hi = 00000001h
		fi-cdecl-u64-ret: fi-cdecl-ret-u64
		fi-u64-parts: as fixed-int64-parts! :fi-cdecl-u64-ret
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = -1

#if target = 'IA-32 [

	--test-- "fixed-int-abi-stdcall"
		--assert 8 = fi-stdcall-mix
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
			as int64! -3
			as uint64! 4294967295
		--assert (as int32! fi-stdcall-ret-u16) = 60000

	--test-- "fixed-int-abi-stdcall-return64"
		fi-stdcall-i64-ret: fi-stdcall-ret-i64
		fi-i64-parts: as fixed-int64-parts! :fi-stdcall-i64-ret
		--assert fi-i64-parts/lo = 00000002h
		--assert fi-i64-parts/hi = 00000001h
		fi-stdcall-u64-ret: fi-stdcall-ret-u64
		fi-u64-parts: as fixed-int64-parts! :fi-stdcall-u64-ret
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = -1

]

	--test-- "fixed-int-abi-callback"
		--assert 8 = fi-callback-mix
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
			as int64! -3
			as uint64! 4294967295
		--assert (as int32! fi-callback-ret-i16) = -300

	--test-- "fixed-int-abi-callback-return64"
		fi-callback-i64-ret: fi-callback-ret-i64
		fi-i64-parts: as fixed-int64-parts! :fi-callback-i64-ret
		--assert fi-i64-parts/lo = 00000002h
		--assert fi-i64-parts/hi = 00000001h
		fi-callback-u64-ret: fi-callback-ret-u64
		fi-u64-parts: as fixed-int64-parts! :fi-callback-u64-ret
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = -1

	--test-- "fixed-int-abi-variadic"
		--assert 5 = fi-variadic-score [
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
		]

	--test-- "fixed-int-abi-typed"
		--assert 9 = fi-typed-score [
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
			as int64! -3
			as uint64! 4294967295
		]

	--test-- "fixed-int-abi-cdecl-variadic"
		--assert 1 = fi-cdecl-variadic-sink [
			as int8! -2
			as uint8! 250
			as int16! -300
			as uint16! 60000
			as int32! -123456
			as uint32! 4294967295
		]

===end-group===

]

~~~end-file~~~
