REBOL [
  Title:   "Old Red regression tests script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %regression-tests.r
	Rights:  "Copyright (C) 2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Old Regression tests"

    --compile-and-run-this-red {
      ;================ BASIC =================
      print "or1"
      print 789
      
      print "or2"
      a: 123
      a: a + 2
      print a * 6 - a
    
    
      ;================ BLOCK =================

      b: [4 7 9 [11] test /ref 'red]
      
      print "or3"
      print pick b 2
      
      print "or4"
      print pick pick b 4 1
      
      print "or5"
      print pick next b 1
      
      print "or6"
      print pick next next b 1
      print "or7"
      print pick back next b 1
      
      print "or8"
      print length-of b
      
      print "or9"
      print length-of next next b
      
      print "or10"
      print length-of pick b 4
      
      print "or11"
      print pick at b 2 1
      
      print "or12"
      print pick skip b 2 1
      
      print "or13"
      print pick b 99
      
      print "or14"
      print pick b -99
      
      print "or15"
      print pick at next b -1 1
      
      print "or16"
      print pick skip next b -1 1
      
      print "or17"
      print length-of tail b
      
      print "or18"
      print length-of head tail b
      
      print "or19"
      print index-of b
      
      print "or20"
      print index-of tail b
      
      print "or21"
      print head? b
      
      print "or22"
      print head? next b
      
      print "or23"
      print tail? b
      
      print "or24"
      print tail? tail b
      
 
      append b 123
      print "or25"
      print length-of b
      
      print "or26"
      print pick b length-of b
      
      
      append b [7 8 9]
      print "or27"
      print length-of b
      print "or28"
      print pick tail b -2
      
      
      poke b 1 66
      
      print "or29"
      print pick b 1
      
      
      poke b 3 [5 4]
      
      print "or30"
      print length-of pick b 3
      
      
      clear next next b
      print "or31"
      print length-of b
      print "or32"
      print pick b 3
      
      ;================ STRING =================
      
      s: "HellƩo кошка"
      
      print "or33"
      print s
      
      print "or34"
      print 123
      
      
      α: 1
      β: 2
      print "or35"
      print α + β
      
      print "or36"
      print "Χαῖρε, κόσμε!"
      
      print "or37"
      print #"a"
      
      print "or38"
      print #"α"
      
      print "or39"
      print #"a" + 1
      
      z: "Χαῖρε, κόσμε!"
      
      print "or40"
      print head? z
      
      print "or41"
      print tail? z
      
      print "or42"
      print length-of z
      
      print "or43"
      print index-of z
      
      ;--invalid UTF-8
      print "or44"
      ;print "^(D801)^(DC81)"            
      
      print "or45"
      ;print "^(10481)"              
      
      s: "toto"
      
      print "or46"
      print length-of s
      
      print "or47"
      print pick s 2
      
      print "or48"
      print pick next s 1
      
      print "or49"
      print pick next next s 1
      
      print "or50"
      print pick back next s 1
      
      print "or51"
      print length-of next next s
      
      print "or53"
      print pick at s 2 1
      
      print "or54"
      print pick skip s 2 1
      
      print "or55"
      print pick s 99
      
      print "or56"
      print pick s -99
      
      print "or57"
      print pick at next s -1 1
      
      print "or58"
      print pick skip next s -1 1
      
      print "or59"
      print pick head s 1
      
      print "or60"
      
      print pick tail s 1
      
      print "or61"
      print pick head tail s 1
      
      print "or62"
      print length-of tail s
      
      print "or63"
      print length-of head tail s
      
      print "or64"
      print index-of s
      
      print "or65"
      print index-of tail s
      
      print "or66"
      print head? s
      
      print "or67"
      print head? next s
      
      print "or68"
      print tail? s
      
      print "or69"
      print tail? tail s
      
      print "or70"
      print length-of s
      
      append s #"z"
      
      print "or71"
      print s
      
      print "or72"
      print length-of s
      
      append s [#"y" #"x"]
      
      print "or73"
      print s
      
      print "or74"
      print length-of s
      
      poke s 2 #"-"
      
      print "or75"
      print s
      
      poke at s 5 -1 #"O"
      append s #"α"
      
      print "or76"
      print s
      
      print "or77"
      print length-of s
      
      clear at s 3
      
      print "or78"
      print length-of s
      
      print "or79"
      print 1 = 2
      
      print "or80"
      print 3 <= 4
      
      print "or81"
      print 1 <> 2
      
      print "or82"
      print 8 + 1 <> 9
      
      print "or83"
      print 1 = "one"
      
      print "or84"
      print #"b" - 1 = #"a"
      
      print "or85"
      print #"d" >= #"z"
      
      print "or86"
      print #"d" < #"z"
      
      print "---IF"
      
      print "or87"
      if 1 = 2 [print "ko"]
      print "ok"
      
      print "or88"
      if 2  [print "ok"]
      
      print "or89"
      if 3 = 3 [print "ok"]
      
      print "or90"
      if 1 + 4 = 5 [print "ok"]
      
      print "or91"
      if none [print "ko"]
      print "ok"
      
      print "---EITHER"
      print "or92"
      either 1 = 2 [print "true"][print "false"]
      
      print "or93"
      either 1 + 4 = 5 [print "true"][print "false"]
      
      print "or94"
      either true [either 3 = 4 [print "ko1"][print "ok"]][print "ko2"]
      
      print "---ANY"
      print "or95"
      print any [true false]
      
      print "or96"
      print any [1 = 2  3]
      
      print "or97"
      print any [1 > 5]
      
      print "---ALL"
      
      print "or98"
      print all [true false]
      
      print "or99"
      print all [2]
      
      print "or100"
      print all [1 < 5 true 1 + 2 <= 3]
      
      c: "^(10FFFF)"
      ;c: #"^(10FFFF)"
      
      print "---APPEND"
      
      print "or101"
      print append "test" "hello"
      
      print "or102"
      print append "tαst" "hello"
      
      print "or103"
      print append "test" "hαllo"
      
      print "or104"
      print append "test" ["h" #"σ" "llo"]
      
      print "---Symbols"
      list: [test5 /test2 'test3 test6:]
      
      print "or105"
      print pick list 1
      
      print "or106"
      print pick list 2
      
      print "or107"
      print pick list 3
      
      print "or108"
      print pick list 4
      
      print integer!
      print datatype!
      
      q: [1 2 3 test [3 4] #"u" /ref]
      
      print "or109"
      print q
      
      print "---MOLD"
      
      print "or110"
      print mold q
      
      print "or111"
      print mold list
      
      print "or112"
      loop 3 [loop 1 + 1 [prin "."]]
      print
      ;loop 20'000'000 [tail? next "x"]
      
      
      print "or113"
      list: tail list
      until [
      	list: back list
      	print mold pick list 1
      	head? list
      ]
      
      print "or114"
      while [not tail? list][
      	prin mold pick list 1
      	list: next list
      ]
      prin lf
      
      print "or115"
      print z
      
      print "or116"
      print pick z 1
      
      print "or117"
      print mold pick z 1
      
      print "or118"
      repeat c 5 [prin "x"]
      
      ;-- z: "Χαῖρε, κόσμε!"
      
      print "or119"
      print newline
      foreach w z [
      	prin "char: " 
      	prin w
      	prin " cp: "
      	print 0 + w
      ]
      
      print "or120"
      foreach item head list [
      	print mold item
      ]
      
      print "or121"
      list: next head list
      forall list [
          prin mold pick list 1
      	prin #" "
      ]
      prin newline
      
      print "or122"
      print length-of list
      
    }

===start-group=== "Basic"

  --test-- "or1"
  --assert-printed? "or1^/789"
  
  --test-- "or2"
  --assert-printed? "or2^/625"  

===end-group===

===start-group=== "Block"

  --test-- "or3"
  --assert-printed? "or3^/7"

  --test-- "or4"
  --assert-printed? "or4^/11"
  
  --test-- "or5"
  --assert-printed? "or5^/7"
  
  --test-- "or6"
  --assert-printed? "or6^/9"
  
  --test-- "or7"
  --assert-printed? "or7^/4"
  
  --test-- "or8"
  --assert-printed? "or8^/7"
  
  --test-- "or9"
  --assert-printed? "or9^/5"
  
  --test-- "or10"
  --assert-printed? "or10^/1"
  
  --test-- "or11"
  --assert-printed? "or11^/7"
  
  --test-- "or12"
  --assert-printed? "or12^/9"
  
  --test-- "or13"
  --assert-printed? "or13^/none"
  
  --test-- "or14"
  --assert-printed? "or14^/none"
  
  --test-- "or15"
  --assert-printed? "or15^/4"
  
  --test-- "or16"
  --assert-printed? "or16^/4"
  
  --test-- "or17"
  --assert-printed? "or17^/0"
  
  --test-- "or18"
  --assert-printed? "or18^/7"
  
  --test-- "or19"
  --assert-printed? "or19^/1"
  
  --test-- "or20"
  --assert-printed? "or20^/8"
  
  --test-- "or21"
  --assert-printed? "or21^/true"
  
  --test-- "or22"
  --assert-printed? "or22^/false"
  
  --test-- "or23"
  --assert-printed? "or23^/false"
  
  --test-- "or24"
  --assert-printed? "or24^/true"
  
  --test-- "or25"
  --assert-printed? "or25^/8"
  
  --test-- "or26"
  --assert-printed? "or26^/123"
  
  --test-- "or27"
  --assert-printed? "or27^/11"
  
  --test-- "or28"
  --assert-printed? "or28^/8"
  
  --test-- "or29"
  --assert-printed? "or29^/66"
  
  --test-- "or30"
  --assert-printed? "or30^/2"
  
  --test-- "or31"
  --assert-printed? "or31^/2"
  
  --test-- "or32"
  --assert-printed? "or32^/none"
    
===end-group===

===start-group=== "String"

  --test-- "or33"
  --assert-printed? "or33^/" ; unicode
  
  --test-- "or34"
  --assert-printed? "or34^/123"
  
  --test-- "or35"
  --assert-printed? "or35^/3"
  
  --test-- "or36"
  --assert-printed? "or34^/" ; unicode
  
  --test-- "or37"
  --assert-printed? "or37^/a"
  
  --test-- "or38"
  --assert-printed? "or38^/" ; unicode
  
  --test-- "or39"
  --assert-printed? "or39^/b"
  
  --test-- "or40"
  --assert-printed? "or40^/" ; unicode
  
  --test-- "or41"
  --assert-printed? "or41^/" ; unicode
  
  --test-- "or42"
  --assert-printed? "or42^/13"
  
  --test-- "or43"
  --assert-printed? "or43^/1"
  
  --test-- "or44"
  --assert-printed? "or44^/" ; unicode
  
  --test-- "or45"
  --assert-printed? "or45^/" ; unicode
  
  --test-- "or46"
  --assert-printed? "or46^/4"
  
  --test-- "or47"
  --assert-printed? "or47^/o"
  
  --test-- "or48"
  --assert-printed? "or48^/o"
  
  --test-- "or49"
  --assert-printed? "or49^/t"
  
  --test-- "or50"
  --assert-printed? "or50^/t"
  
  --test-- "or51"
  --assert-printed? "or51^/2"
  
  --test-- "or52"
  ;; number skipped
  
  --test-- "or53"
  --assert-printed? "or53^/o"
  
  --test-- "or54"
  --assert-printed? "or54^/t"
  
  --test-- "or55"
  --assert-printed? "or55^/none"
  
  --test-- "or56"
  --assert-printed? "or56^/none"
  
  --test-- "or57"
  --assert-printed? "or57^/t"
  
  --test-- "or58"
  --assert-printed? "or58^/t"
  
  --test-- "or59"
  --assert-printed? "or59^/t"
  
  --test-- "or60"
  --assert-printed? "or60^/none"
  
  --test-- "or61"
  --assert-printed? "or61^/t"
  
  --test-- "or62"
  --assert-printed? "or62^/0"
  
  --test-- "or63"
  --assert-printed? "or63^/4"
  
  --test-- "or64"
  --assert-printed? "or64^/1"
  
  --test-- "or65"
  --assert-printed? "or65^/5"
  
  --test-- "or66"
  --assert-printed? "or66^/true"
  
  --test-- "or67"
  --assert-printed? "or67^/false"
  
  --test-- "or68"
  --assert-printed? "or68^/false"
  
  --test-- "or69"
  --assert-printed? "or69^/true"
  
  --test-- "or70"
  --assert-printed? "or70^/4"
  
  --test-- "or71"
  --assert-printed? "or71^/totoz"
  
  --test-- "or72"
  --assert-printed? "or72^/5"
  
  --test-- "or73"
  --assert-printed? "or73^/totozyx"
  
  --test-- "or74"
  --assert-printed? "or74^/7"
  
  --test-- "or75"
  --assert-printed? "or75^/t-tozyx"
  
  --test-- "or76"
  --assert-printed? "or76^/"  ;unicode
  
  --test-- "or77"
  --assert-printed? "or77^/8"
  
  --test-- "or78"
  --assert-printed? "or78^/2"
  
  --test-- "or79"
  --assert-printed? "or79^/false"
  
  --test-- "or80"
  --assert-printed? "or80^/true"
  
  --test-- "or81"
  --assert-printed? "or81^/true"
  
  --test-- "or82"
  --assert-printed? "or82^/false"
  
  --test-- "or83"
  --assert-printed? "or83^/false"
  
  --test-- "or84"
  --assert-printed? "or84^/true"
  
  --test-- "or85"
  --assert-printed? "or85^/false"
  
  --test-- "or86"
  --assert-printed? "or86^/true"
  
===end-group===

===start-group=== "if"

  --test-- "or87"
  --assert-printed? "or87^/ok"          
  
  --test-- "or88"
  --assert-printed? "or88^/ok"
  
  --test-- "or89"
  --assert-printed? "or89^/ok"
  
  --test-- "or90"
  --assert-printed? "or90^/ok"

  --test-- "or91"
  --assert-printed? "or91^/ok"          

===end-group===

===start-group=== "either"

  --test-- "or92"
  --assert-printed? "or92^/false"
  
  --test-- "or93"
  --assert-printed? "or93^/true"
  
  --test-- "or94"
  --assert-printed? "or94^/ok"

===end-group===

===start-group=== "any"

  --test-- "or95"
  --assert-printed? "or95^/true"
  
  --test-- "or96"
  --assert-printed? "or96^/3"
  
  --test-- "or97"
  --assert-printed? "or97^/none"

===end-group===

===start-group=== "all"

  --test-- "or98"
  --assert-printed? "or98^/none"
  
  --test-- "or99"
  --assert-printed? "or99^/2"
  
  --test-- "or100"
  --assert-printed? "or100^/true"
  
===end-group===

===start-group=== "append"
  
  --test-- "or101"
  --assert-printed? "or101^/testhello"
  
  --test-- "or102"
  --assert-printed? "or102^/"       ;; unicode
  
  --test-- "or103"
  --assert-printed? "or103^/"       ;; unicode

  --test-- "or104"
  --assert-printed? "or104^/"       ;; unicode
  
===end-group===

===start-group=== "symbols"

  --test-- "or105"
  --assert-printed? "or105^/test5"
  
  --test-- "or106"
  --assert-printed? "or106^/test2"
  
  --test-- "or107"
  --assert-printed? "or107^/test3"
  
  --test-- "or108"
  --assert-printed? "or108^/test6"
  
  --test-- "or109"
  --assert-printed? "or109^/1 2 3 test 3 4 u ref"

===end-group===

===start-group=== "mold"

  --test-- "or110"
  --assert-printed? {or110^/[1 2 3 test [3 4] #"u" /ref]}
  
  --test-- "or111"
  --assert-printed? {or111^/[test5 /test2 test3 test6:]}
  
  --test-- "or112"
  --assert-printed? "or112^/......"
  
  --test-- "or113"
  --assert-printed? {or112^/test6:^/test3^//test2^/test5}
  
  --test-- "or114"
  --assert-printed? "or114^/test5/test2test3test6:"
  
  --test-- "or115"
  --assert-printed? "or115^/"                ;; unicode
  
  --test-- "or116"
  --assert-printed? "or116^/"                ;; unicode
  
  --test-- "or117"
  --assert-printed? "or117^/"                ;; unicode
  
  --test-- "or118"
  --assert-printed? "or118^/"                ;; unicode
  
  --test-- "or119"
  --assert-printed? "or119^/"                ;; unicode
  
  --test-- "or120"
  --assert-printed? "or120^/test5^//test2^/test3^/test6:"
  
  --test-- "or121"
  --assert-printed?  "or121^//test2 test3 test6:"
  
  --test-- "or122"
  --assert-printed? "or122^/3"
  
===end-group===
  
~~~end-file~~~ 

