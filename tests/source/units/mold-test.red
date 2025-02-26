Red [
	Title:   "Red mold test script"
	Author:  "bitbegin"
	File: 	 %mold-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "mold"

===start-group=== "string-basic"

	--test-- "mold-string-basic-1"
		a: ""				;-- literal: ""
		b: {""}
		--assert b = mold a

	--test-- "mold-string-basic-2"
		a: {}				;-- literal: ""
		b: {""}
		--assert b = mold a

	--test-- "mold-string-basic-3"
		a: "{}"				;-- literal: "{}"
		b: {"{}"}
		--assert b = mold a

	--test-- "mold-string-basic-4"
		a: {""}				;-- literal: {""}
		b: {{""}}
		--assert b = mold a

	--test-- "mold-string-basic-5"
		a: "{"				;-- literal: "{"
		b: {"^{"}
		--assert b = mold a

	--test-- "mold-string-basic-6"
		a: "}"				;-- literal: "}"
		b: {"^}"}
		--assert b = mold a

	--test-- "mold-string-basic-7"
		a: {"}				;-- literal: {"}
		b: {{"}}
		--assert b = mold a

	--test-- "mold-string-basic-8"
		a: {""}				;-- literal: {""}
		b: {{""}}
		--assert b = mold a

	--test-- "mold-string-basic-9"
		a: "}{"				;-- literal: "}{"
		b: {"^}^{"}
		--assert b = mold a

	--test-- "mold-string-basic-10"
		a: "^""				;-- literal: {"}
		b: {{"}}
		--assert b = mold a

	--test-- "mold-string-basic-11"
		a: "^"{"			;-- literal: {"^{}
		b: {^{"^^^{^}}
		--assert b = mold a

	--test-- "mold-string-basic-12"
		a: "^"{}"			;-- literal: {"{}}
		b: {{"{}}}
		--assert b = mold a

	--test-- "mold-string-basic-13"
		a: "^"}{"			;-- literal: {"^}^{}
		b: {{"^^}^^{}}
		--assert b = mold a

	--test-- "mold-string-basic-14"
		a: {^{}				;-- literal: "{"
		b: {"^{"}
		--assert b = mold a

	--test-- "mold-string-basic-15"
		a: {^{"}			;-- literal: {^{"}
		b: {^{^^^{"^}}
		--assert b = mold a

	--test-- "mold-string-basic-16"
		a: "{{{"			;-- literal: "{{{"
		b: {"^{^{^{"}
		--assert b = mold a

	--test-- "mold-string-basic-17"
		a: "}}}"			;-- literal: "}}}"
		b: {"^}^}^}"}
		--assert b = mold a

	--test-- "mold-string-basic-18"
		a: "{{{}}}}"		;-- literal: "{{{}}}}"
		b: {"{{{}}}^}"}
		--assert b = mold a

	--test-- "mold-string-basic-19"
		a: "}{}"			;-- literal: "}{}"
		b: {"^}{}"}
		--assert b = mold a

	--test-- "mold-string-basic-20"
		a: "}{{}"			;-- literal: "}{{}"
		b: {"^}^{^{^}"}
		--assert b = mold a

	--test-- "mold-string-basic-21"
		a: "}{{}}"			;-- literal: "}{{}}"
		b: {"^}{{}}"}
		--assert b = mold a

	--test-- "mold-string-basic-22"
		a: "{}{"			;-- literal: "{}{"
		b: {"{}^{"}
		--assert b = mold a

	--test-- "mold-string-basic-23"
		a: "{}{}{"			;-- literal: "{}{"
		b: {"{}{}^{"}
		--assert b = mold a

===end-group=== 

===start-group=== "string"
	
	--test-- "mold-string-1"
		a: "abc"			;-- literal: "abc"
		b: {"abc"}
		--assert b = mold a

	--test-- "mold-string-2"
		a: "a^"bc"			;-- literal: {a"bc}
		b: {{a"bc}}
		--assert b = mold a

	--test-- "mold-string-3"
		a: "a{bc"			;-- literal: "a{bc"
		b: {"a^{bc"}
		--assert b = mold a

	--test-- "mold-string-4"
		a: "a}{bc"			;-- literal: "a}{bc"
		b: {"a^}^{bc"}
		--assert b = mold a

	--test-- "mold-string-5"
		a: "a}{bc"			;-- literal: "a}{bc"
		b: {{"a^^}^^{bc"}}
		--assert b = mold mold a

	--test-- "mold-string-6"
		a: "a^"b^"c"		;-- literal: {a"b"c}
		b: {{a"b"c}}
		--assert b = mold a

	--test-- "mold-string-7"
		a: "a{}bc"			;-- literal: "a{}bc"
		b: {"a{}bc"}
		--assert b = mold a

===end-group===

===start-group=== "mold-hash"
	
	--test-- "mold-hash-1"
		append/only h: make hash! [] h
		--assert "make hash! [make hash! [...]]" = mold h

===end-group===

===start-group=== "mold-object"

	--test-- "mold-object-1"
		--assert 20 = length? mold/part/flat system 20

===end-group===

===start-group=== "ref"
	
	--test-- "mold-ref-1"
		--assert "@abc" = mold @abc
		--assert "@DEF" = mold @DEF

	--test-- "mold-ref-2"
		--assert "" = mold/part @abc 0
		--assert "@" = mold/part @abc 1
		--assert "@abc" = mold/part @abc 100

===end-group===

===start-group=== "mold-all"
	
	--test-- "mold-true" --assert "true" = mold true

	--test-- "mold-all-true" --assert "#(true)" = mold/all true

	--test-- "mold-false" --assert "false" = mold false

	--test-- "mold-all-false" --assert "#(false)" = mold/all false

	--test-- "mold-none" --assert "none" = mold none

	--test-- "mold-all-none" --assert "#(none)" = mold/all none

	--test-- "mold-block" --assert "[true false none]" = mold [#(true) #(false) #(none)]

	--test-- "mold-all-block"
		--assert "[#(true) #(false) #(none)]" = mold/all [#(true) #(false) #(none)]

===end-group=== 

===start-group=== "mold-only"

	--test-- "mo-map"	--assert {a: 2^/b: 3^/c: 4} == mold/only #[a: 2 b: 3 c: 4]
	--test-- "mo-obj"	--assert {a: 2^/b: 3^/c: 4} == mold/only object [a: 2 b: 3 c: 4]
	--test-- "mo-vec"	--assert "1 2 3 4" == mold/only make vector! [1 2 3 4]
	--test-- "mo-hash"	--assert "1 2 3 4" == mold/only make hash! [1 2 3 4]
	--test-- "mo-paren"	--assert "1 2 3 4" == mold/only to-paren [1 2 3 4]
	--test-- "mo-image"	--assert "2x2 #{112233FFFFFFFFFFFFFFFFFF}" == mold/only make image! [2x2 #{11223344}]
	--test-- "mo-bin"	--assert "1122334455" == mold/only #{1122334455}
	--test-- "mo-type"	--assert "integer! float! percent!" == mold/only number!
	
	--test-- "mo-err"
		s-mo-err: mold/only try [1 / 0]
		remove/part pos: find/tail s-mo-err "stack: " find pos lf
		remove/part pos: find/tail s-mo-err "near: " find pos #"w"	
		--assert s-mo-err == {code: 400^/type: 'math^/id: 'zero-divide^/arg1: none^/arg2: none^/arg3: none^/near: where: '/^/stack: ^/files: none}

===end-group===

~~~end-file~~~
