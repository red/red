Red/System [
	Title:   "Red/System null test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "namespace"

	nmsp1: context [
		i: 123
		f: 1.23
		f32: as float32! 2.46
		l: true
		s: "my string"
		fn: func [pi [pointer! [integer!]] return: [integer!]] [pi/value: 789 789]
		fn2: func [
			i [integer!] 
			return: [integer!]
		][ 2 * i]
		st: declare struct! [
			a [integer!]
			b [integer!]
		]
	]
	
	i: 987
	ctx: context [
		i: 123
		j: "test"
		foo: func [return: [integer!]][
			i: i + 1
			i
		]
		--test-- "in-ns1"
		--assert 124 = foo
	]
    
===start-group=== "basic"

	--test-- "ns1"		--assert 123 = nmsp1/i
	--test-- "ns2"		--assert 1.23 = nmsp1/f
	--test-- "ns3"		--assert (as float32! 2.46) = nmsp1/f32
	--test-- "ns4"		--assert nmsp1/l
	--test-- "ns5"		
		--assert nmsp1/s/1 = #"m"
		--assert nmsp1/s/2 = #"y"
		--assert nmsp1/s/3 = #" "
		--assert nmsp1/s/4 = #"s"
		--assert nmsp1/s/5 = #"t"
		--assert nmsp1/s/6 = #"r"
		--assert nmsp1/s/7 = #"i"
		--assert nmsp1/s/8 = #"n"
		--assert nmsp1/s/9 = #"g"
	--test-- "ns6"
		nmsp1/s: "hello"
		--assert 5 = length? nmsp1/s
	--test-- "ns7"
		ns1-b-i: 0
		--assert 789 = nmsp1/fn :ns1-b-i
	--test-- "ns8"
		ns1-b-i: 4
		--assert 8 = nmsp1/fn2 ns1-b-i
	--test-- "ns9"
		nmsp1/st/a: 1
		--assert nmsp1/st/a = 1
	--test-- "ns10"		--assert ctx/j/1 = #"t"
	--test-- "ns11"		--assert ctx/foo = 125
	--test-- "ns12"
		ctx/i: ctx/i + 1
		--assert ctx/i = 126
		--assert i = 987
	--test-- "ns13"
		ns13i: 1
		ns13i-nsp: context [
			ns13i: 2
			get-ns13i: func [return: [integer!]] [ns13i]
		]
		--assert 2 = ns13i-nsp/get-ns13i

===end-group===

===start-group=== "hiding"

	i: 321
	f: 3.21
	f32: as float32! 6.42
	l: false
	s: "not my string"
	fn: func [pi [pointer! [integer!]]] [pi/value: 987]
	fn2: func[
		i [integer!] 
		return: [integer!]
	][ 3 * i]
	st: declare struct! [
		a [integer!]
		b [integer!]
	]
	
	--test-- "nmh1"
		nmsp1/i: 789
		--assert i = 321
	--test-- "nmh2"
		nmsp1/f: 7.89
		--assert f = 3.21
	--test-- "nmh3"
		nmsp1/f32: as float32! 7.89
		--assert nmsp1/f32 = as float32! 7.89
	--test-- "nmh4"
		nmsp1/s: "str"
		--assert 13 = length? s
	--test-- "nmh5"
		nmh5-i: 1
		nmsp1/fn :nmh5-i
	--assert 789 = nmh5-i
	--test-- "nmh6"
		nmh6-i: 1
		fn :nmh6-i
		--assert 987 = nmh6-i
	--test-- "nmh7"
		nmh7-i: 2
		--assert 4 = nmsp1/fn2 nmh7-i
		--assert 6 = fn2 nmh7-i
	--test-- "nmh8"
		st/a: 1
		st/b: 2
		nmsp1/st/a: 100
		nmsp1/st/b: 200
		--assert 1 = st/a
		--assert 2 = st/b
    
===end-group===

===start-group=== "initialisation"

	nmsp2: context [
		i: 2
		j: 3
		k: 0
		s: "12345"
		st: declare struct! [
			a [integer!]
			b [c-string!]
			c [float!]
			d [integer!]
		]
		
		k: i * j
		s/1: #"h"
		s/2: #"e"
		s/3: #"l"
		s/4: #"l"
		s/5: #"o"
		st/a: 1
		st/b: "hello"
		st/c: 12345.678 
		st/d: 1
		until [
			i: i * j
			j: j - 1
			j < 1
		]  
	]
	--test-- "nmi1"		--assert nmsp2/i = 12
	--test-- "nmi2"		--assert nmsp2/j = 0
	--test-- "nmi3"		--assert nmsp2/k = 6
	--test-- "nmi4"
		--assert nmsp2/s/1 = #"h"
		--assert nmsp2/s/2 = #"e"
		--assert nmsp2/s/3 = #"l"
		--assert nmsp2/s/4 = #"l"
		--assert nmsp2/s/5 = #"o"
	--test-- "nmi5"		--assert nmsp2/st/a = 1
	--test-- "nmi6"
		--assert nmsp2/st/b/1 = #"h"
		--assert nmsp2/st/b/2 = #"e"
		--assert nmsp2/st/b/3 = #"l"
		--assert nmsp2/st/b/4 = #"l"
		--assert nmsp2/st/b/5 = #"o"
	--test-- "nmi7"		--assert nmsp2/st/c = 12345.678
	--test-- "nmi8"		--assert nmsp2/st/d = 1
  
===end-group===

===start-group=== "multiple"

		nmspa: context [
			i: 1
		]
		nmspb: context [
			i: 2
		]
		nmspc: context [
			i: 3
		]
		nmspd: context [
			i: 4
		]
		nmspe: context [
			i: 5
		]
		nmspf: context [
			i: 6
		]
		nmspg: context [
			i: 7
		]
		nmsph: context [
			i: 8
		]
		nmspi: context [
			i: 9
		]
		nmspj: context [
			i: 10
		]
		nmspk: context [
			i: 11
		]
	--test-- "nsm1"
		--assert nmspa/i = 1
		--assert nmspb/i = 2
		--assert nmspc/i = 3
		--assert nmspd/i = 4
		--assert nmspe/i = 5
		--assert nmspf/i = 6
		--assert nmspg/i = 7
		--assert nmsph/i = 8
		--assert nmspi/i = 9
		--assert nmspj/i = 10
		--assert nmspk/i = 11
	
===end-group===

===start-group=== "global access"

	--test-- "nmga1"
		i2: 0
		j: 3
		nmsp3: context [
			i: 2
			k: i * j
			i2: 4
		]
	--assert nmsp3/k = 6
	--assert nmsp3/i2 = 4
	--assert i2 = 0
	--test-- "nmga2"
		j3: 1
		nmsp4: context [
			i3: 2
			k3: i3 * j3
			i4: 4
		]
		i4: 0
		j3: 3
		--assert nmsp4/k3 = 2
		--assert i4 = 0
===end-group===

===start-group=== "pointers"

	--test-- "nmp1"
		i: 12345
		nmsp5: context [
			pi: declare pointer! [integer!]
		]
		nmsp5/pi: :i
		--assert nmsp5/pi/value = 12345
	--test-- "nmp3"
		nmsp6a: context [
			i: 67890
			get-addr-i: func [
				return: [pointer! [integer!]]
			][
				:i
			]
		]
		pinmp3: declare pointer! [integer!]
		pinmp3: nmsp6a/get-addr-i
		--assert 67890 = pinmp3/value
===end-group===

===start-group=== "nesting"

	--test-- "nmm1"
		nmsp7: context [
			i: 0
			nmsp7-1: context [
				i: 1
				j: i * nmsp7/i
				nmsp7-2: context [
					i: 2
					j: i * nmsp7/i
					k: i * nmsp7/nmsp7-1/i
					nmsp7-3: context [
						i: 3
						j: i * nmsp7/i
						k: i * nmsp7/nmsp7-1/i
						l: i * nmsp7/nmsp7-1/nmsp7-2/i
					]
					--assert i = 2
					--assert j = 0
					--assert k = 2
					--assert nmsp7/i = 0
					--assert nmsp7/nmsp7-1/i = 1
					--assert nmsp7/nmsp7-1/j = 0
				]
				--assert i = 1
				--assert j = 0
				--assert nmsp7/i = 0
			]
			--assert i = 0
		]
		--assert nmsp7/i = 0
		--assert nmsp7/nmsp7-1/i = 1
		--assert nmsp7/nmsp7-1/j = 0
		--assert nmsp7/nmsp7-1/nmsp7-2/i = 2
		--assert nmsp7/nmsp7-1/nmsp7-2/j = 0
		--assert nmsp7/nmsp7-1/nmsp7-2/k = 2
		--assert nmsp7/nmsp7-1/nmsp7-2/nmsp7-3/i = 3
		--assert nmsp7/nmsp7-1/nmsp7-2/nmsp7-3/j = 0
		--assert nmsp7/nmsp7-1/nmsp7-2/nmsp7-3/k = 3
		--assert nmsp7/nmsp7-1/nmsp7-2/nmsp7-3/l = 6
		 
	--test-- "nmm2"
		red: context [
			c: context [set: func [return: [integer!]][1] ]
			w: context [d: func [return: [integer!]][c/set] ]
		]
		--assert red/w/d = 1
  
===end-group===

===start-group=== "include"

	--test-- "nminc1"
		nmsp8: context [
			#include %namespace-test-include.reds
		]
	--assert 54321 = nmsp8/i
  
===end-group===

===start-group=== "libs"

		nmsp-lib: context [
			#import [
				LIBM-file cdecl [
					abs-int: "abs" [
						i       [integer!]
						return: [integer!]
					]
				]
			]
			#import [
				LIBC-file cdecl [
					strlen: "strlen" [
						str     [c-string!]
						return: [integer!]
					]
				]
			]
		]
	--test-- "nmlibs1"		--assert 1 = nmsp-lib/abs-int -1
	--test-- "nmlibs2"		--assert 11 = nmsp-lib/strlen "hello world"
	
===end-group===

===start-group=== "cross-reference"

		nmxr1: context [c: 789 fooo: func [][nmxr2/e: 123]]
		nmxr2: context [e: 456 f: nmxr1/c]

	--test-- "ns-cross-1"
		--assert nmxr2/e = 456
		nmxr1/fooo
		--assert nmxr2/e = 123
	
	--test-- "ns-cross-2"	
		--assert nmxr2/f = 789

===end-group===

===start-group=== "with"

	--test-- "nsw1"
		nsw1-nsp: context [b: 123]
		with nsw1-nsp [
		  --assert b = 123
		]
	  
	--test-- "nsw2"
		nsw2-nsp1: context [b: 123]
		nsw2-nsp2: context [b: 456]
		with [nsw2-nsp1 nsw2-nsp2] [
			--assert b = 456
			--assert nsw2-nsp1/b = 123
			--assert nsw2-nsp2/b = 456
		]
	  
	--test-- "nsw3"
		nsw3-nsp1: context [z: declare pointer! [integer!] fooo: func [][nsw3-nsp2/e: 123]]
		nsw3-nsp2: context [e: 456]
	
		with nsw3-nsp1 [
			c: 123
			z: null
		]
		--assert nsw3-nsp1/z = null
	
		e: -1
		with [nsw3-nsp1 nsw3-nsp2][
			fooo
			--assert e = 123
			]
		--assert e = -1
	
	--test-- "nsw4"
		nsw4-nsp1: context [e: 456]
		nsw4-nsp2: context [fooo: func [][e: 123]]
		with [nsw4-nsp1 nsw4-nsp2] [
			fooo
			--assert e = 456
	]
	
===end-group===

===start-group=== "System/Words"

	--test-- "nssw1"
		nssw1-a: 1
		nssw1-nmsp: context [
		  nssw1-a: 2
		  --assert 1 = system/words/nssw1-a
		  --assert 2 = nssw1-a
		  system/words/nssw1-a: 3
		]
		--assert nssw1-a = 3
	
	--test-- "nssw2"
		nssw2-i: 1
		nssw2-nmsp: context [
			nssw2-i: 2
			pi: declare pointer! [integer!]
			pi: :nssw2-i
			--assert pi/value = 2
		]
		--assert nssw2-i = 1

===end-group===

===start-group=== "context as local variable"
  
	--test-- "nscasv2"
		nsca2-f: function [
			return: [integer!]
			/local
			context
		][
			context: 1
			context
		]
		--assert nsca2-f = 1

===end-group===

===start-group=== "accessing alias from context"
 
	--test-- "nsaa2 - issue #238"
		nssa2-c: context [
			s!: alias struct! [val [integer!]]
			s: declare s!
			s/val: 200
		]
		
		with nssa2-c [
			nssa2-f: function [
				p [s!]
				return: [integer!]
			][
				p/val
			]
		]
		--assert 200 = nssa2-f nssa2-c/s

===end-group===

===start-group=== "inline functions in namespace"

	--test-- "ifin1 - issue 285"
		ifin-func: func [i [integer!] return: [integer!]][i]
		ifin-nsp: context [
			f: func [[infix] a [integer!] b [integer!] return: [integer!]][a + b]
			i: ifin-func 1 f 2
		]
		--assert 3 = ifin-nsp/i

===end-group===


===start-group=== "reported issues"

	--test-- "namespace-issue-#1322"
		ni1322-nmsp: context [
			p: 123
			
			system-func: func [p [int-ptr!]][
				p/value: 33
			]
			
			change-p: func [
				/local
					p		[integer!]
			][
				p: 0
				system-func :p
			]
		]
		--assert ni1322-nmsp/p = 123
		ni1322-nmsp/change-p
		--assert ni1322-nmsp/p = 123
	
===end-group===

~~~end-file~~~

