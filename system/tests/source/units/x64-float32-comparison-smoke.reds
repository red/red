Red/System [
	Title: "Red/System x86-64 float32 comparison smoke test"
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

	equal32?: func [
		left  [float32!]
		right [float32!]
		return: [logic!]
	][
		left = right
	]

	almost-equal32?: func [
		left  [float32!]
		right [float32!]
		return: [logic!]
		/local l r al ar diff [integer!]
	][
		if left = right [return yes]
		l: as-integer keep left
		r: as-integer keep right
		al: l and 7FFFFFFFh
		ar: r and 7FFFFFFFh
		if all [al = 0 ar = 0] [return yes]
		diff: al - ar
		if diff < 0 [diff: 0 - diff]
		diff <= 10
	]

	msg: "OK^/"
	bits: 1069547520
	zero: as-float32 0
	half: as-float32 0.5
	one: as-float32 1
	one-half: as-float32 1.5

	if equal32? half zero [sys-exit 1]
	if equal32? one-half one [sys-exit 2]
	if almost-equal32? half zero [sys-exit 3]
	if almost-equal32? one-half one [sys-exit 4]
	if (as-integer keep half) <> 3F000000h [sys-exit 5]
	if (as float32! keep bits) <> one-half [sys-exit 6]

	sys-write 1 msg 3
	sys-exit 0
]
