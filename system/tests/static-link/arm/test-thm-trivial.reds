Red/System [Title: "Static link: ARM Thumb-2 trivial leaf functions"]

#import [
	"trivial-thumb.o" cdecl [
		add-one: "add_one" [x [integer!] return: [integer!]]
		add-two: "add_two" [x [integer!] y [integer!] return: [integer!]]
		triple:  "triple"  [x [integer!] return: [integer!]]
	]
]

;-- Thumb-compiled leaf functions: exercises the basic merge path with a
;-- Thumb object (no Thumb-specific relocations needed for these leaves;
;-- the symbol values carry the T-bit, so the wire-imports pointer slot
;-- gets the LSB-set address and BLX-through-the-slot interworks).
r1: add-one 41
r2: add-two 20 22
r3: triple 14

either all [r1 = 42  r2 = 42  r3 = 42][
	print "PASS: static link ARM Thumb trivial^/"
][
	print "FAIL: static link ARM Thumb trivial^/"
]
