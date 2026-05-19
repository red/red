Red/System [Title: "Static link: selective archive member loading"]

#import [
	"seltest.a" cdecl [
		used: "seltest_used" [return: [integer!]]
	]
]

;-- seltest.a also contains seltest_unused.o, which calls an unresolvable
;-- symbol (__static_link_poison__). The link succeeds only because nothing
;-- references seltest_unused, so that member is never pulled in.
either 42 = used [
	print "PASS: selective archive loading^/"
][
	print "FAIL: selective archive loading^/"
]
