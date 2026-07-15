Red/System [
	Title: "Windows x86-64 all-tests runner canary"
]

#import [
	"kernel32.dll" stdcall [
		exit-process: "ExitProcess" [status [integer!]]
	]
]

#if target = 'X86-64 [
	if (size? pointer!) <> 8 [exit-process 1]
	if (size? int-ptr!) <> 8 [exit-process 2]
	if (size? function!) <> 8 [exit-process 3]
	exit-process 0
]

exit-process 4
