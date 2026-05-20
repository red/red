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

]

~~~end-file~~~
