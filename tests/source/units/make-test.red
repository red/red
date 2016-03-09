Red [
	Title:   "Red make test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %make-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "make"

===start-group=== "make basic"
	
	--test-- "mb1 - issue #465"
		mb1-s: make string! 0
		append mb1-s #"B"
		append mb1-s #"C"
		append mb1-s #"D"
	--assert "BCD" = mb1-s
	
	--test-- "mb2"
		mb2-s: make string! 1 
		append mb2-s #"A"
		append mb2-s #"B"
		append mb2-s #"C"
		append mb2-s #"D"
	--assert "ABCD" = mb2-s
  
===end-group===

~~~end-file~~~

