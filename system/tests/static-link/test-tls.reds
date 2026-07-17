Red/System [Title: "Static link: PE implicit TLS (__declspec(thread) + dynamic thread_local)"]

;-- tls_test.obj (see tls_test.cpp for the build line) carries a .tls$
;-- template, a static-init __declspec(thread) slot, a dynamic-init
;-- C++ thread_local (.CRT$XD* initializer walked by ___dyn_tls_init)
;-- and a user TLS callback in .CRT$XLB. The linker publishes the CRT's
;-- IMAGE_TLS_DIRECTORY (tlssup.obj's __tls_used, resident in crodata,
;-- with its $XL callback bounds) through the PE data directory;
;-- tls_check() proves per-thread copies AND that the loader drove the
;-- callback array -- the latter is what /Zc:tlsGuards cannot mask.
#import [
	"tls_test.obj" cdecl [
		tls-check: "tls_check" [return: [integer!]]
	]
]

either 127 = tls-check [
	print "PASS: PE implicit TLS (static + dynamic thread_local)^/"
][
	print "FAIL: PE implicit TLS^/"
]
