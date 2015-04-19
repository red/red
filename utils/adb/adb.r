REBOL [
	Title:   "Android Debug Bridge"
	Author:  "Qingtian Xie"
	File: 	 %adb.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

adb: context [
	rsa-key: make object! [
		n: #{CFEBB5D9A507B66F4DF4F000DB98667BA4E7DA8CE0D055A70B6DC3221C14583EB4F8C001A836E331FB2EE928250668020232D730AF36E035F3DF94BC64FC8A3635C06040B2007F55BCF9EE4F07EF846F05AF5915E090DB6876C95EC80A447D0DEBE8D82714876BD3C937CF4CCA842787D3BE2CC50BC575E18D471603BC0F4BD8132561343F0BC8F7FD94336ECAF93A06624755A4F97F4A852EE94CF2B794A39571473C1F74FC0311C3FF25AAA366F52341353B9AD2DB3FBE4E0407380D9EC1B2DA8D990A0A4A9AB2D859D9A0242D9C550AF4275BF04C5508B95236B3952C6651D1B2857206245FBB56EDFF38BC2A700ABA6072497EAA26CFCE1F66766E722C27}
		e: 65537
		d: #{339AE335B3BA285393DBB93DDD43041CA81F4BA52F9F45C302192A176B34B97A46DC7E7B6ACEC4B10110F1999F26E9E5A5BA0CA2EEBA06081E115E0F2C5969CC6EA6E2BCEBF127A9960FCA501F3E19769CC89AA9CD64E6B014DB8204D057935A43353580ED9D76EBC7C36C5638E578124441AD46F2D6FD9D0FBD96FF324BF19CAB0056EA87F14589C3FFE04F01B78CAE01DA35B3D4DAFD932B2BD155ACDB8AC280B5EFD59A945DD90D8CEE93BDABAF5084D5BAAB350526D1ABDEB0F84324E223D07341D0138690C9EE2F80E8ECB6DC861B09D88C9CBA9CC8C868C6524007A659C24937814985E82ADCC526C481B74FF1111F15D97398AC6B87BEBD563D7770D1}
		p: #{EDB9D1D0CAF87CF2A4A28C5C3DB8FC363D9B3A8BDEEB8D5B53658FB5A373E887259389900F647DA0DF8F30B4FC612E0C185E406BCF22F926038CA9FF78E084284CFAE2F84E8A3B0B0A05B7485FB372C55FF4EACB60392BEB977DE7470C4A4B3E1FEB3F9092B58350FF4A93ED5AF8F428A5408D9880A9E6ADB06CE6FF9E06B855}
		q: #{DFE75BF92CB077E211BFD1F618AF189D54DC155651352D1796D930C41C52F938BC111C9CC496CA6253FDB1C71830BA56D5A49844E54EC4B5859AF379CC88855C2DB5AD7C936362F3E6BB6457BDEEF3F0F016D1B1B00930AD7F3A4883B22EA6AF766DF204D085B7CBBF7AD24AA5E8E76EDC6EC23747CFD6CF1BFE46DA8509BE8B}
		dmp1: #{81C69C3CF06100CCF1856F3C77D1819616C1A40F716D83E8A439605F975092531CF752F49B028FF67FB4CAB132C9D67A71DF1A2A009526105385B9D42667E29DA190A0D14F06F53E8C851C4E5D3838627984D99C96F5FEFD08E1899D669F343E40EC8AF1E0B5486FB23E434D23099F3885261D66706ECFE867D4BBB235D19355}
		dmq1: #{6414D849A2AE268808830368CB53C8DEDA859D8BFDB495394C163CF40BED12B5476B26ACF43AAAB014F6FB36111C06CEB5A462E3B8D3E29D78E0F01FEB4AC2C19734F41D110C85B89BD3FB6034E7D0664C0B072433998806A52DFA27D3C7827E3FA39960898C9BC1190FDF5BBA994689894280D190E9D80CAF6893672DBC534D}
		iqmp: #{489FC5D855BE388CE68CA7B47A17D41E26194A4942B91B9A8FB7689134E23A62F9C3A884C8479254039F28919595C62C029AFBD8139C3C5005B199459E95E398C846781494E43DCFBE49A1FEDC8703B7DDAB0A32608C34B3B2F52142456AADE916955901F3221DDBA9A2B8CC73F7CC12215F89C526FAA147A8B4775CF9E6FB5A}
		n-mont-ri: none
		n-mont-rr: none
		n-mont-n: none
		n-mont-ni: none
		n-mont-n0: none
		n-mont-flags: none
		p-mont-ri: none
		p-mont-rr: none
		p-mont-n: none
		p-mont-ni: none
		p-mont-n0: none
		p-mont-flags: none
		q-mont-ri: none
		q-mont-rr: none
		q-mont-n: none
		q-mont-ni: none
		q-mont-n0: none
		q-mont-flags: none
	]
	adb-public-key: {QAAAAGl8j+QnLHJudmYfzs8mqn5JcmC6CnAqvDj/7Va7XyQGcoWy0VFmLJWzNlK5CFVM8Fsn9ApVnC0koNlZ2LKaSgoKmY3assGeDTgHBE6+P9vSmjs1QSP1ZqOqJf/DEQP8dB88R3GVo5S38kzpLoVKf/mkVUdiBjr5ym4zlP33yAs/NGElE9hLD7wDFkeN4XXFC8UsvtOHJ4TKTM83ydNrhxQn2OjrDX1ECsheyXZo25DgFVmvBW+E7wdP7vm8VX8AskBgwDU2ivxkvJTf8zXgNq8w1zICAmgGJSjpLvsx4zaoAcD4tD5YFBwiw20Lp1XQ4Iza56R7ZpjbAPD0TW+2B6XZtevPUVQvVlAOZVaeKDe8G6BtO4sqUhASmZuAeziiqKJgpSRr9qOFw6mqQP8ELVtmaN2u+dbqE/0KWtOt+Skm7f5cd8NDSSPRZhEVR7OP+qs03oNl0llZxJI67ZbuHXGgD3IRSUn8lM9+jf0ONhYo3C/g9MIbRWpZhnZRcLZw5AwjEno5tzYb/xVcDyUDqr96U8f0ZwRk/cYDTpmRYpF2/o5vLD8KC7RknRknQi/PV5ABDCeBBZAobppJfqG01pA2xdXsVAU2vV/bVrT9KU7MaoEfxcky8uO3A8Wjc5C9aM0tsQVQt96WxoSOzuSIk2oO1FfML6bcUM6JFtToqP/46Dw2pwEAAQA= unknown@unknown^@}

	ADB_CLASS:		to-integer #{FF}
	ADB_SUBCLASS:	to-integer #{42}
	ADB_PROTOCOL:	to-integer #{01}
	vendor-ids: [
		#{0502} #{1914} #{1F3A} #{1b8e} #{16D5} #{0E79} #{0b05} #{1D91} #{04B7}
		#{1219} #{413c} #{03fc} #{297F} #{2207} #{0489} #{04C5} #{0F1C} #{091E}
		#{0414} #{1E85} #{271D} #{18d1} #{201E} #{19A5} #{109b} #{0c2e} #{03f0}
		#{0bb4} #{12D1} #{2314} #{8087} #{067e} #{2420} #{24E3} #{2116} #{2237}
		#{0482} #{1949} #{17EF} #{2006} #{1004} #{25E3} #{2A96} #{22b8} #{0DB0}
		#{0e8d} #{0409} #{2080} #{0955} #{22D9} #{2257} #{2836} #{10A9} #{1D4D}
		#{0471} #{04DA} #{1662} #{29e4} #{1D45} #{05c6} #{0408} #{1532} #{2207}
		#{04e8} #{04dd} #{1F53} #{29a9} #{1d9c} #{054C} #{0FCE} #{1BBB} #{1d09}
		#{2340} #{0451} #{0930} #{1E68} #{2A49} #{E040} #{0531} #{2717} #{2916}
		#{1EBF} #{19D2}
	]

	;-- Descriptor types ... USB 2.0 spec table 9.5
	USB_DT_DEVICE:					1
	USB_DT_CONFIG:					2
	USB_DT_STRING:					3
	USB_DT_INTERFACE:				4
	USB_DT_ENDPOINT:				5
	USB_DT_DEVICE_QUALIFIER:		6
	USB_DT_OTHER_SPEED_CONFIG:		7
	USB_DT_INTERFACE_POWER:			8
	;; these are from a minor usb 2.0 revision (ECN)
	USB_DT_OTG:						9
	USB_DT_DEBUG:					10
	USB_DT_INTERFACE_ASSOCIATION:	11

	;-- Endpoints
	USB_ENDPOINT_NUMBER_MASK:		to-integer #{0F}	;-- in bEndpointAddress
    USB_ENDPOINT_DIR_MASK:			to-integer #{80}

    USB_ENDPOINT_XFERTYPE_MASK:		to-integer #{03}	;-- in bmAttributes
    USB_ENDPOINT_XFER_CONTROL:		0
    USB_ENDPOINT_XFER_ISOC:			1
    USB_ENDPOINT_XFER_BULK:			2
    USB_ENDPOINT_XFER_INT:			3
    USB_ENDPOINT_MAX_ADJUSTABLE:	128

	AUTH_TOKEN:						1
	AUTH_SIGNATURE:					2
	AUTH_RSAPUBLICKEY:				3

	PACKET_SIZE:   1024 * 64			;-- 64KB
	MAX_PAYLOAD:   4096
	A_AUTH:        to-integer #{48545541}
	A_SYNC:        to-integer #{434e5953}
	A_CNXN:        to-integer #{4e584e43}
	A_OPEN:        to-integer #{4e45504f}
	A_OKAY:        to-integer #{59414b4f}
	A_CLSE:        to-integer #{45534c43}
	A_WRTE:        to-integer #{45545257}
	A_VERSION:     to-integer #{01000000}

	message!: make struct! [
		command 	[integer!]			;-- command identifier constant
		arg0		[integer!]			;-- first argument
		arg1		[integer!]			;-- second argument
		data-length	[integer!]			;-- length of payload (0 is allowed)
		data-crc32	[integer!]			;-- crc32 of data payload
		magic		[integer!]			;-- command ^ 0xffffffff
	] none

	syncmsg!: make struct! [
		id		[integer!]
		size	[integer!]
	] none

	MKID: func [id][
		(to-integer id/1) or
		(shift/left to-integer id/2 8) or
		(shift/left to-integer id/3 16) or
		(shift/left to-integer id/4 24)
	]

	ID_STAT: MKID "STAT"
	ID_LIST: MKID "LIST"
	ID_ULNK: MKID "ULNK"
	ID_SEND: MKID "SEND"
	ID_RECV: MKID "RECV"
	ID_DENT: MKID "DENT"
	ID_DONE: MKID "DONE"
	ID_DATA: MKID "DATA"
	ID_OKAY: MKID "OKAY"
	ID_FAIL: MKID "FAIL"
	ID_QUIT: MKID "QUIT"

	null: 		  to-char 0
	form-struct:  :third

	to-struct: func [
		struct	[struct!]
		data	[string! binary!]
	][
		change third struct copy/part data length? third struct
		struct
	]

	make-int-ptr: func [n [integer! char!]][
		make struct! [int [integer!]] reduce [to-integer n]
	]

	make-null-string: func [len [integer!]][
		head insert/dup make string! len null len
	]

	to-hex16: func [v [integer! char!]][
		skip debase/base to-hex to integer! v 16 2
	]

	to-hex32: func [v [integer! char!]][
		debase/base to-hex to integer! v 16
	]

	adb-interface?: func [
		vendor-id	 [integer!]
		usb-class	 [integer! char!]
		usb-subclass [integer! char!]
		usb-protocol [integer! char!]
	][
		to-logic all [
			find vendor-ids to-hex16 vendor-id
			usb-class = ADB_CLASS
			usb-subclass = ADB_SUBCLASS
			usb-protocol = ADB_PROTOCOL
		]
	]

	usb-info!: make object! [
		device-set: 0
		device:		0					;-- device handle
		interface:	0					;-- interface handle
		read-id:	null				;-- read pipe id
		write-id:	null				;-- write pipe id
		local-id:	1
		remote-id:	0
		zero-mask:  0
	]

	platform-file: switch/default system/version/4 [
		2 [%usb-osx.r]
		3 [%usb-windows.r]
		7 [print "FreeBSD: Not Support yet" halt]
	][
		%usb-linux.r
	]

	usb: do bind load platform-file 'self
	usb-mode: no

	init-device: func [/local handle][
		if handle: usb/init-device [usb-mode: yes return handle]
		;else try TCP mode for simulator
	]

	close-device: func [
		device		[object!]
	][
		either usb-mode [
			usb/close-device device
		][
			;-- TCP mode
		]
	]

	read-device: func [
		device		[object!]
		data		[string! binary!]
	][
		either usb-mode [
			usb/pipe/read device data
		][
			;-- TCP mode
		]
	]

	write-device: func [
		device		[object!]
		data		[string! binary!]
	][
		either usb-mode [
			usb/pipe/write device data
		][
			;-- TCP mode
		]
	]

	receive-message: func [
		device		[object!]
		cmd			[string! block!]
		/waiting
		/authed
		/local buffer recv-cmd msg data signature
	][
		until [
			buffer: make-null-string MAX_PAYLOAD
			read-device device buffer
			recv-cmd: either buffer/1 = null [clear buffer][
				if cmd = "ALL" [return buffer]
				copy/part buffer 4
			]
			if waiting [prin "."]
			find cmd recv-cmd
		]
		msg: to-struct message! buffer

		switch/default recv-cmd [
			"AUTH" [
				data: receive-message device "ALL"
				either authed [
					send-message/authed device A_AUTH adb-public-key		;-- send public key
					print [
						"**ADB**: Please check the confirmation dialog on your device." lf
						"**ADB**: Waiting for device."
					]
				][
					data: join #{3021300906052B0E03021A05000414} copy/part data msg/data-length
					signature: rsa-encrypt/private rsa-key data
					send-message device A_AUTH signature
				]
				receive-message/waiting/authed device ["AUTH" "CNXN"]
			]
			"OKAY" [
				device/remote-id: msg/arg0
			]
			"CNXN" [
				if positive? msg/data-length [
					data: receive-message device "ALL"
					print ["** Installing to device:" get-device-name data]
				]
			]
			"WRTE" [
				buffer: receive-message device "ALL"
				send-message device A_OKAY ""
			]
			"CLSE" [
				send-message device A_CLSE ""
			]
		][buffer]
		buffer
	]

	send-message: func [
		device		[object!]
		cmd			[integer!]
		data		[string! binary!]
		/authed
		/local len sum msg magic arg0
	][
		if binary? data [data: to-string data]
		magic: cmd xor -1
		len: length? data
		sum: 0
		foreach c data [sum: sum + (to-integer c)]
		case [
			cmd = A_CNXN [
				msg: [cmd A_VERSION MAX_PAYLOAD len sum magic]
			]
			cmd = A_OPEN [
				msg: [cmd device/local-id 0 len sum magic]
			]
			cmd = A_CLSE [
				msg: [cmd 0 device/remote-id len sum magic]
			]
			cmd = A_AUTH [
				arg0: either authed [AUTH_RSAPUBLICKEY][AUTH_SIGNATURE]
				msg: [cmd arg0 0 len sum magic]
			]
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd device/local-id device/remote-id len sum magic]
			]
		]
		write-device device form-struct make struct! message! reduce msg
		unless empty? data [write-device device data]
		if cmd = A_WRTE [
			if empty? receive-message device "OKAY" [
				print "**ADB**: Error: Send message failed"
				print ["message: " copy/part data 4]
				close-device device
				halt
			]
		]
	]

	modified-time?: func [file-path /local date][
		date: modified? file-path
		(date - 1970-1-1) * 24 * 3600 + (to-integer date/time - date/zone)
	]

	file-size?: func [file-path /local size unit][
		unit: "KB"
		size: (size? file-path) / 1000
		if size > 1000 [size: size / 1000 unit: "MB"]
		join to-string size unit
	]

	get-device-name: func [data][
		attempt [
			data: parse data ";"
			data: parse data/1 "="
			data/2
		]
	]

	push: func [
		device		[object!]
		apk-path	[file!]
		/local apk-name remote-path msg data file packet
	][
		apk-name: pick split-path apk-path 2
		remote-path: join "/data/local/tmp/" apk-name
		print ["** Transferring:" remote-path "(" file-size? apk-path ")"]

		data: join remote-path ",33206"
		msg: make struct! syncmsg! reduce [ID_SEND length? data]
		send-message device A_WRTE form-struct msg

		file: read/binary apk-path
		until [
			packet: copy/part file file: skip file PACKET_SIZE
			msg: make struct! syncmsg! reduce [ID_DATA length? packet]
			append data form-struct msg
			while [true][
				append data copy/part packet packet: skip packet MAX_PAYLOAD - length? data
				either MAX_PAYLOAD = length? data [
					send-message device A_WRTE data
					clear data
				][break]
			]
			empty? file
		]
		unless empty? data [send-message device A_WRTE data]

		msg: make struct! syncmsg! reduce [ID_DONE modified-time? apk-path]
		send-message device A_WRTE form-struct msg
		receive-message device "WRTE"

		msg: make struct! syncmsg! reduce [ID_QUIT 0]
		send-message device A_WRTE form-struct msg
		receive-message device "CLSE"
		print ["** Transferring: Done" ]
		remote-path
	]

	install: func [
		device		[object!]
		apk-path	[file!]
		/local data remote-path cmd
	][
		send-message device A_CNXN "host::^@"
		receive-message device ["AUTH" "CNXN"]
		send-message device A_OPEN "sync:^@"
		receive-message device "OKAY"

		remote-path: push device apk-path

		prin "** Installing.."
		cmd: rejoin ["shell:pm install " remote-path #"^@"]
		device/local-id: 3
		send-message device A_OPEN cmd
		receive-message device "OKAY"
		until [
			prin "."
			data: receive-message device "WRTE"
			parse data [["Success" | "Fail"] to end]
		]
		print [lf "**" data]
		receive-message device "CLSE"

		cmd: rejoin ["shell:rm " remote-path #"^@"]
		device/local-id: 5
		send-message device A_OPEN cmd
		receive-message device "OKAY"
		receive-message device "CLSE"
	]
]

;-- test
device: adb/init-device
adb/install device %/C/ProgramData/Red/builds/eval.apk
adb/close-device device
