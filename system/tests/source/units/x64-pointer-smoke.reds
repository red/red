Red/System [
	Title: "Red/System x86-64 pointer smoke test"
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

	pair!: alias struct! [
		left  [integer!]
		right [integer!]
	]
	record!: alias struct! [
		first  [integer!]
		second [integer!]
		third  [integer!]
	]
	records!: alias struct! [
		first  [integer!]
		second [integer!]
		third  [integer!]
		fourth [integer!]
		fifth  [integer!]
		sixth  [integer!]
	]
	holder!: alias struct! [
		value [byte-ptr!]
	]
	char-store!: alias struct! [
		value [int64!]
	]

	pair: declare pair!
	p: declare pointer! [integer!]
	records: declare records!
	record: as record! records
	holder: declare holder!
	char-store: declare char-store!
	chars: as c-string! char-store
	base-chars: chars
	char-index: 2
	score: 0

	p: as pointer! [integer!] pair
	p/value: 41
	p/2: 1

	if p/value = 41 [score: score + 1]
	if p/2 = 1 [score: score + 1]
	if pair/left = 41 [score: score + 1]
	if pair/right = 1 [score: score + 1]

	record/first: 11
	record: record + 1
	record/first: 22
	if records/first = 11 [score: score + 1]
	if records/fourth = 22 [score: score + 1]

	holder/value: either true [as byte-ptr! pair][null]
	if holder/value = as byte-ptr! pair [score: score + 1]
	holder/value: as byte-ptr! pair
	if holder/value = as byte-ptr! pair [score: score + 1]
	chars/char-index: #"0" + 7
	if chars/2 = #"7" [score: score + 1]
	chars: chars + 1
	char-index: 0
	chars/char-index: #"A"
	if base-chars/1 = #"A" [score: score + 1]
	if chars/char-index = #"A" [score: score + 1]

	if score = 11 [
		sys-write 1 "OK^/" 3
		sys-exit 0
	]
	sys-exit 1
]
