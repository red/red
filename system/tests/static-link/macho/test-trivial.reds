Red/System [Title: "Static link: Mach-O trivial leaf functions"]

#import [
	"trivial.o" cdecl [
		add-one: "add_one" [x [integer!] return: [integer!]]
		add-two: "add_two" [x [integer!] y [integer!] return: [integer!]]
		triple:  "triple"  [x [integer!] return: [integer!]]
	]
]

r1: add-one 41
r2: add-two 20 22
r3: triple 14

either all [r1 = 42  r2 = 42  r3 = 42][
	print "PASS: static link Mach-O trivial^/"
][
	print "FAIL: static link Mach-O trivial^/"
]
