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
	random/seed C0DECh								;-- seed for tests that use random
	
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
				value: random 1 << 30
				value: value * random/only [-1 +1]
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
				value: value * random/only [-1 +1]
				--assert value == test/one value
			]
		
		--test-- "one-percent"
			--assert 0% == test/one 0%
			--assert 1% == test/one 1%
			--assert -1% == test/one -1%
			--assert 100% == test/one 100%
			
			loop 10 [
				value: random 10000000000000000%
				value: value * random/only [-1 +1]
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
				value: value * random/only [-1 +1]
				--assert value == test/one value
			]
		
		--test-- "one-tuple"
			--assert 0.0.0 == test/one 0.0.0
			--assert 1.2.3.4.5.6.7.8.9 == test/one 1.2.3.4.5.6.7.8.9
			
			loop 10 [
				value: random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test/one value
			]
		
		--test-- "one-time"
			--assert 0:0 == test/one 0:0
			--assert 1:2:3.456 == test/one 1:2:3.456
			
			loop 10 [
				value: random now/time/precise
				value: value * random/only [-1 +1]
				--assert value == test/one value
			]
		
		--test-- "one-date"
			--assert 1/1/1 == test/one 1/1/1
			--assert 9-Sep-99 == test/one 9/9/99
			
			loop 10 [
				value: random now
				--assert value == test/one value
			]
		
		--test-- "one-money"
			--assert $0 == test/one $0
			--assert $1 == test/one $1
			--assert -$1 == test/one -$1
			--assert -USD$1234.56789 == test/one -USD$1234.56789
			
			loop 10 [
				value: as-money pick system/locale/currencies/list random 170 random 1'000
				value: value * random/only [-1 +1]
				--assert value == test/one value
			]
		
		--test-- "one-bitset"
			--assert strict-equal? charset 1 test/one charset 1
			--assert strict-equal? charset #{CAFE} test/one charset #{CAFE}
			--assert strict-equal? charset #{C0FFEE} test/one charset #{C0FFEE}
			--assert strict-equal? charset #{BADFACE} test/one charset #{BADFACE}
			--assert strict-equal? charset #{DEADBEEF} test/one charset #{DEADBEEF}
			--assert strict-equal? charset [#"a" - #"z"] test/one charset [#"a" - #"z"]
			
			loop 10 [
				value: charset to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test/one value
			]
		
		--test-- "one-vector"
			--assert strict-equal? make vector! [] test/one make vector! []
			--assert strict-equal? make vector! [1] test/one make vector! [1]
			--assert strict-equal? make vector! [#"a"] test/one make vector! [#"a"]
			--assert strict-equal? make vector! [1.0] test/one make vector! [1.0]
			--assert strict-equal? make vector! [1%] test/one make vector! [1%]
			--assert strict-equal?
				next make vector! [1 2 3]
				test/one next make vector! [1 2 3]
			--assert strict-equal?
				skip make vector! [1% 2% 3% 4% 5%] 3
				test/one skip make vector! [1% 2% 3% 4% 5%] 3
			--assert strict-equal?
				make vector! [#"a" #"b" #"c"]
				head test/one tail make vector! [#"a" #"b" #"c"]
			
			loop 100 [
				value: attempt [
					skip make vector! reduce [
						type: random/only [integer! float! percent! char!]
						random/only [8 16 32 64]
						collect [loop random 10 [keep to get type random 100]]
					] (random 4) - 1
				]
				
				if value [							;-- some unit sizes and types are incompatible
					--assert value == test/one value
					--assert (index? value) == (index? test/one value)
				]
			]
		
		--test-- "one-binary"
			bytes: [#{} #{F0} #{CAFE} #{C0FFEE} #{BADFACE} #{DEADBEEF}]
			forall bytes [--assert bytes/1 == head test/one skip bytes/1 (random 4) - 1]
			
			loop 10 [
				value: skip
					to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
					(random 4) - 1
				
				--assert value == test/one value
				--assert (index? value) == (index? test/one value)
			]
		
		--test-- "one-any-string"
			strings: ["string" <tag> email@address url:// %file @reference]
			forall strings [--assert strings/1 == head test/one skip strings/1 (random 4) - 1]
		
			loop 10 [
				value: skip to
					get random/only [string! tag! email! ref! url! file!]
					rejoin collect [loop random 100 [keep to char! random 10'000]]
					(random 4) - 1
					
				--assert value == test/one value
				--assert (index? value) == (index? test/one value)
			]
		
	===end-group===

~~~end-file~~~