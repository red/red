Red/System [
	Title:		"Red/System infix syntax test script"
	Author:		"Nenad Rakocevic"
	File:		%infix-test.reds
	Tabs:		4
	Rights:		"Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "infix syntax"

===start-group=== "Simple infix syntax test"
	--test-- "infix-1"
		inf-test: func [[infix] a [integer!] b [integer!] return: [integer!]][
			a + b
		]
		inf-value: 2 inf-test 3
		--assert inf-value = 5
===end-group===

===start-group=== "Test infix call with an additional infix operator"
	--test-- "infix-2"
		inf-assert?: func [[infix] s [c-string!] t [logic!]][
			--assert  t
		]
		"test" inf-assert? (inf-value = 5)	;-- paren are mandatory to force evaluation priority
===end-group===

~~~end-file~~~
