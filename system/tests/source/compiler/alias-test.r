REBOL [
	Title:   "Red/System alias test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %alias-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "alias-compile"

===start-group=== "compiler checks"

	--test-- "alias-1"
		--assert --compiled? {
			Red/System []
			a3-alias!: alias struct! [a [integer!] b [integer!]]
			a3-struct: declare a3-alias!
			a3-struct/a: 1
			a3-struct/b: 2
			a3-struct-1: declare a3-alias!
			a3-struct-1/a: 3
			a3-struct-1/b: 4
		}
	 
    	--clean
  
    --test-- "alias-2"
    	--assert --compiled? {
    		Red/System []
    		a5-alias!: alias struct! [a [integer!] b [integer!]]
    		a5-struct: declare a5-alias!
    		a5-pointer: declare pointer! [integer!]
    		a5-struct/a: 1
    		a5-struct/b: 2
    		a5-pointer: as [pointer! [integer!]] a5-struct
    		a5-struct: as a5-alias! a5-pointer
    	} 
  		--clean
    
  	--test-- "alias-3"
  		--assert --compiled? {
    		Red/System []  
    		a5-alias!: alias struct! [a [byte!] b [byte!]]
    		a6-alias!: alias struct! [a [byte!] b [byte!]]
    		a6-struct: declare struct! [
    			s1 [a5-alias!]
    			s2 [a5-alias!]
    			]
    		a6-struct/s1: declare a6-alias!
    	}
  		--clean
  
===end-group=== 
       
~~~end-file~~~


