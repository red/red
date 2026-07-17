Red/System [Title: "Static link: associative COMDATs follow their folded parent"]

;-- comdatinit_{a,b}.obj (see comdatinit.hpp for the build line) both
;-- instantiate one C++17 inline variable: a COMDAT .data slot, a COMDAT
;-- ??__E initializer and a keyless .CRT$XCU entry ASSOCIATIVE to that
;-- text. Duplicate folding must drop the twin's XCU together with its
;-- parent -- kept, it re-runs the surviving initializer once per TU:
;-- bump()'s counter reads 2 and the variable holds the SECOND result.
#import [
	"comdatinit_a.obj" cdecl [
		side-a: "side_value_a" [return: [integer!]]
	]
	"comdatinit_b.obj" cdecl [
		side-b:     "side_value_b" [return: [integer!]]
		init-count: "init_count"   [return: [integer!]]
	]
]

either all [
	1 = init-count								;-- the initializer ran ONCE
	1 = side-a
	1 = side-b
][
	print "PASS: associative COMDAT folding^/"
][
	print ["FAIL: associative COMDAT folding |" init-count "|" side-a "|" side-b lf]
]
