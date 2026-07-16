Red/System [
	Title: "Red/System ARM64 large frame and offset smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	chunk!: alias struct! [
		v01 [integer!] v02 [integer!] v03 [integer!] v04 [integer!]
		v05 [integer!] v06 [integer!] v07 [integer!] v08 [integer!]
		v09 [integer!] v10 [integer!] v11 [integer!] v12 [integer!]
		v13 [integer!] v14 [integer!] v15 [integer!] v16 [integer!]
		v17 [integer!] v18 [integer!] v19 [integer!] v20 [integer!]
		v21 [integer!] v22 [integer!] v23 [integer!] v24 [integer!]
		v25 [integer!] v26 [integer!] v27 [integer!] v28 [integer!]
		v29 [integer!] v30 [integer!] v31 [integer!] v32 [integer!]
	]
	large!: alias struct! [
		b01 [chunk! value] b02 [chunk! value] b03 [chunk! value] b04 [chunk! value]
		b05 [chunk! value] b06 [chunk! value] b07 [chunk! value] b08 [chunk! value]
		b09 [chunk! value] b10 [chunk! value] b11 [chunk! value] b12 [chunk! value]
		b13 [chunk! value] b14 [chunk! value] b15 [chunk! value] b16 [chunk! value]
		b17 [chunk! value] b18 [chunk! value] b19 [chunk! value] b20 [chunk! value]
		b21 [chunk! value] b22 [chunk! value] b23 [chunk! value] b24 [chunk! value]
		b25 [chunk! value] b26 [chunk! value] b27 [chunk! value] b28 [chunk! value]
		b29 [chunk! value] b30 [chunk! value] b31 [chunk! value] b32 [chunk! value]
		b33 [chunk! value] b34 [chunk! value] b35 [chunk! value] b36 [chunk! value]
		b37 [chunk! value] b38 [chunk! value] b39 [chunk! value] b40 [chunk! value]
	]
	#import ["libc.so.6" cdecl [
		imported-noop: "getpid" [value [large! value] return: [integer!]]
	]]

	check-large-frame: func [return: [integer!] /local value [large! value] marker [integer!] pid [integer!]][
		value/b01/v01: 111
		value/b40/v32: 222
		marker: 333
		pid: imported-noop value
		either all [
			pid > 0
			value/b01/v01 = 111
			value/b40/v32 = 222
			marker = 333
		][value/b01/v01 + value/b40/v32][0]
	]

	if check-large-frame <> 333 [sys-exit 1]
	sys-exit 0
]
