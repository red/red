Red [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %logic-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "logic"

===start-group=== "literal logic! value tests"

  --test-- "llv-1"
  --assert true
  
  --test-- "llv-2"
  --assert not false
===end-group===
  
===start-group=== "logic variable tests"
  --test-- "lv-1"
    a: true
  --assert a
  
  --test-- "lv-2"
    a: false
  --assert not a
===end-group===

===start-group=== "conditional expression assignment tests"
  --test-- "lce-1"
    a: 3 < 5
  --assert a
  
  --test-- "lce-2"
    a: 1 = 2
  --assert not a
===end-group===
  
===start-group=== "logic value as last conditional expression in UNTIL tests"
  --test-- "lu-1"
    a: true
    i: 0
    until [
      i: i + 1
      a
    ]
  --assert i = 1
  
  --test-- "lu-2"
    i: 0
    c: 3
    stop?: false
    until [
      i: i + 1
      c: c - 1
      if 0 = c [stop?: true]
      stop?
    ]
  --assert c = 0
  --assert i = 3
===end-group===

===start-group=== "logic value as conditional expression in WHILE tests"
  --test-- "lw-1"
    a: false
    i: 0 
    while [a][i: i + 1]
  --assert i = 0

  --test-- "lw-2"
    i: 0
    c: 3
    run?: true
    while [run?][
      i: i + 1
      c: c - 1
      if 0 = c [run?: false]
    ]
  --assert c = 0
  --assert i = 3
===end-group===

===start-group=== "passing logic! as function's argument tests"
    log-foo: func [a [logic!] return: [logic!]][a]

  --test-- "logic-arg-1"    
  --assert log-foo true

  --test-- "logic-arg-2" 
  --assert not log-foo false

  --test-- "logic-arg-3" 
  --assert log-foo 1 < 2
  
  --test-- "logic-arg-4"
  --assert log-foo 3 <> 4
  
  --test-- "logic-arg-5"
  --assert log-foo (1 + 1 < 3)
  
  --test-- "logic-arg-6"
    a: false
    if false = log-foo (2 + 2 = 5) [a: true]
  --assert a
  
  --test-- "logic-arg-7"
  --assert not log-foo 3 = 4

===end-group===

===start-group=== "all with logic!"

  --test-- "logic-all-1"
    result:  all [
      true
      true
    ]
  --assert result

  --test-- "logic-all-2"
    result: all [
      false
      true
    ]
  --assert not result

  --test-- "logic-all-3"
    result all [
      true
      false
    ]
  --assert not result

  --test-- "logic-all-4"
    result: all [
      false
      false
    ]
  --assert not result
  
  --test-- "logic-all-5"
    a: all [true]
  --assert a

  --test-- "logic-all-6"
    a: all [false]
  --assert not a

  --test-- "logic-all-7"
    a: all [1 < 2 false]
  --assert not a

  --test-- "logic-all-8"
    a: all [false 1 < 2]
  --assert not a

  --test-- "logic-all-9"
    a: all [true 1 = 2]
  --assert not a

  --test-- "logic-all-10"
    a: all [1 = 2 true]
  --assert not a
  
  --test-- "logic-all-11"
    a: all [1 < 2]
  --assert a
  
  --test-- "logic-all-12"
    a: all [1 = 2]
  --assert not a
  
  --test-- "logic-all-13"
    a: all [1 < 2 3 <> 4]
  --assert a

  --test-- "logic-all-14"
    a: all [1 = 2 3 <> 4]
  --assert not a
  
  --test-- "logic-all-15"
  --assert not log-foo make logic! all [1 = 2]
   
  --test-- "logic-all-16"
  --assert log-foo all [1 < 2 3 <> 4]
  
  --test-- "logic-all-17"
  --assert not log-foo make logic! all [1 = 2 3 <> 4]

  --test-- "logic-all-18"
    a: log-foo all [1 < 2]
  --assert a 
 
  --test-- "logic-all-19"
    a: log-foo make logic! all [1 = 2]
  --assert not a
  
  --test-- "logic-all-20"
    a: log-foo all [1 < 2 3 <> 4]
  --assert a

  --test-- "logic-all-21"
      a: all [log-foo true]
  --assert a
  
===end-group===

===start-group=== "any with logic!"

  --test-- "logic-any-1"
    result: any [
      true
      true
    ]
  --assert result
  
  --test-- "logic-any-2"
    result: any [
      false
      true
    ]
  --assert result

  --test-- "logic-any-3"
    result: any [
      true
      false
    ]
  --assert result
  
  --test-- "logic-any-4"
    result: any [
      false
      false
    ]
  --assert not result
  
  --test-- "logic-any-5"
    a: any [true]
  --assert a

  --test-- "logic-any-6"
    a: any [false]
  --assert not a

  --test-- "logic-any-7"
    a: any [1 < 2 false]
  --assert a

  --test-- "logic-any-8"
    a: any [false 1 < 2]
  --assert a
 
  --test-- "logic-any-9"
    a: any [true 1 = 2]
  --assert a

  --test-- "logic-any-10"
    a: any [1 = 2 true]
  --assert a

  --test-- "logic-any-11"
  a: any [1 < 2]
  --assert a

  --test-- "logic-any-12"
    a: any [1 = 2]
  --assert not a
  
  --test-- "logic-any-13"
    a: any [1 < 2 3 <> 4]
  --assert a
 
  --test-- "logic-any-14"
    a: any [1 = 2 3 <> 4]
  --assert a
  
  --test-- "logic-any-15"
  --assert none = any [1 = 2]
  
  --test-- "logic-any-16"
  --assert log-foo any [1 < 2 3 <> 4]
  
  --test-- "logic-any-17"
  --assert log-foo any [1 = 2 3 <> 4]
  
  --test-- "logic-any-18"
    a: log-foo any [1 < 2]
  --assert a 

  --test-- "logic-any-19"
    a: log-foo (none <> any [1 = 2])
  --assert not a 

  --test-- "logic-any-20"
    a: log-foo any [1 < 2 3 <> 4]
  --assert a
  
  --test-- "logic-any-21"
    a: any [log-foo true]
  --assert a

===end-group===

===start-group=== "function returning a logic value"
    lgc-test?: func [
      return: [logic!]
    ][
      either 1 < 2 [true] [false]
    ]

  --test-- "logic-return-1" 
  --assert lgc-test?

  --test-- "logic-return-2"
    a: lgc-test?
  --assert a

    lgc-test2?: func [
      return: [logic!]
    ][
      either 1 = 2 [true] [false]
    ]

  --test-- "logic-return-3"
  --assert not lgc-test2?

  --test-- "logic-return-4"
    a: lgc-test2?
  --assert not a
  
	lgc-test3?: func [return: [logic!]][
		either true [
			1 = 3
		][
			false
		]
	]
	
 --test-- "logic-return-5"
 --assert not lgc-test3?
 
	lgc-test4?: func [return: [logic!]][
		either false [
			1 = 3
		][
			false
		]
	]
	
 --test-- "logic-return-6"
 --assert not lgc-test4?
 
	lgc-test5?: func [return: [logic!]][
		either 1 < 2 [true] [false]
	]

 --test-- "logic-return-7"
 --assert lgc-test5?

===end-group===

===start-group=== "equality lgc-tests"

  --test-- "logic-=-1"
    a: false
  --assert a = false

  --test-- "logic-=-2"
    a: true
  --assert not a = false

  --test-- "logic-=-3"
    a: false
  --assert not a <> false

  --test-- "logic-=-4"
    a: true
  --assert a <> false

  --test-- "logic-=-5"
    a: false
    b: a = false
  --assert b
  
  --test-- "logic-=-6"
    a: true
    b: a = false
  --assert not b

  --test-- "logic-=-7"
    a: false
    b: false <> a
  --assert not b

  --test-- "logic-=-8"
    a: true
    b: false <> a
  --assert b
  
  --test-- "logic-=-9"
    a: false
  --assert log-foo a = false
  
  --test-- "logic-=-10"
    a: false
  --assert log-foo a = false
  
  --test-- "logic-=-11"
    a: true
  --assert not log-foo a = false
  
===end-group===

===start-group=== "logic value returned by function"

	fooT: func [return: [logic!]][1 < 2]
	fooF: func [return: [logic!]][1 = 2]

	--test-- "logic-ret-1" --assert fooT
	--test-- "logic-ret-2" --assert not fooF

===end-group===

===start-group=== "complemented"

	--test-- "comp-1" --assert true  = complement false
	--test-- "comp-2" --assert false = complement true

===end-group===

===start-group=== "and"
	--test-- "and1" --assert true  and true  =  true
	--test-- "and2" --assert true  and false =  false
	--test-- "and3" --assert false and true  =  false
	--test-- "and4" --assert false and false =  false
===end-group===

===start-group=== "or"
	--test-- "or1" --assert  true  or false  =  true
	--test-- "or2" --assert  false or true   =  true
	--test-- "or3" --assert  false or false  =  false
	--test-- "or4" --assert  true  or true   =  true
===end-group===

===start-group=== "xor"
	--test-- "xor1" --assert true  xor false =  true
	--test-- "xor2" --assert false xor true  =  true
	--test-- "xor3" --assert true  xor true  =  false
	--test-- "xor4" --assert false xor false =  false
===end-group===

===start-group=== "logic! values remember their source word"

	;-- FORM and MOLD give back the word the value was written as
	--test-- "lw-1"  --assert "true"  = mold true
	--test-- "lw-2"  --assert "false" = mold false
	--test-- "lw-3"  --assert "on"    = mold on
	--test-- "lw-4"  --assert "off"   = mold off
	--test-- "lw-5"  --assert "yes"   = mold yes
	--test-- "lw-6"  --assert "no"    = mold no

	--test-- "lw-7"  --assert "true"  = form true
	--test-- "lw-8"  --assert "false" = form false
	--test-- "lw-9"  --assert "on"    = form on
	--test-- "lw-10" --assert "off"   = form off
	--test-- "lw-11" --assert "yes"   = form yes
	--test-- "lw-12" --assert "no"    = form no

	--test-- "lw-13" --assert "#(true)"  = mold/all true
	--test-- "lw-14" --assert "#(false)" = mold/all false
	--test-- "lw-15" --assert "#(on)"    = mold/all on
	--test-- "lw-16" --assert "#(off)"   = mold/all off
	--test-- "lw-17" --assert "#(yes)"   = mold/all yes
	--test-- "lw-18" --assert "#(no)"    = mold/all no

	;-- construction syntax round-trips through the runtime lexer.
	;-- LOAD is used rather than literal #(on) because the toolchain's own
	;-- lexer does not know the new words yet.
	--test-- "lw-19" --assert "true"  = mold load "#(true)"
	--test-- "lw-20" --assert "false" = mold load "#(false)"
	--test-- "lw-21" --assert "on"    = mold load "#(on)"
	--test-- "lw-22" --assert "off"   = mold load "#(off)"
	--test-- "lw-23" --assert "yes"   = mold load "#(yes)"
	--test-- "lw-24" --assert "no"    = mold load "#(no)"

	--test-- "lw-25" --assert logic? load "#(on)"
	--test-- "lw-26" --assert load "#(on)"
	--test-- "lw-27" --assert not load "#(off)"

	;-- construction syntax is case-insensitive, as it already was for TRUE/FALSE
	--test-- "lw-28" --assert "on"  = mold load "#(ON)"
	--test-- "lw-29" --assert "no"  = mold load "#(No)"
	--test-- "lw-30" --assert "yes" = mold load "#(YeS)"

	;-- the other construction words are unaffected. NO must not shadow NONE,
	;-- and NONE must not swallow NO, since the words share a prefix.
	--test-- "lw-31" --assert none?  load "#(none)"
	--test-- "lw-32" --assert unset? load "#(unset)"
	--test-- "lw-33" --assert integer! = load "#(integer!)"
	--test-- "lw-34" --assert string!  = load "#(string!)"

	;-- partial and unknown words are still rejected
	--test-- "lw-35" --assert error? try [load "#(n)"]
	--test-- "lw-36" --assert error? try [load "#(o)"]
	--test-- "lw-37" --assert error? try [load "#(non)"]
	--test-- "lw-38" --assert error? try [load "#(nones)"]
	--test-- "lw-39" --assert error? try [load "#(ye)"]
	--test-- "lw-40" --assert error? try [load "#(offs)"]
	--test-- "lw-41" --assert error? try [load "#(nope)"]

	;-- the remembered word carries no meaning: equality ignores it
	--test-- "lw-42" --assert on  =  true
	--test-- "lw-43" --assert off =  false
	--test-- "lw-44" --assert yes =  on
	--test-- "lw-45" --assert no  =  off
	--test-- "lw-46" --assert on  == true
	--test-- "lw-47" --assert same? on true
	--test-- "lw-48" --assert on  <> off
	--test-- "lw-49" --assert (find reduce [on] true) <> none

	;-- and no effect on truthiness
	--test-- "lw-50" --assert "on-branch" = either on ["on-branch"]["off-branch"]
	--test-- "lw-51" --assert "no-branch" = either no ["yes-branch"]["no-branch"]

	;-- values derived from a remembered one fall back to TRUE/FALSE
	--test-- "lw-52" --assert "false" = mold not on
	--test-- "lw-53" --assert "true"  = mold not off
	--test-- "lw-54" --assert "false" = mold not yes
	--test-- "lw-55" --assert "false" = mold complement on
	--test-- "lw-56" --assert "true"  = mold complement off
	--test-- "lw-57" --assert "true"  = mold (on and yes)
	--test-- "lw-58" --assert "true"  = mold (off or yes)
	--test-- "lw-59" --assert "true"  = mold (on xor off)
	--test-- "lw-60" --assert "true"  = mold (1 = 1)
	--test-- "lw-61" --assert "false" = mold (1 = 2)
	--test-- "lw-62" --assert "true"  = mold logic? on

	;-- TO conversions follow the remembered word
	--test-- "lw-63" --assert 'true = to word! true
	--test-- "lw-64" --assert 'on   = to word! on
	--test-- "lw-65" --assert 'off  = to word! off
	--test-- "lw-66" --assert 'yes  = to word! yes
	--test-- "lw-67" --assert 'no   = to word! no
	--test-- "lw-68" --assert "on"  = to string! on
	--test-- "lw-69" --assert "no"  = to string! no
	--test-- "lw-70" --assert "false" = to string! false

	;-- MAKE and TO LOGIC! produce plain TRUE/FALSE
	--test-- "lw-71" --assert "true"  = mold make logic! 1
	--test-- "lw-72" --assert "false" = mold make logic! 0
	--test-- "lw-73" --assert "true"  = mold to logic! 1

	;-- the word survives being carried around in a series
	--test-- "lw-74" --assert "[on off yes no]" = mold reduce [on off yes no]
	--test-- "lw-75" --assert "[#(on) #(no)]"   = mold/all reduce [on no]
	--test-- "lw-76" --assert "on" = mold first reduce [on]
	--test-- "lw-77"
		blk: copy []
		append blk on
	--assert "[on]" = mold blk
	--test-- "lw-78" --assert "on" = mold load mold on
	--test-- "lw-79" --assert "on" = mold load mold/all on

===end-group===

~~~end-file~~~
