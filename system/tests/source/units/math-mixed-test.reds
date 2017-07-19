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

===start-group=== "Arithmetic"

  mm-s: declare struct! [
      a [integer!]
      b [integer!]
      c [integer!]
      d [integer!]
      e [integer!]
      f [integer!]
      g [integer!]
      h [integer!]
  ]

  --test-- "maths-auto-1"
  --assert 1 = ( (1 * 1) * 1 )
  --test-- "maths-auto-2"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert 1 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-3"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert 1 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-4"
  --assert 1 = ( ((ident 1) * (ident 1)) * (ident 1) )
  --test-- "maths-auto-5"
  --assert 8 = ( (2 * 2) * 2 )
  --test-- "maths-auto-6"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert 8 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-7"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert 8 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-8"
  --assert 8 = ( ((ident 2) * (ident 2)) * (ident 2) )
  --test-- "maths-auto-9"
  --assert 16777216 = ( (256 * 256) * 256 )
  --test-- "maths-auto-10"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert 16777216 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-11"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert 16777216 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-12"
  --assert 16777216 = ( ((ident 256) * (ident 256)) * (ident 256) )
  --test-- "maths-auto-13"
  --assert 16974593 = ( (257 * 257) * 257 )
  --test-- "maths-auto-14"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert 16974593 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-15"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert 16974593 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-16"
  --assert 16974593 = ( ((ident 257) * (ident 257)) * (ident 257) )
  --test-- "maths-auto-17"
  --assert 16776960 = ( (255 * 256) * 257 )
  --test-- "maths-auto-18"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert 16776960 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-19"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert 16776960 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-20"
  --assert 16776960 = ( ((ident 255) * (ident 256)) * (ident 257) )
  --test-- "maths-auto-21"
  --assert -16777216 = ( (-256 * 256) * 256 )
  --test-- "maths-auto-22"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -16777216 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-23"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -16777216 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-24"
  --assert -16777216 = ( ((ident -256) * (ident 256)) * (ident 256) )
  --test-- "maths-auto-25"
  --assert -16974593 = ( (257 * -257) * 257 )
  --test-- "maths-auto-26"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert -16974593 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-27"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert -16974593 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-28"
  --assert -16974593 = ( ((ident 257) * (ident -257)) * (ident 257) )
  --test-- "maths-auto-29"
  --assert -16776960 = ( (255 * 256) * -257 )
  --test-- "maths-auto-30"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert -16776960 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-31"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert -16776960 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-32"
  --assert -16776960 = ( ((ident 255) * (ident 256)) * (ident -257) )
  --test-- "maths-auto-33"
  --assert -16777216 = ( (-256 * -256) * -256 )
  --test-- "maths-auto-34"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert -16777216 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-35"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert -16777216 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-36"
  --assert -16777216 = ( ((ident -256) * (ident -256)) * (ident -256) )
  --test-- "maths-auto-37"
  --assert -16974593 = ( (-257 * -257) * -257 )
  --test-- "maths-auto-38"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert -16974593 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-39"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert -16974593 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-40"
  --assert -16974593 = ( ((ident -257) * (ident -257)) * (ident -257) )
  --test-- "maths-auto-41"
  --assert -16776960 = ( (-255 * -256) * -257 )
  --test-- "maths-auto-42"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert -16776960 = ((mm-a  * mm-b) * mm-c )
  --test-- "maths-auto-43"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert -16776960 = ( (mm-s/a * mm-s/b) * mm-s/c )
  --test-- "maths-auto-44"
  --assert -16776960 = ( ((ident -255) * (ident -256)) * (ident -257) )
  --test-- "maths-auto-45"
  --assert 8 =(as integer! ((#"^(02)" * #"^(02)") * #"^(02)" ))
  --test-- "maths-auto-46"
  --assert 168 =(as integer! ((#"^(07)" * #"^(08)") * #"^(03)" ))
  --test-- "maths-auto-47"
  --assert 1000 = ( (1 * #"^(0A)") * 100 )
  --test-- "maths-auto-48"
  --assert 8192 = ( (2 * #"^(10)") * 256 )
  --test-- "maths-auto-49"
  --assert 250 =(as integer! ((#"^(FD)" * #"^(FE)") * #"^(FF)" ))
  --test-- "maths-auto-50"
  --assert 116 =(as integer! ((#"^(AA)" * 34) * #"^(99)" ))
  --test-- "maths-auto-51"
  --assert -1 = ( (1 - 1) - 1 )
  --test-- "maths-auto-52"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert -1 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-53"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert -1 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-54"
  --assert -1 = ( ((ident 1) - (ident 1)) - (ident 1) )
  --test-- "maths-auto-55"
  --assert -2 = ( (2 - 2) - 2 )
  --test-- "maths-auto-56"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert -2 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-57"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert -2 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-58"
  --assert -2 = ( ((ident 2) - (ident 2)) - (ident 2) )
  --test-- "maths-auto-59"
  --assert -256 = ( (256 - 256) - 256 )
  --test-- "maths-auto-60"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert -256 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-61"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert -256 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-62"
  --assert -256 = ( ((ident 256) - (ident 256)) - (ident 256) )
  --test-- "maths-auto-63"
  --assert -257 = ( (257 - 257) - 257 )
  --test-- "maths-auto-64"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert -257 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-65"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert -257 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-66"
  --assert -257 = ( ((ident 257) - (ident 257)) - (ident 257) )
  --test-- "maths-auto-67"
  --assert -258 = ( (255 - 256) - 257 )
  --test-- "maths-auto-68"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert -258 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-69"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert -258 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-70"
  --assert -258 = ( ((ident 255) - (ident 256)) - (ident 257) )
  --test-- "maths-auto-71"
  --assert -768 = ( (-256 - 256) - 256 )
  --test-- "maths-auto-72"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -768 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-73"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -768 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-74"
  --assert -768 = ( ((ident -256) - (ident 256)) - (ident 256) )
  --test-- "maths-auto-75"
  --assert 257 = ( (257 - -257) - 257 )
  --test-- "maths-auto-76"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert 257 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-77"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert 257 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-78"
  --assert 257 = ( ((ident 257) - (ident -257)) - (ident 257) )
  --test-- "maths-auto-79"
  --assert 256 = ( (255 - 256) - -257 )
  --test-- "maths-auto-80"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert 256 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-81"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert 256 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-82"
  --assert 256 = ( ((ident 255) - (ident 256)) - (ident -257) )
  --test-- "maths-auto-83"
  --assert 256 = ( (-256 - -256) - -256 )
  --test-- "maths-auto-84"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert 256 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-85"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert 256 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-86"
  --assert 256 = ( ((ident -256) - (ident -256)) - (ident -256) )
  --test-- "maths-auto-87"
  --assert 257 = ( (-257 - -257) - -257 )
  --test-- "maths-auto-88"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert 257 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-89"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert 257 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-90"
  --assert 257 = ( ((ident -257) - (ident -257)) - (ident -257) )
  --test-- "maths-auto-91"
  --assert 258 = ( (-255 - -256) - -257 )
  --test-- "maths-auto-92"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert 258 = ((mm-a  - mm-b) - mm-c )
  --test-- "maths-auto-93"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert 258 = ( (mm-s/a - mm-s/b) - mm-s/c )
  --test-- "maths-auto-94"
  --assert 258 = ( ((ident -255) - (ident -256)) - (ident -257) )
  --test-- "maths-auto-95"
  --assert 254 =(as integer! ((#"^(02)" - #"^(02)") - #"^(02)" ))
  --test-- "maths-auto-96"
  --assert 252 =(as integer! ((#"^(07)" - #"^(08)") - #"^(03)" ))
  --test-- "maths-auto-97"
  --assert -109 = ( (1 - #"^(0A)") - 100 )
  --test-- "maths-auto-98"
  --assert -270 = ( (2 - #"^(10)") - 256 )
  --test-- "maths-auto-99"
  --assert 0 =(as integer! ((#"^(FD)" - #"^(FE)") - #"^(FF)" ))
  --test-- "maths-auto-100"
  --assert 239 =(as integer! ((#"^(AA)" - 34) - #"^(99)" ))
  --test-- "maths-auto-101"
  --assert 0 = ( (1 * 1) - 1 )
  --test-- "maths-auto-102"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert 0 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-103"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert 0 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-104"
  --assert 0 = ( ((ident 1) * (ident 1)) - (ident 1) )
  --test-- "maths-auto-105"
  --assert 2 = ( (2 * 2) - 2 )
  --test-- "maths-auto-106"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert 2 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-107"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert 2 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-108"
  --assert 2 = ( ((ident 2) * (ident 2)) - (ident 2) )
  --test-- "maths-auto-109"
  --assert 65280 = ( (256 * 256) - 256 )
  --test-- "maths-auto-110"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert 65280 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-111"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert 65280 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-112"
  --assert 65280 = ( ((ident 256) * (ident 256)) - (ident 256) )
  --test-- "maths-auto-113"
  --assert 65792 = ( (257 * 257) - 257 )
  --test-- "maths-auto-114"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert 65792 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-115"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert 65792 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-116"
  --assert 65792 = ( ((ident 257) * (ident 257)) - (ident 257) )
  --test-- "maths-auto-117"
  --assert 65023 = ( (255 * 256) - 257 )
  --test-- "maths-auto-118"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert 65023 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-119"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert 65023 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-120"
  --assert 65023 = ( ((ident 255) * (ident 256)) - (ident 257) )
  --test-- "maths-auto-121"
  --assert -65792 = ( (-256 * 256) - 256 )
  --test-- "maths-auto-122"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -65792 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-123"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -65792 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-124"
  --assert -65792 = ( ((ident -256) * (ident 256)) - (ident 256) )
  --test-- "maths-auto-125"
  --assert -66306 = ( (257 * -257) - 257 )
  --test-- "maths-auto-126"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert -66306 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-127"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert -66306 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-128"
  --assert -66306 = ( ((ident 257) * (ident -257)) - (ident 257) )
  --test-- "maths-auto-129"
  --assert 65537 = ( (255 * 256) - -257 )
  --test-- "maths-auto-130"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert 65537 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-131"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert 65537 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-132"
  --assert 65537 = ( ((ident 255) * (ident 256)) - (ident -257) )
  --test-- "maths-auto-133"
  --assert 65792 = ( (-256 * -256) - -256 )
  --test-- "maths-auto-134"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert 65792 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-135"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert 65792 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-136"
  --assert 65792 = ( ((ident -256) * (ident -256)) - (ident -256) )
  --test-- "maths-auto-137"
  --assert 66306 = ( (-257 * -257) - -257 )
  --test-- "maths-auto-138"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert 66306 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-139"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert 66306 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-140"
  --assert 66306 = ( ((ident -257) * (ident -257)) - (ident -257) )
  --test-- "maths-auto-141"
  --assert 65537 = ( (-255 * -256) - -257 )
  --test-- "maths-auto-142"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert 65537 = ((mm-a  * mm-b) - mm-c )
  --test-- "maths-auto-143"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert 65537 = ( (mm-s/a * mm-s/b) - mm-s/c )
  --test-- "maths-auto-144"
  --assert 65537 = ( ((ident -255) * (ident -256)) - (ident -257) )
  --test-- "maths-auto-145"
  --assert 2 =(as integer! ((#"^(02)" * #"^(02)") - #"^(02)" ))
  --test-- "maths-auto-146"
  --assert 53 =(as integer! ((#"^(07)" * #"^(08)") - #"^(03)" ))
  --test-- "maths-auto-147"
  --assert -90 = ( (1 * #"^(0A)") - 100 )
  --test-- "maths-auto-148"
  --assert -224 = ( (2 * #"^(10)") - 256 )
  --test-- "maths-auto-149"
  --assert 7 =(as integer! ((#"^(FD)" * #"^(FE)") - #"^(FF)" ))
  --test-- "maths-auto-150"
  --assert 251 =(as integer! ((#"^(AA)" * 34) - #"^(99)" ))
  --test-- "maths-auto-151"
  --assert 0 = ( (1 - 1) * 1 )
  --test-- "maths-auto-152"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-153"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-154"
  --assert 0 = ( ((ident 1) - (ident 1)) * (ident 1) )
  --test-- "maths-auto-155"
  --assert 0 = ( (2 - 2) * 2 )
  --test-- "maths-auto-156"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-157"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-158"
  --assert 0 = ( ((ident 2) - (ident 2)) * (ident 2) )
  --test-- "maths-auto-159"
  --assert 0 = ( (256 - 256) * 256 )
  --test-- "maths-auto-160"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-161"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-162"
  --assert 0 = ( ((ident 256) - (ident 256)) * (ident 256) )
  --test-- "maths-auto-163"
  --assert 0 = ( (257 - 257) * 257 )
  --test-- "maths-auto-164"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-165"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-166"
  --assert 0 = ( ((ident 257) - (ident 257)) * (ident 257) )
  --test-- "maths-auto-167"
  --assert -257 = ( (255 - 256) * 257 )
  --test-- "maths-auto-168"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert -257 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-169"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert -257 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-170"
  --assert -257 = ( ((ident 255) - (ident 256)) * (ident 257) )
  --test-- "maths-auto-171"
  --assert -131072 = ( (-256 - 256) * 256 )
  --test-- "maths-auto-172"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -131072 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-173"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -131072 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-174"
  --assert -131072 = ( ((ident -256) - (ident 256)) * (ident 256) )
  --test-- "maths-auto-175"
  --assert 132098 = ( (257 - -257) * 257 )
  --test-- "maths-auto-176"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert 132098 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-177"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert 132098 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-178"
  --assert 132098 = ( ((ident 257) - (ident -257)) * (ident 257) )
  --test-- "maths-auto-179"
  --assert 257 = ( (255 - 256) * -257 )
  --test-- "maths-auto-180"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert 257 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-181"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert 257 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-182"
  --assert 257 = ( ((ident 255) - (ident 256)) * (ident -257) )
  --test-- "maths-auto-183"
  --assert 0 = ( (-256 - -256) * -256 )
  --test-- "maths-auto-184"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-185"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-186"
  --assert 0 = ( ((ident -256) - (ident -256)) * (ident -256) )
  --test-- "maths-auto-187"
  --assert 0 = ( (-257 - -257) * -257 )
  --test-- "maths-auto-188"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert 0 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-189"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert 0 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-190"
  --assert 0 = ( ((ident -257) - (ident -257)) * (ident -257) )
  --test-- "maths-auto-191"
  --assert -257 = ( (-255 - -256) * -257 )
  --test-- "maths-auto-192"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert -257 = ((mm-a  - mm-b) * mm-c )
  --test-- "maths-auto-193"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert -257 = ( (mm-s/a - mm-s/b) * mm-s/c )
  --test-- "maths-auto-194"
  --assert -257 = ( ((ident -255) - (ident -256)) * (ident -257) )
  --test-- "maths-auto-195"
  --assert 0 =(as integer! ((#"^(02)" - #"^(02)") * #"^(02)" ))
  --test-- "maths-auto-196"
  --assert 253 =(as integer! ((#"^(07)" - #"^(08)") * #"^(03)" ))
  --test-- "maths-auto-197"
  --assert -900 = ( (1 - #"^(0A)") * 100 )
  --test-- "maths-auto-198"
  --assert -3584 = ( (2 - #"^(10)") * 256 )
  --test-- "maths-auto-199"
  --assert 1 =(as integer! ((#"^(FD)" - #"^(FE)") * #"^(FF)" ))
  --test-- "maths-auto-200"
  --assert 72 =(as integer! ((#"^(AA)" - 34) * #"^(99)" ))
  --test-- "maths-auto-201"
  --assert 1 = ( 1 * 1 * 1 )
  --test-- "maths-auto-202"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert 1 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-203"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert 1 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-204"
  --assert 1 = ( (ident 1) * (ident 1) * (ident 1) )
  --test-- "maths-auto-205"
  --assert 8 = ( 2 * 2 * 2 )
  --test-- "maths-auto-206"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert 8 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-207"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert 8 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-208"
  --assert 8 = ( (ident 2) * (ident 2) * (ident 2) )
  --test-- "maths-auto-209"
  --assert 16777216 = ( 256 * 256 * 256 )
  --test-- "maths-auto-210"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert 16777216 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-211"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert 16777216 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-212"
  --assert 16777216 = ( (ident 256) * (ident 256) * (ident 256) )
  --test-- "maths-auto-213"
  --assert 16974593 = ( 257 * 257 * 257 )
  --test-- "maths-auto-214"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert 16974593 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-215"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert 16974593 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-216"
  --assert 16974593 = ( (ident 257) * (ident 257) * (ident 257) )
  --test-- "maths-auto-217"
  --assert 16776960 = ( 255 * 256 * 257 )
  --test-- "maths-auto-218"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert 16776960 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-219"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert 16776960 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-220"
  --assert 16776960 = ( (ident 255) * (ident 256) * (ident 257) )
  --test-- "maths-auto-221"
  --assert -16777216 = ( -256 * 256 * 256 )
  --test-- "maths-auto-222"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -16777216 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-223"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -16777216 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-224"
  --assert -16777216 = ( (ident -256) * (ident 256) * (ident 256) )
  --test-- "maths-auto-225"
  --assert -16974593 = ( 257 * -257 * 257 )
  --test-- "maths-auto-226"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert -16974593 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-227"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert -16974593 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-228"
  --assert -16974593 = ( (ident 257) * (ident -257) * (ident 257) )
  --test-- "maths-auto-229"
  --assert -16776960 = ( 255 * 256 * -257 )
  --test-- "maths-auto-230"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert -16776960 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-231"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert -16776960 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-232"
  --assert -16776960 = ( (ident 255) * (ident 256) * (ident -257) )
  --test-- "maths-auto-233"
  --assert -16777216 = ( -256 * -256 * -256 )
  --test-- "maths-auto-234"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert -16777216 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-235"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert -16777216 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-236"
  --assert -16777216 = ( (ident -256) * (ident -256) * (ident -256) )
  --test-- "maths-auto-237"
  --assert -16974593 = ( -257 * -257 * -257 )
  --test-- "maths-auto-238"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert -16974593 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-239"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert -16974593 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-240"
  --assert -16974593 = ( (ident -257) * (ident -257) * (ident -257) )
  --test-- "maths-auto-241"
  --assert -16776960 = ( -255 * -256 * -257 )
  --test-- "maths-auto-242"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert -16776960 = ( mm-a * mm-b * mm-c )
  --test-- "maths-auto-243"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert -16776960 = ( mm-s/a * mm-s/b * mm-s/c )
  --test-- "maths-auto-244"
  --assert -16776960 = ( (ident -255) * (ident -256) * (ident -257) )
  --test-- "maths-auto-245"
  --assert 8 =(as integer! (#"^(02)" * #"^(02)" * #"^(02)" ))
  --test-- "maths-auto-246"
  --assert 168 =(as integer! (#"^(07)" * #"^(08)" * #"^(03)" ))
  --test-- "maths-auto-247"
  --assert 1000 = ( 1 * #"^(0A)" * 100 )
  --test-- "maths-auto-248"
  --assert 8192 = ( 2 * #"^(10)" * 256 )
  --test-- "maths-auto-249"
  --assert 250 =(as integer! (#"^(FD)" * #"^(FE)" * #"^(FF)" ))
  --test-- "maths-auto-250"
  --assert 116 =(as integer! (#"^(AA)" * 34 * #"^(99)" ))
  --test-- "maths-auto-251"
  --assert -1 = ( 1 - 1 - 1 )
  --test-- "maths-auto-252"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert -1 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-253"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert -1 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-254"
  --assert -1 = ( (ident 1) - (ident 1) - (ident 1) )
  --test-- "maths-auto-255"
  --assert -2 = ( 2 - 2 - 2 )
  --test-- "maths-auto-256"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert -2 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-257"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert -2 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-258"
  --assert -2 = ( (ident 2) - (ident 2) - (ident 2) )
  --test-- "maths-auto-259"
  --assert -256 = ( 256 - 256 - 256 )
  --test-- "maths-auto-260"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert -256 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-261"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert -256 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-262"
  --assert -256 = ( (ident 256) - (ident 256) - (ident 256) )
  --test-- "maths-auto-263"
  --assert -257 = ( 257 - 257 - 257 )
  --test-- "maths-auto-264"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert -257 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-265"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert -257 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-266"
  --assert -257 = ( (ident 257) - (ident 257) - (ident 257) )
  --test-- "maths-auto-267"
  --assert -258 = ( 255 - 256 - 257 )
  --test-- "maths-auto-268"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert -258 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-269"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert -258 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-270"
  --assert -258 = ( (ident 255) - (ident 256) - (ident 257) )
  --test-- "maths-auto-271"
  --assert -768 = ( -256 - 256 - 256 )
  --test-- "maths-auto-272"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -768 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-273"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -768 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-274"
  --assert -768 = ( (ident -256) - (ident 256) - (ident 256) )
  --test-- "maths-auto-275"
  --assert 257 = ( 257 - -257 - 257 )
  --test-- "maths-auto-276"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert 257 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-277"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert 257 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-278"
  --assert 257 = ( (ident 257) - (ident -257) - (ident 257) )
  --test-- "maths-auto-279"
  --assert 256 = ( 255 - 256 - -257 )
  --test-- "maths-auto-280"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert 256 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-281"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert 256 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-282"
  --assert 256 = ( (ident 255) - (ident 256) - (ident -257) )
  --test-- "maths-auto-283"
  --assert 256 = ( -256 - -256 - -256 )
  --test-- "maths-auto-284"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert 256 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-285"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert 256 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-286"
  --assert 256 = ( (ident -256) - (ident -256) - (ident -256) )
  --test-- "maths-auto-287"
  --assert 257 = ( -257 - -257 - -257 )
  --test-- "maths-auto-288"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert 257 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-289"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert 257 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-290"
  --assert 257 = ( (ident -257) - (ident -257) - (ident -257) )
  --test-- "maths-auto-291"
  --assert 258 = ( -255 - -256 - -257 )
  --test-- "maths-auto-292"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert 258 = ( mm-a - mm-b - mm-c )
  --test-- "maths-auto-293"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert 258 = ( mm-s/a - mm-s/b - mm-s/c )
  --test-- "maths-auto-294"
  --assert 258 = ( (ident -255) - (ident -256) - (ident -257) )
  --test-- "maths-auto-295"
  --assert 254 =(as integer! (#"^(02)" - #"^(02)" - #"^(02)" ))
  --test-- "maths-auto-296"
  --assert 252 =(as integer! (#"^(07)" - #"^(08)" - #"^(03)" ))
  --test-- "maths-auto-297"
  --assert -109 = ( 1 - #"^(0A)" - 100 )
  --test-- "maths-auto-298"
  --assert -270 = ( 2 - #"^(10)" - 256 )
  --test-- "maths-auto-299"
  --assert 0 =(as integer! (#"^(FD)" - #"^(FE)" - #"^(FF)" ))
  --test-- "maths-auto-300"
  --assert 239 =(as integer! (#"^(AA)" - 34 - #"^(99)" ))
  --test-- "maths-auto-301"
  --assert 0 = ( 1 - 1 * 1 )
  --test-- "maths-auto-302"
    mm-a: 1
    mm-b: 1
    mm-c: 1
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-303"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-304"
  --assert 0 = ( (ident 1) - (ident 1) * (ident 1) )
  --test-- "maths-auto-305"
  --assert 0 = ( 2 - 2 * 2 )
  --test-- "maths-auto-306"
    mm-a: 2
    mm-b: 2
    mm-c: 2
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-307"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-308"
  --assert 0 = ( (ident 2) - (ident 2) * (ident 2) )
  --test-- "maths-auto-309"
  --assert 0 = ( 256 - 256 * 256 )
  --test-- "maths-auto-310"
    mm-a: 256
    mm-b: 256
    mm-c: 256
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-311"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-312"
  --assert 0 = ( (ident 256) - (ident 256) * (ident 256) )
  --test-- "maths-auto-313"
  --assert 0 = ( 257 - 257 * 257 )
  --test-- "maths-auto-314"
    mm-a: 257
    mm-b: 257
    mm-c: 257
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-315"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-316"
  --assert 0 = ( (ident 257) - (ident 257) * (ident 257) )
  --test-- "maths-auto-317"
  --assert -257 = ( 255 - 256 * 257 )
  --test-- "maths-auto-318"
    mm-a: 255
    mm-b: 256
    mm-c: 257
  --assert -257 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-319"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: 257
  --assert -257 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-320"
  --assert -257 = ( (ident 255) - (ident 256) * (ident 257) )
  --test-- "maths-auto-321"
  --assert -131072 = ( -256 - 256 * 256 )
  --test-- "maths-auto-322"
    mm-a: -256
    mm-b: 256
    mm-c: 256
  --assert -131072 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-323"
    mm-s/a: -256
    mm-s/b: 256
    mm-s/c: 256
  --assert -131072 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-324"
  --assert -131072 = ( (ident -256) - (ident 256) * (ident 256) )
  --test-- "maths-auto-325"
  --assert 132098 = ( 257 - -257 * 257 )
  --test-- "maths-auto-326"
    mm-a: 257
    mm-b: -257
    mm-c: 257
  --assert 132098 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-327"
    mm-s/a: 257
    mm-s/b: -257
    mm-s/c: 257
  --assert 132098 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-328"
  --assert 132098 = ( (ident 257) - (ident -257) * (ident 257) )
  --test-- "maths-auto-329"
  --assert 257 = ( 255 - 256 * -257 )
  --test-- "maths-auto-330"
    mm-a: 255
    mm-b: 256
    mm-c: -257
  --assert 257 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-331"
    mm-s/a: 255
    mm-s/b: 256
    mm-s/c: -257
  --assert 257 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-332"
  --assert 257 = ( (ident 255) - (ident 256) * (ident -257) )
  --test-- "maths-auto-333"
  --assert 0 = ( -256 - -256 * -256 )
  --test-- "maths-auto-334"
    mm-a: -256
    mm-b: -256
    mm-c: -256
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-335"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-336"
  --assert 0 = ( (ident -256) - (ident -256) * (ident -256) )
  --test-- "maths-auto-337"
  --assert 0 = ( -257 - -257 * -257 )
  --test-- "maths-auto-338"
    mm-a: -257
    mm-b: -257
    mm-c: -257
  --assert 0 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-339"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
  --assert 0 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-340"
  --assert 0 = ( (ident -257) - (ident -257) * (ident -257) )
  --test-- "maths-auto-341"
  --assert -257 = ( -255 - -256 * -257 )
  --test-- "maths-auto-342"
    mm-a: -255
    mm-b: -256
    mm-c: -257
  --assert -257 = ( mm-a - mm-b * mm-c )
  --test-- "maths-auto-343"
    mm-s/a: -255
    mm-s/b: -256
    mm-s/c: -257
  --assert -257 = ( mm-s/a - mm-s/b * mm-s/c )
  --test-- "maths-auto-344"
  --assert -257 = ( (ident -255) - (ident -256) * (ident -257) )
  --test-- "maths-auto-345"
  --assert 0 =(as integer! (#"^(02)" - #"^(02)" * #"^(02)" ))
  --test-- "maths-auto-346"
  --assert 253 =(as integer! (#"^(07)" - #"^(08)" * #"^(03)" ))
  --test-- "maths-auto-347"
  --assert -900 = ( 1 - #"^(0A)" * 100 )
  --test-- "maths-auto-348"
  --assert -3584 = ( 2 - #"^(10)" * 256 )
  --test-- "maths-auto-349"
  --assert 1 =(as integer! (#"^(FD)" - #"^(FE)" * #"^(FF)" ))
  --test-- "maths-auto-350"
  --assert 72 =(as integer! (#"^(AA)" - 34 * #"^(99)" ))
  --test-- "maths-auto-351"
  --assert 3 =(as integer! ((#"^(02)" / #"^(02)") + #"^(02)" ))
  --test-- "maths-auto-352"
  --assert 3 =(as integer! ((#"^(07)" / #"^(08)") + #"^(03)" ))
  --test-- "maths-auto-353"
  --assert 255 =(as integer! ((#"^(FD)" / #"^(FE)") + #"^(FF)" ))
  --test-- "maths-auto-354"
  --assert 1 = ( (1 * 1) * (1 * 1) )
  --test-- "maths-auto-355"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 1 = ((mm-a  * mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-356"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 1 = ( (mm-s/a * mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-357"
  --assert 1 = ( ((ident 1) * (ident 1)) * ((ident 1) * (ident 1)) )
  --test-- "maths-auto-358"
  --assert 16 = ( (2 * 2) * (2 * 2) )
  --test-- "maths-auto-359"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 16 = ((mm-a  * mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-360"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 16 = ( (mm-s/a * mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-361"
  --assert 16 = ( ((ident 2) * (ident 2)) * ((ident 2) * (ident 2)) )
  --test-- "maths-auto-362"
  --assert 0 =(as integer! ((#"^(FF)" * 256) * (257 * 258) ))
  --test-- "maths-auto-363"
  --assert 24 =(as integer! ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)") ))
  --test-- "maths-auto-364"
  --assert 0 = ( (1 - 1) - (1 - 1) )
  --test-- "maths-auto-365"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 0 = ((mm-a  - mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-366"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 0 = ( (mm-s/a - mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-367"
  --assert 0 = ( ((ident 1) - (ident 1)) - ((ident 1) - (ident 1)) )
  --test-- "maths-auto-368"
  --assert 0 = ( (2 - 2) - (2 - 2) )
  --test-- "maths-auto-369"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 0 = ((mm-a  - mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-370"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 0 = ( (mm-s/a - mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-371"
  --assert 0 = ( ((ident 2) - (ident 2)) - ((ident 2) - (ident 2)) )
  --test-- "maths-auto-372"
  --assert 0 = ( (256 - 256) - (256 - 256) )
  --test-- "maths-auto-373"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 0 = ((mm-a  - mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-374"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 0 = ( (mm-s/a - mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-375"
  --assert 0 = ( ((ident 256) - (ident 256)) - ((ident 256) - (ident 256)) )
  --test-- "maths-auto-376"
  --assert 0 = ( (257 - 257) - (257 - 257) )
  --test-- "maths-auto-377"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 0 = ((mm-a  - mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-378"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 0 = ( (mm-s/a - mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-379"
  --assert 0 = ( ((ident 257) - (ident 257)) - ((ident 257) - (ident 257)) )
  --test-- "maths-auto-380"
  --assert 0 =(as integer! ((#"^(FF)" - 256) - (257 - 258) ))
  --test-- "maths-auto-381"
  --assert 0 =(as integer! ((#"^(FC)" - #"^(FD)") - (#"^(FE)" - #"^(FF)") ))
  --test-- "maths-auto-382"
  --assert 1 = ( (1 * 1) - (1 - 1) )
  --test-- "maths-auto-383"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 1 = ((mm-a  * mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-384"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 1 = ( (mm-s/a * mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-385"
  --assert 1 = ( ((ident 1) * (ident 1)) - ((ident 1) - (ident 1)) )
  --test-- "maths-auto-386"
  --assert 4 = ( (2 * 2) - (2 - 2) )
  --test-- "maths-auto-387"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 4 = ((mm-a  * mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-388"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 4 = ( (mm-s/a * mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-389"
  --assert 4 = ( ((ident 2) * (ident 2)) - ((ident 2) - (ident 2)) )
  --test-- "maths-auto-390"
  --assert 65536 = ( (256 * 256) - (256 - 256) )
  --test-- "maths-auto-391"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 65536 = ((mm-a  * mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-392"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 65536 = ( (mm-s/a * mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-393"
  --assert 65536 = ( ((ident 256) * (ident 256)) - ((ident 256) - (ident 256)) )
  --test-- "maths-auto-394"
  --assert 66049 = ( (257 * 257) - (257 - 257) )
  --test-- "maths-auto-395"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 66049 = ((mm-a  * mm-b) - (mm-c - mm-d) )
  --test-- "maths-auto-396"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 66049 = ( (mm-s/a * mm-s/b) - (mm-s/c - mm-s/d) )
  --test-- "maths-auto-397"
  --assert 66049 = ( ((ident 257) * (ident 257)) - ((ident 257) - (ident 257)) )
  --test-- "maths-auto-398"
  --assert 1 =(as integer! ((#"^(FF)" * 256) - (257 - 258) ))
  --test-- "maths-auto-399"
  --assert 13 =(as integer! ((#"^(FC)" * #"^(FD)") - (#"^(FE)" - #"^(FF)") ))
  --test-- "maths-auto-400"
  --assert 0 = ( (1 - 1) * (1 - 1) )
  --test-- "maths-auto-401"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 0 = ((mm-a  - mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-402"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-403"
  --assert 0 = ( ((ident 1) - (ident 1)) * ((ident 1) - (ident 1)) )
  --test-- "maths-auto-404"
  --assert 0 = ( (2 - 2) * (2 - 2) )
  --test-- "maths-auto-405"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 0 = ((mm-a  - mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-406"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-407"
  --assert 0 = ( ((ident 2) - (ident 2)) * ((ident 2) - (ident 2)) )
  --test-- "maths-auto-408"
  --assert 0 = ( (256 - 256) * (256 - 256) )
  --test-- "maths-auto-409"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 0 = ((mm-a  - mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-410"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-411"
  --assert 0 = ( ((ident 256) - (ident 256)) * ((ident 256) - (ident 256)) )
  --test-- "maths-auto-412"
  --assert 0 = ( (257 - 257) * (257 - 257) )
  --test-- "maths-auto-413"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 0 = ((mm-a  - mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-414"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-415"
  --assert 0 = ( ((ident 257) - (ident 257)) * ((ident 257) - (ident 257)) )
  --test-- "maths-auto-416"
  --assert 1 =(as integer! ((#"^(FF)" - 256) * (257 - 258) ))
  --test-- "maths-auto-417"
  --assert 1 =(as integer! ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)") ))
  --test-- "maths-auto-418"
  --assert -1 = ( (1 - 1) - (1 * 1) )
  --test-- "maths-auto-419"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert -1 = ((mm-a  - mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-420"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert -1 = ( (mm-s/a - mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-421"
  --assert -1 = ( ((ident 1) - (ident 1)) - ((ident 1) * (ident 1)) )
  --test-- "maths-auto-422"
  --assert -4 = ( (2 - 2) - (2 * 2) )
  --test-- "maths-auto-423"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert -4 = ((mm-a  - mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-424"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert -4 = ( (mm-s/a - mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-425"
  --assert -4 = ( ((ident 2) - (ident 2)) - ((ident 2) * (ident 2)) )
  --test-- "maths-auto-426"
  --assert -65536 = ( (256 - 256) - (256 * 256) )
  --test-- "maths-auto-427"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert -65536 = ((mm-a  - mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-428"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert -65536 = ( (mm-s/a - mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-429"
  --assert -65536 = ( ((ident 256) - (ident 256)) - ((ident 256) * (ident 256)) )
  --test-- "maths-auto-430"
  --assert -66049 = ( (257 - 257) - (257 * 257) )
  --test-- "maths-auto-431"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert -66049 = ((mm-a  - mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-432"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert -66049 = ( (mm-s/a - mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-433"
  --assert -66049 = ( ((ident 257) - (ident 257)) - ((ident 257) * (ident 257)) )
  --test-- "maths-auto-434"
  --assert 253 =(as integer! ((#"^(FF)" - 256) - (257 * 258) ))
  --test-- "maths-auto-435"
  --assert 253 =(as integer! ((#"^(FC)" - #"^(FD)") - (#"^(FE)" * #"^(FF)") ))
  --test-- "maths-auto-436"
  --assert 0 = ( (1 * 1) * (1 - 1) )
  --test-- "maths-auto-437"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 0 = ((mm-a  * mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-438"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 0 = ( (mm-s/a * mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-439"
  --assert 0 = ( ((ident 1) * (ident 1)) * ((ident 1) - (ident 1)) )
  --test-- "maths-auto-440"
  --assert 0 = ( (2 * 2) * (2 - 2) )
  --test-- "maths-auto-441"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 0 = ((mm-a  * mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-442"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 0 = ( (mm-s/a * mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-443"
  --assert 0 = ( ((ident 2) * (ident 2)) * ((ident 2) - (ident 2)) )
  --test-- "maths-auto-444"
  --assert 0 = ( (256 * 256) * (256 - 256) )
  --test-- "maths-auto-445"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 0 = ((mm-a  * mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-446"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 0 = ( (mm-s/a * mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-447"
  --assert 0 = ( ((ident 256) * (ident 256)) * ((ident 256) - (ident 256)) )
  --test-- "maths-auto-448"
  --assert 0 = ( (257 * 257) * (257 - 257) )
  --test-- "maths-auto-449"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 0 = ((mm-a  * mm-b) * (mm-c - mm-d) )
  --test-- "maths-auto-450"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 0 = ( (mm-s/a * mm-s/b) * (mm-s/c - mm-s/d) )
  --test-- "maths-auto-451"
  --assert 0 = ( ((ident 257) * (ident 257)) * ((ident 257) - (ident 257)) )
  --test-- "maths-auto-452"
  --assert 0 =(as integer! ((#"^(FF)" * 256) * (257 - 258) ))
  --test-- "maths-auto-453"
  --assert 244 =(as integer! ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)") ))
  --test-- "maths-auto-454"
  --assert 0 = ( (1 - 1) * (1 * 1) )
  --test-- "maths-auto-455"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 0 = ((mm-a  - mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-456"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-457"
  --assert 0 = ( ((ident 1) - (ident 1)) * ((ident 1) * (ident 1)) )
  --test-- "maths-auto-458"
  --assert 0 = ( (2 - 2) * (2 * 2) )
  --test-- "maths-auto-459"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 0 = ((mm-a  - mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-460"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-461"
  --assert 0 = ( ((ident 2) - (ident 2)) * ((ident 2) * (ident 2)) )
  --test-- "maths-auto-462"
  --assert 0 = ( (256 - 256) * (256 * 256) )
  --test-- "maths-auto-463"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 0 = ((mm-a  - mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-464"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-465"
  --assert 0 = ( ((ident 256) - (ident 256)) * ((ident 256) * (ident 256)) )
  --test-- "maths-auto-466"
  --assert 0 = ( (257 - 257) * (257 * 257) )
  --test-- "maths-auto-467"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 0 = ((mm-a  - mm-b) * (mm-c * mm-d) )
  --test-- "maths-auto-468"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 0 = ( (mm-s/a - mm-s/b) * (mm-s/c * mm-s/d) )
  --test-- "maths-auto-469"
  --assert 0 = ( ((ident 257) - (ident 257)) * ((ident 257) * (ident 257)) )
  --test-- "maths-auto-470"
  --assert 254 =(as integer! ((#"^(FF)" - 256) * (257 * 258) ))
  --test-- "maths-auto-471"
  --assert 254 =(as integer! ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)") ))
  --test-- "maths-auto-472"
  --assert 0 = ( (1 * 1) - (1 * 1) )
  --test-- "maths-auto-473"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 0 = ((mm-a  * mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-474"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 0 = ( (mm-s/a * mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-475"
  --assert 0 = ( ((ident 1) * (ident 1)) - ((ident 1) * (ident 1)) )
  --test-- "maths-auto-476"
  --assert 0 = ( (2 * 2) - (2 * 2) )
  --test-- "maths-auto-477"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 0 = ((mm-a  * mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-478"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 0 = ( (mm-s/a * mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-479"
  --assert 0 = ( ((ident 2) * (ident 2)) - ((ident 2) * (ident 2)) )
  --test-- "maths-auto-480"
  --assert 0 = ( (256 * 256) - (256 * 256) )
  --test-- "maths-auto-481"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 0 = ((mm-a  * mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-482"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 0 = ( (mm-s/a * mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-483"
  --assert 0 = ( ((ident 256) * (ident 256)) - ((ident 256) * (ident 256)) )
  --test-- "maths-auto-484"
  --assert 0 = ( (257 * 257) - (257 * 257) )
  --test-- "maths-auto-485"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 0 = ((mm-a  * mm-b) - (mm-c * mm-d) )
  --test-- "maths-auto-486"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 0 = ( (mm-s/a * mm-s/b) - (mm-s/c * mm-s/d) )
  --test-- "maths-auto-487"
  --assert 0 = ( ((ident 257) * (ident 257)) - ((ident 257) * (ident 257)) )
  --test-- "maths-auto-488"
  --assert 254 =(as integer! ((#"^(FF)" * 256) - (257 * 258) ))
  --test-- "maths-auto-489"
  --assert 10 =(as integer! ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)") ))
  --test-- "maths-auto-490"
  --assert 4 = ( 1 + 1 + 1 + 1 )
  --test-- "maths-auto-491"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
  --assert 4 = ( mm-a + mm-b + mm-c + mm-d )
  --test-- "maths-auto-492"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
  --assert 4 = ( mm-s/a + mm-s/b + mm-s/c + mm-s/d )
  --test-- "maths-auto-493"
  --assert 4 = ( (ident 1) + (ident 1) + (ident 1) + (ident 1) )
  --test-- "maths-auto-494"
  --assert 8 = ( 2 + 2 + 2 + 2 )
  --test-- "maths-auto-495"
    mm-a: 2
    mm-b: 2
    mm-c: 2
    mm-d: 2
  --assert 8 = ( mm-a + mm-b + mm-c + mm-d )
  --test-- "maths-auto-496"
    mm-s/a: 2
    mm-s/b: 2
    mm-s/c: 2
    mm-s/d: 2
  --assert 8 = ( mm-s/a + mm-s/b + mm-s/c + mm-s/d )
  --test-- "maths-auto-497"
  --assert 8 = ( (ident 2) + (ident 2) + (ident 2) + (ident 2) )
  --test-- "maths-auto-498"
  --assert 1024 = ( 256 + 256 + 256 + 256 )
  --test-- "maths-auto-499"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
  --assert 1024 = ( mm-a + mm-b + mm-c + mm-d )
  --test-- "maths-auto-500"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
  --assert 1024 = ( mm-s/a + mm-s/b + mm-s/c + mm-s/d )
  --test-- "maths-auto-501"
  --assert 1024 = ( (ident 256) + (ident 256) + (ident 256) + (ident 256) )
  --test-- "maths-auto-502"
  --assert 1028 = ( 257 + 257 + 257 + 257 )
  --test-- "maths-auto-503"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
  --assert 1028 = ( mm-a + mm-b + mm-c + mm-d )
  --test-- "maths-auto-504"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
  --assert 1028 = ( mm-s/a + mm-s/b + mm-s/c + mm-s/d )
  --test-- "maths-auto-505"
  --assert 1028 = ( (ident 257) + (ident 257) + (ident 257) + (ident 257) )
  --test-- "maths-auto-506"
  --assert 2 =(as integer! (#"^(FF)" + 256 + 257 + 258 ))
  --test-- "maths-auto-507"
  --assert 246 =(as integer! (#"^(FC)" + #"^(FD)" + #"^(FE)" + #"^(FF)" ))
  --test-- "maths-auto-508"
  --assert 0 =(as integer! (#"^(FC)" / #"^(FD)" * #"^(FE)" / #"^(FF)" ))
  --test-- "maths-auto-509"
  --assert 1 = ( ((1 * 1) * (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-510"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a * mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-511"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-512"
  --assert 1 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-513"
  --assert 72 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-514"
  --assert 40320 = ( ((1 * 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-515"
  --assert 128 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-516"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-517"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-518"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-519"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-520"
  --assert 220 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-521"
  --assert -20160 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-522"
  --assert 48 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-523"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-524"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-525"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-526"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-527"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-528"
  --assert -16800 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-529"
  --assert 112 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-530"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-531"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-532"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-533"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-534"
  --assert 48 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-535"
  --assert 856800 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-536"
  --assert 192 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-537"
  --assert 0 = ( ((1 * 1) * (1 * 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-538"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-539"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-540"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-541"
  --assert 250 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-542"
  --assert -1656 = ( ((1 * 2) * (#"^(03)" * 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-543"
  --assert 120 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-544"
  --assert 0 = ( ((1 * 1) * (1 * 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-545"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-546"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-547"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-548"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-549"
  --assert -1344 = ( ((1 * 2) * (#"^(03)" * 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-550"
  --assert 224 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-551"
  --assert 0 = ( ((1 * 1) * (1 * 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-552"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-553"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-554"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-555"
  --assert 24 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-556"
  --assert -624 = ( ((1 * 2) * (#"^(03)" * 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-557"
  --assert 160 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-558"
  --assert 0 = ( ((1 * 1) * (1 * 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-559"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-560"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-561"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-562"
  --assert 220 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-563"
  --assert -720 = ( ((1 * 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-564"
  --assert 64 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-565"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-566"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-567"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-568"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-569"
  --assert 220 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-570"
  --assert -20160 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-571"
  --assert 48 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-572"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-573"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-574"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-575"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-576"
  --assert 220 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-577"
  --assert -20160 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-578"
  --assert 48 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-579"
  --assert -1 = ( ((1 - 1) - (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-580"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-581"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-582"
  --assert -1 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-583"
  --assert 208 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-584"
  --assert -21840 = ( ((1 - 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-585"
  --assert 24 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-586"
  --assert 0 = ( ((1 - 1) * (1 - 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-587"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-588"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-589"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-590"
  --assert 232 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-591"
  --assert -428400 = ( ((1 - 2) * (#"^(03)" - 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-592"
  --assert 24 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-593"
  --assert -1 = ( ((1 - 1) * (1 * 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-594"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-595"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-596"
  --assert -1 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-597"
  --assert 241 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-598"
  --assert -1692 = ( ((1 - 2) * (#"^(03)" * 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-599"
  --assert 202 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-600"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-601"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-602"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-603"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-604"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-605"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-606"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-607"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-608"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-609"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-610"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-611"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-612"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-613"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-614"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-615"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-616"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-617"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-618"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-619"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-620"
  --assert 6 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-621"
  --assert 672 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-622"
  --assert 60 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-623"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-624"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-625"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-626"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-627"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-628"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-629"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-630"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-631"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-632"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-633"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-634"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-635"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-636"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-637"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-638"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-639"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-640"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-641"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-642"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-643"
  --assert 244 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-644"
  --assert 312 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-645"
  --assert 212 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-646"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-647"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-648"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-649"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-650"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-651"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-652"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-653"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-654"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-655"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-656"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-657"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-658"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-659"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-660"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-661"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-662"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-663"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-664"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-665"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-666"
  --assert 18 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-667"
  --assert 360 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-668"
  --assert 104 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-669"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-670"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-671"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-672"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-673"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-674"
  --assert -16800 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-675"
  --assert 112 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-676"
  --assert -1 = ( ((1 - 1) - (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-677"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-678"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-679"
  --assert -1 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-680"
  --assert 208 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-681"
  --assert -21840 = ( ((1 - 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-682"
  --assert 24 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-683"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-684"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-685"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-686"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-687"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-688"
  --assert -16800 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-689"
  --assert 112 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-690"
  --assert 1 = ( ((1 * 1) - (1 - 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-691"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-692"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-693"
  --assert 1 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-694"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-695"
  --assert -425040 = ( ((1 * 2) - (#"^(03)" - 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-696"
  --assert 88 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-697"
  --assert -1 = ( ((1 * 1) - (1 * 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-698"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a * mm-b) - (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-699"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-700"
  --assert -1 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-701"
  --assert 243 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-702"
  --assert -1690 = ( ((1 * 2) - (#"^(03)" * 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-703"
  --assert 2 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-704"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-705"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-706"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-707"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-708"
  --assert 0 = ( ((256 * 256) - (256 * 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-709"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-710"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-711"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-712"
  --assert 0 = ( ((257 * 257) - (257 * 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-713"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-714"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-715"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-716"
  --assert 0 = ( ((-256 * -256) - (-256 * -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-717"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-718"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-719"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-720"
  --assert 0 = ( ((-257 * -257) - (-257 * -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-721"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-722"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-723"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-724"
  --assert 2 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-725"
  --assert 560 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-726"
  --assert 204 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-727"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-728"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-729"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-730"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-731"
  --assert 0 = ( ((256 * 256) - (256 * 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-732"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-733"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-734"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-735"
  --assert 0 = ( ((257 * 257) - (257 * 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-736"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-737"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-738"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-739"
  --assert 0 = ( ((-256 * -256) - (-256 * -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-740"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-741"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-742"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-743"
  --assert 0 = ( ((-257 * -257) - (-257 * -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-744"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-745"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-746"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-747"
  --assert 252 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-748"
  --assert 260 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-749"
  --assert 4 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-750"
  --assert 0 = ( ((1 * 1) - (1 * 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-751"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-752"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-753"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-754"
  --assert 0 = ( ((256 * 256) - (256 * 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-755"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-756"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-757"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-758"
  --assert 0 = ( ((257 * 257) - (257 * 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-759"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-760"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-761"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-762"
  --assert 0 = ( ((-256 * -256) - (-256 * -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-763"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-764"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-765"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-766"
  --assert 0 = ( ((-257 * -257) - (-257 * -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-767"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c * mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-768"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-769"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-770"
  --assert 6 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-771"
  --assert 300 = ( ((1 * 2) - (#"^(03)" * 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-772"
  --assert 200 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-773"
  --assert -1 = ( ((1 * 1) * (1 - 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-774"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-775"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-776"
  --assert -1 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-777"
  --assert 248 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-778"
  --assert -1170 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-779"
  --assert 176 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-780"
  --assert 0 = ( ((1 - 1) * (1 - 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-781"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-782"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-783"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-784"
  --assert 0 = ( ((256 - 256) * (256 - 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-785"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-786"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-787"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-788"
  --assert 0 = ( ((257 - 257) * (257 - 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-789"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-790"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-791"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-792"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-793"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-794"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-795"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-796"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-797"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-798"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-799"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-800"
  --assert 4 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-801"
  --assert 14280 = ( ((1 - 2) * (#"^(03)" - 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-802"
  --assert 254 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-803"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-804"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-805"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-806"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-807"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-808"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-809"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-810"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-811"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-812"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-813"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-814"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-815"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-816"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-817"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-818"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-819"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-820"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-821"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-822"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-823"
  --assert 16 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-824"
  --assert -13260 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-825"
  --assert 208 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-826"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-827"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-828"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-829"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-830"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-831"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-832"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-833"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-834"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-835"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-836"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-837"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-838"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-839"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-840"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-841"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-842"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-843"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-844"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-845"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-846"
  --assert 232 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-847"
  --assert -15300 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-848"
  --assert 160 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-849"
  --assert -1 = ( ((1 * 1) * (1 - 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-850"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-851"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-852"
  --assert -1 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-853"
  --assert 248 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-854"
  --assert -1170 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-855"
  --assert 176 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-856"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-857"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-858"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-859"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-860"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-861"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-862"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-863"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-864"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-865"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-866"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-867"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-868"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-869"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-870"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-871"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-872"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-873"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-874"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-875"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-876"
  --assert 248 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-877"
  --assert -28560 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-878"
  --assert 112 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-879"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-880"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-881"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-882"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-883"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-884"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-885"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-886"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-887"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-888"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-889"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-890"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-891"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-892"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-893"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-894"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-895"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-896"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-897"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-898"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-899"
  --assert 16 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-900"
  --assert -13260 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-901"
  --assert 208 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-902"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-903"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-904"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-905"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-906"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-907"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-908"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-909"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-910"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-911"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-912"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-913"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-914"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-915"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-916"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-917"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-918"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-919"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-920"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-921"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-922"
  --assert 232 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-923"
  --assert -15300 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-924"
  --assert 160 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-925"
  --assert 0 = ( ((1 - 1) - (1 - 1)) * ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-926"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-927"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-928"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-929"
  --assert 220 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-930"
  --assert -430080 = ( ((1 - 2) - (#"^(03)" - 4)) * ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-931"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-932"
  --assert -2 = ( ((1 - 1) - (1 * 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-933"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -2 = ( ((mm-a - mm-b) - (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-934"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -2 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-935"
  --assert -2 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-936"
  --assert 240 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-937"
  --assert -1693 = ( ((1 - 2) - (#"^(03)" * 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-938"
  --assert 201 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-939"
  --assert 0 = ( ((1 - 1) - (1 * 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-940"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-941"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-942"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-943"
  --assert 0 = ( ((256 - 256) - (256 * 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-944"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-945"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-946"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-947"
  --assert 0 = ( ((257 - 257) - (257 * 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-948"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-949"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-950"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-951"
  --assert 0 = ( ((-256 - -256) - (-256 * -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-952"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-953"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-954"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-955"
  --assert 0 = ( ((-257 - -257) - (-257 * -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-956"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-957"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-958"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-959"
  --assert 8 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-960"
  --assert 728 = ( ((1 - 2) - (#"^(03)" * 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-961"
  --assert 62 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-962"
  --assert 0 = ( ((1 - 1) - (1 - 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-963"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-964"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-965"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-966"
  --assert 0 = ( ((256 - 256) - (256 - 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-967"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-968"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-969"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-970"
  --assert 0 = ( ((257 - 257) - (257 - 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-971"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-972"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-973"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-974"
  --assert 0 = ( ((-256 - -256) - (-256 - -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-975"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-976"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-977"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-978"
  --assert 0 = ( ((-257 - -257) - (-257 - -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-979"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-980"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-981"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-982"
  --assert 244 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-983"
  --assert 6656 = ( ((1 - 2) - (#"^(03)" - 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-984"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-985"
  --assert 0 = ( ((1 - 1) * (1 - 1)) - ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-986"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-987"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-988"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-989"
  --assert 0 = ( ((256 - 256) * (256 - 256)) - ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-990"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-991"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-992"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-993"
  --assert 0 = ( ((257 - 257) * (257 - 257)) - ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-994"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-995"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-996"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-997"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) - ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-998"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-999"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1000"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1001"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) - ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1002"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1003"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1004"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1005"
  --assert 4 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1006"
  --assert -225 = ( ((1 - 2) * (#"^(03)" - 4)) - ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1007"
  --assert 13 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1008"
  --assert 0 = ( ((1 - 1) * (1 * 1)) - ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1009"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1010"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1011"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1012"
  --assert 0 = ( ((256 - 256) * (256 * 256)) - ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1013"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1014"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1015"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) - (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1016"
  --assert 0 = ( ((257 - 257) * (257 * 257)) - ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1017"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1018"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1019"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) - (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1020"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) - ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1021"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1022"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1023"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) - (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1024"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) - ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1025"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1026"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1027"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) - (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1028"
  --assert 255 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1029"
  --assert 44 = ( ((1 - 2) * (#"^(03)" * 4)) - ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1030"
  --assert 228 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1031"
  --assert 0 = ( ((1 - 1) * (1 * 1)) - ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-1032"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1033"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1034"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1035"
  --assert 0 = ( ((256 - 256) * (256 * 256)) - ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-1036"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1037"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1038"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) - (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1039"
  --assert 0 = ( ((257 - 257) * (257 * 257)) - ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-1040"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1041"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1042"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) - (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1043"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) - ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-1044"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1045"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1046"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) - (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1047"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) - ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-1048"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1049"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1050"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) - (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1051"
  --assert 249 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1052"
  --assert 14 = ( ((1 - 2) * (#"^(03)" * 4)) - ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-1053"
  --assert 216 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1054"
  --assert 0 = ( ((1 - 1) * (1 * 1)) - ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-1055"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1056"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1057"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1058"
  --assert 0 = ( ((256 - 256) * (256 * 256)) - ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-1059"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1060"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1061"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) - (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1062"
  --assert 0 = ( ((257 - 257) * (257 * 257)) - ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-1063"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1064"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1065"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) - (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1066"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) - ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-1067"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1068"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1069"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) - (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1070"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) - ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1071"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1072"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1073"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) - (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1074"
  --assert 3 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1075"
  --assert 18 = ( ((1 - 2) * (#"^(03)" * 4)) - ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1076"
  --assert 238 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1077"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 - 1) - (1 * 1)) )
  --test-- "maths-auto-1078"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1079"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1080"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1081"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 - 256) - (256 * 256)) )
  --test-- "maths-auto-1082"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1083"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1084"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1085"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 - 257) - (257 * 257)) )
  --test-- "maths-auto-1086"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1087"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1088"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1089"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 - -256) - (-256 * -256)) )
  --test-- "maths-auto-1090"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1091"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1092"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1093"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 - -257) - (-257 * -257)) )
  --test-- "maths-auto-1094"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1095"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1096"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1097"
  --assert 9 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1098"
  --assert 684 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 - 6) - (7 * 8)) )
  --test-- "maths-auto-1099"
  --assert 90 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1100"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 - 1) * (1 - 1)) )
  --test-- "maths-auto-1101"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1102"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1103"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1104"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 - 256) * (256 - 256)) )
  --test-- "maths-auto-1105"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1106"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1107"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1108"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 - 257) * (257 - 257)) )
  --test-- "maths-auto-1109"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1110"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1111"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1112"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 - -256) * (-256 - -256)) )
  --test-- "maths-auto-1113"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1114"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1115"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1116"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 - -257) * (-257 - -257)) )
  --test-- "maths-auto-1117"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1118"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1119"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1120"
  --assert 253 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1121"
  --assert -12 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 - 6) * (7 - 8)) )
  --test-- "maths-auto-1122"
  --assert 226 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1123"
  --assert 0 = ( ((1 - 1) * (1 * 1)) * ((1 * 1) - (1 - 1)) )
  --test-- "maths-auto-1124"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1125"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1126"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1127"
  --assert 0 = ( ((256 - 256) * (256 * 256)) * ((256 * 256) - (256 - 256)) )
  --test-- "maths-auto-1128"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1129"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1130"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1131"
  --assert 0 = ( ((257 - 257) * (257 * 257)) * ((257 * 257) - (257 - 257)) )
  --test-- "maths-auto-1132"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1133"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1134"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1135"
  --assert 0 = ( ((-256 - -256) * (-256 * -256)) * ((-256 * -256) - (-256 - -256)) )
  --test-- "maths-auto-1136"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1137"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1138"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1139"
  --assert 0 = ( ((-257 - -257) * (-257 * -257)) * ((-257 * -257) - (-257 - -257)) )
  --test-- "maths-auto-1140"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c * mm-d)) * ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1141"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1142"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1143"
  --assert 235 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1144"
  --assert -372 = ( ((1 - 2) * (#"^(03)" * 4)) * ((5 * 6) - (7 - 8)) )
  --test-- "maths-auto-1145"
  --assert 122 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1146"
  --assert 0 = ( ((1 * 1) - (1 - 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-1147"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1148"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1149"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1150"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1151"
  --assert -1933 = ( ((1 * 2) - (#"^(03)" - 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-1152"
  --assert 33 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1153"
  --assert 0 = ( ((1 * 1) - (1 - 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1154"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1155"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1156"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1157"
  --assert 0 = ( ((256 * 256) - (256 - 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1158"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1159"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1160"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1161"
  --assert 0 = ( ((257 * 257) - (257 - 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1162"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1163"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1164"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1165"
  --assert 0 = ( ((-256 * -256) - (-256 - -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1166"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1167"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1168"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1169"
  --assert 0 = ( ((-257 * -257) - (-257 - -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1170"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1171"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1172"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1173"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1174"
  --assert 14168 = ( ((1 * 2) - (#"^(03)" - 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1175"
  --assert 142 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1176"
  --assert 0 = ( ((1 * 1) - (1 - 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-1177"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1178"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1179"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1180"
  --assert 0 = ( ((256 * 256) - (256 - 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-1181"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1182"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1183"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1184"
  --assert 0 = ( ((257 * 257) - (257 - 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-1185"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1186"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1187"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1188"
  --assert 0 = ( ((-256 * -256) - (-256 - -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-1189"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1190"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1191"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1192"
  --assert 0 = ( ((-257 * -257) - (-257 - -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-1193"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1194"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1195"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1196"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1197"
  --assert 6578 = ( ((1 * 2) - (#"^(03)" - 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-1198"
  --assert 58 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1199"
  --assert 0 = ( ((1 * 1) - (1 - 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-1200"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1201"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1202"
  --assert 0 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1203"
  --assert 0 = ( ((256 * 256) - (256 - 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-1204"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1205"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1206"
  --assert 0 = ( (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1207"
  --assert 0 = ( ((257 * 257) - (257 - 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-1208"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1209"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1210"
  --assert 0 = ( (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1211"
  --assert 0 = ( ((-256 * -256) - (-256 - -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-1212"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1213"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1214"
  --assert 0 = ( (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1215"
  --assert 0 = ( ((-257 * -257) - (-257 - -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1216"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1217"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1218"
  --assert 0 = ( (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1219"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1220"
  --assert 7590 = ( ((1 * 2) - (#"^(03)" - 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1221"
  --assert 84 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1222"
  --assert 0 = ( ((1 * 1) * (1 - 1)) - ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1223"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1224"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1225"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1226"
  --assert 0 = ( ((256 * 256) * (256 - 256)) - ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1227"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1228"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1229"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1230"
  --assert 0 = ( ((257 * 257) * (257 - 257)) - ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1231"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1232"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1233"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1234"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) - ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1235"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1236"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1237"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1238"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) - ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1239"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1240"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1241"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1242"
  --assert 6 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1243"
  --assert 566 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1244"
  --assert 202 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1245"
  --assert 0 = ( ((1 * 1) * (1 - 1)) - ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-1246"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1247"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1248"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1249"
  --assert 0 = ( ((256 * 256) * (256 - 256)) - ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-1250"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1251"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1252"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1253"
  --assert 0 = ( ((257 * 257) * (257 - 257)) - ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-1254"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1255"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1256"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1257"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) - ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-1258"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1259"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1260"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1261"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) - ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-1262"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1263"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1264"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1265"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1266"
  --assert 536 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-1267"
  --assert 190 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1268"
  --assert 0 = ( ((1 * 1) * (1 - 1)) - ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-1269"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1270"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1271"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1272"
  --assert 0 = ( ((256 * 256) * (256 - 256)) - ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-1273"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1274"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1275"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1276"
  --assert 0 = ( ((257 * 257) * (257 - 257)) - ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-1277"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1278"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1279"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1280"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) - ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-1281"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1282"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1283"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1284"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) - ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1285"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1286"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1287"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1288"
  --assert 10 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1289"
  --assert 540 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1290"
  --assert 212 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1291"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 - 1) - (1 * 1)) )
  --test-- "maths-auto-1292"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1293"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1294"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1295"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 - 256) - (256 * 256)) )
  --test-- "maths-auto-1296"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1297"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1298"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1299"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 - 257) - (257 * 257)) )
  --test-- "maths-auto-1300"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1301"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1302"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1303"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 - -256) - (-256 * -256)) )
  --test-- "maths-auto-1304"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1305"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1306"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1307"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 - -257) - (-257 * -257)) )
  --test-- "maths-auto-1308"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1309"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1310"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1311"
  --assert 244 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1312"
  --assert -29070 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 - 6) - (7 * 8)) )
  --test-- "maths-auto-1313"
  --assert 168 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1314"
  --assert 0 = ( ((1 * 1) * (1 - 1)) * ((1 - 1) * (1 - 1)) )
  --test-- "maths-auto-1315"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1316"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1317"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1318"
  --assert 0 = ( ((256 * 256) * (256 - 256)) * ((256 - 256) * (256 - 256)) )
  --test-- "maths-auto-1319"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1320"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1321"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1322"
  --assert 0 = ( ((257 * 257) * (257 - 257)) * ((257 - 257) * (257 - 257)) )
  --test-- "maths-auto-1323"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1324"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1325"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1326"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) * ((-256 - -256) * (-256 - -256)) )
  --test-- "maths-auto-1327"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1328"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1329"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1330"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) * ((-257 - -257) * (-257 - -257)) )
  --test-- "maths-auto-1331"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1332"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1333"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1334"
  --assert 4 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1335"
  --assert 510 = ( ((1 * 2) * (#"^(03)" - 4)) * ((5 - 6) * (7 - 8)) )
  --test-- "maths-auto-1336"
  --assert 200 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1337"
  --assert 2 = ( ((1 * 1) * (1 * 1)) - ((1 - 1) - (1 * 1)) )
  --test-- "maths-auto-1338"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 2 = ( ((mm-a * mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1339"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 2 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1340"
  --assert 2 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1341"
  --assert 9 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" - #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1342"
  --assert 81 = ( ((1 * 2) * (#"^(03)" * 4)) - ((5 - 6) - (7 * 8)) )
  --test-- "maths-auto-1343"
  --assert 147 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" - #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1344"
  --assert 1 = ( ((1 * 1) * (1 * 1)) - ((1 - 1) * (1 - 1)) )
  --test-- "maths-auto-1345"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a * mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1346"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1347"
  --assert 1 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1348"
  --assert 5 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1349"
  --assert 23 = ( ((1 * 2) * (#"^(03)" * 4)) - ((5 - 6) * (7 - 8)) )
  --test-- "maths-auto-1350"
  --assert 143 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1351"
  --assert 0 = ( ((1 * 1) * (1 * 1)) - ((1 * 1) - (1 - 1)) )
  --test-- "maths-auto-1352"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1353"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1354"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1355"
  --assert 255 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" * #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1356"
  --assert -7 = ( ((1 * 2) * (#"^(03)" * 4)) - ((5 * 6) - (7 - 8)) )
  --test-- "maths-auto-1357"
  --assert 131 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" * #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1358"
  --assert 0 = ( ((1 * 1) * (1 * 1)) * ((1 - 1) - (1 - 1)) )
  --test-- "maths-auto-1359"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1360"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1361"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1362"
  --assert 0 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1363"
  --assert 0 = ( ((1 * 2) * (#"^(03)" * 4)) * ((5 - 6) - (7 - 8)) )
  --test-- "maths-auto-1364"
  --assert 0 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1365"
  --assert 0 = ( ((1 - 1) * (1 - 1)) - ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1366"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1367"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1368"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1369"
  --assert 0 = ( ((256 - 256) * (256 - 256)) - ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1370"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1371"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1372"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1373"
  --assert 0 = ( ((257 - 257) * (257 - 257)) - ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1374"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1375"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1376"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1377"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) - ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1378"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1379"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1380"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1381"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) - ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1382"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1383"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1384"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1385"
  --assert 0 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1386"
  --assert -199 = ( ((1 - 2) * (#"^(03)" - 4)) - ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1387"
  --assert 3 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1388"
  --assert 0 = ( ((1 - 1) * (1 - 1)) - ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-1389"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1390"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1391"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1392"
  --assert 0 = ( ((256 - 256) * (256 - 256)) - ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-1393"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1394"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1395"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1396"
  --assert 0 = ( ((257 - 257) * (257 - 257)) - ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-1397"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1398"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1399"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1400"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) - ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-1401"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1402"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1403"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1404"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) - ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-1405"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1406"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1407"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1408"
  --assert 250 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1409"
  --assert -229 = ( ((1 - 2) * (#"^(03)" - 4)) - ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-1410"
  --assert 247 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1411"
  --assert 0 = ( ((1 - 1) * (1 - 1)) - ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-1412"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1413"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1414"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1415"
  --assert 0 = ( ((256 - 256) * (256 - 256)) - ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-1416"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1417"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1418"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1419"
  --assert 0 = ( ((257 - 257) * (257 - 257)) - ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-1420"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1421"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1422"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1423"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) - ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-1424"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1425"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1426"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1427"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) - ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1428"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1429"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1430"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1431"
  --assert 4 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1432"
  --assert -225 = ( ((1 - 2) * (#"^(03)" - 4)) - ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1433"
  --assert 13 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1434"
  --assert -1 = ( ((1 - 1) - (1 - 1)) - ((1 * 1) * (1 * 1)) )
  --test-- "maths-auto-1435"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e * mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1436"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1437"
  --assert -1 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1438"
  --assert 241 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1439"
  --assert -1936 = ( ((1 - 2) - (#"^(03)" - 4)) - ((5 * 6) * (7 * 8)) )
  --test-- "maths-auto-1440"
  --assert 232 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1441"
  --assert 0 = ( ((1 - 1) - (1 - 1)) * ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1442"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1443"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1444"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1445"
  --assert 0 = ( ((256 - 256) - (256 - 256)) * ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1446"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1447"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1448"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1449"
  --assert 0 = ( ((257 - 257) - (257 - 257)) * ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1450"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1451"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1452"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1453"
  --assert 0 = ( ((-256 - -256) - (-256 - -256)) * ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1454"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1455"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1456"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1457"
  --assert 0 = ( ((-257 - -257) - (-257 - -257)) * ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1458"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1459"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1460"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1461"
  --assert 6 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1462"
  --assert 14336 = ( ((1 - 2) - (#"^(03)" - 4)) * ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1463"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1464"
  --assert 0 = ( ((1 - 1) - (1 - 1)) * ((1 * 1) - (1 * 1)) )
  --test-- "maths-auto-1465"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1466"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1467"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1468"
  --assert 0 = ( ((256 - 256) - (256 - 256)) * ((256 * 256) - (256 * 256)) )
  --test-- "maths-auto-1469"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1470"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1471"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) - ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1472"
  --assert 0 = ( ((257 - 257) - (257 - 257)) * ((257 * 257) - (257 * 257)) )
  --test-- "maths-auto-1473"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1474"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1475"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) - ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1476"
  --assert 0 = ( ((-256 - -256) - (-256 - -256)) * ((-256 * -256) - (-256 * -256)) )
  --test-- "maths-auto-1477"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1478"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1479"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) - ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1480"
  --assert 0 = ( ((-257 - -257) - (-257 - -257)) * ((-257 * -257) - (-257 * -257)) )
  --test-- "maths-auto-1481"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1482"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1483"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) - ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1484"
  --assert 244 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1485"
  --assert 6656 = ( ((1 - 2) - (#"^(03)" - 4)) * ((5 * 6) - (7 * 8)) )
  --test-- "maths-auto-1486"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1487"
  --assert 0 = ( ((1 - 1) - (1 - 1)) * ((1 * 1) * (1 - 1)) )
  --test-- "maths-auto-1488"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1489"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1490"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) * (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1491"
  --assert 0 = ( ((256 - 256) - (256 - 256)) * ((256 * 256) * (256 - 256)) )
  --test-- "maths-auto-1492"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1493"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1494"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) * (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1495"
  --assert 0 = ( ((257 - 257) - (257 - 257)) * ((257 * 257) * (257 - 257)) )
  --test-- "maths-auto-1496"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1497"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1498"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) * (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1499"
  --assert 0 = ( ((-256 - -256) - (-256 - -256)) * ((-256 * -256) * (-256 - -256)) )
  --test-- "maths-auto-1500"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1501"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1502"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) * (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1503"
  --assert 0 = ( ((-257 - -257) - (-257 - -257)) * ((-257 * -257) * (-257 - -257)) )
  --test-- "maths-auto-1504"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) * ((mm-e * mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1505"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) * ((mm-s/e * mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1506"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) * (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1507"
  --assert 18 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) * ((#"^(02)" * #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1508"
  --assert 7680 = ( ((1 - 2) - (#"^(03)" - 4)) * ((5 * 6) * (7 - 8)) )
  --test-- "maths-auto-1509"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) * ((#"^(FC)" * #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1510"
  --assert 1 = ( ((1 - 1) - (1 * 1)) * ((1 - 1) - (1 * 1)) )
  --test-- "maths-auto-1511"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) - (mm-g * mm-h)) )
  --test-- "maths-auto-1512"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) - (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1513"
  --assert 1 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1514"
  --assert 12 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") - (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1515"
  --assert 741 = ( ((1 - 2) - (#"^(03)" * 4)) * ((5 - 6) - (7 * 8)) )
  --test-- "maths-auto-1516"
  --assert 93 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") - (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1517"
  --assert 0 = ( ((1 - 1) - (1 * 1)) * ((1 - 1) * (1 - 1)) )
  --test-- "maths-auto-1518"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1519"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1520"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) * (ident 1))) * (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1521"
  --assert 0 = ( ((256 - 256) - (256 * 256)) * ((256 - 256) * (256 - 256)) )
  --test-- "maths-auto-1522"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1523"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1524"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) * (ident 256))) * (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1525"
  --assert 0 = ( ((257 - 257) - (257 * 257)) * ((257 - 257) * (257 - 257)) )
  --test-- "maths-auto-1526"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1527"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1528"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) * (ident 257))) * (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1529"
  --assert 0 = ( ((-256 - -256) - (-256 * -256)) * ((-256 - -256) * (-256 - -256)) )
  --test-- "maths-auto-1530"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1531"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1532"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) * (ident -256))) * (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1533"
  --assert 0 = ( ((-257 - -257) - (-257 * -257)) * ((-257 - -257) * (-257 - -257)) )
  --test-- "maths-auto-1534"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c * mm-d)) * ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1535"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c * mm-s/d)) * ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1536"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) * (ident -257))) * (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1537"
  --assert 252 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" * #"^(01)")) * ((#"^(02)" - #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1538"
  --assert -13 = ( ((1 - 2) - (#"^(03)" * 4)) * ((5 - 6) * (7 - 8)) )
  --test-- "maths-auto-1539"
  --assert 225 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" * #"^(FB)")) * ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1540"
  --assert 1 = ( ((1 * 1) - (1 - 1)) - ((1 - 1) * (1 * 1)) )
  --test-- "maths-auto-1541"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1542"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1543"
  --assert 1 = ( (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) * (ident 1))) )
  --test-- "maths-auto-1544"
  --assert 65536 = ( ((256 * 256) - (256 - 256)) - ((256 - 256) * (256 * 256)) )
  --test-- "maths-auto-1545"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 65536 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1546"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 65536 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1547"
  --assert 65536 = ( (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) * ((ident 256) * (ident 256))) )
  --test-- "maths-auto-1548"
  --assert 66049 = ( ((257 * 257) - (257 - 257)) - ((257 - 257) * (257 * 257)) )
  --test-- "maths-auto-1549"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 66049 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1550"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 66049 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1551"
  --assert 66049 = ( (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) * ((ident 257) * (ident 257))) )
  --test-- "maths-auto-1552"
  --assert 65536 = ( ((-256 * -256) - (-256 - -256)) - ((-256 - -256) * (-256 * -256)) )
  --test-- "maths-auto-1553"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 65536 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1554"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 65536 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1555"
  --assert 65536 = ( (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) * ((ident -256) * (ident -256))) )
  --test-- "maths-auto-1556"
  --assert 66049 = ( ((-257 * -257) - (-257 - -257)) - ((-257 - -257) * (-257 * -257)) )
  --test-- "maths-auto-1557"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 66049 = ( ((mm-a * mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g * mm-h)) )
  --test-- "maths-auto-1558"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 66049 = ( ((mm-s/a * mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g * mm-s/h)) )
  --test-- "maths-auto-1559"
  --assert 66049 = ( (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) * ((ident -257) * (ident -257))) )
  --test-- "maths-auto-1560"
  --assert 2 =(as integer! (((#"^(01)" * #"^(02)") - (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" * #"^(02)")) ))
  --test-- "maths-auto-1561"
  --assert -197 = ( ((1 * 2) - (#"^(03)" - 4)) - ((5 - 6) * (7 * 8)) )
  --test-- "maths-auto-1562"
  --assert 59 =(as integer! (((#"^(F8)" * #"^(F9)") - (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" * #"^(FF)")) ))
  --test-- "maths-auto-1563"
  --assert -1 = ( ((1 * 1) * (1 - 1)) - ((1 * 1) - (1 - 1)) )
  --test-- "maths-auto-1564"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert -1 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1565"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert -1 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1566"
  --assert -1 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) * (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1567"
  --assert -65536 = ( ((256 * 256) * (256 - 256)) - ((256 * 256) - (256 - 256)) )
  --test-- "maths-auto-1568"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert -65536 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1569"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert -65536 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1570"
  --assert -65536 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) * (ident 256)) - ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1571"
  --assert -66049 = ( ((257 * 257) * (257 - 257)) - ((257 * 257) - (257 - 257)) )
  --test-- "maths-auto-1572"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert -66049 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1573"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert -66049 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1574"
  --assert -66049 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) * (ident 257)) - ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1575"
  --assert -65536 = ( ((-256 * -256) * (-256 - -256)) - ((-256 * -256) - (-256 - -256)) )
  --test-- "maths-auto-1576"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert -65536 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1577"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert -65536 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1578"
  --assert -65536 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) * (ident -256)) - ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1579"
  --assert -66049 = ( ((-257 * -257) * (-257 - -257)) - ((-257 * -257) - (-257 - -257)) )
  --test-- "maths-auto-1580"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert -66049 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e * mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1581"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert -66049 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e * mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1582"
  --assert -66049 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) * (ident -257)) - ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1583"
  --assert 253 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" * #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1584"
  --assert 479 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 * 6) - (7 - 8)) )
  --test-- "maths-auto-1585"
  --assert 187 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" * #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1586"
  --assert 0 = ( ((1 * 1) * (1 - 1)) - ((1 - 1) - (1 - 1)) )
  --test-- "maths-auto-1587"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1588"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1589"
  --assert 0 = ( (((ident 1) * (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1590"
  --assert 0 = ( ((256 * 256) * (256 - 256)) - ((256 - 256) - (256 - 256)) )
  --test-- "maths-auto-1591"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1592"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1593"
  --assert 0 = ( (((ident 256) * (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1594"
  --assert 0 = ( ((257 * 257) * (257 - 257)) - ((257 - 257) - (257 - 257)) )
  --test-- "maths-auto-1595"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1596"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1597"
  --assert 0 = ( (((ident 257) * (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1598"
  --assert 0 = ( ((-256 * -256) * (-256 - -256)) - ((-256 - -256) - (-256 - -256)) )
  --test-- "maths-auto-1599"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1600"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1601"
  --assert 0 = ( (((ident -256) * (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1602"
  --assert 0 = ( ((-257 * -257) * (-257 - -257)) - ((-257 - -257) - (-257 - -257)) )
  --test-- "maths-auto-1603"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a * mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1604"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a * mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1605"
  --assert 0 = ( (((ident -257) * (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1606"
  --assert 4 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1607"
  --assert 510 = ( ((1 * 2) * (#"^(03)" - 4)) - ((5 - 6) - (7 - 8)) )
  --test-- "maths-auto-1608"
  --assert 200 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1609"
  --assert 1 = ( ((1 * 1) * (1 * 1)) - ((1 - 1) - (1 - 1)) )
  --test-- "maths-auto-1610"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 1 = ( ((mm-a * mm-b) * (mm-c * mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1611"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 1 = ( ((mm-s/a * mm-s/b) * (mm-s/c * mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1612"
  --assert 1 = ( (((ident 1) * (ident 1)) * ((ident 1) * (ident 1))) - (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1613"
  --assert 6 =(as integer! (((#"^(01)" * #"^(02)") * (#"^(03)" * #"^(01)")) - ((#"^(02)" - #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1614"
  --assert 24 = ( ((1 * 2) * (#"^(03)" * 4)) - ((5 - 6) - (7 - 8)) )
  --test-- "maths-auto-1615"
  --assert 144 =(as integer! (((#"^(F8)" * #"^(F9)") * (#"^(FA)" * #"^(FB)")) - ((#"^(FC)" - #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1616"
  --assert 0 = ( ((1 - 1) * (1 - 1)) - ((1 - 1) * (1 - 1)) )
  --test-- "maths-auto-1617"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1618"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1619"
  --assert 0 = ( (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) * ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1620"
  --assert 0 = ( ((256 - 256) * (256 - 256)) - ((256 - 256) * (256 - 256)) )
  --test-- "maths-auto-1621"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1622"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1623"
  --assert 0 = ( (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) * ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1624"
  --assert 0 = ( ((257 - 257) * (257 - 257)) - ((257 - 257) * (257 - 257)) )
  --test-- "maths-auto-1625"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1626"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1627"
  --assert 0 = ( (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) * ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1628"
  --assert 0 = ( ((-256 - -256) * (-256 - -256)) - ((-256 - -256) * (-256 - -256)) )
  --test-- "maths-auto-1629"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1630"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1631"
  --assert 0 = ( (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) * ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1632"
  --assert 0 = ( ((-257 - -257) * (-257 - -257)) - ((-257 - -257) * (-257 - -257)) )
  --test-- "maths-auto-1633"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) * (mm-c - mm-d)) - ((mm-e - mm-f) * (mm-g - mm-h)) )
  --test-- "maths-auto-1634"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) * (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) * (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1635"
  --assert 0 = ( (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) * ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1636"
  --assert 253 =(as integer! (((#"^(01)" - #"^(02)") * (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") * (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1637"
  --assert -256 = ( ((1 - 2) * (#"^(03)" - 4)) - ((5 - 6) * (7 - 8)) )
  --test-- "maths-auto-1638"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") * (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") * (#"^(FE)" - #"^(FF)")) ))
  --test-- "maths-auto-1639"
  --assert 0 = ( ((1 - 1) - (1 - 1)) - ((1 - 1) - (1 - 1)) )
  --test-- "maths-auto-1640"
    mm-a: 1
    mm-b: 1
    mm-c: 1
    mm-d: 1
    mm-e: 1
    mm-f: 1
    mm-g: 1
    mm-h: 1
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1641"
    mm-s/a: 1
    mm-s/b: 1
    mm-s/c: 1
    mm-s/d: 1
    mm-s/e: 1
    mm-s/f: 1
    mm-s/g: 1
    mm-s/h: 1
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1642"
  --assert 0 = ( (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) - (((ident 1) - (ident 1)) - ((ident 1) - (ident 1))) )
  --test-- "maths-auto-1643"
  --assert 0 = ( ((256 - 256) - (256 - 256)) - ((256 - 256) - (256 - 256)) )
  --test-- "maths-auto-1644"
    mm-a: 256
    mm-b: 256
    mm-c: 256
    mm-d: 256
    mm-e: 256
    mm-f: 256
    mm-g: 256
    mm-h: 256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1645"
    mm-s/a: 256
    mm-s/b: 256
    mm-s/c: 256
    mm-s/d: 256
    mm-s/e: 256
    mm-s/f: 256
    mm-s/g: 256
    mm-s/h: 256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1646"
  --assert 0 = ( (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) - (((ident 256) - (ident 256)) - ((ident 256) - (ident 256))) )
  --test-- "maths-auto-1647"
  --assert 0 = ( ((257 - 257) - (257 - 257)) - ((257 - 257) - (257 - 257)) )
  --test-- "maths-auto-1648"
    mm-a: 257
    mm-b: 257
    mm-c: 257
    mm-d: 257
    mm-e: 257
    mm-f: 257
    mm-g: 257
    mm-h: 257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1649"
    mm-s/a: 257
    mm-s/b: 257
    mm-s/c: 257
    mm-s/d: 257
    mm-s/e: 257
    mm-s/f: 257
    mm-s/g: 257
    mm-s/h: 257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1650"
  --assert 0 = ( (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) - (((ident 257) - (ident 257)) - ((ident 257) - (ident 257))) )
  --test-- "maths-auto-1651"
  --assert 0 = ( ((-256 - -256) - (-256 - -256)) - ((-256 - -256) - (-256 - -256)) )
  --test-- "maths-auto-1652"
    mm-a: -256
    mm-b: -256
    mm-c: -256
    mm-d: -256
    mm-e: -256
    mm-f: -256
    mm-g: -256
    mm-h: -256
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1653"
    mm-s/a: -256
    mm-s/b: -256
    mm-s/c: -256
    mm-s/d: -256
    mm-s/e: -256
    mm-s/f: -256
    mm-s/g: -256
    mm-s/h: -256
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1654"
  --assert 0 = ( (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) - (((ident -256) - (ident -256)) - ((ident -256) - (ident -256))) )
  --test-- "maths-auto-1655"
  --assert 0 = ( ((-257 - -257) - (-257 - -257)) - ((-257 - -257) - (-257 - -257)) )
  --test-- "maths-auto-1656"
    mm-a: -257
    mm-b: -257
    mm-c: -257
    mm-d: -257
    mm-e: -257
    mm-f: -257
    mm-g: -257
    mm-h: -257
  --assert 0 = ( ((mm-a - mm-b) - (mm-c - mm-d)) - ((mm-e - mm-f) - (mm-g - mm-h)) )
  --test-- "maths-auto-1657"
    mm-s/a: -257
    mm-s/b: -257
    mm-s/c: -257
    mm-s/d: -257
    mm-s/e: -257
    mm-s/f: -257
    mm-s/g: -257
    mm-s/h: -257
  --assert 0 = ( ((mm-s/a - mm-s/b) - (mm-s/c - mm-s/d)) - ((mm-s/e - mm-s/f) - (mm-s/g - mm-s/h)) )
  --test-- "maths-auto-1658"
  --assert 0 = ( (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) - (((ident -257) - (ident -257)) - ((ident -257) - (ident -257))) )
  --test-- "maths-auto-1659"
  --assert 253 =(as integer! (((#"^(01)" - #"^(02)") - (#"^(03)" - #"^(01)")) - ((#"^(02)" - #"^(03)") - (#"^(01)" - #"^(02)")) ))
  --test-- "maths-auto-1660"
  --assert -256 = ( ((1 - 2) - (#"^(03)" - 4)) - ((5 - 6) - (7 - 8)) )
  --test-- "maths-auto-1661"
  --assert 0 =(as integer! (((#"^(F8)" - #"^(F9)") - (#"^(FA)" - #"^(FB)")) - ((#"^(FC)" - #"^(FD)") - (#"^(FE)" - #"^(FF)")) ))

===end-group===


~~~end-file~~~
