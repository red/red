Red/System [Title: "Static link: /alternatename directive aliasing"]

;-- altname_test.obj embeds /alternatename:_alt_entry=_real_entry in its
;-- .drectve section; alt_entry is defined nowhere and must resolve
;-- through the alias -- the CRT's overridable-entry-point mechanism.
#import [
	"altname_test.obj" cdecl [
		alt-entry: "alt_entry" [x [integer!] return: [integer!]]
	]
]

either 42 = alt-entry 22 [
	print "PASS: alternatename aliasing^/"
][
	print "FAIL: alternatename aliasing^/"
]
