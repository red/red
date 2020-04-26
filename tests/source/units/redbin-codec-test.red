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
			loop 10 [
				value: random true
				--assert value == test/one value
			]
		
		--test-- "one-integer"
			--assert 0 == test/one 0
			--assert 1 == test/one 1
			--assert -1 == test/one -1
			--assert 1337 == test/one 1337
			--assert (1 << 31) == test/one 1 << 31
			--assert (complement 1 << 31) == test/one complement 1 << 31
			loop 10 [
				value: random 1 << 31
				--assert value == test/one value
			]
		
		--test-- "one-char"
			--assert #"a" == test/one #"a"
			--assert #"A" == test/one #"A"
			--assert null == test/one null
			--assert #"^D" == test/one #"^(4)"
			--assert #"💾" == test/one #"💾"
			loop 10 [
				value: random #"Z"
				--assert value == test/one value
			]
		
		--test-- "one-float"
			--assert 0.0 == test/one 0.0
			--assert 0.1 == test/one 0.1
			--assert -1.0 == test/one -1.0
			--assert "1.#NaN" == mold test/one 1.#NaN
			--assert 1.#INF == test/one 1.#INF
			--assert -1.#INF == test/one -1.#INF
			loop 10 [
				value: random 1'000'000'000'000
				--assert value == test/one value
			]
		
		--test-- "one-percent"
			--assert 0% == test/one 0%
			--assert 1% == test/one 1%
			--assert -1% == test/one -1%
			--assert 100% == test/one 100%
			loop 10 [
				value: random 10000000000000000%
				--assert value == test/one value
			]
		
		--test-- "one-pair"
			--assert 0x0 == test/one 0x0
			--assert 0x1 == test/one 0x1
			--assert 1x0 == test/one 1x0
			--assert 1x1 == test/one 1x1
			--assert -1x-2 == test/one -1x-2
			loop 10 [
				value: random 10000x10000
				--assert value == test/one value
			]
			
	===end-group===

~~~end-file~~~