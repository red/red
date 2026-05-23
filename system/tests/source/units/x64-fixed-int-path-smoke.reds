Red/System [
	Title: "Red/System x86-64 fixed integer path smoke test"
]

#if target = 'X86-64 [
	#either OS = 'Windows [
		#import [
			"kernel32.dll" stdcall [
				sys-exit: "ExitProcess" [
					status [integer!]
				]
			]
		]
	][
		#syscall [
			sys-exit: 60 [
				status [integer!]
			]
		]
	]

	pair64!: alias struct! [
		i64 [int64!]
		u64 [uint64!]
	]

	main: func [
		/local
			s [pair64!]
			i [int64!]
			j [int64!]
			u [uint64!]
			v [uint64!]
	][
		s: declare pair64!
		i: 0000000100000000h
		j: 0000000000000002h
		s/i64: i
		s/i64: s/i64 + j
		if s/i64 <> 0000000100000002h [sys-exit 1]

		u: as uint64! 0000000100000000h
		v: as uint64! 0000000000000002h
		s/u64: u
		s/u64: s/u64 + v
		if s/u64 <> as uint64! 0000000100000002h [sys-exit 2]

		if ((123456789000 / 10) + (9876543210 * 2)) <> 32098765320 [
			sys-exit 3
		]
		if 8 <> (7 + 1) [sys-exit 4]

		sys-exit 0
	]

	main
]
