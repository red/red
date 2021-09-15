Red/System [
	Title:   "Red/System manual test of floating point number relations"
	Author:  "@hiiamboris"
	File: 	 %float-matrix-manual.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;; NOTE:
;; this is the lowest level test of NaN operations
;; it is intended to have as simple logic as possible to keep branching at a minimum
;; test succeeds if it produces the following output (use tab size=8 to see it aligned):
comment {
operands:	-1.0	1.0	1.#INF	-1.#INF	-1.#IND	

-1.0	-1.0	<=true	<false	=true	<>false	>false	>=true	101001	<= IF E1 C1 	<  UL IN E2 C2 	=  IF E1 C1 	<> UL IN E2 C2 	 > UL IN E2 C2 	>= IF E1 C1 
-1.0	1.0	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.0	1.#INF	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.0	-1.#INF	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
-1.0	-1.#IND	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 

1.0	-1.0	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
1.0	1.0	<=true	<false	=true	<>false	>false	>=true	101001	<= IF E1 C1 	<  UL IN E2 C2 	=  IF E1 C1 	<> UL IN E2 C2 	 > UL IN E2 C2 	>= IF E1 C1 
1.0	1.#INF	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
1.0	-1.#INF	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
1.0	-1.#IND	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 

1.#INF	-1.0	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
1.#INF	1.0	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
1.#INF	1.#INF	<=true	<false	=true	<>false	>false	>=true	101001	<= IF E1 C1 	<  UL IN E2 C2 	=  IF E1 C1 	<> UL IN E2 C2 	 > UL IN E2 C2 	>= IF E1 C1 
1.#INF	-1.#INF	<=false	<false	=false	<>true	>true	>=true	000111	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > IF E1 C1 	>= IF E1 C1 
1.#INF	-1.#IND	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 

-1.#INF	-1.0	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#INF	1.0	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#INF	1.#INF	<=true	<true	=false	<>true	>false	>=false	110100	<= IF E1 C1 	<  IF E1 C1 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#INF	-1.#INF	<=true	<false	=true	<>false	>false	>=true	101001	<= IF E1 C1 	<  UL IN E2 C2 	=  IF E1 C1 	<> UL IN E2 C2 	 > UL IN E2 C2 	>= IF E1 C1 
-1.#INF	-1.#IND	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 

-1.#IND	-1.0	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#IND	1.0	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#IND	1.#INF	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#IND	-1.#INF	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
-1.#IND	-1.#IND	<=false	<false	=false	<>true	>false	>=false	000100	<= UL IN E2 C2 	<  UL IN E2 C2 	=  UL IN E2 C2 	<> IF E1 C1 	 > UL IN E2 C2 	>= UL IN E2 C2 
}

blk: [-1.0 1.0 0.0 0.0 0.0]
f: as float-ptr! blk

f/3:  1.0 / 0.0
f/4: -1.0 / 0.0
f/5:  0.0 / 0.0

print "operands:^-"
f': f loop SIZE?(blk) [
	print [f'/1 "^-"]
	f': f' + 1
]
print [lf lf]

a: f  b: f  x: 0.0 y: 0.0
i1: 0 i2: 0 i3: 0 i4: 0 i5: 0 i6: 0
b1: no b2: no b3: no b4: no b5: no b6: no
loop SIZE?(blk) [
	b: f
	loop SIZE?(blk) [
		x: a/1  y: b/1
		print [x "^-" y "^-"]

		b1: x <= y
		b2: x <  y
		b3: x =  y
		b4: x <> y
		b5: x  > y
		b6: x >= y
		print ["<=" b1 "^-<" b2 "^-=" b3 "^-<>" b4 "^->" b5 "^->=" b6 "^-"]

		i1: as integer! x <= y
		i2: as integer! x <  y
		i3: as integer! x =  y
		i4: as integer! x <> y
		i5: as integer! x  > y
		i6: as integer! x >= y
		print [i1 i2 i3 i4 i5 i6]

		print "^-<= "
		if     x <= y [print "IF "]
		unless x <= y [print "UL "]
		if not x <= y [print "IN "]
		either x <= y [print "E1 "][print "E2 "]
		case  [x <= y [print "C1 "] yes [print "C2 "]]

		print "^-<  "
		if     x <  y [print "IF "]
		unless x <  y [print "UL "]
		if not x <  y [print "IN "]
		either x <  y [print "E1 "][print "E2 "]
		case  [x <  y [print "C1 "] yes [print "C2 "]]

		print "^-=  "
		if     x  = y [print "IF "]
		unless x  = y [print "UL "]
		if not x  = y [print "IN "]
		either x  = y [print "E1 "][print "E2 "]
		case  [x  = y [print "C1 "] yes [print "C2 "]]

		print "^-<> "
		if     x <> y [print "IF "]
		unless x <> y [print "UL "]
		if not x <> y [print "IN "]
		either x <> y [print "E1 "][print "E2 "]
		case  [x <> y [print "C1 "] yes [print "C2 "]]

		print "^- > "
		if     x  > y [print "IF "]
		unless x  > y [print "UL "]
		if not x  > y [print "IN "]
		either x  > y [print "E1 "][print "E2 "]
		case  [x  > y [print "C1 "] yes [print "C2 "]]

		print "^->= "
		if     x >= y [print "IF "]
		unless x >= y [print "UL "]
		if not x >= y [print "IN "]
		either x >= y [print "E1 "][print "E2 "]
		case  [x >= y [print "C1 "] yes [print "C2 "]]

		print lf
		b: b + 1
	]
	print lf
	a: a + 1
]
