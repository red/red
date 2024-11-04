REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc-5.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 5"

===start-group=== "Red regressions #2001 - #2500"

	; help functions for crash and compiler-problem detection
	true?: func [value] [not not value]
	crashed?: does [true? find qt/output "*** Runtime Error"]
	compiled?: does [true? not find qt/comp-output "Error"]
	script-error?: does [true? find qt/output "Script Error"]
	syntax-error?: does [true? find qt/output "Syntax Error"]
	compiler-error?: does [true? find qt/comp-output "*** Compiler Internal Error"]
	compilation-error?: does [true? find qt/comp-output "*** Compilation Error"]
	loading-error: func [value] [found? find qt/comp-output join "*** Loading Error: " value]
	compilation-error: func [value] [found? find qt/comp-output join "*** Compilation Error: " value]
	syntax-error: func [value] [found? find qt/comp-output join "*** Syntax Error: " value]
	script-error: func [value] [found? find qt/output join "*** Script Error: " value]
	; -test-: :--test--
	; --test--: func [value] [probe value -test- value]

	--test-- "#2007"
		; NOTE: without View support `make image!` produces a runtime error
		--compile-and-run-this-red {make image! 0x0}
		--assert not crashed?

	--test-- "#2027"
		--compile-and-run-this-red {do [a: func [b "b var" [integer!]][b]]}
		--assert script-error "invalid function definition"

	; --test-- "#2133"
	;	FIXME: still OPEN
	; 	--compile-and-run/pgm %tests/source/units/issue-2133.red
	; 	--assert not crashed?

	--test-- "#2137"
		--compile-and-run-this-red {repeat n 56 [to string! debase/base at form to-hex n + 191 7 16]}
		--assert not crashed?

	--test-- "#2143"
		--compile-and-run-this-red {
do [
	ts: [test: 10]
	t-o: object []
	make t-o ts		
]
}
		--assert not crashed?

	--test-- "#2159"
		--compile-and-run-this-red {append #{} to-hex 20}
		--assert not crashed?

	--test-- "#2162"
		--compile-and-run-this-red {write/info https://api.github.com/user [GET [User-Agent: "me"]]}
		--assert not crashed?

	--test-- "#2173"
		--compile-and-run-this-red {not parse [] [help]}
		--assert not crashed?

	--test-- "#2179"
		--compile-and-run-this-red {
test: none
parse ["hello" "world"] ["hello" set test opt "world"]
test
parse ["hello"] ["hello" set test opt "world"]
test
parse ["hello"] ["hello" set test any "world"]
test
}
		--assert not crashed?

	--test-- "#2182"
		--compile-and-run-this-red {sym: 10 forall sym []}
		--assert not crashed?

	--test-- "#2214"
		; NOTE: without View support `make image!` produces a runtime error
		--compile-and-run-this-red {make image! []}
		--assert not crashed?

	;; #2438 --> see %load-test.red

===end-group===


===start-group=== "Red regressions #2501 - #3000"

	;; for this test it doesn't matter if it errors out or returns a pair
	--test-- "#2538"
		--compile-and-run-this-red {probe system/console/size}
		--assert not crashed?
	
	--test-- "#2671"
		--compile-this {Red [] #"^^(0000001)"}
		--assert syntax-error "Invalid char! value"

		--compile-this {Red [] "^^(0000001)"}
		--assert syntax-error "Invalid string! value"
		
		--compile-this {Red [] #"^^(skibadee-skibadanger)"}
		--assert syntax-error "Invalid char! value"
		
		--compile-this {Red [] "^^(skibadee-skibadanger)"}
		--assert syntax-error "Invalid string! value"
	
===end-group===

; ===start-group=== "Red regressions #3001 - #3500"
; ===end-group===

===start-group=== "Red regressions #3501 - #4000"

	--test-- "#3670"
		write qt-tmp-file "1 + 2"
		qt/source-file?: yes
		qt/compile qt-temp-file
		--assert probe not compiler-error?
		--assert probe syntax-error "Invalid Red program"

	--test-- "#3624"
		--compile-and-run-this-red {probe replace/case/all quote :a/b/A/a/B [a] 'x}
		--assert qt/output = ":x/b/A/x/B^/"
	
	;; for this test it doesn't matter if it errors out or outputs a result
	--test-- "#3714"
		
		--compile-and-run-this-red {probe system/view/metrics/dpi}
		--assert not crashed?
		
		--compile-and-run-this-red {probe system/view/screens/1/size}
		--assert not crashed?
		
		--compile-and-run-this-red {
			print mold/flat/part system/console 100
			print mold/flat/part system/console/size 100
		}
		--assert not crashed?


	--test-- "#3733"
		--compile-and-run-this-red {f: does [1] do [f/q]}
		--assert not crashed?
		--assert script-error?

		;; FIXME: this should not error out when compiled:
		--compile-and-run-this-red {
			do [f: func [/q] bind [1] context []]
			f/q
		}
		--assert not crashed?
		; --assert not script-error?

; FIXME: cannot test this until compile-time macros will be expanded by Red, not Rebol	
;	--test-- "#3773"
;		;; see the same triad interpreted in regression-test-red.red...
;
;		;; context? should not accept a string
;		--compile-and-run-this-red {
;			#macro ctx: func [x] [context? x]
;			ctx ""
;		}
;		--assert compiler-error?
;
;		;; this is reduced like: (mc 'mc) => (mc) => error (no arg)
;		--compile-and-run-this-red {
;			#macro mc: func [x] [x]
;			probe quote (mc 'mc)
;		}
;		--assert compiler-error?
;
;		;; :mc = func [x][x], so `mc :mc` executing `x` applies it to an empty arg list => error
;		--compile-and-run-this-red {
;			#macro mc: func [x] [x]
;			probe quote (mc :mc)
;		}
;		--assert compiler-error?


	--test-- "#3831"
		--compile-and-run-this-red {repeat x none []}
		--assert not crashed?
		--assert script-error?

		--compile-and-run-this-red {loop none []}
		--assert not crashed?
		--assert script-error?


	--test-- "#3866"
		--compile-and-run-this-red {
			f: func [x [string!]][probe x]
			f 1
		}
		--assert not crashed?
		--assert script-error?


	--test-- "#3876"
		--compile-and-run-this-red {
			count: 0.0
			vec-size: 100.0
			vec: make vector! [float! 64 100]
			count: count + 1.0
			print count
			print vec/:count
			val: (1.012345 * (count / vec-size))
			print val
			vec/:count: val
		}
		--assert not crashed?
		--assert script-error?


	--test-- "#3891"
		--compile-and-run-this-red {probe load "a<=>"}
		--assert not crashed?
		
===end-group===

===start-group=== "Red regressions #4001 - #4500"

	--test-- "#4190"
		--compile-and-run-this-red {
			fc: make face! [
				fn: does [self/parent: 'boom]
			]
			fc/fn
			print fc/parent
		}
		--assert not crashed?
		--assert true? find qt/output "boom"
		
===end-group===

===start-group=== "Red regressions #4501 - #5000"

	--test-- "#4526"
		--compile-and-run-this {
			Red []
			do bind [probe 1 ** 2] context [**: make op! func [x y][x + y]]
		}
		--assert compiled?
		--assert 3 = load qt/output

	--test-- "#4527"
		--compile-and-run-this {
			Red []
			f: function [b [block!] return: [default!] /local i ] [	;-- modified after #5552
				c: clear []
				probe c
				foreach x c [1]
			]
			f [a/b]
		}
		--assert compiled?
		--assert [] = load qt/output

	--test-- "#4568"
		--compile-this {Red [Config: [red-strict-check?: off]] :foo}
		--assert compiled?
	
	--test-- "#4569"
		--compile-and-run-this {
			Red []

			bind 'foo has [foo]['WTF]
			foo: object []

			probe foo
			probe :foo
		}
		--assert compiled?
		--assert [make object! [] make object! []] = load qt/output
		
		--compile-and-run-this {
			Red []

			block: reduce ['foo func [/bar]["Definitely not bar."]]
			foo:  context [bar: does ['bar]]
			print foo/bar
		}
		--assert compiled?
		--assert 'bar = load qt/output
		
	--test-- "#4570"
		--compile-and-run-this {Red [] quote + 0 0}
		--assert not script-error?
		--compile-and-run-this {Red [] quote >> 0 0}
		--assert not crashed?
  
	--test-- "#4613"
		--compile-this "Red [] probe bug$0"
		--assert compilation-error?
		
		--compile-and-run-this "Red [Currencies: [bug]] probe bug$0"
		--assert compiled?
		--assert bug$0 = load qt/output
		
		--compile-and-run-this {
			Red [Currencies: [bug]]
			append system/locale/currencies/list 'bug
			probe bug$0
		}
		--assert compiled?
		--assert script-error?

	--test-- "#4854"
		--compile-and-run-this {
			Red []

			recycle/off

			do [
				f-call: func [f] [f/x 1 2]

				f1: function [/x q w /local a b c] [
					f-call :f2
					print "passed!"
				]
				f2: function [/x q w] [
					print 1
					foreach n [1] [
						a: b: c: d: e: f: none					;) z = none then crash in foreach-next
						a: b: c: d: e: f: g: none					;) z = none then crash in foreach-next
						b: c: d: e: f: g: h: none				;) z = :?? then crash in foreach-next
						a: b: c: d: e: f: g: h: i: none			;) crash before z in context/set
						a: b: c: d: e: f: g: h: i: j: none		;) crash before z in context/set
						a: b: c: d: e: f: g: h: i: j: k: none		;) crash before z in context/set
						a: b: c: d: e: f: g: h: i: j: k: l: none	;) crash before z in context/set
						z: none
						?? z
					]
					print 2

				]
				f-call :f1
			]
		}
		--assert compiled?
		--assert not crashed?
		--assert true? find qt/output "passed!"

	--test-- "#4990"
		--compile-and-run-this {
			Red []
			s: "abc" 
			loop 100 [
				forall s [probe s continue]
			]
		}
		--assert compiled?
		--assert not crashed?
		--assert not find qt/output "Error"

	--test-- "#5065"
		--compile-and-run-this {
			Red []
			do [
				old: reduce list: [:loop :repeat :prin :exp :max :odd? :divide]
				loop 1 [] repeat x 1 [] prin [] exp 1 max 1 0 odd? 2 divide 2 2 
				new: reduce list
				if all collect [
					repeat i length? list [keep :old/:i =? :new/:i]
				] [print "MATCH"]
			]
		}
		--assert compiled?
		--assert true? find qt/output "MATCH"

	--test-- "#5070"
		--compile-and-run-this {
			Red []
			m: #[]
			m/1:       does [1]
			m/(2):     does [2]
			m/key:     does [3]
			m/("s"):   does [4]
			m/(#"c"):  does [5]
			put m 'key does [6]
			put m "s"  does [7]
			put m #"c" does [8]
			print mold/only to-block m
		}
		--assert compiled?
		--assert (load qt/output) == [
		    1    func [][1] 
		    2    func [][2] 
		    key: func [][6] 
		    "s"  func [][7] 
		    #"c" func [][8]
		]

	--test-- "#5071"
		--compile-and-run-this {Red [] b: [] construct b}
		--assert compiled?

	--test-- "#5097"
		--compile-and-run-this {
			Red []
			case/all [
				true  [while [false] []]
				false []
			]
		}
		--assert compiled?

	--test-- "#5239"
		do [--assert error? try [do try/all [throw 'grenade]]]
		
	--test-- "#5335"
	
		--compile-and-run-this {
			Red []
			c5335: 0
			on-parse-event5335: func [e m r i s return: [logic!]][c5335: c5335 + 1 true]

			parse-trace5335: func [input [series!] rules [block!] /case /part limit [integer!] return: [logic! block!]][
				parse/:case/:part/trace input rules limit :on-parse-event5335
			]
			parse-trace5335 [a b c] [some word!]
			probe c5335
		}
		--assert compiled?
		--assert (load qt/output) > 0
		
	--test-- "#5552.1"
		--compile-this {Red [] f552: function [/ref x /local y return: [block!]][a: 1 print "OK"]}
		--assert not compiled?
		--assert found? find qt/comp-output "invalid function"
	--test-- "#5552.2"	
		--compile-this {Red [] f552: function [/ref x /local y return: [block!] "locals follow docstring ->"][a: 1 print "OK"]}
		--assert not compiled?
		--assert found? find qt/comp-output "invalid function"
	--test-- "#5552.3"	
		--compile-this {Red [] f552: func [a [block!] return: [block!] /ref /local x][]}
		--assert not compiled?
		--assert found? find qt/comp-output "invalid function"
	--test-- "#5552.4"	
		--compile-this {Red [] f552: func [a [block!] return: [block!] /ref y /local x][]}
		--assert not compiled?
		--assert found? find qt/comp-output "invalid function"

===end-group===

~~~end-file~~~ 
