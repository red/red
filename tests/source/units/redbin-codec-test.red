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
	
	test: function [value [any-type!]][
		load/as save/as none :value 'redbin 'redbin
	]
	
	===start-group=== "values"
		--test-- "unset"
			--assert () == test ()
		
		--test-- "none"
			--assert none == test none
		
		--test-- "datatype"
			--assert datatype! == test datatype!
			--assert typeset! == test typeset!
		
		--test-- "logic"
			--assert true == test true
			--assert false == test false
			
			loop 10 [
				value: random true
				--assert value == test value
			]
		
		--test-- "integer"
			--assert 0 == test 0
			--assert 1 == test 1
			--assert -1 == test -1
			--assert 1337 == test 1337
			--assert (1 << 31) == test 1 << 31
			--assert (complement 1 << 31) == test complement 1 << 31
			
			loop 10 [
				value: random 1 << 30
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "char"
			--assert #"a" == test #"a"
			--assert #"A" == test #"A"
			--assert null == test null
			--assert #"^D" == test #"^(4)"
			--assert #"💾" == test #"💾"
			
			loop 10 [
				value: random #"Z"
				--assert value == test value
			]
		
		--test-- "float"
			--assert 0.0 == test 0.0
			--assert 0.1 == test 0.1
			--assert -1.0 == test -1.0
			--assert "1.#NaN" == mold test 1.#NaN
			--assert 1.#INF == test 1.#INF
			--assert -1.#INF == test -1.#INF
			
			loop 10 [
				value: random 1'000'000'000'000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "percent"
			--assert 0% == test 0%
			--assert 1% == test 1%
			--assert -1% == test -1%
			--assert 100% == test 100%
			
			loop 10 [
				value: random 10000000000000000%
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "pair"
			--assert 0x0 == test 0x0
			--assert 0x1 == test 0x1
			--assert 1x0 == test 1x0
			--assert 1x1 == test 1x1
			--assert -1x-2 == test -1x-2
			
			loop 10 [
				value: random 10000x10000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "tuple"
			--assert 0.0.0 == test 0.0.0
			--assert 1.2.3.4.5.6.7.8.9 == test 1.2.3.4.5.6.7.8.9
			
			loop 10 [
				value: random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test value
			]
		
		--test-- "time"
			--assert 0:0 == test 0:0
			--assert 1:2:3.456 == test 1:2:3.456
			
			loop 10 [
				value: random now/time/precise
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "date"
			--assert 1/1/1 == test 1/1/1
			--assert 9-Sep-99 == test 9/9/99
			
			loop 10 [
				value: random now
				--assert value == test value
			]
		
		--test-- "money"
			--assert $0 == test $0
			--assert $1 == test $1
			--assert -$1 == test -$1
			--assert -USD$1234.56789 == test -USD$1234.56789
			
			loop 10 [
				value: as-money pick system/locale/currencies/list random 170 random 1'000
				value: value * random/only [-1 +1]
				--assert value == test value
			]
		
		--test-- "typeset"
			--assert strict-equal? make typeset! [] test make typeset! []
			--assert series! == test series!
			--assert any-string! == test any-string!
			--assert immediate! == test immediate!
			--assert scalar! == test scalar!
		
		--test-- "bitset"
			--assert strict-equal? charset 1 test charset 1
			--assert strict-equal? charset #{CAFE} test charset #{CAFE}
			--assert strict-equal? charset #{C0FFEE} test charset #{C0FFEE}
			--assert strict-equal? charset #{BADFACE} test charset #{BADFACE}
			--assert strict-equal? charset #{DEADBEEF} test charset #{DEADBEEF}
			--assert strict-equal? charset [#"a" - #"z"] test charset [#"a" - #"z"]
			
			loop 10 [
				value: charset to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
				--assert value == test value
			]
		
		--test-- "vector"
			--assert strict-equal? make vector! [] test make vector! []
			--assert strict-equal? make vector! [1] test make vector! [1]
			--assert strict-equal? make vector! [#"a"] test make vector! [#"a"]
			--assert strict-equal? make vector! [1.0] test make vector! [1.0]
			--assert strict-equal? make vector! [1%] test make vector! [1%]
			--assert strict-equal?
				next make vector! [1 2 3]
				test next make vector! [1 2 3]
			--assert strict-equal?
				skip make vector! [1% 2% 3% 4% 5%] 3
				test skip make vector! [1% 2% 3% 4% 5%] 3
			--assert strict-equal?
				make vector! [#"a" #"b" #"c"]
				head test tail make vector! [#"a" #"b" #"c"]
			
			loop 100 [
				value: attempt [
					skip make vector! reduce [
						type: random/only [integer! float! percent! char!]
						random/only [8 16 32 64]
						collect [loop random 10 [keep to get type random 100]]
					] (random 4) - 1
				]
				
				if value [							;-- some unit sizes and types are incompatible
					--assert value == test value
					--assert (index? value) == index? test value
				]
			]
		
		--test-- "binary"
			bytes: [#{} #{F0} #{CAFE} #{C0FFEE} #{BADFACE} #{DEADBEEF}]
			forall bytes [--assert bytes/1 == head test skip bytes/1 (random 4) - 1]
			
			loop 10 [
				value: skip
					to binary! random to tuple! copy/part 64#{////////////////} 2 + random 11
					(random 4) - 1
				
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "any-string"
			strings: [{} "string" <tag> email@address url:// %file @reference]
			forall strings [--assert strings/1 == head test skip strings/1 (random 4) - 1]
		
			loop 10 [
				value: skip to
					get random/only to block! any-string!
					rejoin collect [loop random 100 [keep to char! random 10'000]]
					(random 4) - 1
					
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "any-list"
			blocks: [[] [1] [1 2 3] ["a" [#{BC} [[[[[[1.2.3]]]]] [[[$4.56]] [78x90]]]]]]
			forall blocks [--assert blocks/1 == head test skip blocks/1 (random 4) - 1]
			
			loop 10 [
				value: collect [
					loop random 100 [
						keep to
							get random/only [integer! float! pair! money!]
							random 1'000
					]
				]
				value: skip value (random 4) - 1
				if random true [value: to paren! value]
				
				--assert value == test value
				--assert (index? value) == index? test value
			]
		
		--test-- "map"
			maps: [#() #(a b) #("abcd" #(<de> [f g]))]
			forall maps [--assert maps/1 == test maps/1]
			
			loop 10 [
				value to map! collect [
					loop (random 50) << 1 [
						keep rejoin collect [loop random 100 [keep to char! random 10'000]]
					]
				]
				
				--assert value == test value
			]
		
		--test-- "any-path"
			paths: [a/b :c/(d) 'e/f/(g/:h)/:i]
			forall paths [--assert paths/1 == test paths/1]
		
		--test-- "all-word"
			values: [a 'b :c d: /e #f]
			forall values [--assert values/1 == test values/1]
			
			loop 10 [
				type? value: to get random/only to block! all-word! rejoin collect [
					loop random 100 [keep to char! random 10'000]
				]				
				--assert value == test value
			]
		
	===end-group===

~~~end-file~~~
