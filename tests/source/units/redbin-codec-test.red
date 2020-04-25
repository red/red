Red [
	Title:	 "Redbin codec test script"
	Author:	 "Vladimir Vasilyev"
	File:	 %redbin-test.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "Redbin codec"
	test: function [value [any-type!] /one][
		data: load/as save/as none :value 'redbin 'redbin
		either one [first data][data]
	]
	
	===start-group=== "one"
		--test-- "one-unset"
			--assert () == test/one ()
		
		--test-- "one-none"
			--assert none == test/one none
		
		--test-- "one-datatype"
			--assert datatype! == test/one datatype!
			--assert typeset! == test/one typeset!
		
		--test-- "one-logic"
			--assert true == test/one true
			--assert false == test/one false
		
		--test-- "one-integer"
			--assert 0 == test/one 0
			--assert 1 == test/one 1
			--assert -1 == test/one -1
			--assert 1337 == test/one 1337
			--assert (1 << 31) == test/one 1 << 31
			--assert (complement 1 << 31) == test/one complement 1 << 31
		
		--test-- "one-char"
			--assert #"a" == test/one #"a"
			--assert #"A" == test/one #"A"
			--assert null == test/one null
			--assert #"^D" == test/one #"^(4)"
			--assert #"💾" == test/one #"💾"
		
	===end-group===

~~~end-file~~~