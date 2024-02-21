REBOL [
	Title:   "Red preprocessor test script"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "preprocessor tests"

	--test-- "Simple directives"
		--compile-and-run-this {
			Red[]
			#do [cond?: yes anti?: no level: 2]
			print #if config/type = 'exe ["*test1*"]
			print #if cond? ["*test2*"]
			print #if not anti? ["*test3*"]
			print #if find [a b c] 'b ["*test4*"]

			print #either cond? ["*test5*"]["fail"]
			print #either anti? ["fail"]["*test6*"]

			print #switch 1 [1 ["*test7*"] 2 ["fail"] #default ["fail"]]
			print #switch 'b [a ["fail"] b ["*test8*"] #default ["fail"]]
			print #switch 'c [a ["fail"] b ["fail"] #default ["*test9*"]]
			print #switch level [1 ["fail"] 2 ["*test10*"] #default ["fail"]]

			print #case [level = 1 ["fail"] level >= 2 ["*test11*"] 'else ["fail"]]

			#process off
			print ["*test12*" #if #either #switch #case #do]
			#process on
		}

		--assert-printed? "*test1*"
		--assert-printed? "*test2*"
		--assert-printed? "*test3*"
		--assert-printed? "*test4*"
		--assert-printed? "*test5*"
		--assert-printed? "*test6*"
		--assert-printed? "*test7*"
		--assert-printed? "*test8*"
		--assert-printed? "*test9*"
		--assert-printed? "*test10*"
		--assert-printed? "*test11*"
		--assert-printed? "*test12* if either switch case do"


	--test-- "Macros & #do"
		--compile-and-run-this {
			Red[]

			prin "*test1* "
			#do [a: 12]
			print "nothing"

			#macro add2: func [n][n + 2]
			#macro foo: func [a b][add2 a + b]
			#macro bar: func [a b][a - b]
			#macro ['max some [integer!]] func [[manual] s e][
				change/part s first maximum-of copy/part next s e e 
				s
			]
			prin "*test2* "
			print #do keep [5 * a]
			prin "*test3* "
			print 6 + 2
			prin "*test4* "
			print foo 1 foo 3 4

			#local [
				#macro integer! func [[manual] s e][s/1: s/1 + 1 next s]
				prin "*test5* "
				print foo 1 foo 3 4
				prin "*test6* "
				print 6 + 2
			]
			prin "*test7* "
			print foo 1 foo 3 4
			prin "*test8* "
			print max 50 20 54546 40 85 30
			prin "*test9*"
			#reset
			probe ['*test10* foo 5 9]
		}
		
		--assert-printed? "*test1* nothing"
		--assert-printed? "*test2* 60"
		--assert-printed? "*test3* 8"
		--assert-printed? "*test4* 12"
		--assert-printed? "*test5* 17"
		--assert-printed? "*test6* 10"
		--assert-printed? "*test7* 12"
		--assert-printed? "*test8* 54546"
		--assert-printed? "*test9*"
		--assert-printed? "*test10* foo 5 9"

	--test-- "fetch-next"
		--compile-and-run-this {
			Red []
			prin "*test1* " probe preprocessor/fetch-next []
			prin "*test2* " probe preprocessor/fetch-next [1 2]
			prin "*test3* " probe preprocessor/fetch-next [1 + 2 3]
			prin "*test4* " probe preprocessor/fetch-next [a: 1 + b: 2 3]
			prin "*test5* " probe preprocessor/fetch-next [+ 1 2 3]
			b: reduce ['o make object! [f: func [/x y z][]]]
			prin "*test6* " probe preprocessor/fetch-next [a: 1 + b/o/f 2 3 4]
			prin "*test7* " probe preprocessor/fetch-next [a: 1 + b/o/f/x 2 3 4]
			prin "*test8* " probe preprocessor/fetch-next [a: 1 + b/o/f/x 2 3 * 4 * 5 6]
			b: reduce ['o make object! [f: func [/x 'y :z][]]]
			f: func [x][]
			prin "*test9* " probe preprocessor/fetch-next [a: 1 + b/o/f/x f f 4 5 6]
			prin "*test10* " probe preprocessor/fetch-next [a: 1 + b/o/f/x + * 4 5 6]
			o: make op! func [x 'y][]
			prin "*test11* " probe preprocessor/fetch-next ['a o b: 1]
			prin "*test12* " probe preprocessor/fetch-next [f o f 1]
			prin "*test13* " probe preprocessor/fetch-next [b/o/f o b/o/f/x 1 2 3]
			p: 10x20 s: "abcd"
			b: reduce [p s]
			w1: 'p w2: 's w3: 3
			prin "*test14* " probe preprocessor/fetch-next [p/y s/3]
			prin "*test15* " probe preprocessor/fetch-next [s/3]
			prin "*test16* " probe preprocessor/fetch-next [b/:w1/y b/(w2)/:w3]
			prin "*test17* " probe preprocessor/fetch-next [b/(w2)/:w3]
		}
		
		--assert-printed? "*test1* []"
		--assert-printed? "*test2* [2]"
		--assert-printed? "*test3* [3]"
		--assert-printed? "*test4* [3]"
		--assert-printed? "*test5* [2 3]"
		--assert-printed? "*test6* [2 3 4]"
		--assert-printed? "*test7* [4]"
		--assert-printed? "*test8* [6]"
		--assert-printed? "*test9* [4 5 6]"
		--assert-printed? "*test10* [4 5 6]"
		--assert-printed? "*test11* [1]"
		--assert-printed? "*test12* [1]"
		--assert-printed? "*test13* [1 2 3]"
		--assert-printed? "*test14* [s/3]"
		--assert-printed? "*test15* []"
		--assert-printed? "*test16* [b/(w2)/:w3]"
		--assert-printed? "*test17* []"


	--test-- "#5027"
		--compile-and-run-this {
			Red []
			#if true [
				#do [abc: 0  print "Set to zero!"]
				#macro ['macro1] func [[manual] s e] [abc: 1000 change/part s reduce ['print abc] 1]
				#macro ['macro2] func [[manual] s e] [change/part s reduce ['print abc] 1]
			]
			macro1
			macro2
			macro2
		}
		--assert-printed? "1000"
		--assert-printed? "1000"
		--assert-printed? "1000"

	--test-- "#5098"
		--compile-and-run-this {
			Red []
			do/expand {#do [abcd: 1]}
		}
		--assert empty? qt/output

~~~end-file~~~ 
