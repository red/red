Red [
	Title:   "Red pair test script"
	Author:  "Peter W A Wood"
	File: 	 %pair-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]
 

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "pair"

===start-group=== "pair - basic"

	--test-- "pb-1"
		pb1-p: 1x1
		--assert equal? pb1-p/x 1
		--assert equal? pb1-p/y 1
		--assert equal? first pb1-p 1
		--assert equal? second pb1-p 1
		--assert equal? pb1-p 1x1
		--assert equal? pick pb1-p 1 1
		--assert equal? pick pb1-p 2 1
		
	--test-- "pb-2"
		pb2-p: 0x0
		--assert equal? pb2-p/x 0
		--assert equal? pb2-p/y 0
		--assert equal? first pb2-p 0
		--assert equal? second pb2-p 0
		--assert equal? pb2-p 0x0
		--assert equal? pick pb2-p 1 0
		--assert equal? pick pb2-p 2 0
		
	--test-- "pb-3"
		pb3-p: 2147483647x2147483647
		--assert equal? pb3-p/x 2147483647
		--assert equal? pb3-p/y 2147483647
		--assert equal? first pb3-p 2147483647
		--assert equal? second pb3-p 2147483647
		--assert equal? pb3-p 2147483647x2147483647
		--assert equal? pick pb3-p 1 2147483647
		--assert equal? pick pb3-p 2 2147483647
		
	--test-- "pb-4"
		pb4-p: -2147483648x-2147483648
		--assert equal? pb4-p/x -2147483648
		--assert equal? pb4-p/y -2147483648
		--assert equal? first pb4-p -2147483648
		--assert equal? second pb4-p -2147483648
		--assert equal? pb4-p -2147483648x-2147483648
		--assert equal? pick pb4-p 1 -2147483648
		--assert equal? pick pb4-p 2 -2147483648
		
	--test-- "pb-5"
		pb5-p: 2147483647x-2147483648
		--assert equal? pb5-p/x 2147483647
		--assert equal? pb5-p/y -2147483648
		--assert equal? first pb5-p 2147483647
		--assert equal? second pb5-p -2147483648
		--assert equal? pb5-p 2147483647x-2147483648
		--assert equal? pick pb5-p 1 2147483647
		--assert equal? pick pb5-p 2 -2147483648
		
	--test-- "pb-6"			--assert equal? 3x4 as-pair 3 4
	--test-- "pb-7"			--assert equal? 4x5 make pair! [4 5]
	--test-- "pb-8"			--assert equal? none attempt [as-pair 10]
	--test-- "pb-9"			--assert equal? 10x10 make pair! 10
		
===end-group===

===start-group=== "pair - assignment"

	--test-- "pa-1"
		pa1-p: 1x1
		--assert equal? pa1-p 1x1
		pa1-p/x: 0
		--assert equal? pa1-p 0x1
		pa1-p/y: 0
		--assert equal? pa1-p 0x0

===end-group===

===start-group=== "pair - add"

	--test-- "padd-1"
		padd1-p: 1x1
		--assert equal? padd1-p + 2 3x3
	
	--test-- "padd-2"
		padd2-p: 1x1
		--assert equal? padd2-p + 2x1 3x2
		
	--test-- "padd-3"
		padd3-p: 1x1
		--assert equal? padd3-p + 2147483646x2147483646 2147483647x2147483647
		
	--test-- "padd-4"
		padd4-p: 1x1
		--assert equal? padd4-p + 2147483646 2147483647x2147483647
		
===end-group===

===start-group=== "pair - subtract"

	--test-- "psub-1"
		psub1-p: 1x1
		--assert equal? psub1-p - 2 -1x-1
	
	--test-- "psub-2"
		psub2-p: 1x1
		--assert equal? psub2-p - 2x1 -1x0
		
	--test-- "psub-3"
		psub3-p: 1x1
		--assert equal? psub3-p - 2147483647x2147483647 -2147483646x-2147483646
		
	--test-- "psub-4"
		psub4-p: -1x-1
		--assert equal? psub4-p - 2147483647 -2147483648x-2147483648
		
===end-group===


===start-group=== "pair - multiply"

	--test-- "pmul-1"
		pmul1-p: 1x1
		--assert equal? pmul1-p * 2 2x2
	
	--test-- "pmul-2"
		pmul2-p: 1x1
		--assert equal? pmul2-p * 2x1 2x1
; awaiting integer! to float! promotion			
	--test-- "pmul-3"
		pmul3-p: 2x2
		;--assert equal? attempt [pmul3-p * 2147483647x2147483647] none
		
	--test-- "pmul-4"
		pmul4-p: -3x-3
		;--assert equal? attempt [pmul4-p * -2147483648] none
	
===end-group===

===start-group=== "pair - divide"

	--test-- "pdiv-1"
		pdiv1-p: 4x4
		--assert equal? pdiv1-p / 2 2x2
	
	--test-- "pdiv-2"
		pdiv2-p: 16x15
		--assert equal? pdiv2-p / 2x1 8x15
		
	--test-- "pdiv-3"
		pdiv3-p: 2147483647x2147483647
		--assert equal? pdiv3-p / 2 1073741823x1073741823
		
	--test-- "pdiv-4"
		pdiv4-p: -2147483648x-2147483648
		--assert equal? pdiv4-p / -2147483648 1x1
		
===end-group===

===start-group=== "pair - remainder"

	--test-- "prem-1"
		prem1-p: 4x4
		--assert equal? prem1-p % 2 0x0
	
	--test-- "prem-2"
		prem2-p: 16x15
		--assert equal? prem2-p % 2x3 0x0
		
	--test-- "prem-3"
		prem3-p: 2147483647x2147483647
		--assert equal? prem3-p % 2 1x1
		
	--test-- "prem-4"
		prem4-p: -2147483648x-2147483648
		--assert equal? prem4-p % -2147483648 0x0
		
===end-group===

===start-group=== "pair - negate"

	--test-- "pneg-1"
		pneg1-p: 4x4
		--assert equal? negate pneg1-p -4x-4
	
	--test-- "pneg-2"
		pneg2-p: -16x-15
		--assert equal? negate pneg2-p 16x15
		
	--test-- "pneg-3"
		pneg3-p: 2147483647x2147483647
		--assert equal? negate pneg3-p -2147483647x-2147483647
; awaiting integer! to float! promotion		
	--test-- "pneg-4"
		pneg4-p: -2147483648x-2147483648
;		--assert equal? attempt [negate pneg4-p] none
		
===end-group===

===start-group=== "pair - and"
	
	--test-- "pand-1"		--assert equal? 0x0 (1x1 and 0x0)
	--test-- "pand-2"		--assert equal? 1x1 (1x1 and 1x1)
	--test-- "pand-3"   	--assert equal? 1x0 (1x1 and 1x0)
	--test-- "pand-4" 		--assert equal? 16x0 (16x16 and 16x4)
	--test-- "pand-5"		--assert equal? 7x4	(7x7 and 7x4)

===end-group===

===start-group=== "pair - and"
	
	--test-- "pand-1"		--assert equal? 0x0 (1x1 and 0x0)
	--test-- "pand-2"		--assert equal? 1x1 (1x1 and 1x1)
	--test-- "pand-3"   	--assert equal? 1x0 (1x1 and 1x0)
	--test-- "pand-4" 		--assert equal? 16x0 (16x16 and 16x4)
	--test-- "pand-5"		--assert equal? 7x4	(7x7 and 7x4)

===end-group===

===start-group=== "pair - or"

	--test-- "por-1"		--assert equal? 1x1 (1x1 or 0x0)
	--test-- "por-2"		--assert equal? 1x1 (1x1 or 1x1)
	--test-- "por-3"   		--assert equal? 1x1 (1x1 or 1x0)
	--test-- "por-4" 		--assert equal? 16x20 (16x16 or 16x4)
	--test-- "por-5"		--assert equal? 7x7	(7x7 or 7x4)

===end-group===

===start-group=== "pair - xor"

	--test-- "pxor-1"		--assert equal? 1x1 (1x1 xor 0x0)
	--test-- "pxor-2"		--assert equal? 0x0 (1x1 xor 1x1)
	--test-- "pxor-3"   	--assert equal? 0x1 (1x1 xor 1x0)
	--test-- "pxor-4" 		--assert equal? 0x20 (16x16 xor 16x4)
	--test-- "pxor-5"		--assert equal? 0x3	(7x7 xor 7x4)

===end-group===

===start-group=== "pair - reverse"

	--test-- "prev-1"		--assert equal? reverse 1x2 2x1
	
===end-group===

===start-group=== "pair - comparison"

	--test-- "pcomp-1"		--assert equal? 1x1 1x1
	--test-- "pcomp-2"		--assert not-equal? 1x1 1x0
	--test-- "pcomp-3"		--assert not-equal? 1x1 0x1
	--test-- "pcomp-4"		--assert not-equal? 1x1 0x0

===end-group===

~~~end-file~~~
