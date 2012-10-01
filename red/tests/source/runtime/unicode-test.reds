Red/System [
	Title:   "Red/System runtime tools test"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %unicode-test.reds
	Rights:  "Copyright (C) 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds
#include %../../../runtime/red.reds

~~~start-file~~~ "unicode"

===start-group=== "load-utf8 iso-8559 only"

with red [
  lui-func: func [
    utf8-str        [c-string!]
    return:         [c-string!]
    /local
      n             [node!]
      s             [series!]
      str           [c-string!]
  ][

    n: unicode/load-utf8 utf8-str size? utf8-str
    s: as series! n/value
    str: as c-string! s/offset
    str
  ]
]

--test-- "lui1"
  lius1:  lui-func "a" 
--assert lius1/1 = #"a"

--test-- "lui2"
lius2:  lui-func "^(01)a^(7F)" 
--assert lius2/1 = #"^(01)"
--assert lius2/2 = #"a"
--assert lius2/3 = #"^(7F)"

--test-- "lui3"
lius3:  lui-func "^(01)a^(7F)^(C2)^(80)^(C3)^(BF)" 
--assert lius3/1 = #"^(01)"
--assert lius3/2 = #"a"
--assert lius3/3 = #"^(7F)"
--assert lius3/4 = #"^(80)"
--assert lius3/5 = #"^(FF)"

===end-group===

===start-group=== "load-utf8 UCS-2 only"
--test-- "luu21"
luu21:  lui-func "^(C4)^(80)^(C4)^(BF)^(C5)^(80)^(C5)^(BF)" 
--assert luu21/1 = #"^(00)"
--assert luu21/2 = #"^(01)"
--assert luu21/3 = #"^(3F)"
--assert luu21/4 = #"^(01)"
--assert luu21/5 = #"^(40)"
--assert luu21/6 = #"^(01)"
--assert luu21/7 = #"^(7F)"
--assert luu21/8 = #"^(01)"

--test-- "luu22"
luu22:  lui-func "^(EF)^(BF)^(BF)^(DF)^(BF)^(E0)^(A0)^(80)" 
--assert luu22/1 = #"^(FF)"
--assert luu22/2 = #"^(FF)"
--assert luu22/3 = #"^(FF)"
--assert luu22/4 = #"^(07)"
--assert luu22/5 = #"^(00)"
--assert luu22/6 = #"^(08)"

===end-group===

===start-group=== "load-utf8 UCS-4 only"
--test-- "luu41"
luu41:  lui-func "^(F0)^(90)^(80)^(80)"
--assert luu41/1 = #"^(00)"
--assert luu41/2 = #"^(00)"
--assert luu41/3 = #"^(01)"
--assert luu41/4 = #"^(00)"

--test-- "luu42"
luu42:  lui-func "^(F4)^(8F)^(BF)^(BF)"
--assert luu42/1 = #"^(FF)"
--assert luu42/2 = #"^(FF)"
--assert luu42/3 = #"^(10)"
--assert luu42/4 = #"^(00)"

--test-- "luu43"
luu43: lui-func "^(F0)^(90)^(80)^(80)^(F4)^(8F)^(BF)^(BF)"
--assert luu43/1 = #"^(00)"
--assert luu43/2 = #"^(00)"
--assert luu43/3 = #"^(01)"
--assert luu43/4 = #"^(00)"
--assert luu43/5 = #"^(FF)"
--assert luu43/6 = #"^(FF)"
--assert luu43/7 = #"^(10)"
--assert luu43/8 = #"^(00)"

--test-- "luu44"
luu44: lui-func "^(F4)^(80)^(80)^(80)"
--assert luu44/1 = #"^(00)"
--assert luu44/2 = #"^(00)"
--assert luu44/3 = #"^(10)"
--assert luu44/4 = #"^(00)"

===end-group===

===start-group=== "load-utf8 ISO-8859 -> UCS2"
--test-- "luiu21"
luiu21: lui-func "a^(EF)^(BF)^(BF)"
--assert luiu21/1 = #"^(61)"
--assert luiu21/2 = #"^(00)"
--assert luiu21/3 = #"^(FF)"
--assert luiu21/4 = #"^(FF)"
===end-group===

===start-group=== "load-utf8 ISO-8859 -> UCS4"
--test-- "luiu41"
luiu41: lui-func "a^(F4)^(80)^(80)^(80)"
--assert luiu41/1 = #"^(61)"
--assert luiu41/2 = #"^(00)"
--assert luiu41/3 = #"^(00)"
--assert luiu41/4 = #"^(00)"
--assert luiu41/5 = #"^(00)"
--assert luiu41/6 = #"^(00)"
--assert luiu41/7 = #"^(10)"
--assert luiu41/8 = #"^(00)"
===end-group===

===start-group=== "load-utf8 ISO-8859 -> UCS2 -> UCS4"
--test-- "luiu241"
luiu241: lui-func "a^(EF)^(BF)^(BF)^(F4)^(80)^(80)^(80)"
--assert luiu241/1  = #"^(61)"
--assert luiu241/2  = #"^(00)"
--assert luiu241/3  = #"^(00)"
--assert luiu241/4  = #"^(00)"
--assert luiu241/5  = #"^(FF)"
--assert luiu241/6  = #"^(FF)"
--assert luiu241/7  = #"^(00)"
--assert luiu241/8  = #"^(00)"
--assert luiu241/9  = #"^(00)"
--assert luiu241/10 = #"^(00)"
--assert luiu241/11 = #"^(10)"
--assert luiu241/12 = #"^(00)"
===end-group===

  
~~~end-file~~~

