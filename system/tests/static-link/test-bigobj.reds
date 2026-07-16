Red/System [Title: "Static link: /bigobj COFF object layout"]

;-- bigobj_test.obj uses the ANON_OBJECT_HEADER_BIGOBJ container (see
;-- bigobj_test.c for the build line) -- the layout MSVC emits under
;-- /bigobj, which large C++ builds enable as a matter of course.
#import [
	"bigobj_test.obj" cdecl [
		bo-add:   "bo_add"   [a [integer!] b [integer!] return: [integer!]]
		bo-scale: "bo_scale" [x [integer!] return: [integer!]]
	]
]

r1: bo-add 20 22
r2: bo-scale 6

either all [r1 = 42  r2 = 42][
	print "PASS: static link bigobj^/"
][
	print "FAIL: static link bigobj^/"
]
