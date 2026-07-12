Red/System [
	Title: "Red/System x86-64 secondary operand smoke test"
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

	msg: "OK^/"
	other: msg
	flag: yes
	other-flag: yes
	score: 0
	secondary-scope: context [
		top: 1
		increment: func [return: [integer!]][
			top: top + 1
			top
		]
	]

	if msg = other [score: score + 1]
	if flag = other-flag [score: score + 2]
	if secondary-scope/increment <> 2 [sys-exit 4]

	if score <> 3 [
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
