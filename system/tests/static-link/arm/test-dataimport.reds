Red/System [Title: "Static link: ARM libc data-symbol imports (stdout/stderr)"]

#import [
	"dataimport_test.o" cdecl [
		data-import-ok: "data_import_ok" [return: [integer!]]
	]
]

;-- data_import_ok reads the libc DATA symbols stdout/stderr; it returns 1
;-- only if both copy relocations resolved to usable FILE* streams.
either 1 = data-import-ok [
	print "PASS: static link ARM data imports^/"
][
	print "FAIL: static link ARM data imports^/"
]
