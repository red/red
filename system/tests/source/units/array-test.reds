Red/System [
	Title:   "Red/System arrays test script"
	Author:  "Nenad Rakocevic"
	File: 	 %array-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "array!"

===start-group=== "Literal arrays"

	--test-- "Float array"					;#4031
	fa: [1e-16 1e-32 1e-64 1e-128 0.0]
	p: as int-ptr! fa
	--assert 5 = size? fa
	fa/5: 1.234
	--assert fa/5 = 1.234
	
	--test-- "bin-arr-1"
		bin-arr-1: #{0908070605}	
		--assert 9 = as-integer bin-arr-1/1
		--assert 8 = as-integer bin-arr-1/2
		--assert 7 = as-integer bin-arr-1/3
		--assert 6 = as-integer bin-arr-1/4
		--assert 5 = as-integer bin-arr-1/5
	
	--test-- "bin-arr-2"
		test-bin-arr-2: func [return: [byte-ptr!] /local buff [byte-ptr!]][
			buff: #{0304050607}
			buff
		]
		bin-arr-2: test-bin-arr-2
		--assert 3 = as-integer bin-arr-2/1
		--assert 4 = as-integer bin-arr-2/2
		--assert 5 = as-integer bin-arr-2/3
		--assert 6 = as-integer bin-arr-2/4
		--assert 7 = as-integer bin-arr-2/5

	--test-- "bin-arr-3"
		bin-arr-3: #{0A0B}
		--assert 10 = as-integer bin-arr-3/1
		--assert 11 = as-integer bin-arr-3/2


===end-group===



~~~end-file~~~