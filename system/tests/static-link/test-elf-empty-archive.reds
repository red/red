Red/System [Title: "Static link: empty archive import"]

#import [
	"seltest.a" cdecl []
	"trivial.o" cdecl [
		add-one: "add_one" [x [integer!] return: [integer!]]
	]
]

either 42 = add-one 41 [
	print "PASS: static link empty archive import^/"
][
	print "FAIL: static link empty archive import^/"
]
