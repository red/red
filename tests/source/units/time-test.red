Red [
	Title:	"Red time! datatype tests"
	Author:	"Gregg Irwin"
	File:	%time-test.red
	Version: 0.0.1
	Rights:	"Copyright (C) 2016 Gregg Irwin. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red

~~~start-file~~~ "time"

===start-group=== "time - basic"

	--test-- "tb-1"
		tb1-t: 1:1:1
		--assert equal? tb1-t/hour 1
		--assert equal? tb1-t/minute 1
		--assert equal? tb1-t/second 1
		--assert equal? first tb1-t 1
		--assert equal? second tb1-t 1
		--assert equal? third tb1-t 1
		--assert equal? tb1-t 1:1:1
		--assert equal? pick tb1-t 1 1
		--assert equal? pick tb1-t 2 1
		--assert equal? pick tb1-t 3 1
		
	--test-- "tb-2"
		tb2-t: 0:0:0
		--assert equal? tb2-t/hour 0
		--assert equal? tb2-t/minute 0
		--assert equal? tb2-t/second 0
		--assert equal? first tb2-t 0
		--assert equal? second tb2-t 0
		--assert equal? third tb2-t 0
		--assert equal? tb2-t 0:0:0
		--assert equal? pick tb2-t 1 0
		--assert equal? pick tb2-t 2 0
		--assert equal? pick tb2-t 3 0
		
	; Max empirical value
	--test-- "tb-3"
		tb3-t: 2147483645:59:59
		--assert equal? tb3-t/hour 2147483645
		--assert equal? tb3-t/minute 59
		--assert equal? tb3-t/second 59
		--assert equal? first tb3-t 2147483645
		--assert equal? second tb3-t 59
		--assert equal? third tb3-t 59
		--assert equal? tb3-t 2147483644:58:58 + 1:1:1
		--assert equal? pick tb3-t 1 2147483645
		--assert equal? pick tb3-t 2 59
		--assert equal? pick tb3-t 3 59
		
; Invalid syntax now (to be removed once that statement is verified)
;	--test-- "tb-4"
;		tb4-t: -1:-0:-0
;		--assert equal? tb4-t/hour -1
;		--assert equal? tb4-t/minute 0
;		--assert equal? tb4-t/second 0
;		--assert equal? first tb4-t -1
;		--assert equal? second tb4-t 0
;		--assert equal? third tb4-t 0
;		--assert equal? tb4-t -1:0:0
;		--assert equal? pick tb4-t 1 0
;		--assert equal? pick tb4-t 2 0
;		--assert equal? pick tb4-t 3 0

		;red>> 2147483647:00
		;== 2147483646:00:00.0
		;red>> 2147483646:00
		;== 2147483645:59:59.9990234
		;red>> 2147483645:00
		;== 2147483645:00:00.0

;!! Won't compile
;	--test-- "tb-e1"
;		--assert error? try [tb-e1-t: -1:-1:-0]
;	--test-- "tb-e2"
;		--assert error? try [tb-e2-t: -1:-0:-1]

; Empirical limits
;	--test-- "tb-4"
;		tb4-t: -2147483647:2147483647					;<-- invalid under R2
;		--assert equal? tb4-t/hour -2147483648
;		--assert equal? tb4-t/minute -2147483648
;		--assert equal? first tb4-t -2147483648
;		--assert equal? second tb4-t -2147483648
;		--assert equal? tb4-t -2147483648:-2147483648
;		--assert equal? pick tb4-t 1 -2147483648
;		--assert equal? pick tb4-t 2 -2147483648
		
;	--test-- "tb-5"
;		tb5-t: 21474836467:2147483647
;		--assert equal? tb5-t/hour 2147483647
;		--assert equal? tb5-t/minute -2147483648
;		--assert equal? first tb5-t 2147483647
;		--assert equal? second tb5-t -2147483648
;		--assert equal? tb5-t 2147483647:-2147483648
;		--assert equal? pick tb5-t 1 2147483647
;		--assert equal? pick tb5-t 2 -2147483648
		
	;--test-- "tb-6"			--assert equal? 1:2:3 make time! [1 2 3]
	;--test-- "tb-7"			--assert equal? 04:05 make time! [4 5]
	;--test-- "tb-8"			--assert equal? 06:00 make time! [6]
	--test-- "tb-9"			--assert equal? 0:0:7 make time! 7
	--test-- "tb-10"		--assert equal? 0:0:0 make time! 0
		
===end-group===

===start-group=== "time - assignment"

	--test-- "ta-1"
		ta1-t: 1:1:1
		--assert equal? ta1-t 1:1:1
		ta1-t/hour: 0
		--assert equal? ta1-t 0:1:1
		ta1-t/minute: 0
		--assert equal? ta1-t 0:0:1
		ta1-t/second: 0
		--assert equal? ta1-t 0:0:0

	--test-- "ta-2"
		ta2-t: 59:59:59
		--assert equal? ta2-t 59:59:59
		ta2-t/hour: 0
		--assert equal? ta2-t 0:59:59
		ta2-t/minute: 0
		--assert equal? ta2-t 0:0:59
		ta2-t/second: 0
		--assert equal? ta2-t 0:0:0

	--test-- "ta-3"
		ta3-t: 1:1:1
		--assert equal? ta3-t 1:1:1
		ta3-t/hour: 0
		--assert equal? ta3-t 0:1:1
		ta3-t/minute: 0
		--assert equal? ta3-t 0:0:1
		ta3-t/second: 0
		--assert equal? ta3-t 0:0:0

	;red>> t: 1:1:1
	;== 1:01:01
	;red>> t/hour: -1
	;== -1
	;red>> t
	;== -0:58:59

	--test-- "ta-4"
		ta4-t: 1:1:1
		ta4-t/hour: -1
		--assert equal? ta4-t -0:58:59

	--test-- "ta-5"
		ta5-t: 1:1:1
		ta5-t/minute: -1
		--assert equal? ta5-t 0:59:01

	--test-- "ta-6"
		ta6-t: 1:1:1
		ta6-t/second: -1
		--assert equal? ta6-t 1:00:59
	
	--test-- "ta-7"
		ta7-t: 0:0:0
		ta7-t/hour: 60
		--assert equal? ta7-t 60:00:00

	--test-- "ta-8"
		ta8-t: 0:0:0
		ta8-t/minute: 60
		--assert equal? ta8-t 1:00:00

	--test-- "ta-9"
		ta9-t: 0:0:0
		ta9-t/second: 60
		--assert equal? ta9-t 0:01:00

	--test-- "ta-10"
		ta10-t: 0:0:0
		ta10-t/second: 59.9999999
		--assert equal? ta10-t 0:00:59.9999999

; console shows 0:00:60 but ta11-t * 10 = 0:09:59.9999999
;	--test-- "ta-11"
;		ta11-t: 0:0:0
;		ta11-t/second: 59.99999999
;		--assert equal? ta11-t 0:00:60
	
	--test-- "ta-12"
		ta12-t1: -1:0:0
		ta12-t2: 0:0:0
		ta12-t2/hour: -1
		--assert equal? ta12-t1 ta12-t2

	--test-- "ta-13"
		ta13-t1: -0:1:0
		ta13-t2: 0:0:0
		ta13-t2/minute: -1
		--assert equal? ta13-t1 ta13-t2

	--test-- "ta-14"
		ta14-t1: -0:0:1
		ta14-t2: 0:0:0
		ta14-t2/second: -1
		--assert equal? ta14-t1 ta14-t2

===end-group===


===start-group=== "time function arguments"

	tf: func [
		ta		[time!]
		tb		[time!]
		return: [integer!]
		/local
			tl [time!]
	][
		tl: ta
		if tl <> ta [return 1]
		tl: tb
		if tl <> tb [return 2]
		1
	]

	--test-- "time-func-args-1"
		--assert 1 = tf 1:1:1 2:2:2

	--test-- "time-func-args-2"
		; quick empirical min/max values
		--assert 1 = tf 170144881:00:05.620492334958379e19 0:00:09.99999e-16

===end-group===


===start-group=== "time function return"

	tf1: func [
		tfi	[integer!]
		return: [time!]
	][
		switch tfi [
			1 [1:1:1]
			2 [170144881:00:05.620492334958379e19]
			3 [0:00:09.99999e-16]
		]
	]
	--test-- "time return 1"
		--assert 1:1:1 = tf1 1
	--test-- "time return 2"
		--assert 170144881:00:05.620492334958379e19 = tf1 2
	--test-- "time return 3"
		--assert 0:00:09.99999e-16 = tf1 3

===end-group===

===start-group=== "basic math"

	--test-- "tbm-1"
		tbm-1-t1: -1:0:0
		tbm-1-t2: 0:0:0 - 1:0:0
		--assert equal? tbm-1-t1 tbm-1-t2

	--test-- "tbm-2"
		tbm-2-t1: -0:1:0
		tbm-2-t2: 0:0:0 - 0:1:0
		--assert equal? tbm-2-t1 tbm-2-t2

	--test-- "tbm-3"
		tbm-3-t1: -0:0:1
		tbm-3-t2: 0:0:0 - 0:0:1
		--assert equal? tbm-3-t1 tbm-3-t2

	--test-- "tbm-4"
		tbm-4-t1: 1:0:0
		tbm-4-t2: 0:0:0 + 1:0:0
		--assert equal? tbm-4-t1 tbm-4-t2

	--test-- "tbm-5"
		tbm-5-t1: 0:1:0
		tbm-5-t2: 0:0:0 + 0:1:0
		--assert equal? tbm-5-t1 tbm-5-t2

	--test-- "tbm-6"
		tbm-6-t1: 0:0:1
		tbm-6-t2: 0:0:0 + 0:0:1
		--assert equal? tbm-6-t1 tbm-6-t2
		
===end-group===

===start-group=== "absolute"
	--test-- "abs1" --assert 0:0:0 = absolute -0:0:0
	--test-- "abs2" --assert 1:0:0 = absolute -1:0:0
	--test-- "abs3" --assert 0:1:0 = absolute -0:1:0
	--test-- "abs4" --assert 0:0:1 = absolute -0:0:1
===end-group===


===start-group=== "even?/odd?"
	--test-- "even1" --assert even? 0:0:0
	--test-- "even2" --assert even? 0:0:2
	--test-- "even3" --assert even? 1:1:2
	--test-- "even4" --assert even? 0:0:2.99999999999999			; Limit before rounding affects result
	--test-- "even5" --assert even? -0:0:2

	--test-- "not-even1" --assert not even? 0:0:1
	--test-- "not-even2" --assert not even? 0:0:3
	--test-- "not-even3" --assert not even? 2:2:3
	--test-- "not-even4" --assert not even? 0:0:1.99999999999999	; Limit before rounding affects result
	--test-- "not-even5" --assert not even? -0:0:1

	--test-- "odd1" --assert odd? 0:0:1
	--test-- "odd2" --assert odd? 0:0:3
	--test-- "odd3" --assert odd? 2:2:3
	--test-- "odd4" --assert odd? 0:0:1.99999999999999				; Limit before rounding affects result
	--test-- "odd5" --assert odd? -0:0:1

	--test-- "not-odd1" --assert not odd? 0:0:0
	--test-- "not-odd2" --assert not odd? 0:0:2
	--test-- "not-odd3" --assert not odd? 1:1:2
	--test-- "not-odd4" --assert not odd? 0:0:2.99999999999999		; Limit before rounding affects result
	--test-- "not-odd5" --assert not odd? -0:0:2
===end-group===

===start-group=== "negate/sign?"
	--test-- "negate1" --assert   0:0:1   = negate -0:0:1
	--test-- "negate2" --assert   0:1:0   = negate -0:1:0
	--test-- "negate3" --assert   1:0:0   = negate -1:0:0
	--test-- "negate4" --assert  -0:0:1   = negate  0:0:1
	--test-- "negate5" --assert  -0:1:0   = negate  0:1:0
	--test-- "negate6" --assert  -1:0:0   = negate  1:0:0
	--test-- "negate7" --assert   1:1:1.1 = negate -1:1:1.1
	--test-- "negate8" --assert  -1:1:1.1 = negate  1:1:1.1
	
	--test-- "sign1" --assert 0 = sign? 0:0:0
	--test-- "sign2" --assert 0 = sign? -0:0:0

	--test-- "sign3" --assert 1 = sign? 0:0:1
	--test-- "sign4" --assert 1 = sign? 0:1:0
	--test-- "sign5" --assert 1 = sign? 1:0:0
	--test-- "sign6" --assert 1 = sign? 1:1:1.1

	--test-- "sign7"  --assert -1 = sign? -0:0:1
	--test-- "sign8"  --assert -1 = sign? -0:1:0
	--test-- "sign9"  --assert -1 = sign? -1:0:0
	--test-- "sign10" --assert -1 = sign? -1:1:1.1
===end-group===

; mod, modulo

===start-group=== "max/min"

;	--test-- "max1"
;		--assert 1:0:0  = max  1:0:0 0:0:0
;		--assert 0:0:0  = max -1:0:0 0:0:0
;	--test-- "max2"
;		--assert 0:1:0  = max  0:1:0 0:0:0
;		--assert 0:0:0  = max -0:1:0 0:0:0
;	--test-- "max3"
;		--assert 0:0:1  = max  0:0:1 0:0:0
;		--assert 0:0:0  = max -0:0:1 0:0:0
;
;	--test-- "min1"
;		--assert  0:0:0 = min  1:0:0 0:0:0
;		--assert -1:0:0 = min -1:0:0 0:0:0
;	--test-- "min2"
;		--assert  0:0:0 = min  0:1:0 0:0:0
;		--assert -0:1:0 = min -0:1:0 0:0:0
;	--test-- "min3"
;		--assert  0:0:0 = min  0:0:1 0:0:0
;		--assert -0:0:1 = min -0:0:1 0:0:0

===end-group===

===start-group=== "negative?/positive?/zero?"

;	--test-- "neg1"  --assert true  = negative? -1:0:0
;	--test-- "neg2"  --assert false = negative?  0:0:0
;	--test-- "neg3"  --assert false = negative?  1:0:0
;	--test-- "neg4"  --assert false = negative?  0:0:1
;	--test-- "pos1"  --assert true  = positive?  1:0:0
;	--test-- "pos2"  --assert false = positive?  0:0:0
;	--test-- "pos3"  --assert false = positive? -1:0:0
;	--test-- "pos4"  --assert false = positive? -0:0:1
;	--test-- "zero1" --assert true  = zero?  0:0:0
;	--test-- "zero2" --assert true  = zero? -0:0:0
;	--test-- "zero3" --assert false = zero?  1:0:0
;	--test-- "zero4" --assert false = zero?  0:1:0
;	--test-- "zero5" --assert false = zero?  0:0:1
;	--test-- "zero6" --assert false = zero? -0:0:1

===end-group===

;===start-group=== "round"

; round/to  0:0:1.4  1	; bogus result in 0.6.2

;	--test-- "round1"  --assert  = round/to 
;	--test-- "round2"  --assert  = round/to 
;
;	--test-- "round3"  --assert  = round/down 
;	--test-- "round4"  --assert  = round/down 
;
;	--test-- "round5"  --assert  = round/even 
;	--test-- "round6"  --assert  = round/even 
;
;	--test-- "round7"  --assert  = round/half-down 
;	--test-- "round8"  --assert  = round/half-down 
;
;	--test-- "round9"  --assert  = round/floor 
;	--test-- "round10" --assert  = round/floor 
;
;	--test-- "round11" --assert  = round/ceiling 
;	--test-- "round12" --assert  = round/ceiling 
;
;	--test-- "round13" --assert  = round/half-ceiling 
;	--test-- "round14" --assert  = round/half-ceiling 
;
;	--test-- "round15" --assert  = round 
;	--test-- "round16" --assert  = round 
;	--test-- "round17" --assert  = round 
;	--test-- "round18" --assert  = round 
;	--test-- "round19" --assert  = round 
;	--test-- "round20" --assert  = round 
;===end-group===

===start-group=== "Rudolf Meijer's Test Cases"
	--test-- "time-RM make z" --assert 0:00:00.0 == make time! 0
	--test-- "time-RM make f" --assert 1:02:03.4 == make time! 3723.4
	--test-- "time-RM form" --assert "0:00:00.0" == form 0:0:0
	--test-- "time-RM mold" --assert "0:00:00.0" == form 0:0:0
	--test-- "time-RM abs" --assert 0:00:01.0 == absolute make time! -1
	--test-- "time-RM add t t" --assert 2:03:04.0 == (1:01:01 + 1:02:03)
	--test-- "time-RM divide t t" --assert 3600.0 == (1:00:00 / 0:00:01)
	--test-- "time-RM divide t f" --assert 0:00:01 == (1:00:00 / 3600.0)
	--test-- "time-RM divide t i" --assert 0:00:01 == (1:00:00 / 3600)
	--test-- "time-RM multiply t f" --assert 2:00:00 == (0:00:01 * 7200.0)
	--test-- "time-RM multiply t i" --assert 2:00:00 == (0:00:01 * 7200)
	--test-- "time-RM multiply i t" --assert 2:00:00 == (7200 * 0:00:01)
	--test-- "time-RM multiply f t" --assert 2:00:00 == (7200.0 * 0:00:01)
	--test-- "time-RM negate" --assert -0:00:01.0 = negate 0:00:01
	--test-- "time-RM remainder t t" --assert 0:00:15.0 == (10:00.0 % 0:45.0)
	--test-- "time-RM round" --assert 0:00:04.0 == round make time! 4.3
	--test-- "time-RM subtract t t" --assert 1:02:03.0 == (2:03:04 - 1:01:01 )
===end-group===

===start-group=== "Result type by action"
	; Arithmetic operations on time! values, by action
	; Credit to Rudolf Meijer
	--test-- "time-RM-action type" --assert time? 0:0:0
	--test-- "time-RM-action abs" --assert time?  absolute  0:0:0
	--test-- "time-RM-action add t t" --assert time?  add 0:0:0 0:0:0
	--test-- "time-RM-action add i t" --assert time?  add 1     0:0:0
	--test-- "time-RM-action add t i" --assert time?  add 0:0:0 1
	--test-- "time-RM-action add f t" --assert time?  add 1.0   0:0:0
	--test-- "time-RM-action add t f" --assert time?  add 0:0:0 1.0
	--test-- "time-RM-action divide t t" --assert float? divide 0:0:5 0:0:2
	--test-- "time-RM-action divide t f" --assert time?  divide 0:0:5 2.5
	--test-- "time-RM-action divide f t" --assert time?  divide 5 0:0:2.5
	--test-- "time-RM-action multiply t t" --assert error? try [multiply 0:0:5 0:0:2]
	--test-- "time-RM-action multiply t f" --assert time?  multiply 0:0:5 2.5
	--test-- "time-RM-action multiply t i" --assert time?  multiply 0:0:5 2
	--test-- "time-RM-action multiply i t" --assert time?  multiply 5 0:0:2.5
	--test-- "time-RM-action multiply f t" --assert time?  multiply 5.5 0:0:2.5
	--test-- "time-RM-action negate" --assert time?  negate 1:0:0
	--test-- "time-RM-action power" --assert error? try [power 1:0:0 2]
	--test-- "time-RM-action remainder t t" --assert time?  remainder 0:0:5 0:0:2
	--test-- "time-RM-action remainder t f" --assert time?  remainder 0:0:5 2.5
	--test-- "time-RM-action remainder t i" --assert time?  remainder 0:0:5 2
	--test-- "time-RM-action remainder f t" --assert time?  remainder 5.5 0:0:2.5
	--test-- "time-RM-action round" --assert time?  round 1:0:0.1
	--test-- "time-RM-action subtract t t" --assert time?  subtract 2:0:0 1:0:0
	--test-- "time-RM-action subtract i t" --assert time?  subtract 1     0:0:0
	--test-- "time-RM-action subtract f t" --assert time?  subtract 1.0   0:0:0
	--test-- "time-RM-action subtract t f" --assert time?  subtract 0:0:0 1.0
	--test-- "time-action subtract t i" --assert time?  subtract 0:0:0 1
===end-group===

~~~end-file~~~
