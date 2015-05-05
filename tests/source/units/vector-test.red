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

~~~end-file~~~

