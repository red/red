Red/System [Title: "Static link: Mach-O __eh_frame emission + C++ unwind"]

;-- tryeh_test.o (see tryeh_test.cpp for the build line) carries real
;-- unwind records in __TEXT,__eh_frame plus an LSDA in __gcc_except_tab
;-- and a __mod_init_func constructor. The emitter must write the
;-- __eh_frame payload it declares (libunwind finds the section by name
;-- in the image -- padding there aborts the catch), the entry stub must
;-- run the ctor on a 16-byte-aligned stack, and the throw must unwind
;-- through libc++abi back into the catch.
#import [
	"tryeh_test.o" cdecl [
		try-eh: "try_eh" [v [integer!] return: [integer!]]
	]
]

either all [
	1001 = try-eh 1								;-- non-throwing path
	22   = try-eh 3								;-- throw 15, catch 15 + ctor's 7
][
	print ["PASS: Mach-O __eh_frame unwind (+ mod_init ctor)" lf]
][
	print ["FAIL: Mach-O __eh_frame unwind" lf]
]
