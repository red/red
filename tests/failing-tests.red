Red [
	Title:   "Failing Red Tests"
	Author:  "Peter W A Wood"
	File: 	 %failing-tests.red
	Version: 1.0.0
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %../quick-test/quick-test.red

***start-run*** "failing tests"

~~~start-file~~~ "float"

===start-group=== "power"
	--test-- "pow5" --assert 0.0 = power 0.0 -1		;@@ return INF or 0.0 ?
	--test-- "pow6" --assert 0.0 = power -0.0 -1	;@@ return -INF or 0.0 ?
===end-group===

===start-group=== "float-cosine"
	--test-- "float-cosine-3"
		--assert 0.0 = cosine/radians pi / 2
===end-group===

===start-group=== "float-divide"

	--test-- "float-divide 37"          ;; only fails on Windows
		i: 2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? 2.022794416824728e-308 2.2250738585072014e-308 / 1.1
		--assert strict-equal? 2.022794416824728e-308 divide 2.2250738585072014e-308 1.1
		--assert strict-equal? 2.022794416824728e-308 i / j
		--assert strict-equal? 2.022794416824728e-308 divide i j

	--test-- "float-divide 38"			;; only fails on Windows
		i: 2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? -2.022794416824728e-308 2.2250738585072014e-308 / -1.1
		--assert strict-equal? -2.022794416824728e-308 divide 2.2250738585072014e-308 -1.1
		--assert strict-equal? -2.022794416824728e-308 i / j
		--assert strict-equal? -2.022794416824728e-308 divide i j
		
	--test-- "float-divide 47"			;; only fails on Windows
		i: -2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? -2.022794416824728e-308 -2.2250738585072014e-308 / 1.1
		--assert strict-equal? -2.022794416824728e-308 divide -2.2250738585072014e-308 1.1
		--assert strict-equal? -2.022794416824728e-308 i / j
		--assert strict-equal? -2.022794416824728e-308 divide i j

	--test-- "float-divide 48"			;; only fails on Windows
		i: -2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? 2.022794416824728e-308 -2.2250738585072014e-308 / -1.1
		--assert strict-equal? 2.022794416824728e-308 divide -2.2250738585072014e-308 -1.1
		--assert strict-equal? 2.022794416824728e-308 i / j
		--assert strict-equal? 2.022794416824728e-308 divide i j
		
	--test-- "float-divide 111"
		i: 0.0
		j: 0.0
		--assert strict-equal? 1.#NAN 0.0 / 0.0
		--assert strict-equal? 1.#NAN divide 0.0 0.0
		--assert strict-equal? 1.#NAN i / j
		--assert strict-equal? 1.#NAN divide i j
		
===end-group===

~~~end-file~~~

~~~start-file~~~ "append"

===start-group=== "append/dup"
	
;; this test is premature before the introduction of a garbage collector
	
	--test-- "append/dup5"
		--assert false
	comment {
	--assert not error? try [
		ad5-s: copy " "
		append/dup ad5-s #" " 2147483647
		--assert 2147483647 = length? ad5-s
	]
	}
===end-group===

;; these tests are premature before the introduction of a garbage collector
===start-group=== "big strings" 
	--test-- "bg1"
		--assert false
	comment {
		bg1-s: copy ""
		loop 2147483647 [
			append bg1-s #"a"
		]
	--assert 2147483647 = length? bg1-s
		clear bg1-s
	
	--test-- "bg2"
		bg2-s: copy ""
		loop 2147483647 [
			append bg2-s #"é"
		]
	--assert 2147483647 = length? bg2-s
		clear bg2-s
	
	--test-- "bg3"
		bg3-s: copy ""
		loop 2147483647 [
			append bg3-s #"✐"
		]
	--assert 2147483647 = length? bg3-s
		clear bg3-s
	
		--test-- "bg4"
		bg4-s: copy ""
		loop 2147483647 [
			append bg4-s #"^(2710)"
		]
	--assert 2147483647 = length? bg4-s
		clear bg4-s
	}	
===end-group===

~~~end-file~~~

~~~start-file~~~ "find"

===start-group=== "find/any"      ; not yet implemented
	--test-- "find/any"
		--assert not error? try [ find/any "12345" "*" ]
	--test-- "find/any-1"
		;--assert "12345" = find/any "12345" "*"
	--test-- "find/any-2"
		;--assert "12345" = find/any "12345" "?"
	--test-- "find/any-3"
		;--assert "2345" = find/any "12345" "2?4"
	--test-- "find/any-4"
		;--assert "2345" = find/any "12345" "2*"
	--test-- "find/any-5"
		;--assert "e✐" = find/any "abcde✐" "e?"        ;; code point 10000 (decimal)
	--test-- "find/any-6"
		;--assert "e✐f" = find/any "abcde✐f" "?f" 
	--test-- "find/any-7"
		;--assert "e✐" = find/any "abcde✐" "e*" 
	--test-- "find/any-8"
		;--assert "abcde✐f" = find/any "abcde✐f" "*f" 
	--test-- "find/any-9"
		;--assert "e^(010000)" = find/any "abcde^(010000)" "e?"        
	--test-- "find/any-10"
		;--assert "e^(010000)f" = find/any "abcde^(010000)f" "?f" 
	--test-- "find/any-11"
		;--assert "e^(010000)" = find/any "abcde^(010000)" "e*" 
	--test-- "find/any-12"
		;--assert "abcde^(010000)f" = find/any "abcde^(010000)f" "*f" 
===end-group===

===start-group=== "find/with"      ; not yet implemented
	--test-- "find/with"
		--assert not error? try [ find/with "12345" "^(FFFF)" "^(FFFE)^(FFFF)" ]
	--test-- "find/with-1"
		;--assert "12345" = find/with "12345" "^(FFFF)" "^(FFFE)^(FFFF)" 
	--test-- "find/with-2"
		;--assert "12345" = find/with "12345" "^(FFFE)" "^(FFFE)^(FFFF)" 
	--test-- "find/with-3"
		;--assert "2345" = find/with "12345" "2^(FFFE)3" "^(FFFE)^(FFFF)"
	--test-- "find/with-4"
		;--assert "2345" = find/with "12345" "2^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-5"
		;--assert "e✐" = find/with "abcde✐" "e^(FFFE)" "^(FFFE)^(FFFF)"
	--test-- "find/with-6"
		;--assert "e✐f" = find/with "abcde✐f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "find/with-7"
		;--assert "e✐" = find/with "abcde✐" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-8"
		;--assert "abcde✐f" = find/with "abcde✐f" "^(FFFF)f" "^(FFFE)^(FFFF)" 
	--test-- "find/with-9"
		;--assert "e^(010000)" = find/with "abcde^(010000)" "e^(FFFE)" "^(FFFE)^(FFFF)"        
	--test-- "find/with-10"
		;--assert "e^(010000)f" = find/with "abcde^(010000)f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "find/with-11"
		;--assert "e^(010000)" = find/with "abcde^(010000)" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-12"
		;--assert "abcde^(010000)f" = find/with "abcde^(010000)f" "^(FFFF)f" "^(FFFE)^(FFFF)"
===end-group===

~~~end-file~~~

~~~start-file~~~ "integer"

===start-group=== "modulo"

	--test-- "1 // -2147483648"
		i: 1
		j: -2147483648
		--assert not error? try [ strict-equal? 1 1 // -2147483648 ]
		--assert not error? try [ strict-equal? 1 modulo 1 -2147483648 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "1 // 2147483647"
		i: 1
		j: 2147483647
		--assert not error? try [ strict-equal? 1 1 // 2147483647 ]
		--assert not error? try [ strict-equal? 1 modulo 1 2147483647 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "-2147483648 // 1"
		i: -2147483648
		j: 1
		--assert not error? try [ strict-equal? 0 -2147483648 // 1 ]
		--assert not error? try [ strict-equal? 0 modulo -2147483648 1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	
	--test-- "-2147483648 // 2147483647"
		i: -2147483648
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483646 -2147483648 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483646 modulo -2147483648 2147483647 ]
		--assert not error? try [ strict-equal? 2147483646 i // j ]
		--assert not error? try [ strict-equal? 2147483646 modulo i j ]

	--test-- "-2147483648 // -7"
		i: -2147483648
		j: -7
		--assert not error? try [ strict-equal? 5 -2147483648 // -7 ]
		--assert not error? try [ strict-equal? 5 modulo -2147483648 -7 ]
		--assert not error? try [ strict-equal? 5 i // j ]
		--assert not error? try [ strict-equal? 5 modulo i j ]

	--test-- "-2147483648 // -8"
		i: -2147483648
		j: -8
		--assert not error? try [ strict-equal? 0 -2147483648 // -8 ]
		--assert not error? try [ strict-equal? 0 modulo -2147483648 -8 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "-2147483648 // -10"
		i: -2147483648
		j: -10
		--assert not error? try [ strict-equal? 2 -2147483648 // -10 ]
		--assert not error? try [ strict-equal? 2 modulo -2147483648 -10 ]
		--assert not error? try [ strict-equal? 2 i // j ]
		--assert not error? try [ strict-equal? 2 modulo i j ]

	--test-- "2147483647 // 1"
		i: 2147483647
		j: 1
		--assert not error? try [ strict-equal? 0 2147483647 // 1 ]
		--assert not error? try [ strict-equal? 0 modulo 2147483647 1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "2147483647 // -1"
		i: 2147483647
		j: -1
		--assert not error? try [ strict-equal? 0 2147483647 // -1 ]
		--assert not error? try [ strict-equal? 0 modulo 2147483647 -1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "2147483647 // -2147483648"
		i: 2147483647
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483647 2147483647 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483647 modulo 2147483647 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483647 i // j ]
		--assert not error? try [ strict-equal? 2147483647 modulo i j ]

	--test-- "2147483647 // -7"
		i: 2147483647
		j: -7
		--assert not error? try [ strict-equal? 1 2147483647 // -7 ]
		--assert not error? try [ strict-equal? 1 modulo 2147483647 -7 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "2147483647 // -8"
		i: 2147483647
		j: -8
		--assert not error? try [ strict-equal? 7 2147483647 // -8 ]
		--assert not error? try [ strict-equal? 7 modulo 2147483647 -8 ]
		--assert not error? try [ strict-equal? 7 i // j ]
		--assert not error? try [ strict-equal? 7 modulo i j ]

	--test-- "2147483647 // -10"
		i: 2147483647
		j: -10
		--assert not error? try [ strict-equal? 7 2147483647 // -10 ]
		--assert not error? try [ strict-equal? 7 modulo 2147483647 -10 ]
		--assert not error? try [ strict-equal? 7 i // j ]
		--assert not error? try [ strict-equal? 7 modulo i j ]
		
	--test-- "-7 // -2147483648"
		i: -7
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483641 -7 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483641 modulo -7 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483641 i // j ]
		--assert not error? try [ strict-equal? 2147483641 modulo i j ]

	--test-- "-7 // 2147483647"
		i: -7
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483640 -7 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483640 modulo -7 2147483647 ]
		--assert not error? try [ strict-equal? 2147483640 i // j ]
		--assert not error? try [ strict-equal? 2147483640 modulo i j ]
		
	--test-- "-8 // -2147483648"
		i: -8
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483640 -8 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483640 modulo -8 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483640 i // j ]
		--assert not error? try [ strict-equal? 2147483640 modulo i j ]

	--test-- "-8 // 2147483647"
		i: -8
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483639 -8 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483639 modulo -8 2147483647 ]
		--assert not error? try [ strict-equal? 2147483639 i // j ]
		--assert not error? try [ strict-equal? 2147483639 modulo i j ]

	--test-- "-10 // -2147483648"
		i: -10
		j: -2147483648
		--assert error? try [ strict-equal? 2147483638 -10 // -2147483648 ]
		--assert error? try [ strict-equal? 2147483638 modulo -10 -2147483648 ]
		--assert error? try [ strict-equal? 2147483638 i // j ]
		--assert error? try [ strict-equal? 2147483638 modulo i j ]

	--test-- "-10 // 2147483647"
		i: -10
		j: 2147483647
		--assert error? try [ strict-equal? 2147483637 -10 // 2147483647 ]
		--assert error? try [ strict-equal? 2147483637 modulo -10 2147483647 ]
		--assert error? try [ strict-equal? 2147483637 i // j ]
		--assert error? try [ strict-equal? 2147483637 modulo i j ]

===end-group===

~~~end-file~~~

~~~start-file~~~ "lexer.test"

===start-group=== "lexer-time"

	;;red
	--test-- "lexer-time-1" 
		--assert [2147483645:59:59]	= load/all {2147483645:59:59}
	;;der
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "object"

===start-group=== "nested objects"
	--test-- "no5"
		--assert false
		comment{
		no5-o1: make object! [
			o2: make object! [
			o3: make object! [
			o4: make object! [
			o5: make object! [
			o6: make object! [
			o7: make object! [
			o8: make object! [
			o9: make object! [
			o10: make object! [
			o11: make object! [
			o12: make object! [
			o13: make object! [
			o14: make object! [
			o15: make object! [
				i: 1
			]]]]]]]]]]]]]]
		]

		--assert no5-o1/o2/o3/o4/o5/o6/o7/o8/o9/o10/o11/o12/o13/o14/o15/i = 1 
		}
		
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "pair"

===start-group=== "pair - multiply"
	; awaiting integer! to float! promotion			
	--test-- "pmul-3"
		pmul3-p: 2x2
		--assert not error? try[ pmul3-p * 2147483647x2147483647 ]
		
	--test-- "pmul-4"
		pmul4-p: -3x-3
		--assert not error? try [ pmul4-p * -2147483648 ]
	
===end-group===

===start-group=== "pair - negate"
		
; awaiting integer! to float! promotion		
	--test-- "pneg-4"
		pneg4-p: -2147483648x-2147483648
		--assert not error? try [ negate pneg4-p ]
		
===end-group===

~~~end-file~~~

~~~start-file~~~ "reactivity"
===start-group=== "IS function"

 --test-- "is-7"
		--assert not error? try [
			d: make reactor! [x: is [y + 1] y: is [x + 3]]
			--assert none? d/x
			--assert none? d/y
			d/x: 1
			--assert d/x = 5
			--assert d/y = 4
		]

===end-group===

~~~end-file~~~

~~~start-file~~~ "select"

===start-group=== "select/any"      ; not yet implemented
	--test-- "select/any-1"
	;--assert none = select/any "12345" "*"
	--test-- "select/any-2"
	;--assert #"2" = select/any "12345" "?"
	--test-- "select/any-3"
	;--assert #"5" = select/any "12345" "2?4"
	--test-- "select/any-4"
	;assert none = select/any "12345" "2*"
	--test-- "select/any-5"
	;assert "" = select/any "abcde✐f" "e?"        ;; code point 10000 (decimal)
	--test-- "select/any-6"
	;assert "g" = select/any "abcde✐fg" "?f" 
	--test-- "select/any-7"
	;assert none = select/any "abcde✐" "e*" 
	--test-- "select/any-8"
	;assert "g" = select/any "abcde✐fg" "*f" 
	--test-- "select/any-9"
	;assert "f" = select/any "abcde^(010000)f" "e?"        
	--test-- "select/any-10"
	;assert "g" = select/any "abcde^(010000)fg" "?f" 
	--test-- "select/any-11"
	;assert none = select/any "abcde^(010000)" "e*" 
	--test-- "select/any-12"
	;assert "g" = select/any "abcde^(010000)fg" "*f" 
===end-group===

===start-group=== "select/with"      ; not yet implemented
	--test-- "select/with-1"
	;--assert #"2" = select/with "12345" "^(FFFF)" "^(FFFE)^(FFFF)" 
	--test-- "select/with-2"
	;--assert none = select/with "12345" "^(FFFE)" "^(FFFE)^(FFFF)" 
	--test-- "select/with-3"
	;--assert #"4" = select/with "12345" "2^(FFFE)3" "^(FFFE)^(FFFF)"
	--test-- "select/with-4"
	;assert #"3" = select/with "12345" "2^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-5"
	;assert none = select/with "abcde✐" "e^(FFFE)" "^(FFFE)^(FFFF)"
	--test-- "select/with-6"
	;assert #"g" = select/with "abcde✐fg" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "select/with-7"
	;assert #"f" = select/with "abcde✐f" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-8"
	;assert #"g" = select/with "abcde✐fg" "^(FFFF)f" "^(FFFE)^(FFFF)" 
	--test-- "select/with-9"
	;assert none = select/with "abcde^(010000)" "e^(FFFE)" "^(FFFE)^(FFFF)"        
	--test-- "select/with-10"
	;assert #"g" = select/with "abcde^(010000)f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "select/with-11"
	;assert #"f" = select/with "abcde^(010000)" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-12"
	;assert #"g" = select/with "abcde^(010000)f" "^(FFFF)f" "^(FFFE)^(FFFF)"
===end-group===

~~~end-file~~~

~~~start-file~~~ "Switch"

===start-group=== "switch-all"			;; not sure if it will be implemented.
	
	--test-- "switch-all-1" 
	--assert false
		comment {
		sa1-i: 1
		sa1-j: 0
		;switch/all sa1-i [
			0	[sa1-j: sa1-j + 1]
			1	[sa1-j: sa1-j + 2]
			2	[sa1-j: sa1-j + 4]
		]
	    --assert sa1-j = 6 
	    }
	
===end-group===

~~~end-file~~~

***end-run***