Red/System [
	Title:   "Red/System math mixed tests script"
	Author:  "Nenad Rakocevic"
	File: 	 %math-mixed-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "math-mixed"

===start-group=== "Math implicit type castings"

	--test-- "math-implicit-cast-1"	--assert 10 - #"^C" = 7
	--test-- "math-implicit-cast-2" --assert -1 - #"^C" = -4
	--test-- "math-implicit-cast-3" --assert 10 + #"^C" = 13
	--test-- "math-implicit-cast-4" --assert -1 + #"^C" = 2
	--test-- "math-implicit-cast-5" --assert 10 * #"^C" = 30
	--test-- "math-implicit-cast-6" --assert -1 * #"^C" = -3
	--test-- "math-implicit-cast-7" --assert 10 / #"^C" = 3
	--test-- "math-implicit-cast-8" --assert -10 / #"^C" = -3
	--test-- "math-implicit-cast-9" --assert 1000 - #"^C" = 997

	byte: #"^C"
	--test-- "math-implicit-cast-10" --assert 10 - byte = 7
	--test-- "math-implicit-cast-11" --assert -1 - byte = -4
	--test-- "math-implicit-cast-12" --assert 10 + byte = 13
	--test-- "math-implicit-cast-13" --assert -1 + byte = 2
	--test-- "math-implicit-cast-14" --assert 10 * byte = 30
	--test-- "math-implicit-cast-15" --assert -1 * byte = -3
	--test-- "math-implicit-cast-16" --assert 10 / byte = 3
	--test-- "math-implicit-cast-17" --assert -10 / byte = -3
	--test-- "math-implicit-cast-18" --assert 1000 - byte = 997
	--test-- "math-implicit-cast-19" --assert 1000 or (as-integer byte) = 1003

===end-group===


===start-group=== "Simple nested expressions"

		ident: func [i [integer!] return: [integer!]][i]
		a: 1
		b: 2
		c: 3

	--test-- "math-nested-1"		--assert 1 + (3 - 2) = 2
	--test-- "math-nested-2"		--assert a + (3 - 2) = 2
	--test-- "math-nested-3"		--assert a + (3 - b) = 2
	--test-- "math-nested-4"		--assert a + (c - 2) = 2
	--test-- "math-nested-5"		--assert a + (c - b) = b
	--test-- "math-nested-6"		--assert (3 - 1) + (3 - 2) = 3
	--test-- "math-nested-7"		--assert (c - a) + (c - b) = c
	--test-- "math-nested-8"		--assert ((3 - 1) - (3 - 2)) - ((3 - 1) - (3 - 2)) = 0
	--test-- "math-nested-9"		--assert ((c - a) - (c - b)) - ((c - a) - (c - b)) = 0
	--test-- "math-nested-10"		--assert (3 * 1) + (3 * 2) = 9
	--test-- "math-nested-11"		--assert (3 / 1) + (3 / 2) = 4
	--test-- "math-nested-12"		--assert ((3 * 1) - (3 * 2)) * ((3 * 1) - (3 * 2)) = 9
	--test-- "math-nested-13"		--assert (c * a) + (c * b) = 9
	--test-- "math-nested-14"		--assert (3 * ident 1) + (3 * ident 2) = 9
	--test-- "math-nested-15"		--assert ((ident 3) * ident 1) + ((ident 3) * ident 2) = 9
	
		foo-nested: func [
			/local a b c
		][
			a: 2
			b: 3
			c: 4

			--test-- "loc-math-nested-1"	--assert 1 + (3 - 2) = 2
			--test-- "loc-math-nested-2"	--assert a + (3 - 2) = 3
			--test-- "loc-math-nested-3"	--assert a + (3 - b) = 2
			--test-- "loc-math-nested-4"	--assert a + (c - 2) = 4
			--test-- "loc-math-nested-5"	--assert a + (c - b) = b
			--test-- "loc-math-nested-6"	--assert (3 - 1) + (3 - 2) = 3
			--test-- "loc-math-nested-7"	--assert (c - a) + (c - b) = b
			--test-- "loc-math-nested-8"	--assert ((3 - 1) - (3 - 2)) - ((3 - 1) - (3 - 2)) = 0
			--test-- "loc-math-nested-9"	--assert ((c - a) - (c - b)) - ((c - a) - (c - b)) = 0
		]
		foo-nested

===end-group===

===start-group=== "Mixed nested expressions"

		fooA: func [a [int-ptr!] return: [int-ptr!]][a]
		fooB: func [b [integer!] return: [integer!]][b]

		s: declare struct! [
			a	[int-ptr!]
			b	[integer!]
			c	[int-ptr!]
		]
		s/b: 3
		size: 2

	--test-- "math-mixed-1"
		s/a: as int-ptr! 1000h
		s/a: s/a + 2							;-- reg/imm
		--assert s/a = as int-ptr! 1008h

	--test-- "math-mixed-2"
		s/a: as int-ptr! 1000h
		i: 2 + as-integer s/a					;-- imm/reg
		--assert i = 1002h

	--test-- "math-mixed-3"
		s/a: as int-ptr! 1000h
		s/a: (as int-ptr! 2) + as-integer s/a	;-- imm/reg
		--assert s/a = as int-ptr! 4002h

	--test-- "math-mixed-4"
		s/a: as int-ptr! s/b + size				;-- reg/ref
		--assert s/a = as int-ptr! 05h

	--test-- "math-mixed-5"
		i: size + s/b							;-- ref/reg
		--assert i = 05h

	--test-- "math-mixed-6"
		s/a: as int-ptr! size + s/b				;-- ref/reg
		--assert s/a = as int-ptr! 05h

	--test-- "math-mixed-7"
		i: s/b + size - 1						;-- (reg/ref)/imm
		--assert i = 04h

	--test-- "math-mixed-8"
		i: s/b - 1 + size						;-- (reg/imm)/ref
		--assert i = 04h

	--test-- "math-mixed-9"
		s/a: as int-ptr! 1000h
		s/a: s/a + size - 1						;-- (reg/ref)/imm
		--assert s/a = as int-ptr! 1004h

	--test-- "math-mixed-10"
		s/a: as int-ptr! 1000h
		s/a: s/a - 1 + size						;-- (reg/imm)/ref
		--assert s/a = as int-ptr! 1004h

	--test-- "math-mixed-11"
		s/a: as int-ptr! 1000h
		s/c: s/a + s/b + 2						;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-12"
		s/a: as int-ptr! 1000h
		s/c: s/a + s/b + size					;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-13"
		s/a: as int-ptr! 1000h
		s/c: s/a + s/b + s/b					;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 1018h

	--test-- "math-mixed-14"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) + 2						;-- reg/imm
		--assert s/a = as int-ptr! 1008h

	--test-- "math-mixed-15"
		s/a: as int-ptr! 1000h
		i: 2 + as-integer fooA s/a				;-- imm/reg
		--assert i = 1002h

	--test-- "math-mixed-16"
		s/a: as int-ptr! 1000h
		s/a: (as int-ptr! 2) + as-integer fooA s/a	;-- imm/reg
		--assert s/a = as int-ptr! 4002h

	--test-- "math-mixed-17"
		s/a: (as int-ptr! fooB s/b) + size		;-- reg/ref
		--assert s/a = as int-ptr! 0Bh

	--test-- "math-mixed-18"
		i: size + fooB s/b						;-- ref/reg
		--assert i = 05h

	--test-- "math-mixed-19"
		s/a: (as int-ptr! size) + fooB s/b		;-- ref/reg
		--assert s/a = as int-ptr! 0Eh

	--test-- "math-mixed-20"
		i: (fooB s/b) + size - 1				;-- (reg/ref)/imm
		--assert i = 04h

	--test-- "math-mixed-21"
		i: (fooB s/b) - 1 + size				;-- (reg/imm)/ref
		--assert i = 04h

	--test-- "math-mixed-22"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) + size - 1				;-- (reg/ref)/imm
		--assert s/a = as int-ptr! 1004h
  
	--test-- "math-mixed-23"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) - 1 + size				;-- (reg/imm)/ref
		--assert s/a = as int-ptr! 1004h

	--test-- "math-mixed-24"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + s/b + 2				;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-25"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + s/b + size			;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-26"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + (fooB s/b) + s/b		;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 1018h

	--test-- "math-mixed-27"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + (fooB s/b) + 2		;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-28"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + (fooB s/b) + size		;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 1014h

	--test-- "math-mixed-29"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) + s/b + (fooB s/b) 		;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 1018h

	--test-- "math-mixed-30"
		s/a: as int-ptr! 1000h
		i: s/b + (fooA s/a) + (fooB s/b) 		;-- (reg/reg)/reg
		--assert i = 1006h

	--test-- "math-mixed-31"
		s/a: as int-ptr! 1000h
		i: 2 + (fooA s/a) + (fooB s/b) 			;-- (imm/reg)/reg
		--assert i = 1005h

	--test-- "math-mixed-32"
		s/a: as int-ptr! 1000h
		i: 2 + (fooA s/a) + size				;-- (imm/reg)/ref
		--assert i = 1004h

	--test-- "math-mixed-33"
		s/a: as int-ptr! 1000h
		i: 2 + (fooA s/a) + 3					;-- (imm/reg)/imm
		--assert i = 1005h


	--test-- "math-mixed-34"
		s/a: as int-ptr! 1000h
		s/a: s/a - 2							;-- reg/imm
		--assert s/a = as int-ptr! 0FF8h

	--test-- "math-mixed-35"
		s/a: as int-ptr! 1000h
		i: 2000h - as-integer s/a				;-- imm/reg
		--assert i = 1000h

	--test-- "math-mixed-36"
		s/a: as int-ptr! 1000h
		s/a: (as int-ptr! 6000h) - as-integer s/a	;-- imm/reg
		--assert s/a = as int-ptr! 2000h

	--test-- "math-mixed-37"
		s/a: as int-ptr! s/b - size				;-- reg/ref
		--assert s/a = as int-ptr! 01h

	--test-- "math-mixed-38"
		i: size - s/b							;-- ref/reg
		--assert i = -1

	--test-- "math-mixed-39"
		s/a: (as int-ptr! size) - s/b			;-- ref/reg
		--assert s/a = as int-ptr! -10

	--test-- "math-mixed-40"
		i: s/b - size - 1						;-- (reg/ref)/imm
		--assert i = 0

	--test-- "math-mixed-41"
		i: s/b - 1 - size						;-- (reg/imm)/ref
		--assert i = 0

	--test-- "math-mixed-42"
		s/a: as int-ptr! 1000h
		s/a: s/a - size - 1						;-- (reg/ref)/imm
		--assert s/a = as int-ptr! 0FF4h

	--test-- "math-mixed-43"
		s/a: as int-ptr! 1000h
		s/a: s/a - 1 - size						;-- (reg/imm)/ref
		--assert s/a = as int-ptr! 0FF4h

	--test-- "math-mixed-44"
		s/a: as int-ptr! 1000h
		s/c: s/a - s/b - 2						;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-45"
		s/a: as int-ptr! 1000h
		s/c: s/a - s/b - size					;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-46"
		s/a: as int-ptr! 1000h
		s/c: s/a - s/b - s/b					;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 0FE8h

	--test-- "math-mixed-47"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) - 2						;-- reg/imm
		--assert s/a = as int-ptr! 0FF8h

	--test-- "math-mixed-48"
		s/a: as int-ptr! 1000h
		i: 2 - as-integer fooA s/a				;-- imm/reg
		--assert i = FFFFF002h

	--test-- "math-mixed-49"
		s/a: as int-ptr! 1000h
		s/a: (as int-ptr! 2) - as-integer fooA s/a	;-- imm/reg
		--assert s/a = as int-ptr! FFFFC002h

	--test-- "math-mixed-50"
		s/a: (as int-ptr! fooB s/b) - size		;-- reg/ref
		--assert s/a = as int-ptr! -5

	--test-- "math-mixed-51"
		i: size - fooB s/b						;-- ref/reg
		--assert i = -1

	--test-- "math-mixed-52"
		s/a: (as int-ptr! size) - fooB s/b		;-- ref/reg
		--assert s/a = as int-ptr! -10

	--test-- "math-mixed-53"
		i: (fooB s/b) - size - 1				;-- (reg/ref)/imm
		--assert i = 0

	--test-- "math-mixed-54"
		i: (fooB s/b) - 1 - size				;-- (reg/imm)/ref
		--assert i = 0

	--test-- "math-mixed-55"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) - size - 1				;-- (reg/ref)/imm
		--assert s/a = as int-ptr! 0FF4h

	--test-- "math-mixed-56"
		s/a: as int-ptr! 1000h
		s/a: (fooA s/a) - 1 - size				;-- (reg/imm)/ref
		--assert s/a = as int-ptr! 0FF4h

	--test-- "math-mixed-57"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - s/b - 2				;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-58"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - s/b - size			;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-59"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - (fooB s/b) - s/b		;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 0FE8h

	--test-- "math-mixed-60"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - (fooB s/b) - 2		;-- (reg/reg)/imm
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-61"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - (fooB s/b) - size		;-- (reg/reg)/ref
		--assert s/c = as int-ptr! 0FECh

	--test-- "math-mixed-62"
		s/a: as int-ptr! 1000h
		s/c: (fooA s/a) - s/b - (fooB s/b) 		;-- (reg/reg)/reg
		--assert s/c = as int-ptr! 0FE8h

	--test-- "math-mixed-63"
		s/a: as int-ptr! 1000h
		i: s/b - (fooA s/a) - (fooB s/b) 		;-- (reg/reg)/reg
		--assert i = FFFFF000h

	--test-- "math-mixed-64"
		s/a: as int-ptr! 1000h
		i: 2 - (fooA s/a) - (fooB s/b) 			;-- (imm/reg)/reg
		--assert i = FFFFEFFFh

	--test-- "math-mixed-65"
		s/a: as int-ptr! 1000h
		i: 2 - (fooA s/a) - size				;-- (imm/reg)/ref
		--assert i = FFFFF000h

	--test-- "math-mixed-66"
		s/a: as int-ptr! 1000h
		i: 2 - (fooA s/a) - 3					;-- (imm/reg)/imm
		--assert i = FFFFEFFFh

	--test-- "math-mixed-67"
		s/a: as int-ptr! 1000h
		s/c: as int-ptr! 1010h
		i: as-integer s/c - s/a					;-- reg/reg (pointer - pointer)
		--assert i = 10h

	--test-- "math-mixed-68"
		s/a: as int-ptr! 1000h
		s/c: as int-ptr! 1010h
		i: as-integer (s/c - s/a) + 1			;-- reg/reg (pointer - pointer)
		--assert i = 14h

	--test-- "math-mixed-69"
		s/a: as int-ptr! 00154E28h
		s/c: as int-ptr! 00150018h
		i: (as-integer (s/a - s/c) + 1)	/ 4		;-- reg/reg (pointer - pointer)
		--assert i = 4997

	--test-- "math-mixed-70"
		p: declare struct! [
			a	[byte-ptr!]
			c	[int-ptr!]
		]
		p/a: as byte-ptr! 001F0014h
		p/c: as int-ptr!  001D0004h
		i: as-integer (p/a - ((as byte-ptr! p/c) + 16))	;-- reg/(reg/imm)
		--assert i = 00020000h

	--test-- "math-mixed-71"
		p/a: as byte-ptr! 001F0014h
		p/c: as int-ptr!  001D0014h
		series: p/c
		sz: 32
		--assert ((as byte-ptr! series) + sz) < p/a		;-- (ref/ref)/reg

===end-group===

~~~end-file~~~
