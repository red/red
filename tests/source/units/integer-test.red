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
		;--assert error? try [-2147483648 / -1]
		;--assert error? try [divide -2147483648 -1]
		;--assert error? try [i / j]
		;--assert error? try [divide i j]

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

~~~end-file~~~
