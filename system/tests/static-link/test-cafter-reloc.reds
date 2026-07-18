Red/System [Title: "Static link: relocations inside a cafter (.fptable*) section"]

;-- fptreloc_test.obj (see fptreloc_test.c for the build line) plants a
;-- statically initialized function pointer in .fptable$r: page-isolated
;-- cafter content CARRYING a DIR32 relocation. The patch must land in
;-- the cafter buffer at the cafter base -- applied against .data
;-- instead, this call jumps through a zero slot and an unrelated .data
;-- cell gets stomped.
#import [
	"fptreloc_test.obj" cdecl [
		call-probe: "call_probe" [return: [integer!]]
	]
]

either 42 = call-probe [
	print "PASS: cafter-section relocation^/"
][
	print "FAIL: cafter-section relocation^/"
]
