Red/System [
	Title:   "Red/System pointer! [float!] datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %float-pointer-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "pointer! [float!]"

===start-group=== "Pointers simple read/write tests"

	--test-- "pointer-rw-1"
	p-struct: declare struct! [n [float!] m [float!]]
	pA: declare pointer! [float!]
	pB: declare pointer! [float!]

	p-struct/n: 1.23
	--assert p-struct/n = 1.23

	--test-- "pointer-rw-2"
	pA: as [pointer! [float!]] p-struct
	pA/value: 9.87
	--assert p-struct/n = 9.87
	pA/1: 9.87
	--assert p-struct/n = 9.87

	--test-- "pointer-rw-3"
	p-struct/n: 123.45
	--assert pA/value = 123.45
	--assert pA/1 = 123.45

	--test-- "pointer-rw-4"
	p-float: 456.789
	pA/2: p-float
	--assert p-struct/m = p-float
	--assert p-struct/n = 123.45		;-- look for memory corruption

	--test-- "pointer-rw-5"
	p-idx: 1
	pA/p-idx: 1.23456789
	--assert p-struct/n = 1.23456789

	--test-- "pointer-rw-6"
	p-idx: 2
	pA/p-idx: 9.63
	--assert p-struct/n = 1.234567890
	--assert p-struct/m = 9.63

	--test-- "pointer-rw-7"
	p-struct/n: 123.45
	p-int: 147.258
	p-struct/m: p-float
	--assert pA/2 = p-float
	--assert p-struct/n = 123.45		;-- look for memory corruption

	--test-- "pointer-rw-8"
	pB: pA
	--assert pB/value = 123.45

	--test-- "pointer-rw-9"
	foo-pointer: func [
		a [pointer! [float!]]
		return: [pointer! [float!]]
	][
		a
	]

	pB: foo-pointer pA 
	--assert pB/value = 123.45

	pointer-str: declare struct! [
		A [pointer! [float!]]
		B [pointer! [float!]]
		sub [
			struct! [
				C [pointer! [float!]]
			]
		]
	]
	pointer-str/sub: declare struct! [C [pointer! [float!]]]

	--test-- "pointer-rw-10"
	pointer-str/A: pA
	--assert pointer-str/A/value = 123.45

	--test-- "pointer-rw-11"
	pointer-str/A/value: 25836.9147
	--assert p-struct/n = 25836.9147
	--assert p-struct/m = p-float		;-- look for memory corruption			

	--test-- "pointer-rw-12"
	pointer-str/sub/C: pA
	--assert pointer-str/sub/C/value = 25836.9147

	--test-- "pointer-rw-13"
	pointer-str/sub/C/2: 98765.4321
	--assert p-struct/m = 98765.4321
	

===start-group=== "Pointers arithmetic"
	
	--test-- "pointer-calc-1"
	pa-struct: declare struct! [n [float!] m [float!] p [float!] o [float!]]
	pA: declare pointer! [float!]
	pB: declare pointer! [float!]
	
	pA: as [pointer! [float!]] pa-struct
	pa-struct/n: 1.23456789
	pa-struct/m: 9.87654321
	--assert pA/value = 1.23456789
	
	--test-- "pointer-calc-2"
	pA: pA + 1
	--assert pA/value = 9.87654321
	
	--test-- "pointer-calc-3"
	pa-struct/o: 1.23
	pA: pA + 2
	--assert pA/value = 1.23
	
	--test-- "pointer-calc-4"
	pA: pA - 3
	--assert pA/value = 1.23456789
	
	--test-- "pointer-calc-5"
	pointer-idx: 3
	pA: pA + pointer-idx
	--assert pA/value = 1.23
	
	--test-- "pointer-calc-6"
	pointer-idx: -3
	pA: pA + pointer-idx
	--assert pA/value = 1.23456789
	
	--test-- "pointer-calc-7"
	pA: pA - pointer-idx
	--assert pA/value = 1.23
	
	--test-- "pointer-calc-9" 
	pA: as [pointer! [float!]] pa-struct
	--assert pA/1 = 1.23456789
	--assert pA/2 = 9.87654321
	
	--test-- "pointer-calc-10" 
	pointer-idx: 1
	--assert pA/pointer-idx = 1.23456789
	
	--test-- "pointer-calc-11" 
	pointer-idx: 2
	--assert pA/pointer-idx = 9.87654321
	
	--test-- "pointer-calc-12" 
	pointer-idx: 4
	--assert pA/pointer-idx = 1.23
	
===end-group===

===start-group=== "Local pointers simple read/write tests"

pointer-local-foo: func [
	/local
		p-struct [struct! [n [float!] m [float!]]]
		pA 		 [pointer! [float!]]
		pB 		 [pointer! [float!]]
		p-float  [float!]
		p-idx    [integer!]
		pointer-str [struct! [
			A [pointer! [float!]]
			B [pointer! [float!]]
			sub [struct! [C [pointer! [float!]]]]
		]]
		pa-struct [struct! [n [float!] m [float!] p [float!] o [float!]]]
		pointer-idx [integer!]
][

	--test-- "loc-point-rw-1"
	p-struct: declare struct! [n [float!] m [float!]]
	pA: declare pointer! [float!]
	pB: declare pointer! [float!]

	p-struct/n: 1.23
	--assert p-struct/n = 1.23

	--test-- "loc-point-rw-2"
	pA: as [pointer! [float!]] p-struct
	pA/value: 9.87
	--assert p-struct/n = 9.87
	pA/1: 9.87
	--assert p-struct/n = 9.87

	--test-- "loc-point-rw-3"
	p-struct/n: 123.45
	--assert pA/value = 123.45
	--assert pA/1 = 123.45

	--test-- "loc-point-rw-4"
	p-float: 456.789
	pA/2: p-float
	--assert p-struct/m = p-float
	--assert p-struct/n = 123.45		;-- look for memory corruption

	--test-- "loc-point-rw-5"
	p-idx: 1
	pA/p-idx: 3.69
	--assert p-struct/n = 3.69

	--test-- "loc-point-rw-6"
	p-idx: 2
	pA/p-idx: 9.63
	--assert p-struct/m = 9.63

	--test-- "loc-point-rw-7"
	p-struct/n: 123.45
	p-float: 1472.58
	p-struct/m: p-float
	--assert pA/2 = p-float
	--assert p-struct/n = 123.45		;-- look for memory corruption

	--test-- "loc-point-rw-8"
	pB: pA
	--assert pB/value = 123.45

	--test-- "loc-point-rw-9"
	pB: foo-pointer pA 
	--assert pB/value = 123.45

	pointer-str: declare struct! [
		A [pointer! [float!]]
		B [pointer! [float!]]
		sub [
			struct! [
				C [pointer! [float!]]
			]
		]
	]
	pointer-str/sub: declare struct! [C [pointer! [float!]]]

	--test-- "loc-point-rw-10"
	pointer-str/A: pA
	--assert pointer-str/A/value = 123.45

	--test-- "loc-point-rw-11"
	pointer-str/A/value: 25836.9147
	--assert p-struct/n = 25836.9147
	--assert p-struct/m = p-float		;-- look for memory corruption			

	--test-- "loc-point-rw-12"
	pointer-str/sub/C: pA
	--assert pointer-str/sub/C/value = 25836.9147

	--test-- "loc-point-rw-13"
	pointer-str/sub/C/2: 98765.4321
	--assert p-struct/m = 98765.4321
	
	--test-- "loc-point-calc-1"
	pa-struct: declare struct! [n [float!] m [float!] p [float!] o [float!]]

	pA: as [pointer! [float!]] pa-struct
	pa-struct/n: 1.23456789
	pa-struct/m: 9.87654321
	--assert pA/value = 1.23456789

	--test-- "loc-point-calc-2"
	pA: pA + 1
	--assert pA/value = 9.87654321

	--test-- "loc-point-calc-3"
	pa-struct/o: 1.23
	pA: pA + 2
	--assert pA/value = 1.23

	--test-- "loc-point-calc-4"
	pA: pA - 3
	--assert pA/value = 1.23456789

	--test-- "loc-point-calc-5"
	p-idx: 3
	pA: pA + p-idx
	--assert pA/value = 1.23
	
	--test-- "loc-point-calc-6"
	p-idx: -3
	pA: pA + p-idx
	--assert pA/value = 1.23456789
	
	--test-- "loc-point-calc-7"
	pA: pA - p-idx
	--assert pA/value = 1.23
	
	--test-- "loc-point-calc-9" 
	pA: as [pointer! [float!]] pa-struct
	--assert pA/1 = 1.23456789
	--assert pA/2 = 9.87654321

	--test-- "loc-point-calc-10" 
	pointer-idx: 1
	--assert pA/pointer-idx = 1.23456789

	--test-- "loc-point-calc-11" 
	pointer-idx: 2
	--assert pA/pointer-idx = 9.87654321

	--test-- "loc-point-calc-12" 
	pointer-idx: 4
	--assert pA/pointer-idx = 1.23
]
pointer-local-foo

===end-group===

~~~end-file~~~