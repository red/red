Red [
	Title:   "Red date! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %date-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
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
	--test-- "cfmt-15" --assert "5-Sep-2012/6:00:00+04:30"	= mold 5/9/2012/6:0+0430
	--test-- "cfmt-16" --assert "4-Apr-2000/6:00:00+08:00"	= mold 4/Apr/2000/6:00+8:00
	--test-- "cfmt-17" --assert "2-Oct-1999/2:00:00-04:00"	= mold 1999-10-2/2:00-4:00
	--test-- "cfmt-18" --assert "1-Jan-1990/12:20:25-06:00"	= mold 1/1/1990/12:20:25-6
	
	--test-- "cfmt-19" --assert "7-Jul-2017/8:22:23"		= mold 2017-07-07T08:22:23+00:00
	--test-- "cfmt-20" --assert "7-Jul-2017/8:22:23"		= mold 2017-07-07T08:22:23Z
	--test-- "cfmt-21" --assert "7-Jul-2017/8:22:23"		= mold 20170707T082223Z
	--test-- "cfmt-22" --assert "7-Jul-2017/8:22:00"		= mold 20170707T0822Z
	--test-- "cfmt-23" --assert "7-Jul-2017/8:22:23+05:30"	= mold 20170707T082223+0530
	
	
	--test-- "cfmt-24" --assert "2-Jan-2017" 				= mold 2017-W01
	--test-- "cfmt-25" --assert "9-Jun-2017" 				= mold 2017-W23-5
	--test-- "cfmt-26" --assert "1-Jan-2017" 				= mold 2017-001
	--test-- "cfmt-27" --assert "2-Jun-2017" 				= mold 2017-153
	--test-- "cfmt-28" --assert "2-Jan-2017/10:50:00"		= mold 2017-W01T10:50
	--test-- "cfmt-29" --assert "9-Jun-2017/10:50:00-04:00"	= mold 2017-W23-5T10:50:00-4:00
	--test-- "cfmt-30" --assert "1-Jan-2017/10:50:00" 		= mold 2017-001T10:50
	--test-- "cfmt-31" --assert "2-Jun-2017/10:50:00-04:00" = mold 2017-153T10:50:00-4:00
	
	
	--test-- "cfmt-40" --assert "3-Mar-0000/13:44:24+09:15"		= mold 3-Mar-0000/13:44:24+09:15
	--test-- "cfmt-41" --assert "3-Mar-2017/13:44:24-02:15"		= mold 3-Mar-2017/13:44:24-02:15
	--test-- "cfmt-42" --assert "3-Mar-2017/13:44:24-02:00"		= mold 3-Mar-2017/13:44:24-02:00
	--test-- "cfmt-43" --assert "[3-Mar-0000/13:44:24+09:15]"	= mold [3-Mar-0000/13:44:24+09:15]
	--test-- "cfmt-44" --assert "[3-Mar-2017/13:44:24+09:00]"	= mold [3-Mar-2017/13:44:24+09:00]
	--test-- "cfmt-45" --assert "[3-Mar-2017/13:44:24-02:00]"	= mold [3-Mar-2017/13:44:24-02:00]
	--test-- "cfmt-46" --assert "[3-Mar-2017/13:44:24-02:15]"	= mold [3-Mar-2017/13:44:24-02:15]
	--test-- "cfmt-47" --assert "[3-Mar-2017/13:44:24]"			= mold [3-Mar-2017/13:44:24]

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

	--test-- "rfmt-19" --assert 7-Jul-2017/8:22:23		  = load "2017-07-07T08:22:23+00:00"
	--test-- "rfmt-20" --assert 7-Jul-2017/8:22:23		  = load "2017-07-07T08:22:23Z"
	--test-- "rfmt-21" --assert 7-Jul-2017/8:22:23		  = load "20170707T082223Z"
	--test-- "rfmt-22" --assert 7-Jul-2017/8:22:00		  = load "20170707T0822Z"
	--test-- "rfmt-23" --assert 7-Jul-2017/8:22:23+05:30  = load "20170707T082223+0530"
	
	--test-- "rfmt-24" --assert 2-Jan-2017 				  = load "2017-W01"
	--test-- "rfmt-25" --assert 9-Jun-2017 				  = load "2017-W23-5"
	--test-- "rfmt-26" --assert 1-Jan-2017 				  = load "2017-001"
	--test-- "rfmt-27" --assert 2-Jun-2017 				  = load "2017-153"
	--test-- "rfmt-28" --assert 2-Jan-2017/10:50:00		  = load "2017-W01T10:50"
	--test-- "rfmt-29" --assert 9-Jun-2017/10:50:00-04:00 = load "2017-W23-5T10:50:00-4:00"
	--test-- "rfmt-30" --assert 1-Jan-2017/10:50:00		  = load "2017-001T10:50"
	--test-- "rfmt-31" --assert 2-Jun-2017/10:50:00-04:00 = load "2017-153T10:50:00-4:00"

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

===start-group=== "dates creation"

	--test-- "make1"	--assert 3-Feb-1978				  = make date! [1978 2 3]
	--test-- "make2"	--assert 3-Feb-1978/5:00:00+08:00 = make date! [1978 2 3 5:0:0 8]
	--test-- "make3"	--assert 3-Feb-1978/5:00:00 	  = make date! [1978 2 3 5:0:0]
	--test-- "make4"	--assert 3-Feb-1978/5:20:30 	  = make date! [1978 2 3 5 20 30]
	--test-- "make5"	--assert 3-Feb-1978/5:20:30-4:00  = make date! [1978 2 3 5 20 30 -4]
	--test-- "make6"	--assert 3-Feb-1978/5:20:30+4:00  = make date! [1978 2 3 5 20 30 4]
	--test-- "make7"	--assert error? try [make date! [1978 2 3 5]]
	--test-- "make8"	--assert error? try [make date! [1978 2 3 5 20]]
	--test-- "make10"	--assert error? try [make date! [1981 2 29]]
	--test-- "make11"	--assert error? try [make date! [1 2 2017 23 70 0 4:30]]
	--test-- "make12"	--assert error? try [make date! [1 2 2017 23:70:0 4:30]]
	
	--test-- "make14"	--assert 3-Feb-1978				  = make date! [3 2 1978]
	--test-- "make15"	--assert 3-Feb-1978/5:20:30+4:00  = make date! [3 2 1978 5 20 30 4]
	--test-- "make16"	--assert 1-Jan-0001 			  = make date! [1 1 1]
	--test-- "make17"	--assert 1-Jan-0002 			  = make date! [1 1 2]
	--test-- "make18"	--assert 30-Jan-0002			  = make date! [30 1 2]
	--test-- "make19"	--assert error? try [make date! [32 1 2]]
	--test-- "make20"	--assert error? try [make date! [99 1 2]]
	--test-- "make21"	--assert 2-Jan-0100				  = make date! [100 1 2]
	
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
	--test-- "pathr-12" --assert d/week	   = 27
	--test-- "pathr-13" --assert d/isoweek = 27
	
	--test-- "pw-year"
		d: 5-Jul-2017/12:41:40+08:00
		d/year:	1981
		--assert d/year = 1981
		
		d: 5-Jul-2017/12:41:40+08:00
		d/year: 0
		--assert d/year = 0
		--assert d = 5-Jul-0000/12:41:40+08:00
		
		d: 5-Jul-2017/12:41:40+08:00
		d/year: -150
		--assert d/year = -150
		--assert "5/Jul/-150/12:41:40+08:00" = mold d
		
		d: 5-Jul-2017/12:41:40+08:00
		d/year: 123456
		--assert "5/Jul/-7616/12:41:40+08:00" = mold d
	
	
	--test-- "pw-month1"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 2
		--assert d/month = 2
		--assert d = 5-Feb-2017/12:41:40+08:00
	
	--test-- "pw-month2"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: -2
		--assert d/month = 10
		--assert d = 5-Oct-2016/12:41:40+08:00
		
	--test-- "pw-month3"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 20
		--assert d = 5-Aug-2018/12:41:40+08:00

	--test-- "pw-month4"
		d: 5-Jul-2017/12:41:40+08:00
		d/month: 0
		--assert d = 5-Dec-2016/12:41:40+08:00
	
	--test-- "pw-month5"
		d: 31-jan-2017
		d/month: 2
		--assert d = 3-Mar-2017
	
	
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
		
	--test-- "pw-zone7"
		d: 6-Jul-2017/1:51:42-09:00
		d/zone: -9:00
		--assert d/zone = -9:00
		--assert "6-Jul-2017/1:51:42-09:00" = mold d
		
	--test-- "pw-zone8"
		d: 6-Jul-2017/1:51:42+2:00
		d/zone: -9:00
		--assert d/zone = -9:00
		--assert "6-Jul-2017/1:51:42-09:00" = mold d
	
	
	--test-- "pw-timezone1"
		d: 5-Jul-2017/12:41:40+08:00
		d/timezone: 1
		--assert d/timezone = 1:00
		--assert d = 5-Jul-2017/5:41:40+01:00

	--test-- "pw-timezone2"
		d: 5-Jul-2017/12:41:40+08:00
		d/timezone: 2:45
		--assert d/timezone = 2:45
		--assert "5-Jul-2017/7:26:40+02:45" = mold d

	--test-- "pw-timezone4"
		d: 5-Jul-2017/12:41:40+08:00
		d/timezone: -4
		--assert d/timezone = -4:00
		--assert d = 5-Jul-2017/0:41:40-04:00

	--test-- "pw-timezone5"
		d: 5-Jul-2017/12:41:40+08:00
		d/timezone: -5:15
		--assert d/timezone = -5:15
		--assert "4-Jul-2017/23:26:40-05:15" = mold d

	--test-- "pw-timezone6"
		d: 5-Jul-2017/12:41:40+08:00
		d/timezone: 6:24
		--assert d/timezone = 6:15
		--assert "5-Jul-2017/11:05:40+06:15" = mold d

	--test-- "pw-timezone7"
		d: 6-Jul-2017/1:51:42-09:00
		d/timezone: -9:00
		--assert d/timezone = -9:00
		--assert "6-Jul-2017/1:51:42-09:00" = mold d
		
	--test-- "pw-timezone8"
		d: 6-Jul-2017/1:51:42+2:00
		d/timezone: -9:00
		--assert d/timezone = -9:00
		--assert "5-Jul-2017/14:51:42-09:00" = mold d
	
	
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
		
		
	--test-- "pw-week1"
		d: 5-Jul-2017/12:41:40+8:00
		d/week: 100
		--assert d/week = 48
		--assert d = 25-Nov-2018/12:41:40+08:00

	--test-- "pw-week2"
		d: 5-Jul-2017/12:41:40+8:00
		d/week: 500
		--assert d/week = 31
		--assert d = 26-Jul-2026/12:41:40+08:00

	--test-- "pw-week3"
		d: 5-Jul-2017/12:41:40+8:00
		d/week: 0
		--assert d/week = 1
		--assert d = 1-Jan-2017/12:41:40+08:00

	--test-- "pw-week4"
		d: 5-Jul-2017/12:41:40+8:00
		d/week: -100
		--assert d/week = 1
	--assert d = 1-Jan-2017/12:41:40+08:00
	
	
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
	--test-- "math-26"	--assert 0.000123 = to float! difference 1-1-70/0:0:0.000123 1-Jan-1970
	;difference d 5-Jul-2017/12:41:40-5:15
	
	--test-- "math-30"	--assert  1 + d = 6-Jul-2017/12:41:40+08:00
	--test-- "math-31"	--assert -1 + d = 4-Jul-2017/12:41:40+08:00

===end-group===

===start-group=== "date conversions"

	--test-- "conv-1"	--assert 1499229700 = to-integer 5-Jul-2017/12:41:40+8:00
	--test-- "conv-2"	--assert 1499258500 = to-integer 5-Jul-2017/12:41:40
	--test-- "conv-3"	--assert 1499272900 = to-integer 5-Jul-2017/12:41:40-4:00
	--test-- "conv-4"	--assert 0 = to-integer 1/1/1970
	--test-- "conv-5"	--assert -31536000  = to-integer 1/1/1969
	--test-- "conv-6"	--assert 946684800  = to-integer 1/1/2000
	
	--test-- "conv-7"	--assert 5-Jul-2017/4:41:40  = to-date 1499229700
	--test-- "conv-8"	--assert 5-Jul-2017/12:41:40 = to-date 1499258500
	--test-- "conv-9"	--assert 5-Jul-2017/16:41:40 = to-date 1499272900
	--test-- "conv-10"	--assert 1/1/1970/0:00:0 = to-date 0
	--test-- "conv-11"	--assert 1/1/1969/0:00:0 = to-date -31536000
	--test-- "conv-12"	--assert 1/1/2000/0:00:0 = to-date 946684800
	--test-- "conv-13"	--assert 31-Dec-1999/23:00:34 = to-date 946681234
	--test-- "conv-14"	--assert 31-Dec-1969/23:59:59 = to-date -1
	
	--test-- "conv-20"	--assert 3-Mar-1973/9:46:40 = to-date reduce [1970 1 1 to-time 100000000 0]
	--test-- "conv-21"	--assert 1-Mar-1981 = to-date [1981 2 29]
	--test-- "conv-22"	--assert 2-Feb-2017/0:10:00+04:30 = to date! [1 2 2017 23 70 0 4:30]

	--test-- "conv-23"	--assert 1499299200 = to integer! 5-Jul-2017/23:59:59.999999

===end-group===

===start-group=== "weeks accuracy"

	--test-- "wr-1"		d: 13-Jan-2019 	--assert d/week = 3
	--test-- "wr-2"		d: 12-Jan-2019 	--assert d/week = 2
	--test-- "wr-3"		d: 6-Jan-2019 	--assert d/week = 2
	--test-- "wr-4"		d: 5-Jan-2019 	--assert d/week = 1
	--test-- "wr-5"		d: 14-Jan-2018 	--assert d/week = 3
	--test-- "wr-6"		d: 13-Jan-2018 	--assert d/week = 2
	--test-- "wr-7"		d: 7-Jan-2018 	--assert d/week = 2
	--test-- "wr-8"		d: 6-Jan-2018 	--assert d/week = 1
	--test-- "wr-9"		d: 15-Jan-2017 	--assert d/week = 3
	--test-- "wr-10"	d: 14-Jan-2017 	--assert d/week = 2
	--test-- "wr-11"	d: 8-Jan-2017 	--assert d/week = 2
	--test-- "wr-12"	d: 7-Jan-2017 	--assert d/week = 1
	--test-- "wr-13"	d: 10-Jan-2016 	--assert d/week = 3
	--test-- "wr-14"	d: 9-Jan-2016 	--assert d/week = 2
	--test-- "wr-15"	d: 3-Jan-2016	--assert d/week = 2
	--test-- "wr-16"	d: 2-Jan-2016	--assert d/week = 1
	--test-- "wr-17"	d: 11-Jan-2015 	--assert d/week = 3
	--test-- "wr-18"	d: 10-Jan-2015 	--assert d/week = 2
	--test-- "wr-19"	d: 4-Jan-2015	--assert d/week = 2
	--test-- "wr-20"	d: 3-Jan-2015	--assert d/week = 1
	--test-- "wr-21"	d: 12-Jan-2014 	--assert d/week = 3
	--test-- "wr-22"	d: 11-Jan-2014 	--assert d/week = 2
	--test-- "wr-23"	d: 5-Jan-2014	--assert d/week = 2
	--test-- "wr-24"	d: 4-Jan-2014	--assert d/week = 1
	--test-- "wr-25"	d: 13-Jan-2013 	--assert d/week = 3
	--test-- "wr-26"	d: 12-Jan-2013 	--assert d/week = 2
	--test-- "wr-27"	d: 6-Jan-2013	--assert d/week = 2
	--test-- "wr-28"	d: 5-Jan-2013	--assert d/week = 1
	--test-- "wr-29"	d: 15-Jan-2012 	--assert d/week = 3
	--test-- "wr-30"	d: 14-Jan-2012 	--assert d/week = 2
	--test-- "wr-31"	d: 8-Jan-2012	--assert d/week = 2
	--test-- "wr-32"	d: 7-Jan-2012	--assert d/week = 1
	--test-- "wr-33"	d: 9-Jan-2011 	--assert d/week = 3
	--test-- "wr-34"	d: 8-Jan-2011 	--assert d/week = 2
	--test-- "wr-35"	d: 2-Jan-2011	--assert d/week = 2
	--test-- "wr-36"	d: 1-Jan-2011	--assert d/week = 1

	--test-- "ww-1"		d: 3-Jul-2019	d/week: 3	--assert d = 13-Jan-2019
	--test-- "ww-3"		d: 3-Jul-2019	d/week: 2	--assert d = 6-Jan-2019
	--test-- "ww-4"		d: 3-Jul-2019	d/week: 1	--assert d = 1-Jan-2019
	--test-- "ww-5"		d: 3-Jul-2018	d/week: 3	--assert d = 14-Jan-2018
	--test-- "ww-7"		d: 3-Jul-2018	d/week: 2	--assert d = 7-Jan-2018
	--test-- "ww-8"		d: 3-Jul-2018	d/week: 1	--assert d = 1-Jan-2018
	--test-- "ww-9"		d: 3-Jul-2017	d/week: 3	--assert d = 15-Jan-2017
	--test-- "ww-11"	d: 3-Jul-2017	d/week: 2	--assert d = 8-Jan-2017
	--test-- "ww-12"	d: 3-Jul-2017	d/week: 1	--assert d = 1-Jan-2017
	--test-- "ww-13"	d: 3-Jul-2016	d/week: 3	--assert d = 10-Jan-2016
	--test-- "ww-15"	d: 3-Jul-2016	d/week: 2	--assert d = 3-Jan-2016
	--test-- "ww-16"	d: 3-Jul-2016	d/week: 1	--assert d = 1-Jan-2016
	--test-- "ww-17"	d: 3-Jul-2015	d/week: 3	--assert d = 11-Jan-2015
	--test-- "ww-19"	d: 3-Jul-2015	d/week: 2	--assert d = 4-Jan-2015
	--test-- "ww-20"	d: 3-Jul-2015	d/week: 1	--assert d = 1-Jan-2015
	--test-- "ww-21"	d: 3-Jul-2014	d/week: 3	--assert d = 12-Jan-2014
	--test-- "ww-23"	d: 3-Jul-2014	d/week: 2	--assert d = 5-Jan-2014
	--test-- "ww-24"	d: 3-Jul-2014	d/week: 1	--assert d = 1-Jan-2014
	--test-- "ww-25"	d: 3-Jul-2013	d/week: 3	--assert d = 13-Jan-2013
	--test-- "ww-27"	d: 3-Jul-2013	d/week: 2	--assert d = 6-Jan-2013
	--test-- "ww-28"	d: 3-Jul-2013	d/week: 1	--assert d = 1-Jan-2013
	--test-- "ww-29"	d: 3-Jul-2012	d/week: 3	--assert d = 15-Jan-2012
	--test-- "ww-31"	d: 3-Jul-2012	d/week: 2	--assert d = 8-Jan-2012
	--test-- "ww-32"	d: 3-Jul-2012	d/week: 1	--assert d = 1-Jan-2012
	--test-- "ww-33"	d: 3-Jul-2011	d/week: 3	--assert d = 9-Jan-2011
	--test-- "ww-35"	d: 3-Jul-2011	d/week: 2	--assert d = 2-Jan-2011
	--test-- "ww-36"	d: 3-Jul-2011	d/week: 1	--assert d = 1-Jan-2011
	
===end-group===

===start-group=== "ISO weeks accuracy"

	--test-- "iwr-1"	d: 7-Jan-2019 	--assert d/isoweek = 2
	--test-- "iwr-2"	d: 6-Jan-2019 	--assert d/isoweek = 1
	--test-- "iwr-3"	d: 31-Dec-2018	--assert d/isoweek = 1
	--test-- "iwr-4"	d: 30-Dec-2018	--assert d/isoweek = 52
	--test-- "iwr-5"	d: 1-Jan-2018 	--assert d/isoweek = 1
	--test-- "iwr-6"	d: 31-Dec-2017	--assert d/isoweek = 52
	--test-- "iwr-7"	d: 3-Jul-2017 	--assert d/isoweek = 27
	--test-- "iwr-8"	d: 1-Jan-2017 	--assert d/isoweek = 52
	--test-- "iwr-9"	d: 2-Jan-2017 	--assert d/isoweek = 1
	--test-- "iwr-10"	d: 30-Dec-2016	--assert d/isoweek = 52
	--test-- "iwr-11"	d: 26-Dec-2016	--assert d/isoweek = 52
	--test-- "iwr-12"	d: 25-Dec-2016	--assert d/isoweek = 51
	--test-- "iwr-13"	d: 4-Jan-2016 	--assert d/isoweek = 1
	--test-- "iwr-14"	d: 3-Jan-2016 	--assert d/isoweek = 53
	--test-- "iwr-15"	d: 31-Dec-2015	--assert d/isoweek = 53
	--test-- "iwr-16"	d: 28-Dec-2015	--assert d/isoweek = 53
	--test-- "iwr-17"	d: 27-Dec-2015	--assert d/isoweek = 52
	--test-- "iwr-18"	d: 5-Jan-2015 	--assert d/isoweek = 2
	--test-- "iwr-19"	d: 4-Jan-2015 	--assert d/isoweek = 1
	--test-- "iwr-20"	d: 31-Dec-2014	--assert d/isoweek = 1
	--test-- "iwr-21"	d: 29-Dec-2014	--assert d/isoweek = 1
	--test-- "iwr-22"	d: 28-Dec-2014	--assert d/isoweek = 52
	--test-- "iwr-23"	d: 6-Jan-2014 	--assert d/isoweek = 2
	--test-- "iwr-24"	d: 5-Jan-2014 	--assert d/isoweek = 1
	--test-- "iwr-25"	d: 31-Dec-2013	--assert d/isoweek = 1
	--test-- "iwr-26"	d: 30-Dec-2013	--assert d/isoweek = 1
	--test-- "iwr-27"	d: 29-Dec-2013	--assert d/isoweek = 52
	--test-- "iwr-28"	d: 7-Jan-2013 	--assert d/isoweek = 2
	--test-- "iwr-29"	d: 6-Jan-2013 	--assert d/isoweek = 1
	--test-- "iwr-30"	d: 1-Jan-2013 	--assert d/isoweek = 1
	--test-- "iwr-31"	d: 31-Dec-2012	--assert d/isoweek = 1
	--test-- "iwr-32"	d: 30-Dec-2012	--assert d/isoweek = 52
	--test-- "iwr-33"	d: 24-Dec-2012	--assert d/isoweek = 52
	--test-- "iwr-34"	d: 23-Dec-2012	--assert d/isoweek = 51
	--test-- "iwr-35"	d: 2-Jan-2012 	--assert d/isoweek = 1
	--test-- "iwr-36"	d: 1-Jan-2012 	--assert d/isoweek = 52
	--test-- "iwr-37"	d: 31-Dec-2011	--assert d/isoweek = 52
	--test-- "iwr-38"	d: 26-Dec-2011	--assert d/isoweek = 52
	--test-- "iwr-39"	d: 25-Dec-2011	--assert d/isoweek = 51
	
	--test-- "iww-1"	d: 3-Jul-2019	d/isoweek: 2	--assert d = 7-Jan-2019 
	--test-- "iww-3"	d: 3-Jul-2019	d/isoweek: 1	--assert d = 31-Dec-2018
	--test-- "iww-4"	d: 3-Jul-2018	d/isoweek: 52	--assert d = 24-Dec-2018
	--test-- "iww-5"	d: 3-Jul-2018	d/isoweek: 1	--assert d = 1-Jan-2018 
	--test-- "iww-6"	d: 3-Jul-2017	d/isoweek: 52	--assert d = 25-Dec-2017
	--test-- "iww-7"	d: 3-Jul-2017	d/isoweek: 27	--assert d = 3-Jul-2017
	--test-- "iww-9"	d: 3-Jul-2017	d/isoweek: 1	--assert d = 2-Jan-2017
	--test-- "iww-11"	d: 3-Jul-2016	d/isoweek: 52	--assert d = 26-Dec-2016
	--test-- "iww-12"	d: 3-Jul-2016	d/isoweek: 51	--assert d = 19-Dec-2016
	--test-- "iww-13"	d: 3-Jul-2016	d/isoweek: 1	--assert d = 4-Jan-2016 
	--test-- "iww-16"	d: 3-Jul-2015	d/isoweek: 53	--assert d = 28-Dec-2015
	--test-- "iww-17"	d: 3-Jul-2015	d/isoweek: 52	--assert d = 21-Dec-2015
	--test-- "iww-18"	d: 3-Jul-2015	d/isoweek: 2	--assert d = 5-Jan-2015
	--test-- "iww-21"	d: 3-Jul-2015	d/isoweek: 1	--assert d = 29-Dec-2014
	--test-- "iww-22"	d: 3-Jul-2014	d/isoweek: 52	--assert d = 22-Dec-2014
	--test-- "iww-23"	d: 3-Jul-2014	d/isoweek: 2	--assert d = 6-Jan-2014
	--test-- "iww-26"	d: 3-Jul-2014	d/isoweek: 1	--assert d = 30-Dec-2013
	--test-- "iww-27"	d: 3-Jul-2013	d/isoweek: 52	--assert d = 23-Dec-2013
	--test-- "iww-28"	d: 3-Jul-2013	d/isoweek: 2	--assert d = 7-Jan-2013
	--test-- "iww-31"	d: 3-Jul-2013	d/isoweek: 1	--assert d = 31-Dec-2012
	--test-- "iww-33"	d: 3-Jul-2012	d/isoweek: 52	--assert d = 24-Dec-2012
	--test-- "iww-34"	d: 3-Jul-2012	d/isoweek: 51	--assert d = 17-Dec-2012
	--test-- "iww-35"	d: 3-Jul-2012	d/isoweek: 1	--assert d = 2-Jan-2012 
	--test-- "iww-38"	d: 3-Jul-2011	d/isoweek: 52	--assert d = 26-Dec-2011
	--test-- "iww-39"	d: 3-Jul-2011	d/isoweek: 51	--assert d = 19-Dec-2011
	
===end-group===

===start-group=== "date misc"

	--test-- "misc-1"
		--assert "1-Jan-0001" = mold 1/1/0001
		--assert "1-Jan-0001" = mold load "1/1/0001"

	--test-- "misc-2"
		d: 1/1/0000
		d: d - 1
		--assert "31/Dec/-1" = mold d

	--test-- "misc-3"
		res: make block! 10
		random/seed 1
		loop 10 [append res random 1/1/9999]
		--assert res = [
			4-May-1485 
			28-Jul-6609 
			14-Jan-9528 
			20-May-6200 
			14-Dec-8121 
			17-Apr-0909 
			18-Jan-0386 
			13-Mar-9178 
			26-Sep-3370 
			23-Mar-2377
		]
		
	--test-- "misc-4"
		res: make block! 10
		random/seed 2
		loop 10 [append res random 1/1/9999/23:59:59]
		--assert res = [
			3-Mar-0000/13:44:24+09:45
			14-Jan-2046/9:34:48-12:15
			19-Nov-4262/9:41:12-01:30
			12-Feb-1864/3:26:00-14:30
			29-Jul-4351/8:14:00+09:30
			18-Dec-1884/22:30:48-07:00
			21-May-5509/0:14:24-03:00
			23-Apr-4622/4:22:48+05:30
			22-Feb-1583/16:36:48-14:45
			26-Feb-6712/17:07:12-10:00
		]

===end-group===

~~~end-file~~~
