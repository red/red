Red [
	Title:   "Red debase test script"
	Author:  "Arnold van Hofwegen"
	File: 	 %entab-detab-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood & Arnold van Hofwegen. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "entab-detab"

===start-group=== "entab"

	--test-- "entab 1"          
		--assert strict-equal? "^-a    " entab "    a    "
	--test-- "entab 2"          
		--assert strict-equal? "^-^-a" entab "        a"
	--test-- "entab 3"          
		--assert strict-equal? "    a    " entab/size "    a    " 5
	--test-- "entab 4"          
		--assert strict-equal? "^- a    " entab/size "    a    " 3
   
===end-group===

===start-group=== "detab"

	--test-- "detab 1"          
		--assert strict-equal? "    a    " detab "^-a^-"

	--test-- "detab 2"          
		--assert strict-equal? "     a     " detab/size "^-a^-" 5

	--test-- "detab 3"          
		--assert strict-equal? " a " detab/size "^-a^-" 1

===end-group===

~~~end-file~~~
