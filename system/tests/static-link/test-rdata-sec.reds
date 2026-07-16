Red/System [Title: "Static link: _RDATA section (MSVC CRT read-only data)"]

#import [
	"rdatasec_test.obj" cdecl [
		rd-read: "rd_read" [return: [integer!]]
	]
]

either 42 = rd-read [
	print "PASS: _RDATA section^/"
][
	print "FAIL: _RDATA section^/"
]
