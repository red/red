Red/System [Title: "Static link: libc trampoline (memcpy)"]

#import [
	"memcpy_test.obj" cdecl [
		copy-and-return-len: "copy_and_return_len" [
			dst	[byte-ptr!]
			src	[byte-ptr!]
			n	[integer!]
			return: [integer!]
		]
		sum-first-bytes: "sum_first_bytes" [
			buf	[byte-ptr!]
			n	[integer!]
			return: [integer!]
		]
	]
]

src: declare c-string!
dst: declare c-string!
src: "ABCDEF"
dst: "......"

;-- copy_and_return_len relays through memcpy in msvcrt.dll via trampoline
n: copy-and-return-len (as byte-ptr! dst) (as byte-ptr! src) 6

;-- 'A'+'B'+'C'+'D'+'E'+'F' = 65+66+67+68+69+70 = 405
sum: sum-first-bytes (as byte-ptr! dst) 6

either all [n = 6  sum = 405][
	print "PASS: static link memcpy^/"
][
	print "FAIL: static link memcpy^/"
]
