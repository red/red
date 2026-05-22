Red/System [
	Title: "Red/System x86-64 int64 smoke test"
]

#if target = 'X86-64 [
	#syscall [
		sys-write: 1 [
			fd  [integer!]
			buf [c-string!]
			len [integer!]
		]
		sys-exit: 60 [
			status [integer!]
		]
	]

	add-one64: func [
		value [int64!]
		return: [int64!]
	][
		value + 1
	]

	id-u64: func [
		value [uint64!]
		return: [uint64!]
	][
		value
	]

	msg: "OK^/"
	score: 0
	i64: add-one64 0000000100000000h
	u64: id-u64 FFFFFFFFFFFFFFFFh
	if i64 = 0000000100000001h [
		score: score + 1
	]
	if u64 = FFFFFFFFFFFFFFFFh [
		score: score + 1
	]
	if score = 2 [
		sys-write 1 msg 3
	]
	sys-exit 0
]
