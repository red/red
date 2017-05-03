Red [
	Title:   "Red runtime preprocessor tests"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor-test.red
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "preprocessor"

===start-group=== "Basic Directives"

	--test-- "#if"
		#do [cond?: yes anti?: no level: 2]
		--assert #if config/type = 'exe [true]
		--assert #if cond? [true]
		--assert #if not anti? [true]
		--assert #if find [a b c] 'b [true]

	--test-- "#either"
		--assert #either cond? [true][false]
		--assert #either anti? [false][true]

	--test-- "#switch"
		--assert #switch 1 [1 [true] 2 [false] #default [false]]
		--assert #switch 'b [a [false] b [true] #default [false]]
		--assert #switch 'c [a [false] b [false] #default [true]]
		--assert #switch level [1 [false] 2 [true] #default [false]]

	--test-- "#case"
		--assert #case [level = 1 [false] level >= 2 [true] 'else [false]]

	--test-- "#process"
		#process off
		--assert ["*test12*" #if #either #switch #case #do] 
			= load {["*test12*" #if #either #switch #case #do]}
		#process on

===end-group===

===start-group=== "Macros"

	--test-- "macro-1"
		#do [
			unless value? 'maximum-of [
				maximum-of: function [list [block! paren!]][
					m: list forall list [if list/1 > m/1 [m: list]]
					m
				]
			]
			a: 12
		]

		#macro add2: func [n][n + 2]
		#macro foo: func [a b][add2 a + b]
		#macro bar: func [a b][a - b]
		#macro ['max some [integer!]] func [s e][
			first maximum-of copy/part next s e
		]

	--test-- "macro-2"
		--assert 60 = #do keep [5 * a]

	--test-- "macro-3"
		--assert 12 = foo 1 foo 3 4

		#local [
			#macro integer! func [s e][s/1 + 1]
			--test-- "macro-4"
				--assert (load "17") = foo 1 foo 3 4
			--test-- "macro-5"
				--assert 6 + 2 = (load "10")
		]
		--test-- "macro-6"
			--assert 12 = foo 1 foo 3 4
		--test-- "macro-7"
			--assert 54546 = max 50 20 54546 40 85 30
		--test-- "macro-8"
			#reset
			--assert [foo 5 9] = load {foo 5 9}

===end-group===

~~~end-file~~~