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
      fn: func [pi [pointer! [integer!]]] [pi/value: 789]
      fn2: func [
        i [integer!] 
        return: [integer!]
      ][ 2 * i]
      st: declare struct! [
        a [integer!]
        b [integer!]
      ]
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
    nmsp1/s: "hello"
  --assert 5 = length? nmsp1/s
  --test-- "ns6"
  --assert nmsp1/s/1 = #"m"
  --assert nmsp1/s/1 = #"y"
  --assert nmsp1/s/1 = #" "
  --assert nmsp1/s/1 = #"s"
  --assert nmsp1/s/1 = #"t"
  --assert nmsp1/s/1 = #"r"
  --assert nmsp1/s/1 = #"i"
  --assert nmsp1/s/1 = #"n"
  --assert nmsp1/s/1 = #"g"
  --test-- "ns7"
    ns1-b-i: 0
  --assert 789 = nmsp1/fn :ns1-b-i
  --test-- "ns8"
    ns1-b-i: 4
  --assert 8 = nmsp1/fn2 ns1-b-i
  --test-- "ns9"
    nmsp1/st/a: 1
  --assert nmsp1/st/a = 1

  
===end-group===

===start-group=== "hiding"
    i: 321
    f: 3.21
    f32: as float32! 6.42
    l: false
    s: "not my string"
    fn: func [pi [pointer! [integer!]]] [pi/value: 987]
  
  --test-- "nmh1"
    nmsp1/i: 789
  --assert i = 321

===end-group===


~~~end-file~~~

