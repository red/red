Red [
	Title:   "Red runtime preprocessor tests"
	Author:  "Nenad Rakocevic"
	File: 	 %preprocessor-test.red
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
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
	
	--test-- "#do keep"
		--assert 1 = #do keep [1]	
	
	--test-- "#do : issue #2924"
		--assert 2 = (#do keep [2])

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

===start-group=== "#rejoin"

	--test-- "#rejoin-1"
		--assert [rejoin [""]   ] == [#rejoin "()"]
		--assert [rejoin ["" []]] == [#rejoin "([])"]	;-- result is string not block

	--test-- "#rejoin-2" --assert [#rejoin "(\(\\\))"    ] == [rejoin ["((\\))"] ]		;-- escaping & string grouping
	--test-- "#rejoin-3" --assert [#rejoin %"(\(\\\))"   ] == [rejoin [%"((\\))"]]		;-- 1st string is the return type
	--test-- "#rejoin-4" --assert [#rejoin %"({(})(\\\))"] == [rejoin [%"" "((\\))"]]
	--test-- "#rejoin-5" --assert [#rejoin "()"          ] == [rejoin ["" ()]    ]
	--test-- "#rejoin-6" --assert [#rejoin "([])"        ] == [rejoin ["" []]    ]		;-- paren removal from obvious cases
	--test-- "#rejoin-7" --assert [#rejoin "(1)"         ] == [rejoin ["" 1]     ]
	--test-- "#rejoin-8" --assert [#rejoin "('x)"        ] == [rejoin ["" 'x]    ]
	--test-- "#rejoin-9" --assert [#rejoin "(x)"         ] == [rejoin ["" (x)]   ]

	--test-- "#rejoin-11-expansion-within-rejoin"
		--assert [ #rejoin "(append {1} #rejoin {2(1 + 2)})" ]
			== [ rejoin ["" (append "1" rejoin ["2" (1 + 2)])] ]
	
	--test-- "#rejoin-12"
		--assert [ #rejoin "(1 + 2)(\text)" ]
			== [ rejoin ["" (1 + 2) "(text)"] ]
	
	--test-- "#rejoin-13-line-comments"
		--assert [rejoin ["" (1 + 2 * 3)]] == [#rejoin {(;-- comment
			1 + 2 * 3									;-- another
		)}]

	--test-- "#rejoin-14"
		--assert [#rejoin <tag flag=(mold 1 + 2)/>] == [
			rejoin [
				<tag flag=>								;-- result is a <tag>
				(mold 1 + 2)
				{/}										;-- other strings should be normal, or we'll have <<">> result
			]
		]
		
	--test-- "#rejoin-15"
		--assert [#rejoin %"()() - (1 + 2)) - (\(<abc)))>) - (func)(1)()()"] == [
			rejoin [
				%""										;-- 1st string is of argument/result type, even empty
				() ()									;-- () makes an unset, no empty strings inbetween
				" - "									;-- subsequent fragments are of string! type
				(1 + 2)									;-- 2+ tokens are parenthesized
				") - ("									;-- literal parens
				<abc)))>								;-- an explicit tag! - not a string!; without parens around
				" - "
				(func)									;-- words are parenthesized
				1										;-- single token does not need parens
				() ()									;-- no unnecessary empty strings
			]
		]
  
===end-group===

~~~end-file~~~