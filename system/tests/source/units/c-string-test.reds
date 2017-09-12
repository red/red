Red/System [
	Title:   "Red/System c-string! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %c-string-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "c-string!"

===start-group=== "String arithmetic tests"

	--test-- "string-math-1"
		stringA: "test"
		stringB: stringA + 1
		--assert stringB/1 = #"e"
		stringB: stringA + 2
		--assert stringB/1 = #"s"
		stringB: stringA + 3
		--assert stringB/1 = #"t"
		stringB: stringA + 4
		--assert stringB/1 = #"^@"
		
	--test-- "string-math-2"
		stringC: stringB - 1
		--assert stringC/1 = #"t"
		stringC: stringB - 2
		--assert stringC/1 = #"s"
		stringC: stringB - 3
		--assert stringC/1 = #"e"
		stringC: stringB - 4
		--assert stringC/1 = #"t"
		
	--test-- "string-math-3"
		string-idx: 2
		stringB: stringA + string-idx
		--assert stringB/1 = #"s"
		
	--test-- "string-math-4"
		string-idx: -3
		stringB: stringA + 4
		stringC: stringB + string-idx
		--assert stringC/1 = #"e"

===end-group===

===start-group=== "Local string arithmetic tests"

	string-local-foo: func [
		/local
			stringA 	[c-string!]
			stringB 	[c-string!]
			stringC 	[c-string!]
			string-idx 	[integer!]
	][
	--test-- "loc-str-math-1"
		stringA: "test"
		stringB: stringA + 1
		--assert stringB/1 = #"e"
		stringB: stringA + 2
		--assert stringB/1 = #"s"
		stringB: stringA + 3
		--assert stringB/1 = #"t"
		stringB: stringA + 4
		--assert stringB/1 = #"^@"
		
	--test-- "loc-str-math-2"
		stringC: stringB - 1
		--assert stringC/1 = #"t"
		stringC: stringB - 2
		--assert stringC/1 = #"s"
		stringC: stringB - 3
		--assert stringC/1 = #"e"
		stringC: stringB - 4
		--assert stringC/1 = #"t"
		
	--test-- "loc-str-math-3"
		string-idx: 2
		stringB: stringA + string-idx
		--assert stringB/1 = #"s"
		
	--test-- "loc-str-math-4"
		string-idx: -3
		stringB: stringA + 4
		stringC: stringB + string-idx
		--assert stringC/1 = #"e"
	]
	string-local-foo

===end-group===

===start-group=== "reported issues"

===end-group===

~~~end-file~~~