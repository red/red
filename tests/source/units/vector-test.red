Red [
	Title:   "Red series test script"
	Author:  "Peter W A Wood"
	File: 	 %vector-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "vector"

===start-group=== "make"

	vector-make-test: func [
		name [string!]
		type [datatype!]
		spec [block!]
		len [integer!] 
		test-value [char! float! integer! percent!]
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

	vector-make-test "vector-make-10" percent! [100% 200% 300% 400% 500%] 5 0%
		
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

	--test-- "vector-comparison-11"
		--assert (make vector! [1% 2% 3% 4%]) = make vector! [1% 2% 3% 4%]
	
	--test-- "vector-comparison-12"
		--assert (make vector! [1% 2% 3% 4%]) <> make vector! [1% 2% 3% 3%]
		
	--test-- "vector-comparison-13"
		--assert (make vector! [1% 2% 3% 4%]) > make vector! [1% 2% 3% 3%]
		
	--test-- "vector-comparison-14"
		--assert (make vector! [1% 2% 3% 3%]) < make vector! [1% 2% 3% 4%]
	
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
	
	--test-- "vector-ordinal-9"
		--assert 3 = second next make vector! [1 2 3 4]

	--test-- "vector-ordinal-10"
		--assert 3% = second next make vector! [1% 2% 3% 4%]
	
		
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

===start-group=== "vector remove"

	--test-- "vector-remove-1"
		--assert (make vector! [2 3]) = remove make vector! [1 2 3]
		
	--test-- "vector-remove-2"
		--assert (make vector! [3]) = remove next make vector! [1 2 3]
		
	--test-- "vector-remove-3"
		--assert (make vector! []) = remove tail make vector! [1 2 3]
		
	--test-- "vector-remove-4"
		--assert (make vector! []) = remove back tail make vector! [1 2 3]
		
	--test-- "vector-remove-5"
		--assert (make vector! [3]) = remove back back tail make vector! [1 2 3]

===end-group===

===start-group=== "vector reverse"

	--test-- "vector-reverse-1"
		--assert (make vector! [4 3 2 1]) = reverse make vector! [1 2 3 4]
		
	--test-- "vector-reverse-2"
		--assert (make vector! [1 4 3 2 ]) = head reverse next make vector! [1 2 3 4]
		
	--test-- "vector-reverse-2"
		--assert (make vector! [1 2 3 4]) = head reverse tail make vector! [1 2 3 4]
		
===end-group===

===start-group=== "vector take"

	--test-- "vector-take-1"
		vt1-v: make vector! [1 2 3 4]
		--assert 1 = take vt1-v
		--assert vt1-v = make vector! [2 3 4]
	
	--test-- "vector-take-2"
		vt2-v: make vector! [1 2 3 4]
		--assert 2 = take next vt2-v
		--assert vt2-v = make vector! [1 3 4]
		
	--test-- "vector-take-3"
		vt3-v: make vector! [1 2 3 4]
		--assert 4 = take/last vt3-v
		--assert vt3-v = make vector! [1 2 3]
		
	--test-- "vector-take-4"
		vt4-v: make vector! [1 2 3 4]
		--assert (make vector! [1 2]) = take/part vt4-v 2
		--assert vt4-v = make vector! [3 4]
		
	--test-- "vector-take-5"
		vt5-v: make vector! [1 2 3 4]
		--assert (make vector! [1 2]) = take/part vt5-v find vt5-v 3
		--assert vt5-v = make vector! [3 4]

===end-group===

===start-group=== "vector sort"

	--test-- "vector-sort-1"
		--assert (make vector! [1 2 3]) = sort make vector! [3 2 1]
		
	--test-- "vector-sort-2"
		--assert (make vector! [3 1 2]) = head sort next make vector! [3 2 1]
		
	--test-- "vector-sort-3"
		--assert (make vector! [3 2 1]) = head sort tail make vector! [3 2 1]

	--test-- "vector-sort-4"
		--assert (make vector! [#"c" #"à" #"é"]) = sort make vector! [#"é" #"à" #"c"]
		
===end-group===

===start-group=== "vector find"

	--test-- "vector-find-1"
		--assert none = find make vector! [1 2 3 4] "five"

	--test-- "vector-find-2"
		--assert none = find next make vector! [1 2 3 4] 1
	
	--test-- "vector-find-3"
		--assert 1 = first find make vector! [1 2 3 4] 1
	
	--test-- "vector-find-4"
		--assert none = find make vector! [1 2 3 4] 1.0
	
	--test-- "vector-find-5"
		--assert 1 = length? find make vector! [1 2 3 4] 4
	
	--test-- "vector-find-6"
		--assert none = find/part make vector! [1 2 3 4] 4 3

	--test-- "vector-find-7"
		--assert 3 = first find/part make vector! [1 2 3 4] 3 3
		--assert 4 = second find/part make vector! [1 2 3 4] 3 3
		--assert 2 = length? find/part make vector! [1 2 3 4] 3 3
		
	--test-- "vector-find-8"
		--assert #"a" = first find/case make vector! [ #"A" #"a" #"b" #"c"] #"a"
		--assert 3 = length? find/case make vector! [ #"A" #"a" #"b" #"c"] #"a"
		
	--test-- "vector-find-9"
		--assert #"a" = first find make vector! [ #"A" #"a" #"b" #"c"] #"a"
		
	--test-- "vector-find-10"
		--assert (make vector! [4 5 6]) = find/skip make vector! [1 4 4 4 5 6] 4 3
		
	--test-- "vector-find-11"
		--assert (make vector! [1]) = find/last make vector! [1 1 1 1 1] 1
	
	--test-- "vector-find-12"
		vf12-v: next next next make vector! [1 2 1 2 1 2]
		--assert (make vector! [2 1 2 1 2]) = find/reverse vf12-v 2
		
	--test-- "vector-find-13"
		--assert (make vector! [5 6]) = find/tail make vector! [1 2 3 4 5 6] 4
		
	--test-- "vector-find-14"
		--assert (make vector! [3 4]) = find/match next make vector! [1 2 3 4] 2
		
===end-group===

===start-group=== "vector select"

	--test-- "vector-select-1"
		--assert none = select make vector! [1 2 3 4] "five"

	--test-- "vector-select-2"
		--assert none = select next make vector! [1 2 3 4] 1
	
	--test-- "vector-select-3"
		--assert 2 = select make vector! [1 2 3 4] 1
	
	--test-- "vector-select-4"
		--assert none = select make vector! [1 2 3 4] 1.0
	
	--test-- "vector-select-5"
		--assert 4 = select make vector! [1 2 3 4] 3
	
	--test-- "vector-select-6"
		--assert none = select/part make vector! [1 2 3 4] 4 3

	--test-- "vector-select-7"
		--assert 4 = select/part make vector! [1 2 3 4] 3 3
		
	--test-- "vector-select-8"
		--assert #"b" = select/case make vector! [ #"A" #"a" #"b" #"c"] #"a"
		
	--test-- "vector-select-9"
		--assert #"b" = select make vector! [ #"A" #"a" #"b" #"c"] #"a"
		
	--test-- "vector-select-10"
		--assert 5 = select/skip make vector! [1 4 4 4 5 6] 4 3
		
	--test-- "vector-select-11"
		--assert 1 = select/last make vector! [1 2 3 4 1] 4
	
	--test-- "vector-select-12"
		vs12-v: next next next next make vector! [1 2 1 2 3 4]
		--assert 3 = select/reverse vs12-v 2
		
===end-group===

===start-group=== "vector add"
		
		va-v1: make vector! [10 20 30 40 50]
		va-v2: make vector! [2 3 4 5 6]

	--test-- "vector-add-1"
		va1-v: va-v1 + va-v2
		--assert va1-v = make vector! [12 23 34 45 56]
	
	--test-- "vector-add-2"
		va2-v: add va-v1 va-v2
		--assert va2-v = make vector! [12 23 34 45 56]
		
	--test-- "vector-add-3"
		va3-v: add next va-v1 va-v2
		--assert va3-v = make vector! [22 33 44 55]
		
	--test-- "vector-add-4"	
		va4-v: add va-v1 next next va-v2
		--assert va4-v = make vector! [14 25 36]
		
	--test-- "vector-add-5"
		va-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		va5-v: va-v1 + va-v1
		--assert va5-v = make vector! [2.0 4.0 6.0 8.0 10.0]
	
	--test-- "vector-add-6"
		va6-v: va-v1 + 0.5
		--assert va6-v = make vector! [1.5 2.5 3.5 4.5 5.5]
		
	--test-- "vector-add-7"
		va-v1: make vector! [10 20 30 40 50]
		va7-v: va-v1 + -1
		--assert va7-v = make vector! [9 19 29 39 49]
		
	--test-- "vector-add-8"
		va-v1: make vector! [10 20 30 40 50]
		va8-v: va-v1 + 1.5
		--assert va8-v = make vector! [11 21 31 41 51]
		
	--test-- "vector-add-9"
		va-v1: make vector! [10 20 30 40 50]
		va9-v: va-v1 + 0.5
		--assert va9-v = make vector! [10 20 30 40 50]
	
	--test-- "vector-add-10"
		va10-v1: make vector! [integer! 8 [253 254 255]]
		va10-v2: make vector! [integer! 8 [3 2 1]]
		va10-v3: va10-v1 + va10-v2
		--assert va10-v3 = make vector! [integer! 8 [0 0 0]]
		
===end-group===

===start-group=== "vector subtract"
		
		vs-v1: make vector! [10 20 30 40 50]
		vs-v2: make vector! [2 3 4 5 6]

	--test-- "vector-subtract-1"
		vs1-v: vs-v1 - vs-v2
		--assert vs1-v = make vector! [8 17 26 35 44]
	
	--test-- "vector-subtract-2"
		vs2-v: subtract vs-v1 vs-v2
		--assert vs2-v = make vector! [8 17 26 35 44]
		
	--test-- "vector-subtract-3"
		vs3-v: subtract next vs-v1 vs-v2
		--assert vs3-v = make vector! [18 27 36 45]
		
	--test-- "vector-subtract-4"	
		vs4-v: subtract vs-v1 next next vs-v2
		--assert vs4-v = make vector! [6 15 24]
		
	--test-- "vector-subtract-5"
		vs-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vs5-v: vs-v1 - vs-v1
		--assert vs5-v = make vector! [0.0 0.0 0.0 0.0 0.0]
	
	--test-- "vector-subtract-6"
		vs6-v: vs-v1 - 0.5
		--assert vs6-v = make vector! [0.5 1.5 2.5 3.5 4.5]
		
	--test-- "vector-subtract-7"
		vs-v1: make vector! [10 20 30 40 50]
		vs7-v: vs-v1 - -1
		--assert vs7-v = make vector! [11 21 31 41 51]
		
	--test-- "vector-subtract-8"
		vs-v1: make vector! [10 20 30 40 50]
		vs8-v: vs-v1 - 1.5
		--assert vs8-v = make vector! [9 19 29 39 49]
		
	--test-- "vector-subtract-9"
		vs-v1: make vector! [10 20 30 40 50]
		vs9-v: vs-v1 - 0.5
		--assert vs9-v = make vector! [10 20 30 40 50]
		
===end-group===

===start-group=== "vector multiply"
		
		vm-v1: make vector! [10 20 30 40 50]
		vm-v2: make vector! [2 3 4 5 6]

	--test-- "vector-multiply-1"
		vm1-v: vm-v1 * vm-v2
		--assert vm1-v = make vector! [20 60 120 200 300]
	
	--test-- "vector-multiply-2"
		vm2-v: multiply vm-v1 vm-v2
		--assert vm2-v = make vector! [20 60 120 200 300]
		
	--test-- "vector-multiply-3"
		vm3-v: multiply next vm-v1 vm-v2
		--assert vm3-v = make vector! [40 90 160 250]
		
	--test-- "vector-multiply-4"	
		vm4-v: multiply vm-v1 next next vm-v2
		--assert vm4-v = make vector! [40 100 180]
		
	--test-- "vector-multiply-5"
		vm-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vm5-v: vm-v1 * vm-v1
		--assert vm5-v = make vector! [1.0 4.0 9.0 16.0 25.0]
	
	--test-- "vector-multiply-6"
		vm6-v: vm-v1 * 0.5
		--assert vm6-v = make vector! [0.5 1.0 1.5 2.0 2.5]
		
	--test-- "vector-multiply-7"
		vm-v1: make vector! [10 20 30 40 50]
		vm7-v: vm-v1 * -1
		--assert vm7-v = make vector! [-10 -20 -30 -40 -50]
		
	--test-- "vector-multiply-8"
		vm-v1: make vector! [10 20 30 40 50]
		vm8-v: vm-v1 * 1.5
		--assert vm8-v = make vector! [10 20 30 40 50]
		
	--test-- "vector-multiply-9"
		vm-v1: make vector! [10 20 30 40 50]
		vm9-v: vm-v1 * 0.5
		--assert vm9-v = make vector! [0 0 0 0 0]
		
	--test-- "vector-multiply-10"
		vm10-v1: make vector! [integer! 8 [253 254 255]]
		vm10-v2: make vector! [integer! 8 [3 2 1]]
		vm10-v3: vm10-v1 * vm10-v2
		--assert vm10-v3 = make vector! [integer! 8 [247 252 255]]

	--test-- "vector-multiply-11"
		vm-v1: make vector! [100% 200% 300% 400% 500%]
		vm9-v: vm-v1 * 50%
		--assert vm9-v = make vector! [50% 100% 150% 200% 250%]
			
===end-group===

===start-group=== "vector divide"
		
		vm-v1: make vector! [10 20 30 40 50]
		vm-v2: make vector! [2 3 4 5 6]

	--test-- "vector-divide-1"
		vm1-v: vm-v1 / vm-v2
		--assert vm1-v = make vector! [5 6 7 8 8]
	
	--test-- "vector-divide-2"
		vm2-v: divide vm-v1 vm-v2
		--assert vm2-v = make vector! [5 6 7 8 8]
		
	--test-- "vector-divide-3"
		vm3-v: divide next vm-v1 vm-v2
		--assert vm3-v = make vector! [10 10 10 10]
		
	--test-- "vector-divide-4"	
		vm4-v: divide vm-v1 next next vm-v2
		--assert vm4-v = make vector! [2 4 5]
		
	--test-- "vector-divide-5"
		vm-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vm5-v: vm-v1 / vm-v1
		--assert vm5-v = make vector! [1.0 1.0 1.0 1.0 1.0]
	
	--test-- "vector-divide-6"
		vm6-v: vm-v1 / 0.5
		--assert vm6-v = make vector! [2.0 4.0 6.0 8.0 10.0]
		
	--test-- "vector-divide-7"
		vm-v1: make vector! [10 20 30 40 50]
		vm7-v: vm-v1 / -1
		--assert vm7-v = make vector! [-10 -20 -30 -40 -50]
		
	--test-- "vector-divide-8"
		vm-v1: make vector! [10 20 30 40 50]
		vm8-v: vm-v1 / 1.5
		--assert vm8-v = make vector! [10 20 30 40 50]
		
	--test-- "vector-divide-9"
		vm-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vm9-v: vm-v1 / 5.0
		--assert vm9-v = make vector! [0.2 0.4 0.6 0.8 1.0]
		
===end-group===

===start-group=== "vector remainder"
		
		vm-v1: make vector! [10 20 30 40 50]
		vm-v2: make vector! [2 3 4 5 6]

	--test-- "vector-remainder-1"
		vm1-v: vm-v1 % vm-v2
		--assert vm1-v = make vector! [0 2 2 0 2]
	
	--test-- "vector-remainder-2"
		vm2-v: remainder vm-v1 vm-v2
		--assert vm2-v = make vector! [0 2 2 0 2]
		
	--test-- "vector-remainder-3"
		vm3-v: remainder next vm-v1 vm-v2
		--assert vm3-v = make vector! [0 0 0 0]
		
	--test-- "vector-remainder-4"	
		vm4-v: remainder vm-v1 next next vm-v2
		--assert vm4-v = make vector! [2 0 0]
		
	--test-- "vector-remainder-5"
		vm-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vm5-v: vm-v1 % vm-v1
		--assert vm5-v = make vector! [0.0 0.0 0.0 0.0 0.0]
	
	--test-- "vector-remainder-6"
		vm6-v: vm-v1 % 0.5
		--assert vm6-v = make vector! [0.0 0.0 0.0 0.0 0.0]
		
	--test-- "vector-remainder-7"
		vm-v1: make vector! [10 20 30 40 50]
		vm7-v: vm-v1 % -1
		--assert vm7-v = make vector! [0 0 0 0 0]
		
	--test-- "vector-remainder-8"
		vm-v1: make vector! [10 20 30 40 50]
		vm8-v: vm-v1 % 1.5
		--assert vm8-v = make vector! [0 0 0 0 0]
		
	--test-- "vector-remainder-9"
		vm-v1: make vector! [1.0 2.0 3.0 4.0 5.0]
		vm9-v: vm-v1 % 5.0
		--assert vm9-v = make vector! [1.0 2.0 3.0 4.0 0.0]
		
===end-group===

===start-group=== "vector and"
		
		vand-v1: make vector! [10 20 30 40 50]
		vand-v2: make vector! [2 3 4 5 6]

	--test-- "vector-and-1"
		vand1-v: vand-v1 and vand-v2
		--assert vand1-v = make vector! [2 0 4 0 2]
	
	--test-- "vector-and-2"
		vand2-v: vand-v1 and next vand-v2
		--assert vand2-v = make vector! [2 4 4 0]
		
	--test-- "vector-and-3"
		vand3-v: (next vand-v1) and vand-v2
		--assert vand3-v = make vector! [0 2 0 0]
		
	--test-- "vector-and-4"	
		vand4-v: vand-v1 and next next vand-v2
		--assert vand4-v = make vector! [0 4 6]
		
	--test-- "vector-and-5"
		vand-v1: make vector! [10 20 30 40 50]
		vand7-v: vand-v1 and -1
		--assert vand7-v = make vector! [10 20 30 40 50]
		
===end-group===

===start-group=== "vector or"
		
		vor-v1: make vector! [10 20 30 40 50]
		vor-v2: make vector! [2 3 4 5 6]

	--test-- "vector-or-1"
		vor1-v: vor-v1 or vor-v2
		--assert vor1-v = make vector! [10 23 30 45 54]
	
	--test-- "vector-or-2"
		vor2-v: vor-v1 or next vor-v2
		--assert vor2-v = make vector! [11 20 31 46]
		
	--test-- "vector-or-3"
		vor3-v: (next vor-v1) or vor-v2
		--assert vor3-v = make vector! [22 31 44 55]
		
	--test-- "vector-or-4"	
		vor4-v: vor-v1 or next next vor-v2
		--assert vor4-v = make vector! [14 21 30]
		
	--test-- "vector-or-5"
		vor-v1: make vector! [10 20 30 40 50]
		vor7-v: vor-v1 or -1
		--assert vor7-v = make vector! [-1 -1 -1 -1 -1]
		
===end-group===

===start-group=== "vector xor"
		
		vxor-v1: make vector! [10 20 30 40 50]
		vxor-v2: make vector! [2 3 4 5 6]

	--test-- "vector-xor-1"
		vxor1-v: vxor-v1 xor vxor-v2
		--assert vxor1-v = make vector! [8 23 26 45 52]
	
	--test-- "vector-xor-2"
		vxor2-v: vxor-v1 xor next vxor-v2
		--assert vxor2-v = make vector! [9 16 27 46]
		
	--test-- "vector-xor-3"
		vxor3-v: (next vxor-v1) xor vxor-v2
		--assert vxor3-v = make vector! [22 29 44 55]
		
	--test-- "vector-xor-4"	
		vxor4-v: vxor-v1 xor next next vxor-v2
		--assert vxor4-v = make vector! [14 17 24]
		
	--test-- "vector-xor-5"
		vxor-v1: make vector! [10 20 30 40 50]
		vxor7-v: vxor-v1 xor -1
		--assert vxor7-v = make vector! [-11 -21 -31 -41 -51]
		
===end-group===

~~~end-file~~~

