Red/System [Title: "Static link: relocs into non-primary members of a duplicate ELF group"]

;-- libgroupdup.a (see groupdup.hpp for the build line): two objects each
;-- carry the SAME 2-payload COMDAT group (.text._Z7guardedi + its LSDA in
;-- .gcc_except_table._Z7guardedi). The duplicate group is discarded, but
;-- the duplicate object's .eh_frame FDE still relocates against BOTH
;-- dropped members: pc-begin into the text, the LSDA pointer into the
;-- except-table. Each must redirect into the kept group's member of the
;-- SAME NAME -- an LSDA redirected onto the text base parses as garbage
;-- and kills the unwinder. Both calls throw and catch through the shared
;-- comdat frame to prove the surviving tables.
#import [
	"libgroupdup.a" cdecl [
		call-a: "call_a" [v [integer!] return: [integer!]]
		call-b: "call_b" [v [integer!] return: [integer!]]
	]
]

either all [
	19 = call-a 5								;-- throw 15, catch +4
	22 = call-b 5								;-- throw 18, catch +4
][
	print ["PASS: duplicate-group LSDA redirect" lf]
][
	print ["FAIL: duplicate-group LSDA redirect" lf]
]
