Red/System [Title: "Static link: ARM Thumb-2 MOVW/MOVT (64-byte alignment)"]

#import [
	"aligntest-thumb.o" cdecl [
		buf-addr:  "buf_addr"  [return: [int-ptr!]]
		buf-first: "buf_first" [return: [integer!]]
	]
]

;-- Thumb-compiled buf_addr / buf_first load aligned_buf's address with a
;-- THM_MOVW + THM_MOVT pair (split 16-bit immediate). The static linker
;-- must patch both halves so the absolute address resolves correctly.
addr: as integer! buf-addr
fval: buf-first

either all [zero? (addr and 63)  fval = 11][
	print "PASS: static link ARM Thumb alignment^/"
][
	print "FAIL: static link ARM Thumb alignment^/"
]
