Red/System [Title: "Static link: weak vs strong symbol folding"]

#import [
	"cwtest.a" cdecl [
		comdat-value: "comdat_value" [return: [integer!]]
	]
]

;-- cwtest.a contains weakdef.o first (weak `comdat_value` returning 99)
;-- and strongdef.o second (strong `comdat_value` returning 42). The strong
;-- definition must replace the weak one regardless of merge order; without
;-- weak/COMDAT folding the weak member would win and we'd see 99.
either 42 = comdat-value [
	print "PASS: weak/COMDAT symbol folding^/"
][
	print "FAIL: weak/COMDAT symbol folding^/"
]
