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

===end-group===



~~~end-file~~~