Red/System [
	Title: "ARM64 overflow block smoke test"
]

#if target = 'ARM64 [
	#syscall [
		sys-exit: 93 [status [integer!]]
	]

	value: declare integer!
	wide: declare int64!
	uwide: declare uint64!
	flag: declare logic!
	flag: overflow? [value: 1 + 1]
	if flag [sys-exit 1]

	flag: overflow? [wide: (as int64! 40000) + (as int64! 1)]
	if flag [sys-exit 2]
	if wide <> as int64! 40001 [sys-exit 3]
	flag: overflow? [wide: (as int64! 7FFFFFFFFFFFFFFFh) + (as int64! 1)]
	if not flag [sys-exit 4]
	flag: overflow? [wide: (as int64! 8000000000000000h) - (as int64! 1)]
	if not flag [sys-exit 5]
	flag: overflow? [wide: (as int64! 20000) * (as int64! 2)]
	if flag [sys-exit 6]
	if wide <> as int64! 40000 [sys-exit 7]
	flag: overflow? [wide: (as int64! -20000) * (as int64! 2)]
	if flag [sys-exit 13]
	if wide <> as int64! -40000 [sys-exit 14]
	flag: overflow? [wide: (as int64! 4000000000000000h) * (as int64! 4)]
	if not flag [sys-exit 8]

	flag: overflow? [uwide: (as uint64! FFFFFFFFFFFFFFFFh) + (as uint64! 1)]
	if not flag [sys-exit 9]
	flag: overflow? [uwide: (as uint64! 0) - (as uint64! 1)]
	if not flag [sys-exit 10]
	flag: overflow? [uwide: (as uint64! 20000) * (as uint64! 2)]
	if flag [sys-exit 11]
	flag: overflow? [uwide: (as uint64! 8000000000000000h) * (as uint64! 2)]
	if not flag [sys-exit 12]
	sys-exit 0
]
