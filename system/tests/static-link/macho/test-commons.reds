Red/System [Title: "Static link: Mach-O common coalescing (largest size + alignment)"]

;-- commons_a.o declares shared_buf[4] (+ a double and a guard slot right
;-- after it); commons_b.o declares shared_buf[16]. Coalescing must give
;-- the SINGLE slot the LARGEST size whatever the object order -- with
;-- first-wins, fill_buf's 64-byte write overruns into dcommon and
;-- tail_guard. The double's slot must land 8-byte aligned.
#import [
	"commons_a.o" cdecl [
		sum-buf:       "sum_buf"       [return: [integer!]]
		guard-value:   "guard_value"   [return: [integer!]]
		dcommon-align: "dcommon_align" [return: [integer!]]
	]
	"commons_b.o" cdecl [
		fill-buf: "fill_buf" []
	]
]

fill-buf
either all [
	136 = sum-buf								;-- all 16 ints stored and read back
	zero? guard-value							;-- nothing stomped past the slot
	zero? dcommon-align							;-- 8-byte-aligned double common
][
	print ["PASS: Mach-O commons (largest wins, aligned, no overrun)" lf]
][
	print ["FAIL: Mach-O commons |" sum-buf "|" guard-value "|" dcommon-align lf]
]
