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
      prin "or1"
      print 789
      
      prin "or2"
      a: 123
      a: a + 2
      print a * 6 - a
    
    
      ;================ BLOCK =================

      b: [4 7 9 [11] test /ref 'red]
      
      prin "or3"
      print pick b 2
      
      prin "or4"
      print pick pick b 4 1
      
      prin "or5"
      print pick next b 1
      
      prin "or6"
      print pick next next b 1
      prin "or7"
      print pick back next b 1
      
      prin "or8"
      print length-of b
      
      prin "or9"
      print length-of next next b
      
      prin "or10"
      print length-of pick b 4
      
      prin "or11"
      print pick at b 2 1
      
      prin "or12"
      print pick skip b 2 1
      
      prin "or13"
      print pick b 99
      
      prin "or14"
      print pick b -99
      
      prin "or15"
      print pick at next b -1 1
      
      prin "or16"
      print pick skip next b -1 1
      
      prin "or17"
      print length-of tail b
      
      prin "or18"
      print length-of head tail b
      
      prin "or19"
      print index-of b
      
      prin "or20"
      print index-of tail b
      
      prin "or21"
      print head? b
      
      prin "or22"
      print head? next b
      
      prin "or23"
      print tail? b
      
      prin "or24"
      print tail? tail b
      
 
      append b 123
      prin "or25"
      print length-of b
      
      prin "or26"
      print pick b length-of b
      
      
      append b [7 8 9]
      prin "or27"
      print length-of b
      prin "or28"
      print pick tail b -2
      
      
      poke b 1 66
      
      prin "or29"
      print pick b 1
      
      
      poke b 3 [5 4]
      
      prin "or30"
      print length-of pick b 3
      
      
      clear next next b
      prin "or31"
      print length-of b
      prin "or32"
      print pick b 3
      
      ;================ STRING =================
      
      s: "HellƩo кошка"
      
      prin "or33"
      print s
      
      prin "or34"
      print 123
      
      
      α: 1
      β: 2
      prin "or35"
      print α + β
      
      prin "or36"
      print "Χαῖρε, κόσμε!"
      
      prin "or37"
      print #"a"
      
      prin "or38"
      print #"α"
      
      prin "or39"
      print #"a" + 1
      
      z: "Χαῖρε, κόσμε!"
      
      prin "or40"
      print head? z
      
      prin "or41"
      print tail? z
      
      prin "or42"
      print length-of z
      
      prin "or43"
      print index-of z
      
      ;--invalid UTF-8
      prin "or44"
      ;print "^(D801)^(DC81)"            
      
      prin "or45"
      ;print "^(10481)"              
      
      s: "toto"
      
      prin "or46"
      print length-of s
      
      prin "or47"
      print pick s 2
      
      prin "or48"
      print pick next s 1
      
      prin "or49"
      print pick next next s 1
      
      prin "or50"
      print pick back next s 1
      
      prin "or51"
      print length-of next next s
      
      prin "or53"
      print pick at s 2 1
      
      prin "or54"
      print pick skip s 2 1
      
      prin "or55"
      print pick s 99
      
      prin "or56"
      print pick s -99
      
      prin "or57"
      print pick at next s -1 1
      
      prin "or58"
      print pick skip next s -1 1
      
      prin "or59"
      print pick head s 1
      
      prin "or60"
      
      print pick tail s 1
      
      prin "or61"
      print pick head tail s 1
      
      prin "or62"
      print length-of tail s
      
      prin "or63"
      print length-of head tail s
      
      prin "or64"
      print index-of s
      
      prin "or65"
      print index-of tail s
      
      prin "or66"
      print head? s
      
      prin "or67"
      print head? next s
      
      prin "or68"
      print tail? s
      
      prin "or69"
      print tail? tail s
      
      prin "or70"
      print length-of s
      
      append s #"z"
      
      prin "or71"
      print s
      
      prin "or72"
      print length-of s
      
      append s [#"y" #"x"]
      
      prin "or73"
      print s
      
      prin "or74"
      print length-of s
      
      poke s 2 #"-"
      
      prin "or75"
      print s
      
      poke at s 5 -1 #"O"
      append s #"α"
      
      prin "or76"
      print s
      
      prin "or77"
      print length-of s
      
      clear at s 3
      
      prin "or78"
      print length-of s
      
      prin "or79"
      print 1 = 2
      
      prin "or80"
      print 3 <= 4
      
      prin "or81"
      print 1 <> 2
      
      prin "or82"
      print 8 + 1 <> 9
      
      prin "or83"
      print 1 = "one"
      
      prin "or84"
      print #"b" - 1 = #"a"
      
      prin "or85"
      print #"d" >= #"z"
      
      prin "or86"
      print #"d" < #"z"
      
      print "---IF"
      
      prin "or87"
      if 1 = 2 [print "ko"]
      print "ok"
      
      prin "or88"
      if 2  [print "ok"]
      
      prin "or89"
      if 3 = 3 [print "ok"]
      
      prin "or90"
      if 1 + 4 = 5 [print "ok"]
      
      prin "or91"
      if none [print "ko"]
      print "ok"
      
      print "---EITHER"
      prin "or92"
      either 1 = 2 [print "true"][print "false"]
      
      prin "or93"
      either 1 + 4 = 5 [print "true"][print "false"]
      
      prin "or94"
      either true [either 3 = 4 [print "ko1"][print "ok"]][print "ko2"]
      
      print "---ANY"
      prin "or95"
      print any [true false]
      
      prin "or96"
      print any [1 = 2  3]
      
      prin "or97"
      print any [1 > 5]
      
      print "---ALL"
      
      prin "or98"
      print all [true false]
      
      prin "or99"
      print all [2]
      
      prin "or100"
      print all [1 < 5 true 1 + 2 <= 3]
      
      c: "^(10FFFF)"
      ;c: #"^(10FFFF)"
      
      print "---APPEND"
      
      prin "or101"
      print append "test" "hello"
      
      prin "or102"
      print append "tαst" "hello"
      
      prin "or103"
      print append "test" "hαllo"
      
      prin "or104"
      print append "test" ["h" #"σ" "llo"]
      
      print "---Symbols"
      list: [test5 /test2 'test3 test6:]
      
      prin "or105"
      print pick list 1
      
      prin "or106"
      print pick list 2
      
      prin "or107"
      print pick list 3
      
      prin "or108"
      print pick list 4
      
      print integer!
      print datatype!
      
      q: [1 2 3 test [3 4] #"u" /ref]
      
      prin "or109"
      print q
      
      print "---MOLD"
      
      prin "or110"
      print mold q
      
      prin "or111"
      print mold list
      
      prin "or112"
      loop 3 [loop 1 + 1 [prin "."]]
      print
      ;loop 20'000'000 [tail? next "x"]
      
      
      prin "or113"
      list: tail list
      until [
      	list: back list
      	prin mold pick list 1
      	head? list
      ]
      
      
      prin "or114"
      while [not tail? list][
      	prin mold pick list 1
      	list: next list
      ]
      prin lf
      
      prin "or115"
      print z
      
      prin "or116"
      print pick z 1
      
      prin "or117"
      print mold pick z 1
      
      prin "or118"
      repeat c 5 [prin "x"]
      
      ;-- z: "Χαῖρε, κόσμε!"
      
      prin "or119"
      print newline
      foreach w z [
      	prin "char: " 
      	prin w
      	prin " cp: "
      	print 0 + w
      ]
      
      prin "or120"
      foreach item head list [
      	prin mold item
      ]
      
      prin "or121"
      list: next head list
      forall list [
          prin mold pick list 1
      	prin #" "
      ]
      prin newline
      
      prin "or122"
      print length-of list
      
    }
    
    ;; Windows console output is UTF-16LE for Red programs
    ;; We need to remove the #"^(00)" chars from the output so
    ;; that the tests will run cross-platform
    
    replace/all qt/output "^(00)" ""

===start-group=== "Basic"

  --test-- "or1"
  --assert-printed? "or1789"
  
  --test-- "or2"
  --assert-printed? "or2625"  

===end-group===

===start-group=== "Block"

  --test-- "or3"
  --assert-printed? "or37"

  --test-- "or4"
  --assert-printed? "or411"
  
  --test-- "or5"
  --assert-printed? "or57"
  
  --test-- "or6"
  --assert-printed? "or69"
  
  --test-- "or7"
  --assert-printed? "or74"
  
  --test-- "or8"
  --assert-printed? "or87"
  
  --test-- "or9"
  --assert-printed? "or95"
  
  --test-- "or10"
  --assert-printed? "or101"
  
  --test-- "or11"
  --assert-printed? "or117"
  
  --test-- "or12"
  --assert-printed? "or129"
  
  --test-- "or13"
  --assert-printed? "or13none"
  
  --test-- "or14"
  --assert-printed? "or14none"
  
  --test-- "or15"
  --assert-printed? "or154"
  
  --test-- "or16"
  --assert-printed? "or164"
  
  --test-- "or17"
  --assert-printed? "or170"
  
  --test-- "or18"
  --assert-printed? "or187"
  
  --test-- "or19"
  --assert-printed? "or191"
  
  --test-- "or20"
  --assert-printed? "or208"
  
  --test-- "or21"
  --assert-printed? "or21true"
  
  --test-- "or22"
  --assert-printed? "or22false"
  
  --test-- "or23"
  --assert-printed? "or23false"
  
  --test-- "or24"
  --assert-printed? "or24true"
  
  --test-- "or25"
  --assert-printed? "or258"
  
  --test-- "or26"
  --assert-printed? "or26123"
  
  --test-- "or27"
  --assert-printed? "or2711"
  
  --test-- "or28"
  --assert-printed? "or288"
  
  --test-- "or29"
  --assert-printed? "or2966"
  
  --test-- "or30"
  --assert-printed? "or302"
  
  --test-- "or31"
  --assert-printed? "or312"
  
  --test-- "or32"
  --assert-printed? "or32none"
    
===end-group===

===start-group=== "String"

  --test-- "or33"
  --assert-printed? "or33" ; unicode
  
  --test-- "or34"
  --assert-printed? "or34123"
  
  --test-- "or35"
  --assert-printed? "or353"
  
  --test-- "or36"
  --assert-printed? "or34" ; unicode
  
  --test-- "or37"
  --assert-printed? "or37a"
  
  --test-- "or38"
  --assert-printed? "or38" ; unicode
  
  --test-- "or39"
  --assert-printed? "or39b"
  
  --test-- "or40"
  --assert-printed? "or40" ; unicode
  
  --test-- "or41"
  --assert-printed? "or41" ; unicode
  
  --test-- "or42"
  --assert-printed? "or4213"
  
  --test-- "or43"
  --assert-printed? "or431"
  
  --test-- "or44"
  --assert-printed? "or44" ; unicode
  
  --test-- "or45"
  --assert-printed? "or45" ; unicode
  
  --test-- "or46"
  --assert-printed? "or464"
  
  --test-- "or47"
  --assert-printed? "or47o"
  
  --test-- "or48"
  --assert-printed? "or48o"
  
  --test-- "or49"
  --assert-printed? "or49t"
  
  --test-- "or50"
  --assert-printed? "or50t"
  
  --test-- "or51"
  --assert-printed? "or512"
  
  --test-- "or52"
  ;; number skipped
  
  --test-- "or53"
  --assert-printed? "or53o"
  
  --test-- "or54"
  --assert-printed? "or54t"
  
  --test-- "or55"
  --assert-printed? "or55none"
  
  --test-- "or56"
  --assert-printed? "or56none"
  
  --test-- "or57"
  --assert-printed? "or57t"
  
  --test-- "or58"
  --assert-printed? "or58t"
  
  --test-- "or59"
  --assert-printed? "or59t"
  
  --test-- "or60"
  --assert-printed? "or60none"
  
  --test-- "or61"
  --assert-printed? "or61t"
  
  --test-- "or62"
  --assert-printed? "or620"
  
  --test-- "or63"
  --assert-printed? "or634"
  
  --test-- "or64"
  --assert-printed? "or641"
  
  --test-- "or65"
  --assert-printed? "or655"
  
  --test-- "or66"
  --assert-printed? "or66true"
  
  --test-- "or67"
  --assert-printed? "or67false"
  
  --test-- "or68"
  --assert-printed? "or68false"
  
  --test-- "or69"
  --assert-printed? "or69true"
  
  --test-- "or70"
  --assert-printed? "or704"
  
  --test-- "or71"
  --assert-printed? "or71totoz"
  
  --test-- "or72"
  --assert-printed? "or725"
  
  --test-- "or73"
  --assert-printed? "or73totozyx"
  
  --test-- "or74"
  --assert-printed? "or747"
  
  --test-- "or75"
  --assert-printed? "or75t-tozyx"
  
  --test-- "or76"
  --assert-printed? "or76"  ;unicode
  
  --test-- "or77"
  --assert-printed? "or778"
  
  --test-- "or78"
  --assert-printed? "or782"
  
  --test-- "or79"
  --assert-printed? "or79false"
  
  --test-- "or80"
  --assert-printed? "or80true"
  
  --test-- "or81"
  --assert-printed? "or81true"
  
  --test-- "or82"
  --assert-printed? "or82false"
  
  --test-- "or83"
  --assert-printed? "or83false"
  
  --test-- "or84"
  --assert-printed? "or84true"
  
  --test-- "or85"
  --assert-printed? "or85false"
  
  --test-- "or86"
  --assert-printed? "or86true"
  
===end-group===

===start-group=== "if"

  --test-- "or87"
  --assert-printed? "or87ok"          
  
  --test-- "or88"
  --assert-printed? "or88ok"
  
  --test-- "or89"
  --assert-printed? "or89ok"
  
  --test-- "or90"
  --assert-printed? "or90ok"

  --test-- "or91"
  --assert-printed? "or91ok"          

===end-group===

===start-group=== "either"

  --test-- "or92"
  --assert-printed? "or92false"
  
  --test-- "or93"
  --assert-printed? "or93true"
  
  --test-- "or94"
  --assert-printed? "or94ok"

===end-group===

===start-group=== "any"

  --test-- "or95"
  --assert-printed? "or95true"
  
  --test-- "or96"
  --assert-printed? "or963"
  
  --test-- "or97"
  --assert-printed? "or97none"

===end-group===

===start-group=== "all"

  --test-- "or98"
  --assert-printed? "or98none"
  
  --test-- "or99"
  --assert-printed? "or992"
  
  --test-- "or100"
  --assert-printed? "or100true"
  
===end-group===

===start-group=== "append"
  
  --test-- "or101"
  --assert-printed? "or101testhello"
  
  --test-- "or102"
  --assert-printed? "or102"       ;; unicode
  
  --test-- "or103"
  --assert-printed? "or103"       ;; unicode

  --test-- "or104"
  --assert-printed? "or104"       ;; unicode
  
===end-group===

===start-group=== "symbols"

  --test-- "or105"
  --assert-printed? "or105test5"
  
  --test-- "or106"
  --assert-printed? "or106test2"
  
  --test-- "or107"
  --assert-printed? "or107test3"
  
  --test-- "or108"
  --assert-printed? "or108test6"
  
  --test-- "or109"
  --assert-printed? "or1091 2 3 test 3 4 u ref"

===end-group===

===start-group=== "mold"

  --test-- "or110"
  --assert-printed? {or110[1 2 3 test [3 4] #"u" /ref]}
  
  --test-- "or111"
  --assert-printed? {or111[test5 /test2 'test3 test6:]}
  
  --test-- "or112"
  --assert-printed? "or112......"
  
  --test-- "or113"
  --assert-printed? {or113test6:'test3/test2test5}
  
  --test-- "or114"
  --assert-printed? "or114test5/test2'test3test6:"
  
  --test-- "or115"
  --assert-printed? "or115"                ;; unicode
  
  --test-- "or116"
  --assert-printed? "or116"                ;; unicode
  
  --test-- "or117"
  --assert-printed? "or117"                ;; unicode
  
  --test-- "or118"
  --assert-printed? "or118"                ;; unicode
  
  --test-- "or119"
  --assert-printed? "or119"                ;; unicode
  
  --test-- "or120"
  --assert-printed? "or120test5/test2'test3test6:"
  
  --test-- "or121"
  --assert-printed?  "or121/test2 'test3 test6:"
  
  --test-- "or122"
  --assert-printed? "or1223"
  
===end-group===
  
~~~end-file~~~ 

