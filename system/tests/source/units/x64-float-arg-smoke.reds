Red/System [
	Title: "Red/System x86-64 float argument smoke test"
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

	add-float: func [
		a [float!]
		b [float!]
		return: [float!]
	][
		a + b
	]

	add-float32: func [
		a [float32!]
		b [float32!]
		return: [float32!]
	][
		a + b
	]

	check-mixed: func [
		p     [c-string!]
		value [float!]
		flag  [logic!]
		return: [logic!]
	][
		all [p/1 = #"O" value = as float! 4.5 flag]
	]

	float-source: func [return: [float!]][1234.75]
	integer-sink: func [value [integer!] return: [integer!]][value]

	cast-after-branch: func [
		return: [integer!]
		/local value [float!]
	][
		value: float-source
		either value > 2147483647.0 [-1][integer-sink as-integer value]
	]

	check-casts: func [
		return: [integer!]
		/local
			value [float!]
			single [float32!]
			i [integer!]
	][
		value: 1234.75
		i: as integer! value
		if i <> 1234 [return 1]
		i: as-integer value
		if i <> 1234 [return 2]
		i: cast-after-branch
		if i <> 1234 [return 3]

		value: as float! i
		if value <> 1234.0 [return 4]

		single: as float32! 12.5
		value: as float! single
		if value <> 12.5 [return 5]
		0
	]

	msg: "OK^/"
	score: 0
	cast-error: check-casts
	if cast-error <> 0 [
		cast-error: cast-error + 10
		sys-exit cast-error
	]
	f: add-float 1.25 2.25
	f32: add-float32 as float32! 1.5 as float32! 2.5
	if f = as float! 3.5 [
		score: score + 1
	]
	if f32 = as float32! 4.0 [
		score: score + 1
	]
	if check-mixed msg f + 1.0 yes [
		score: score + 1
	]
	if score <> 3 [
		score: score + 20
		sys-exit score
	]
	sys-write 1 msg 3
	sys-exit 0
]
