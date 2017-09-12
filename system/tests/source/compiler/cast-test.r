REBOL [
	Title:   "Red/System cast test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %cast-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

compiled?: func [
  src [string!]
][
  exe: --compile-this src
  if all [
    exe
    exists? exe
  ][
    delete exe
  ]
  qt/compile-ok?
]
  

~~~start-file~~~ "cast-compile"

===start-group=== "compiler checks"

  --test-- "cast integer! 1"
  --assert compiled? {
      Red/System[]
      #"^^(00)" = as byte! 0
    }
    
  --test-- "cast logic! 1"
  --assert compiled? {
      Red/System[]
      #"^^(01)" = as byte! true
    }
    
  --test-- "cast logic! 2"
  --assert compiled? {
      Red/System[]
      #"^^(00)" = as byte! false
    }
    
  --test-- "cast c-string! 1"
  --assert compiled? {
      Red/System[]
      false = as logic! ""
   }
   
   --test-- "cast c-string! 2"
   --assert compiled? {
      Red/System[]
      csc7-struct: declare struct! [
        c1 [byte!]
        c2 [byte!]
        c3 [byte!]
        c4 [byte!]
        c5 [byte!]
      ]
      csc7-str: "Peter"
      csc7-struct: as [struct! [
        c1 [byte!] c2 [byte!] c3 [byte!] c4 [byte!] c5 [byte!]
      ]] csc7-str
    }
    
	--test-- "cast function! 1"
	--assert compiled? {
		Red/System[]
		foo: func [a [integer!]][]
		i: as integer! :foo
	}
 
 ===end-group===
 
 ===start-group=== "Warnings"
    
    warning-test: func[
      type [string!]
      src [string!]
    ][
      --test-- reform ["cast" type  "warning"]
      result: false
      result: compiled? src
      msg: "*** Warning: type casting from #type# to #type# is not necessary"
      warning: replace/all copy msg "#type#" type
       either result [
         --assert none <> find qt/comp-output warning 
       ][
          --assert result                       ;; signify failing test
          print qt/comp-output
       ]
    ]
       
    warning-test "byte!" {
        Red/System []
         b: #"A"
         #"A" = as byte! b
    }
    
    warning-test "integer!" {
        Red/System []
         i: 0
         0 = as integer! i
    }
    
    warning-test "integer!" {
        Red/System []
         1 = as integer! 1
    }
    
    warning-test "integer!" {
        Red/System []
         (as integer! 1) = 1
    }
    
    warning-test "integer!" {
        Red/System []
         print as integer! 1
    }

  --test-- "logic! warning special case"
    result: false
    result: compiled? {
      Red/System []

      l: true
      true = as logic! l
    } 
    warning: "*** Warning: type casting"
    either result [
  --assert found? find qt/comp-output warning 
    ][
      --assert result                       ;; signify failing test
      print qt/comp-output
    ]
  
    warning-test "logic!" {
        Red/System []
         l: 1 = 1
         l2: as logic! l
    }


    warning-test "c-string!" {
        Red/System []
         cs: "hello"
         cs2: as c-string! cs
    }
    
    warning-test "pointer!" {
        Red/System []
         p:  declare pointer! [integer!]
         p1: declare pointer! [integer!]
         p: as [pointer! [integer!]] 1
         p1: p
         p1 = as [pointer! [integer!]] p
    }
    
    warning-test "struct!" {
        Red/System []
         s1: declare struct! [a [integer!] b [integer!]]
         s2: declare struct! [a [integer!] b [integer!]]
         s2 = as [struct! [a [integer!] b [integer!]]] s1
    }
        
===end-group=== 

===start-group=== "Errors"
 
	--test-- "cast function! error 1"
	--compile-this {
		Red/System []
		foo: func [a [integer!]][]
		b: as byte! :foo
	}
	--assert-msg? "type casting from function! to byte! is not allowed"
	
	--test-- "cast function! error 2"
	--compile-this {
		Red/System []
		foo: func [a [integer!]][]
		l: as logic! :foo
	}
	--assert-msg? "type casting from function! to logic! is not allowed"
	
	--test-- "cast function! error 3"
	--compile-this {
		Red/System [] 
		foo: func [a [integer!]][]
		s: as c-string! :foo
	}
	--assert-msg? "type casting from function! to c-string! is not allowed"
	
	--test-- "cast byte! error 4"
	--compile-this {
		Red/System [] 
		cfe4-byte: as byte! 1.0
	}
	--assert-msg? "type casting from float! to byte! is not allowed"
	
	--test-- "cast byte! error 5"
	--compile-this {
		Red/System [] 
		cfe5-byte: as byte! "a pointer"
	}
	--assert-msg? "type casting from c-string! to byte! is not allowed"
	
	--test-- "cast byte! error 6"
	--compile-this {
	  Red/System [] 
	  cfe6-pointer: declare pointer! [integer!]
		cfe6-byte: as byte! cfe6-pointer
	}
	--assert-msg? "type casting from pointer! to byte! is not allowed"
	
	--test-- "cast float! error 9"
	--compile-this {
	  Red/System []
	  cfe9-logic: as logic! 1.0
	}
	--assert-msg? "type casting from float! to logic! is not allowed"
	
	--test-- "cast float32! error 10"
	--compile-this {
	  Red/System []
	  cfe10-logic: as logic! as float32! 1.0
	}
	--assert-msg? "type casting from float32! to logic! is not allowed"
	
	--test-- "cast byte! error 11"
	--compile-this {
	  	Red/System []
		print as byte! "a pointer"
	}
	--assert-msg? "type casting from c-string! to byte! is not allowed"
	
	--test-- "cast byte! error 12"
	--compile-this {
	  Red/System []
	  c11e6-pointer: declare pointer! [integer!]
		print as byte! c11e6-pointer
	}
	--assert-msg? "type casting from pointer! to byte! is not allowed"
	
	--test-- "cast byte! error 13"
	--compile-this {
	  Red/System []
		print as byte! 1.0
	}
	--assert-msg? "type casting from float! to byte! is not allowed"
	
	--test-- "cast logic! error 14"
	--compile-this {
	  Red/System []
		print as logic! 1.0
	}
	--assert-msg? "type casting from float! to logic! is not allowed"
	      
~~~end-file~~~

