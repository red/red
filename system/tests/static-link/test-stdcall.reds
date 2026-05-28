Red/System [Title: "Static link: stdcall functions"]

#import [
	"stdcall_test.obj" stdcall [
		add-std:      "add_std"      [a [integer!] b [integer!] return: [integer!]]
		mul3-std:     "mul3_std"     [a [integer!] b [integer!] c [integer!] return: [integer!]]
		identity-std: "identity_std" [x [integer!] return: [integer!]]
	]
]

r1: add-std 20 22
r2: mul3-std 2 3 7
r3: identity-std 42

either all [r1 = 42  r2 = 42  r3 = 42][
	print "PASS: static link stdcall^/"
][
	print "FAIL: static link stdcall^/"
]
