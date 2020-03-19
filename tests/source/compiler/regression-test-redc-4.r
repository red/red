REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc-4.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 4"

===start-group=== "Red regressions #1501 - #2000"

	; help functions for crash and compiler-problem detection
	true?: func [value] [not not value]
	crashed?: does [true? find qt/output "*** Runtime Error"]
	compiled?: does [true? not find qt/comp-output "Error"]
	script-error?: does [true? find qt/output "Script Error"]
	compiler-error?: does [true? find qt/comp-output "*** Compiler Internal Error"]
	compilation-error?: does [true? find qt/comp-output "*** Compilation Error"]
	loading-error: func [value] [found? find qt/comp-output join "*** Loading Error: " value]
	compilation-error: func [value] [found? find qt/comp-output join "*** Compilation Error: " value]
	syntax-error: func [value] [found? find qt/comp-output join "*** Syntax Error: " value]
	script-error: func [value] [found? find qt/comp-output join "*** Script Error: " value]
	; -test-: :--test--
	; --test--: func [value] [probe value -test- value]

	--test-- "#1524"
		--compile-and-run-this-red {parse [x][keep 1]}
		--assert not crashed?

	--test-- "#1589"
		--compile-and-run-this-red {power -1 0.5}
		--assert not crashed?

	--test-- "#1598"
		--compile-and-run-this-red {3x4 // 1.1}
		--assert not crashed?

	--test-- "#1679"
		--compile-and-run-this-red {probe switch 1 []}
		--assert equal? qt/output "none^/"

	--test-- "#1694"
		--compile-and-run-this-red {
do  [
	f: func [x] [x]
	probe try [f/only 3]
]
		}
		--assert true? find qt/output "arg2: 'only"

	--test-- "#1698"
		--compile-and-run-this-red {
	h: make hash! []
	loop 10 [insert tail h 1]
}
		--assert not crashed?

	--test-- "#1700"
		--compile-and-run-this-red {change-dir %../}
		--assert not crashed?

	--test-- "#1702"
		--compile-and-run-this-red {
offset?: func [
	series1
	series2
] [
	(index? series2) - (index? series1)
]
cmp: context [
	shift-window: func [look-ahead-buffer positions][
		set look-ahead-buffer skip get look-ahead-buffer positions              
	]
	match-length: func [a b /local start][
		start: a
		while [all [a/1 = b/1 not tail? a]][a: next a b: next b]
		probe offset? start a
	]
	find-longest-match: func [
		search 
		data
		/local 
			pos len off length result
	] [
		pos: data
		length: 0
		result: head insert insert clear [] 0 0
		while [pos: find/case/reverse pos first data] [
			if (len: match-length pos data) > length [
				if len > 15 [
					break
				]
				length: len
			]
		]
		result
	]
	lz77: context [
		result: copy []
		compress: func [
			data [any-string!]
			/local
				look-ahead-buffer search-buffer position length
		] [
			clear result
			look-ahead-buffer: data
			search-buffer: data
			while [not empty? look-ahead-buffer] [
				set [position length] find-longest-match search-buffer look-ahead-buffer
				shift-window 'look-ahead-buffer length + 1
			]
		]
	]
]
cmp/lz77/compress "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}
		--assert not script-error?

	--test-- "#1720"
		--compile-and-run-this-red {write http://abc.com compose [ {} {} ]}
		--assert not crashed?
		--assert script-error?

	--test-- "#1730"
		--compile-and-run-this-red {reduce does ["ok"]}
		--assert not crashed?
		--compile-and-run-this-red {do [reduce does ["ok"]]}
		--assert not crashed?

	--test-- "#1758"
		--compile-and-run-this-red {do [system/options/path: none]}
		--assert not crashed?

	--test-- "#1774"
		--compile-this-red {system/options/}
		--assert syntax-error "Invalid path! value"

	--test-- "#1831"
		--compile-and-run-this-red {do [function [a] [repeat a/1]]}
		--assert not crashed?

	--test-- "#1836"
		--compile-and-run-this-red {
do [
	content: [a [b] c]
	rule: [any [
		set item word! (print item) 
	|	mark: () into [rule] stop: (prin "STOP: " probe stop)]
	]
	parse content rule
]
}
		--assert not crashed?

	--test-- "#1842"
		--compile-and-run-this-red {do [throw 10]}
		--assert not crashed?

;; FIXME: still crashes in 0.6.4
; 	--test-- "#1858"
; 		--compile-and-run-this-red {
; probe type? try [
; 	f: func [] [f]
; 	f
; ]
; }
; 		--assert not crashed?
; 		--assert equal? qt/output "error!^/"

	--test-- "#1866"
		--compile-and-run-this-red {do [parse "abc" [(return 1)]]}
		--assert not crashed?

	--test-- "#1868"
		--compile-this-red {
dot2d: func [a [pair!] b [pair!] return: [float!]][
	(to float! a/x * to float! b/x) + (to float! b/y * to float! b/y)
]
norm: func [a [pair!] return: [integer!] /local d2 ][
	d2: dot2d a a 
	res: to integer! (square-root d2) 
	return res 
]
distance: func [a [pair!] b [pair!] return: [integer!] /local res ][
	norm (a - b)
]
}
		--assert compiled?

	--test-- "#1878"
		--compile-and-run-this-red {
digit: charset "0123456789"
content: "a&&1b&&2c"
block: copy [] parse content [
	collect into block any [
		remove keep ["&&" some digit] 
		(remove/part head block 1 probe head block) 
	| 	skip
	]
]
}
		--assert not crashed?

	--test-- "#1894"
		--compile-and-run-this-red {parse [1] [collect into test keep [skip]]}
		--assert not crashed?

	--test-- "#1895"
		--compile-and-run-this-red {
fn: func [body [block!]] [collect [do body]]
fn [x: 1]
}
	 	--assert not crashed?

	--test-- "#1907"
		--compile-and-run-this-red {do [set: 1]}
		--assert not crashed?

	--test-- "#1935"
		--compile-and-run-this-red {do load {test/:}}
		--assert not crashed?

	--test-- "#1969"
		--compile-and-run-this-red {
foo: func [a [float!] b [float!]][a + b]
#system [
    #call [foo 2.0 4.0]
    fl: as red-float! stack/arguments
    probe fl/value
]
}
		--assert equal? "6" trim/all qt/output

	--test-- "#1974"
		--compile-and-run-this-red {
do [
	f1: func [p [string!]][print p]
	reflect f1 'spec
]
}
		--assert not crashed?

===end-group===

~~~end-file~~~ 
