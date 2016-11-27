REBOL [
	Title:   "Red preprocessor test script"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
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

~~~end-file~~~ 
