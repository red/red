Red [
	Title:   "Red reactivity test script"
	Author:  "Nenad Rakocevic"
	File: 	 %reactivity-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "reactivity"

===start-group=== "TIE function"

	--test-- "tie-1"
		tie-1a: make reactor! [x: 1 tie y: [x + 1]]
		--assert tie-1a/x == 1
		--assert tie-1a/y == 2
		tie-1a/x: 5
		--assert tie-1a/y == 6
		unset 'tie-1a

	--test-- "tie-2"
		tie-2a: make reactor! [x: 1 tie y: [x + 1]]
		--assert [x + 1] = react? tie-2a 'x
		--assert 	 none? react?/target tie-2a 'x
		--assert [x + 1] = react?/target tie-2a 'y
		--assert     none? react? tie-2a 'y
		unset 'tie-2a
	
	--test-- "tie-3"
		tie-3b: make reactor! [x: 2 y: 3 tie z: [x + y]]
		--assert tie-3b/x == 2
		--assert tie-3b/y == 3
		--assert tie-3b/z == 5
		tie-3b/x: 5
		--assert tie-3b/z == 8
		unset 'tie-3b

	--test-- "tie-4"
		tie-4b: make reactor! [x: 2 y: 3 tie z: [x + y]]
		--assert [x + y] = react? tie-4b 'x
		--assert [x + y] = react? tie-4b 'y
		--assert [x + y] = react?/target tie-4b 'z
		unset 'tie-4b
    
    --test-- "tie-5"
		tie-5c: make reactor! [x: 1 tie y: [x + 1] tie z: [y + 1]]
		--assert tie-5c/x == 1
		--assert tie-5c/y == 2
		--assert tie-5c/z == 3
		tie-5c/x: 4
		--assert tie-5c/y == 5
		--assert tie-5c/z == 6
		unset 'tie-5c

	--test-- "tie-6"
		tie-6c: make reactor! [x: 1 tie y: [x + 1] tie z: [y + 1]]
		--assert [x + 1] = react? tie-6c 'x
		--assert     none? react?/target tie-6c 'x
		--assert [x + 1] = react?/target tie-6c 'y
		--assert [y + 1] = react? tie-6c 'y
		--assert none? react? tie-6c 'z
		--assert [y + 1] = react?/target tie-6c 'z
		unset 'tie-6c

	--test-- "tie-7"
		tie-7d: make reactor! [tie x: [attempt [y + 1]] tie y: [attempt [x + 3]]]
		--assert none? tie-7d/x
		--assert none? tie-7d/y
		tie-7d/x: 1
		--assert tie-7d/x = 5
		--assert tie-7d/y = 4
		unset 'tie-7d

	--test-- "tie-8"
		tie-8r: make reactor! [tie x: [attempt [y + 1]] tie y: [attempt [z + 2]] tie z: [attempt [x + 3]]]
		--assert none? tie-8r/x
		--assert none? tie-8r/y
		--assert none? tie-8r/z
		tie-8r/x: 1
		--assert tie-8r/x = 7
		--assert tie-8r/z = 4
		--assert tie-8r/y = 6
		tie-8r/y: 1
		--assert tie-8r/y = 7
		--assert tie-8r/x = 2
		--assert tie-8r/z = 5
		tie-8r/z: 1
		--assert tie-8r/z = 7
		--assert tie-8r/y = 3
		--assert tie-8r/x = 4
		unset 'tie-8r


	;-- final group cleanup
	clear-reactions

===end-group===

===start-group=== "relations formation"

	--test-- "rf-1" 	; sanity check
		rf-1-r: make reactor! [a: 1 tie b: [a * 2]]
		--assert 0 < length? system/reactivity/relations
		clear-reactions
		--assert empty? system/reactivity/relations
		unset [rf-1-r]

	--test-- "rf-2" 	; shouldn't add duplicate relations
		clear-reactions
		rf-2-r: make reactor! [a: 1 tie b: [a * a * a]]
		--assert 1 * 4 = length? system/reactivity/relations
		unset [rf-2-r]

	--test-- "rf-3" 	; same
		clear-reactions
		do [	; FIXME: workaround for #3797
			rf-3-r: make reactor! [a: b: 1  react [self/b: self/a * self/a * self/a]]
			--assert 1 * 4 = length? system/reactivity/relations
			--assert (rf-3-r/a: 2  rf-3-r/b = 8)
		]
		unset [rf-3-r]

	--test-- "rf-4"	; same
		clear-reactions
		do [	; FIXME: workaround for #3797
			rf-4-r: make reactor! [a: b: c: 1  react [self/c: self/a * self/a * self/b * self/b]]
			--assert 2 * 4 = length? system/reactivity/relations
			--assert (rf-4-r/a: 2  rf-4-r/c = 4)
			--assert (rf-4-r/b: 2  rf-4-r/c = 16)
		]
		unset [rf-4-r]

	--test-- "rf-5" 	; same
		clear-reactions
		do [	; FIXME: workaround for #3797
			rf-5-r: make reactor! [
				a: b: c: d: 1
				tie b: [a + a] 											; +1
				react [self/c: self/a * self/b * a * b]					; +2
				react [self/d: self/a + self/b + self/c + a + b + c] 	; +3
			]
			--assert 6 * 4 = length? system/reactivity/relations
			--assert (rf-5-r/a: 2  rf-5-r/b = 4)
			--assert rf-5-r/c = 64
			--assert rf-5-r/d = (2 + 4 + 64 * 2)
		]
		unset [rf-5-r]

	--test-- "rf-6"	; #3333 where `is` produced an excessive reaction with the wrong target object
		clear-reactions
		rf-6r: make reactor! [x: 1]
		rf-6c: context [tie x: [rf-6r/x] ]
		--assert 1 * 4 = length? system/reactivity/relations 	;-- should only be a single reaction
		--assert rf-6r = :system/reactivity/relations/1 		;-- `r` should be the source object
		unset [rf-6c rf-6r]

	--test-- "rf-7"	; #3333 triple-reaction case
		clear-reactions
		rf-7r: make reactor! [x: 1]
		tie rf-7x: [rf-7r/x]
		--assert 1 * 4 = length? system/reactivity/relations 	;-- should only be a single reaction
		--assert rf-7r = :system/reactivity/relations/1 		;-- `r` should be the source object
		unset [rf-7r rf-7x]

	;-- final group cleanup
	clear-reactions

===end-group===

===start-group=== "deep reactions"

	--test-- "dpr-1"
		cnt: 0
		dpr1: deep-reactor [s: "hello"]
		react [if dpr1/s <> "hello" [cnt: cnt + 1]]
		dpr1/s/2: #"x"
		--assert cnt = 1

	--test-- "dpr-2"
		cnt: 0
		dpr2: deep-reactor [s: [a b c]]
		react [if dpr2/s/2 <> 'b [cnt: cnt + 1]]
		dpr2/s/2: 'x
		--assert cnt = 1

	--test-- "dpr-3"
		cnt: 0
		dpr3: deep-reactor [pos: 3x4 e: hello@d.com c: 1.2.3 b: make bitset! 5]
		react [if dpr3/pos/x > 10 [cnt: cnt + 1]]
		react [if dpr3/e/user <> "hello" [cnt: cnt + 1]]
		react [if dpr3/c/1 > 100 [cnt: cnt + 1]]
		react [if dpr3/b/3 [cnt: cnt + 1]]
		dpr3/pos/x: 2
		dpr3/pos/x: 12
		--assert cnt = 1
		dpr3/e/host: "d2.com"
		dpr3/e/user: "hi"
		--assert cnt = 2
		dpr3/c/2: 200
		dpr3/c/1: 240
		--assert cnt = 3
		dpr3/b/1: true
		dpr3/b/3: true
		--assert cnt = 4

===end-group===

===start-group=== "regression tests"

	--test-- "#3091"
		a3091: make reactor! [b: 5 tie c: [b]]
		do bind [b: 2] a3091
		--assert a3091/c = 2

	--test-- "#4022"
		do [													;-- force through interpreter as
			a4022: make reactor! [i: repeat i 2 [i]]			;-- `repeat` returns unset when compiled.
			--assert a4022/i = 2
		]
	
	--test-- "#4176"
		do [
			r: make reactor! [
				n: 1
				tie c: [1x1 * n]
				tie x: [c/x]
				tie t: [n * 1:0:0]
				tie hms: [rejoin [t/hour t/minute t/second]]
			]
			--assert (skip body-of r 2) == [
				n: 1 
				c: 1x1 
				x: 1 
				t: 1:00:00 
				hms: "100.0"
			]
			r/n: 2
			--assert (skip body-of r 2) == [
				n: 2
				c: 2x2
				x: 2
				t: 2:00:00
				hms: "200.0"
			]
		]

	--test-- "#4510"
		clear-reactions
		a: reactor [data: none]
		b: reactor [data: none]
		react/later [--assert true a/('data)]
		react/link/later func [a b] [--assert true a/('data)] [a b]
		--assert empty? system/reactivity/relations
		
===end-group===

~~~end-file~~~