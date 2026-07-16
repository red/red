Red/System [
	Title: "Red/System ARM64 atomic smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	g: 0

	main: func [
		/local n [integer!] previous [integer!] ok [logic!]
	][
		system/atomic/store :g 7
		n: system/atomic/load :g
		if n <> 7 [sys-exit 1]

		previous: system/atomic/add/old :g 5
		if previous <> 7 [sys-exit 2]
		if g <> 12 [sys-exit 3]

		n: system/atomic/sub :g 2
		if n <> 10 [sys-exit 4]

		n: system/atomic/or :g 5
		if n <> 15 [sys-exit 5]
		n: system/atomic/xor :g 3
		if n <> 12 [sys-exit 6]
		n: system/atomic/and :g 10
		if n <> 8 [sys-exit 7]

		ok: system/atomic/cas :g 8 11
		if not ok [sys-exit 8]
		if g <> 11 [sys-exit 9]

		ok: system/atomic/cas :g 8 12
		if ok [sys-exit 10]
		if g <> 11 [sys-exit 11]

		system/atomic/add :g 1
		if g <> 12 [sys-exit 12]
		system/atomic/fence
		sys-exit 0
	]

	main
]
