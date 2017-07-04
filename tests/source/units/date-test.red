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
	--test-- "rfmt-14" --assert 5-Sep-2012/6:00:00  	  = probe load "5/9/2012/6:00+8"
	--test-- "rfmt-15" --assert 5-Sep-2012/6:00:00	 	  = load "5/9/2012/6:0"
	--test-- "rfmt-16" --assert 4-Apr-2000/6:00:00+08:00  = probe load "4/Apr/2000/6:00+8:00"
	--test-- "rfmt-17" --assert 2-Oct-1999/2:00:00-04:00  = load "1999-10-2/2:00-4:00"
	--test-- "rfmt-18" --assert 1-Jan-1990/12:20:25-06:00 = load "1/1/1990/12:20:25-6"

===end-group===

~~~end-file~~~
