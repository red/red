Red/System [
	Title:   "Red/System USE keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %use-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "use"
  
  --test-- "use-1"
	use1-test: func [/local a [integer!]][
		a: 42
		use [b [integer!]][
			b: 2
			--assert b = 2

			#if any [target = 'IA-32 target = 'ARM][
				--assert :a - 1 = :b					;-- check that `b` stack slot is at right location.
			]
		]
		--assert a = 42
	]
	use1-test
 
  --test-- "use-2"
	use2-test: func [/local a [integer!]][
		a: 42
		use [b [float!] c [integer!]][
			b: 2.0
			c: 123
			--assert b = 2.0
			--assert c = 123

			#if any [target = 'IA-32 target = 'ARM][
				--assert :a - 2 = :b					;-- check that `b` stack slot is at right location.
				--assert :a - 3 = :c					;-- check that `c` stack slot is at right location.
			]
		]
		--assert a = 42
	]
	use2-test

  --test-- "use-3"
	use3-test: func [][
		use [b [integer!]][
			b: 3
			--assert b = 3
		]
	]
	use3-test

  --test-- "use-4"
	use4-test: func [/local a [integer!]][
		catch 10 [
			use [b [integer!]][
				b: 4
				--assert b = 4
				throw 1
			]
		]
		--assert system/thrown = 1
		system/thrown: 0
	]
	use4-test

  --test-- "use-5"
	use5-test: func [/local a [integer!]][
		use [b [integer!]][
			b: 4
			--assert b = 4
			catch 10 [
				b: 5
				--assert b = 5
				throw 1
			]
		]
		--assert system/thrown = 1
		system/thrown: 0
	]
	use5-test

  --test-- "use-6"
	use6-test: func [/local a [integer!]][
		a: 42
		use [b [integer!]][
			b: 4
			--assert b = 4
			loop 1 [
				b: 6
				--assert b = 6
			]
		]
		--assert a = 42
	]
	use6-test
 
  --test-- "use-7"
	use7-test: func [/local a [integer!]][
		a: 42
		loop 1 [
			use [b [integer!]][
				b: 7
				--assert b = 7
			]
		]
		--assert a = 42
	]
 	use7-test
 	
   --test-- "use-8"
	 use8-test: func [/local a [integer!]][
	 	a: 42
		use [b [integer!]][
			b: 7
			--assert b = 7
			use [c [integer!]][
				c: 8
				--assert c = 8
			]
			--assert b = 7
		]
	 	--assert a = 42
	 ]
	 use8-test

  --test-- "use-9"
  	use9-str!: alias struct! [n [integer!]]
  	
	use9-test: func [/local a [integer!]][
	 	a: 42
		use [b [use9-str! value]][
			b/n: 123
			--assert b/n = 123
		]
	 	--assert a = 42
	]
	use9-test
 
~~~end-file~~~

