Red/System [
	Title: "Red/System ARM64 fixed-width integer smoke test"
]

#if target = 'ARM64 [
	#syscall [sys-exit: 93 [status [integer!]]]

	arm64-fixed-box!: alias struct! [i [integer!] f [float!]]
	arm64-fixed-value!: alias struct! [
		tag [uint8!]
		ptr [int-ptr!]
		fptr [pointer! [float!]]
	]
	arm64-fixed-nested!: alias struct! [
		head [uint8!]
		value [arm64-fixed-value! value]
		done [uint16!]
	]

	typed-check: func [
		[typed]
		count [integer!] list [typed-value!]
		return: [integer!]
	][
		if count <> 8 [return 20]
		if not all [type-int8! = list/type -2 = typed-value-as-integer list][return 21]
		list: list + 1
		if not all [type-uint8! = list/type 250 = typed-value-as-integer list][return 22]
		list: list + 1
		if not all [type-int16! = list/type -300 = typed-value-as-integer list][return 23]
		list: list + 1
		if not all [type-uint16! = list/type 60000 = typed-value-as-integer list][return 24]
		list: list + 1
		if not all [type-int32! = list/type -123456 = typed-value-as-integer list][return 25]
		list: list + 1
		if not all [type-uint32! = list/type -1 = typed-value-as-integer list][return 26]
		list: list + 1
		if type-int64! <> list/type [return 27]
		if -3 <> typed-value-as-integer list [return 29]
		if -1 <> list/_padding [return 30]
		list: list + 1
		if type-uint64! <> list/type [return 28]
		if -1 <> typed-value-as-integer list [return 31]
		if 0 <> list/_padding [return 32]
		0
	]

	check: func [
		return: [integer!]
		/local
			i8  [int8!]
			u8  [uint8!]
			i16 [int16!]
			u16 [uint16!]
			box [arm64-fixed-box!]
			nested [arm64-fixed-nested!]
	][
		i8: (as int8! -100) + (as int8! 7)
		if i8 <> as int8! -93 [sys-exit 1]

		i8: (as int8! -100) * (as int8! 7)
		if i8 <> as int8! 68 [sys-exit 2]

		i8: (as int8! -100) % (as int8! 7)
		if i8 <> as int8! -2 [sys-exit 3]

		i8: (as int8! -100) // (as int8! 7)
		if i8 <> as int8! 5 [sys-exit 4]

		i8: (as int8! -64) >>> 2
		if i8 <> as int8! 48 [sys-exit 5]

		u8: (as uint8! 250) + (as uint8! 10)
		if u8 <> as uint8! 4 [sys-exit 6]

		u8: (as uint8! 250) % (as uint8! 11)
		if u8 <> as uint8! 8 [sys-exit 7]

		u8: (as uint8! 240) >>> 4
		if u8 <> as uint8! 15 [sys-exit 8]

		i16: (as int16! -21846) or (as int16! 3855)
		if i16 <> as int16! -20561 [sys-exit 9]

		u16: (as uint16! 60000) xor (as uint16! 3855)
		if u16 <> as uint16! 58735 [sys-exit 10]

		box: declare arm64-fixed-box!
		nested: declare arm64-fixed-nested!
		box/i: 1234
		box/f: 9.75
		nested/value/ptr: :box/i
		nested/value/fptr: as pointer! [float!] :box/f
		if nested/value/ptr <> :box/i [sys-exit 11]
		if nested/value/fptr <> as pointer! [float!] :box/f [sys-exit 12]
		if nested/value/ptr/value <> 1234 [sys-exit 13]
		if nested/value/fptr/value <> 9.75 [sys-exit 14]
		nested/value/ptr/value: -1234
		nested/value/fptr/value: 19.5
		if box/i <> -1234 [sys-exit 15]
		if box/f <> 19.5 [sys-exit 16]

		0
	]

	result: check
	if result <> 0 [sys-exit result]
	result: typed-check [
		as int8! -2
		as uint8! 250
		as int16! -300
		as uint16! 60000
		as int32! -123456
		as uint32! 4294967295
		as int64! -3
		as uint64! 4294967295
	]
	sys-exit result
]
