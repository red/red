Red [
	Title:   "Red MOVE test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %move-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "move"

===start-group=== "same blocks"

	--test-- "move-1"
		list: [a b c d e]
		move list at list 1
		--assert list = [a b c d e]

	--test-- "move-2"
		list: [a b c d e]
		move list at list 2
		--assert list = [b a c d e]

	--test-- "move-3"
		list: [a b c d e]
		move list at list 3
		--assert list = [b c a d e]

	--test-- "move-4"
		list: [a b c d e]
		move list at list 4
		--assert list = [b c d a e]

	--test-- "move-5"
		list: [a b c d e]
		move list at list 5
		--assert list = [b c d e a]

	--test-- "move-6"
		list: [a b c d e]
		move list at list 6
		--assert list = [b c d e a]

	--test-- "move-7"
		list: [a b c d e]
		move list tail list
		--assert list = [b c d e a]

	--test-- "move-8"
		list: [a b c d e]
		move back tail list list
		--assert list = [e a b c d]

	--test-- "move-9"
		list: [a b c d e]
		move back back tail list at list 2
		--assert list = [a d b c e]

	--test-- "move-10"
		list: [a b c d e]
		move/part list tail list 2
		--assert list = [c d e a b]

===end-group===

===start-group=== "different blocks"

	--test-- "move-diff-1"
		list1: [a b c]
		list2: [d e f]
		move list1 list2
		--assert list1 = [b c]
		--assert list2 = [a d e f]

	--test-- "move-diff-2"
		list1: [a b c]
		list2: [d e f]
		move at list1 2 at list2 2
		--assert list1 = [a c]
		--assert list2 = [d b e f]

	--test-- "move-diff-3"
		list1: [a b c]
		list2: [d e f]
		move list1 tail list2
		--assert list1 = [b c]
		--assert list2 = [d e f a]

	--test-- "move-diff-4"
		list1: [a b c]
		list2: [d e f]
		move/part list1 list2 2
		--assert list1 = [c]
		--assert list2 = [a b d e f]

	--test-- "move-diff-5"
		list1: [a b c]
		list2: [d e f]
		move/part at list1 2 at list2 2 2
		--assert list1 = [a]
		--assert list2 = [d b c e f]

	--test-- "move-diff-6"
		list1: [a b c]
		list2: [d e f]
		move/part list1 tail list2 2
		--assert list1 = [c]
		--assert list2 = [d e f a b]

	--test-- "move-diff-7"
		list1: [a b c]
		list2: []
		move/part list1 tail list2 3
		--assert list1 = []
		--assert list2 = [a b c]

===end-group===

~~~end-file~~~