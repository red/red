Red [
  Title:   "Red CATCH/THROW test script"
  Author:  "Nenad Rakocevic"
  File:    %throw-test.reds
  Tabs:    4
  Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
  License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "catch/throw"

===start-group=== "Anonymous THROW"

	--test-- "an1" --assert 1  = catch [throw 1 --assert no]
	--test-- "an2" --assert 2  = catch [if true [throw 2 --assert no] --assert no]
	--test-- "an3" --assert 3  = catch [loop 1 [throw 3 --assert no] --assert no]
	--test-- "an4" --assert 4  = catch [while [true][throw 4 --assert no] --assert no]
	--test-- "an5" --assert 5  = catch [until [throw 5 --assert no] --assert no]
	--test-- "an6" --assert 6  = catch [6]
	--test-- "an7" --assert 7  = catch [4 + 3]
	--test-- "an8" --assert 8  = catch [do [throw 8 --assert no] --assert no]

	--test-- "an9"
		f: does [throw 9 --assert no]
		--assert 9 = catch [f]

	--test-- "an10"
		f: does [throw 10 --assert no]
		g: does [f --assert no]
		--assert 10 = catch [g]
	
	--test-- "an11" --assert 11 = catch [parse "1" [(throw 11 --assert no)] --assert no]
	
===end-group===

===start-group=== "Named THROW"

	--test-- "name1" --assert 1  = catch [throw/name 1 'a --assert no]
	--test-- "name2" --assert 2  = catch/name [if true [throw/name 2 'a --assert no] --assert no] 'a
	--test-- "name3" --assert 3  = catch/name [loop 1 [throw/name 3 'b --assert no] --assert no] 'b
	--test-- "name4" --assert 4  = catch/name [while [true][throw/name 4 'c --assert no] --assert no] 'c
	--test-- "name5" --assert 5  = catch/name [until [throw/name 5 'd --assert no] --assert no] 'd
	--test-- "name6" --assert 6  = catch/name [do [throw/name 6 'e --assert no] --assert no] 'e

	--test-- "name7"
		f: does [throw/name 7 'i --assert no]
		--assert 7 = catch/name [f] 'i

	--test-- "name8"
		f: does [throw/name 10 'j --assert no]
		g: does [f --assert no]
		--assert 10 = catch/name [g] 'j

	--test-- "name9"
		--assert 1 = catch/name [
			catch/name [throw/name 1 'hello	--assert no] 'world
			--assert no
		] 'hello

	--test-- "name10"
		--assert 123 = catch/name [
			--assert 2 = catch [throw/name 2 'hello --assert no]
			123
		] 'hello
		
	--test-- "name11"
		--assert 1 = catch [
			catch/name [throw/name 1 'hello	--assert no] 'world
			--assert yes
		]
		
	--test-- "name31" --assert 1  = catch [throw/name 1 'a --assert no]
	--test-- "name32" --assert 2  = catch/name [if true [throw/name 2 'a --assert no] --assert no] [a b]
	--test-- "name33" --assert 3  = catch/name [loop 1 [throw/name 3 'b --assert no] --assert no] [a b]
	--test-- "name34" --assert 4  = catch/name [while [true][throw/name 4 'c --assert no] --assert no] [a c]
	--test-- "name35" --assert 5  = catch/name [until [throw/name 5 'd --assert no] --assert no] [d]
	--test-- "name36" --assert 6  = catch/name [do [throw/name 6 'e --assert no] --assert no] [e d]
  
  	--test-- "name37"
  		f: does [throw/name 7 'i --assert no]
  		--assert 7 = catch/name [f][i]
  
  	--test-- "name38"
  		f: does [throw/name 10 'j --assert no]
  		g: does [f --assert no]
  		--assert 10 = catch/name [g][i j]
  
  	--test-- "name39"
  		--assert 1 = catch/name [
  			catch/name [throw/name 1 'hello	--assert no] 'world
  			--assert no
  		][hello]
  
  	--test-- "name40"
  		--assert 123 = catch/name [
  			--assert 2 = catch [throw/name 2 'hello --assert no]
  			123
  		][hi hello]
  		
  	--test-- "name41"
  		--assert 1 = catch [
  			catch/name [throw/name 1 'hello	--assert no][world]
  			--assert yes
		]
  
===end-group===
    
~~~end-file~~~

