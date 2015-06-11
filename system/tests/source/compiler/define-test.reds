Red/System [
	Title:   "Red/System #define test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %define-test.reds
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.reds

~~~start-file~~~ "define"

===start-group=== "reported issues"
	--test-- "issue #504"
		#define I504-MAX-SIZE 2
		i504-arr: as int-ptr! allocate I504-MAX-SIZE * size? integer!
		i504-arr/1: 1
		i504-arr/2: 2
	--assert 2 = i504-arr/I504-MAX-SIZE
	
===end-group===
  

~~~end-file~~~
