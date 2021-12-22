Red [
	Title:   "CLI module test script"
	Author:  @hiiamboris
	Tabs:	 4
	Rights:  "Copyright (C) 2021 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Needs:   CLI
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "cli"

===start-group=== "utilities"

	--test-- "cli/str-to-ref"
		--assert /x = cli/str-to-ref "x"

	--test-- "cli/prep-spec-1"
		--assert (reduce ['x      "" make typeset! [string!] ]) = cli/prep-spec [x] 
	--test-- "cli/prep-spec-2"
		--assert (reduce ['x   "doc" make typeset! [integer!]]) = cli/prep-spec [x [integer!] "doc"] 
		
	--test-- "cli/prep-spec-3"
		--assert (reduce [[/x /y] "" none]) = cli/prep-spec [/x /y "alias x"] 
	--test-- "cli/prep-spec-4"
		--assert (reduce [[/x /y] "" none]) = cli/prep-spec [/y "alias x"  /x] 
	--test-- "cli/prep-spec-5"
		--assert (reduce [[/x /y] "" none]) = cli/prep-spec [/y "alias /x" /x] 
	--test-- "cli/prep-spec-6"
		--assert 
			(reduce [
				[/x /y] "doc1" none
				'z      "doc2" make typeset! [integer! block!]
			]) = cli/prep-spec [/x "doc1" z [integer! block!] "doc2" /y "alias x"]
	--test-- "cli/prep-spec-7"
		--assert  error? try [cli/prep-spec [/x y /z "alias x" w]] 
	--test-- "cli/prep-spec-8"
		--assert  error? try [cli/prep-spec [/z "alias x" w]] 

	--test-- "cli/supported"
		--assert     cli/supported? func [/x][]     "x"
		--assert     cli/supported? func [a /x y][] "x"
		--assert not cli/supported? func [a /x y][] "y"
		--assert not cli/supported? func [a /x y][] "a"
		--assert not cli/supported? func [a /x y][] "b"

	--test-- "cli/unary"
		--assert     cli/unary? func [/x y][]   "x"
		--assert not cli/unary? func [/x y z][] "x"
		--assert not cli/unary? func [/x][]     "x"

	--test-- "cli/check-value-1"
		--assert 1   = cli/check-value "1" [ integer! ]
		--assert 1   = cli/check-value "1" [ string! integer! ]
		--assert "1" = cli/check-value "1" [ string! ]
		--assert %1  = cli/check-value "1" [ file! ]
		--assert %1  = cli/check-value "1" [ string! file! ]
		
	--test-- "cli/check-value-2"
		--assert error? try     [cli/check-value "1"   [typeset!]]
		--assert error? try/all [cli/check-value "1 2" [integer!]]
		--assert error? try/all [cli/check-value "1 2" [integer! block!]]
		--assert error? try/all [cli/check-value "1"   [date!]]
		--assert error? try/all [cli/check-value ")#!" [date!]]

	--test-- "cli/add-refinements"
		--assert  [f   [1 2] [/x []    ]] =
			cli/add-refinements [f   [1 2] [      ]] func [/x /y z [integer!]][] "x" "0" 
		--assert  [f   [1 2] [/y [3]   ]] =
			cli/add-refinements [f   [1 2] [      ]] func [/x /y z [integer!]][] "y" "3" 
		--assert  [y/y [1 2] [/y [3]   ]] =
			cli/add-refinements [y/y [1 2] [      ]] func [/x /y z [integer!]][] "y" "3" 
		--assert  [y/y [1 2] [/y [3 4] ]] =
			cli/add-refinements [y/y [1 2] [/y [3]]] func [/x /y z [integer!]][] "y" "4" 
		--assert  [y/y [1 2] [/y /z [3]]] =
			cli/add-refinements [y/y [1 2] [      ]] func [/x /y q [integer!] /z "alias y"][] "z" "3"

	--test-- "cli/add-operand"
		--assert  [f [1]     []] = cli/add-operand [f []    []] func [a [integer!] b [integer!] /x /y z][] "1" 
		--assert  [f [1 2]   []] = cli/add-operand [f [1]   []] func [a [integer!] b [integer!] /x /y z][] "2" 
		--assert  [f [1 2 3] []] = cli/add-operand [f [1 2] []] func [a [integer!] b [integer!] /x /y z][] "3" 

	--test-- "cli/prep-call-1"
		--assert  [y/y/x       ] = cli/prep-call [y/y [] [/x    [0]]] func [/x /y q /z "alias y"][] 
		--assert  [y/y/y/z 3   ] = cli/prep-call [y/y [] [/y /z [3]]] func [/x /y q [integer!] /z "alias /y"][] 
		--assert  [y/y/y/z [3] ] = cli/prep-call [y/y [] [/y /z [3]]] func [/x /y q [integer! block!] /z "alias y"][] 
	
	--test-- "cli/prep-call-2"
		--assert  [y/y 1 2     ] = cli/prep-call [y/y [1 2] []      ] func [a [integer!] b [integer!] /x /z "alias /x"][] 
		--assert  [y/y 1 [2]   ] = cli/prep-call [y/y [1 2] []      ] func [a [integer!] b [integer! block!] /x /z "alias x"][] 
		--assert  [y/y 1 [2 3] ] = cli/prep-call [y/y [1 2 3] []    ] func [a [integer!] b [integer! block!] /x /z "alias /x"][] 

===end-group=== 

===start-group=== "programs"

	test-prog-1: func [
		a [integer!] b [file!] c [time! date! block!] "docstring of c"
		/x
		/y "docstring of y"
			y1 [float!] "docstring of y1" 
		/y2 "alias y"
		/z "docstring of z"
			z1 [block! date!] "docstring of z1"
		/local q
	][
		compose/only [a: (a) b: (b) c: (c) x: (x) y: (y) y1: (y1) y2: (y2) z: (z) z1: (z1)]
	]

	test-prog-2: func [a b] [
		compose/only [a: (a) b: (b)]
	]

	test-prog-3: func [/a x [logic! block!] /b y [logic!] /c z [logic! string!]] [
		compose/only [a: (a) x: (x) b: (b) y: (y) c: (c) z: (z)]
	]

	replace-std-words: func [blk] [
		replace/all/deep blk false 'false
		replace/all/deep blk true  'true
		replace/all/deep blk none  'none
		blk
	]
	
	test: function [prog [word!] args [block!] /with opts [block!]] [
		replace-std-words cli/process-into/options (prog) compose [args: args (any [opts []])]
	]

	handler: func [er [block!]] [return er/1]

	test-fail: function [prog [word!] args [block!]] [
		cli/process-into/options (prog) [args: args on-error: handler]
	]
	

	--test-- "cli/prog1-1"
		--assert [a: 1 b: %a.out c: [] x: false y: false y1: none y2: false z: false z1: none]
			= test 'test-prog-1 ["1" "a.out"]
	--test-- "cli/prog1-2"
		--assert [a: 1 b: %- c: [] x: false y: false y1: none y2: false z: false z1: none]
			= test 'test-prog-1 ["1" "-"]
	--test-- "cli/prog1-3"
		--assert [a: 1 b: %a.out c: [3:00:00] x: false y: false y1: none y2: false z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0"]
	--test-- "cli/prog1-4"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: false y: false y1: none y2: false z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6"]
	--test-- "cli/prog1-5"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: false y1: none y2: false z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x"]
	--test-- "cli/prog1-6"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1.0"]
	--test-- "cli/prog1-7"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1"]
	--test-- "cli/prog1-8"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y 1.0"]
	--test-- "cli/prog1-9"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "--y2" "1.0"]
	--test-- "cli/prog1-10"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "--y2 1.0"]
	--test-- "cli/prog1-11"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 1.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "--y2=1.0"]
	--test-- "cli/prog1-12"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 2.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1.0" "-y" "2.0"]
	--test-- "cli/prog1-13"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 2.0  y2: true  z: false z1: none]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1.0" "--y2" "2.0"]
	--test-- "cli/prog1-14"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 2.0  y2: true  z: true  z1: [1-Jan-2001]]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1.0" "-y" "2.0" "-z" "1/1/1"]
	--test-- "cli/prog1-15"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 2.0  y2: true  z: true  z1: [1-Jan-2001 2-Feb-2002]]
			= test 'test-prog-1 ["1" "a.out" "3:0" "4:5:6" "-x" "-y" "1.0" "-y" "2.0" "-z" "1/1/1" "-z" "2/2/2"]
	--test-- "cli/prog1-16"
		--assert [a: 1 b: %a.out c: [3:00:00 4:05:06] x: true  y: true  y1: 2.0  y2: true  z: true  z1: [1-Jan-2001 2-Feb-2002]]
			= test 'test-prog-1 ["1" "-z" "1/1/1" "a.out" "-z 2/2/2" "-y" "1.0" "3:0" "4:5:6" "-x" "-y" "2.0"]
	--test-- "cli/prog1-17"
		--assert [a: 1 b: %a.out c: [3:00:00 4-May-2006] x: true  y: true  y1: 2.0  y2: true  z: true  z1: [1-Jan-2001 2-Feb-2002]]
			= test 'test-prog-1 ["1" "-z 1/1/1" "a.out" "-z 2/2/2" "-y" "1.0" "3:0" "4/5/6" "-x" "-y" "2.0"]
	--test-- "cli/prog1-18"
		--assert [a: 1 b: %a.out c: [3:00:00 4-May-2006 4:00:00 5:00:00] x: true  y: true  y1: 2.0  y2: true  z: true  z1: [1-Jan-2001 2-Feb-2002]]
			= test 'test-prog-1 ["1" "-z 1/1/1" "a.out" "-z 2/2/2" "-y" "1.0" "3:0" "4/5/6" "4:0" "5:0:0" "-x" "-y" "2.0"]
			
	;; shortcut tests
	--test-- "cli/prog1-sc-1"
		--assert [a: 0 b: %"" c: [] x: false y: false y1: none y2: false z: true z1: [2-Feb-2002]]
			= test/with 'test-prog-1 ["-z 2/2/2"] [shortcuts: [z]]
	--test-- "cli/prog1-sc-2"
		--assert [a: 0 b: %"" c: [] x: true y: false y1: none y2: false z: false z1: none]
			= test/with 'test-prog-1 ["-x"] [shortcuts: [z x]]
	--test-- "cli/prog1-sc-3"
		--assert [a: 0 b: %"" c: [] x: true y: false y1: none y2: false z: true z1: [2-Feb-2002]]
			= test/with 'test-prog-1 ["-z 2/2/2" "-x"] [shortcuts: [z]]
	--test-- "cli/prog1-sc-4"
		--assert [a: 0 b: %"" c: [] x: true y: false y1: none y2: false z: true z1: [2-Feb-2002]]
			= test/with 'test-prog-1 ["-z 2/2/2" "-x"] [shortcuts: [x]]

	--test-- "cli/prog1-fail-1"
		--assert 'ER_FEW    = test-fail 'test-prog-1 []
	--test-- "cli/prog1-fail-2"
		--assert 'ER_FEW    = test-fail 'test-prog-1 ["1"]
	--test-- "cli/prog1-fail-3"
		--assert 'ER_TYPE   = test-fail 'test-prog-1 ["1" "2" "-z 1000"]
	--test-- "cli/prog1-fail-4"
		--assert 'ER_LOAD   = test-fail 'test-prog-1 ["1" "2" "-z )&#@"]
	--test-- "cli/prog1-fail-5"
		--assert 'ER_OPT    = test-fail 'test-prog-1 ["1" "2" "--unknown-option"]
	--test-- "cli/prog1-fail-6"
		--assert 'ER_OPT    = test-fail 'test-prog-1 ["1" "2" "--7x0"]
	--test-- "cli/prog1-fail-7"
		--assert 'ER_CHAR   = test-fail 'test-prog-1 ["1" "2" "--y2%bad"]
	--test-- "cli/prog1-fail-8"
		--assert 'ER_EMPTY  = test-fail 'test-prog-1 ["1" "2" "-z"]
	--test-- "cli/prog1-fail-9"
		--assert 'ER_VAL    = test-fail 'test-prog-1 ["1" "2" "-x 100"]
	--test-- "cli/prog1-fail-10"
		--assert 'ER_FORMAT = test-fail 'test-prog-1 ["1" "2" "-zxc"]


	--test-- "cli/prog2-fail-1"
		--assert 'ER_MUCH   = test-fail 'test-prog-2 ["1" "2" "3"]
		

	--test-- "cli/prog3-1"
		--assert [a: false x: none b: true y: true c: false z: none] = test 'test-prog-3 ["-b" "yes"]
	--test-- "cli/prog3-2"
		--assert [a: false x: none b: true y: true c: false z: none] = test 'test-prog-3 ["-b" "on"]
	--test-- "cli/prog3-3"
		--assert [a: false x: none b: true y: true c: false z: none] = test 'test-prog-3 ["-b" "true"]
	--test-- "cli/prog3-4"
		--assert [a: true x: [true false false false] b: false y: none c: false z: none]
			= test 'test-prog-3 ["-a" "yes" "-a" "no" "-a" "false" "-a" "off"]
	--test-- "cli/prog3-5"
		--assert [a: false x: none b: false y: none c: true z: false] = test 'test-prog-3 ["-c" "no"]
	--test-- "cli/prog3-6"
		--assert [a: false x: none b: false y: none c: true z: true] = test 'test-prog-3 ["-c" "yes"]

	--test-- "cli/prog3-fail-1"
		--assert 'ER_TYPE = test-fail 'test-prog-3 ["-a" "100"]


	--test-- "cli/extract-args"
		--assert (reduce [none "--" none "-- --"]) = cli/extract-args ["--" "--" "-- --"] test-prog-1


	--test-- "cli/help-for-1"
		--assert (cli/help-for/no-version test-prog-1) 
			= (cli/help-for/options test-prog-1 [no-version: yes])
	--test-- "cli/help-for-2"
		--assert (cli/help-for/no-help    test-prog-1) 
			= (cli/help-for/options test-prog-1 [no-help: yes])
	--test-- "cli/help-for-3"
		--assert (cli/help-for/name       test-prog-1 "no name!") 
			= (cli/help-for/options test-prog-1 [name: "no name!"])
	--test-- "cli/help-for-4"
		--assert (cli/help-for/exename    test-prog-1 "no name!") 
			= (cli/help-for/options test-prog-1 [exename: "no name!"])
	--test-- "cli/help-for-5"
		--assert (cli/help-for/version    test-prog-1 1.2.3.4) 
			= (cli/help-for/options test-prog-1 [version: 1.2.3.4])
	--test-- "cli/help-for-6"
		--assert (cli/help-for/columns    test-prog-1 [5 10 20 10 30]) 
			= (cli/help-for/options test-prog-1 [columns: [5 10 20 10 30]])

	--test-- "cli/version-for-1"
		--assert (cli/version-for/name       test-prog-1 "no name!") 
			= (cli/version-for/options test-prog-1 [name: "no name!"])
	--test-- "cli/version-for-2"
		--assert (cli/version-for/version    test-prog-1 "custom") 
			= (cli/version-for/options test-prog-1 [version: "custom"])
	--test-- "cli/version-for-3"
		--assert (cli/version-for/brief      test-prog-1) 
			= (cli/version-for/options test-prog-1 [brief: yes])
			
	--test-- "cli/syntax-for-1"
		--assert (cli/syntax-for/exename     test-prog-1 "no name!") 
			= (cli/syntax-for/options  test-prog-1 [exename: "no name!"])

===end-group=== 

~~~end-file~~~
