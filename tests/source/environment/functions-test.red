Red [
	Title:   "Red functions test script"
	Author:  "mahengyang"
	File: 	 %functions-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic, Peter W A Wood & mahengyang. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "functions"

===start-group=== "also tests"

	--test-- "also-1" 
		at1-1: 2
		at1-2: also 1 reduce [at1-1: 3]
		--assert 1 = at1-2
		--assert 3 = at1-1
	
	--test-- "also-2" --assert [1] = also [1] 2
	--test-- "also-3" --assert none = also none 2 
	--test-- "also-4" --assert #"^(00)" = also #"^(00)" 2 
	
===end-group===

===start-group=== "attempt tests"

	--test-- "attempt-1" --assert 2 = attempt [1 + 1]
	--test-- "attempt-2" --assert none = attempt [1 / 0]
	--test-- "attempt-3" --assert none = attempt [1 * "abc"]

===end-group===

===start-group=== "quit tests"

	--test-- "mock quit/return 1"
		; TODO
		; backup-quit-return: :quit-return
		; quit-return: func [/return status] [any [status 0]]
		; --assert 0 = quit
		; --assert 1 = quit/return 1
		; quit-return: :backup-quit-return

===end-group===

===start-group=== "empty tests"

	--test-- "empty-1" --assert true = empty? []
	--test-- "empty-2" --assert true = empty? none
	--test-- "empty-3" --assert false = empty? [1]
	--test-- "empty-4" --assert false = empty? [[]]
	--test-- "empty-5" --assert true = empty? ""
	--test-- "empty-6" --assert false = empty? "a"
	--test-- "empty-7" --assert false = empty? [red blue]
	--test-- "empty-8" --assert false = empty? %functions-test.red

===end-group===

===start-group=== "?? tests"
	--test-- "mock ?? print"
		; TODO
		; save-print: :print
		; save-prin: :prin 
		; output: copy ""
		; print: function[val][append output reduce value]
		; prin: function[val][append output reduce value]
		; ??-1-a: 1
		; ?? ??-1-a
    	; --assert none <> find output "??-1-a: 1"
   		; print: :save-print
   		; prin: :save-prin
===end-group===

===start-group=== "probe tests"
	;; TODO
	;; PROBE NEEDS TO BE MOCKED TO STOP PROBE OUTPUT LEAKING IN TO TEST OUTPUT
	;--test-- "probe-test-1" --assert 1 = probe 1
	;--test-- "probe-test-2" --assert [1] = probe [1]
	;--test-- "probe-test-3" --assert :prin = probe :prin
	;--test-- "probe-test-4" --assert "1" = probe "1"
	;--test-- "probe-test-5" --assert [] = probe []

===end-group===

===start-group=== "quote tests"
	
	--test-- "quote-test-1" --assert 1 = quote 1

===end-group===

===start-group=== "first tests"
	--test-- "first-test-1" --assert #"a" = first "abcde"
	--test-- "first-test-2" --assert 1 = first [1 2 3 4 5]
	--test-- "first-test-3" --assert 1 = first 1.2.3.4.5
	--test-- "first-test-4" --assert 1 = first 1x2
	--test-- "first-test-5" --assert 12 = first 12:13:14.15
===end-group===

===start-group=== "second tests"
	--test-- "second-test-1" --assert #"b" = second "abcde"
	--test-- "second-test-2" --assert 2 = second [1 2 3 4 5]
	--test-- "second-test-3" --assert 2 = second 1.2.3.4.5
	--test-- "second-test-4" --assert 2 = second 1x2
	--test-- "second-test-5" --assert 13 = second 12:13:14.15
===end-group===

===start-group=== "third tests"
	--test-- "third-test-1" --assert #"c" = third "abcde"
	--test-- "third-test-2" --assert 3 = third [1 2 3 4 5]
	--test-- "third-test-3" --assert 3 = third 1.2.3.4.5
	--test-- "third-test-4" --assert 14 = third 12:13:14
===end-group===

===start-group=== "fourth tests"
	--test-- "fourth-test-1" --assert #"d" = fourth "abcde"
	--test-- "fourth-test-2" --assert 4 = fourth [1 2 3 4 5]
	--test-- "fourth-test-3" --assert 4 = fourth 1.2.3.4.5
===end-group===

===start-group=== "fifth tests"
	--test-- "fifth-test-1" --assert #"e" = fifth "abcde"
	--test-- "fifth-test-2" --assert 5 = fifth [1 2 3 4 5]
===end-group===

===start-group=== "last tests"
	--test-- "last-test-1" --assert #"e" = last "abcde"
	--test-- "last-test-2" --assert 5 = last [1 2 3 4 5]
===end-group===

===start-group=== "context tests"
	--test-- "context-1" 
		context-result-1: context [a: 1 b: "2" f: func [] ["ok"]]
			--assert Object! = type? context-result-1
			--assert 1 = context-result-1/a
			--assert "2" = context-result-1/b
			--assert "ok" = context-result-1/f
===end-group===

===start-group=== "alter tests"
	--test-- "alter-test-1"
		alter-1: copy "abc"
		alter-result-1: alter alter-1 "d"
			--assert true = alter-result-1
			--assert "abcd" = alter-1
		
	--test-- "alter-test-2"
		alter-2: copy "abc"
		alter-result-2: alter alter-2 "bc"
			--assert false = alter-result-2
			--assert "ac" = alter-2

	--test-- "alter-test-3"
		alter-3: [1 2 3]
		alter-result-3: alter alter-3 [1 2]
			--assert false = alter-result-3
			--assert [2 3] = alter-3
===end-group===

===start-group=== "offset? tests"
	--test-- "offset? 1"
		offset-test-1: [1 2 3 4]
		offset-test-2: [3 4]
			--assert 0 = offset? offset-test-1 offset-test-2
	
		offset-test-3: [1 2 3 4]
		offset-test-4: [3 4]
		offset-test-3: next offset-test-3
			--assert -1 = offset? offset-test-3 offset-test-4

		offset-test-5: [1 2 3 4]
		offset-test-6: [3 4]
		offset-test-5: next offset-test-5
		offset-test-6: next next offset-test-6
			--assert 1 = offset? offset-test-5 offset-test-6
===end-group===

===start-group=== "repend tests"
	--test-- "repend test"
		repend-test-1: [1 "two" 3]
		repend repend-test-1 [(2 + 2) "five"]
			--assert [1 "two" 3 4 "five"] = repend-test-1

	--test-- "repend/only test"
		repend-only-test-1: [1 "two" 3]
		repend/only repend-only-test-1 [(2 + 2) "five"]
			--assert [1 "two" 3 [4 "five"]] = repend-only-test-1
===end-group===

===start-group=== "replace tests"
	--test-- "replace test"
		--assert [1 2 3] = replace [1 4 3] 4 2
		--assert [1 2 3] = replace [4 5 3] [4 5] [1 2]
		--assert "abc" = replace "axc" "x" "b"
		--assert "abc" = replace "xyc" "xy" "ab"
		--assert "abcx" = replace "abxx" "x" "c"
		--assert "abcc" = replace/all "abxx" "x" "c"
		--assert [1 9 [2 3 4]] = replace [1 2 [2 3 4]] 2 9
		--assert [1 9 [2 3 4]] = replace/all [1 2 [2 3 4]] 2 9
		;--assert [1 9 [9 3 4]] = replace/deep [1 2 [2 3 4]] 2 9

===end-group===

===start-group=== "math tests"
	--test-- "math test"
		--assert 0.5 = math [1 / 2.0]
		--assert 2 = math [(1 / 2.0) (2 * 1)]
		--assert 8 = math [(1 / 2) (power 2 3)]
		--assert none = math/safe [(1 / 0) (power 2 3)]
===end-group===

===start-group=== "charset tests"
	--test-- "charset test"
		--assert (make bitset! #{00000000000000000000000020}) = charset "b"
===end-group===

===start-group=== "on-parse-event tests"
	;TODO
===end-group===

===start-group=== "parse-trace tests"
	;TODO
===end-group===

===start-group=== "suffix? tests"
	--test-- "suffix? test"
		--assert %.b = suffix? "abc.b"
		--assert %.com = suffix? http://red-lang.com
		--assert %.red = suffix? %test.red
		--assert none = suffix? %test
===end-group===

===start-group=== "load tests"
	--test-- "load test"
		--assert [prin 1] = load "prin 1"
		--assert [prin 1] = load/part "prin 1 prin 2" 7
		;TODO
===end-group===

===start-group=== "save tests"
	--test-- "save test"
		save-test-1: copy ""
		save save-test-1 1
			--assert "#{31}" = save-test-1
	--test-- "save test 2"
		save-test-2: copy ""
		save save-test-2 "abc"
			--assert "#{2261626322}" = save-test-2
	--test-- "save test 3"
		save-test-3: copy ""
		save/as save-test-3 "abc" none
			--assert "#{2261626322}" = save-test-3
		;TODO
===end-group===

===start-group=== "cause-error tests"
	--test-- "cause-error test"
		cause-error-func-1: function [] [cause-error 'math 'zero-divide []]
		cause-error-result-1: try [cause-error-func-1]
			--assert error? cause-error-result-1
===end-group===

===start-group=== "pad tests"
	--test-- "pad test"
		--assert "a" = pad "a" 1
		--assert "a " = pad "a" 2
		--assert "a" = pad "a" -2
		--assert " a" = pad/left "a" 2
		--assert "ax" = pad/with "a" 2 #"x"
===end-group===

===start-group=== "mod tests"
	--test-- "mod test"
		--assert 1 = mod 3 2
		--assert 2 = mod 2 3
		--assert 0 = mod 2 2
		--assert -5 = mod -2 -3
		--assert #"^W" = mod #"x" #"a"
===end-group===

===start-group=== "modulo tests"
	--test-- "modulo test"
		--assert 1 = modulo 3 2
		--assert 2 = modulo 2 3
		--assert 0 = modulo 2 2
		--assert 1 = modulo -2 -3
		--assert #"^W" = modulo #"x" #"a"
===end-group===

===start-group=== "to-red-file tests"
	--test-- "to-red-file test"
		to-red-file-test-1: to-red-file %functions-test.red
		--assert %functions-test.red = to-red-file-test-1
===end-group===

===start-group=== "dir? tests"
	--test-- "dir? test"
		--assert false = dir? %abc
		--assert true = dir? %abc/
		--assert true = dir? http://red-lang.com/
		--assert false = dir? http://red-lang.com
===end-group===

===start-group=== "normalize-dir tests"
	--test-- "normalize-dir test"
		--assert not none? find (normalize-dir %a) "/a/"
===end-group===

===start-group=== "what-dir tests"
	--test-- "what-dir test"
		--assert not none? what-dir
===end-group===

===start-group=== "change-dir tests"
	--test-- "change-dir test"
		--assert what-dir = (change-dir %.)
		--assert error? try [change-dir %a]
===end-group===

===start-group=== "list-dir tests"
	--test-- "list-dir test"
	;TODO
===end-group===

===start-group=== "make-dir tests"
	--test-- "make-dir test"
	;TODO
===end-group===

===start-group=== "extract tests"
	--test-- "extract test"
		--assert "ace" = extract "abcde" 2
		--assert "abcde" = extract "abcde" 1
		--assert "ad" = extract "abcde" 3
		--assert "be" = extract/index "abcde" 3 2
	--test-- "extract/into test"
		extract-into-test-1: copy ""
		extract/index/into "abcde" 3 2 extract-into-test-1
			--assert "be" = extract-into-test-1
===end-group===

===start-group=== "extract-boot-args tests"
	--test-- "extract-boot-args test"
		;TODO
===end-group===

===start-group=== "collect tests"
	--test-- "collect test"
		--assert [] = collect [4 3 * 3 (3 * 10) (5 * 100)]
		--assert [4 30] = collect [keep 4 3 * 3 keep (3 * 10) (5 * 100)]
	--test-- "collect/into test"
		collect-into-test-1: [1 2]
		collect/into [keep 4 3 * 3 keep (3 * 10) (5 * 100)] collect-into-test-1
			--assert [1 2 4 30] = collect-into-test-1
===end-group===

===start-group=== "flip-exe-flag tests"
	--test-- "flip-exe-flag test"
		;TODO
===end-group===

===start-group=== "split tests"
	--test-- "split test"
		--assert ["a" "b" "c"] = split "a-b-c" "-"
		--assert ["a" "c"] = split "a-b-c" "-b-"
		--assert ["a-b-c"] = split "a-b-c" "x"
===end-group===

===start-group=== "dirize tests"
	--test-- "dirize test"
		--assert http://red-lang.com/ = dirize http://red-lang.com
		--assert %a/ = dirize %a
		--assert "a/" = dirize "a"
===end-group===

===start-group=== "clean-path tests"
	--test-- "clean-path test"
		--assert %/red-lang.com = clean-path http://red-lang.com
		--assert (rejoin [what-dir %a]) = clean-path %a
		--assert %"" = clean-path/only %a
		--assert %/red-lang.com/ = clean-path/only/dir http://red-lang.com
===end-group===

===start-group=== "split-path tests"
	--test-- "split-path test"
		--assert [%./ %a] = split-path %a
		--assert [http:// %red-lang.com] = split-path http://red-lang.com
===end-group===

===start-group=== "do-file tests"
	--test-- "do-file test"
	;TODO
===end-group===

===start-group=== "path-thru tests"
	--test-- "path-thru test"
		--assert not none? find (path-thru http://red-lang.com) "/cache/red-lang.com"
===end-group===

===start-group=== "exists-thru? tests"
	--test-- "exists-thru? test"
		--assert not exists-thru? http://red-lang.com
===end-group===

===start-group=== "read-thru tests"
	--test-- "read-thru test"
	;TODO
===end-group===

===start-group=== "load-thru tests"
	--test-- "load-thru test"
	;TODO
===end-group===

===start-group=== "do-thru tests"
	--test-- "do-thru test"
	;TODO
===end-group===

===start-group=== "cos tests"
	--test-- "cos test"
		--assertf~= cos 1.0 0.540302 0.0001 
===end-group===

===start-group=== "sin tests"
	--test-- "sin test"
		--assertf~= sin 1.0 0.8414709 0.0001
===end-group===

===start-group=== "tan tests"
	--test-- "tan test"
		--assertf~= tan 1.0 1.55740772 0.0001
===end-group===

===start-group=== "acos tests"
	--test-- "acos test"
		--assertf~= acos 0.1 1.470628 0.0001
===end-group===

===start-group=== "asin tests"
	--test-- "asin test"
		--assertf~= asin 1.0 1.5707963 0.0001
===end-group===

===start-group=== "atan tests"
	--test-- "atan test"
		--assertf~= atan 1.0 0.7853981 0.0001
===end-group===

===start-group=== "atan tests"
	--test-- "atan test"
		--assertf~= atan 1.0 0.7853981 0.0001
===end-group===

===start-group=== "atan2 tests"
	--test-- "atan2 test"
		--assertf~= (atan2 10 1) 1.4711276 0.0001
===end-group===

===start-group=== "sqrt tests"
	--test-- "sqrt test"
		--assertf~= (sqrt 2) 1.41421356 0.0001
		--assert 2.0 = sqrt 4
===end-group===

===start-group=== "sqrt tests"
	--test-- "sqrt test"
		--assert "24" = rejoin [1 + 1 2 * 2]
===end-group===

~~~end-file~~~
