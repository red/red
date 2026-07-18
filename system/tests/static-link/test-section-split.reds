Red/System [Title: "Static link: read-only vs writable data land in separate PE sections"]

;-- sectsplit_test.obj (see sectsplit_test.c) carries a const array (ss_table,
;-- read-only) and a written global (ss_counter). The static linker must place
;-- the const in a read-only PE section (.rdata, non-writable) and the global
;-- in a writable one (.data), so no writable datum shares a page with the
;-- read-only-after-init data the MSVC CRT re-protects. This test exercises
;-- both at run time; the structural placement is asserted by check-sections.r.
#import [
	"sectsplit_test.obj" cdecl [
		ss-read: "ss_read" [i [integer!] return: [integer!]]
		ss-bump: "ss_bump" [return: [integer!]]
	]
]

r1: ss-read 41			;-- ss_table[41] = 42
r2: ss-bump				;-- ++ss_counter = 8 (writable global updated)
r3: ss-bump				;-- = 9

either all [r1 = 42  r2 = 8  r3 = 9][
	print "PASS: section split read-only vs writable^/"
][
	print ["FAIL: section split:" r1 r2 r3 "^/"]
]
