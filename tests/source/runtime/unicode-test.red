Red [
	Title:   "Red/System runtime tools test"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %unicode-test.red
	Rights:  "Copyright (C) 2012-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#system [
	#include %../../../quick-test/quick-test.reds

	~~~start-file~~~ "unicode"

	===start-group=== "load-utf8 iso-8559 only"

	lui-func: func [
		utf8-str [c-string!]
		return:  [c-string!]
		/local
		  n [node!]
		  s [series!]
	][
		n: unicode/load-utf8 utf8-str 1 + system/words/length? utf8-str
		s: as series! n/value
		as c-string! s/offset
	]

	--test-- "lui1"
		lius1:  lui-func "a" 
		--assert lius1/1 = #"a"

	--test-- "lui2"
		str2: "_a_"
		str2/1: #"^(01)"
		str2/3: #"^(7F)"
		
		lius2:  lui-func str2
		--assert lius2/1 = #"^(01)"
		--assert lius2/2 = #"a"
		--assert lius2/3 = #"^(7F)"

	--test-- "lui3"
		str3: "_a_____"
		str3/1: #"^(01)"
		str3/3: #"^(7F)"
		str3/4: #"^(C2)"
		str3/5: #"^(80)"
		str3/6: #"^(C3)"
		str3/7: #"^(BF)"
		
		lius3:  lui-func str3
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
		str22: "________"
		str22/1: #"^(EF)"
		str22/2: #"^(BF)"
		str22/3: #"^(BF)"
		str22/4: #"^(DF)"
		str22/5: #"^(BF)"
		str22/6: #"^(E0)"
		str22/7: #"^(A0)"
		str22/8: #"^(80)"
		
		luu22:  lui-func str22
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
		luu42: lui-func "^(F4)^(8F)^(BF)^(BF)"
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

]

