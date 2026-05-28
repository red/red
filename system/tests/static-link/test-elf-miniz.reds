Red/System [Title: "Static link: ELF libminiz.a archive round-trip"]

#import [
	"libminiz.a" cdecl [
		mz-compress: "mz_compress" [
			dst		[byte-ptr!]
			dst-len	[int-ptr!]
			src		[byte-ptr!]
			src-len	[integer!]
			return:	[integer!]
		]
		mz-uncompress: "mz_uncompress" [
			dst		[byte-ptr!]
			dst-len	[int-ptr!]
			src		[byte-ptr!]
			src-len	[integer!]
			return:	[integer!]
		]
	]
]

src: allocate 256
dst: allocate 512
rt:  allocate 256

p: src
i: 0
while [i < 256][
	p/1: as byte! (i and 15) + 65
	p: p + 1
	i: i + 1
]

dst-len: as int-ptr! allocate 4
dst-len/value: 512
status: mz-compress dst dst-len src 256
if status <> 0 [print "FAIL: mz_compress^/" quit 1]

rt-len: as int-ptr! allocate 4
rt-len/value: 256
status: mz-uncompress rt rt-len dst dst-len/value
if status <> 0 [print "FAIL: mz_uncompress^/" quit 1]

if rt-len/value <> 256 [print "FAIL: length mismatch^/" quit 1]

ps: src
pr: rt
i:  0
ok?: yes
while [i < 256][
	if ps/1 <> pr/1 [ok?: no]
	ps: ps + 1
	pr: pr + 1
	i:  i + 1
]

either ok? [
	print "PASS: static link ELF libminiz.a^/"
][
	print "FAIL: libminiz.a byte mismatch^/"
]
