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

	--test-- "mold-string-baseic-1"
		a: ""				;-- literal: ""
		b: {""}
		--assert b = mold a

	--test-- "mold-string-baseic-2"
		a: {}				;-- literal: ""
		b: {""}
		--assert b = mold a

	--test-- "mold-string-baseic-3"
		a: "{}"				;-- literal: "{}"
		b: {"{}"}
		--assert b = mold a

	--test-- "mold-string-baseic-4"
		a: {""}				;-- literal: {""}
		b: {{""}}
		--assert b = mold a

	--test-- "mold-string-baseic-5"
		a: "{"				;-- literal: "{"
		b: {"^{"}
		--assert b = mold a

	--test-- "mold-string-baseic-6"
		a: "}"				;-- literal: "}"
		b: {"^}"}
		--assert b = mold a

	--test-- "mold-string-baseic-7"
		a: {"}				;-- literal: {"}
		b: {{"}}
		--assert b = mold a

	--test-- "mold-string-baseic-8"
		a: {""}				;-- literal: {""}
		b: {{""}}
		--assert b = mold a

	--test-- "mold-string-baseic-9"
		a: "}{"				;-- literal: "}{"
		b: {"^}^{"}
		--assert b = mold a

	--test-- "mold-string-baseic-10"
		a: "^""				;-- literal: {"}
		b: {{"}}
		--assert b = mold a

	--test-- "mold-string-baseic-11"
		a: "^"{"			;-- literal: {"^{}
		b: {^{"^^^{^}}
		--assert b = mold a

	--test-- "mold-string-baseic-12"
		a: "^"{}"			;-- literal: {"{}}
		b: {{"{}}}
		--assert b = mold a

	--test-- "mold-string-baseic-13"
		a: "^"}{"			;-- literal: {"^}^{}
		b: {{"^^}^^{}}
		--assert b = mold a

	--test-- "mold-string-baseic-14"
		a: {^{}				;-- literal: "{"
		b: {"^{"}
		--assert b = mold a

	--test-- "mold-string-baseic-15"
		a: {^{"}			;-- literal: {^{"}
		b: {^{^^^{"^}}
		--assert b = mold a

	--test-- "mold-string-baseic-16"
		a: "{{{"			;-- literal: "{{{"
		b: {"^{^{^{"}
		--assert b = mold a

	--test-- "mold-string-baseic-17"
		a: "}}}"			;-- literal: "}}}"
		b: {"^}^}^}"}
		--assert b = mold a

	--test-- "mold-string-baseic-18"
		a: "{{{}}}}"		;-- literal: "{{{}}}}"
		b: {"{{{}}}^}"}
		--assert b = mold a

	--test-- "mold-string-baseic-19"
		a: "}{}"			;-- literal: "}{}"
		b: {"^}{}"}
		--assert b = mold a

	--test-- "mold-string-baseic-20"
		a: "}{{}"			;-- literal: "}{{}"
		b: {"^}^{^{^}"}
		--assert b = mold a

	--test-- "mold-string-baseic-21"
		a: "}{{}}"			;-- literal: "}{{}}"
		b: {"^}{{}}"}
		--assert b = mold a

	--test-- "mold-string-baseic-22"
		a: "{}{"			;-- literal: "{}{"
		b: {"{}^{"}
		--assert b = mold a

	--test-- "mold-string-baseic-23"
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


~~~end-file~~~