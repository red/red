Red [
	Title:	 "Red SIGN? function tests"
	Author:	 "Gregg Irwin"
	File:	 %sign-test.red
	Version: 0.0.1
	Rights:	 "Copyright (C) 2016 Gregg Irwin. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red

sign?: func [
	"Returns sign of N as 1, 0, or -1 (to use as a multiplier)."
	n [number! time!]
][
	case [
		n > 0 [1]
		n < 0 [-1]
		n = 0 [0]
	]
]

~~~start-file~~~ "sign?"

===start-group=== "sign? - fixed values"

	--test-- "s-0"
		--assert equal?  0 sign? 0
		--assert equal?  0 sign? 0.0
		--assert equal?  0 sign? 0:0:0

		--assert equal?  0 sign? -0
		--assert equal?  0 sign? -0.0
		--assert equal?  0 sign? -0:0:0

	--test-- "s-1"
		--assert equal?  1 sign? 1
		--assert equal?  1 sign? 1.0
		--assert equal?  1 sign? 1:0:0

		--assert equal? -1 sign? -1
		--assert equal? -1 sign? -1.0
		--assert equal? -1 sign? -1:0:0

	--test-- "s-N-I"
		--assert equal?  1 sign? 123456789
	--test-- "s-N-F"
		--assert equal?  1 sign? 123456789.0
	--test-- "s-N-T"
		--assert equal?  1 sign? 123456789:0:0

	--test-- "s-N-I"
		--assert equal?  1 sign? 1234567890
	--test-- "s-N-F"
		--assert equal?  1 sign? 1234567890.0
	--test-- "s-N-T"
		--assert equal?  1 sign? 1234567890:0:0

	--test-- "s-nN"
	
		--assert equal? -1 sign? -123456789
		--assert equal? -1 sign? -123456789.0
		--assert equal? -1 sign? -123456789:0:0
		
		
===end-group===

===start-group=== "sign? - big values/edge cases"

	--test-- "s-bv-1i"
		--assert equal?  1 sign? 1073741824
	--test-- "s-bv-1f"
		--assert equal?  1 sign? 1073741824.0
	--test-- "s-bv-1t"
		--assert equal?  1 sign? 1073741824:0:0

	--test-- "s-bv-2i"
		--assert equal?  1 sign? 1073741825
	--test-- "s-bv-2f"
		--assert equal?  1 sign? 1073741825.0
	--test-- "s-bv-2t"
		--assert equal?  1 sign? 1073741825:0:0

	--test-- "s-bv-3i"
		--assert equal?  1 sign? 2147483647
	--test-- "s-bv-3f"
		--assert equal?  1 sign? 2147483647.0
	--test-- "s-bv-3t"
		--assert equal?  1 sign? 2147483647:0:0

	--test-- "s-bv-4i"
		--assert equal? -1 sign? -2147483648
	--test-- "s-bv-4f"
		--assert equal? -1 sign? -2147483648.0
	--test-- "s-bv-4t"
		--assert equal? -1 sign? -2147483647:59:59	; Larger than this overflows time

	--test-- "s-bv-5i"
		--assert equal? -1 sign? -2147483647
	--test-- "s-bv-5f"
		--assert equal? -1 sign? -2147483647.0
	--test-- "s-bv-5t"
		--assert equal? -1 sign? -2147483647:0:0

===end-group===

===start-group=== "sign? - random values"

	--test-- "sr-i"
		sr-i-res: loop 100'000 [
			if 1 <> sign? n: random  2'147'483'647 [break/return n]
		]
		--assert not integer? sr-i-res
		
	--test-- "sr-f"
		sr-f-res: loop 100'000 [
			if 1 <> sign? n: random 2'147'483'647.0 [break/return n]
		]
		--assert not float? sr-f-res
	
	--test-- "sr-t"
		sr-t-res: loop 100'000 [
			if 1 <> sign? n: random 2'147'483'647:00:00 [break/return n]
		]
		--assert not time? sr-t-res
	
	--test-- "sr-ni"
		sr-ni-res: loop 100'000 [
			if -1 <> sign? n: random  -2'147'483'647 [break/return n]
		]
		--assert not integer? sr-ni-res
		
	--test-- "sr-nf"
		sr-nf-res: loop 100'000 [
			if -1 <> sign? n: random -2'147'483'647.0 [break/return n]
		]
		--assert not float? sr-nf-res
	
	--test-- "sr-nt"
		sr-nt-res: loop 100'000 [
			if -1 <> sign? n: random -2'147'483'647:00:00 [break/return n]
		]
		--assert not time? sr-nt-res

===end-group===

~~~end-file~~~
