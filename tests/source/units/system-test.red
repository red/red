Red [
	Title:   {Red system "object" test script}
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %system-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
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

===start-group=== "replaced system sub-objects"

	--test-- "rss1"
		rss-saved: system/script/header
		do [system/script/header: make system/standard/header [Title: "rss"]]
		--assert "rss" = system/script/header/title
		system/script/header: rss-saved
		unset 'rss-saved

===end-group===

~~~end-file~~~

