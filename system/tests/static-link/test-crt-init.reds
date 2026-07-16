Red/System [Title: "Static link: sorted .CRT$X?? initializer tables + /include"]

;-- Three translation units contribute initializer pointers to .CRT$XCM1,
;-- $XCM2 and $XCM3 (see crtinit_a.c); the linker must lay them out sorted
;-- by full section name between the fixture's own $XCA/$XCZ bounds.
;-- crtinit_c.obj is referenced by NOTHING -- it links purely through
;-- crtinit_a's /include:_c_forced directive.
#import [
	"crtinit_a.obj" cdecl [
		run-inits: "run_inits" [return: [integer!]]
		order-at:  "order_at"  [i [integer!] return: [integer!]]
	]
	"crtinit_bc.lib" cdecl [
		b-ping: "b_ping" [return: [integer!]]
	]
]

n:  run-inits
o1: order-at 0
o2: order-at 1
o3: order-at 2

either all [n = 3  o1 = 1  o2 = 2  o3 = 3  7 = b-ping][
	print "PASS: sorted .CRT initializer tables^/"
][
	print ["FAIL: sorted .CRT initializer tables:" n o1 o2 o3 "^/"]
]
