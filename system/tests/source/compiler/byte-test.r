REBOL [
	Title:   "Red/System cast test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %byte-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "byte-compile"

===start-group=== "compiler checks"

	--test-- "byte cc 1"
  		--assert --compiled? {
    		Red/System []		
    	;;	b: #"á"				This should be re-instated for version 2				
    	}
 
===end-group=== 
       
~~~end-file~~~


