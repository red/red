Red/System [
	Title: "x64 atomic direct smoke"
]

#if target = 'X86-64 [
	g: 0

	load-store: func [
		return: [integer!]
	][
		system/atomic/store :g 7
		system/atomic/add :g 5
		system/atomic/sub :g 2
		system/atomic/cas :g 10 11
		system/atomic/fence
		g
	]

	main: func [
	][
		if load-store <> 11 [quit 1]
		quit 0
	]

	main
]
