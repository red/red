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
      print length? b
      
      prin "or9"
      print length? next next b
      
      prin "or10"
      print length? pick b 4
      
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
      print length? tail b
      
      prin "or18"
      print length? head tail b
      
      prin "or19"
      print index? b
      
      prin "or20"
      print index? tail b
      
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
      print length? b
      
      prin "or26"
      print pick b length? b
      
      
      append b [7 8 9]
      prin "or27"
      print length? b
      prin "or28"
      print pick tail b -2
      
      
      poke b 1 66
      
      prin "or29"
      print pick b 1
      
      
      poke b 3 [5 4]
      
      prin "or30"
      print length? pick b 3
      
      
      clear next next b
      prin "or31"
      print length? b
      prin "or32"
      print pick b 3
      
      ;================ STRING =================
      
      ;s: {^(48)^(65)^(6C)^(6C)^(C6)^(A9)^(6F)^(20)^(D0)^(BA)^(D0)^(BE)^(D1)^(88)^(D0)^(BA)^(D0)^(B0)}              ;;"HellƩo кошка"
      
      ;prin "or33"
      ;print s
      
      prin "or34"
      print 123
      
      
      α: 1
      β: 2
      prin "or35"
      print α + β
      
      ;prin "or36"
      ;print {^(CE)^(A7)^(CE)^(B1)^(E1)^(BF)^(96)^(CF)^(81)^(CE)^(B5)^(2C)^(20)^(CE)^(BA)^(CF)^(8C)^(CF)^(83)^(CE)^(BC)^(CE)^(B5)^(21)}    ;"Χαῖρε, κόσμε!"
      
      prin "or37"
      print #"a"
      
      prin "or38"
      print #"α"
      
      prin "or39"
      print #"a" + 1
      
      ;z: {^(CE)^(A7)^(CE)^(B1)^(E1)^(BF)^(96)^(CF)^(81)^(CE)^(B5)^(2C)^(20)^(CE)^(BA)^(CF)^(8C)^(CF)^(83)^(CE)^(BC)^(CE)^(B5)^(21)}        ;;"Χαῖρε, κόσμε!"
      
      ;prin "or40"
      ;print head? z
      
      ;prin "or41"
      ;print tail? z
      
      ;prin "or42"
      ;print length? z
      
      ;prin "or43"
      ;print index? z
      
      ;--invalid UTF-8
      prin "or44"
      ;print "^(D801)^(DC81)"            
      
      prin "or45"
      ;print "^(10481)"              
      
      s: "toto"
      
      prin "or46"
      print length? s
      
      prin "or47"
      print pick s 2
      
      prin "or48"
      print pick next s 1
      
      prin "or49"
      print pick next next s 1
      
      prin "or50"
      print pick back next s 1
      
      prin "or51"
      print length? next next s
      
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
      print length? tail s
      
      prin "or63"
      print length? head tail s
      
      prin "or64"
      print index? s
      
      prin "or65"
      print index? tail s
      
      prin "or66"
      print head? s
      
      prin "or67"
      print head? next s
      
      prin "or68"
      print tail? s
      
      prin "or69"
      print tail? tail s
      
      prin "or70"
      print length? s
      
      append s #"z"
      
      prin "or71"
      print s
      
      prin "or72"
      print length? s
      
      append s [#"y" #"x"]
      
      prin "or73"
      print s
      
      prin "or74"
      print length? s
      
      poke s 2 #"-"
      
      prin "or75"
      print s
      
      poke at s 5 -1 #"O"
      append s #"α"
      
      prin "or76"
      print s
      
      prin "or77"
      print length? s
      
      clear at s 3
      
      prin "or78"
      print length? s
      
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
      print mold pick list 1
      
      prin "or106"
      print pick list 2
      
      prin "or107"
      print pick list 3
      
      prin "or108"
      print mold pick list 4
      
      print integer!
      print datatype!
      
      q: [1 2 3 test [3 4] #"u" /ref]
      
      prin "or109"
      print mold q
      
      print "---MOLD"
      
      prin "or110"
      print mold q
      
      prin "or111"
      print mold list
      
      prin "or112"
      loop 3 [loop 1 + 1 [prin "."]]
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
      
      ;prin "or115"
      ;print z
      
      ;prin "or116"
      ;print pick z 1
      
      ;prin "or117"
      ;print mold pick z 1
      
      prin "or118"
      repeat c 5 [prin "x"]
      
      ;z: {^(CE)^(A7)^(CE)^(B1)^(E1)^(BF)^(96)^(CF)^(81)^(CE)^(B5)^(2C)^(20)^(CE)^(BA)^(CF)^(8C)^(CF)^(83)^(CE)^(BC)^(CE)^(B5)^(21)} ;"Χαῖρε, κόσμε!"
      
      ;prin "or119"
      ;print newline
      ;foreach w z [
      	;prin "char: " 
      	;prin w
      	;prin " cp: "
      	;print 0 + w
      ;]
      
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
      print length? list
	  
	  prin "or123"
	  list: [11 #"v" 22 #"t" 33 #"z"]
	  foreach [x y] list [
		prin x
		prin #":"
		prin y
	  ]	
	  
	  print "---Paths"
	  
	  prin "or124"
	  prin mold 'a/b/c
	  z: [a/b a/b/3: :a/b/c]
	  
	  prin "or125"
	  prin mold z
	  
	  a: [x y z [3 4 5]]
	  prin "or126"
	  prin mold a/1
	  prin "or127"
	  prin mold a/4
	  prin "or128"
	  prin a/4/3

	  b: 3
	  prin "or129"
	  prin mold a/:b

	  a/2: 123
	  a/4/1: #"t"
	  b: 4
	  a/:b/2: #"x"
	  prin "or130"
	  prin mold a
      
    }
    
===start-group=== "Basic"

  --test-- "or1"
  --assert-red-printed? "or1789"
  
  --test-- "or2"
  --assert-red-printed? "or2625"  

===end-group===

===start-group=== "Block"

  --test-- "or3"
  --assert-red-printed? "or37"

  --test-- "or4"
  --assert-red-printed? "or411"
  
  --test-- "or5"
  --assert-red-printed? "or57"
  
  --test-- "or6"
  --assert-red-printed? "or69"
  
  --test-- "or7"
  --assert-red-printed? "or74"
  
  --test-- "or8"
  --assert-red-printed? "or87"
  
  --test-- "or9"
  --assert-red-printed? "or95"
  
  --test-- "or10"
  --assert-red-printed? "or101"
  
  --test-- "or11"
  --assert-red-printed? "or117"
  
  --test-- "or12"
  --assert-red-printed? "or129"
  
  --test-- "or13"
  --assert-red-printed? "or13none"
  
  --test-- "or14"
  --assert-red-printed? "or14none"
  
  --test-- "or15"
  --assert-red-printed? "or154"
  
  --test-- "or16"
  --assert-red-printed? "or164"
  
  --test-- "or17"
  --assert-red-printed? "or170"
  
  --test-- "or18"
  --assert-red-printed? "or187"
  
  --test-- "or19"
  --assert-red-printed? "or191"
  
  --test-- "or20"
  --assert-red-printed? "or208"
  
  --test-- "or21"
  --assert-red-printed? "or21true"
  
  --test-- "or22"
  --assert-red-printed? "or22false"
  
  --test-- "or23"
  --assert-red-printed? "or23false"
  
  --test-- "or24"
  --assert-red-printed? "or24true"
  
  --test-- "or25"
  --assert-red-printed? "or258"
  
  --test-- "or26"
  --assert-red-printed? "or26123"
  
  --test-- "or27"
  --assert-red-printed? "or2711"
  
  --test-- "or28"
  --assert-red-printed? "or288"
  
  --test-- "or29"
  --assert-red-printed? "or2966"
  
  --test-- "or30"
  --assert-red-printed? "or302"
  
  --test-- "or31"
  --assert-red-printed? "or312"
  
  --test-- "or32"
  --assert-red-printed? "or32none"
    
===end-group===

===start-group=== "String"

  ;--test-- "or33"
  ;--assert-red-printed? "or33HellƩo кошка" 
  
  --test-- "or34"
  --assert-red-printed? "or34123"
  
  --test-- "or35"
  --assert-red-printed? "or353"
  
  ;--test-- "or36"
  ;--assert-red-printed? "or36Χαῖρε, κόσμε!" 
  
  --test-- "or37"
  --assert-red-printed? "or37a"
  
  --test-- "or38"
  --assert-red-printed? "or38α"
  
  --test-- "or39"
  --assert-red-printed? "or39b"
  
  ;--test-- "or40"
  ;--assert-red-printed? "or40true" 
  
  ;--test-- "or41"
  ;--assert-red-printed? "or41false"
  
  ;--test-- "or42"
  ;--assert-red-printed? "or4213"
  
  ;--test-- "or43"
  ;--assert-red-printed? "or431"
  
  --test-- "or44"
  --assert-red-printed? "or44" ; unicode input not accepted
  
  --test-- "or45"
  --assert-red-printed? "or45" ; unicode input not accepted
  
  --test-- "or46"
  --assert-red-printed? "or464"
  
  --test-- "or47"
  --assert-red-printed? "or47o"
  
  --test-- "or48"
  --assert-red-printed? "or48o"
  
  --test-- "or49"
  --assert-red-printed? "or49t"
  
  --test-- "or50"
  --assert-red-printed? "or50t"
  
  --test-- "or51"
  --assert-red-printed? "or512"
  
  --test-- "or52"
  ;; number skipped
  
  --test-- "or53"
  --assert-red-printed? "or53o"
  
  --test-- "or54"
  --assert-red-printed? "or54t"
  
  --test-- "or55"
  --assert-red-printed? "or55none"
  
  --test-- "or56"
  --assert-red-printed? "or56none"
  
  --test-- "or57"
  --assert-red-printed? "or57t"
  
  --test-- "or58"
  --assert-red-printed? "or58t"
  
  --test-- "or59"
  --assert-red-printed? "or59t"
  
  --test-- "or60"
  --assert-red-printed? "or60none"
  
  --test-- "or61"
  --assert-red-printed? "or61t"
  
  --test-- "or62"
  --assert-red-printed? "or620"
  
  --test-- "or63"
  --assert-red-printed? "or634"
  
  --test-- "or64"
  --assert-red-printed? "or641"
  
  --test-- "or65"
  --assert-red-printed? "or655"
  
  --test-- "or66"
  --assert-red-printed? "or66true"
  
  --test-- "or67"
  --assert-red-printed? "or67false"
  
  --test-- "or68"
  --assert-red-printed? "or68false"
  
  --test-- "or69"
  --assert-red-printed? "or69true"
  
  --test-- "or70"
  --assert-red-printed? "or704"
  
  --test-- "or71"
  --assert-red-printed? "or71totoz"
  
  --test-- "or72"
  --assert-red-printed? "or725"
  
  --test-- "or73"
  --assert-red-printed? "or73totozyx"
  
  --test-- "or74"
  --assert-red-printed? "or747"
  
  --test-- "or75"
  --assert-red-printed? "or75t-tozyx"
  
  --test-- "or76"
  --assert-red-printed? "or76t-tOzyxα"
  
  --test-- "or77"
  --assert-red-printed? "or778"
  
  --test-- "or78"
  --assert-red-printed? "or782"
  
  --test-- "or79"
  --assert-red-printed? "or79false"
  
  --test-- "or80"
  --assert-red-printed? "or80true"
  
  --test-- "or81"
  --assert-red-printed? "or81true"
  
  --test-- "or82"
  --assert-red-printed? "or82false"
  
  --test-- "or83"
  --assert-red-printed? "or83false"
  
  --test-- "or84"
  --assert-red-printed? "or84true"
  
  --test-- "or85"
  --assert-red-printed? "or85false"
  
  --test-- "or86"
  --assert-red-printed? "or86true"
  
===end-group===

===start-group=== "if"

  --test-- "or87"
  --assert-red-printed? "or87ok"          
  
  --test-- "or88"
  --assert-red-printed? "or88ok"
  
  --test-- "or89"
  --assert-red-printed? "or89ok"
  
  --test-- "or90"
  --assert-red-printed? "or90ok"

  --test-- "or91"
  --assert-red-printed? "or91ok"          

===end-group===

===start-group=== "either"

  --test-- "or92"
  --assert-red-printed? "or92false"
  
  --test-- "or93"
  --assert-red-printed? "or93true"
  
  --test-- "or94"
  --assert-red-printed? "or94ok"

===end-group===

===start-group=== "any"

  --test-- "or95"
  --assert-red-printed? "or95true"
  
  --test-- "or96"
  --assert-red-printed? "or963"
  
  --test-- "or97"
  --assert-red-printed? "or97none"

===end-group===

===start-group=== "all"

  --test-- "or98"
  --assert-red-printed? "or98none"
  
  --test-- "or99"
  --assert-red-printed? "or992"
  
  --test-- "or100"
  --assert-red-printed? "or100true"
  
===end-group===

===start-group=== "append"
  
  --test-- "or101"
  --assert-red-printed? "or101testhello"
  
  --test-- "or102"
  --assert-red-printed? "or102"       ;; unicode
  
  --test-- "or103"
  --assert-red-printed? "or103"       ;; unicode

  --test-- "or104"
  --assert-red-printed? "or104"       ;; unicode
  
===end-group===

===start-group=== "symbols"

  --test-- "or105"
  --assert-red-printed? "or105test5"
  
  --test-- "or106"
  --assert-red-printed? "or106test2"
  
  --test-- "or107"
  --assert-red-printed? "or107test3"
  
  --test-- "or108"
  --assert-red-printed? "or108test6"
  
  --test-- "or109"
  --assert-red-printed? {or109[1 2 3 test [3 4] #"u" /ref]}

===end-group===

===start-group=== "mold"

  --test-- "or110"
  --assert-red-printed? {or110[1 2 3 test [3 4] #"u" /ref]}
  
  --test-- "or111"
  --assert-red-printed? {or111[test5 /test2 'test3 test6:]}
  
  --test-- "or112"
  --assert-red-printed? "or112......"
  
  --test-- "or113"
  --assert-red-printed? {or113test6:'test3/test2test5}
  
  --test-- "or114"
  --assert-red-printed? "or114test5/test2'test3test6:"
  
  ;--test-- "or115"
  ;--assert-red-printed? "or115Χαῖρε, κόσμε!"                
  
  ;--test-- "or116"
  ;--assert-red-printed? "or116Χ"                
  
  ;--test-- "or117"
  ;--assert-red-printed? {or117#"^(CE)"}                
  
  --test-- "or118"
  --assert-red-printed? "or118xxxxx"                
  
  ;--test-- "or119"
  ;--assert-red-printed? {char: Χ cp: 935}
  ;--assert-red-printed? {char: α cp: 945}
  ;--assert-red-printed? {char: ῖ cp: 8150}
  ;--assert-red-printed? {char: ρ cp: 961}
  ;--assert-red-printed? {char: ε cp: 949}
  ;--assert-red-printed? {char: , cp: 44}
  ;--assert-red-printed? {char:   cp: 32}
  ;--assert-red-printed? {char: κ cp: 954}
  ;--assert-red-printed? {char: ό cp: 972}
  ;--assert-red-printed? {char: σ cp: 963}
  ;--assert-red-printed? {char: μ cp: 956}
  ;--assert-red-printed? {char: ε cp: 949}
  ;--assert-red-printed? {char: ! cp: 33}
  
  --test-- "or120"
  --assert-red-printed? "or120test5/test2test3test6:"
  
  --test-- "or121"
  --assert-red-printed?  "or121/test2 'test3 test6:"
  
  --test-- "or122"
  --assert-red-printed? "or1223"

  --test-- "or123"
  --assert-red-printed? "or12311:v22:t33:z"
  
===end-group===

===start-group=== "paths"

  --test-- "or124"
  --assert-red-printed?  "or124a/b/c"
  
  --test-- "or125"
  --assert-red-printed?  "or125[a/b a/b/3: :a/b/c]"
  
  --test-- "or126"
  --assert-red-printed?  "or126x"
  
  --test-- "or127"
  --assert-red-printed?  "or127[3 4 5]"
  
  --test-- "or128"
  --assert-red-printed?  "or1285"
  
  --test-- "or129"
  --assert-red-printed?  "or129z"
  
  --test-- "or130"
  --assert-red-printed?  {or130[x 123 z [#"t" #"x" 5]]}

===end-group===
  
~~~end-file~~~ 

