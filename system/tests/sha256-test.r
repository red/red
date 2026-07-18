REBOL [
	Title:   "Host-side SHA-256 tests"
	File:    %sha256-test.r
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do %../utils/sha256.r

assert-digest: func [data [binary! string!] expected [binary!] /local actual][
	actual: sha256/digest data
	unless actual = expected [
		print ["SHA-256 mismatch:" mold data]
		print ["expected:" mold expected]
		print ["actual:  " mold actual]
		quit/return 1
	]
]

assert-digest #{} #{
	E3B0C44298FC1C149AFBF4C8996FB924
	27AE41E4649B934CA495991B7852B855
}
assert-digest "abc" #{
	BA7816BF8F01CFEA414140DE5DAE2223
	B00361A396177A9CB410FF61F20015AD
}
assert-digest
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
	#{248D6A61D20638B8E5C026930C3E6039A33CE45964FF2167F6ECEDD419DB06C1}

bytes: make binary! 256
repeat i 256 [append bytes to char! (i - 1)]
assert-digest bytes #{40AFF2E9D2D8922E47AFD4648E6967497158785FBD1DA870E7110266BF944880}

page: make binary! 16384
insert/dup tail page #{00} 16384
assert-digest page #{4FE7B59AF6DE3B665B67788CC2F99892AB827EFAE3A467342B3BB4E3BC8E5BFE}

paged: copy page
append paged page
insert/dup tail paged #{00} 32
expected-pages: make binary! 96
append expected-pages #{4FE7B59AF6DE3B665B67788CC2F99892AB827EFAE3A467342B3BB4E3BC8E5BFE}
append expected-pages #{4FE7B59AF6DE3B665B67788CC2F99892AB827EFAE3A467342B3BB4E3BC8E5BFE}
append expected-pages #{66687AADF862BD776C8FC18B8E9F8E20089714856EE233B3902A591D0D5F2925}
unless expected-pages = sha256/digest-pages paged length? paged 16384 [
	print "SHA-256 page hashing mismatch"
	quit/return 1
]

print "Host-side SHA-256 tests passed"
