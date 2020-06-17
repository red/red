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

===start-group=== "IS function"

	--test-- "is-1"
		is-1a: make reactor! [x: 1 y: is [x + 1]]
		--assert is-1a/x == 1
		--assert is-1a/y == 2
		is-1a/x: 5
		--assert is-1a/y == 6
		unset 'is-1a

	--test-- "is-2"
		is-2a: make reactor! [x: 1 y: is [x + 1]]
		--assert [x + 1] = react? is-2a 'x
		--assert 	 none? react?/target is-2a 'x
		--assert [x + 1] = react?/target is-2a 'y
		--assert     none? react? is-2a 'y
		unset 'is-2a
	
	--test-- "is-3"
		is-3b: make reactor! [x: 2 y: 3 z: is [x + y]]
		--assert is-3b/x == 2
		--assert is-3b/y == 3
		--assert is-3b/z == 5
		is-3b/x: 5
		--assert is-3b/z == 8
		unset 'is-3b

	--test-- "is-4"
		is-4b: make reactor! [x: 2 y: 3 z: is [x + y]]
		--assert [x + y] = react? is-4b 'x
		--assert [x + y] = react? is-4b 'y
		--assert [x + y] = react?/target is-4b 'z
		unset 'is-4b
    
    --test-- "is-5"
		is-5c: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		--assert is-5c/x == 1
		--assert is-5c/y == 2
		--assert is-5c/z == 3
		is-5c/x: 4
		--assert is-5c/y == 5
		--assert is-5c/z == 6
		unset 'is-5c

	--test-- "is-6"
		is-6c: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		--assert [x + 1] = react? is-6c 'x
		--assert     none? react?/target is-6c 'x
		--assert [x + 1] = react?/target is-6c 'y
		--assert [y + 1] = react? is-6c 'y
		--assert none? react? is-6c 'z
		--assert [y + 1] = react?/target is-6c 'z
		unset 'is-6c

	--test-- "is-7"
		is-7d: make reactor! [x: is [attempt [y + 1]] y: is [attempt [x + 3]]]
		--assert none? is-7d/x
		--assert none? is-7d/y
		is-7d/x: 1
		--assert is-7d/x = 1 							;-- x is fixed by the assignment
		--assert is-7d/y = 4
		unset 'is-7d

	--test-- "is-8"
		is-8r: make reactor! [x: is [attempt [y + 1]] y: is [attempt [z + 2]] z: is [attempt [x + 3]]]
		--assert none? is-8r/x
		--assert none? is-8r/y
		--assert none? is-8r/z
		is-8r/x: 1
		--assert is-8r/x = 1 							;-- x is fixed by the assignment
		--assert is-8r/z = 4
		--assert is-8r/y = 6
		is-8r/y: 1
		--assert is-8r/y = 1 							;-- y is fixed by the assignment
		--assert is-8r/x = 2
		--assert is-8r/z = 5
		is-8r/z: 1
		--assert is-8r/z = 1 							;-- z is fixed by the assignment
		--assert is-8r/y = 3
		--assert is-8r/x = 4
		unset 'is-8r


	;-- final group cleanup
	clear-reactions

===end-group===

===start-group=== "relations formation"

	--test-- "rf-1" 									;-- sanity check
		rf-1-r: make reactor! [a: 1 b: is [a * 2]]
		--assert 0 < system/reactivity/relations-count
		clear-reactions
		--assert 0 = system/reactivity/relations-count
		unset [rf-1-r]

	--test-- "rf-2" 									;-- shouldn't add duplicate relations
		clear-reactions
		rf-2-r: make reactor! [a: 1 b: is [a * a * a]]
		--assert 1 = system/reactivity/relations-count
		unset [rf-2-r]

	--test-- "rf-3" 									;-- same
		clear-reactions
		do [											;@@ FIXME: workaround for #3797
			rf-3-r: make reactor! [a: b: 1  react [self/b: self/a * self/a * self/a]]
			--assert 1 = system/reactivity/relations-count
			--assert (rf-3-r/a: 2  rf-3-r/b = 8)
		]
		unset [rf-3-r]

	--test-- "rf-4"										;-- same
		clear-reactions
		do [											;@@ FIXME: workaround for #3797
			rf-4-r: make reactor! [a: b: c: 1  react [self/c: self/a * self/a * self/b * self/b]]
			--assert 2 = system/reactivity/relations-count
			--assert (rf-4-r/a: 2  rf-4-r/c = 4)
			--assert (rf-4-r/b: 2  rf-4-r/c = 16)
		]
		unset [rf-4-r]

	--test-- "rf-5" 									;-- same
		clear-reactions
		do [											;@@ FIXME: workaround for #3797
			rf-5-r: make reactor! [
				a: b: c: d: 1
				b: is [a + a] 											;-- +1
				react [self/c: self/a * self/b * a * b]					;-- +2
				react [self/d: self/a + self/b + self/c + a + b + c] 	;-- +3
			]
			--assert 6 = system/reactivity/relations-count
			--assert (rf-5-r/a: 2  rf-5-r/b = 4)
			--assert rf-5-r/c = 64
			--assert rf-5-r/d = (2 + 4 + 64 * 2)
		]
		unset [rf-5-r]

	--test-- "rf-6"										;-- #3333 where `is` produced an excessive reaction with the wrong target object
		clear-reactions
		rf-6r: make reactor! [x: 1]
		rf-6c: context [ x: is [rf-6r/x] ]
		--assert 1 = system/reactivity/relations-count 		;-- should only be a single reaction
		--assert rf-6r =? :system/reactivity/index/2/1 		;-- `rf-6r` should be the source object
		unset [rf-6c rf-6r]

	--test-- "rf-7"										;-- #3333 triple-reaction case
		clear-reactions
		rf-7r: make reactor! [x: 1]
		rf-7x: is [rf-7r/x]
		--assert 1 = system/reactivity/relations-count 		;-- should only be a single reaction
		--assert rf-7r = :system/reactivity/index/2/1 		;-- `rf-7r` should be the source object
		unset [rf-7r rf-7x]

	--test-- "rf-8"										;-- correct path recognition
		clear-reactions
		rf-8r: make deep-reactor! [p: 1x1]					;-- deep-reactor to watch for p/x change
		rf-8x: is [rf-8r/p/x]								;-- single reaction on `rf-8r/p`
		--assert 1 = system/reactivity/relations-count
		--assert (rf-8r/p: 2x2  rf-8x = 2)
		--assert (rf-8r/p/x: 3  rf-8x = 3)
		--assert rf-8r/p = 3x2
		unset [rf-8r rf-8x]

	--test-- "rf-9"										;-- correct non-object path recognition
		clear-reactions
		rf-9r: make deep-reactor! [p: 1x1  x: is [p/x]]		;-- `is` must register p in p/x
		--assert 1 = system/reactivity/relations-count
		--assert rf-9r/x = 1
		--assert (rf-9r/p: 2x2  rf-9r/x = 2)
		--assert (rf-9r/p/x: 3  rf-9r/x = 3)
		--assert rf-9r/p = 3x2
		unset [rf-9r]

	--test-- "rf-10"									;-- correct non-object path recognition
		clear-reactions
		do [											;@@ FIXME: workaround for #3797
			rf-10r: make reactor! [a: 1 b: 2 c: 3  w: 'a  x: is [self/:w]]		;-- `is` must register :w in p/x
			--assert 1 = system/reactivity/relations-count
			--assert rf-10r/x = 1
			--assert (rf-10r/w: 'b  rf-10r/x = 2)
			--assert (rf-10r/w: 'c  rf-10r/x = 3)
		]
		unset [rf-10r]

	--test-- "rf-11"									;-- correct non-object path recognition; nested
		clear-reactions
		rf-11r: make deep-reactor! [
			p: 1x1 b: [a [1 2] b [3 4]] w: 'a
			x: is [b/:w/(p/x)]							;-- `is` must register b, :w, and p in p/x
		]
		--assert 3 = system/reactivity/relations-count
		--assert rf-11r/x = 1
		--assert (rf-11r/w:  'b  rf-11r/x = 3)
		--assert (rf-11r/p/x: 2  rf-11r/x = 4)
		unset [rf-11r]

	;-- final group cleanup
	clear-reactions

===end-group===

===start-group=== "regression tests"

	--test-- "#3091"
		a3091: make reactor! [b: 5 c: is [b]]
		do bind [b: 2] a3091
		--assert a3091/c = 2

	--test-- "#4022"
		a4022: make reactor! [i: repeat i 2 [i]]
		--assert a4022/i = 2

	--test-- "#4166-1"
		r4166: make reactor! [x: y: 1]
		react b4166: [r4166/y: 2 * r4166/x]
		--assert b4166 =? react? r4166 'x
		clear-reactions

	--test-- "#4166-2"
		do [											;@@ FIXME: compiler can't swallow such `on-change*`
			r4166: make reactor! [x: 1 y: is [x * 2]]
			o4166: object [
				on-change*: func spec-of :r4166/on-change* copy/deep body-of :r4166/on-change*
				x: 1 y: 2
			]
			--assert block? react?/target r4166 'y
			--assert not    react?/target o4166 'y		;-- should not be mistaken for r4166
		]
		clear-reactions

	--test-- "#4166-3"
		do [											;@@ FIXME: compiler can't swallow such `on-change*`
			r4166: make reactor! spec: [x: 1 y: is [x * 2]]
			o4166: object [
				on-change*: func spec-of :r4166/on-change* copy/deep body-of :r4166/on-change*
				x: 1 y: 2
			]
			react/unlink last spec o4166
			--assert (r4166/x: 3  r4166/y = 6)			;-- should not be unlinked
		]
		clear-reactions

	--test-- "#4176"
		r4176: make reactor! [n: 1 c: is [1x1 * n] x: is [c/x] t: is [n * 1:0:0] hms: is [rejoin [t/hour t/minute t/second]]]
		r4176/n: 2
		--assert r4176/c = 2x2
		--assert r4176/x = 2
		--assert r4176/t = 2:0:0
		--assert none <> find/match r4176/hms "200"		;-- allow both "200" and "200.0"
		clear-reactions

	--test-- "#4471-1"
		r4471: make reactor! [x: 1]
		b4471: []
		react [all [:r4471/x integer? r4471/x append b4471 r4471/x]]
		r4471/x: 2
		r4471/x: 3
		--assert b4471 = [1 2 3]
		clear-reactions

	--test-- "#4471-2"
		a4471: make deep-reactor! [text: 0]
		b4471: make deep-reactor! [text: 0]
		n4471: 0
		react/link func [a b] [n4471: n4471 + 1 a/text b/text b/text b/text] [a4471 b4471]
		--assert 1 = n4471
		--assert (b4471/text: 1  2 = n4471)
		clear-reactions

	;@@ FIXME: this requires `print` mockup, else it outputs the dump
	;@@ FIXME: this requires images to be garbage-collected, else they stay in RAM
	; --test-- "#4507"
	; 	a4507: make deep-reactor! [i: make image! 2000x2000]
	; 	b4507: make deep-reactor! [i: make image! 2000x2000 a: a4507]
	; 	react/link func [a b] [b/i] [a4507 b4507]
	; 	t04507: now/precise
	; 	dump-reactions
	; 	dt4507: difference now/precise t04507
	; 	--assert dt4507 < 0:0:1							;-- took ~10 sec originally
	; 	clear-reactions

	--test-- "#4510"
		a4510: make deep-reactor! [data: 0]
		b4510: make deep-reactor! [data: 0]
		react/later [a4510/('data)]
		react/link/later func [a b] [a/('data)] [a4510 b4510]
		--assert 0 = system/reactivity/relations-count
		clear-reactions


===end-group===

~~~end-file~~~