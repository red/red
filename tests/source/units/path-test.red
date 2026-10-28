Red [
	Title:   "Red/System path! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %char-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "path"

===start-group=== "block access"
	blk: [a b c [d] e]
	
	--test-- "blk-1"
		--assert blk/1 = 'a
		--assert blk/2 = 'b
		--assert blk/3 = 'c
		--assert blk/4 = [d]
		--assert blk/4/1 = 'd
	
	--test-- "blk-2"
		blk/1: 99
		--assert blk/1 = 99
		blk/2: 'z
		--assert blk/2 = 'z
		blk/4/1: -1
		--assert blk/4 = [-1]
		--assert blk = [99 z c [-1] e]

	--test-- "blk-3"
		idx: 1
		--assert blk/:idx = 99
		--assert blk/4/:idx = -1
		idx: 4
		--assert blk/:idx/1 = -1
		idx: 1
		blk/:idx: 0
		--assert blk/:idx = 0
		--assert blk/1 = 0

	--test-- "blk-4"
	idx: 'z
	--assert blk/:idx = 'c

	--test-- "blk-5"
	--assert blk/z = 'c

	--test-- "blk-6"
		blk: [4 5 6 ["o"]]
		idx: 2
		--assert blk/(1) = 4
		--assert blk/(1 + 2) = 6
		--assert blk/(idx) = 5
    	
		--test-- "blk-7"
		--assert blk/(idx + 2)/(1) = "o"
		--assert blk/(idx + 2)/(1)/(idx - 1) = #"o"

	--test-- "blk-8"
		blk/(1): 99
		idx: 2
		--assert blk/1 = 99
		blk/(idx + 2)/(1)/(idx - 1): #"z"	
		--assert blk/4/1/1 = #"z"
    	
		--test-- "blk-9"
		inc: func [a][a + 1]
		--assert blk/(inc 1) = 5

===end-group===

===start-group=== "string access"
	str: "abcde"
	
	--test-- "str-1"
		--assert str/1 = #"a"
		--assert str/2 = #"b"
		--assert str/3 = #"c"
		--assert str/4 = #"d"
	
	--test-- "str-2"
		str/1: #"9"
		--assert str/1 = #"9"
		str/2: #"z"
		--assert str/2 = #"z"
		--assert str = "9zcde"

	--test-- "str-3"
		idx: 1
		--assert str/:idx = #"9"
		idx: 4
		--assert str/:idx = #"d"
		idx: 1
		str/:idx: #"0"
		--assert str/:idx = #"0"
		--assert str/1 = #"0"

	--test-- "str-4"
		str: "456o"
		idx: 2
		--assert str/(1) = #"4"
		--assert str/(1 + 2) = #"6"
		--assert str/(idx) = #"5"

	--test-- "str-5"
		str/(1): #"9"
		--assert str/1 = #"9"
		idx: 2
		str/(idx + 2): #"z"	
		--assert str/4 = #"z"

	--test-- "str-6"
		inc: func [a][a + 1]
		--assert str/(inc 1) = #"5"
	
	--test-- "str-7 - issue #1113"
		s7-a: "abcz"
		s7-b: 5
		--assert none = s7-a/5
		--assert none = s7-a/:s7-b

===end-group===


===start-group=== "paren paths"

	ppt-get: function [b [block!] i [integer!]][b/(i + 1)]
	ppt-set: function [b [block!] i [integer!] v][b/(i + 1): v]
	ppt-ret: function [b [block!]][b/(return 'returned) 'not-returned]
	ppt-trail: make block! 8
	ppt-tick: func [tag [word!] value][append ppt-trail tag :value]
	ppt-order: function [b [block!]][i: 1 v: b/:i/(i: 2 1) reduce [v i]]
	ppt-ret2: function [b [block!]][b/1/(return 'second) 'not-returned]
	ppt-exit: function [b [block!]][b/1/(exit) 'not-exited]
	ppt-gc: function [][nb: [[1 9] [3 4]] nb/(recycle 2)/(recycle 1)]

	--test-- "paren-path-1"
		ppt-b: [10 20 30 [40 50] x 60]
		--assert 20 = ppt-get ppt-b 1
		--assert 50 = ppt-b/(1 + 3)/(1 + 1)
		--assert 60 = ppt-b/('x)
		--assert 10 = ppt-b/((1))
		--assert none? ppt-b/(99)
		--assert none? ppt-b/(0)
		--assert error? try [ppt-b/(99)/1]
		--assert error? try [ppt-b/(())]

	--test-- "paren-path-2"
		ppt-c: copy/deep [10 20 30 [40 50]]
		--assert 99 = ppt-set ppt-c 0 99
		--assert 7 = ppt-c/(1 + 3)/(1): 7
		--assert [99 20 30 [7 50]] = ppt-c
		--assert error? try [ppt-c/(99): 1]

	--test-- "paren-path-3"
		ppt-s: copy "hello"
		--assert #"e" = ppt-s/(1 + 1)
		--assert #"j" = ppt-s/(1): #"j"
		--assert "jello" = ppt-s
		ppt-bin: copy #{010203}
		--assert 2 = ppt-bin/(1 + 1)
		ppt-m: make map! [a: 1 "k" 2]
		--assert 2 = ppt-m/("k")
		--assert 5 = ppt-m/('n): 5
		--assert 5 = ppt-m/n
		ppt-v: make vector! [1 2 3]
		--assert 20 = ppt-v/(1 + 1): 20
		--assert 20 = ppt-v/2
		ppt-p: 3x4
		--assert 4 = ppt-p/('y)
		--assert 9 = ppt-p/(1): 9
		--assert 9x4 = ppt-p

	--test-- "paren-path-4"						;-- objects, on-change*
		ppt-o: object [
			a: 1
			sub: object [x: 1x2]
			on-change*: func [word old new][append ppt-trail word]
		]
		clear ppt-trail
		--assert 1 = ppt-o/('a)
		--assert 5 = ppt-o/('a): 5
		--assert [a] = ppt-trail
		--assert 42 = ppt-o/('sub)/x/(1): 42
		--assert 42x2 = ppt-o/sub/x
		--assert error? try [ppt-o/('zz)]

	--test-- "paren-path-5"						;-- get-paths
		--assert 20 = :ppt-b/(1 + 1)
		ppt-fb: reduce ['foo does [42]]
		--assert function? :ppt-fb/('foo)
		--assert 42 = ppt-fb/('foo)
		--assert unset? :ppt-o/('zz)

	--test-- "paren-path-6"						;-- evaluation order, return, break, throw
		ppt-nb: [[1 2] [3 4]]
		clear ppt-trail
		--assert 9 = ppt-nb/(ppt-tick 'a 1)/(ppt-tick 'b 2): ppt-tick 'v 9
		--assert [v a b] = ppt-trail
		--assert [[1 9] [3 4]] = ppt-nb
		--assert 'returned = ppt-ret [1]
		ppt-r: make block! 3
		loop 3 [append ppt-r ppt-nb/(if 1 < length? ppt-r [break] 1)]
		--assert [1 9] = ppt-r
		--assert 'thrown = catch [ppt-nb/(throw 'thrown)]
		--assert 20 = ppt-b/(ppt-x: 1 ppt-x + 1)

	--test-- "paren-path-7"						;-- each paren runs when the walk reaches it
		ppt-ob: [[10] [20]]
		ppt-i: 1
		--assert 10 = ppt-ob/:ppt-i/(ppt-i: 2 1)
		--assert 2 = ppt-i
		ppt-i: 1
		--assert 99 = ppt-ob/:ppt-i/(ppt-i: 2 1): 99
		--assert [[99] [20]] = ppt-ob
		--assert [10 2] = ppt-order [[10] [20]]
		ppt-hb: [[5] [6]]
		--assert 5 = ppt-hb/1/(ppt-hb: [[9]] 1)
		ppt-mb: [[1 2] [3 4]]
		ppt-i: 1
		--assert 4 = ppt-mb/(ppt-i: 2)/:ppt-i
		ppt-eb: [[1 2] [3 4]]
		clear ppt-trail
		--assert error? try [ppt-eb/(ppt-tick 'a 3)/1/(ppt-tick 'b 1)]
		--assert [a] = ppt-trail
		ppt-fr: reduce ['foo func [/bar][either bar ['baz]['qux]]]
		clear ppt-trail
		--assert error? try [ppt-fr/('foo)/(ppt-tick 'c 'bar)]
		--assert [] = ppt-trail

	--test-- "paren-path-8"						;-- GC, return, exit and break in a later paren
		--assert 3 = ppt-gc
		ppt-gb: reduce [reduce [1 2] reduce [3 1x2]]
		--assert 2 = ppt-gb/(1)/(recycle 2)
		ppt-gb/(2)/(2)/(recycle 1): 5
		--assert 5x2 = ppt-gb/2/2
		--assert 'second = ppt-ret2 [[1]]
		--assert unset? ppt-exit [[1]]
		ppt-n: 0
		loop 3 [ppt-n: ppt-n + 1 ppt-eb/1/(break)]
		--assert 1 = ppt-n

	--test-- "paren-path-9"						;-- a paren setting a field of an object with on-change*
		ppt-oc: object [i: 0 on-change*: func [word old new][append ppt-trail word]]
		ppt-onset: function [][nb: [[1 2] [3 4]] r: nb/(1)/(ppt-oc/i: 2) reduce [r ppt-oc/i]]
		ppt-sb: [10]
		clear ppt-trail
		--assert 10 = ppt-sb/(ppt-oc/i: 1)
		--assert 1 = ppt-oc/i
		--assert [i] = ppt-trail
		ppt-snb: [[1 2] [3 4]]
		--assert 3 = ppt-snb/(ppt-oc/i: 2)/(ppt-oc/i: 1)
		--assert 1 = ppt-oc/i
		ppt-sc: copy [1 2]
		ppt-sc/(ppt-oc/i: 2): 99
		--assert [1 99] = ppt-sc
		--assert 2 = ppt-oc/i
		--assert [2 2] = ppt-onset

===end-group===


===start-group=== "self paths"

	spt-trail: make block! 4
	spt-o: context [
		lb: [1 2 3]
		w: 'lb
		paren-get: func [][self/(w)/(1)]
		paren-set: func [][self/(w)/(2): 'x]
		getword: func [][self/:w]
		getword-int: func [][self/:w/1]
		word-int-set: func [][self/lb/3: 'z]
		getword-set: func [][self/:w: [4 5 6]]
		in-do: func [][do [self/lb]]
	]
	spt-d: make spt-o [lb: [7 8 9]]
	spt-e: context [
		a: 1
		w: 'a
		on-change*: func [word old new][append spt-trail word]
		set-a: func [v][self/(w): v]
		set-a2: func [v][self/:w: v]
	]

	--test-- "self-path-1"
		--assert 1 = spt-o/paren-get
		--assert 'x = spt-o/paren-set
		--assert [1 x 3] = spt-o/getword
		--assert 1 = spt-o/getword-int
		--assert 'z = spt-o/word-int-set
		--assert [1 x z] = spt-o/lb

	--test-- "self-path-2"
		--assert [4 5 6] = spt-o/getword-set
		--assert [4 5 6] = spt-o/lb
		--assert [4 5 6] = spt-o/in-do

	--test-- "self-path-3"						;-- copy made at compile time
		--assert 7 = spt-d/paren-get
		--assert 7 = spt-d/getword-int
		--assert [7 8 9] = spt-d/in-do

	--test-- "self-path-4"						;-- on-change* through SELF paths
		--assert 5 = spt-e/set-a 5
		--assert 6 = spt-e/set-a2 6
		--assert [a a] = spt-trail
		--assert 6 = spt-e/a

===end-group===


===start-group=== "issues"

	--test-- "issue #1993"
		s: object [v: object [a: none]]
		live?: s/v/a: no
		--assert live? == false
		--assert s/v/a == false

		do [
			range: [0 0]
			a: range/2: 1
			--assert range = [0 1]
			--assert a = 1
		]

	--test-- "issue #2525"
		u: %a/b
		--assert %a/b/1 = u/1
		--assert %a/b/c/1 = u/c/1

		u: %a/b
		--assert %a/b/c/d = u/c/d
		--assert error? try [u/c/d: 123]

		face2525: object [size: 80x24]
		min-size: 345x50
		--assert min-size/x + 10 = 355
		face2525/size/y: min-size/y + 10
		--assert face2525/size/y = 60

	--test-- "issue #3845"
		u: ["b" ["c" ["d" 1]]]
		--assert 1 = u/("b")/("c")/("d")

	--test-- "issue #4910"
		o4910: object [unset a: 'a]
		--assert unset? get/any 'o4910/a

		a4910: context [b: context [c: 123]]
		--assert 123 = get 'a4910/b/c
		--assert unset? get/any 'a4910/b/zz
		--assert error? try [get 'a4910/zz/c]

	--test-- "issue #4988"
		do [									; test specifically from interpreter
			o4988: context [f: does [print 123]] 
			--assert function? get 'o4988/f
		]

	--test-- "issue #5101"
		do [									; for interpreter only
			o5101: object [a: 1]				; compiler would report an error
			--assert error? try [o5101/b: 1]
		]

===end-group===

===start-group=== "functions reached through paths"

	--test-- "path-call-1"						;-- compiled code cannot pass the argument: no-arg, no crash
		fpc-b: reduce ['one func [x][x + 1] 'zero does [42]]
		fpc-e: try [fpc-b/('one) 5]
		either system/state/interpreted? [
			--assert 6 = fpc-e
		][
			--assert error? fpc-e
			--assert 'no-arg = fpc-e/id
		]

	--test-- "path-call-2"
		fpc-o: reduce [object [f: func [x][x * 2]]]
		fpc-e: try [fpc-o/(1)/f 5]
		either system/state/interpreted? [
			--assert 10 = fpc-e
		][
			--assert error? fpc-e
			--assert 'no-arg = fpc-e/id
		]

	--test-- "path-call-3"
		--assert error? try [append/('only) [] [1]]

	--test-- "path-call-4"
		fpc-h: func [x /r][x]
		fpc-hh: :fpc-h
		--assert error? try [fpc-hh/(1) 5]

	--test-- "path-call-5"						;-- traced call from compiled code
		fpc-f0: does [fpc-b/('zero)]
		fpc-tracer: function [event [word!] code [any-block! none!] offset [integer!] value [any-type!] ref [any-type!] frame [pair!]][]
		--assert 42 = do/trace [fpc-f0] :fpc-tracer

===end-group===

~~~end-file~~~
