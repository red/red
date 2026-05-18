Red/System [Title: "Static link: msvcrt export-table verification"]

#import [
	"randtest.obj" cdecl [
		roll: "roll" [seed [integer!] return: [integer!]]
	]
]

;-- roll() calls srand() + rand() -- both real msvcrt.dll exports, and
;-- neither is on the linker's fallback whitelist. The program linking at
;-- all proves the linker verified them against msvcrt.dll's export table.
r: roll 12345

either all [r >= 0  r <= 32767][
	print "PASS: static link export-table^/"
][
	print "FAIL: static link export-table^/"
]
