Red [
	Title:   "Red loading test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %load-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "load"

===start-group=== "Delimiter LOAD tests"

	--test-- "load-1"  --assert "" 		 = load {""}
	--test-- "load-2"  --assert "" 		 = load {{}}
	--test-- "load-3"  --assert "{" 	 = load {"^{"}
	--test-- "load-4"  --assert "}" 	 = load {"^}"}
	--test-- "load-5"  --assert "{}"	 = load {"^{^}"}
	--test-- "load-6"  --assert {^}^{} 	 = load {"^}^{"}
	--test-- "load-7"  --assert "^{^}^}" = load {"^{^}^}"}
	--test-- "load-8"  --assert ""		 = load {"^"}
	--test-- "load-9"  --assert ""		 = load "{}"
	--test-- "load-10" --assert "{"		 = load "{^^{}"
	--test-- "load-11" --assert {"}		 = load {{"}}
	--test-- "load-12" --assert "^/" 	 = load "{^/}^/"
	--test-- "load-13" --assert "^/" 	 = load "{^/}"
	--test-- "load-14" --assert "{^/}"	 = load {{{^/}}}
	--test-- "load-15" --assert {{"x"}}	 = load {{{"x"}}}
	--test-- "load-16" --assert "{x}"	 = load {{{x}}}
	--test-- "load-17" --assert {"x"}	 = load {{"x"}}
	--test-- "load-18" --assert "x"		 = load {{x}}
	
===end-group===

===start-group=== "LOAD /part tests"
	src: "123abc789"

	--test-- "load-p1" --assert 123  = load/part src 3
	--test-- "load-p2" --assert 12   = load/part src 2
	--test-- "load-p3" --assert 1    = load/part src 1
	--test-- "load-p4" --assert []   = load/part src 0
	--test-- "load-p4" --assert 'abc = load/part skip src 3 3

===end-group===
 
===start-group=== "LOAD floats test"

	--test-- "load-30"	--assert "123.0"		= mold load "123.0"
	--test-- "load-31"	--assert "1.123"		= mold load "1.123"
	--test-- "load-32"	--assert "0.123"		= mold load ".123"
	--test-- "load-33"	--assert "100.0"		= mold load "1E2"
	--test-- "load-34"	--assert "1200.0"		= mold load "1.2E3"
	--test-- "load-35"	--assert "10.0"			= mold load ".1E2"
	--test-- "load-36"	--assert "12.3"			= mold load ".123E2"
	--test-- "load-37"	--assert "-0.3"			= mold load "-.3"
	--test-- "load-38"	--assert "1.#NaN"		= mold load "1.#nan"
	--test-- "load-39"	--assert "1.#INF"		= mold load "1.#INF"
	--test-- "load-40"	--assert "-1.#INF"		= mold load "-1.#Inf"
	--test-- "load-41"	--assert "1.0e23"		= mold load "0.99999999999999999999999999999999999999999e+23"
	--test-- "load-42"	--assert "-9.3e-9"		= mold load "-93E-10"
	--test-- "load-43"	--assert "0.0"			= mold load "2183167012312112312312.23538020374420446192e-370"
	--test-- "load-44"	--assert 1.3			== load "1,3"
	;--test-- "load-45"	--assert 2147483648.0	== load "2147483648"
	;--test-- "load-46"	--assert -2147483649.0	== load "-2147483649"

===end-group===

===start-group=== "Load integer tests"

	--test-- "load-int-1"	--assert 0 == load "0"
	--test-- "load-int-2"	--assert 2147483647 == load "2147483647"
	--test-- "load-int-3"	--assert -2147483648 == load "-2147483648"
	--test-- "load-int-4"	--assert error? try [load "1a3"]
	--test-- "load-int-5"	--assert 1 == load "1"
	--test-- "load-int-6"	--assert 1 == load "+1"
	--test-- "load-int-7"	--assert -1 == load "-1"
	--test-- "load-int-8"	--assert 0 == load "+0"
	--test-- "load-int-9"	--assert 0 == load "-0"
	--test-- "load-int-10"	--assert 1 == load "01h"
	--test-- "load-int-11"	--assert 2147483647 == load "7FFFFFFFh"
	--test-- "load-int-12"	--assert -1 == load "FFFFFFFFh"
	
===end-group===

===start-group=== "load word tests"

	--test-- "load-word-1"	--assert 'w == load "w"
	--test-- "load-word-2"	--assert '? == load "?"
	--test-- "load-word-3"	--assert '! == load "!"
	--test-- "load-word-4"	--assert '. == load "."
	--test-- "load-word-5"	--assert 'a' == load "a'"  	
	--test-- "load-word-6"	--assert '+ == load "+"
	--test-- "load-word-7"	--assert '- == load "-"
	--test-- "load-word-8"	--assert '* == load "*"
	--test-- "load-word-9"	--assert '& == load "&"
	--test-- "load-word-10"	--assert '| == load "|"
	--test-- "load-word-11"	--assert '= == load "="
	--test-- "load-word-12"	--assert '_ == load "_"
	--test-- "load-word-13" --assert '~ == load "~"
	--test-- "load-word-14" --assert 'a == load "a;b"
	--test-- "load-word-15"	--assert 'a/b == load "a/b"
	--test-- "load-word-16" --assert strict-equal? first [a:] load "a:"
	--test-- "load-word-17"	--assert strict-equal? first [:a] load ":a"
	--test-- "load-word-18"	--assert strict-equal? first ['a] load "'a"
	--test-- "load-word-19" --assert strict-equal? first [œ∑´®†] load "œ∑´®†"
	

===end-group===

===start-group=== "load code tests"
	--test-- "load-code-1"	--assert [a ()] == load "a()"
	--test-- "load-code-2"	--assert [a []] == load "a[]"
	--test-- "load-code-3"	--assert [a {}] == load "a{}"
	--test-- "load-code-4"	--assert [a ""] == load {a""}
===end-group=== 

===start-group=== "load map tests"

	--test-- "load-map-1"
		lm1-blk: load "m: #(a: 1 b: 2)"
		--assert 2 == length? lm1-blk
		--assert strict-equal? first [m:] first lm1-blk
		--assert map! = type? second lm1-blk
		--assert 2 == length? second lm1-blk
		--assert 1 == select second lm1-blk first [a:]
		--assert 2 == select second lm1-blk first [b:]

===end-group===

~~~end-file~~~
