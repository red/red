Red/System [Title: "Static link: STATIC-keyed COMDAT folding with redirection"]

;-- cfold_test.lib (see cfold_a.c): both members pool the same double
;-- constants as STATIC-keyed COMDATs (__real@...). The second member's
;-- pool folds onto the first's, and its relocations must redirect into
;-- the kept twin -- a broken redirection aborts the link; a wrong one
;-- corrupts the constants below.
#import [
	"cfold_test.lib" cdecl [
		fold-a: "fold_a" [x [integer!] return: [integer!]]
		fold-b: "fold_b" [x [integer!] return: [integer!]]
	]
]

r1: fold-a 1000
r2: fold-b 1000

either all [r1 = 10242  r2 = 10242][
	print "PASS: COMDAT literal-pool folding^/"
][
	print "FAIL: COMDAT literal-pool folding^/"
]
