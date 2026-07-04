Red/System [
	Title:   "Red/System protect test script"
	Author:  "Nenad Rakocevic"
	File: 	 %protect-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2026 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

pt-double: func [n [integer!] return: [integer!]][n * 2]
pt-triple: func [n [integer!] return: [integer!]][n * 3]

int-fn!: alias function! [n [integer!] return: [integer!]]

pt-nums: protect [10 20 30 40]
pt-flts: protect [1.5 2.5 3.5]
pt-msg:  protect "protected string"
pt-bin:  protect #{C0FFEE}
pt-mix:  protect ["alpha" "beta"]
pt-fns:  protect [:pt-double :pt-triple]
pt-cast: protect as byte-ptr! "AB"
PT-RATE: protect 60
PT-HALF: protect 0.5
PT-CHAR: protect #"Z"

pt-tab2: [1 PT-RATE 3]							;-- protected scalar folded in a literal array

pt-fptrs: declare struct! [						;-- struct fields: portable function pointer calls
	f1 [int-fn!]
	f2 [int-fn!]
]
pt-fptrs/f1: as int-fn! pt-fns/1
pt-fptrs/f2: as int-fn! pt-fns/2

pt-sum: func [return: [integer!] /local i s [integer!]][
	s: 0
	i: 1
	while [i <= 4][s: s + pt-nums/i i: i + 1]
	s
]

~~~start-file~~~ "protect"

===start-group=== "protected data"

	--test-- "pt-int-array"
	--assert 4 = size? pt-nums
	--assert 10 = pt-nums/1
	--assert 40 = pt-nums/4
	--assert 100 = pt-sum

	--test-- "pt-float-array"
	--assert pt-flts/2 = 2.5

	--test-- "pt-string"
	--assert pt-msg/1 = #"p"
	--assert 16 = length? pt-msg

	--test-- "pt-binary"
	--assert 192 = as-integer pt-bin/1
	--assert 255 = as-integer pt-bin/2
	--assert 238 = as-integer pt-bin/3

	--test-- "pt-string-array"
	--assert 0 = compare-memory as byte-ptr! pt-mix/1 as byte-ptr! "alpha" 6
	--assert 0 = compare-memory as byte-ptr! pt-mix/2 as byte-ptr! "beta" 5

	--test-- "pt-function-array"				;-- protected function pointer table
	--assert 14 = pt-fptrs/f1 7
	--assert 21 = pt-fptrs/f2 7

	--test-- "pt-cast-literal"
	--assert pt-cast/1 = #"A"
	--assert pt-cast/2 = #"B"

===end-group===

===start-group=== "protected scalar constants"

	--test-- "pt-scalars"
	--assert PT-RATE = 60
	--assert 61 = (PT-RATE + 1)
	--assert PT-HALF = 0.5
	--assert 1.0 = (PT-HALF + PT-HALF)
	--assert PT-CHAR = #"Z"

	--test-- "pt-scalar-in-array"
	--assert 60 = pt-tab2/2

	--test-- "pt-scalar-in-case"
	--assert 1 = case [PT-RATE = 60 [1] true [0]]

===end-group===

~~~end-file~~~
