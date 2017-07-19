Red [
	Title:   "Red type? test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %type-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "type?"

===start-group=== "unevaluated literals"
	--test-- "type?ul-1"			--assert integer! = type? first [1]
	--test-- "type?ul-2"			--assert char! = type? first [#"a"]
	--test-- "type?ul-3"			--assert block! = type? first [[]]
	--test-- "type?ul-4"			--assert get-word! = type? first [:b]
	--test-- "type?ul-5"			--assert logic! = type? first [#[true]]
	--test-- "type?ul-6"			--assert issue! = type? first [#1]
	--test-- "type?ul-7"			--assert none! = type? first [#[none]]
	--test-- "type?ul-8"			--assert paren! = type? first [(1)]
	--test-- "type?ul-9"			--assert set-word! = type? first [b:]
	--test-- "type?ul-10"			--assert string! = type? first ["1234566789"]
	--test-- "type?ul-11"			--assert unset! = type? ()
	--test-- "type?ul-12"			--assert word! = type? first [a]
	--test-- "type?ul-13"			--assert lit-word! = type? first ['a]
===end-group===

===start-group=== "word value"
	--test-- "type?wv-1"
		value: 1
		--assert integer! = type? value
	--test-- "type?wv-2"
		value: #"a"
		--assert char! = type? value
	--test-- "type?wv-3"
		value: [a b c d]
		--assert block! = type? value
	--test-- "type?wv-4"
		value: true
		--assert logic! = type? value
	--test-- "type?wv-5"
		value: #123456789
		--assert issue! = type? value
	--test-- "type?wv-6"
		value: none
		--assert none! = type? value
	--test-- "type?wv-7"
		value: first [("a b c d")]
		--assert paren! = type? value
	--test-- "type?wv-8"
		value: first [a:]
		--assert set-word! = type? value
	--test-- "type?wv-9"
		value: "Hello Nenad"
		--assert string! = type? value
	--test-- "type?wv-10"
		set/any 'value ()
		--assert unset! = type? get/any 'value
	--test-- "type?wv-11"
		value: 'a
		--assert word! = type? value
	--test-- "type?wv-12"
		value: first ['a]
		--assert lit-word! = type? value
===end-group===

===start-group=== "get word value"
	--test-- "type?gwv-1"
		value: 1
		--assert integer! = type? :value
	--test-- "type?gwv-2"
		value: #"a"
		--assert char! = type? :value
	--test-- "type?gwv-3"
		value: [a b c d]
		--assert block! = type? :value
	--test-- "type?gwv-4"
		value: first [:g]
		--assert get-word! = type? :value
	--test-- "type?gwv-5"
		value: true
		--assert logic! = type? :value
	--test-- "type?gwv-6"
		value: #123456789
		--assert issue! = type? :value
	--test-- "type?gwv-7"
		value: none
		--assert none! = type? :value
	--test-- "type?gwv-8"
		value: first [("abcd")]
		--assert paren! = type? :value
	--test-- "type?gwv-9"
		value: first [a: ]
		--assert set-word! = type? :value
	--test-- "type?gwv-10"
		value: "Hello Nenad"
		--assert string! = type? :value
	--test-- "type?gwv-11"
	  set/any 'value ()
		--assert unset! = type? :value
	--test-- "type?gwv-12"
		value: 'a
		--assert word! = type? :value
	--test-- "type?gwv-13"
		value: first ['a]
		--assert lit-word! = type? :value
===end-group===

===start-group=== "scalar?"
	--test-- "scalar? char!"
	--assert scalar? #"A"
	--test-- "not scalar? string!"
	--assert not scalar? ""
===end-group===

===start-group=== "immediate?"
    --test-- "immediate? none!" 		    --assert immediate? none
    --test-- "not immediate? map!"			--assert not immediate? #()
===end-group===

~~~end-file~~~