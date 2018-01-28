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
	--test-- "load-45"	--assert 2147483648.0	== load "2147483648"
	--test-- "load-46"	--assert -2147483649.0	== load "-2147483649"

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
		
	--test-- "load-map-2"
		lm2-blk: load "m: make map! [a: 1 b: 2]"
		--assert 4 == length? lm2-blk
		--assert strict-equal? first [m:] first lm2-blk
		--assert 'make == second lm2-blk
		--assert 'map! == third lm2-blk
		--assert 4 == length? fourth lm2-blk
		--assert 1 == select fourth lm2-blk first [a:]
		--assert 2 == select fourth lm2-blk first [b:]

===end-group===

===start-group=== "load object tests"

	--test-- "load-object-1"
		lo1-blk: load {
			o: make object! [
				a: 1
				b: 1.0
				c: #"1"
				d: "one"
				e: #(a: 1 b: 2)
				f: func [][1]
			]
		}
		--assert block! = type? lo1-blk
		--assert 4 = length? lo1-blk
		--assert strict-equal?
			first [o:]
			first lo1-blk
		--assert 'make == second lo1-blk
		--assert 'object! == third lo1-blk
		--assert 14 == length? fourth lo1-blk
		--assert strict-equal?
			first [a:]
			first fourth lo1-blk
		--assert 1 == second fourth lo1-blk
		--assert strict-equal?
			first [b:]
			third fourth lo1-blk
		--assert 1.0 == fourth fourth lo1-blk
		--assert strict-equal?
			first [c:]
			fifth fourth lo1-blk
		--assert #"1" == pick fourth lo1-blk 6
		--assert strict-equal?
			first [d:]
			pick fourth lo1-blk 7
		--assert "one" == pick fourth lo1-blk 8
		--assert strict-equal?
			first [e:]
			pick fourth lo1-blk 9
		--assert map! == type? pick fourth lo1-blk 10
		--assert 1 == select pick fourth lo1-blk 10 'a
		--assert 2 == select pick fourth lo1-blk 10 'b
		--assert strict-equal?
			first [f:]
			pick fourth lo1-blk 11
		--assert 'func == pick fourth lo1-blk 12
		--assert [] == pick fourth lo1-blk 13
		--assert [1] == pick fourth lo1-blk 14
		
	--test-- "load-object-2"
		lo2-blk: load {
			o: make object! [
				oo: make object! [
					ooo: make object! [
						a: 1
					]
				]
			]
		}
		--assert 4 == length? lo2-blk
		--assert 4 == length? fourth lo2-blk
		--assert 4 == length? fourth fourth lo2-blk
		--assert 2 == length? fourth fourth fourth lo2-blk
		--assert strict-equal?
			first [o:]
			first lo2-blk
		--assert 'make == second lo2-blk
		--assert 'object! == third lo2-blk
		--assert strict-equal?
			first [oo:]
			first fourth lo2-blk
		--assert 'make == second fourth lo2-blk
		--assert 'object! == third fourth lo2-blk
		--assert strict-equal?
			first [ooo:]
			first fourth fourth lo2-blk
		--assert 'make == second fourth fourth lo2-blk
		--assert 'object! == third fourth fourth lo2-blk
		--assert strict-equal?
			first [a:]
			first fourth fourth fourth lo2-blk
		--assert 1 == second fourth fourth fourth lo2-blk

===end-group===

===start-group=== "load next tests"

	--test-- "load-next-1"
		s: "123 []hello"
		--assert 123 	== load/next s 's
		--assert [] 	== load/next s 's
		--assert 'hello == load/next s 's
		--assert [] 	== load/next s 's
		--assert [] 	== load/next s 's
		--assert (head s) == "123 []hello"

	--test-- "load-next-2"
		s: "{}()[]"
		--assert "" 			 == load/next s 's
		--assert (make paren! 0) == load/next s 's
		--assert [] 			 == load/next s 's

	--test-- "load-next-3"
		s: "^-{}^/(^/)^M[^-]"
		--assert "" 			 == load/next s 's
		--assert (make paren! 0) == load/next s 's
		--assert [] 			 == load/next s 's

~~~end-file~~~
