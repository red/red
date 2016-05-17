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

	--test-- "move-11"
		hash: make hash! [a b c d e f g 1 2 3]
		hash2: skip hash 6
		move hash hash2
		move/part hash hash2 3
		move/part hash2 hash 2
		--assert 1 = hash/d
		--assert 'e = select hash 1
		--assert 'f = hash/e
		--assert 'c = hash/b
		--assert 2 = hash/c
		--assert 3 = select hash 2

	--test-- "issue-1905"
		list: [a b c d e f g]
		move/part list skip list 3 2
		--assert list = [c d a b e f g]

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

	--test-- "move-diff-8"
		hash1: make hash! [a b c d e f g 1 2 3]
		hash2: make hash! [x y z 7 8 9]
		move hash1 hash2
		move/part hash1 hash2 3
		move/part skip hash2 3 hash1 3
		move/part skip hash1 3 skip hash2 2 3
		--assert 'x = hash1/a
		--assert 1 = hash1/y
		--assert 'y = hash1/x
		--assert 2 = select hash1 1
		--assert 'c = hash2/b
		--assert 'e = hash2/c
		--assert 'g = hash2/f
		--assert 7 = hash2/z
		--assert 8 = select hash2 7
===end-group===

===start-group=== "same strings"

	--test-- "mv-str-1"
		str: "abcde"
		move str at str 1
		--assert str = "abcde"

	--test-- "mv-str-2"
		str: "abcde"
		move str at str 2
		--assert str = "bacde"

	--test-- "mv-str-3"
		str: "abcde"
		move str at str 3
		--assert str = "bcade"

	--test-- "mv-str-4"
		str: "abcde"
		move str at str 4
		--assert str = "bcdae"

	--test-- "mv-str-5"
		str: "abcde"
		move str at str 5
		--assert str = "bcdea"

	--test-- "mv-str-6"
		str: "abcde"
		move str at str 6
		--assert str = "bcdea"

	--test-- "mv-str-7"
		str: "abcde"
		move str tail str
		--assert str = "bcdea"

	--test-- "mv-str-8"
		str: "abcde"
		move back tail str str
		--assert str = "eabcd"

	--test-- "mv-str-9"
		str: "abcde"
		move back back tail str at str 2
		--assert str = "adbce"

	--test-- "mv-str-10"
		str: "abcde"
		move/part str tail str 2
		--assert str = "cdeab"

	--test-- "issue-1905-str"
		str: "abcdefg"
		move/part str skip str 3 2
		--assert str = "cdabefg"


===end-group===

===start-group=== "different strings"

	--test-- "mv-str-diff-1"
		str1: "abc"
		str2: "def"
		move str1 str2
		--assert str1 = "bc"
		--assert str2 = "adef"

	--test-- "mv-str-diff-2"
		str1: "abc"
		str2: "def"
		move at str1 2 at str2 2
		--assert str1 = "ac"
		--assert str2 = "dbef"

	--test-- "mv-str-diff-3"
		str1: "abc"
		str2: "def"
		move str1 tail str2
		--assert str1 = "bc"
		--assert str2 = "defa"

	--test-- "mv-str-diff-4"
		str1: "abc"
		str2: "def"
		move/part str1 str2 2
		--assert str1 = "c"
		--assert str2 = "abdef"

	--test-- "mv-str-diff-5"
		str1: "abc"
		str2: "def"
		move/part at str1 2 at str2 2 2
		--assert str1 = "a"
		--assert str2 = "dbcef"

	--test-- "mv-str-diff-6"
		str1: "abc"
		str2: "def"
		move/part str1 tail str2 2
		--assert str1 = "c"
		--assert str2 = "defab"

	--test-- "mv-str-diff-7"
		str1: "abc"
		str2: ""
		move/part str1 tail str2 3
		--assert str1 = ""
		--assert str2 = "abc"

===end-group===

===start-group=== "different encodings"

	--test-- "mv-str-unit-1"
		str1: "abc"
		str2: "一二三"
		move str1 str2
		--assert str1 = "bc"
		--assert str2 = "a一二三"

	--test-- "mv-str-unit-2"
		str1: "abc"
		str2: "一二三"
		move at str1 2 at str2 2
		--assert str1 = "ac"
		--assert str2 = "一b二三"

	--test-- "mv-str-unit-3"
		str1: "abc"
		str2: "一二三"
		move str1 tail str2
		--assert str1 = "bc"
		--assert str2 = "一二三a"

	--test-- "mv-str-unit-4"
		str1: "abc"
		str2: "一二三"
		move/part str1 str2 2
		--assert str1 = "c"
		--assert str2 = "ab一二三"

	--test-- "mv-str-unit-5"
		str1: "abc"
		str2: "一二三"
		move/part at str1 2 at str2 2 2
		--assert str1 = "a"
		--assert str2 = "一bc二三"

	--test-- "mv-str-unit-6"
		str1: "abc"
		str2: "一二三"
		move/part str1 tail str2 2
		--assert str1 = "c"
		--assert str2 = "一二三ab"

	--test-- "mv-str-unit-7"
		str1: "一二三"
		str2: ""
		move/part str1 tail str2 3
		--assert str1 = ""
		--assert str2 = "一二三"

===end-group===

~~~end-file~~~