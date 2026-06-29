Red/System [Title: "Static link: section alignment (64-byte / AVX-512)"]

#import [
	"aligntest.obj" cdecl [
		buf-addr:  "buf_addr"  [return: [int-ptr!]]
		buf-first: "buf_first" [return: [integer!]]
	]
]

addr: as integer! buf-addr
fval: buf-first

either all [zero? (addr and 63)  fval = 11][
	print "PASS: static link alignment^/"
][
	print "FAIL: static link alignment^/"
]
