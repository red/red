Red/System [
	Title:   "Red/System union! datatype test script"
	Author:  "Red Foundation"
	File: 	 %union-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

#if any [target = 'IA-32 target = 'ARM] [

raw-value!: alias union! [
	i32 [integer!]
	u8  [uint8!]
	f32 [float32!]
	ptr [int-ptr!]
	str [c-string!]
	ch  [byte!]
]

tagged-value!: alias union! [
	[variant]
	i8  [int8!]
	u16 [uint16!]
	i32 [int32!]
	u64 [uint64!]
	f32 [float32!]
	ptr [int-ptr!]
	str [c-string!]
	ch  [byte!]
]

small-tagged-value!: alias union! [
	[variant]
	i32 [integer!]
]

event!: alias union! [
	[variant]
	mouse [
		x [integer!]
		y [integer!]
	]
	key [
		code [integer!]
	]
]

boxed-value!: alias struct! [
	head [uint8!]
	data [tagged-value! value]
	tail [uint16!]
]

raw-boxed-value!: alias struct! [
	head [integer!]
	data [raw-value! value]
	tail [integer!]
]

union-by-value-id: func [value [tagged-value! value] return: [integer!]][
	either variant? value 'i32 [value/i32][0]
]

union-by-value-make: func [
	return: [small-tagged-value! value]
	/local value [small-tagged-value! value]
][
	value/i32: 987
	value
]

union-by-value-make-large: func [
	return: [tagged-value! value]
	/local value [tagged-value! value]
][
	value/i32: 654
	value
]

~~~start-file~~~ "union!"

===start-group=== "Raw union layout and access"

	--test-- "union-raw-size-1"
	--assert 4 = size? raw-value!

	--test-- "union-raw-rw-1"
	raw: declare raw-value!
	raw/i32: 123456
	--assert raw/i32 = 123456
	raw/u8: as uint8! 255
	--assert raw/u8 = as uint8! 255
	raw/ch: #"A"
	--assert raw/ch = #"A"

	--test-- "union-raw-rw-2"
	raw/f32: as float32! 6.25
	--assert raw/f32 = as float32! 6.25
	raw/str: "hello"
	--assert raw/str/1 = #"h"

	--test-- "union-raw-rw-3"
	raw-int: 4321
	raw/ptr: :raw-int
	--assert raw/ptr/value = 4321
	raw/ptr/value: 8765
	--assert raw-int = 8765

	--test-- "union-raw-in-struct-1"
	raw-box: declare raw-boxed-value!
	raw-box/head: 11
	raw-box/tail: 22
	raw-box/data/i32: 333
	--assert raw-box/head = 11
	--assert raw-box/tail = 22
	--assert raw-box/data/i32 = 333
	raw-box/data/str: "raw-box"
	--assert raw-box/data/str/1 = #"r"

===end-group===

===start-group=== "Tagged union predicates and assignment"

	--test-- "union-tagged-size-1"
	--assert 12 = size? tagged-value!

	--test-- "union-tagged-rw-1"
	v: declare tagged-value!
	--assert not variant? v 'i8
	v/i8: as int8! -12
	--assert variant? v 'i8
	--assert not variant? v 'u16
	--assert v/i8 = as int8! -12

	--test-- "union-tagged-rw-2"
	v/u16: as uint16! 65535
	--assert variant? v 'u16
	--assert v/u16 = as uint16! 65535
	v/i32: -123456
	--assert variant? v 'i32
	--assert v/i32 = -123456

	--test-- "union-tagged-rw-3"
	v/u64: FFFFFFFFFFFFFFFFh
	--assert variant? v 'u64
	--assert v/u64 = FFFFFFFFFFFFFFFFh

	--test-- "union-tagged-rw-4"
	v/f32: as float32! 1.5
	--assert variant? v 'f32
	--assert v/f32 = as float32! 1.5
	v/str: "hello"
	--assert variant? v 'str
	--assert v/str/1 = #"h"
	v/ch: #"Z"
	--assert variant? v 'ch
	--assert v/ch = #"Z"

	--test-- "union-tagged-rw-5"
	tagged-int: 1234
	v/ptr: :tagged-int
	--assert variant? v 'ptr
	--assert v/ptr/value = 1234
	v/ptr/value: 5678
	--assert tagged-int = 5678

===end-group===

===start-group=== "Tagged union struct payloads"

	--test-- "union-struct-payload-1"
	e: declare event!
	--assert not variant? e 'mouse
	e/mouse/x: 10
	e/mouse/y: 20
	--assert variant? e 'mouse
	--assert e/mouse/x = 10
	--assert e/mouse/y = 20

	--test-- "union-struct-payload-2"
	e/key/code: 42
	--assert variant? e 'key
	--assert e/key/code = 42

	--test-- "union-switch-1"
	score: 0
	switch e [
		mouse [score: 1]
		key   [score: 2]
		default [score: 3]
	]
	--assert score = 2

	--test-- "union-switch-2"
	score: 7
	switch e [
		mouse [score: 1]
	]
	--assert score = 7

===end-group===

===start-group=== "Tagged union inside struct"

	--test-- "union-in-struct-1"
	box: declare boxed-value!
	box/head: as uint8! 12
	box/tail: as uint16! 3456
	box/data/i32: 77
	--assert box/head = as uint8! 12
	--assert box/tail = as uint16! 3456
	--assert variant? box/data 'i32
	--assert box/data/i32 = 77

	--test-- "union-in-struct-2"
	box/data/str: "boxed"
	--assert variant? box/data 'str
	--assert box/data/str/1 = #"b"

===end-group===

===start-group=== "Tagged union by value"

	--test-- "union-by-value-1"
	v/i32: 456
	--assert 456 = union-by-value-id v

	--test-- "union-by-value-2"
	small-v: declare small-tagged-value!
	small-v: union-by-value-make
	--assert variant? small-v 'i32
	--assert small-v/i32 = 987

	--test-- "union-by-value-3"
	v: union-by-value-make-large
	--assert variant? v 'i32
	--assert v/i32 = 654

===end-group===

~~~end-file~~~

]
