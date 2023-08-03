Red [
	Title:   "Red points test script"
	Author:  "Nenad Rakocevic"
	File: 	 %points-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2023 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]
 

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "point2D"

===start-group=== "point2D - basic"

	--test-- "pb-1"
		pb1-pt: (1, 1)
		--assert equal? pb1-pt/x 1
		--assert equal? pb1-pt/y 1
		--assert equal? first pb1-pt 1
		--assert equal? second pb1-pt 1
		--assert equal? pb1-pt (1, 1)
		--assert equal? pick pb1-pt 1 1
		--assert equal? pick pb1-pt 2 1
		--assert equal? pick pb1-pt 'x 1
		--assert equal? pick pb1-pt 'y 1
		
	--test-- "pb-2"
		pb2-pt: (0, 0)
		--assert equal? pb2-pt/x 0
		--assert equal? pb2-pt/y 0
		--assert equal? first pb2-pt 0
		--assert equal? second pb2-pt 0
		--assert equal? pb2-pt (0, 0)
		--assert equal? pick pb2-pt 1 0
		--assert equal? pick pb2-pt 2 0
		
	--test-- "pb-6"			--assert equal? (3, 4) as-point2D 3 4
	--test-- "pb-7"			--assert equal? (4, 5) make point2D! [4.0 5.0]
	--test-- "pb-8"			--assert equal? none attempt [as-point2D 10]
	--test-- "pb-9"			--assert equal? (10, 10) make point2D! 10

	--test-- "pb-10"		--assert (1, -1.#inf) = as-point2D 1 -1.#inf
	--test-- "pb-11"		--assert (1,  1.#inf) = as-point2D 1  1.#inf
	--test-- "pb-12"		--assert "(1, 1.#NAN)" = mold as-point2D 1  1.#nan		; NaN comparisons will all fail
	--test-- "pb-13"		--assert (-1.#inf, 1) = as-point2D -1.#inf 1

	--test-- "pb-14" 		--assert equal? pick (-5, 3) 'x -5
	--test-- "pb-15" 		--assert equal? pick (-5, 3) 'y 3
	--test-- "pb-16" 		--assert error? try [pick (1, 1) 'hello]
		
===end-group===

===start-group=== "point2D - assignment"

	--test-- "pa-1"
		pa1-pt: (1, 1)
		--assert equal? pa1-pt (1, 1)
		pa1-pt/x: 0
		--assert equal? pa1-pt (0, 1)
		pa1-pt/y: 0
		--assert equal? pa1-pt (0, 0)

===end-group===

===start-group=== "point2D - add"

	--test-- "padd-1"
		padd1-pt: (1, 1)
		--assert equal? padd1-pt + 2 (3, 3)
	
	--test-- "padd-2"
		padd2-pt: (1, 1)
		--assert equal? padd2-pt + (2, 1) (3, 2)
		
	--test-- "padd-3"
		padd3-pt: (1, 1)
		--assert equal? padd3-pt + (2147483646, 2147483646) (2147483647, 2147483647)
		
	--test-- "padd-4"
		padd4-pt: (1, 1)
		--assert equal? padd4-pt + 2147483646 (2147483647, 2147483647)
		
===end-group===

===start-group=== "point2D - subtract"

	--test-- "psub-1"
		psub1-pt: (1, 1)
		--assert equal? psub1-pt - 2 (-1, -1)
	
	--test-- "psub-2"
		psub2-pt: (1, 1)
		--assert equal? psub2-pt - (2, 1) (-1, 0)
		
	--test-- "psub-3"
		psub3-pt: (1, 1)
		--assert equal? psub3-pt - (2147483647, 2147483647) (-2147483646, -2147483646)
		
	--test-- "psub-4"
		psub4-pt: (-1, -1)
		--assert equal? psub4-pt - 2147483647 (-2147483648, -2147483648)
		
===end-group===


===start-group=== "point2D - multiply"

	--test-- "pmul-1"
		pmul1-pt: (1, 1)
		--assert equal? pmul1-pt * 2 (2, 2)
	
	--test-- "pmul-2"
		pmul2-pt: (1, 1)
		--assert equal? pmul2-pt * (2, 1) (2, 1)

	--test-- "pmul-3"
		pmul3-pt: (2, 2)
		--assert equal? (4294967296, 4294967296) pmul3-pt * (2147483647, 2147483647)
		
	--test-- "pmul-4"
		pmul4-pt: (-3, -3)
		--assert equal? (6.442451e9, 6.442451e9) pmul4-pt * -2147483648
	
===end-group===

===start-group=== "point2D - divide"

	--test-- "pdiv-1"
		pdiv1-pt: (4, 4)
		--assert equal? pdiv1-pt / 2 (2, 2)
	
	--test-- "pdiv-2"
		pdiv2-pt: (16, 15)
		--assert equal? pdiv2-pt / (2, 1) (8, 15)
		
	--test-- "pdiv-3"
		pdiv3-pt: (2147483647, 2147483647)
		--assert equal? pdiv3-pt / 2 (1073741823, 1073741823)
		
	--test-- "pdiv-4"
		pdiv4-pt: (-2147483648, -2147483648)
		--assert equal? pdiv4-pt / -2147483648 (1, 1)
		
===end-group===

===start-group=== "point2D - remainder"

	--test-- "prem-1"
		prem1-pt: (4, 4)
		--assert equal? prem1-pt % 2 (0, 0)
	
	--test-- "prem-2"
		prem2-pt: (16, 15)
		--assert equal? prem2-pt % (2, 3) (0, 0)
		
	--test-- "prem-3"
		prem3-pt: (7483647, 7483647)
		--assert equal? prem3-pt % 2 (1, 1)
		
	--test-- "prem-4"
		prem4-pt: (-2147483648, -2147483648)
		--assert equal? prem4-pt % -2147483648 (0, 0)
		
===end-group===

===start-group=== "point2D - negate"

	--test-- "pneg-1"
		pneg1-pt: (4, 4)
		--assert equal? negate pneg1-pt (-4, -4)
	
	--test-- "pneg-2"
		pneg2-pt: (-16, -15)
		--assert equal? negate pneg2-pt (16, 15)
		
	--test-- "pneg-3"
		pneg3-pt: (2147483647, 2147483647)
		--assert equal? negate pneg3-pt (-2147483647, -2147483647)

	--test-- "pneg-4"
		pneg4-pt: (-2147483.0, -2147483.0)
		--assert (2147483.0, 2147483.0) = negate pneg4-pt
		
===end-group===

===start-group=== "point2D - reverse"

	--test-- "prev-1"		--assert equal? reverse (1, 2) (2, 1)
	
===end-group===

===start-group=== "point2D - maths with other types"

	--test-- "p3mot-1"		--assert 2   * (1,1) == (2,2)
	--test-- "p3mot-2"		--assert 2.5 * (4,4) == (10,10)
	--test-- "p3mot-3"		--assert 50% * (124, 44) == (62, 22)
	
===end-group===

===start-group=== "point2D - comparison"

	--test-- "pcomp-1"		--assert equal? (1, 1) (1, 1)
	--test-- "pcomp-2"		--assert not-equal? (1, 1) (1, 0)
	--test-- "pcomp-3"		--assert not-equal? (1, 1) (0, 1)
	--test-- "pcomp-4"		--assert not-equal? (1, 1) (0, 0)
	
	--test-- "pcomp-5"		--assert (1, 1) = max (1, 1) (0, 0)
	--test-- "pcomp-6"		--assert (40, 20) = max (10, 20) (40, 10)
	--test-- "pcomp-7"		--assert (10, 10) = min (10, 20) (40, 10)

===end-group===

===start-group=== "point2D - round"

	--test-- "pround-1"		--assert (15, 10) = round/to (17, 8)  5
	--test-- "pround-3"		--assert (15, 10) = round/to (15, 10) 1
	--test-- "pround-3"		--assert (15, 10) = round/to (15, 10) 0
	--test-- "pround-4"		--assert (20, 40) = round/to (22, 33) (10, 20)

===end-group===

===start-group=== "point3D - basic"

	--test-- "p3b-1"
		pb1-pt: (1, 1, 1)
		--assert equal? pb1-pt/x 1
		--assert equal? pb1-pt/y 1
		--assert equal? pb1-pt/z 1
		--assert equal? first pb1-pt 1
		--assert equal? second pb1-pt 1
		--assert equal? third pb1-pt 1
		--assert equal? pb1-pt (1, 1, 1)
		--assert equal? pick pb1-pt 1 1
		--assert equal? pick pb1-pt 2 1
		--assert equal? pick pb1-pt 3 1
		--assert equal? pick pb1-pt 'x 1
		--assert equal? pick pb1-pt 'y 1
		--assert equal? pick pb1-pt 'z 1
		
	--test-- "p3b-2"
		pb2-pt: (0, 0, 0)
		--assert equal? pb2-pt/x 0
		--assert equal? pb2-pt/y 0
		--assert equal? pb2-pt/z 0
		--assert equal? first pb2-pt 0
		--assert equal? second pb2-pt 0
		--assert equal? third pb2-pt 0
		--assert equal? pb2-pt (0, 0, 0)
		--assert equal? pick pb2-pt 1 0
		--assert equal? pick pb2-pt 2 0
		--assert equal? pick pb2-pt 3 0
		
	--test-- "p3b-6"		--assert equal? (3, 4, 5) as-point3D 3 4 5
	--test-- "p3b-7"		--assert equal? (4, 5, 6) make point3D! [4.0 5.0 6.0]
	--test-- "p3b-8"		--assert equal? none attempt [as-point3D 10]
	--test-- "p3b-9"		--assert equal? (10, 10, 10) make point3D! 10

	--test-- "p3b-10"		--assert (1, 2, -1.#inf) = as-point3D 1 2 -1.#inf
	--test-- "p3b-11"		--assert (1, 3, 1.#inf) = as-point3D 1 3 1.#inf
	--test-- "p3b-12"		--assert "(1, 4, 1.#NAN)" = mold as-point3D 1 4 1.#nan		; NaN comparisons will all fail
	--test-- "p3b-13"		--assert (-1.#inf, 1, 2) = as-point3D -1.#inf 1 2

	--test-- "p3b-14" 		--assert equal? pick (-5, 3, 7) 'x -5
	--test-- "p3b-15" 		--assert equal? pick (-5, 3, 7) 'y 3
	--test-- "p3b-15-1" 	--assert equal? pick (-5, 3, 7) 'z 7
	--test-- "p3b-16" 		--assert error? try [pick (1, 1, 1) 'hello]
		
===end-group===

===start-group=== "point3D - assignment"

	--test-- "p3a-1"
		pa1-pt: (1, 1, 1)
		--assert equal? pa1-pt (1, 1, 1)
		pa1-pt/x: 0
		--assert equal? pa1-pt (0, 1, 1)
		pa1-pt/y: 0
		--assert equal? pa1-pt (0, 0, 1)
		pa1-pt/z: 0
		--assert equal? pa1-pt (0, 0, 0)

===end-group===

===start-group=== "point3D - add"

	--test-- "p3add-1"
		padd1-pt: (1, 1, 1)
		--assert equal? padd1-pt + 2 (3, 3, 3)
	
	--test-- "p3add-2"
		padd2-pt: (1, 1, 1)
		--assert equal? padd2-pt + (2, 1, 4) (3, 2, 5)
		
	--test-- "p3add-3"
		padd3-pt: (1, 1, 1)
		--assert equal? padd3-pt + (2147483, 2147483, 2147483) (2147484, 2147484, 2147484)
		
===end-group===

===start-group=== "point3D - subtract"

	--test-- "p3sub-1"
		psub1-pt: (1, 1, 1)
		--assert equal? psub1-pt - 2 (-1, -1, -1)
	
	--test-- "p3sub-2"
		psub2-pt: (1, 1, 1)
		--assert equal? psub2-pt - (2, 1, 2) (-1, 0, -1)
		
	--test-- "p3sub-3"
		psub3-pt: (1, 1, 1)
		--assert equal? psub3-pt - (2147484, 2147484, 2147484) (-2147483, -2147483, -2147483)
		
	--test-- "p3sub-4"
		psub4-pt: (-1, -1, -1)
		--assert equal? psub4-pt - 2147484 (-2147485, -2147485, -2147485)
		
===end-group===


===start-group=== "point3D - multiply"

	--test-- "p3mul-1"
		pmul1-pt: (1, 1, 1)
		--assert equal? pmul1-pt * 2 (2, 2, 2)
	
	--test-- "p3mul-2"
		pmul2-pt: (1, 1, 1)
		--assert equal? pmul2-pt * (2, 1, 3) (2, 1, 3)

	--test-- "p3mul-3"
		pmul3-pt: (2, 2, 2)
		--assert equal? (4294968, 4294968, 4294968) pmul3-pt * (2147484, 2147484, 2147484)
		
	--test-- "p3mul-4"
		pmul4-pt: (-3, -3, -3)
		--assert equal? (6.442451e9, 6.442451e9, 6.442451e9) pmul4-pt * -2147483648
	
===end-group===

===start-group=== "point3D - divide"

	--test-- "p3div-1"
		pdiv1-pt: (4, 4, 4)
		--assert equal? pdiv1-pt / 2 (2, 2, 2)
	
	--test-- "p3div-2"
		pdiv2-pt: (16, 15, 14)
		--assert equal? pdiv2-pt / (2, 1, 2) (8, 15, 7)
		
	--test-- "p3div-3"
		pdiv3-pt: (2147484, 2147484, 2147484)
		--assert equal? pdiv3-pt / 2 (1073742, 1073742, 1073742)
		
	--test-- "p3div-4"
		pdiv4-pt: (-2147483648, -2147483648, -2147483648)
		--assert equal? pdiv4-pt / -2147483648 (1, 1, 1)
		
===end-group===

===start-group=== "point3D - remainder"

	--test-- "p3rem-1"
		prem1-pt: (4, 4, 4)
		--assert equal? prem1-pt % 2 (0, 0, 0)
	
	--test-- "p3rem-2"
		prem2-pt: (16, 15, 14)
		--assert equal? prem2-pt % (2, 3, 7) (0, 0, 0)
		
	--test-- "p3rem-3"
		prem3-pt: (7483647, 7483647, 7483647)
		--assert equal? prem3-pt % 2 (1, 1, 1)
		
	--test-- "p3rem-4"
		prem4-pt: (-2147483648, -2147483648, -2147483648)
		--assert equal? prem4-pt % -2147483648 (0, 0, 0)
		
===end-group===

===start-group=== "point3D - negate"

	--test-- "p3neg-1"
		pneg1-pt: (4, 4, 4)
		--assert equal? negate pneg1-pt (-4, -4, -4)
	
	--test-- "p3neg-2"
		pneg2-pt: (-16, -15, -14)
		--assert equal? negate pneg2-pt (16, 15, 14)
		
	--test-- "p3neg-3"
		pneg3-pt: (2147483647, 2147483647, 2147483647)
		--assert equal? negate pneg3-pt (-2147483647, -2147483647, -2147483647)

	--test-- "p3neg-4"
		pneg4-pt: (-2147483.0, -2147483.0, -2147483.0)
		--assert (2147483.0, 2147483.0, 2147483.0) = negate pneg4-pt
		
===end-group===

===start-group=== "point3D - reverse"

	--test-- "p3rev-1"		--assert equal? reverse (1, 2, 3) (3, 2, 1)
	
===end-group===

===start-group=== "point3D - maths with other types"

	--test-- "p3mot-1"		--assert 2   * (1,1,2) == (2,2,4)
	--test-- "p3mot-2"		--assert 2.5 * (4,4,10) == (10,10,25)
	--test-- "p3mot-3"		--assert 50% * (124, 44, 26) == (62, 22, 13)
	
===end-group===

===start-group=== "point3D - comparison"

	--test-- "p3comp-1"		--assert equal? (1, 1, 1) (1, 1, 1)
	--test-- "p3comp-2"		--assert not-equal? (1, 1, 1) (1, 1, 0)
	--test-- "p3comp-3"		--assert not-equal? (1, 1, 1) (0, 1, 1)
	--test-- "p3comp-4"		--assert not-equal? (1, 1, 1) (0, 0, 0)
	
	--test-- "p3comp-5"		--assert (1, 1, 1) = max (1, 1, 1) (0, 0, 0)
	--test-- "p3comp-6"		--assert (40, 20, 15) = max (10, 20, 5) (40, 10, 15)
	--test-- "p3comp-7"		--assert (10, 10, 10) = min (10, 20, 10) (40, 10, 30)

===end-group===

;===start-group=== "point3D - round"
;
;	--test-- "p3round-1"		--assert (15, 10) = round/to (17, 8)  5
;	--test-- "p3round-3"		--assert (15, 10) = round/to (15, 10) 1
;	--test-- "p3round-3"		--assert (15, 10) = round/to (15, 10) 0
;	--test-- "p3round-4"		--assert (20, 40) = round/to (22, 33) (10, 20)
;
;===end-group===


~~~end-file~~~

