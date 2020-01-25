Red [
	Title:   "Red lexer test script"
	Author:  "Nenad Rakocevic"
	File: 	 %lexer-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "lexer"

===start-group=== "transcode/next"

	--test-- "tn-1"
		--assert [123 " []hello"] == transcode/next "123 []hello"
		--assert [[] "hello"]     == transcode/next " []hello"
		--assert [hello ""]       == transcode/next "hello"

	--test-- "tn-2"
		--assert [[a] " 123"] == transcode/next "[a] 123"


===end-group===


===start-group=== "transcode/trace"

	logs: make block! 100

	lex-logger: function [
	  event  [word!]
	  input  [string! binary!]
	  type   [datatype! word! none!]
	  line   [integer!]
	  token
	  return:  [logic!]
	][
		t: tail logs
		reduce/into [event to-word type to-word type? type line token] tail logs
		new-line t yes
		any [event <> 'error all [input: next input false]]
	]

	--test-- "tt-1"
		clear logs
		--assert (compose [a: 1 (to-path 'b) []]) == transcode/trace "a: 1 b/ []" :lex-logger
		--assert logs = [
		    scan  set-word! word!     1 1x3
		    load  set-word! datatype! 1 a:
		    scan  integer!  word!     1 4x5
		    load  integer!  datatype! 1 1
		    open  path!     datatype! 1 6x6
		    load  word!     datatype! 1 b
		    close path!     datatype! 1 8x8
		    error error!    datatype! 1 8x8
		    open  block!    datatype! 1 9x9
		    close block!    datatype! 1 10x10
		]

	--test-- "tt-2"
		clear logs
		--assert (compose [a: 1 (to-path 'b) x]) == transcode/trace "a: 1 b/ x" :lex-logger
		--assert logs = [
		    scan  set-word! word!     1 1x3
		    load  set-word! datatype! 1 a:
		    scan  integer!  word!     1 4x5
		    load  integer!  datatype! 1 1
		    open  path!     datatype! 1 6x6
		    load  word!     datatype! 1 b
		    close path!     datatype! 1 8x8
		    error error!    datatype! 1 8x8
		    scan  word!     word!     1 9x10
		    load  word!     datatype! 1 x
		]

	--test-- "tt-3"
		clear logs
		--assert none == transcode/trace "a: 1 #(r: 2) [ x" :lex-logger
		--assert logs = [
		    scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    open map! datatype! 1 7x7
		    scan set-word! word! 1 8x10
		    load set-word! datatype! 1 r:
		    scan integer! word! 1 11x12
		    load integer! datatype! 1 2
		    close map! datatype! 1 12x12
		    open block! datatype! 1 14x14
		    scan word! word! 1 16x17
		    load word! datatype! 1 x
		    error error! datatype! 1 14x17
		]

	--test-- "tt-4"
		clear logs
		--assert [a: 1 x] == transcode/trace "a: 1 ) x" :lex-logger
		--assert logs = [
		    scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    close paren! datatype! 1 6x6
		    error error! datatype! 1 6x6
		    scan word! word! 1 8x9
		    load word! datatype! 1 x
		]

	--test-- "tt-5"
		clear logs
		--assert [hello 3.14 pi world] == transcode/trace "hello ^/\ 3.14 pi world" :lex-logger
		--assert logs = [
		    scan word! word! 1 1x6
		    load word! datatype! 1 hello
		    error error! datatype! 2 8x8
		    scan float! word! 2 10x14
		    load float! datatype! 2 3.14
		    scan word! word! 2 15x17
		    load word! datatype! 2 pi
		    scan word! word! 2 18x23
		    load word! datatype! 2 world
		]

	--test-- "tt-6"
		clear logs
		--assert [123 "abc" 123456789123.0 test] == transcode/trace "123 {abc} 123456789123 test" :lex-logger
		--assert logs = [
		    scan integer! word! 1 1x4
		    load integer! datatype! 1 123
		    open string! datatype! 1 5x5
		    close string! datatype! 1 6x9
		    scan float! word! 1 11x23
		    load float! datatype! 1 123456789123.0
		    scan word! word! 1 24x28
		    load word! datatype! 1 test
		]

	--test-- "tt-7"
		clear logs
		--assert [a: 1] == transcode/trace "a: 1 ]" :lex-logger
		--assert logs = [
			scan set-word! word! 1 1x3
		    load set-word! datatype! 1 a:
		    scan integer! word! 1 4x5
		    load integer! datatype! 1 1
		    close block! datatype! 1 6x6
		    error error! datatype! 1 6x6
		]

	--test-- "tt-8"	
		lex-filter: function [
			event  [word!]
			input  [string! binary!]
			type   [datatype! word! none!]
			line   [integer!]
			token
			return:  [logic!]
		][
			t: tail logs
			reduce/into [event to-word type to-word type? type line token] tail logs
			new-line t yes
			switch event [
				scan  [yes]
				load  [to-logic find [integer! float! pair!] type]
				open  [no]
				close [no]
			]
		]

		clear logs
		--assert [hello "test" pi world] = transcode/trace "hello ^/123 ^/[^/3x4 {test} 3.14 pi]^/ world" :lex-filter
		--assert logs = [
		    scan word! word! 1 1x6
		    load word! datatype! 1 hello
		    scan integer! word! 2 8x11
		    load integer! datatype! 2 123
		    open block! datatype! 3 13x13
		    scan pair! word! 4 15x18
		    load pair! datatype! 4 3x4
		    open string! datatype! 4 19x19
		    close string! datatype! 4 20x24
		    scan float! word! 4 26x30
		    load float! datatype! 4 3.14
		    scan word! word! 4 31x33
		    load word! datatype! 4 pi
		    close block! datatype! 4 33x33
		    scan word! word! 5 36x41
		    load word! datatype! 5 world
		]


===end-group===

~~~end-file~~~