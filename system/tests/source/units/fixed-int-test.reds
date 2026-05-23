Red/System [
	Title:   "Red/System fixed-width integer datatype test script"
	Author:  "Red Foundation"
	File: 	 %fixed-int-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

#if any [target = 'IA-32 target = 'ARM target = 'X86-64] [

fixed-int-pair!: alias struct! [
	s16 [int16!]
	u16 [uint16!]
	u32 [uint32!]
]

fixed-int64-parts!: alias struct! [
	lo [integer!]
	hi [integer!]
]

fixed-int-struct!: alias struct! [
	i8  [int8!]
	u8  [uint8!]
	i16 [int16!]
	u16 [uint16!]
	i32 [int32!]
	u32 [uint32!]
	i64 [int64!]
	u64 [uint64!]
]

fixed-int-layout!: alias struct! [
	u8  [uint8!]
	i16 [int16!]
	i32 [int32!]
]

fixed-int-nested!: alias struct! [
	tag   [uint8!]
	value [fixed-int-layout! value]
	tail  [uint8!]
]

fixed-int-mixed!: alias struct! [
	tag  [uint8!]
	raw  [byte!]
	name [c-string!]
	ptr  [int-ptr!]
	f32  [float32!]
	i16  [int16!]
	fptr [pointer! [float!]]
	f64  [float!]
	u64  [uint64!]
	tail [int8!]
]

fixed-int-mixed-nested!: alias struct! [
	head  [uint8!]
	value [fixed-int-mixed! value]
	done  [uint16!]
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
	if all [type-int8! = list/type -2 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-uint8! = list/type 250 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-int16! = list/type -300 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-uint16! = list/type 60000 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-int32! = list/type -123456 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-uint32! = list/type -1 = as integer! list/value] [score: score + 1]
	list: list + 1
	if all [type-int64! = list/type -3 = as integer! list/value -1 = list/_padding] [score: score + 1]
	list: list + 1
	if all [type-uint64! = list/type -1 = as integer! list/value 0 = list/_padding] [score: score + 1]
	score
]

fi-cdecl-variadic-sink: func [[cdecl variadic] return: [integer!]][1]

]

~~~start-file~~~ "fixed-int"

#if any [target = 'IA-32 target = 'ARM target = 'X86-64] [

===start-group=== "fixed integer sizes and aliases"

	--test-- "fixed-int-size-1"
		--assert 1 = (size? int8!)
		--assert 1 = (size? uint8!)
		--assert 2 = (size? int16!)
		--assert 2 = (size? uint16!)
		--assert 4 = (size? int32!)
		--assert 4 = (size? uint32!)
		--assert (size? integer!) = (size? int32!)

	--test-- "fixed-int-struct-size-1"
		#either target = 'X86-64 [
			--assert 32 = (size? fixed-int-struct!)
		][
			--assert 32 = (size? fixed-int-struct!)
		]
		--assert 8 = (size? fixed-int-layout!)
		--assert 16 = (size? fixed-int-nested!)
		#either target = 'X86-64 [
			--assert 64 = (size? fixed-int-mixed!)
			--assert 80 = (size? fixed-int-mixed-nested!)
		][
			--assert 44 = (size? fixed-int-mixed!)
			--assert 52 = (size? fixed-int-mixed-nested!)
		]
		fi-pad: declare struct! [u8 [uint8!] i16 [int16!]]
		--assert 4 = (size? fi-pad)

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

	--test-- "fixed-int-cast-5"
		fi-i32: as int32! 255
		fi-i8: as int8! fi-i32
		--assert fi-i8 = as int8! -1
		fi-i32: as int32! 256
		fi-u8: as uint8! fi-i32
		--assert fi-u8 = as uint8! 0
		fi-i32: as int32! 65535
		fi-i16: as int16! fi-i32
		--assert fi-i16 = as int16! -1
		fi-i32: as int32! 65536
		fi-u16: as uint16! fi-i32
		--assert fi-u16 = as uint16! 0

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
		fi-i8-c: fi-i8-c >>> 2
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
		fi-u8-c: fi-u8-c >> 4
		--assert fi-u8-c = as uint8! 15
		fi-u8-c: as uint8! 240
		fi-u8-c: fi-u8-c >>> 4
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
		fi-i16-c: fi-i16-c >>> 4
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
		fi-u16-c: fi-u16-c >> 8
		--assert fi-u16-c = as uint16! 240
		fi-u16-c: as uint16! 61440
		fi-u16-c: fi-u16-c >>> 8
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
		fi-i32-c: (as int32! -1431655766) or (as int32! 252645135)
		--assert fi-i32-c = as int32! AFAFAFAFh
		fi-i32-c: (as int32! -1431655766) xor (as int32! 252645135)
		--assert fi-i32-c = as int32! A5A5A5A5h
		fi-i32-c: as int32! 3
		fi-i32-c: fi-i32-c << 8
		--assert fi-i32-c = as int32! 768
		fi-i32-c: as int32! -1024
		fi-i32-c: fi-i32-c >> 4
		--assert fi-i32-c = as int32! -64
		fi-i32-c: as int32! -1024
		fi-i32-c: fi-i32-c >>> 8
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
		fi-u32-c: fi-u32-c >> 24
		--assert fi-u32-c = as uint32! 240
		fi-u32-c: as uint32! F0000000h
		fi-u32-c: fi-u32-c >>> 24
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
		fi-i64-a: as int64! 0000000500000008h
		fi-i64-b: as int64! 3
		fi-i64-c: fi-i64-a / fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = AAAAAAADh
		--assert fi-i64-parts/hi = 1
		fi-i64-c: fi-i64-a % fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 1
		--assert fi-i64-parts/hi = 0
		fi-i64-c: fi-i64-a // fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 1
		--assert fi-i64-parts/hi = 0
		fi-i64-a: as int64! FFFFFFFAFFFFFFF8h
		fi-i64-c: fi-i64-a / fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 55555553h
		--assert fi-i64-parts/hi = -2
		fi-i64-c: fi-i64-a % fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = -1
		--assert fi-i64-parts/hi = -1
		fi-i64-c: fi-i64-a // fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 2
		--assert fi-i64-parts/hi = 0
		fi-i64-a: as int64! 0000000500000007h
		fi-i64-b: as int64! 0000000200000000h
		fi-i64-c: fi-i64-a / fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 2
		--assert fi-i64-parts/hi = 0
		fi-i64-c: fi-i64-a % fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 7
		--assert fi-i64-parts/hi = 1
		fi-i64-c: fi-i64-a // fi-i64-b
		fi-i64-parts: as fixed-int64-parts! :fi-i64-c
		--assert fi-i64-parts/lo = 7
		--assert fi-i64-parts/hi = 1
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

	--test-- "fixed-int-op-int64-direct"
		--assert 123456789000 + 98765432100 = 222222221100
		--assert 123456789000 - 98765432100 = 24691356900
		--assert 12345678900 * 10 = 123456789000
		--assert -123456789000 + 98765432100 = -24691356900
		--assert 123456789000 / 12345678900 = 10
		--assert 123456789009 % 12345678900 = 9
		--assert 123456789009 // 12345678900 = 9
		--assert -123456789009 / 12345678900 = -10
		--assert -123456789009 % 12345678900 = -9
		--assert -123456789009 // 12345678900 = 12345678891
		--assert (123456789000 / 10) + (9876543210 * 2) = 32098765320
		--assert (0000000F000000F0h and 00000003000000F0h) = 00000003000000F0h
		--assert (0000000F00000000h or 00000000000000F0h) = 0000000F000000F0h
		--assert (0000000F000000F0h xor 00000003000000F0h) = 0000000C00000000h
		--assert ((as int64! 1) << 40) = 0000010000000000h
		--assert ((as int64! 8000000000000000h) >> 60) = as int64! FFFFFFFFFFFFFFF8h
		--assert 123456789000 > 98765432100
		--assert -123456789000 < 98765432100
		--assert 0000000100000000h >= 4294967296

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
		fi-u64-a: as uint64! FFFFFFFFFFFFFFFFh
		fi-u64-b: as uint64! 0000000100000001h
		fi-u64-c: fi-u64-a / fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = 0
		fi-u64-c: fi-u64-a % fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 0
		--assert fi-u64-parts/hi = 0
		fi-u64-c: fi-u64-a // fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 0
		--assert fi-u64-parts/hi = 0
		fi-u64-b: as uint64! 3
		fi-u64-c: fi-u64-a / fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 55555555h
		--assert fi-u64-parts/hi = 55555555h
		fi-u64-c: fi-u64-a % fi-u64-b
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 0
		--assert fi-u64-parts/hi = 0
		fi-u64-c: as uint64! F000000000000000h
		fi-u64-c: fi-u64-c >> 60
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 15
		--assert fi-u64-parts/hi = 0
		fi-u64-c: as uint64! F000000000000000h
		fi-u64-c: fi-u64-c >>> 60
		fi-u64-parts: as fixed-int64-parts! :fi-u64-c
		--assert fi-u64-parts/lo = 15
		--assert fi-u64-parts/hi = 0
		fi-shift-count: 60
		fi-u64-c: as uint64! F000000000000000h
		fi-u64-c: fi-u64-c >>> fi-shift-count
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

	--test-- "fixed-int-op-uint64-direct"
		--assert ((as uint64! F000000000000000h) + (as uint64! 1000000000000000h)) = as uint64! 0
		--assert ((as uint64! FFFFFFFFFFFFFFFFh) - (as uint64! FFFFFFFFFFFFFFFEh)) = as uint64! 1
		--assert ((as uint64! 0000000100000000h) * (as uint64! 3)) = as uint64! 0000000300000000h
		--assert (as uint64! FFFFFFFFFFFFFFFFh) / (as uint64! 0000000100000001h) = as uint64! 00000000FFFFFFFFh
		--assert (as uint64! FFFFFFFFFFFFFFFFh) % (as uint64! 0000000100000001h) = as uint64! 0
		--assert (as uint64! FFFFFFFFFFFFFFFFh) // (as uint64! 0000000100000001h) = as uint64! 0
		--assert ((as uint64! F0F0F0F000000000h) and (as uint64! 0FF00FF000000000h)) = as uint64! 00F000F000000000h
		--assert ((as uint64! F0F0F0F000000000h) or (as uint64! 0FF00FF000000000h)) = as uint64! FFF0FFF000000000h
		--assert ((as uint64! F0F0F0F000000000h) xor (as uint64! 0FF00FF000000000h)) = as uint64! FF00FF0000000000h
		--assert ((as uint64! F000000000000000h) >>> 60) = as uint64! 15
		--assert (as uint64! FFFFFFFFFFFFFFFFh) > (as uint64! 7FFFFFFFFFFFFFFFh)
		--assert (as uint64! 0000000100000000h) <= (as uint64! FFFFFFFFFFFFFFFFh)

	--test-- "fixed-int-op-direct-small"
		--assert ((as int8! -100) + (as int8! 7)) = as int8! -93
		--assert ((as int8! -100) * (as int8! 7)) = as int8! 68
		--assert ((as int8! -100) % (as int8! 7)) = as int8! -2
		--assert ((as int8! -100) // (as int8! 7)) = as int8! 5
		--assert (((as int8! -64) >> 2) = as int8! -16)
		--assert (((as int8! -64) >>> 2) = as int8! 48)
		--assert (((as int8! -86) xor (as int8! 15)) = as int8! -91)

		--assert ((as uint8! 250) + (as uint8! 10)) = as uint8! 4
		--assert ((as uint8! 250) / (as uint8! 10)) = as uint8! 25
		--assert (((as uint8! 240) >> 4) = as uint8! 15)
		--assert (((as uint8! 240) >>> 4) = as uint8! 15)
		--assert ((not as uint8! 240) = as uint8! 15)
		--assert (as uint8! 250) > (as uint8! 10)

		--assert ((as int16! -30000) - (as int16! 7)) = as int16! -30007
		--assert ((as int16! -30000) / (as int16! 7)) = as int16! -4285
		--assert (((as int16! -1024) >> 3) = as int16! -128)
		--assert (((as int16! -1024) >>> 4) = as int16! 4032)
		--assert (((as int16! -21846) or (as int16! 3855)) = as int16! -20561)
		--assert (as int16! -30000) < (as int16! 7)

		--assert ((as uint16! 60000) * (as uint16! 2)) = as uint16! 54464
		--assert ((as uint16! 60000) % (as uint16! 7)) = as uint16! 3
		--assert (((as uint16! 61440) >> 8) = as uint16! 240)
		--assert (((as uint16! 61440) >>> 8) = as uint16! 240)
		--assert (((as uint16! 60000) xor (as uint16! 3855)) = as uint16! 58735)
		--assert (as uint16! 60000) > (as uint16! 7)

		--assert ((as int32! -123456) + (as int32! 100)) = as int32! -123356
		--assert ((as int32! -123456) // (as int32! 100)) = as int32! 44
		--assert (((as int32! -1024) >> 4) = as int32! -64)
		--assert (((as int32! -1024) >>> 8) = as int32! 16777212)
		--assert (((as int32! -1431655766) or (as int32! 252645135)) = as int32! AFAFAFAFh)
		--assert (as int32! -123456) <> (as int32! 100)

		--assert ((as uint32! EE6B2800h) - (as uint32! 100000)) = as uint32! EE69A160h
		--assert ((as uint32! EE6B2800h) / (as uint32! 100000)) = as uint32! 40000
		--assert (((as uint32! F0000000h) >> 24) = as uint32! 240)
		--assert (((as uint32! F0000000h) >>> 24) = as uint32! 240)
		--assert (((as uint32! EE6B2800h) and (as uint32! 252645135)) = as uint32! 235603968)
		--assert (as uint32! EE6B2800h) >= (as uint32! EE6B2800h)

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

	--test-- "fixed-int-struct-fields-1"
		fi-struct: declare struct! [
			i8  [int8!]
			u8  [uint8!]
			i16 [int16!]
			u16 [uint16!]
			i32 [int32!]
			u32 [uint32!]
			i64 [int64!]
			u64 [uint64!]
		]
		fi-struct/i8: as int8! -2
		fi-struct/u8: as uint8! 250
		fi-struct/i16: as int16! -300
		fi-struct/u16: as uint16! 60000
		fi-struct/i32: as int32! -123456
		fi-struct/u32: as uint32! 4294967295
		fi-struct/i64: as int64! FFFFFFFFFFFFFFFEh
		fi-struct/u64: as uint64! FFFFFFFFFFFFFFFFh
		--assert -2 = as int32! fi-struct/i8
		--assert 250 = as int32! fi-struct/u8
		--assert -300 = as int32! fi-struct/i16
		--assert 60000 = as int32! fi-struct/u16
		--assert fi-struct/i32 = as int32! -123456
		--assert -1 = as integer! fi-struct/u32
		--assert fi-struct/i64 = as int64! FFFFFFFFFFFFFFFEh
		--assert fi-struct/u64 = as uint64! FFFFFFFFFFFFFFFFh
		fi-i64-parts: as fixed-int64-parts! :fi-struct/i64
		--assert fi-i64-parts/lo = -2
		--assert fi-i64-parts/hi = -1
		fi-u64-parts: as fixed-int64-parts! :fi-struct/u64
		--assert fi-u64-parts/lo = -1
		--assert fi-u64-parts/hi = -1

	--test-- "fixed-int-struct-fields-2"
		fi-direct: declare struct! [
			i8  [int8!]
			u8  [uint8!]
			i16 [int16!]
			u16 [uint16!]
			i32 [int32!]
			u32 [uint32!]
			i64 [int64!]
			u64 [uint64!]
		]
		fi-direct/i8: as int8! -7
		fi-direct/u8: as uint8! 200
		fi-direct/i16: as int16! -1234
		fi-direct/u16: as uint16! 54321
		fi-direct/i32: as int32! -7654321
		fi-direct/u32: as uint32! EE6B2800h
		fi-direct/i64: 0000000100000000h
		fi-direct/u64: as uint64! F000000000000000h
		--assert -7 = as int32! fi-direct/i8
		--assert 200 = as int32! fi-direct/u8
		--assert -1234 = as int32! fi-direct/i16
		--assert 54321 = as int32! fi-direct/u16
		--assert fi-direct/i32 = as int32! -7654321
		--assert fi-direct/u32 = as uint32! EE6B2800h
		--assert fi-direct/i64 = 0000000100000000h
		--assert fi-direct/u64 = as uint64! F000000000000000h

	--test-- "fixed-int-struct-fields-3"
		fi-struct: declare struct! [
			i8  [int8!]
			u8  [uint8!]
			i16 [int16!]
			u16 [uint16!]
			i32 [int32!]
			u32 [uint32!]
			i64 [int64!]
			u64 [uint64!]
		]
		fi-i64-a: 0000000100000000h
		fi-i64-b: 0000000000000002h
		fi-struct/i64: fi-i64-a
		--assert fi-struct/i64 = 0000000100000000h
		fi-struct/i64: fi-struct/i64 + fi-i64-b
		--assert fi-struct/i64 = 0000000100000002h
		fi-i64-a: fi-struct/i64
		fi-struct/i64: fi-i64-a + fi-i64-b
		--assert fi-struct/i64 = 0000000100000004h
		fi-u64-a: as uint64! 0000000100000000h
		fi-u64-b: as uint64! 0000000000000002h
		fi-struct/u64: fi-u64-a
		fi-struct/u64: fi-struct/u64 + fi-u64-b
		--assert fi-struct/u64 = as uint64! 0000000100000002h
		fi-u64-a: fi-struct/u64
		fi-struct/u64: fi-u64-a + fi-u64-b
		--assert fi-struct/u64 = as uint64! 0000000100000004h

	--test-- "fixed-int-struct-nested-1"
		fi-nested: declare struct! [
			tag   [uint8!]
			value [fixed-int-layout! value]
			tail  [uint8!]
		]
		fi-nested/tag: as uint8! 11
		fi-nested/value/u8: as uint8! 250
		fi-nested/value/i16: as int16! -300
		fi-nested/value/i32: as int32! -123456
		fi-nested/tail: as uint8! 22
		--assert 11 = as int32! fi-nested/tag
		--assert 250 = as int32! fi-nested/value/u8
		--assert -300 = as int32! fi-nested/value/i16
		--assert fi-nested/value/i32 = as int32! -123456
		--assert 22 = as int32! fi-nested/tail

	--test-- "fixed-int-struct-mixed-1"
		fi-mixed-box: declare struct! [
			i [integer!]
			f [float!]
		]
		fi-mixed: declare fixed-int-mixed!
		fi-mixed-copy: declare fixed-int-mixed!
		fi-mixed-box/i: 321
		fi-mixed-box/f: 12.5
		fi-mixed/tag: as uint8! 199
		fi-mixed/raw: #"Q"
		fi-mixed/name: "fixed"
		fi-mixed/ptr: :fi-mixed-box/i
		fi-mixed/f32: as float32! 6.25
		fi-mixed/i16: as int16! -2048
		fi-mixed/fptr: as pointer! [float!] :fi-mixed-box/f
		fi-mixed/f64: 12345.678
		fi-mixed/u64: as uint64! 8000000000000001h
		fi-mixed/tail: as int8! -9
		--assert 199 = as int32! fi-mixed/tag
		--assert fi-mixed/raw = #"Q"
		--assert fi-mixed/name/1 = #"f"
		--assert fi-mixed/name/5 = #"d"
		--assert fi-mixed/ptr/value = 321
		--assert fi-mixed/f32 = as float32! 6.25
		--assert -2048 = as int32! fi-mixed/i16
		--assert fi-mixed/fptr/value = 12.5
		--assert fi-mixed/f64 = 12345.678
		--assert fi-mixed/u64 = as uint64! 8000000000000001h
		--assert -9 = as int32! fi-mixed/tail
		fi-u64-parts: as fixed-int64-parts! :fi-mixed/u64
		--assert fi-u64-parts/lo = 1
		--assert fi-u64-parts/hi = -2147483648
		fi-mixed/ptr/value: -777
		--assert fi-mixed-box/i = -777
		fi-mixed/fptr/value: 77.25
		--assert fi-mixed-box/f = 77.25
		fi-mixed/name/1: #"F"
		--assert fi-mixed/name/1 = #"F"
		fi-mixed-copy/raw: fi-mixed/raw
		fi-mixed-copy/name: fi-mixed/name
		fi-mixed-copy/ptr: fi-mixed/ptr
		fi-mixed-copy/fptr: fi-mixed/fptr
		fi-mixed-copy/f64: fi-mixed/f64
		fi-mixed-copy/u64: fi-mixed/u64 + as uint64! 0000000000000002h
		--assert fi-mixed-copy/raw = #"Q"
		--assert fi-mixed-copy/name/1 = #"F"
		--assert fi-mixed-copy/name/5 = #"d"
		--assert fi-mixed-copy/ptr/value = -777
		--assert fi-mixed-copy/fptr/value = 77.25
		--assert fi-mixed-copy/f64 = 12345.678
		--assert fi-mixed-copy/u64 = as uint64! 8000000000000003h

	--test-- "fixed-int-struct-mixed-nested-1"
		fi-mixed-box: declare struct! [
			i [integer!]
			f [float!]
		]
		fi-mixed-nested: declare fixed-int-mixed-nested!
		fi-mixed-box/i: 1234
		fi-mixed-box/f: 9.75
		fi-mixed-nested/head: as uint8! 7
		fi-mixed-nested/value/tag: as uint8! 33
		fi-mixed-nested/value/raw: #"Z"
		fi-mixed-nested/value/name: "nested"
		fi-mixed-nested/value/ptr: :fi-mixed-box/i
		fi-mixed-nested/value/f32: as float32! 1.5
		fi-mixed-nested/value/i16: as int16! -321
		fi-mixed-nested/value/fptr: as pointer! [float!] :fi-mixed-box/f
		fi-mixed-nested/value/f64: 44.125
		fi-mixed-nested/value/u64: as uint64! 0000000100000004h
		fi-mixed-nested/value/tail: as int8! -4
		fi-mixed-nested/done: as uint16! 60000
		--assert 7 = as int32! fi-mixed-nested/head
		--assert 33 = as int32! fi-mixed-nested/value/tag
		--assert fi-mixed-nested/value/raw = #"Z"
		--assert fi-mixed-nested/value/name/1 = #"n"
		--assert fi-mixed-nested/value/name/6 = #"d"
		--assert fi-mixed-nested/value/ptr/value = 1234
		--assert fi-mixed-nested/value/f32 = as float32! 1.5
		--assert -321 = as int32! fi-mixed-nested/value/i16
		--assert fi-mixed-nested/value/fptr/value = 9.75
		--assert fi-mixed-nested/value/f64 = 44.125
		--assert fi-mixed-nested/value/u64 = as uint64! 0000000100000004h
		--assert -4 = as int32! fi-mixed-nested/value/tail
		--assert 60000 = as int32! fi-mixed-nested/done
		fi-mixed-nested/value/ptr/value: -1234
		--assert fi-mixed-box/i = -1234
		fi-mixed-nested/value/fptr/value: 19.5
		--assert fi-mixed-box/f = 19.5
		fi-mixed-nested/value/name/1: #"N"
		--assert fi-mixed-nested/value/name/1 = #"N"

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
