Red/System [Title: "Static link: stdcall functions pulled from an archive"]

;-- stdcall_test.lib wraps stdcall_test.obj (llvm-lib /out:stdcall_test.lib
;-- stdcall_test.obj). The user-facing names carry no '@N' suffix, so the
;-- member must resolve through the archive symbol index's stdcall-shape
;-- table (_name@N indexed under its bare name).
#import [
	"stdcall_test.lib" stdcall [
		add-std:      "add_std"      [a [integer!] b [integer!] return: [integer!]]
		mul3-std:     "mul3_std"     [a [integer!] b [integer!] c [integer!] return: [integer!]]
		identity-std: "identity_std" [x [integer!] return: [integer!]]
	]
]

r1: add-std 20 22
r2: mul3-std 2 3 7
r3: identity-std 42

either all [r1 = 42  r2 = 42  r3 = 42][
	print "PASS: static link stdcall from archive^/"
][
	print "FAIL: static link stdcall from archive^/"
]
