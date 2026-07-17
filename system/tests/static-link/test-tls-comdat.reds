Red/System [Title: "Static link: duplicate COMDAT .tls$ folding + post-layout anchors"]

;-- tlsdup_a.obj / tlsdup_b.obj (see tlsdup.hpp for the build line) each
;-- carry the SAME COMDAT .tls$ section for an inline thread_local. The
;-- duplicate must fold to ONE template slot laid out between tlssup.obj's
;-- .tls / .tls$ZZZ markers, and the group's COMDAT anchor must be patched
;-- AFTER the deferred layout runs -- a pre-layout anchor snapshots
;-- base-kind 'none, which target-va? treats as a code address. Both TUs
;-- bumping one slot proves the fold; the worker probe proves the folded
;-- slot still gets a fresh per-thread copy from the template.
#import [
	"tlsdup_a.obj" cdecl [
		bump-a: "bump_a" [return: [integer!]]
	]
	"tlsdup_b.obj" cdecl [
		bump-b:     "bump_b"     [return: [integer!]]
		fresh-copy: "fresh_copy" [return: [integer!]]
	]
]

either all [
	42 = bump-a									;-- 41 + 1
	43 = bump-b									;-- SAME slot: the duplicate folded
	42 = fresh-copy								;-- worker thread: fresh 41 + 1
	44 = bump-a									;-- main copy untouched by the worker
][
	print "PASS: duplicate COMDAT .tls$ folding^/"
][
	print "FAIL: duplicate COMDAT .tls$ folding^/"
]
