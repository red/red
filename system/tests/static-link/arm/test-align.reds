Red/System [Title: "Static link: ARM section alignment (64-byte)"]

#import [
	"aligntest.o" cdecl [
		buf-addr:  "buf_addr"  [return: [int-ptr!]]
		buf-first: "buf_first" [return: [integer!]]
	]
]

addr: as integer! buf-addr
fval: buf-first

either all [zero? (addr and 63)  fval = 11][
	print "PASS: static link ARM alignment^/"
][
	print "FAIL: static link ARM alignment^/"
]
