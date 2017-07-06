Red [
	Title:   "Red date! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %date-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2017 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "date"

===start-group=== "input formats (compile-time lexer)"

	--test-- "cfmt-1" --assert "5-Oct-1999"					= mold 1999-10-5
	--test-- "cfmt-2" --assert "5-Oct-1999"					= mold 1999/10/5
	--test-- "cfmt-3" --assert "5-Oct-1999"					= mold 5-10-1999
	--test-- "cfmt-4" --assert "5-Oct-1999"					= mold 5/10/1999
	--test-- "cfmt-5" --assert "5-Oct-1999"					= mold 5-October-1999
	--test-- "cfmt-6" --assert "11-Sep-1999"				= mold 1999-9-11
	--test-- "cfmt-7" --assert "11-Sep-1999"				= mold 11-9-1999
	--test-- "cfmt-8" --assert "5-Sep-2012"					= mold 5/sep/2012
	--test-- "cfmt-9" --assert "5-Sep-2012"					= mold 5-SEPTEMBER-2012

	--test-- "cfmt-10" --assert "2-Mar-2004"				= mold 02/03/04
	--test-- "cfmt-11" --assert "2-Mar-1971"				= mold 02/03/71
	
	--test-- "cfmt-12" --assert "5-Sep-2012/6:00:00"		= mold 5/9/2012/6:0
	--test-- "cfmt-13" --assert "5-Sep-2012/6:00:00"		= mold 5/9/2012/6:00
	--test-- "cfmt-14" --assert "5-Sep-2012/6:00:00+08:00"	= mold 5/9/2012/6:00+8
	--test-- "cfmt-15" --assert "5-Sep-2012/6:00:00"		= mold 5/9/2012/6:0
	--test-- "cfmt-16" --assert "4-Apr-2000/6:00:00+08:00"	= mold 4/Apr/2000/6:00+8:00
	--test-- "cfmt-17" --assert "2-Oct-1999/2:00:00-04:00"	= mold 1999-10-2/2:00-4:00
	--test-- "cfmt-18" --assert "1-Jan-1990/12:20:25-06:00"	= mold 1/1/1990/12:20:25-6
	
===end-group===

===start-group=== "input formats (run-time lexer)"

	--test-- "rfmt-1" --assert 5-Oct-1999  				  = load "1999-10-5"
	--test-- "rfmt-2" --assert 5-Oct-1999  				  = load "1999/10/5"
	--test-- "rfmt-3" --assert 5-Oct-1999  				  = load "5-10-1999"
	--test-- "rfmt-4" --assert 5-Oct-1999  				  = load "5/10/1999"
	--test-- "rfmt-5" --assert 5-Oct-1999  				  = load "5-October-1999"
	--test-- "rfmt-6" --assert 11-Sep-1999 				  = load "1999-9-11"
	--test-- "rfmt-7" --assert 11-Sep-1999 				  = load "11-9-1999"
	--test-- "rfmt-8" --assert 5-Sep-2012  				  = load "5/sep/2012"
	--test-- "rfmt-9" --assert 5-Sep-2012  				  = load "5-SEPTEMBER-2012"

	--test-- "rfmt-10" --assert 2-Mar-2004	 			  = load "02/03/04"
	--test-- "rfmt-11" --assert 2-Mar-1971				  = load "02/03/71"
	
	--test-- "rfmt-12" --assert 5-Sep-2012/6:00:00		  = load "5/9/2012/6:0"
	--test-- "rfmt-13" --assert 5-Sep-2012/6:00:00		  = load "5/9/2012/6:00"
	--test-- "rfmt-14" --assert 5-Sep-2012/6:00:00+08:00  = load "5/9/2012/6:00+8"
	--test-- "rfmt-15" --assert 5-Sep-2012/6:00:00	 	  = load "5/9/2012/6:0"
	--test-- "rfmt-16" --assert 4-Apr-2000/6:00:00+08:00  = load "4/Apr/2000/6:00+8:00"
	--test-- "rfmt-17" --assert 2-Oct-1999/2:00:00-4:00   = load "1999-10-2/2:00-4:00"
	--test-- "rfmt-18" --assert 1-Jan-1990/12:20:25-06:00 = load "1/1/1990/12:20:25-6"

===end-group===

===start-group=== "comparisons"

	--test-- "cmp1"	 --assert 3-Jul-2017/9:41:40+2:00 = 3-Jul-2017/5:41:40-2:00
	--test-- "cmp2"	 --assert 10/5/1970 < 1/1/1980
	--test-- "cmp3"	 --assert not 10/5/1970 >= 1/1/1980
	--test-- "cmp4"	 --assert 10/5/1970/10:10:10 < 1/1/1980
	--test-- "cmp5"	 --assert 10/5/1970/10:10:10 < 1/1/1980/2:2:2
	--test-- "cmp6"	 --assert 10/5/1970/10:10:10+4:00 < 1/1/1980/2:2:2+8:00
	--test-- "cmp7"	 --assert not 10/5/1970/10:10:10 >= 1/1/1980
	--test-- "cmp8"	 --assert not 10/5/1970/10:10:10 >= 1/1/1980/2:2:2
	--test-- "cmp9"	 --assert not 10/5/1970/10:10:10+4:00 >= 1/1/1980/2:2:2+8:00
	--test-- "cmp10" --assert 10/5/-1970 < 1/1/1950
	--test-- "cmp11" --assert 10/5/-1970 < 1/1/-1950
	--test-- "cmp12" --assert 10/5/-1970/10:10:10+4:00 < 1/1/1950/2:2:2+8:00
	--test-- "cmp13" --assert 10/5/-1970/10:10:10+4:00 < 1/1/-1950/2:2:2+8:00
	--test-- "cmp14" --assert not 10/5/-1970 >= 1/1/1950
	--test-- "cmp15" --assert not 10/5/-1970 >= 1/1/-1950
	--test-- "cmp16" --assert not 10/5/-1970/10:10:10+4:00 >= 1/1/1950/2:2:2+8:00
	--test-- "cmp17" --assert not 10/5/-1970/10:10:10+4:00 >= 1/1/-1950/2:2:2+8:00
	
	--test-- "cmp30"
		--assert [
			10/May/-1970
			10/May/-1970/10:10:10+04:00
			1/Jan/-1950/2:02:02+08:00
			1/Jan/-1950
			1-Jan-0001
			1-Jan-1950/2:02:02+08:00
			10-May-1970/10:10:10
			10-May-1970/10:10:10
			1-Jan-1980/2:02:02
			5-Oct-1999
			1-Jan-2017
			3-Jul-2017/5:41:40-02:00
		] = sort [
			1/1/0001
			1/1/2017
			5/10/1999
			1/1/1950/2:2:2+8:00
			10/5/-1970
			1/1/-1950/2:2:2+8:00
			10/5/-1970/10:10:10+4:00
			1/1/1980/2:2:2
			10/5/1970/10:10:10
			3-Jul-2017/5:41:40-2:00
			1/1/-1950
			10/5/1970/10:10:10
		]

===end-group===

===start-group=== "MAKE date!"

	--test-- "make1"	--assert 3-Feb-1978				  = make date! [1978 2 3]
	--test-- "make2"	--assert 3-Feb-1978/5:00:00+08:00 = make date! [1978 2 3 5:0:0 8]
	--test-- "make3"	--assert 3-Feb-1978/5:00:00 	  = make date! [1978 2 3 5:0:0]
	--test-- "make4"	--assert 3-Feb-1978/5:20:30 	  = make date! [1978 2 3 5 20 30]
	--test-- "make5"	--assert 3-Feb-1978/5:20:30-4:00  = make date! [1978 2 3 5 20 30 -4]
	--test-- "make6"	--assert 3-Feb-1978/5:20:30+4:00  = make date! [1978 2 3 5 20 30 4]
	--test-- "make7"	--assert error? try [make date! [1978 2 3 5]]
	--test-- "make8"	--assert error? try [make date! [1978 2 3 5 20]]

===end-group===

===start-group=== "path accessors"
	d: 5-Jul-2017/12:41:40+08:00
	
	--test-- "pathr-1"  --assert d/year    = 2017
	--test-- "pathr-2"  --assert d/month   = 7
	--test-- "pathr-3"  --assert d/day     = 5
	--test-- "pathr-4"  --assert d/hour	   = 12
	--test-- "pathr-5"  --assert d/minute  = 41
	--test-- "pathr-6"  --assert d/second  = 40
	--test-- "pathr-7"  --assert d/zone    = 8:00
	--test-- "pathr-8"  --assert d/time	   = 12:41:40
	--test-- "pathr-9"  --assert d/weekday = 3
	--test-- "pathr-10" --assert d/yearday = 186
	--test-- "pathr-11" --assert d/yearday = d/julian
	
	--test-- "pw-year"
		d: 5-Jul-2017/12:41:40+08:00
		d/year:	1981
		--assert d/year = 1981
		
		;d: 5-Jul-2017/12:41:40+08:00
		;d/year: 0
		;--assert d/year = 0
		;--assert d = 5-Jul-0000/12:52:06+08:00
		
		d: 5-Jul-2017/12:41:40+08:00
		d/year: -150
		--assert d/year = -150
		--assert "5/Jul/-150/12:41:40+08:00" = mold d
		
		d: 5-Jul-2017/12:41:40+08:00
		d/year: 12345678
		--assert "5-Jul-24910/12:41:40+08:00" = mold d
	
	
	--test-- "pw-month1"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 2
		--assert d/month = 2
		--assert d = 5-Feb-2017/12:41:40+08:00
	
	--test-- "pw-month2"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: -2
		--assert d/month = 10
		--assert d = 5-Oct-2017/12:41:40+08:00
		
	--test-- "pw-month3"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 20
		--assert d = 5-Aug-2018/12:41:40+08:00

	--test-- "pw-month4"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 0
		--assert d = 5-Dec-2016/12:41:40+08:00
	
	
	--test-- "pw-day1"
		d: 5-Jul-2017/12:41:40+08:00
		d/day: 20
		--assert d/day = 20
		--assert d = 20-Jul-2017/12:41:40+08:00
		
	--test-- "pw-day2"
		d: 5-Jul-2017/12:41:40+08:00
		d/day: -15
		--assert d/day = 15
		--assert d = 15-Jun-2017/12:41:40+08:00
	
	--test-- "pw-day3"
		d: 5-Jul-2017/12:41:40+08:00
		d/day: -150
		--assert d/day = 31
		--assert d = 31-Jan-2017/12:41:40+08:00
		
	--test-- "pw-day4"
		d: 5-Jul-2017/12:41:40+08:00
		d/day: 500
		--assert d/day = 12
		--assert d = 12-Nov-2018/12:41:40+08:00
	
	--test-- "pw-day5"
		d: 5-Jul-2017/12:41:40+08:00
		d/day: 0
		--assert d/day = 30
		--assert d = 30-Jun-2017/12:41:40+08:00
	
	
	--test-- "pw-hour1"
		d: 5-Jul-2017/12:41:40+08:00
		d/hour: 19
		--assert d/hour = 19
		--assert d = 5-Jul-2017/19:41:40+08:00
		
	--test-- "pw-hour2"
		d: 5-Jul-2017/12:41:40+08:00
		d/hour: -19
		--assert d/hour = 5
		--assert d = 4-Jul-2017/5:41:40+08:00
		
	--test-- "pw-hour3"
		d: 5-Jul-2017/12:41:40+08:00
		d/hour: -150
		--assert d/hour = 18
		--assert d = 28-Jun-2017/18:41:40+08:00
		
	--test-- "pw-hour4"
		d: 5-Jul-2017/12:41:40+08:00
		d/hour: 150
		--assert d/hour = 6
		--assert d = 11-Jul-2017/6:41:40+08:00
		
	--test-- "pw-hour5"
		d: 5-Jul-2017/12:41:40+08:00
		d/hour: 0
		--assert d/hour = 0
		--assert d = 5-Jul-2017/0:41:40+08:00
		
	--test-- "pw-hour6"
		d: 5-Jul-2017/12:41:40-4:00
		d/hour: 19
		--assert d/hour = 19
		--assert "5-Jul-2017/19:41:40-04:00" = mold d
		
	--test-- "pw-hour7"
		d: 5-Jul-2017/12:41:40-4:00
		d/hour: -19
		--assert d/hour = 5
		--assert "4-Jul-2017/5:41:40-04:00" = mold d
	
	
	--test-- "pw-minute1"
		d: 5-Jul-2017/12:41:40+08:00
		d/minute: 7
		--assert d/minute = 7
		--assert d = 5-Jul-2017/12:07:40+08:00

	--test-- "pw-minute2"
		d: 5-Jul-2017/12:41:40+08:00
		d/minute: -36
		--assert d/minute = 24
		--assert d = 5-Jul-2017/11:24:40+08:00

	--test-- "pw-minute3"
		d: 5-Jul-2017/12:41:40+08:00
		d/minute: -150
		--assert d/minute = 30
		--assert d = 5-Jul-2017/9:30:40+08:00

	--test-- "pw-minute4"
		d: 5-Jul-2017/12:41:40+08:00
		d/minute: 150
		--assert d/minute = 30
		--assert d = 5-Jul-2017/14:30:40+08:00
	
	--test-- "pw-minute5"
		d: 5-Jul-2017/12:41:40+08:00
		d/minute: 0
		--assert d/minute = 0
		--assert d = 5-Jul-2017/12:00:40+08:00
		
	--test-- "pw-minute6"
		d: 5-Jul-2017/12:41:40-4:00
		d/minute: 1500
		--assert d/minute = 0
		--assert "6-Jul-2017/13:00:40-04:00" = mold d

	--test-- "pw-minute7"
		d: 5-Jul-2017/12:41:40-4:00
		d/minute: -1500
		--assert d/minute = 0
		--assert "4-Jul-2017/11:00:40-04:00" = mold d
	
	
	--test-- "pw-second1"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: 7
		--assert d/second = 7
		--assert d = 5-Jul-2017/12:41:07+08:00

	--test-- "pw-second2"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: -36
		--assert d/second = 24
		--assert d = 5-Jul-2017/12:40:24+08:00

	--test-- "pw-second3"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: -150
		--assert d/second = 30
		--assert d = 5-Jul-2017/12:38:30+08:00

	--test-- "pw-second4"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: 150
		--assert d/second = 30
		--assert d = 5-Jul-2017/12:43:30+08:00
	
	--test-- "pw-second5"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: 0
		--assert d/second = 0
		--assert d = 5-Jul-2017/12:41:00+08:00
	
	--test-- "pw-second6"
		d: 5-Jul-2017/12:41:40+08:00
		d/second: 100000
		--assert d/second = 40
		--assert d = 6-Jul-2017/16:27:40+08:00
	
	
	--test-- "pw-zone1"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: 1
		--assert d/zone = 1:00
		--assert d = 5-Jul-2017/12:41:40+1:00
	
	--test-- "pw-zone2"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: 2:45
		--assert d/zone = 2:45
		--assert "5-Jul-2017/12:41:40+02:45" = mold d
	
	--test-- "pw-zone3"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: 3.14
		--assert d/zone = 3:00
		--assert d = 5-Jul-2017/12:41:40+3:00
		
	--test-- "pw-zone4"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: -4
		--assert d/zone = -4:00
		--assert d = 5-Jul-2017/12:41:40-4:00
	
	--test-- "pw-zone5"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: -5:15
		--assert d/zone = -5:15
		--assert "5-Jul-2017/12:41:40-05:15" = mold d
	
	--test-- "pw-zone6"
		d: 5-Jul-2017/12:41:40+08:00
		d/zone: 6:24
		--assert d/zone = 6:15
		--assert "5-Jul-2017/12:41:40+06:15" = mold d
	
	
	--test-- "pw-time1"
		d: 5-Jul-2017/12:41:40+08:00
		d/time: 5:12:34
		--assert d/time = 5:12:34
		--assert d = 5-Jul-2017/5:12:34+08:00

	--test-- "pw-time2"
		d: 5-Jul-2017/12:41:40-06:00
		d/time: 5:12:34
		--assert d/time = 5:12:34
		--assert d = 5-Jul-2017/5:12:34-6:00

	--test-- "pw-time3"
		d: 5-Jul-2017/12:41:40+08:00
		d/time: 10:00
		--assert d/time = 10:00
		--assert d = 5-Jul-2017/10:00:00+08:00

	--test-- "pw-time4"
		d: 5-Jul-2017/12:41:40+08:00
		d/time: -20:00
		--assert d/time = 4:00:00
		--assert d = 4-Jul-2017/4:00:00+08:00

	--test-- "pw-time5"
		d: 5-Jul-2017/12:41:40-4:00
		d/time: -20:00
		--assert d/time = 4:00:00
		--assert d = 4-Jul-2017/4:00:00-4:00


	--test-- "pw-weekday1"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: 1
		--assert d/weekday = 1
		--assert d = 3-Jul-2017/12:41:40+8:00
	
	--test-- "pw-weekday2"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: 7
		--assert d/weekday = 7
		--assert d = 9-Jul-2017/12:41:40+8:00
	
	--test-- "pw-weekday3"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: 0
		--assert d/weekday = 7
		--assert d = 2-Jul-2017/12:41:40+8:00
	
	--test-- "pw-weekday4"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: -1
		--assert d/weekday = 6
		--assert d = 1-Jul-2017/12:41:40+8:00
	
	--test-- "pw-weekday5"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: -2
		--assert d/weekday = 5
		--assert d = 30-Jun-2017/12:41:40+8:00
		
	--test-- "pw-weekday6"
		d: 5-Jul-2017/12:41:40+8:00
		d/weekday: 8
		--assert d/weekday = 1
		--assert d = 10-Jul-2017/12:41:40+8:00
	
	
	--test-- "pw-yearday1"
		d: 5-Jul-2017/12:41:40+8:00
		d/yearday: 1
		--assert d/yearday = 1
		--assert d = 1-Jan-2017/12:41:40+8:00
	
	--test-- "pw-yearday2"
		d: 5-Jul-2017/12:41:40+8:00
		d/yearday: 100
		--assert d/yearday = 100
		--assert d = 10-Apr-2017/12:41:40+08:00

	--test-- "pw-yearday3"
		d: 5-Jul-2017/12:41:40+8:00
		d/yearday: 500
		--assert d/yearday = 135
		--assert d = 15-May-2018/12:41:40+08:00
	
	--test-- "pw-yearday4"
		d: 5-Jul-2017/12:41:40+8:00
		d/yearday: 0
		--assert d/yearday = 366
		--assert d = 31-Dec-2016/12:41:40+08:00
	
	--test-- "pw-yearday5"
		d: 5-Jul-2017/12:41:40+8:00
		d/yearday: -100
		--assert d/yearday = 266
		--assert d = 22-Sep-2016/12:41:40+08:00
		
	--test-- "julianday" --assert d/yearday = d/julian

===end-group===

===start-group=== "math on dates"

	d: 5-Jul-2017/12:41:40+8:00
	--test-- "math-1"	--assert d + 0	  = 5-Jul-2017/12:41:40+08:00
	--test-- "math-2"	--assert d + 1	  = 6-Jul-2017/12:41:40+08:00
	--test-- "math-3"	--assert d + 10   = 15-Jul-2017/12:41:40+08:00
	--test-- "math-4"	--assert d + 100  = 13-Oct-2017/12:41:40+08:00 
	--test-- "math-5"	--assert d + 1000 = 31-Mar-2020/12:41:40+08:00
	--test-- "math-6"	--assert d - 1	  = 4-Jul-2017/12:41:40+08:00
	--test-- "math-7"	--assert d - 10   = 25-Jun-2017/12:41:40+08:00
	--test-- "math-8"	--assert d - 100  = 27-Mar-2017/12:41:40+08:00
	--test-- "math-9"	--assert d - 1000 = 9-Oct-2014/12:41:40+08:00
	--test-- "math-10"	--assert (d + -1000) = (d - 1000)
	--test-- "math-11"	--assert (d - -1000) = (d + 1000)

	--test-- "math-20"	--assert 0:0:0 = difference d d
	--test-- "math-21"	--assert 4444:41:40 = round/to difference d 1/1/2017 1E-3
	--test-- "math-22"	--assert -4:00 = difference d 5-Jul-2017/12:41:40+4:00
	--test-- "math-23"	--assert -13:00 = difference d 5-Jul-2017/12:41:40-5:00
	--test-- "math-24"	--assert -3259:18:20 = round/to difference d 18-11-2017 1E-3
	--test-- "math-25"	--assert -29563:18:20 = round/to difference d 18-11-2020 1E-3
	;difference d 5-Jul-2017/12:41:40-5:15
	
	--test-- "math-30"	--assert  1 + d = 6-Jul-2017/12:41:40+08:00
	--test-- "math-31"	--assert -1 + d = 4-Jul-2017/12:41:40+08:00

===end-group===

===start-group=== "date conversions"

	--test-- "conv-1"	--assert 1499229700 = to-integer 5-Jul-2017/12:41:40+8:00
	--test-- "conv-1"	--assert 1499258500 = to-integer 5-Jul-2017/12:41:40
	--test-- "conv-1"	--assert 1499272900 = to-integer 5-Jul-2017/12:41:40-4:00
	--test-- "conv-1"	--assert 0 = to-integer 1/1/1970
	--test-- "conv-1"	--assert -31536000  = to-integer 1/1/1969
	--test-- "conv-1"	--assert 946684800  = to-integer 1/1/2000
	
	--test-- "conv-1"	--assert 5-Jul-2017/4:41:40  = to-date 1499229700
	--test-- "conv-1"	--assert 5-Jul-2017/12:41:40 = to-date 1499258500
	--test-- "conv-1"	--assert 5-Jul-2017/16:41:40 = to-date 1499272900
	--test-- "conv-1"	--assert 1/1/1970 = to-date 0
	--test-- "conv-1"	--assert 1/1/1969 = to-date -31536000
	--test-- "conv-1"	--assert 1/1/2000 = to-date 946684800
	--test-- "conv-1"	--assert 31-Dec-1999/23:00:34 = to-date 946681234

===end-group===

===start-group=== "date misc"

	--test-- "misc-1"
		--assert "1-Jan-0001" = mold 1/1/0001
		--assert "1-Jan-0001" = mold load "1/1/0001"

	--test-- "misc-2"
		;d: 1/1/0000	;@@ not supported by compiler yet
		d: 1/1/0001
		d: d - 366
		--assert "31/Dec/-1" = mold d

	;random action tests

===end-group===

~~~end-file~~~
