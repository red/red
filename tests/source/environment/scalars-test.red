Red [
	Title:   "Red scalars test script"
	Author:  "Peter W A Wood"
	File: 	 %scalars-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2017 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "scalars"

===start-group=== "constants"

	--test-- "con-01"			--assert yes = true
	--test-- "con-02"			--assert on = true
	--test-- "con-03"			--assert no = false
	--test-- "con-04"			--assert off = false
	--test-- "con-05"			--assert tab = #"^-"
	--test-- "con-06"			--assert cr =  #"^M"
	--test-- "con-07"			--assert newline = #"^/"
	--test-- "con-08"			--assert lf = #"^/"
	--test-- "con-09"			--assert escape = #"^["
	--test-- "con-10"			--assert slash = #"/"
	--test-- "con-11"			--assert sp = #" "
	--test-- "con-12"			--assert null = #"^@"
	--test-- "con-13"			--assert crlf = "^M^/"
	--test-- "con-14"			--assert dot = #"."
	--test-- "con-15"			--assert comma = #"," 
	--test-- "con-16"			--assert dbl-quote = #"^""
	--test-- "con-17"			--assert pi = 3.141592653589793
	--test-- "con-18"			--assert Rebol = false
	--test-- "con-19"			--assert sp = #" "
	
===end-group===

~~~end-file~~~