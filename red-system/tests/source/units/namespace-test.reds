Red/System [
	Title:   "Red/System null test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
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

  --test-- "ns1"
  --assert 123 = nmsp1/i
  --test-- "ns2"
  --assert 1.23 = nmsp1/f
  --test-- "ns3"
  --assert (as float32! 2.46) = nmsp1/f32
  --test-- "ns4"
  --assert nmsp1/l
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
  --test-- "ns10"
  --assert ctx/j/1 = #"t"
  --test-- "ns11"
  --assert ctx/foo = 125
  --test-- "ns12"
    ctx/i: ctx/i + 1
  --assert ctx/i = 126
  --assert i = 987

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
  --test-- "nmi1"
  --assert nmsp2/i = 12
  --test-- "nmi2"
  --assert nmsp2/j = 0
  --test-- "nmi3"
  --assert nmsp2/k = 6
  --test-- "nmi4"
  --assert nmsp2/s/1 = #"h"
  --assert nmsp2/s/2 = #"e"
  --assert nmsp2/s/3 = #"l"
  --assert nmsp2/s/4 = #"l"
  --assert nmsp2/s/5 = #"o"
  --test-- "nmi5"
  --assert nmsp2/st/a = 1
  --test-- "nmi6"
  --assert nmsp2/st/b/1 = #"h"
  --assert nmsp2/st/b/2 = #"e"
  --assert nmsp2/st/b/3 = #"l"
  --assert nmsp2/st/b/4 = #"l"
  --assert nmsp2/st/b/5 = #"o"
  --test-- "nmi7"
  --assert nmsp2/st/c = 12345.678
  --test-- "nmi8"
  --assert nmsp2/st/d = 1
  
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
  --test-- "nmm1"
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
 ; --test-- "nmp2"						;-- getting a pointer on a variable in a context is not
 ;   pi: declare pointer! [integer!]	;-- a supported feature. Use a local function to get such
 ;   nmsp6: context [					;-- pointer.
 ;     i: 12345
 ;   ]
 ;   pi: :nmsp6/i
 ; --assert pi/value = 12345
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
        ]
      ]
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
          strnlen: "strnlen" [
            str     [c-string!]
            maxlen  [integer!]
            return: [integer!]
          ]
        ]
      ]
    ]
  --test-- "nmlibs1"
  --assert 1 = nmsp-lib/abs-int -1
  --test-- "nmlibs2"
  --assert 11 = nmsp-lib/strnlen "hello world" 20
  
~~~end-file~~~

