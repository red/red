Red [
	Title:   "Red series test script"
	Author:  "Peter W A Wood"
	File: 	 %vector-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "vector"

===start-group=== "make"

	vector-make-test: func [
		name [string!]
		type [datatype!]
		spec [block!]
		len [integer!] 
		test-value [char! float! integer!]
		/local
			vm-v
	][
		--test-- name
		vm-v: make vector! spec
		--assert len = length? vm-v
		foreach v vm-v [
			test-value: test-value + 1
			--assert test-value = v
			--assert type = type? v
		]
		--assert none = vm-v/0
		--assert none = vm-v/(len + 1)
	]

	--test-- "vector-make-1"
		vm1-v: make vector! 10
		--assert 10 = length? vm1-v
		foreach v vm1-v [
			--assert v = 0
			--assert integer! = type? v
		]
		--assert none = vm1-v/0
		--assert none = vm1-v/11
		
	vector-make-test "vector-make-2" integer! [1 2 3 4 5] 5 0
		
	vector-make-test "vector-make-3" char! [#"b" #"c" #"d" #"e"] 4 #"a"
	
	vector-make-test "vector-make-4" float! [1.0 2.0 3.0 4.0 5.0] 5 0.0

	vector-make-test "vector-make-5" integer! [integer! 8 [1 2 3 4 5]] 5 0

	vector-make-test "vector-make-6" integer! [integer! 16 [1 2 3 4 5]] 5 0
	
	vector-make-test "vector-make-7" integer! [integer! 32 [1 2 3 4 5]] 5 0
	
	vector-make-test "vector-make-8" float! [float! 64 [1.0 2.0 3.0 4.0 5.0]] 5 0.0
	
	vector-make-test "vector-make-9" float! [float! 32 [1.0 2.0 3.0 4.0 5.0]] 5 0.0
		
===end-group===

===start-group=== "vector-truncate"

	--test-- "vector-trunc-1"
		vt1-v: make vector! [char! 8 [#"^(00)" #"^(01)" #"^(02)"]]
		append vt1-v #"^(0100)"
		--assert 4 = length? vt1-v
		--assert #"^(00)" = vt1-v/4
		--assert none = vt1-v/5
		
	--test-- "vector-trunc-2"
		vt2-v: make vector! [char! 16 [#"^(00)" #"^(01)" #"^(02)"]]
		append vt2-v #"^(100100)"
		--assert 4 = length? vt2-v
		--assert #"^(0100)" = vt2-v/4
		--assert none = vt2-v/5
		
	--test-- "vector-trunc-3"
		vt3-v: make vector! [integer! 8 [0 1 2]]
		append vt3-v 256
		--assert 4 = length? vt3-v
		--assert 0 = vt3-v/4
		--assert none = vt3-v/5
	
	--test-- "vector-trunc-4"
		vt4-v: make vector! [integer! 16 [0 1 2]]
		append vt4-v 65536
		--assert 4 = length? vt4-v
		--assert 0 = vt4-v/4
		--assert none = vt4-v/5
		
	--test-- "vector-trunc-6"
		vt5-v: make vector! [float! 32 [0.0 1.0 2.0]]
		append vt5-v 1.23456789012345678901234567
		--assert 1.2345679 = round/to vt5-v/4 0.0000001 
		
===end-group===

===start-group=== "vector path notation"
	
	--test-- "vector-path-1"
		vp1-v: [0 1 2 3 4]
		--assert none = vp1-v/0
		--assert 0 = vp1-v/1
		--assert 1 = vp1-v/2
		--assert 2 = vp1-v/3
		--assert 3 = vp1-v/4
		--assert 4 = vp1-v/5
		--assert none = vp1-v/6
		--assert none = vp1-v/-1
		
===end-group===

===start-group=== "vector navigation"

	--test-- "vector-navigation-1"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: next vn-v
		--assert vn-v/1 = 1
		--assert vn-v/4 = 4
	
	--test-- "vector-navigation-2"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: next next vn-v
		--assert vn-v/1 = 2
		--assert vn-v/3 = 4
	
	--test-- "vector-navigation-3"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: next next next vn-v
		--assert vn-v/1 = 3 
		--assert vn-v/2 = 4
	
	--test-- "vector-navigation-4"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: next next next next vn-v
		--assert vn-v/1 = 4
		
	--test-- "vector-navigation-5"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: tail vn-v
		--assert vn-v/1 = none
		
	--test-- "vector-navigation-6"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: back tail vn-v
		--assert vn-v/1 = 4
	
	--test-- "vector-navigation-7"
		vn-v: make vector! [0 1 2 3 4]
		vn-v: head tail vn-v
		--assert vn-v/1 = 0
		--assert vn-v/5 = 4
	
===end-group===

===start-group=== "vector comparison"

	--test-- "vector-comparison-1"
		--assert (make vector! [1 2 3 4]) = make vector! [1 2 3 4]
	
	--test-- "vector-comparison-2"
		--assert (make vector! [1 2 3 4]) <> make vector! [1 2 3 3]
		
	--test-- "vector-comparison-3"
		--assert (make vector! [1 2 3 4]) > make vector! [1 2 3 3]
		
	--test-- "vector-comparison-4"
		--assert (make vector! [1 2 3 3]) < make vector! [1 2 3 4]
		
	--test-- "vector-comparison-5"
		--assert (make vector! [1 2 3]) < make vector! [1 2 3 4]
		
	--test-- "vector-comparison-6"
		--assert equal? make vector! [1 2 3 4] make vector! [1 2 3 4]
	
	--test-- "vector-comparison-7"
		--assert not equal? make vector! [1 2 3 4]make vector! [1 2 3 3]
		
	--test-- "vector-comparison-8"
		--assert greater? make vector! [1 2 3 4] make vector! [1 2 3 3]
		
	--test-- "vector-comparison-9"
		--assert lesser? make vector! [1 2 3 3] make vector! [1 2 3 4]
		
	--test-- "vector-comparison-10"
		--assert lesser? make vector! [1 2 3] make vector! [1 2 3 4]
	
===end-group===

===start-group=== "vector ordinal"

	--test-- "vector-ordinal-1"
		--assert 1 = first make vector! [1 2 3 4]

	--test-- "vector-ordinal-2"
		--assert 2 = second make vector! [1 2 3 4]

	--test-- "vector-ordinal-3"
		--assert 3 = third make vector! [1 2 3 4]

	--test-- "vector-ordinal-4"
		--assert 4 = fourth make vector! [1 2 3 4]

	--test-- "vector-ordinal-5"
		--assert 5 = fifth make vector! [1 2 3 4 5]

	--test-- "vector-ordinal-6"
		--assert none = fifth make vector! [1 2 3 4]
		
	--test-- "vector-ordinal-7"
		--assert 4 = last make vector! [1 2 3 4]
		
	--test-- "vector-ordinal-8"
		--assert 2 = first next make vector! [1 2 3 4]		
	
	--test-- "vector-ordinal-7"
		--assert 3 = second next make vector! [1 2 3 4]
		
===end-group===

===start-group=== "vector-clear"
		
		empty-vector: make vector! []

	--test-- "vector-clear-1"
		--assert empty-vector = clear make vector! [1 2 3 4]
		
	--test-- "vector-clear-2"
		vc2-v: make vector! [1 2 3 4]
		append vc2-v 5 
		--assert empty-vector = clear vc2-v
		
===end-group===

===start-group=== "vector-copy"

	--test-- "vector-copy-1"
		vcp1-v1: make vector! [1 2 3 4]
		vcp1-v2: copy vcp1-v1
		vcp1-v1/1: 5
		vcp1-v1/2: 6
		vcp1-v1/3: 7
		vcp1-v1/4: 8
		--assert vcp1-v1 = make vector! [5 6 7 8]
		--assert vcp1-v2 = make vector! [1 2 3 4]
		
	--test-- "vector-copy-2"
		vcp2-v: make vector! [1 2 3 4 5 6 7 8 9]
			--assert (make vector! [1 2 3 4]) = copy/part vcp2-v 4
			
	--test-- "vector-copy-3"
		vcp3-v: make vector! [1 2 3 4 5 6 7 8 9]
			--assert (make vector! [3 4]) = copy/part next next vcp3-v 2

	--test-- "vector-copy-4"
		vcp4-v: make vector! [1 2 3 4 5 6 7 8 9]
			--assert (make vector! [8]) = copy/part back back tail vcp4-v 1

	--test-- "vector-copy-5"
		vcp5-v: make vector! [1 2]
			--assert (make vector! [1 2]) = copy/part vcp5-v 4
	
===end-group===

===start-group=== "vector poke"

	--test-- "vector-poke-1"
		vp1-v: make vector! [1 2]
		poke vp1-v 1 0
		--assert (make vector! [0 2]) = vp1-v
		
	--test-- "vector-poke-2"
		vp2-v: make vector! [1 2 3]
		poke vp2-v 3 0
		--assert (make vector! [1 2 0]) = vp2-v
		
	--test-- "vector-poke-3"
		vp3-v: make vector! [1 2 3]
		poke vp3-v 2 0
		--assert (make vector! [1 0 3]) = vp3-v
		
===end-group===


~~~end-file~~~

