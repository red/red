Red/System [
	Title:   "Red/System enumerations tests"
	File:      %enum-test.reds
	Rights:  "Copyright (C) 2012-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "enumerations"

	--test-- "Enum-1"
		#enum test1! [enumA enumB]
		--assert enumA = 0
		--assert enumB = 1
		
	--test-- "Enum-2"  
		#enum test2! [enumC: 3 enumD]
		--assert enumC = 3
		--assert enumD = 4

  	--test-- "Enum-3"  
		#enum test3! [
			enumE: 11
			;empty line test
			enumF: 10
		]
		--assert enumE = 11
		--assert enumF = 10

	--test-- "Enum-4"
		p1: declare pointer! [integer!]
		p1/value: enumE
		--assert p1/value = 11

	--test-- "Enum-5"
		p2: declare struct! [a [test1!] b [integer!]]
		p2/a: enumC
		p2/b: enumC
		--assert p2/a = 3
		--assert p2/b = 3

	--test-- "Enum-6"
		p3: declare struct! [enumA [integer!]]
		p3/enumA: 3
		--assert enumA = 0
		--assert p3/enumA = 3
		
	--test-- "Enum-7"
		str: "abcd"
		--assert str/3 = #"c"
		--assert str/enumC = #"c"
		
	--test-- "Enum-8"
		fce: func[return: [integer!]][ return enumC ]
		--assert fce = 3
	
	--test-- "Enum-9"
		#enum test9! [enum9: enumC]
		--assert enum9 = 3
	
	--test-- "Enum-10"
		#enum test10! [enum10: enum11: 10 enum12]
		--assert enum10 = 10
		--assert enum11 = 10
		--assert enum12 = 11
	
	--test-- "Enum-11"
		#enum test11! [e11-a e11-b]
		e11-f: func [
			return: [integer!]
			/local
			e11-b
		][
			e11-b: 3
			e11-b
		]
		--assert 3 = e11-f
	
~~~end-file~~~
