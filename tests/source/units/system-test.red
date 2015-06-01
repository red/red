Red [
	Title:   {Red system "object" test script}
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "system"

===start-group=== "system word tests"

	--test-- "swt1 issue #455"
	--assert  function! = type? get first find words-of system/words 'file?
	
	--test-- "swt2 issue #455"
	--assert char! = type? get first find words-of system/words 'cr
	
	--test-- "swt3 issue #455"
	--assert action! = type? get first find words-of system/words 'find
	
	--test-- "swt4 issue #455"
	--assert datatype! = type? get first find words-of system/words 'function!
		
===end-group===

~~~end-file~~~

