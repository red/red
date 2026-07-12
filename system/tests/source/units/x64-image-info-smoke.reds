Red/System [
	Title: "x86-64 executable image descriptor smoke test"
]

sys-exit: func [[cdecl] status [integer!]][
	#import ["libc.so.6" cdecl [exit: "exit" [status [integer!]]]]
	exit status
]

bits: declare pointer! [integer!]
header: 0

if null? system/image/base [sys-exit 1]
if system/image/code <= 0 [sys-exit 2]
if system/image/code-size <= 0 [sys-exit 3]
if system/image/data <= system/image/code [sys-exit 4]
if system/image/data-size <= 0 [sys-exit 5]
if system/image/bitarray < system/image/data [sys-exit 6]
bits: as pointer! [integer!] system/image/base + system/image/bitarray
header: bits/0
if header < 0 [sys-exit 7]

sys-exit 0
