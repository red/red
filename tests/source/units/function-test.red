Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "function"

===start-group=== "Basic function tests"

	--test-- "fun-1"
		foo1: func [][1]
		--assert 1 = foo1
	
	--test-- "fun-2"
		foo2: func [a][a]
		--assert 5 = foo2 5
		--assert "a" = foo2 "a"
		--assert [123] = foo2 [123]
	
	--test-- "fun-3"
		foo3: func [a /local c][c: 1 a + c]
		--assert 3 = foo3 2
	
	--test-- "fun-4"
		foo4: func [a /ref][either ref [a][0]]
		--assert 0 = foo4 5
		--assert 5 = foo4/ref 5
	
	--test-- "fun-5"
		foo5: func [a /ref b][if ref [a: a + b] a * 2]
		--assert 10 = foo5 5
		--assert 16 = foo5/ref 5 3
	
	--test-- "fun-6"
		z: 10
		foo6: func [a [integer!] b [integer!] /ref d /local c][
			c: 2
			unless ref [d: 0]
			a + b * c + z + d
		]

		--assert 16 = foo6 1 2
		--assert 21 = foo6/ref 1 2 5
	
	--test-- "fun-7"
		bar:  func [] [foo7]
		foo7: func [] [42]
		--assert 42 = bar
	
	--test-- "fun-8"
		foo8: func ['a :b][
			--assert a = 'test
			--assert "(1 + 2)" = mold b
		]
		foo8 test (1 + 2)
		
	--test-- "fun-9"
		foo9: func [/local cnt][
			cnt: [0]
			cnt/1: cnt/1 + 1
		]
		--assert 1 = foo9
		--assert 2 = foo9
		--assert 3 = foo9
	
	--test-- "fun-10"
		foo10: func [a][a + 0]
		foo10: func [][1]
		--assert 1 = foo10 "dummy"						;-- make it crash if wrong function referenced
	
	--test-- "fun-11"
		non-evaluated: func ['param] [param]
		res: first [(1 + 2)]
		--assert res = quote (1 + 2)
		--assert res = non-evaluated (quote (1 + 2))
		--assert 'quote = non-evaluated quote (1 + 2)

	--test-- "fun-12"
		foo12: func [/A argA /B argB][reduce [argA argB]]
		res: foo12/A/B 5 6 
		--assert res = [5 6]

	--test-- "fun-13"
		res: foo12/B/A 7 5
		--assert res = [5 7]

	--test-- "fun-14"
		foo14: func [arg1 /A argA /B argB][reduce [arg1 argA argB]]
		res: foo14/A/B 4 7 8
		--assert res = [4 7 8]

	--test-- "fun-15"
		res: foo14/B/A 4 9 7
		--assert res = [4 7 9]

	--test-- "fun-16"
		foo16: func [arg1 /A argA /B argB /C argC][reduce [arg1 argA argB argC]]
		res: foo16/A/B/C 4 5 7 8
		--assert res = [4 5 7 8]

	--test-- "fun-17"
		res: foo16/A/C/B 4 5 9 7
		--assert res = [4 5 7 9]

	--test-- "fun-18"
		foo18: func [/A argA [string!] /B argB [integer!]][reduce [argA argB]]
		res: foo18/A/B "a" 6
		--assert res = ["a" 6]

	--test-- "fun-19"
		res: foo18/B/A 7 "b"
		--assert res = ["b" 7]

===end-group===

===start-group=== "Out of order arguments type-checking tests"
	
	--test-- "ooo-1"
		extract/into/index [1 2 3 4 5 6] 2 b: [] 2

	--test-- "ooo-2"
		ooo2: func [cmd /w /o out [block!]][]
		ooo2/o/w "cmd" o: [] 
		--assert true

	--test-- "ooo-3"
		a: func [/b c [integer!] /d e][]
		a/d/b e: {} 1
		a/d/b {} e: 1
		--assert true

	--test-- "ooo-4"
		--assert error? try [a/d/b 1 e: {}]
		--assert error? try [a/d/b e: 1 {}]

===end-group===

===start-group=== "Alternate constructor tests"
	
	--test-- "fun-alt-1"
		z: 0
		alt1: function [a][
			z: 2
			a + z
		]
		--assert 10 = alt1 8
		--assert z = 0
	
	--test-- "fun-alt-2"
		alt2: does [123]
		--assert 123 = alt2
		
	--test-- "fun-alt-3"
		alt3: has [c][c: 1 c]
		--assert 1 = alt3

===end-group===


===start-group=== "Exit and Return tests"
	
	--test-- "fun-exit-1"
		ex1: does [123 exit 0]
		--assert unset! = type? ex1
		
	--test-- "fun-exit-2"
		ex2: does [if true [exit] 0]
		--assert unset! = type? ex2
		
	--test-- "fun-exit-3"
		ex3: does [until [if true [if true [exit]] true] 0]
		--assert unset! = type? ex3
		
	--test-- "fun-ret-1"
		ret1: does [return true]
		--assert ret1
		
	--test-- "fun-ret-2"
		ret2: does [return 123]
		--assert 123 = ret2
		
	--test-- "fun-ret-3"
		ret3: does [if true [return 3]]
		--assert 3 = ret3
	
	--test-- "fun-ret-4"
		ret4: does [return 1 + 1]
		--assert 2 = ret4
		
	--test-- "fun-ret-5"
		ret5: does [return either false [12][34]]
		--assert 34 = ret5
		
	--test-- "fun-ret-6"								;-- issue #770
		ret6: func [i [integer!]][
			until [
				if true [
					if i = 0 [
						if true [return 0]
						return 1
					]
					return 2
				]
				return 3
				true
			]
		]
		--assert 0 = ret6 0
		--assert 2 = ret6 1

	--test-- "fun-ret-7"
		f: function [][
			blk: [1 2 3 4 5]
			foreach i blk [
				case [
					i > 1 [return i]
				]
			]
		]
		g: function [][if f [return 1]]
		--assert g = 1

	--test-- "fun-ret-8"
		f: function [][
		    case [
		        2 > 1 [return true]
		    ]
		]
		g: function [][if f [return 1]]
		--assert g = 1

	--test-- "fun-ret-9"
		f: function [][if true [return true]]
		g: function [][if f [return 1]]
		--assert g = 1

	--test-- "fun-ret-10"
		g: function [][if true [return 1]]
		--assert g = 1

	--test-- "fun-ret-10"
		f: function [][true]
		g: function [][if f [return 1]]
		--assert g = 1

	--test-- "fun-ret-11"
		f: function [][if true [return true]]
		g: function [][if (f) [return 1]]
		--assert g = 1

	--test-- "fun-ret-12"
		f: function [][if true [return true] ]
		g: function [][if not not f [return 1]]
		--assert g = 1

	--test-- "fun-ret-13"
		f: function [][if true [return 'X]]
		g: function [][if f [return 1]]
		--assert g = 1

	--test-- "fun-ret-14"								;-- issue #778
	 	--assert 1 = do load "f: func [][return 1] t: f"
		
	--test-- "fun-ret-15"								;-- issue #1169
		f: does [parse "1" [(return 123)]]
		--assert f = 123

	--test-- "fun-ret-16"
		f: does [do [return 124]]
		--assert f = 124

===end-group===

===start-group=== "Reflection"
	clean-strings: func [blk [block!]][
		blk: copy blk
		forall blk [if string? blk/1 [remove blk blk: back blk]]
		blk
	]
	
	--test-- "fun-ref-1"
		ref1: func [a b][a + b]
		--assert [a b] = spec-of :ref1
		body: body-of :ref1
		--assert any [
			[a + b] = body
			none? body									;-- if option store-bodies = no
		]
	 
	--test-- "fun-ref-2"
		blk: clean-strings spec-of :append	
		--assert blk = [
			series [series! bitset!] value [any-type!] /part length [number! series!]
			/only /dup count [number!] return: [series! bitset!]
		]
	
	--test-- "fun-ref-3"
		blk: clean-strings spec-of :set	
		--assert blk = [word [any-word! block! object! path!] value [any-type!] /any /case /only /some return: [any-type!]]
		
	--test-- "fun-ref-4"
		blk: clean-strings spec-of :<
		--assert blk = [value1 [any-type!] value2 [any-type!]]

===end-group===

===start-group=== "Capturing of iterators counter word(s)"

	--test-- "fun-capt-1"
		f1: function [] [repeat ii 5 [ii]]
		--assert none <> find spec-of :f1 'ii
		f1
		--assert unset? get/any 'ii
	
	--test-- "fun-capt-2"
		f2: function [] [foreach ii [1 2 3] [ii]]
		--assert none <> find spec-of :f2 'ii
		f2
		--assert unset? get/any 'ii

	--test-- "fun-capt-3"
		f3: function [] [foreach [ii jj] [1 2 3 4] [ii jj]]
		--assert none <> find spec-of :f3 'ii
		--assert none <> find spec-of :f3 'jj
		f3
		--assert unset? get/any 'ii
		--assert unset? get/any 'jj

===end-group===

===start-group=== "Reported issues"
  	--test-- "ri1 issue #415"
		ri415-f: func [] [
    		ri415-g: func [] [1]
			ri415-g
		]
		--assert 1 = ri415-f
  
  	--test-- "ri2 issue #461"
  		ri2-fn: func ['word] [:word]
		--assert op? ri2-fn :+
  	
  	--test-- "ri3 issue #461"
  		ri3-fn: func ['word] [mold :word]
		--assert "'+" = ri3-fn '+
  	
  	--test-- "ri4 issue #461"
  		ri4-fn: func ['word] [mold :word]
 		--assert "+" = ri4-fn +
comment {  	
  	--test-- "ri5 issue #420"
  		ri5-fn: function [][
  			g: func [] [true]
  			g
  		]
  		--assert ri5-fn
}
 comment {   	
  	--test-- "ri6 issue #420"
  		ri6-fn: func [
  			/local
  				g
  		][
  			g: func [] [true]
  			g
  		]
  	--assert ri6-fn
}
  	
  	--test-- "ri7 issue #420"
  		ri7-g: func [][true]
  		ri7-f: func [][ri7-g]
		--assert ri7-f
  	
  	--test-- "ri8 issue #443"
  		ri8-fn: func[
  			/local
  				ri8-b
  				ri8-i
  				ri8-j
  		][
  			ri8-b: copy []
  			foreach [ri8-i ri8-j] [1 2 3 4] [append ri8-b ri8-i * ri8-j]
  			ri8-b
  		]
  		ri8-i: 100
  		ri8-j: 200
  	--assert [2 12] = ri8-fn
  	--assert 100 = ri8-i
  	--assert 200 = ri8-j
  	
  	--test-- "ri9 issue #443"
  		ri9-fn: function[][
  			ri9-b: copy []
  			foreach [ri9-i ri9-j] [1 2 3 4] [append ri9-b ri9-i * ri9-j]
  			ri9-b
  		]
  	--assert [2 12] = ri9-fn
  	--assert error? try [get 'ri9-i]
  	--assert error? try [get 'ri9-j]

===end-group===


===start-group=== "Infix operators creation"
	--test-- "infix-1"
		infix: function [a b][a * 10 + b]
		***: make op! :infix
		--assert 7 *** 3 = 73

;; Test commented as routine declaration cannot be handled in a code block anymore...
;;
;	unless system/state/interpreted? [			;-- routine creation not supported by interpreter
;		infix2: routine [a [integer!] b [integer!]][integer/box a * 20 + b]
;
;		--test-- "infix-2"
;			*+*: make op! :infix2
;			--assert 5 *+* 6 = 106
;
;		--test-- "infix-3"
;			--assert 5 *+* 6 *** 7 = 1067
;	]

===end-group===

===start-group=== "Scope of Variables"

	--test-- "scope1 issue #825"
		s1-text: "abcde"
		s1-f: function [/extern s1-text] [
			s1-text
		]
		--assert s1-f = "abcde"
		
	--test-- "scope2 issue #825"
		s2-f: function [/extern s2-text] [
			s2-text
		]
		s2-text: "abcde"
		--assert s2-f = "abcde"
		
	--test-- "scope3 issue #825"
		s3-text: "abcde"
		s3-f: func [/local s3-text] [
			s3-text: "12345"	
		]

	--test-- "scope4 issue #825"
		s4-text: "abcde"
		s4-f: function [extern s4-text] [
			if extern [s4-text: "12345"]
			s4-text
		]
		--assert "12345" = s4-f true "00000"
		
	--test-- "scope5 issue #825"
		s5-text: "abcde"
		s5-f: func[/extern s5-text] [
			either extern [
				s5-text	
			][
				"00000"
			]
		]
		--assert "12345" = s5-f/extern "12345"
		
	--test-- "scope6 issue #825"
		s6-text: "abcde"
		s6-f: func [local s6-text] [
			s6-text
		]
		--assert "12345" = s6-f "filler" "12345"
		
	--test-- "scope7 issue #825"
		s7-text: "abcde"
		s7-f: function [local s7-text] [
			s7-text
		]
		--assert "12345" = s7-f "filler" "12345"

	--test-- "scope 8"
		s8-f: function [/extern a][]
		--assert empty? spec-of :s8-f

	--test-- "scope 9"
		s9-f: function [/extern a /local b][]
		--assert [/local b] = spec-of :s9-f

	--test-- "scope 10"
		s10-f: function [/local b /extern a][]
		--assert [/local b] = spec-of :s10-f

	--test-- "scope 11"
		s11-f: function [/extern a /local b][c: 0]
		--assert [/local b c] = spec-of :s11-f

	--test-- "scope 12"
		s12-f: function [/local b /extern a][d: 1]
		--assert [/local b d] = spec-of :s12-f

	--test-- "scope 13"
		s13-f: function [/local b][]
		--assert [/local b] = spec-of :s13-f

	--test-- "scope 14"
		s14-f: function [/local b][e: 2]
		--assert [/local b e] = spec-of :s14-f

===end-group===

===start-group=== "functionfunction"
comment { issue #420
	--test-- "funfun1"
        ff1-i: 1
        ff1-f: function [][ff1-i: 2 f: func[][ff1-i] f]
        --assert 2 = ff1-f
 }                                              
                                                
    --test-- "funfun2"
        ff2-i: 1
        ff2-f: function [][ff2-i: 2 ff2-i]
        ff2-r: ff2-f
        --assert 1 = ff2-i
        --assert 2 = ff2-r
        
    --test-- "funfun3"
        ff3-i: 1
        ff3-f: function [][
            ff3-i: 2
            o: make object! [
                ff3-i: 3
            ]
            o/ff3-i
        ]
        --assert 3 = ff3-f
        
    --test-- "funfun4"
        ff4-i: 1
        ff4-f: function [][
            ff4-i: 2
            o: make object! [
                ff4-i: 3
            ]
            ff4-i
        ]
        --assert 2 = ff4-f
            
    --test-- "funfun5 #964"
        ff5-f: function [] [
            either true [
                ff5-x
             ][
                ff5-x: 0
            ]
        ]
        --assert none = ff5-f
                             
    --test-- "funfun6 #964"
        ff6-f: function [] [
            either false [
                ff6-x
             ][
                ff6-x: 0
            ]
        ]
        --assert 0 = ff6-f
        
    --test-- "funfun7"
        ff7-f: function [] [
            a: 1
            b: make object! [c: 2]
            c
        ]   
        --assert none = ff7-f 
        
     --test-- "funfun8"
        ff8-i: 1
        ff8-f: function [] [
            a: 1
            b: make object! [ff8-i: 2]
            ff8-i
        ]   
        --assert none = ff8-f 
        
if system/state/interpreted? [                          ;-- not yet supported by compiler 
    do [
    	--test-- "funfun9"
        ff9-f: function [] [
            a: 1
            b: function [] [c: 2]
            b
            c
        ]   
        --assert none = ff9-f 
    ]
]

if system/state/interpreted? [                          ;-- not yet supported by compiler         
	do [
     --test-- "funfun10"
        ff10-i: 1
        ff10-f: function [] [
            a: 
            b: function [] [ff10-i: 2]
            b
            ff10-i
        ]   
        --assert none = ff10-f 
    ]
]

if system/state/interpreted? [                          ;-- not yet supported by compiler         
    do [
    --test-- "funfun11"
        ff11-i: 1
        ff11-f: function [] [
            ff: func [/local ff11-i][ff11-i: 2]
            ff11-i
        ]
        --assert none = ff11-f
        --assert 1 = ff11-i
    ]
]        
comment { 
    --test-- "funfun12"
        ff12-i: 1
        ff12-f: function [] [
            ff: make object! [ff12-i: 2]
            ff12-i
        ]
        --assert none = ff12-f
        --assert 1 = ff12-i
       
    --test-- "funfun13"
        ff13-i: 1
        ff13-f: function [/extern ff13-i] [
            ff: func [/local ff13-i][ff13-i: 2]
            ff13-i: 3
        ]
        --assert 3 = ff13-f
        --assert 3 = ff13-i
      
    --test-- "funfun14"
        ff14-i: 1
        ff14-f: function [/extern ff14-i] [
            ff: make object! [ff14-i: 2]
            ff14-i: 3
        ]
        --assert 3 = ff14-f
        --assert 3 = ff14-i
       
    --test-- "funfun15"
        ff15-i: 1
        ff15-f: func [
            /local ff15-i
        ][
            ff15-i: 2
            ff: function [
                /extern ff15-i
            ][
                ff15-i
            ]
            ff
        ]
        --assert 2 = ff15-f
        --assert 1 = ff15-i     
}
                                                    
if system/state/interpreted? [                      ;-- not yet supported by compiler
	do [
    --test-- "funfun16"
        ff16-f: function [] [
            f2: func [i] [i: 1]
            f2 i
            i
        ]
        --assert none = ff16-f
    ]
]       

if system/state/interpreted? [                      ;-- not yet supported by compiler
	do [
    --test-- "funfun17"
        ff17-i: 10
        ff17-f: function [] [
            f2: func [ff17-i] [ff17-i: 1]
            f2 ff17-i
            ff17-i
        ]
        --assert none = ff17-f
    ]
]
                                        
===end-group===

===start-group=== "functions with objects"
--test-- "fwo1 - #965"
        fwo1-f: func [
            o object!
        ][
          append o/a o/b  
        ]
        fwo1-o: make object! [ 
            a: "hello"
            b: " world"
        ]
        --assert "hello world" = fwo1-f fwo1-o

===end-group===

===start-group=== "function with lit-arg"
    fwla-f: func ['x][:x]
        
    --test-- "fwla1"
        --assert 10 = fwla-f 10
    
    --test-- "fwla2"
        --assert 50 = fwla-f (20 + 30)
        
    --test-- "fwla3"
        fwla3-i: 40
        --assert 40 = fwla-f :fwla3-i 
        
    --test-- "fwla4"
        fwla4-o: make object! [i: 50]
        --assert 50 = fwla-f :fwla4-o/i

    --test-- "fwla5"
        --assert (first ['fwla4-o/i]) = fwla-f 'fwla4-o/i

    --test-- "fwla6"
        --assert (first [fwla4-o/i:]) = fwla-f fwla4-o/i:

    --test-- "fwla7"
        --assert (first [fwla4-o/i]) = fwla-f fwla4-o/i
===end-group===

===start-group=== "function with get-arg"
        fwga-f: func [:x][:x]
        
    --test-- "fwga1"
        --assert 10 = fwga-f 10
    
    --test-- "fwga2"
        --assert (first [(20 + 30)]) = fwga-f (20 + 30)
        
    --test-- "fwga3"
        fwga3-i: 40
        --assert (first [:fwga3-i]) = fwga-f :fwga3-i 
        
    --test-- "fwga4"
        fwga4-o: make object! [i: 50]
        --assert (first [:fwga4-o/i]) = fwga-f :fwga4-o/i
        
    --test-- "fwga5"
        fwga5-i: 10
        fwga5-f: func[:x][set x 1 + get x]
        --assert 11 = fwga5-f fwga5-i
        --assert 11 = fwga5-i

    --test-- "fwga6"
        --assert (first [fwga4-o/i]) = fwga-f fwga4-o/i

    --test-- "fwga7"
        --assert (first ['fwga4-o/i]) = fwga-f 'fwga4-o/i

    --test-- "fwga8"
        --assert (first [fwga4-o/i:]) = fwga-f fwga4-o/i:
===end-group===

~~~end-file~~~
