Red [
	Title:   "Red/System integer! datatype tests"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %integer-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; These supplement the bulk of the integer tests which are automatically
;; generated.

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "integer"

===start-group=== "absolute"
	--test-- "abs1" --assert 0 = absolute 0
	--test-- "abs2" --assert 1 = absolute 1
	--test-- "abs3" --assert 1 = absolute -1
	--test-- "abs4" --assert 2147483647 = absolute -2147483647
	--test-- "abs5" --assert 2147483647 = absolute 2147483647
===end-group===

===start-group=== "power"
	--test-- "pow1" --assert 3 	 = power  3 1
	--test-- "pow2" --assert 9 	 = power -3 2
	--test-- "pow3" --assert -27 = power -3 3
	--test-- "pow4" --assertf~= -0.3333333333333333 (power -3 -1) 1E-13
	--test-- "pow5" --assert -1  = power -1 3
	--test-- "pow6" --assert 1	 = power -1 -4
	;--test-- "pow7" --assert 0.0 = power 0 -1		;@@ return INF or 0.0
===end-group===

===start-group=== "max/min"
	--test-- "max1" --assert 3 	 = max  3 1
	--test-- "min1" --assert -3  = min -3 2
===end-group===

===start-group=== "negative?/positive?"
	--test-- "neg1" --assert true  = negative? -1
	--test-- "neg2" --assert false = negative? 0
	--test-- "neg3" --assert false = negative? 1
	--test-- "pos1" --assert true  = positive? 1
	--test-- "pos2" --assert false = positive? 0
	--test-- "pos3" --assert false = positive? -1
===end-group===

===start-group=== "complemented"
	--test-- "comp-1" --assert -2 = complement 1
	--test-- "comp-2" --assert -1 = complement 0
	--test-- "comp-3" --assert 0  = complement FFFFFFFFh
===end-group===

===start-group=== "shift"
	--test-- "shift-1" --assert 1  = shift 2 1
	--test-- "shift-2" --assert 16 = shift/left 2 3
	--test-- "shift-3" --assert FFFFFFFEh = shift FFFFFFFCh 1
	--test-- "shift-4" --assert 7FFFFFFEh = shift/logical FFFFFFFCh 1
===end-group===

===start-group=== "shift op!"
	--test-- "shift-op-1" --assert 2 >> 1 = 1
	--test-- "shift-op-2" --assert 2 << 3 = 16
	--test-- "shift-op-3" --assert FFFFFFFCh >> 1 = FFFFFFFEh
	--test-- "shift-op-4" --assert FFFFFFFCh >>> 1 = 7FFFFFFEh
===end-group===

===start-group=== "and"
	--test-- "and1" --assert 01h and 10h = 00h
	--test-- "and2" --assert 11h and 10h = 10h
	--test-- "and3" --assert 01h and 1Fh = 01h
===end-group===

===start-group=== "or"
	--test-- "or1" --assert  01h or 10h  = 11h
	--test-- "or2" --assert  11h or 10h  = 11h
	--test-- "or3" --assert  01h or 1Fh  = 1Fh
===end-group===

===start-group=== "xor"
	--test-- "xor1" --assert 01h xor 10h = 11h
	--test-- "xor2" --assert 11h xor 10h = 01h
	--test-- "xor3" --assert 01h xor 1Fh = 1Eh
===end-group===

===start-group=== "random"
	--test-- "random1" --assert 1 = random 1
	--test-- "random2" --assert 2 = random/only next [1 2]
	--test-- "random3" --assert not negative? random 1
===end-group===

===start-group=== "round"
	--test-- "round1" --assert  123904 = round/to  123'456 1024
	--test-- "round2" --assert -123904 = round/to -123'456 1024

	--test-- "round3" --assert  21 = round/down/to  23 3
	--test-- "round4" --assert -21 = round/down/to -23 3

	--test-- "round5" --assert  24 = round/even/to  23 3
	--test-- "round6" --assert -24 = round/even/to -23 3

	--test-- "round7" --assert  24 = round/half-down/to  23 3
	--test-- "round8" --assert -24 = round/half-down/to -23 3

	--test-- "round9" --assert  21 = round/floor/to  23 3
	--test-- "round10" --assert -24 = round/floor/to -23 3

	--test-- "round11" --assert  24 = round/ceiling/to  23 3
	--test-- "round12" --assert -21 = round/ceiling/to -23 3

	--test-- "round13" --assert  24 = round/half-ceiling/to  23 3
	--test-- "round14" --assert -24 = round/half-ceiling/to -23 3
===end-group===

===start-group=== "with other datatypes"
	--test-- "tuple1" --assert 3 * 1.4.8 = 3.12.24
	--test-- "tuple2" --assert 3 + 1.4.8 = 4.7.11
	--test-- "pair1"  --assert 3 + 2x3 = 5x6
	--test-- "pair1"  --assert 3 * 2x3 = 6x9
===end-group===

===start-group=== "add"
	--test-- "0 + 1"
		i: 0
		j: 1
		--assert strict-equal? 1 0 + 1
		--assert strict-equal? 1 add 0 1
		--assert strict-equal? 1 i + j
		--assert strict-equal? 1 add i j

	--test-- "0 + -1"
		i: 0
		j: -1
		--assert strict-equal? -1 0 + -1
		--assert strict-equal? -1 add 0 -1
		--assert strict-equal? -1 i + j
		--assert strict-equal? -1 add i j

	--test-- "0 + -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? -2147483648 0 + -2147483648
		--assert strict-equal? -2147483648 add 0 -2147483648
		--assert strict-equal? -2147483648 i + j
		--assert strict-equal? -2147483648 add i j

	--test-- "0 + 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 2147483647 0 + 2147483647
		--assert strict-equal? 2147483647 add 0 2147483647
		--assert strict-equal? 2147483647 i + j
		--assert strict-equal? 2147483647 add i j

	--test-- "0 + 65536"
		i: 0
		j: 65536
		--assert strict-equal? 65536 0 + 65536
		--assert strict-equal? 65536 add 0 65536
		--assert strict-equal? 65536 i + j
		--assert strict-equal? 65536 add i j

	--test-- "0 + 256"
		i: 0
		j: 256
		--assert strict-equal? 256 0 + 256
		--assert strict-equal? 256 add 0 256
		--assert strict-equal? 256 i + j
		--assert strict-equal? 256 add i j

	--test-- "0 + 16777216"
		i: 0
		j: 16777216
		--assert strict-equal? 16777216 0 + 16777216
		--assert strict-equal? 16777216 add 0 16777216
		--assert strict-equal? 16777216 i + j
		--assert strict-equal? 16777216 add i j

	--test-- "1 + -1"
		i: 1
		j: -1
		--assert strict-equal? 0 1 + -1
		--assert strict-equal? 0 add 1 -1
		--assert strict-equal? 0 i + j
		--assert strict-equal? 0 add i j

	--test-- "1 + -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? -2147483647 1 + -2147483648
		--assert strict-equal? -2147483647 add 1 -2147483648
		--assert strict-equal? -2147483647 i + j
		--assert strict-equal? -2147483647 add i j

	--test-- "1 + 2147483647"
		i: 1
		j: 2147483647
		--assert error? try [1 + 2147483647]
		--assert error? try [add 1 2147483647]
		--assert error? try [i + j]
		--assert error? try [add i j]

	--test-- "1 + 65536"
		i: 1
		j: 65536
		--assert strict-equal? 65537 1 + 65536
		--assert strict-equal? 65537 add 1 65536
		--assert strict-equal? 65537 i + j
		--assert strict-equal? 65537 add i j

	--test-- "1 + 256"
		i: 1
		j: 256
		--assert strict-equal? 257 1 + 256
		--assert strict-equal? 257 add 1 256
		--assert strict-equal? 257 i + j
		--assert strict-equal? 257 add i j

	--test-- "1 + 16777216"
		i: 1
		j: 16777216
		--assert strict-equal? 16777217 1 + 16777216
		--assert strict-equal? 16777217 add 1 16777216
		--assert strict-equal? 16777217 i + j
		--assert strict-equal? 16777217 add i j

	--test-- "-1 + -2147483648"
		i: -1
		j: -2147483648
		--assert error? try [-1 + -2147483648]
		--assert error? try [add -1 -2147483648]
		--assert error? try [i + j]
		--assert error? try [add i j]

	--test-- "-1 + 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? 2147483646 -1 + 2147483647
		--assert strict-equal? 2147483646 add -1 2147483647
		--assert strict-equal? 2147483646 i + j
		--assert strict-equal? 2147483646 add i j

	--test-- "-1 + 65536"
		i: -1
		j: 65536
		--assert strict-equal? 65535 -1 + 65536
		--assert strict-equal? 65535 add -1 65536
		--assert strict-equal? 65535 i + j
		--assert strict-equal? 65535 add i j

	--test-- "-1 + 256"
		i: -1
		j: 256
		--assert strict-equal? 255 -1 + 256
		--assert strict-equal? 255 add -1 256
		--assert strict-equal? 255 i + j
		--assert strict-equal? 255 add i j

	--test-- "-1 + 16777216"
		i: -1
		j: 16777216
		--assert strict-equal? 16777215 -1 + 16777216
		--assert strict-equal? 16777215 add -1 16777216
		--assert strict-equal? 16777215 i + j
		--assert strict-equal? 16777215 add i j

	--test-- "-2147483648 + 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? -1 -2147483648 + 2147483647
		--assert strict-equal? -1 add -2147483648 2147483647
		--assert strict-equal? -1 i + j
		--assert strict-equal? -1 add i j

	--test-- "-2147483648 + 65536"
		i: -2147483648
		j: 65536
		--assert strict-equal? -2147418112 -2147483648 + 65536
		--assert strict-equal? -2147418112 add -2147483648 65536
		--assert strict-equal? -2147418112 i + j
		--assert strict-equal? -2147418112 add i j

	--test-- "-2147483648 + 256"
		i: -2147483648
		j: 256
		--assert strict-equal? -2147483392 -2147483648 + 256
		--assert strict-equal? -2147483392 add -2147483648 256
		--assert strict-equal? -2147483392 i + j
		--assert strict-equal? -2147483392 add i j

	--test-- "-2147483648 + 16777216"
		i: -2147483648
		j: 16777216
		--assert strict-equal? -2130706432 -2147483648 + 16777216
		--assert strict-equal? -2130706432 add -2147483648 16777216
		--assert strict-equal? -2130706432 i + j
		--assert strict-equal? -2130706432 add i j

	--test-- "2147483647 + 65536"
		i: 2147483647
		j: 65536
		--assert error? try [2147483647 + 65536]
		--assert error? try [add 2147483647 65536]
		--assert error? try [i + j]
		--assert error? try [add i j]

	--test-- "2147483647 + 256"
		i: 2147483647
		j: 256
		--assert error? try [2147483647 + 256]
		--assert error? try [add 2147483647 256]
		--assert error? try [i + j]
		--assert error? try [add i j]

	--test-- "2147483647 + 16777216"
		i: 2147483647
		j: 16777216
		--assert error? try [2147483647 + 16777216]
		--assert error? try [add 2147483647 16777216]
		--assert error? try [i + j]
		--assert error? try [add i j]

	--test-- "65536 + 256"
		i: 65536
		j: 256
		--assert strict-equal? 65792 65536 + 256
		--assert strict-equal? 65792 add 65536 256
		--assert strict-equal? 65792 i + j
		--assert strict-equal? 65792 add i j

	--test-- "65536 + 16777216"
		i: 65536
		j: 16777216
		--assert strict-equal? 16842752 65536 + 16777216
		--assert strict-equal? 16842752 add 65536 16777216
		--assert strict-equal? 16842752 i + j
		--assert strict-equal? 16842752 add i j

	--test-- "256 + 16777216"
		i: 256
		j: 16777216
		--assert strict-equal? 16777472 256 + 16777216
		--assert strict-equal? 16777472 add 256 16777216
		--assert strict-equal? 16777472 i + j
		--assert strict-equal? 16777472 add i j

===end-group===

===start-group=== "subtract"

	--test-- "0 - 1"
		i: 0
		j: 1
		--assert strict-equal? -1 0 - 1
		--assert strict-equal? -1 subtract 0 1
		--assert strict-equal? -1 i - j
		--assert strict-equal? -1 subtract i j

	--test-- "0 - -1"
		i: 0
		j: -1
		--assert strict-equal? 1 0 - -1
		--assert strict-equal? 1 subtract 0 -1
		--assert strict-equal? 1 i - j
		--assert strict-equal? 1 subtract i j

	--test-- "0 - -2147483648"
		i: 0
		j: -2147483648
		--assert error? try [0 - -2147483648]
		--assert error? try [subtract 0 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "0 - 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? -2147483647 0 - 2147483647
		--assert strict-equal? -2147483647 subtract 0 2147483647
		--assert strict-equal? -2147483647 i - j
		--assert strict-equal? -2147483647 subtract i j

	--test-- "0 - 65536"
		i: 0
		j: 65536
		--assert strict-equal? -65536 0 - 65536
		--assert strict-equal? -65536 subtract 0 65536
		--assert strict-equal? -65536 i - j
		--assert strict-equal? -65536 subtract i j

	--test-- "0 - 256"
		i: 0
		j: 256
		--assert strict-equal? -256 0 - 256
		--assert strict-equal? -256 subtract 0 256
		--assert strict-equal? -256 i - j
		--assert strict-equal? -256 subtract i j

	--test-- "0 - 16777216"
		i: 0
		j: 16777216
		--assert strict-equal? -16777216 0 - 16777216
		--assert strict-equal? -16777216 subtract 0 16777216
		--assert strict-equal? -16777216 i - j
		--assert strict-equal? -16777216 subtract i j

	--test-- "1 - 0"
		i: 1
		j: 0
		--assert strict-equal? 1 1 - 0
		--assert strict-equal? 1 subtract 1 0
		--assert strict-equal? 1 i - j
		--assert strict-equal? 1 subtract i j

	--test-- "1 - -1"
		i: 1
		j: -1
		--assert strict-equal? 2 1 - -1
		--assert strict-equal? 2 subtract 1 -1
		--assert strict-equal? 2 i - j
		--assert strict-equal? 2 subtract i j

	--test-- "1 - -2147483648"
		i: 1
		j: -2147483648
		--assert error? try [1 - -2147483648]
		--assert error? try [subtract 1 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "1 - 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? -2147483646 1 - 2147483647
		--assert strict-equal? -2147483646 subtract 1 2147483647
		--assert strict-equal? -2147483646 i - j
		--assert strict-equal? -2147483646 subtract i j

	--test-- "1 - 65536"
		i: 1
		j: 65536
		--assert strict-equal? -65535 1 - 65536
		--assert strict-equal? -65535 subtract 1 65536
		--assert strict-equal? -65535 i - j
		--assert strict-equal? -65535 subtract i j

	--test-- "1 - 256"
		i: 1
		j: 256
		--assert strict-equal? -255 1 - 256
		--assert strict-equal? -255 subtract 1 256
		--assert strict-equal? -255 i - j
		--assert strict-equal? -255 subtract i j

	--test-- "1 - 16777216"
		i: 1
		j: 16777216
		--assert strict-equal? -16777215 1 - 16777216
		--assert strict-equal? -16777215 subtract 1 16777216
		--assert strict-equal? -16777215 i - j
		--assert strict-equal? -16777215 subtract i j

	--test-- "-1 - 0"
		i: -1
		j: 0
		--assert strict-equal? -1 -1 - 0
		--assert strict-equal? -1 subtract -1 0
		--assert strict-equal? -1 i - j
		--assert strict-equal? -1 subtract i j

	--test-- "-1 - 1"
		i: -1
		j: 1
		--assert strict-equal? -2 -1 - 1
		--assert strict-equal? -2 subtract -1 1
		--assert strict-equal? -2 i - j
		--assert strict-equal? -2 subtract i j

	--test-- "-1 - -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? 2147483647 -1 - -2147483648
		--assert strict-equal? 2147483647 subtract -1 -2147483648
		--assert strict-equal? 2147483647 i - j
		--assert strict-equal? 2147483647 subtract i j

	--test-- "-1 - 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? -2147483648 -1 - 2147483647
		--assert strict-equal? -2147483648 subtract -1 2147483647
		--assert strict-equal? -2147483648 i - j
		--assert strict-equal? -2147483648 subtract i j

	--test-- "-1 - 65536"
		i: -1
		j: 65536
		--assert strict-equal? -65537 -1 - 65536
		--assert strict-equal? -65537 subtract -1 65536
		--assert strict-equal? -65537 i - j
		--assert strict-equal? -65537 subtract i j

	--test-- "-1 - 256"
		i: -1
		j: 256
		--assert strict-equal? -257 -1 - 256
		--assert strict-equal? -257 subtract -1 256
		--assert strict-equal? -257 i - j
		--assert strict-equal? -257 subtract i j

	--test-- "-1 - 16777216"
		i: -1
		j: 16777216
		--assert strict-equal? -16777217 -1 - 16777216
		--assert strict-equal? -16777217 subtract -1 16777216
		--assert strict-equal? -16777217 i - j
		--assert strict-equal? -16777217 subtract i j

	--test-- "-2147483648 - 0"
		i: -2147483648
		j: 0
		--assert strict-equal? -2147483648 -2147483648 - 0
		--assert strict-equal? -2147483648 subtract -2147483648 0
		--assert strict-equal? -2147483648 i - j
		--assert strict-equal? -2147483648 subtract i j

	--test-- "-2147483648 - 1"
		i: -2147483648
		j: 1
		--assert error? try [-2147483648 - 1]
		--assert error? try [subtract -2147483648 1]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "-2147483648 - -1"
		i: -2147483648
		j: -1
		--assert strict-equal? -2147483647 -2147483648 - -1
		--assert strict-equal? -2147483647 subtract -2147483648 -1
		--assert strict-equal? -2147483647 i - j
		--assert strict-equal? -2147483647 subtract i j

	--test-- "-2147483648 - 2147483647"
		i: -2147483648
		j: 2147483647
		--assert error? try [-2147483648 - 2147483647]
		--assert error? try [subtract -2147483648 2147483647]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "-2147483648 - 65536"
		i: -2147483648
		j: 65536
		--assert error? try [-2147483648 - 65536]
		--assert error? try [subtract -2147483648 65536]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "-2147483648 - 256"
		i: -2147483648
		j: 256
		--assert error? try [-2147483648 - 256]
		--assert error? try [subtract -2147483648 256]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "-2147483648 - 16777216"
		i: -2147483648
		j: 16777216
		--assert error? try [-2147483648 - 16777216]
		--assert error? try [subtract -2147483648 16777216]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "2147483647 - 0"
		i: 2147483647
		j: 0
		--assert strict-equal? 2147483647 2147483647 - 0
		--assert strict-equal? 2147483647 subtract 2147483647 0
		--assert strict-equal? 2147483647 i - j
		--assert strict-equal? 2147483647 subtract i j

	--test-- "2147483647 - 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 2147483646 2147483647 - 1
		--assert strict-equal? 2147483646 subtract 2147483647 1
		--assert strict-equal? 2147483646 i - j
		--assert strict-equal? 2147483646 subtract i j

	--test-- "2147483647 - -1"
		i: 2147483647
		j: -1
		--assert error? try [2147483647 - -1]
		--assert error? try [subtract 2147483647 -1]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "2147483647 - -2147483648"
		i: 2147483647
		j: -2147483648
		--assert error? try [2147483647 - -2147483648]
		--assert error? try [subtract 2147483647 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "2147483647 - 65536"
		i: 2147483647
		j: 65536
		--assert strict-equal? 2147418111 2147483647 - 65536
		--assert strict-equal? 2147418111 subtract 2147483647 65536
		--assert strict-equal? 2147418111 i - j
		--assert strict-equal? 2147418111 subtract i j

	--test-- "2147483647 - 256"
		i: 2147483647
		j: 256
		--assert strict-equal? 2147483391 2147483647 - 256
		--assert strict-equal? 2147483391 subtract 2147483647 256
		--assert strict-equal? 2147483391 i - j
		--assert strict-equal? 2147483391 subtract i j

	--test-- "2147483647 - 16777216"
		i: 2147483647
		j: 16777216
		--assert strict-equal? 2130706431 2147483647 - 16777216
		--assert strict-equal? 2130706431 subtract 2147483647 16777216
		--assert strict-equal? 2130706431 i - j
		--assert strict-equal? 2130706431 subtract i j

	--test-- "65536 - 0"
		i: 65536
		j: 0
		--assert strict-equal? 65536 65536 - 0
		--assert strict-equal? 65536 subtract 65536 0
		--assert strict-equal? 65536 i - j
		--assert strict-equal? 65536 subtract i j

	--test-- "65536 - 1"
		i: 65536
		j: 1
		--assert strict-equal? 65535 65536 - 1
		--assert strict-equal? 65535 subtract 65536 1
		--assert strict-equal? 65535 i - j
		--assert strict-equal? 65535 subtract i j

	--test-- "65536 - -1"
		i: 65536
		j: -1
		--assert strict-equal? 65537 65536 - -1
		--assert strict-equal? 65537 subtract 65536 -1
		--assert strict-equal? 65537 i - j
		--assert strict-equal? 65537 subtract i j

	--test-- "65536 - -2147483648"
		i: 65536
		j: -2147483648
		--assert error? try [65536 - -2147483648]
		--assert error? try [subtract 65536 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "65536 - 2147483647"
		i: 65536
		j: 2147483647
		--assert strict-equal? -2147418111 65536 - 2147483647
		--assert strict-equal? -2147418111 subtract 65536 2147483647
		--assert strict-equal? -2147418111 i - j
		--assert strict-equal? -2147418111 subtract i j

	--test-- "65536 - 256"
		i: 65536
		j: 256
		--assert strict-equal? 65280 65536 - 256
		--assert strict-equal? 65280 subtract 65536 256
		--assert strict-equal? 65280 i - j
		--assert strict-equal? 65280 subtract i j

	--test-- "65536 - 16777216"
		i: 65536
		j: 16777216
		--assert strict-equal? -16711680 65536 - 16777216
		--assert strict-equal? -16711680 subtract 65536 16777216
		--assert strict-equal? -16711680 i - j
		--assert strict-equal? -16711680 subtract i j

	--test-- "256 - 0"
		i: 256
		j: 0
		--assert strict-equal? 256 256 - 0
		--assert strict-equal? 256 subtract 256 0
		--assert strict-equal? 256 i - j
		--assert strict-equal? 256 subtract i j

	--test-- "256 - 1"
		i: 256
		j: 1
		--assert strict-equal? 255 256 - 1
		--assert strict-equal? 255 subtract 256 1
		--assert strict-equal? 255 i - j
		--assert strict-equal? 255 subtract i j

	--test-- "256 - -1"
		i: 256
		j: -1
		--assert strict-equal? 257 256 - -1
		--assert strict-equal? 257 subtract 256 -1
		--assert strict-equal? 257 i - j
		--assert strict-equal? 257 subtract i j

	--test-- "256 - -2147483648"
		i: 256
		j: -2147483648
		--assert error? try [256 - -2147483648]
		--assert error? try [subtract 256 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "256 - 2147483647"
		i: 256
		j: 2147483647
		--assert strict-equal? -2147483391 256 - 2147483647
		--assert strict-equal? -2147483391 subtract 256 2147483647
		--assert strict-equal? -2147483391 i - j
		--assert strict-equal? -2147483391 subtract i j

	--test-- "256 - 65536"
		i: 256
		j: 65536
		--assert strict-equal? -65280 256 - 65536
		--assert strict-equal? -65280 subtract 256 65536
		--assert strict-equal? -65280 i - j
		--assert strict-equal? -65280 subtract i j

	--test-- "256 - 16777216"
		i: 256
		j: 16777216
		--assert strict-equal? -16776960 256 - 16777216
		--assert strict-equal? -16776960 subtract 256 16777216
		--assert strict-equal? -16776960 i - j
		--assert strict-equal? -16776960 subtract i j

	--test-- "16777216 - 0"
		i: 16777216
		j: 0
		--assert strict-equal? 16777216 16777216 - 0
		--assert strict-equal? 16777216 subtract 16777216 0
		--assert strict-equal? 16777216 i - j
		--assert strict-equal? 16777216 subtract i j

	--test-- "16777216 - 1"
		i: 16777216
		j: 1
		--assert strict-equal? 16777215 16777216 - 1
		--assert strict-equal? 16777215 subtract 16777216 1
		--assert strict-equal? 16777215 i - j
		--assert strict-equal? 16777215 subtract i j

	--test-- "16777216 - -1"
		i: 16777216
		j: -1
		--assert strict-equal? 16777217 16777216 - -1
		--assert strict-equal? 16777217 subtract 16777216 -1
		--assert strict-equal? 16777217 i - j
		--assert strict-equal? 16777217 subtract i j

	--test-- "16777216 - -2147483648"
		i: 16777216
		j: -2147483648
		--assert error? try [16777216 - -2147483648]
		--assert error? try [subtract 16777216 -2147483648]
		--assert error? try [i - j]
		--assert error? try [subtract i j]

	--test-- "16777216 - 2147483647"
		i: 16777216
		j: 2147483647
		--assert strict-equal? -2130706431 16777216 - 2147483647
		--assert strict-equal? -2130706431 subtract 16777216 2147483647
		--assert strict-equal? -2130706431 i - j
		--assert strict-equal? -2130706431 subtract i j

	--test-- "16777216 - 65536"
		i: 16777216
		j: 65536
		--assert strict-equal? 16711680 16777216 - 65536
		--assert strict-equal? 16711680 subtract 16777216 65536
		--assert strict-equal? 16711680 i - j
		--assert strict-equal? 16711680 subtract i j

	--test-- "16777216 - 256"
		i: 16777216
		j: 256
		--assert strict-equal? 16776960 16777216 - 256
		--assert strict-equal? 16776960 subtract 16777216 256
		--assert strict-equal? 16776960 i - j
		--assert strict-equal? 16776960 subtract i j

===end-group===

===start-group=== "multiply"
	--test-- "0 * 1"
		i: 0
		j: 1
		--assert strict-equal? 0 0 * 1
		--assert strict-equal? 0 multiply 0 1
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * -1"
		i: 0
		j: -1
		--assert strict-equal? 0 0 * -1
		--assert strict-equal? 0 multiply 0 -1
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? 0 0 * -2147483648
		--assert strict-equal? 0 multiply 0 -2147483648
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 0 0 * 2147483647
		--assert strict-equal? 0 multiply 0 2147483647
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * 65536"
		i: 0
		j: 65536
		--assert strict-equal? 0 0 * 65536
		--assert strict-equal? 0 multiply 0 65536
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * 256"
		i: 0
		j: 256
		--assert strict-equal? 0 0 * 256
		--assert strict-equal? 0 multiply 0 256
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "0 * 16777216"
		i: 0
		j: 16777216
		--assert strict-equal? 0 0 * 16777216
		--assert strict-equal? 0 multiply 0 16777216
		--assert strict-equal? 0 i * j
		--assert strict-equal? 0 multiply i j

	--test-- "1 * -1"
		i: 1
		j: -1
		--assert strict-equal? -1 1 * -1
		--assert strict-equal? -1 multiply 1 -1
		--assert strict-equal? -1 i * j
		--assert strict-equal? -1 multiply i j

	--test-- "1 * -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? -2147483648 1 * -2147483648
		--assert strict-equal? -2147483648 multiply 1 -2147483648
		--assert strict-equal? -2147483648 i * j
		--assert strict-equal? -2147483648 multiply i j

	--test-- "1 * 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 2147483647 1 * 2147483647
		--assert strict-equal? 2147483647 multiply 1 2147483647
		--assert strict-equal? 2147483647 i * j
		--assert strict-equal? 2147483647 multiply i j

	--test-- "1 * 65536"
		i: 1
		j: 65536
		--assert strict-equal? 65536 1 * 65536
		--assert strict-equal? 65536 multiply 1 65536
		--assert strict-equal? 65536 i * j
		--assert strict-equal? 65536 multiply i j

	--test-- "1 * 256"
		i: 1
		j: 256
		--assert strict-equal? 256 1 * 256
		--assert strict-equal? 256 multiply 1 256
		--assert strict-equal? 256 i * j
		--assert strict-equal? 256 multiply i j

	--test-- "1 * 16777216"
		i: 1
		j: 16777216
		--assert strict-equal? 16777216 1 * 16777216
		--assert strict-equal? 16777216 multiply 1 16777216
		--assert strict-equal? 16777216 i * j
		--assert strict-equal? 16777216 multiply i j

	--test-- "-1 * -2147483648"
		i: -1
		j: -2147483648
		--assert error? try [-1 * -2147483648]
		--assert error? try [multiply -1 -2147483648]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "-1 * 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? -2147483647 -1 * 2147483647
		--assert strict-equal? -2147483647 multiply -1 2147483647
		--assert strict-equal? -2147483647 i * j
		--assert strict-equal? -2147483647 multiply i j

	--test-- "-1 * 65536"
		i: -1
		j: 65536
		--assert strict-equal? -65536 -1 * 65536
		--assert strict-equal? -65536 multiply -1 65536
		--assert strict-equal? -65536 i * j
		--assert strict-equal? -65536 multiply i j

	--test-- "-1 * 256"
		i: -1
		j: 256
		--assert strict-equal? -256 -1 * 256
		--assert strict-equal? -256 multiply -1 256
		--assert strict-equal? -256 i * j
		--assert strict-equal? -256 multiply i j

	--test-- "-1 * 16777216"
		i: -1
		j: 16777216
		--assert strict-equal? -16777216 -1 * 16777216
		--assert strict-equal? -16777216 multiply -1 16777216
		--assert strict-equal? -16777216 i * j
		--assert strict-equal? -16777216 multiply i j

	--test-- "-2147483648 * 2147483647"
		i: -2147483648
		j: 2147483647
		--assert error? try [-2147483648 * 2147483647]
		--assert error? try [multiply -2147483648 2147483647]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "-2147483648 * 65536"
		i: -2147483648
		j: 65536
		--assert error? try [-2147483648 * 65536]
		--assert error? try [multiply -2147483648 65536]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "-2147483648 * 256"
		i: -2147483648
		j: 256
		--assert error? try [-2147483648 * 256]
		--assert error? try [multiply -2147483648 256]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "-2147483648 * 16777216"
		i: -2147483648
		j: 16777216
		--assert error? try [-2147483648 * 16777216]
		--assert error? try [multiply -2147483648 16777216]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "2147483647 * 65536"
		i: 2147483647
		j: 65536
		--assert error? try [2147483647 * 65536]
		--assert error? try [multiply 2147483647 65536]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "2147483647 * 256"
		i: 2147483647
		j: 256
		--assert error? try [2147483647 * 256]
		--assert error? try [multiply 2147483647 256]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "2147483647 * 16777216"
		i: 2147483647
		j: 16777216
		--assert error? try [2147483647 * 16777216]
		--assert error? try [multiply 2147483647 16777216]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "65536 * 256"
		i: 65536
		j: 256
		--assert strict-equal? 16777216 65536 * 256
		--assert strict-equal? 16777216 multiply 65536 256
		--assert strict-equal? 16777216 i * j
		--assert strict-equal? 16777216 multiply i j

	--test-- "65536 * 16777216"
		i: 65536
		j: 16777216
		--assert error? try [65536 * 16777216]
		--assert error? try [multiply 65536 16777216]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

	--test-- "256 * 16777216"
		i: 256
		j: 16777216
		--assert error? try [256 * 16777216]
		--assert error? try [multiply 256 16777216]
		--assert error? try [i * j]
		--assert error? try [multiply i j]

===end-group===

===start-group=== "divide"

		--test-- "0 / 1"
		i: 0
		j: 1
		--assert strict-equal? 0 0 / 1
		--assert strict-equal? 0 divide 0 1
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / -1"
		i: 0
		j: -1
		--assert strict-equal? 0 0 / -1
		--assert strict-equal? 0 divide 0 -1
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? 0 0 / -2147483648
		--assert strict-equal? 0 divide 0 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 0 0 / 2147483647
		--assert strict-equal? 0 divide 0 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / 65536"
		i: 0
		j: 65536
		--assert strict-equal? 0 0 / 65536
		--assert strict-equal? 0 divide 0 65536
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / 256"
		i: 0
		j: 256
		--assert strict-equal? 0 0 / 256
		--assert strict-equal? 0 divide 0 256
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "0 / 16777216"
		i: 0
		j: 16777216
		--assert strict-equal? 0 0 / 16777216
		--assert strict-equal? 0 divide 0 16777216
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "1 / 0"
		i: 1
		j: 0
		--assert error? try [1 / 0]
		--assert error? try [divide 1 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "1 / -1"
		i: 1
		j: -1
		--assert strict-equal? -1 1 / -1
		--assert strict-equal? -1 divide 1 -1
		--assert strict-equal? -1 i / j
		--assert strict-equal? -1 divide i j

	--test-- "1 / -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? 0 1 / -2147483648
		--assert strict-equal? 0 divide 1 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "1 / 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 0 1 / 2147483647
		--assert strict-equal? 0 divide 1 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "1 / 65536"
		i: 1
		j: 65536
		--assert strict-equal? 0 1 / 65536
		--assert strict-equal? 0 divide 1 65536
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "1 / 256"
		i: 1
		j: 256
		--assert strict-equal? 0 1 / 256
		--assert strict-equal? 0 divide 1 256
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "1 / 16777216"
		i: 1
		j: 16777216
		--assert strict-equal? 0 1 / 16777216
		--assert strict-equal? 0 divide 1 16777216
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-1 / 0"
		i: -1
		j: 0
		--assert error? try [-1 / 0]
		--assert error? try [divide -1 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "-1 / 1"
		i: -1
		j: 1
		--assert strict-equal? -1 -1 / 1
		--assert strict-equal? -1 divide -1 1
		--assert strict-equal? -1 i / j
		--assert strict-equal? -1 divide i j

	--test-- "-1 / -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? 0 -1 / -2147483648
		--assert strict-equal? 0 divide -1 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-1 / 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? 0 -1 / 2147483647
		--assert strict-equal? 0 divide -1 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-1 / 65536"
		i: -1
		j: 65536
		--assert strict-equal? 0 -1 / 65536
		--assert strict-equal? 0 divide -1 65536
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-1 / 256"
		i: -1
		j: 256
		--assert strict-equal? 0 -1 / 256
		--assert strict-equal? 0 divide -1 256
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-1 / 16777216"
		i: -1
		j: 16777216
		--assert strict-equal? 0 -1 / 16777216
		--assert strict-equal? 0 divide -1 16777216
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "-2147483648 / 0"
		i: -2147483648
		j: 0
		--assert error? try [-2147483648 / 0]
		--assert error? try [divide -2147483648 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "-2147483648 / 1"
		i: -2147483648
		j: 1
		--assert strict-equal? -2147483648 -2147483648 / 1
		--assert strict-equal? -2147483648 divide -2147483648 1
		--assert strict-equal? -2147483648 i / j
		--assert strict-equal? -2147483648 divide i j

	--test-- "-2147483648 / -1"
		i: -2147483648
		j: -1
		--assert error? try [-2147483648 / -1]
		--assert error? try [divide -2147483648 -1]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "-2147483648 / 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? -1 -2147483648 / 2147483647
		--assert strict-equal? -1 divide -2147483648 2147483647
		--assert strict-equal? -1 i / j
		--assert strict-equal? -1 divide i j

	--test-- "-2147483648 / 65536"
		i: -2147483648
		j: 65536
		--assert strict-equal? -32768 -2147483648 / 65536
		--assert strict-equal? -32768 divide -2147483648 65536
		--assert strict-equal? -32768 i / j
		--assert strict-equal? -32768 divide i j

	--test-- "-2147483648 / 256"
		i: -2147483648
		j: 256
		--assert strict-equal? -8388608 -2147483648 / 256
		--assert strict-equal? -8388608 divide -2147483648 256
		--assert strict-equal? -8388608 i / j
		--assert strict-equal? -8388608 divide i j

	--test-- "-2147483648 / 16777216"
		i: -2147483648
		j: 16777216
		--assert strict-equal? -128 -2147483648 / 16777216
		--assert strict-equal? -128 divide -2147483648 16777216
		--assert strict-equal? -128 i / j
		--assert strict-equal? -128 divide i j

	--test-- "2147483647 / 0"
		i: 2147483647
		j: 0
		--assert error? try [2147483647 / 0]
		--assert error? try [divide 2147483647 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "2147483647 / 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 2147483647 2147483647 / 1
		--assert strict-equal? 2147483647 divide 2147483647 1
		--assert strict-equal? 2147483647 i / j
		--assert strict-equal? 2147483647 divide i j

	--test-- "2147483647 / -1"
		i: 2147483647
		j: -1
		--assert strict-equal? -2147483647 2147483647 / -1
		--assert strict-equal? -2147483647 divide 2147483647 -1
		--assert strict-equal? -2147483647 i / j
		--assert strict-equal? -2147483647 divide i j

	--test-- "2147483647 / -2147483648"
		i: 2147483647
		j: -2147483648
		--assert strict-equal? 0 2147483647 / -2147483648
		--assert strict-equal? 0 divide 2147483647 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "2147483647 / 65536"
		i: 2147483647
		j: 65536
		--assert strict-equal? 32767 2147483647 / 65536
		--assert strict-equal? 32767 divide 2147483647 65536
		--assert strict-equal? 32767 i / j
		--assert strict-equal? 32767 divide i j

	--test-- "2147483647 / 256"
		i: 2147483647
		j: 256
		--assert strict-equal? 8388607 2147483647 / 256
		--assert strict-equal? 8388607 divide 2147483647 256
		--assert strict-equal? 8388607 i / j
		--assert strict-equal? 8388607 divide i j

	--test-- "2147483647 / 16777216"
		i: 2147483647
		j: 16777216
		--assert strict-equal? 127 2147483647 / 16777216
		--assert strict-equal? 127 divide 2147483647 16777216
		--assert strict-equal? 127 i / j
		--assert strict-equal? 127 divide i j

	--test-- "65536 / 0"
		i: 65536
		j: 0
		--assert error? try [65536 / 0]
		--assert error? try [divide 65536 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "65536 / 1"
		i: 65536
		j: 1
		--assert strict-equal? 65536 65536 / 1
		--assert strict-equal? 65536 divide 65536 1
		--assert strict-equal? 65536 i / j
		--assert strict-equal? 65536 divide i j

	--test-- "65536 / -1"
		i: 65536
		j: -1
		--assert strict-equal? -65536 65536 / -1
		--assert strict-equal? -65536 divide 65536 -1
		--assert strict-equal? -65536 i / j
		--assert strict-equal? -65536 divide i j

	--test-- "65536 / -2147483648"
		i: 65536
		j: -2147483648
		--assert strict-equal? 0 65536 / -2147483648
		--assert strict-equal? 0 divide 65536 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "65536 / 2147483647"
		i: 65536
		j: 2147483647
		--assert strict-equal? 0 65536 / 2147483647
		--assert strict-equal? 0 divide 65536 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "65536 / 256"
		i: 65536
		j: 256
		--assert strict-equal? 256 65536 / 256
		--assert strict-equal? 256 divide 65536 256
		--assert strict-equal? 256 i / j
		--assert strict-equal? 256 divide i j

	--test-- "65536 / 16777216"
		i: 65536
		j: 16777216
		--assert strict-equal? 0 65536 / 16777216
		--assert strict-equal? 0 divide 65536 16777216
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "256 / 0"
		i: 256
		j: 0
		--assert error? try [256 / 0]
		--assert error? try [divide 256 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "256 / 1"
		i: 256
		j: 1
		--assert strict-equal? 256 256 / 1
		--assert strict-equal? 256 divide 256 1
		--assert strict-equal? 256 i / j
		--assert strict-equal? 256 divide i j

	--test-- "256 / -1"
		i: 256
		j: -1
		--assert strict-equal? -256 256 / -1
		--assert strict-equal? -256 divide 256 -1
		--assert strict-equal? -256 i / j
		--assert strict-equal? -256 divide i j

	--test-- "256 / -2147483648"
		i: 256
		j: -2147483648
		--assert strict-equal? 0 256 / -2147483648
		--assert strict-equal? 0 divide 256 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "256 / 2147483647"
		i: 256
		j: 2147483647
		--assert strict-equal? 0 256 / 2147483647
		--assert strict-equal? 0 divide 256 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "256 / 65536"
		i: 256
		j: 65536
		--assert strict-equal? 0 256 / 65536
		--assert strict-equal? 0 divide 256 65536
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "256 / 16777216"
		i: 256
		j: 16777216
		--assert strict-equal? 0 256 / 16777216
		--assert strict-equal? 0 divide 256 16777216
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "16777216 / 0"
		i: 16777216
		j: 0
		--assert error? try [16777216 / 0]
		--assert error? try [divide 16777216 0]
		--assert error? try [i / j]
		--assert error? try [divide i j]

	--test-- "16777216 / 1"
		i: 16777216
		j: 1
		--assert strict-equal? 16777216 16777216 / 1
		--assert strict-equal? 16777216 divide 16777216 1
		--assert strict-equal? 16777216 i / j
		--assert strict-equal? 16777216 divide i j

	--test-- "16777216 / -1"
		i: 16777216
		j: -1
		--assert strict-equal? -16777216 16777216 / -1
		--assert strict-equal? -16777216 divide 16777216 -1
		--assert strict-equal? -16777216 i / j
		--assert strict-equal? -16777216 divide i j

	--test-- "16777216 / -2147483648"
		i: 16777216
		j: -2147483648
		--assert strict-equal? 0 16777216 / -2147483648
		--assert strict-equal? 0 divide 16777216 -2147483648
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "16777216 / 2147483647"
		i: 16777216
		j: 2147483647
		--assert strict-equal? 0 16777216 / 2147483647
		--assert strict-equal? 0 divide 16777216 2147483647
		--assert strict-equal? 0 i / j
		--assert strict-equal? 0 divide i j

	--test-- "16777216 / 65536"
		i: 16777216
		j: 65536
		--assert strict-equal? 256 16777216 / 65536
		--assert strict-equal? 256 divide 16777216 65536
		--assert strict-equal? 256 i / j
		--assert strict-equal? 256 divide i j

	--test-- "16777216 / 256"
		i: 16777216
		j: 256
		--assert strict-equal? 65536 16777216 / 256
		--assert strict-equal? 65536 divide 16777216 256
		--assert strict-equal? 65536 i / j
		--assert strict-equal? 65536 divide i j
		
===end-group===

===start-group=== "remainder"

	--test-- "0 % 1"
		i: 0
		j: 1
		--assert strict-equal? 0 0 % 1
		--assert strict-equal? 0 remainder 0 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % -1"
		i: 0
		j: -1
		--assert strict-equal? 0 0 % -1
		--assert strict-equal? 0 remainder 0 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? 0 0 % -2147483648
		--assert strict-equal? 0 remainder 0 -2147483648
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 0 0 % 2147483647
		--assert strict-equal? 0 remainder 0 2147483647
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % -7"
		i: 0
		j: -7
		--assert strict-equal? 0 0 % -7
		--assert strict-equal? 0 remainder 0 -7
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % -8"
		i: 0
		j: -8
		--assert strict-equal? 0 0 % -8
		--assert strict-equal? 0 remainder 0 -8
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "0 % -10"
		i: 0
		j: -10
		--assert strict-equal? 0 0 % -10
		--assert strict-equal? 0 remainder 0 -10
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j
	
	--test-- "1 % 0"
		i: 1
		j: 0
		--assert error? try [1 % 0]
		--assert error? try [remainder 1 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "1 % -1"
		i: 1
		j: -1
		--assert strict-equal? 0 1 % -1
		--assert strict-equal? 0 remainder 1 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "1 % -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? 1 1 % -2147483648
		--assert strict-equal? 1 remainder 1 -2147483648
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "1 % 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 1 1 % 2147483647
		--assert strict-equal? 1 remainder 1 2147483647
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "1 % -7"
		i: 1
		j: -7
		--assert strict-equal? 1 1 % -7
		--assert strict-equal? 1 remainder 1 -7
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "1 % -8"
		i: 1
		j: -8
		--assert strict-equal? 1 1 % -8
		--assert strict-equal? 1 remainder 1 -8
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "1 % -10"
		i: 1
		j: -10
		--assert strict-equal? 1 1 % -10
		--assert strict-equal? 1 remainder 1 -10
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "-1 % 0"
		i: -1
		j: 0
		--assert error? try [-1 % 0]
		--assert error? try [remainder -1 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "-1 % 1"
		i: -1
		j: 1
		--assert strict-equal? 0 -1 % 1
		--assert strict-equal? 0 remainder -1 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-1 % -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? -1 -1 % -2147483648
		--assert strict-equal? -1 remainder -1 -2147483648
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-1 % 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? -1 -1 % 2147483647
		--assert strict-equal? -1 remainder -1 2147483647
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-1 % -7"
		i: -1
		j: -7
		--assert strict-equal? -1 -1 % -7
		--assert strict-equal? -1 remainder -1 -7
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-1 % -8"
		i: -1
		j: -8
		--assert strict-equal? -1 -1 % -8
		--assert strict-equal? -1 remainder -1 -8
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-1 % -10"
		i: -1
		j: -10
		--assert strict-equal? -1 -1 % -10
		--assert strict-equal? -1 remainder -1 -10
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-2147483648 % 0"
		i: -2147483648
		j: 0
		--assert error? try [-2147483648 % 0]
		--assert error? try [remainder -2147483648 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "-2147483648 % 1"
		i: -2147483648
		j: 1
		--assert strict-equal? 0 -2147483648 % 1
		--assert strict-equal? 0 remainder -2147483648 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-2147483648 % -1"
		i: -2147483648
		j: -1
		;--assert error? try [-2147483648 % -1]
		;--assert error? try [remainder -2147483648 -1]
		;--assert error? try [i % j]
		;--assert error? try [remainder i j]

	--test-- "-2147483648 % 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? -1 -2147483648 % 2147483647
		--assert strict-equal? -1 remainder -2147483648 2147483647
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-2147483648 % -7"
		i: -2147483648
		j: -7
		--assert strict-equal? -2 -2147483648 % -7
		--assert strict-equal? -2 remainder -2147483648 -7
		--assert strict-equal? -2 i % j
		--assert strict-equal? -2 remainder i j

	--test-- "-2147483648 % -8"
		i: -2147483648
		j: -8
		--assert strict-equal? 0 -2147483648 % -8
		--assert strict-equal? 0 remainder -2147483648 -8
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-2147483648 % -10"
		i: -2147483648
		j: -10
		--assert strict-equal? -8 -2147483648 % -10
		--assert strict-equal? -8 remainder -2147483648 -10
		--assert strict-equal? -8 i % j
		--assert strict-equal? -8 remainder i j

	--test-- "2147483647 % 0"
		i: 2147483647
		j: 0
		--assert error? try [2147483647 % 0]
		--assert error? try [remainder 2147483647 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "2147483647 % 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 0 2147483647 % 1
		--assert strict-equal? 0 remainder 2147483647 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "2147483647 % -1"
		i: 2147483647
		j: -1
		--assert strict-equal? 0 2147483647 % -1
		--assert strict-equal? 0 remainder 2147483647 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "2147483647 % -2147483648"
		i: 2147483647
		j: -2147483648
		--assert strict-equal? 2147483647 2147483647 % -2147483648
		--assert strict-equal? 2147483647 remainder 2147483647 -2147483648
		--assert strict-equal? 2147483647 i % j
		--assert strict-equal? 2147483647 remainder i j

	--test-- "2147483647 % -7"
		i: 2147483647
		j: -7
		--assert strict-equal? 1 2147483647 % -7
		--assert strict-equal? 1 remainder 2147483647 -7
		--assert strict-equal? 1 i % j
		--assert strict-equal? 1 remainder i j

	--test-- "2147483647 % -8"
		i: 2147483647
		j: -8
		--assert strict-equal? 7 2147483647 % -8
		--assert strict-equal? 7 remainder 2147483647 -8
		--assert strict-equal? 7 i % j
		--assert strict-equal? 7 remainder i j

	--test-- "2147483647 % -10"
		i: 2147483647
		j: -10
		--assert strict-equal? 7 2147483647 % -10
		--assert strict-equal? 7 remainder 2147483647 -10
		--assert strict-equal? 7 i % j
		--assert strict-equal? 7 remainder i j

	--test-- "-7 % 0"
		i: -7
		j: 0
		--assert error? try [-7 % 0]
		--assert error? try [remainder -7 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "-7 % 1"
		i: -7
		j: 1
		--assert strict-equal? 0 -7 % 1
		--assert strict-equal? 0 remainder -7 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-7 % -1"
		i: -7
		j: -1
		--assert strict-equal? 0 -7 % -1
		--assert strict-equal? 0 remainder -7 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-7 % -2147483648"
		i: -7
		j: -2147483648
		--assert strict-equal? -7 -7 % -2147483648
		--assert strict-equal? -7 remainder -7 -2147483648
		--assert strict-equal? -7 i % j
		--assert strict-equal? -7 remainder i j

	--test-- "-7 % 2147483647"
		i: -7
		j: 2147483647
		--assert strict-equal? -7 -7 % 2147483647
		--assert strict-equal? -7 remainder -7 2147483647
		--assert strict-equal? -7 i % j
		--assert strict-equal? -7 remainder i j

	--test-- "-7 % -8"
		i: -7
		j: -8
		--assert strict-equal? -7 -7 % -8
		--assert strict-equal? -7 remainder -7 -8
		--assert strict-equal? -7 i % j
		--assert strict-equal? -7 remainder i j

	--test-- "-7 % -10"
		i: -7
		j: -10
		--assert strict-equal? -7 -7 % -10
		--assert strict-equal? -7 remainder -7 -10
		--assert strict-equal? -7 i % j
		--assert strict-equal? -7 remainder i j

	--test-- "-8 % 0"
		i: -8
		j: 0
		--assert error? try [-8 % 0]
		--assert error? try [remainder -8 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "-8 % 1"
		i: -8
		j: 1
		--assert strict-equal? 0 -8 % 1
		--assert strict-equal? 0 remainder -8 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-8 % -1"
		i: -8
		j: -1
		--assert strict-equal? 0 -8 % -1
		--assert strict-equal? 0 remainder -8 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-8 % -2147483648"
		i: -8
		j: -2147483648
		--assert strict-equal? -8 -8 % -2147483648
		--assert strict-equal? -8 remainder -8 -2147483648
		--assert strict-equal? -8 i % j
		--assert strict-equal? -8 remainder i j

	--test-- "-8 % 2147483647"
		i: -8
		j: 2147483647
		--assert strict-equal? -8 -8 % 2147483647
		--assert strict-equal? -8 remainder -8 2147483647
		--assert strict-equal? -8 i % j
		--assert strict-equal? -8 remainder i j

	--test-- "-8 % -7"
		i: -8
		j: -7
		--assert strict-equal? -1 -8 % -7
		--assert strict-equal? -1 remainder -8 -7
		--assert strict-equal? -1 i % j
		--assert strict-equal? -1 remainder i j

	--test-- "-8 % -10"
		i: -8
		j: -10
		--assert strict-equal? -8 -8 % -10
		--assert strict-equal? -8 remainder -8 -10
		--assert strict-equal? -8 i % j
		--assert strict-equal? -8 remainder i j

	--test-- "-10 % 0"
		i: -10
		j: 0
		--assert error? try [-10 % 0]
		--assert error? try [remainder -10 0]
		--assert error? try [i % j]
		--assert error? try [remainder i j]

	--test-- "-10 % 1"
		i: -10
		j: 1
		--assert strict-equal? 0 -10 % 1
		--assert strict-equal? 0 remainder -10 1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-10 % -1"
		i: -10
		j: -1
		--assert strict-equal? 0 -10 % -1
		--assert strict-equal? 0 remainder -10 -1
		--assert strict-equal? 0 i % j
		--assert strict-equal? 0 remainder i j

	--test-- "-10 % -2147483648"
		i: -10
		j: -2147483648
		--assert strict-equal? -10 -10 % -2147483648
		--assert strict-equal? -10 remainder -10 -2147483648
		--assert strict-equal? -10 i % j
		--assert strict-equal? -10 remainder i j

	--test-- "-10 % 2147483647"
		i: -10
		j: 2147483647
		--assert strict-equal? -10 -10 % 2147483647
		--assert strict-equal? -10 remainder -10 2147483647
		--assert strict-equal? -10 i % j
		--assert strict-equal? -10 remainder i j

	--test-- "-10 % -7"
		i: -10
		j: -7
		--assert strict-equal? -3 -10 % -7
		--assert strict-equal? -3 remainder -10 -7
		--assert strict-equal? -3 i % j
		--assert strict-equal? -3 remainder i j

	--test-- "-10 % -8"
		i: -10
		j: -8
		--assert strict-equal? -2 -10 % -8
		--assert strict-equal? -2 remainder -10 -8
		--assert strict-equal? -2 i % j
		--assert strict-equal? -2 remainder i j

===end-group===

===start-group=== "modulo"

	--test-- "0 // 1"
		i: 0
		j: 1
		--assert strict-equal? 0 0 // 1
		--assert strict-equal? 0 modulo 0 1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "0 // -1"
		i: 0
		j: -1
		--assert strict-equal? 0 0 // -1
		--assert strict-equal? 0 modulo 0 -1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "0 // -2147483648"
		i: 0
		j: -2147483648
		;--assert strict-equal? 0 0 // -2147483648
		;--assert strict-equal? 0 modulo 0 -2147483648
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "0 // 2147483647"
		i: 0
		j: 2147483647
		;--assert strict-equal? 0 0 // 2147483647
		;--assert strict-equal? 0 modulo 0 2147483647
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "0 // -7"
		i: 0
		j: -7
		--assert strict-equal? 0 0 // -7
		--assert strict-equal? 0 modulo 0 -7
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "0 // -8"
		i: 0
		j: -8
		--assert strict-equal? 0 0 // -8
		--assert strict-equal? 0 modulo 0 -8
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "0 // -10"
		i: 0
		j: -10
		--assert strict-equal? 0 0 // -10
		--assert strict-equal? 0 modulo 0 -10
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "1 // 0"
		i: 1
		j: 0
		--assert error? try [1 // 0]
		--assert error? try [modulo 1 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "1 // -1"
		i: 1
		j: -1
		--assert strict-equal? 0 1 // -1
		--assert strict-equal? 0 modulo 1 -1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "1 // -2147483648"
		i: 1
		j: -2147483648
		;--assert strict-equal? 1 1 // -2147483648
		;--assert strict-equal? 1 modulo 1 -2147483648
		;--assert strict-equal? 1 i // j
		;--assert strict-equal? 1 modulo i j

	--test-- "1 // 2147483647"
		i: 1
		j: 2147483647
		;--assert strict-equal? 1 1 // 2147483647
		;--assert strict-equal? 1 modulo 1 2147483647
		;--assert strict-equal? 1 i // j
		;--assert strict-equal? 1 modulo i j

	--test-- "1 // -7"
		i: 1
		j: -7
		--assert strict-equal? 1 1 // -7
		--assert strict-equal? 1 modulo 1 -7
		--assert strict-equal? 1 i // j
		--assert strict-equal? 1 modulo i j

	--test-- "1 // -8"
		i: 1
		j: -8
		--assert strict-equal? 1 1 // -8
		--assert strict-equal? 1 modulo 1 -8
		--assert strict-equal? 1 i // j
		--assert strict-equal? 1 modulo i j

	--test-- "1 // -10"
		i: 1
		j: -10
		--assert strict-equal? 1 1 // -10
		--assert strict-equal? 1 modulo 1 -10
		--assert strict-equal? 1 i // j
		--assert strict-equal? 1 modulo i j

	--test-- "-1 // 0"
		i: -1
		j: 0
		--assert error? try [-1 // 0]
		--assert error? try [modulo -1 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-1 // 1"
		i: -1
		j: 1
		--assert strict-equal? 0 -1 // 1
		--assert strict-equal? 0 modulo -1 1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-1 // -2147483648"
		i: -1
		j: -2147483648
		;--assert strict-equal? 2147483647 -1 // -2147483648
		;--assert strict-equal? 2147483647 modulo -1 -2147483648
		;--assert strict-equal? 2147483647 i // j
		;--assert strict-equal? 2147483647 modulo i j

	--test-- "-1 // 2147483647"
		i: -1
		j: 2147483647
		;--assert strict-equal? 2147483646 -1 // 2147483647
		;--assert strict-equal? 2147483646 modulo -1 2147483647
		;--assert strict-equal? 2147483646 i // j
		;--assert strict-equal? 2147483646 modulo i j

	--test-- "-1 // -7"
		i: -1
		j: -7
		--assert strict-equal? 6 -1 // -7
		--assert strict-equal? 6 modulo -1 -7
		--assert strict-equal? 6 i // j
		--assert strict-equal? 6 modulo i j

	--test-- "-1 // -8"
		i: -1
		j: -8
		--assert strict-equal? 7 -1 // -8
		--assert strict-equal? 7 modulo -1 -8
		--assert strict-equal? 7 i // j
		--assert strict-equal? 7 modulo i j

	--test-- "-1 // -10"
		i: -1
		j: -10
		--assert strict-equal? 9 -1 // -10
		--assert strict-equal? 9 modulo -1 -10
		--assert strict-equal? 9 i // j
		--assert strict-equal? 9 modulo i j

	--test-- "-2147483648 // 0"
		i: -2147483648
		j: 0
		--assert error? try [-2147483648 // 0]
		--assert error? try [modulo -2147483648 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-2147483648 // 1"
		i: -2147483648
		j: 1
		;--assert strict-equal? 0 -2147483648 // 1
		;--assert strict-equal? 0 modulo -2147483648 1
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "-2147483648 // -1"
		i: -2147483648
		j: -1
		--assert error? try [-2147483648 // -1]
		--assert error? try [modulo -2147483648 -1]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-2147483648 // 2147483647"
		i: -2147483648
		j: 2147483647
		;--assert strict-equal? 2147483646 -2147483648 // 2147483647
		;--assert strict-equal? 2147483646 modulo -2147483648 2147483647
		;--assert strict-equal? 2147483646 i // j
		;--assert strict-equal? 2147483646 modulo i j

	--test-- "-2147483648 // -7"
		i: -2147483648
		j: -7
		;--assert strict-equal? 5 -2147483648 // -7
		;--assert strict-equal? 5 modulo -2147483648 -7
		;--assert strict-equal? 5 i // j
		;--assert strict-equal? 5 modulo i j

	--test-- "-2147483648 // -8"
		i: -2147483648
		j: -8
		;--assert strict-equal? 0 -2147483648 // -8
		;--assert strict-equal? 0 modulo -2147483648 -8
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "-2147483648 // -10"
		i: -2147483648
		j: -10
		;--assert strict-equal? 2 -2147483648 // -10
		;--assert strict-equal? 2 modulo -2147483648 -10
		;--assert strict-equal? 2 i // j
		;--assert strict-equal? 2 modulo i j

	--test-- "2147483647 // 0"
		i: 2147483647
		j: 0
		--assert error? try [2147483647 // 0]
		--assert error? try [modulo 2147483647 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "2147483647 // 1"
		i: 2147483647
		j: 1
		;--assert strict-equal? 0 2147483647 // 1
		;--assert strict-equal? 0 modulo 2147483647 1
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "2147483647 // -1"
		i: 2147483647
		j: -1
		;--assert strict-equal? 0 2147483647 // -1
		;--assert strict-equal? 0 modulo 2147483647 -1
		;--assert strict-equal? 0 i // j
		;--assert strict-equal? 0 modulo i j

	--test-- "2147483647 // -2147483648"
		i: 2147483647
		j: -2147483648
		;--assert strict-equal? 2147483647 2147483647 // -2147483648
		;--assert strict-equal? 2147483647 modulo 2147483647 -2147483648
		;--assert strict-equal? 2147483647 i // j
		;--assert strict-equal? 2147483647 modulo i j

	--test-- "2147483647 // -7"
		i: 2147483647
		j: -7
		;--assert strict-equal? 1 2147483647 // -7
		;--assert strict-equal? 1 modulo 2147483647 -7
		;--assert strict-equal? 1 i // j
		;--assert strict-equal? 1 modulo i j

	--test-- "2147483647 // -8"
		i: 2147483647
		j: -8
		;--assert strict-equal? 7 2147483647 // -8
		;--assert strict-equal? 7 modulo 2147483647 -8
		;--assert strict-equal? 7 i // j
		;--assert strict-equal? 7 modulo i j

	--test-- "2147483647 // -10"
		i: 2147483647
		j: -10
		;--assert strict-equal? 7 2147483647 // -10
		;--assert strict-equal? 7 modulo 2147483647 -10
		;--assert strict-equal? 7 i // j
		;--assert strict-equal? 7 modulo i j

	--test-- "-7 // 0"
		i: -7
		j: 0
		--assert error? try [-7 // 0]
		--assert error? try [modulo -7 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-7 // 1"
		i: -7
		j: 1
		--assert strict-equal? 0 -7 // 1
		--assert strict-equal? 0 modulo -7 1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-7 // -1"
		i: -7
		j: -1
		--assert strict-equal? 0 -7 // -1
		--assert strict-equal? 0 modulo -7 -1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-7 // -2147483648"
		i: -7
		j: -2147483648
		;--assert strict-equal? 2147483641 -7 // -2147483648
		;--assert strict-equal? 2147483641 modulo -7 -2147483648
		;--assert strict-equal? 2147483641 i // j
		;--assert strict-equal? 2147483641 modulo i j

	--test-- "-7 // 2147483647"
		i: -7
		j: 2147483647
		;--assert strict-equal? 2147483640 -7 // 2147483647
		;--assert strict-equal? 2147483640 modulo -7 2147483647
		;--assert strict-equal? 2147483640 i // j
		;--assert strict-equal? 2147483640 modulo i j

	--test-- "-7 // -8"
		i: -7
		j: -8
		--assert strict-equal? 1 -7 // -8
		--assert strict-equal? 1 modulo -7 -8
		--assert strict-equal? 1 i // j
		--assert strict-equal? 1 modulo i j

	--test-- "-7 // -10"
		i: -7
		j: -10
		--assert strict-equal? 3 -7 // -10
		--assert strict-equal? 3 modulo -7 -10
		--assert strict-equal? 3 i // j
		--assert strict-equal? 3 modulo i j

	--test-- "-8 // 0"
		i: -8
		j: 0
		--assert error? try [-8 // 0]
		--assert error? try [modulo -8 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-8 // 1"
		i: -8
		j: 1
		--assert strict-equal? 0 -8 // 1
		--assert strict-equal? 0 modulo -8 1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-8 // -1"
		i: -8
		j: -1
		--assert strict-equal? 0 -8 // -1
		--assert strict-equal? 0 modulo -8 -1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-8 // -2147483648"
		i: -8
		j: -2147483648
		;--assert strict-equal? 2147483640 -8 // -2147483648
		;--assert strict-equal? 2147483640 modulo -8 -2147483648
		;--assert strict-equal? 2147483640 i // j
		;--assert strict-equal? 2147483640 modulo i j

	--test-- "-8 // 2147483647"
		i: -8
		j: 2147483647
		;--assert strict-equal? 2147483639 -8 // 2147483647
		;--assert strict-equal? 2147483639 modulo -8 2147483647
		;--assert strict-equal? 2147483639 i // j
		;--assert strict-equal? 2147483639 modulo i j

	--test-- "-8 // -7"
		i: -8
		j: -7
		--assert strict-equal? 6 -8 // -7
		--assert strict-equal? 6 modulo -8 -7
		--assert strict-equal? 6 i // j
		--assert strict-equal? 6 modulo i j

	--test-- "-8 // -10"
		i: -8
		j: -10
		--assert strict-equal? 2 -8 // -10
		--assert strict-equal? 2 modulo -8 -10
		--assert strict-equal? 2 i // j
		--assert strict-equal? 2 modulo i j

	--test-- "-10 // 0"
		i: -10
		j: 0
		--assert error? try [-10 // 0]
		--assert error? try [modulo -10 0]
		--assert error? try [i // j]
		--assert error? try [modulo i j]

	--test-- "-10 // 1"
		i: -10
		j: 1
		--assert strict-equal? 0 -10 // 1
		--assert strict-equal? 0 modulo -10 1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-10 // -1"
		i: -10
		j: -1
		--assert strict-equal? 0 -10 // -1
		--assert strict-equal? 0 modulo -10 -1
		--assert strict-equal? 0 i // j
		--assert strict-equal? 0 modulo i j

	--test-- "-10 // -2147483648"
		i: -10
		j: -2147483648
		;--assert strict-equal? 2147483638 -10 // -2147483648
		;--assert strict-equal? 2147483638 modulo -10 -2147483648
		;--assert strict-equal? 2147483638 i // j
		;--assert strict-equal? 2147483638 modulo i j

	--test-- "-10 // 2147483647"
		i: -10
		j: 2147483647
		;--assert strict-equal? 2147483637 -10 // 2147483647
		;--assert strict-equal? 2147483637 modulo -10 2147483647
		;--assert strict-equal? 2147483637 i // j
		;--assert strict-equal? 2147483637 modulo i j

	--test-- "-10 // -7"
		i: -10
		j: -7
		--assert strict-equal? 4 -10 // -7
		--assert strict-equal? 4 modulo -10 -7
		--assert strict-equal? 4 i // j
		--assert strict-equal? 4 modulo i j

	--test-- "-10 // -8"
		i: -10
		j: -8
		--assert strict-equal? 6 -10 // -8
		--assert strict-equal? 6 modulo -10 -8
		--assert strict-equal? 6 i // j
		--assert strict-equal? 6 modulo i j

===end-group===

===start-group=== "integer or"

	--test-- "0 or 1"
		i: 0
		j: 1
		--assert strict-equal? 1 0 or 1
		--assert strict-equal? 1 or~ 0 1
		--assert strict-equal? 1 i or j
		--assert strict-equal? 1 or~ i j

	--test-- "0 or -1"
		i: 0
		j: -1
		--assert strict-equal? -1 0 or -1
		--assert strict-equal? -1 or~ 0 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "0 or -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? -2147483648 0 or -2147483648
		--assert strict-equal? -2147483648 or~ 0 -2147483648
		--assert strict-equal? -2147483648 i or j
		--assert strict-equal? -2147483648 or~ i j

	--test-- "0 or 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 2147483647 0 or 2147483647
		--assert strict-equal? 2147483647 or~ 0 2147483647
		--assert strict-equal? 2147483647 i or j
		--assert strict-equal? 2147483647 or~ i j

	--test-- "0 or -7"
		i: 0
		j: -7
		--assert strict-equal? -7 0 or -7
		--assert strict-equal? -7 or~ 0 -7
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "0 or -8"
		i: 0
		j: -8
		--assert strict-equal? -8 0 or -8
		--assert strict-equal? -8 or~ 0 -8
		--assert strict-equal? -8 i or j
		--assert strict-equal? -8 or~ i j

	--test-- "0 or -10"
		i: 0
		j: -10
		--assert strict-equal? -10 0 or -10
		--assert strict-equal? -10 or~ 0 -10
		--assert strict-equal? -10 i or j
		--assert strict-equal? -10 or~ i j

	--test-- "1 or 0"
		i: 1
		j: 0
		--assert strict-equal? 1 1 or 0
		--assert strict-equal? 1 or~ 1 0
		--assert strict-equal? 1 i or j
		--assert strict-equal? 1 or~ i j

	--test-- "1 or -1"
		i: 1
		j: -1
		--assert strict-equal? -1 1 or -1
		--assert strict-equal? -1 or~ 1 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "1 or -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? -2147483647 1 or -2147483648
		--assert strict-equal? -2147483647 or~ 1 -2147483648
		--assert strict-equal? -2147483647 i or j
		--assert strict-equal? -2147483647 or~ i j

	--test-- "1 or 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 2147483647 1 or 2147483647
		--assert strict-equal? 2147483647 or~ 1 2147483647
		--assert strict-equal? 2147483647 i or j
		--assert strict-equal? 2147483647 or~ i j

	--test-- "1 or -7"
		i: 1
		j: -7
		--assert strict-equal? -7 1 or -7
		--assert strict-equal? -7 or~ 1 -7
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "1 or -8"
		i: 1
		j: -8
		--assert strict-equal? -7 1 or -8
		--assert strict-equal? -7 or~ 1 -8
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "1 or -10"
		i: 1
		j: -10
		--assert strict-equal? -9 1 or -10
		--assert strict-equal? -9 or~ 1 -10
		--assert strict-equal? -9 i or j
		--assert strict-equal? -9 or~ i j

	--test-- "-1 or 0"
		i: -1
		j: 0
		--assert strict-equal? -1 -1 or 0
		--assert strict-equal? -1 or~ -1 0
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or 1"
		i: -1
		j: 1
		--assert strict-equal? -1 -1 or 1
		--assert strict-equal? -1 or~ -1 1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? -1 -1 or -2147483648
		--assert strict-equal? -1 or~ -1 -2147483648
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? -1 -1 or 2147483647
		--assert strict-equal? -1 or~ -1 2147483647
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or -7"
		i: -1
		j: -7
		--assert strict-equal? -1 -1 or -7
		--assert strict-equal? -1 or~ -1 -7
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or -8"
		i: -1
		j: -8
		--assert strict-equal? -1 -1 or -8
		--assert strict-equal? -1 or~ -1 -8
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-1 or -10"
		i: -1
		j: -10
		--assert strict-equal? -1 -1 or -10
		--assert strict-equal? -1 or~ -1 -10
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-2147483648 or 0"
		i: -2147483648
		j: 0
		--assert strict-equal? -2147483648 -2147483648 or 0
		--assert strict-equal? -2147483648 or~ -2147483648 0
		--assert strict-equal? -2147483648 i or j
		--assert strict-equal? -2147483648 or~ i j

	--test-- "-2147483648 or 1"
		i: -2147483648
		j: 1
		--assert strict-equal? -2147483647 -2147483648 or 1
		--assert strict-equal? -2147483647 or~ -2147483648 1
		--assert strict-equal? -2147483647 i or j
		--assert strict-equal? -2147483647 or~ i j

	--test-- "-2147483648 or -1"
		i: -2147483648
		j: -1
		--assert strict-equal? -1 -2147483648 or -1
		--assert strict-equal? -1 or~ -2147483648 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-2147483648 or 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? -1 -2147483648 or 2147483647
		--assert strict-equal? -1 or~ -2147483648 2147483647
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-2147483648 or -7"
		i: -2147483648
		j: -7
		--assert strict-equal? -7 -2147483648 or -7
		--assert strict-equal? -7 or~ -2147483648 -7
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-2147483648 or -8"
		i: -2147483648
		j: -8
		--assert strict-equal? -8 -2147483648 or -8
		--assert strict-equal? -8 or~ -2147483648 -8
		--assert strict-equal? -8 i or j
		--assert strict-equal? -8 or~ i j

	--test-- "-2147483648 or -10"
		i: -2147483648
		j: -10
		--assert strict-equal? -10 -2147483648 or -10
		--assert strict-equal? -10 or~ -2147483648 -10
		--assert strict-equal? -10 i or j
		--assert strict-equal? -10 or~ i j

	--test-- "2147483647 or 0"
		i: 2147483647
		j: 0
		--assert strict-equal? 2147483647 2147483647 or 0
		--assert strict-equal? 2147483647 or~ 2147483647 0
		--assert strict-equal? 2147483647 i or j
		--assert strict-equal? 2147483647 or~ i j

	--test-- "2147483647 or 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 2147483647 2147483647 or 1
		--assert strict-equal? 2147483647 or~ 2147483647 1
		--assert strict-equal? 2147483647 i or j
		--assert strict-equal? 2147483647 or~ i j

	--test-- "2147483647 or -1"
		i: 2147483647
		j: -1
		--assert strict-equal? -1 2147483647 or -1
		--assert strict-equal? -1 or~ 2147483647 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "2147483647 or -2147483648"
		i: 2147483647
		j: -2147483648
		--assert strict-equal? -1 2147483647 or -2147483648
		--assert strict-equal? -1 or~ 2147483647 -2147483648
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "2147483647 or -7"
		i: 2147483647
		j: -7
		--assert strict-equal? -1 2147483647 or -7
		--assert strict-equal? -1 or~ 2147483647 -7
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "2147483647 or -8"
		i: 2147483647
		j: -8
		--assert strict-equal? -1 2147483647 or -8
		--assert strict-equal? -1 or~ 2147483647 -8
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "2147483647 or -10"
		i: 2147483647
		j: -10
		--assert strict-equal? -1 2147483647 or -10
		--assert strict-equal? -1 or~ 2147483647 -10
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-7 or 0"
		i: -7
		j: 0
		--assert strict-equal? -7 -7 or 0
		--assert strict-equal? -7 or~ -7 0
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-7 or 1"
		i: -7
		j: 1
		--assert strict-equal? -7 -7 or 1
		--assert strict-equal? -7 or~ -7 1
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-7 or -1"
		i: -7
		j: -1
		--assert strict-equal? -1 -7 or -1
		--assert strict-equal? -1 or~ -7 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-7 or -2147483648"
		i: -7
		j: -2147483648
		--assert strict-equal? -7 -7 or -2147483648
		--assert strict-equal? -7 or~ -7 -2147483648
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-7 or 2147483647"
		i: -7
		j: 2147483647
		--assert strict-equal? -1 -7 or 2147483647
		--assert strict-equal? -1 or~ -7 2147483647
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-7 or -8"
		i: -7
		j: -8
		--assert strict-equal? -7 -7 or -8
		--assert strict-equal? -7 or~ -7 -8
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-7 or -10"
		i: -7
		j: -10
		--assert strict-equal? -1 -7 or -10
		--assert strict-equal? -1 or~ -7 -10
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-8 or 0"
		i: -8
		j: 0
		--assert strict-equal? -8 -8 or 0
		--assert strict-equal? -8 or~ -8 0
		--assert strict-equal? -8 i or j
		--assert strict-equal? -8 or~ i j

	--test-- "-8 or 1"
		i: -8
		j: 1
		--assert strict-equal? -7 -8 or 1
		--assert strict-equal? -7 or~ -8 1
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-8 or -1"
		i: -8
		j: -1
		--assert strict-equal? -1 -8 or -1
		--assert strict-equal? -1 or~ -8 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-8 or -2147483648"
		i: -8
		j: -2147483648
		--assert strict-equal? -8 -8 or -2147483648
		--assert strict-equal? -8 or~ -8 -2147483648
		--assert strict-equal? -8 i or j
		--assert strict-equal? -8 or~ i j

	--test-- "-8 or 2147483647"
		i: -8
		j: 2147483647
		--assert strict-equal? -1 -8 or 2147483647
		--assert strict-equal? -1 or~ -8 2147483647
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-8 or -7"
		i: -8
		j: -7
		--assert strict-equal? -7 -8 or -7
		--assert strict-equal? -7 or~ -8 -7
		--assert strict-equal? -7 i or j
		--assert strict-equal? -7 or~ i j

	--test-- "-8 or -10"
		i: -8
		j: -10
		--assert strict-equal? -2 -8 or -10
		--assert strict-equal? -2 or~ -8 -10
		--assert strict-equal? -2 i or j
		--assert strict-equal? -2 or~ i j

	--test-- "-10 or 0"
		i: -10
		j: 0
		--assert strict-equal? -10 -10 or 0
		--assert strict-equal? -10 or~ -10 0
		--assert strict-equal? -10 i or j
		--assert strict-equal? -10 or~ i j

	--test-- "-10 or 1"
		i: -10
		j: 1
		--assert strict-equal? -9 -10 or 1
		--assert strict-equal? -9 or~ -10 1
		--assert strict-equal? -9 i or j
		--assert strict-equal? -9 or~ i j

	--test-- "-10 or -1"
		i: -10
		j: -1
		--assert strict-equal? -1 -10 or -1
		--assert strict-equal? -1 or~ -10 -1
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-10 or -2147483648"
		i: -10
		j: -2147483648
		--assert strict-equal? -10 -10 or -2147483648
		--assert strict-equal? -10 or~ -10 -2147483648
		--assert strict-equal? -10 i or j
		--assert strict-equal? -10 or~ i j

	--test-- "-10 or 2147483647"
		i: -10
		j: 2147483647
		--assert strict-equal? -1 -10 or 2147483647
		--assert strict-equal? -1 or~ -10 2147483647
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-10 or -7"
		i: -10
		j: -7
		--assert strict-equal? -1 -10 or -7
		--assert strict-equal? -1 or~ -10 -7
		--assert strict-equal? -1 i or j
		--assert strict-equal? -1 or~ i j

	--test-- "-10 or -8"
		i: -10
		j: -8
		--assert strict-equal? -2 -10 or -8
		--assert strict-equal? -2 or~ -10 -8
		--assert strict-equal? -2 i or j
		--assert strict-equal? -2 or~ i j


===end-group===

===start-group=== "and"

	--test-- "0 and 1"
		i: 0
		j: 1
		--assert strict-equal? 0 0 and 1
		--assert strict-equal? 0 and~ 0 1
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and -1"
		i: 0
		j: -1
		--assert strict-equal? 0 0 and -1
		--assert strict-equal? 0 and~ 0 -1
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? 0 0 and -2147483648
		--assert strict-equal? 0 and~ 0 -2147483648
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 0 0 and 2147483647
		--assert strict-equal? 0 and~ 0 2147483647
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and -7"
		i: 0
		j: -7
		--assert strict-equal? 0 0 and -7
		--assert strict-equal? 0 and~ 0 -7
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and -8"
		i: 0
		j: -8
		--assert strict-equal? 0 0 and -8
		--assert strict-equal? 0 and~ 0 -8
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "0 and -10"
		i: 0
		j: -10
		--assert strict-equal? 0 0 and -10
		--assert strict-equal? 0 and~ 0 -10
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "1 and 0"
		i: 1
		j: 0
		--assert strict-equal? 0 1 and 0
		--assert strict-equal? 0 and~ 1 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "1 and -1"
		i: 1
		j: -1
		--assert strict-equal? 1 1 and -1
		--assert strict-equal? 1 and~ 1 -1
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "1 and -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? 0 1 and -2147483648
		--assert strict-equal? 0 and~ 1 -2147483648
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "1 and 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 1 1 and 2147483647
		--assert strict-equal? 1 and~ 1 2147483647
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "1 and -7"
		i: 1
		j: -7
		--assert strict-equal? 1 1 and -7
		--assert strict-equal? 1 and~ 1 -7
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "1 and -8"
		i: 1
		j: -8
		--assert strict-equal? 0 1 and -8
		--assert strict-equal? 0 and~ 1 -8
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "1 and -10"
		i: 1
		j: -10
		--assert strict-equal? 0 1 and -10
		--assert strict-equal? 0 and~ 1 -10
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-1 and 0"
		i: -1
		j: 0
		--assert strict-equal? 0 -1 and 0
		--assert strict-equal? 0 and~ -1 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-1 and 1"
		i: -1
		j: 1
		--assert strict-equal? 1 -1 and 1
		--assert strict-equal? 1 and~ -1 1
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "-1 and -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? -2147483648 -1 and -2147483648
		--assert strict-equal? -2147483648 and~ -1 -2147483648
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-1 and 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? 2147483647 -1 and 2147483647
		--assert strict-equal? 2147483647 and~ -1 2147483647
		--assert strict-equal? 2147483647 i and j
		--assert strict-equal? 2147483647 and~ i j

	--test-- "-1 and -7"
		i: -1
		j: -7
		--assert strict-equal? -7 -1 and -7
		--assert strict-equal? -7 and~ -1 -7
		--assert strict-equal? -7 i and j
		--assert strict-equal? -7 and~ i j

	--test-- "-1 and -8"
		i: -1
		j: -8
		--assert strict-equal? -8 -1 and -8
		--assert strict-equal? -8 and~ -1 -8
		--assert strict-equal? -8 i and j
		--assert strict-equal? -8 and~ i j

	--test-- "-1 and -10"
		i: -1
		j: -10
		--assert strict-equal? -10 -1 and -10
		--assert strict-equal? -10 and~ -1 -10
		--assert strict-equal? -10 i and j
		--assert strict-equal? -10 and~ i j

	--test-- "-2147483648 and 0"
		i: -2147483648
		j: 0
		--assert strict-equal? 0 -2147483648 and 0
		--assert strict-equal? 0 and~ -2147483648 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-2147483648 and 1"
		i: -2147483648
		j: 1
		--assert strict-equal? 0 -2147483648 and 1
		--assert strict-equal? 0 and~ -2147483648 1
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-2147483648 and -1"
		i: -2147483648
		j: -1
		--assert strict-equal? -2147483648 -2147483648 and -1
		--assert strict-equal? -2147483648 and~ -2147483648 -1
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-2147483648 and 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? 0 -2147483648 and 2147483647
		--assert strict-equal? 0 and~ -2147483648 2147483647
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-2147483648 and -7"
		i: -2147483648
		j: -7
		--assert strict-equal? -2147483648 -2147483648 and -7
		--assert strict-equal? -2147483648 and~ -2147483648 -7
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-2147483648 and -8"
		i: -2147483648
		j: -8
		--assert strict-equal? -2147483648 -2147483648 and -8
		--assert strict-equal? -2147483648 and~ -2147483648 -8
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-2147483648 and -10"
		i: -2147483648
		j: -10
		--assert strict-equal? -2147483648 -2147483648 and -10
		--assert strict-equal? -2147483648 and~ -2147483648 -10
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "2147483647 and 0"
		i: 2147483647
		j: 0
		--assert strict-equal? 0 2147483647 and 0
		--assert strict-equal? 0 and~ 2147483647 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "2147483647 and 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 1 2147483647 and 1
		--assert strict-equal? 1 and~ 2147483647 1
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "2147483647 and -1"
		i: 2147483647
		j: -1
		--assert strict-equal? 2147483647 2147483647 and -1
		--assert strict-equal? 2147483647 and~ 2147483647 -1
		--assert strict-equal? 2147483647 i and j
		--assert strict-equal? 2147483647 and~ i j

	--test-- "2147483647 and -2147483648"
		i: 2147483647
		j: -2147483648
		--assert strict-equal? 0 2147483647 and -2147483648
		--assert strict-equal? 0 and~ 2147483647 -2147483648
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "2147483647 and -7"
		i: 2147483647
		j: -7
		--assert strict-equal? 2147483641 2147483647 and -7
		--assert strict-equal? 2147483641 and~ 2147483647 -7
		--assert strict-equal? 2147483641 i and j
		--assert strict-equal? 2147483641 and~ i j

	--test-- "2147483647 and -8"
		i: 2147483647
		j: -8
		--assert strict-equal? 2147483640 2147483647 and -8
		--assert strict-equal? 2147483640 and~ 2147483647 -8
		--assert strict-equal? 2147483640 i and j
		--assert strict-equal? 2147483640 and~ i j

	--test-- "2147483647 and -10"
		i: 2147483647
		j: -10
		--assert strict-equal? 2147483638 2147483647 and -10
		--assert strict-equal? 2147483638 and~ 2147483647 -10
		--assert strict-equal? 2147483638 i and j
		--assert strict-equal? 2147483638 and~ i j

	--test-- "-7 and 0"
		i: -7
		j: 0
		--assert strict-equal? 0 -7 and 0
		--assert strict-equal? 0 and~ -7 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-7 and 1"
		i: -7
		j: 1
		--assert strict-equal? 1 -7 and 1
		--assert strict-equal? 1 and~ -7 1
		--assert strict-equal? 1 i and j
		--assert strict-equal? 1 and~ i j

	--test-- "-7 and -1"
		i: -7
		j: -1
		--assert strict-equal? -7 -7 and -1
		--assert strict-equal? -7 and~ -7 -1
		--assert strict-equal? -7 i and j
		--assert strict-equal? -7 and~ i j

	--test-- "-7 and -2147483648"
		i: -7
		j: -2147483648
		--assert strict-equal? -2147483648 -7 and -2147483648
		--assert strict-equal? -2147483648 and~ -7 -2147483648
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-7 and 2147483647"
		i: -7
		j: 2147483647
		--assert strict-equal? 2147483641 -7 and 2147483647
		--assert strict-equal? 2147483641 and~ -7 2147483647
		--assert strict-equal? 2147483641 i and j
		--assert strict-equal? 2147483641 and~ i j

	--test-- "-7 and -8"
		i: -7
		j: -8
		--assert strict-equal? -8 -7 and -8
		--assert strict-equal? -8 and~ -7 -8
		--assert strict-equal? -8 i and j
		--assert strict-equal? -8 and~ i j

	--test-- "-7 and -10"
		i: -7
		j: -10
		--assert strict-equal? -16 -7 and -10
		--assert strict-equal? -16 and~ -7 -10
		--assert strict-equal? -16 i and j
		--assert strict-equal? -16 and~ i j

	--test-- "-8 and 0"
		i: -8
		j: 0
		--assert strict-equal? 0 -8 and 0
		--assert strict-equal? 0 and~ -8 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-8 and 1"
		i: -8
		j: 1
		--assert strict-equal? 0 -8 and 1
		--assert strict-equal? 0 and~ -8 1
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-8 and -1"
		i: -8
		j: -1
		--assert strict-equal? -8 -8 and -1
		--assert strict-equal? -8 and~ -8 -1
		--assert strict-equal? -8 i and j
		--assert strict-equal? -8 and~ i j

	--test-- "-8 and -2147483648"
		i: -8
		j: -2147483648
		--assert strict-equal? -2147483648 -8 and -2147483648
		--assert strict-equal? -2147483648 and~ -8 -2147483648
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-8 and 2147483647"
		i: -8
		j: 2147483647
		--assert strict-equal? 2147483640 -8 and 2147483647
		--assert strict-equal? 2147483640 and~ -8 2147483647
		--assert strict-equal? 2147483640 i and j
		--assert strict-equal? 2147483640 and~ i j

	--test-- "-8 and -7"
		i: -8
		j: -7
		--assert strict-equal? -8 -8 and -7
		--assert strict-equal? -8 and~ -8 -7
		--assert strict-equal? -8 i and j
		--assert strict-equal? -8 and~ i j

	--test-- "-8 and -10"
		i: -8
		j: -10
		--assert strict-equal? -16 -8 and -10
		--assert strict-equal? -16 and~ -8 -10
		--assert strict-equal? -16 i and j
		--assert strict-equal? -16 and~ i j

	--test-- "-10 and 0"
		i: -10
		j: 0
		--assert strict-equal? 0 -10 and 0
		--assert strict-equal? 0 and~ -10 0
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-10 and 1"
		i: -10
		j: 1
		--assert strict-equal? 0 -10 and 1
		--assert strict-equal? 0 and~ -10 1
		--assert strict-equal? 0 i and j
		--assert strict-equal? 0 and~ i j

	--test-- "-10 and -1"
		i: -10
		j: -1
		--assert strict-equal? -10 -10 and -1
		--assert strict-equal? -10 and~ -10 -1
		--assert strict-equal? -10 i and j
		--assert strict-equal? -10 and~ i j

	--test-- "-10 and -2147483648"
		i: -10
		j: -2147483648
		--assert strict-equal? -2147483648 -10 and -2147483648
		--assert strict-equal? -2147483648 and~ -10 -2147483648
		--assert strict-equal? -2147483648 i and j
		--assert strict-equal? -2147483648 and~ i j

	--test-- "-10 and 2147483647"
		i: -10
		j: 2147483647
		--assert strict-equal? 2147483638 -10 and 2147483647
		--assert strict-equal? 2147483638 and~ -10 2147483647
		--assert strict-equal? 2147483638 i and j
		--assert strict-equal? 2147483638 and~ i j

	--test-- "-10 and -7"
		i: -10
		j: -7
		--assert strict-equal? -16 -10 and -7
		--assert strict-equal? -16 and~ -10 -7
		--assert strict-equal? -16 i and j
		--assert strict-equal? -16 and~ i j

	--test-- "-10 and -8"
		i: -10
		j: -8
		--assert strict-equal? -16 -10 and -8
		--assert strict-equal? -16 and~ -10 -8
		--assert strict-equal? -16 i and j
		--assert strict-equal? -16 and~ i j

===end-group===

===start-group=== "xor"

	--test-- "0 xor 1"
		i: 0
		j: 1
		--assert strict-equal? 1 0 xor 1
		--assert strict-equal? 1 xor~ 0 1
		--assert strict-equal? 1 i xor j
		--assert strict-equal? 1 xor~ i j

	--test-- "0 xor -1"
		i: 0
		j: -1
		--assert strict-equal? -1 0 xor -1
		--assert strict-equal? -1 xor~ 0 -1
		--assert strict-equal? -1 i xor j
		--assert strict-equal? -1 xor~ i j

	--test-- "0 xor -2147483648"
		i: 0
		j: -2147483648
		--assert strict-equal? -2147483648 0 xor -2147483648
		--assert strict-equal? -2147483648 xor~ 0 -2147483648
		--assert strict-equal? -2147483648 i xor j
		--assert strict-equal? -2147483648 xor~ i j

	--test-- "0 xor 2147483647"
		i: 0
		j: 2147483647
		--assert strict-equal? 2147483647 0 xor 2147483647
		--assert strict-equal? 2147483647 xor~ 0 2147483647
		--assert strict-equal? 2147483647 i xor j
		--assert strict-equal? 2147483647 xor~ i j

	--test-- "0 xor -7"
		i: 0
		j: -7
		--assert strict-equal? -7 0 xor -7
		--assert strict-equal? -7 xor~ 0 -7
		--assert strict-equal? -7 i xor j
		--assert strict-equal? -7 xor~ i j

	--test-- "0 xor -8"
		i: 0
		j: -8
		--assert strict-equal? -8 0 xor -8
		--assert strict-equal? -8 xor~ 0 -8
		--assert strict-equal? -8 i xor j
		--assert strict-equal? -8 xor~ i j

	--test-- "0 xor -10"
		i: 0
		j: -10
		--assert strict-equal? -10 0 xor -10
		--assert strict-equal? -10 xor~ 0 -10
		--assert strict-equal? -10 i xor j
		--assert strict-equal? -10 xor~ i j

	--test-- "1 xor 0"
		i: 1
		j: 0
		--assert strict-equal? 1 1 xor 0
		--assert strict-equal? 1 xor~ 1 0
		--assert strict-equal? 1 i xor j
		--assert strict-equal? 1 xor~ i j

	--test-- "1 xor -1"
		i: 1
		j: -1
		--assert strict-equal? -2 1 xor -1
		--assert strict-equal? -2 xor~ 1 -1
		--assert strict-equal? -2 i xor j
		--assert strict-equal? -2 xor~ i j

	--test-- "1 xor -2147483648"
		i: 1
		j: -2147483648
		--assert strict-equal? -2147483647 1 xor -2147483648
		--assert strict-equal? -2147483647 xor~ 1 -2147483648
		--assert strict-equal? -2147483647 i xor j
		--assert strict-equal? -2147483647 xor~ i j

	--test-- "1 xor 2147483647"
		i: 1
		j: 2147483647
		--assert strict-equal? 2147483646 1 xor 2147483647
		--assert strict-equal? 2147483646 xor~ 1 2147483647
		--assert strict-equal? 2147483646 i xor j
		--assert strict-equal? 2147483646 xor~ i j

	--test-- "1 xor -7"
		i: 1
		j: -7
		--assert strict-equal? -8 1 xor -7
		--assert strict-equal? -8 xor~ 1 -7
		--assert strict-equal? -8 i xor j
		--assert strict-equal? -8 xor~ i j

	--test-- "1 xor -8"
		i: 1
		j: -8
		--assert strict-equal? -7 1 xor -8
		--assert strict-equal? -7 xor~ 1 -8
		--assert strict-equal? -7 i xor j
		--assert strict-equal? -7 xor~ i j

	--test-- "1 xor -10"
		i: 1
		j: -10
		--assert strict-equal? -9 1 xor -10
		--assert strict-equal? -9 xor~ 1 -10
		--assert strict-equal? -9 i xor j
		--assert strict-equal? -9 xor~ i j

	--test-- "-1 xor 0"
		i: -1
		j: 0
		--assert strict-equal? -1 -1 xor 0
		--assert strict-equal? -1 xor~ -1 0
		--assert strict-equal? -1 i xor j
		--assert strict-equal? -1 xor~ i j

	--test-- "-1 xor 1"
		i: -1
		j: 1
		--assert strict-equal? -2 -1 xor 1
		--assert strict-equal? -2 xor~ -1 1
		--assert strict-equal? -2 i xor j
		--assert strict-equal? -2 xor~ i j

	--test-- "-1 xor -2147483648"
		i: -1
		j: -2147483648
		--assert strict-equal? 2147483647 -1 xor -2147483648
		--assert strict-equal? 2147483647 xor~ -1 -2147483648
		--assert strict-equal? 2147483647 i xor j
		--assert strict-equal? 2147483647 xor~ i j

	--test-- "-1 xor 2147483647"
		i: -1
		j: 2147483647
		--assert strict-equal? -2147483648 -1 xor 2147483647
		--assert strict-equal? -2147483648 xor~ -1 2147483647
		--assert strict-equal? -2147483648 i xor j
		--assert strict-equal? -2147483648 xor~ i j

	--test-- "-1 xor -7"
		i: -1
		j: -7
		--assert strict-equal? 6 -1 xor -7
		--assert strict-equal? 6 xor~ -1 -7
		--assert strict-equal? 6 i xor j
		--assert strict-equal? 6 xor~ i j

	--test-- "-1 xor -8"
		i: -1
		j: -8
		--assert strict-equal? 7 -1 xor -8
		--assert strict-equal? 7 xor~ -1 -8
		--assert strict-equal? 7 i xor j
		--assert strict-equal? 7 xor~ i j

	--test-- "-1 xor -10"
		i: -1
		j: -10
		--assert strict-equal? 9 -1 xor -10
		--assert strict-equal? 9 xor~ -1 -10
		--assert strict-equal? 9 i xor j
		--assert strict-equal? 9 xor~ i j

	--test-- "-2147483648 xor 0"
		i: -2147483648
		j: 0
		--assert strict-equal? -2147483648 -2147483648 xor 0
		--assert strict-equal? -2147483648 xor~ -2147483648 0
		--assert strict-equal? -2147483648 i xor j
		--assert strict-equal? -2147483648 xor~ i j

	--test-- "-2147483648 xor 1"
		i: -2147483648
		j: 1
		--assert strict-equal? -2147483647 -2147483648 xor 1
		--assert strict-equal? -2147483647 xor~ -2147483648 1
		--assert strict-equal? -2147483647 i xor j
		--assert strict-equal? -2147483647 xor~ i j

	--test-- "-2147483648 xor -1"
		i: -2147483648
		j: -1
		--assert strict-equal? 2147483647 -2147483648 xor -1
		--assert strict-equal? 2147483647 xor~ -2147483648 -1
		--assert strict-equal? 2147483647 i xor j
		--assert strict-equal? 2147483647 xor~ i j

	--test-- "-2147483648 xor 2147483647"
		i: -2147483648
		j: 2147483647
		--assert strict-equal? -1 -2147483648 xor 2147483647
		--assert strict-equal? -1 xor~ -2147483648 2147483647
		--assert strict-equal? -1 i xor j
		--assert strict-equal? -1 xor~ i j

	--test-- "-2147483648 xor -7"
		i: -2147483648
		j: -7
		--assert strict-equal? 2147483641 -2147483648 xor -7
		--assert strict-equal? 2147483641 xor~ -2147483648 -7
		--assert strict-equal? 2147483641 i xor j
		--assert strict-equal? 2147483641 xor~ i j

	--test-- "-2147483648 xor -8"
		i: -2147483648
		j: -8
		--assert strict-equal? 2147483640 -2147483648 xor -8
		--assert strict-equal? 2147483640 xor~ -2147483648 -8
		--assert strict-equal? 2147483640 i xor j
		--assert strict-equal? 2147483640 xor~ i j

	--test-- "-2147483648 xor -10"
		i: -2147483648
		j: -10
		--assert strict-equal? 2147483638 -2147483648 xor -10
		--assert strict-equal? 2147483638 xor~ -2147483648 -10
		--assert strict-equal? 2147483638 i xor j
		--assert strict-equal? 2147483638 xor~ i j

	--test-- "2147483647 xor 0"
		i: 2147483647
		j: 0
		--assert strict-equal? 2147483647 2147483647 xor 0
		--assert strict-equal? 2147483647 xor~ 2147483647 0
		--assert strict-equal? 2147483647 i xor j
		--assert strict-equal? 2147483647 xor~ i j

	--test-- "2147483647 xor 1"
		i: 2147483647
		j: 1
		--assert strict-equal? 2147483646 2147483647 xor 1
		--assert strict-equal? 2147483646 xor~ 2147483647 1
		--assert strict-equal? 2147483646 i xor j
		--assert strict-equal? 2147483646 xor~ i j

	--test-- "2147483647 xor -1"
		i: 2147483647
		j: -1
		--assert strict-equal? -2147483648 2147483647 xor -1
		--assert strict-equal? -2147483648 xor~ 2147483647 -1
		--assert strict-equal? -2147483648 i xor j
		--assert strict-equal? -2147483648 xor~ i j

	--test-- "2147483647 xor -2147483648"
		i: 2147483647
		j: -2147483648
		--assert strict-equal? -1 2147483647 xor -2147483648
		--assert strict-equal? -1 xor~ 2147483647 -2147483648
		--assert strict-equal? -1 i xor j
		--assert strict-equal? -1 xor~ i j

	--test-- "2147483647 xor -7"
		i: 2147483647
		j: -7
		--assert strict-equal? -2147483642 2147483647 xor -7
		--assert strict-equal? -2147483642 xor~ 2147483647 -7
		--assert strict-equal? -2147483642 i xor j
		--assert strict-equal? -2147483642 xor~ i j

	--test-- "2147483647 xor -8"
		i: 2147483647
		j: -8
		--assert strict-equal? -2147483641 2147483647 xor -8
		--assert strict-equal? -2147483641 xor~ 2147483647 -8
		--assert strict-equal? -2147483641 i xor j
		--assert strict-equal? -2147483641 xor~ i j

	--test-- "2147483647 xor -10"
		i: 2147483647
		j: -10
		--assert strict-equal? -2147483639 2147483647 xor -10
		--assert strict-equal? -2147483639 xor~ 2147483647 -10
		--assert strict-equal? -2147483639 i xor j
		--assert strict-equal? -2147483639 xor~ i j

	--test-- "-7 xor 0"
		i: -7
		j: 0
		--assert strict-equal? -7 -7 xor 0
		--assert strict-equal? -7 xor~ -7 0
		--assert strict-equal? -7 i xor j
		--assert strict-equal? -7 xor~ i j

	--test-- "-7 xor 1"
		i: -7
		j: 1
		--assert strict-equal? -8 -7 xor 1
		--assert strict-equal? -8 xor~ -7 1
		--assert strict-equal? -8 i xor j
		--assert strict-equal? -8 xor~ i j

	--test-- "-7 xor -1"
		i: -7
		j: -1
		--assert strict-equal? 6 -7 xor -1
		--assert strict-equal? 6 xor~ -7 -1
		--assert strict-equal? 6 i xor j
		--assert strict-equal? 6 xor~ i j

	--test-- "-7 xor -2147483648"
		i: -7
		j: -2147483648
		--assert strict-equal? 2147483641 -7 xor -2147483648
		--assert strict-equal? 2147483641 xor~ -7 -2147483648
		--assert strict-equal? 2147483641 i xor j
		--assert strict-equal? 2147483641 xor~ i j

	--test-- "-7 xor 2147483647"
		i: -7
		j: 2147483647
		--assert strict-equal? -2147483642 -7 xor 2147483647
		--assert strict-equal? -2147483642 xor~ -7 2147483647
		--assert strict-equal? -2147483642 i xor j
		--assert strict-equal? -2147483642 xor~ i j

	--test-- "-7 xor -8"
		i: -7
		j: -8
		--assert strict-equal? 1 -7 xor -8
		--assert strict-equal? 1 xor~ -7 -8
		--assert strict-equal? 1 i xor j
		--assert strict-equal? 1 xor~ i j

	--test-- "-7 xor -10"
		i: -7
		j: -10
		--assert strict-equal? 15 -7 xor -10
		--assert strict-equal? 15 xor~ -7 -10
		--assert strict-equal? 15 i xor j
		--assert strict-equal? 15 xor~ i j

	--test-- "-8 xor 0"
		i: -8
		j: 0
		--assert strict-equal? -8 -8 xor 0
		--assert strict-equal? -8 xor~ -8 0
		--assert strict-equal? -8 i xor j
		--assert strict-equal? -8 xor~ i j

	--test-- "-8 xor 1"
		i: -8
		j: 1
		--assert strict-equal? -7 -8 xor 1
		--assert strict-equal? -7 xor~ -8 1
		--assert strict-equal? -7 i xor j
		--assert strict-equal? -7 xor~ i j

	--test-- "-8 xor -1"
		i: -8
		j: -1
		--assert strict-equal? 7 -8 xor -1
		--assert strict-equal? 7 xor~ -8 -1
		--assert strict-equal? 7 i xor j
		--assert strict-equal? 7 xor~ i j

	--test-- "-8 xor -2147483648"
		i: -8
		j: -2147483648
		--assert strict-equal? 2147483640 -8 xor -2147483648
		--assert strict-equal? 2147483640 xor~ -8 -2147483648
		--assert strict-equal? 2147483640 i xor j
		--assert strict-equal? 2147483640 xor~ i j

	--test-- "-8 xor 2147483647"
		i: -8
		j: 2147483647
		--assert strict-equal? -2147483641 -8 xor 2147483647
		--assert strict-equal? -2147483641 xor~ -8 2147483647
		--assert strict-equal? -2147483641 i xor j
		--assert strict-equal? -2147483641 xor~ i j

	--test-- "-8 xor -7"
		i: -8
		j: -7
		--assert strict-equal? 1 -8 xor -7
		--assert strict-equal? 1 xor~ -8 -7
		--assert strict-equal? 1 i xor j
		--assert strict-equal? 1 xor~ i j

	--test-- "-8 xor -10"
		i: -8
		j: -10
		--assert strict-equal? 14 -8 xor -10
		--assert strict-equal? 14 xor~ -8 -10
		--assert strict-equal? 14 i xor j
		--assert strict-equal? 14 xor~ i j

	--test-- "-10 xor 0"
		i: -10
		j: 0
		--assert strict-equal? -10 -10 xor 0
		--assert strict-equal? -10 xor~ -10 0
		--assert strict-equal? -10 i xor j
		--assert strict-equal? -10 xor~ i j

	--test-- "-10 xor 1"
		i: -10
		j: 1
		--assert strict-equal? -9 -10 xor 1
		--assert strict-equal? -9 xor~ -10 1
		--assert strict-equal? -9 i xor j
		--assert strict-equal? -9 xor~ i j

	--test-- "-10 xor -1"
		i: -10
		j: -1
		--assert strict-equal? 9 -10 xor -1
		--assert strict-equal? 9 xor~ -10 -1
		--assert strict-equal? 9 i xor j
		--assert strict-equal? 9 xor~ i j

	--test-- "-10 xor -2147483648"
		i: -10
		j: -2147483648
		--assert strict-equal? 2147483638 -10 xor -2147483648
		--assert strict-equal? 2147483638 xor~ -10 -2147483648
		--assert strict-equal? 2147483638 i xor j
		--assert strict-equal? 2147483638 xor~ i j

	--test-- "-10 xor 2147483647"
		i: -10
		j: 2147483647
		--assert strict-equal? -2147483639 -10 xor 2147483647
		--assert strict-equal? -2147483639 xor~ -10 2147483647
		--assert strict-equal? -2147483639 i xor j
		--assert strict-equal? -2147483639 xor~ i j

	--test-- "-10 xor -7"
		i: -10
		j: -7
		--assert strict-equal? 15 -10 xor -7
		--assert strict-equal? 15 xor~ -10 -7
		--assert strict-equal? 15 i xor j
		--assert strict-equal? 15 xor~ i j

	--test-- "-10 xor -8"
		i: -10
		j: -8
		--assert strict-equal? 14 -10 xor -8
		--assert strict-equal? 14 xor~ -10 -8
		--assert strict-equal? 14 i xor j
		--assert strict-equal? 14 xor~ i j

===end-group===

===start-group=== "comparisons"

	--test-- "= 1"					--assert 0 = 0
	--test-- "= 2"					--assert not 1 = 0
	--test-- "= 3"					--assert not -1 = 0
	--test-- "= 4"					--assert not 2147483647 = -2147483648
	--test-- "= 5"					--assert 2147483647 = 2147483647
	--test-- "= 6"					--assert -2147483648 = -2147483648
	--test-- "equal? 1"				--assert equal? 0 0
	--test-- "equal? 2"				--assert not equal? 1 0
	--test-- "equal? 3"				--assert not equal? -1 0
	--test-- "equal? 4"				--assert not equal? 2147483647 -2147483648
	--test-- "<> 1"					--assert not 0 <> 0
	--test-- "<> 2"					--assert 1 <> 0
	--test-- "<> 3"					--assert -1 <> 0
	--test-- "<> 4"					--assert 2147483647 <> -2147483648
	--test-- "not equal? 1"			--assert not not-equal? 0  0
	--test-- "not equal? 2"			--assert not-equal? 1 0
	--test-- "not equal? 3"			--assert not-equal? -1 0
	--test-- "not equal? 4"			--assert not-equal? 2147483647 <> -2147483648
	--test-- "> 1"					--assert not 0 > 0
	--test-- "> 2"					--assert 1 > 0
	--test-- "> 3"					--assert 0 > -1
	--test-- "> 4"					--assert 2147483647 > -2147483648
	--test-- "greater? 1"			--assert not greater? 0 0
	--test-- "greater? 2"			--assert greater? 1 0
	--test-- "greater? 3"			--assert greater? 0 -1
	--test-- "greater? 4"			--assert greater? 2147483647 -2147483648
	--test-- "< 1"					--assert not 0 < 0
	--test-- "< 2"					--assert 0 < 1
	--test-- "< 3"					--assert -1 < 0
	--test-- "< 4"					--assert -2147483648 < 2147483647
	--test-- "lesser? 1"			--assert not lesser? 0 0
	--test-- "lesser? 2"			--assert lesser? 0 1
	--test-- "lesser? 3"			--assert lesser? -1 0
	--test-- "lesser? 4"			--assert lesser? -2147483648 2147483647
	--test-- ">= 1"					--assert 0 >= 0
	--test-- ">= 2"					--assert 1 >= 0
	--test-- ">= 3"					--assert 0 >= -1
	--test-- ">= 4"					--assert 2147483647 >= -2147483648
	--test-- " greater-or-equal? 1"	--assert greater-or-equal? 0 0
	--test-- " greater-or-equal? 2"	--assert greater-or-equal? 1 0
	--test-- " greater-or-equal? 3"	--assert greater-or-equal? 0 -1
	--test-- " greater-or-equal? 4"	--assert greater-or-equal? 2147483647 -2147483648
	--test-- "<= 1"					--assert 0 <= 0
	--test-- "<= 2"					--assert 0 <= 1
	--test-- "<= 3"					--assert -1 <= 0
	--test-- "<= 4"					--assert -2147483648 <= 2147483647
	--test-- " lesser-or-equal? 1"	--assert lesser-or-equal? 0 0
	--test-- " lesser-or-equal? 2"	--assert lesser-or-equal? 0 1
	--test-- " lesser-or-equal? 3"	--assert lesser-or-equal? -1 0
	--test-- " lesser-or-equal? 4"	--assert lesser-or-equal? -2147483648 2147483647
		
===end-group===

~~~end-file~~~
