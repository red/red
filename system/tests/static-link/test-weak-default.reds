Red/System [Title: "Static link: weak externals resolve to their default"]

;-- weakdtor_test.obj (see weakdtor_test.cpp): the class vtables carry
;-- ??_E vector-deleting-destructor slots emitted as weak externals whose
;-- aux default is the scalar ??_G in the same object. wd-del exercises
;-- that slot at run time through a real `delete` dispatch.
#import [
	"weakdtor_test.obj" cdecl [
		wd-call: "wd_call" [return: [integer!]]
		wd-del:  "wd_del"  [return: [integer!]]
	]
]

r1: wd-call
r2: wd-del

either all [r1 = 42  r2 = 42][
	print "PASS: weak-external default binding^/"
][
	print "FAIL: weak-external default binding^/"
]
