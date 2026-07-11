Red/System [
	Title: "Red/System x86-64 subroutine smoke test"
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

	check-basic: func [
		return: [integer!]
		/local
			a  [integer!]
			s  [subroutine!]
			s2 [subroutine!]
	][
		a: 1 + 2
		s2: [a: 0 - a]
		s: [
			a: a * 2
			s2
		]
		s
		either a = -6 [0][1]
	]

	check-nested: func [
		return: [integer!]
		/local
			a  [integer!]
			s  [subroutine!]
			s2 [subroutine!]
			s3 [subroutine!]
			s4 [subroutine!]
	][
		a: 1 + 2
		s4: [a: a + 4]
		s3: [a: a + 3 s4]
		s2: [a: 0 - a s3]
		s: [
			a: a * 2
			s2
		]
		s
		either a = 1 [0][2]
	]

	check-return: func [
		value [integer!]
		return: [integer!]
		/local
			do-return [subroutine!]
			err       [integer!]
	][
		do-return: [return err]
		switch value [
			0  [err: 10 do-return]
			5  [err: 20 do-return]
			10 [err: 30 do-return]
			default [value]
		]
	]

	result: check-basic
	if result <> 0 [sys-exit result]

	result: check-nested
	if result <> 0 [sys-exit result]

	if 1 <> check-return 1 [sys-exit 3]
	if 10 <> check-return 0 [sys-exit 4]
	if 3 <> check-return 3 [sys-exit 5]
	if 20 <> check-return 5 [sys-exit 6]

	sys-exit 0
]
