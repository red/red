Red [
	Title:   "Red map test script"
	Author:  "Peter W A Wood"
	File: 	 %map-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "map"

===start-group=== "make"
	
	--test-- "map-make-1"
		mm1-m: make map! [a none b 2 c 3]
		--assert 'none = mm1-m/a
		--assert 2 = mm1-m/b
		--assert 3 = mm1-m/c
		
	--test-- "map-make-2"
		mm2-m: make map! reduce ['a print "" 'b 2 'c 3]
		--assert unset! = type? mm2-m/a
		--assert 2 = mm2-m/b
		--assert 3 = mm2-m/c
	
===end-group=== 

===start-group=== "construction"
	
	--test-- "map-construction-1"
		mc1-m: #(a none b 2 c 3)
		--assert 'none = mc1-m/a
		--assert 2 = mc1-m/b
		--assert 3 = mc1-m/c
	
===end-group===

===start-group=== "delete key"

	--test-- "map-delete-key-1"
		mdk1-m: #(a: 1 b: 2 c: 3)
		mdk1-m/a: none
		--assert none = mdk1-m/a
		--assert none = find words-of mdk1-m 'a

	--test-- "map-delete-key-2"
		mdk2-m: #(a: 1 b: 2 c: 3)
		mdk2-m/a: 'none
		--assert 'none = mdk2-m/a
		--assert [a b c] = find words-of mdk2-m 'a
		
===end-group===

===start-group=== "find"

	--test-- "map-find-1"
		mf1-m: #(a: none b: 1 c: 2)
		--assert true = find mf1-m 'a
		--assert true = find mf1-m 'b
		--assert true = find mf1-m 'c
		--assert none = find mf1-m 'd
		
	--test-- "map-find-2"
		mf2-m: #(a: 1 b: 2 c: 3)
		mf2-m/a: 'none
		mf2-m/b: none
		--assert true = find mf2-m 'a
		--assert none = find mf2-m 'b
		--assert true = find mf2-m 'c

===end-group===

===start-group=== "copy"

	--test-- "map-copy-1"
		mcp1-m: #(a: 1 b: 2)
		mcp1-n: copy mcp1-m
		--assert 1 = mcp1-n/a
		--assert 2 = mcp1-n/b

===end-group===

===start-group=== "string keys"

	--test-- "map-string-keys-1"
		msk1-b: copy []
		msk1-k: copy "key"
		append msk1-b msk1-k
		append msk1-b copy "value"
		msk1-m: make map! msk1-b
		--assert "value" = select msk1-m msk1-k
		append msk1-k "chain"
		--assert none = select msk1-m msk1-k
		--assert "value" = select msk1-m "key"
		
	--test-- "map-string-keys-2"
		msk2-m: #("abcde" 1 "é" 2 "€" 3 "^(1D122)" 4)
		--assert 1 = select msk2-m "abcde"
		--assert 2 = select msk2-m "é"
		--assert 3 = select msk2-m "€"
		--assert 4 = select msk2-m "^(1D122)"
		
===end-group===

===start-group=== "put"

	--test-- "map-put-1"
		mput1-m: #(a: 1 b: 2)
		--assert 3 = put mput1-m 'c 3
		--assert 3 = mput1-m/c
		
	--test-- "map-put-2"
		mput2-m: #(a: 1 b: 2)
		--assert 4 = put mput2-m 'b 4
		--assert 4 = mput2-m/b
	
	--test-- "map-put-3"
		mput3-m: #(a: 1 b: 2)
		--assert unset! = type? put mput3-m 'a print ""
		--assert unset! = type? mput3-m/a
		--assert 2 = length? mput3-m 
		
	--test-- "map-put-4"
		mput4-m: #(a: 1 b: 2)
		--assert none = put mput4-m 'a none
		--assert none = find words-of mput4-m 'a
		--assert none = mput4-m/a
		--assert 1 = length? mput4-m

===end-group===

===start-group=== "function values"

	--test-- "map-func-1"
		mf1-a: 1
		mf1-m: make map! compose [
			mf1-a: 2
			f: (func[][mf1-a])
		]
		--assert 1 = do [mf1-m/f]
	
	--test-- "map-func-2"
		mf2-a: 1
		mf2-m: make map! compose [
			mf2-a: 2
			f: (func[][mf2-m/mf2-a])
		]
		--assert 2 = do [mf2-m/f]

===end-group===

===start-group=== "serialise"

	--test-- "map-serialise-1"
		mser1-m: #(a 1 b 2 c 3)
		--assert {#(^/    a: 1^/    b: 2^/    c: 3^/)} = mold mser1-m
		--assert "a: 1^/b: 2^/c: 3" = form mser1-m
	
	--test-- "map-serialise-2"
		mser2-m: #("a" 1 "b" 2 "c" 3)
		--assert {#(^/    "a" 1^/    "b" 2^/    "c" 3^/)} = mold mser2-m
		--assert {"a" 1^/"b" 2^/"c" 3} = form mser2-m
		
	--test-- "map-serialise-3"
		mser3-m: #(a 1 b 2 c 3)
		--assert #(a: 1 b: 2 c: 3) = load mold mser3-m
		--assert #(a: 1 b: 2 c: 3) = make map! load form mser3-m
	
	--test-- "map-serialise-4"
		mser4-m: #("a" 1 "b" 2 "c" 3)
		--assert #("a" 1 "b" 2 "c" 3) = load mold mser4-m
		--assert #("a" 1 "b" 2 "c" 3) = make map! load form mser4-m
		
	--test-- "map-serialise-5"
		--assert #(a: 1 b: 2 c: 3) = load mold #(a 1 b 2 c 3)
		--assert #(a: 1 b: 2 c: 3) = make map! load form #(a 1 b 2 c 3)
	
	--test-- "map-serialise-6"
		mser4-m: #("a" 1 "b" 2 "c" 3)
		--assert #("a" 1 "b" 2 "c" 3) = load mold #("a" 1 "b" 2 "c" 3)
		--assert #("a" 1 "b" 2 "c" 3) = make map! load form #("a" 1 "b" 2 "c" 3)

===end-group===

===start-group=== "issues"

	--test-- "issue-1835"
		m: make map! [a 1 A 2]
		--assert 2 = select/case m 'A
		--assert 1 = select/case m 'a

		--assert #(a: 2) = make map! [a: 1 a  2]
		--assert #(a: 2) = make map! [a  1 a: 2]

		m: make map! [a 1 A 2 a: 3 :a 4]
		--assert 4 = select m 'a
		--assert 4 = select m first [:a]
		--assert 4 = select/case m first [:a]
		--assert 4 = select/case m first [a:]
		--assert 2 = select/case m first [A]
		--assert 2 = select/case m 'A

	--test-- "issue-1834"
	--assert #(a: 3) = extend/case extend/case make map! [a 1] [a 2] [a 3]

===end-group===

~~~end-file~~~