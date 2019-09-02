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

	--test-- "rf-1" 	; sanity check
		rf-1-r: make reactor! [a: 1 b: is [a * 2]]
		--assert 0 < length? system/reactivity/relations
		clear-reactions
		--assert empty? system/reactivity/relations
		unset [rf-1-r]

	--test-- "rf-2" 	; shouldn't add duplicate relations
		clear-reactions
		rf-2-r: make reactor! [a: 1 b: is [a * a * a]]
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
				b: is [a + a] 											; +1
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
		rf-6c: context [ x: is [rf-6r/x] ]
		--assert 1 * 4 = length? system/reactivity/relations 	;-- should only be a single reaction
		--assert rf-6r = :system/reactivity/relations/1 		;-- `r` should be the source object
		unset [rf-6c rf-6r]

	--test-- "rf-7"	; #3333 triple-reaction case
		clear-reactions
		rf-7r: make reactor! [x: 1]
		rf-7x: is [rf-7r/x]
		--assert 1 * 4 = length? system/reactivity/relations 	;-- should only be a single reaction
		--assert rf-7r = :system/reactivity/relations/1 		;-- `r` should be the source object
		unset [rf-7r rf-7x]


	;-- final group cleanup
	clear-reactions

===end-group===

===start-group=== "regression tests"

	--test-- "#3091"
		a3091: make reactor! [b: 5 c: is [b]]
		do bind [b: 2] a3091
		--assert a3091/c = 2

	--test-- "#4022"
		do [													;-- force through interpreter as
			a4022: make reactor! [i: repeat i 2 [i]]			;-- `repeat` returns unset when compiled.
			--assert a4022/i = 2
		]
	

===end-group===

~~~end-file~~~