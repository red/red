REBOL [
	Title:   "Android Debug Bridge"
	Author:  "Qingtian Xie"
	File: 	 %adb.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

adb: context [
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

	PACKET_SIZE:   1024 * 64			;-- 64KB
	MAX_PAYLOAD:   4096
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

	make-int-ptr: func [n [integer!]][
		make struct! [int [integer!]] reduce [n]
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
		usb-class	 [integer!]
		usb-subclass [integer!]
		usb-protocol [integer!]
	][
		either all [
			find vendor-ids to-hex16 vendor-id
			usb-class = ADB_CLASS
			usb-subclass = ADB_SUBCLASS
			usb-protocol = ADB_PROTOCOL
		][true][false]
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

	platform-file: switch/default fourth system/version [
		2 [%usb-osx.r]
		3 [%usb-windows.r]
		7 [print "FreeBSD: Not Support yet" halt]
	][
		%usb-linux.r
	]

	usb: none
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
		cmd			[string!]
		/local buffer recv-cmd msg data
	][
		until [
			buffer: make-null-string MAX_PAYLOAD
			read-device device buffer
			buffer: trim buffer
			if empty? buffer [return buffer]
			recv-cmd: copy/part buffer 4
			msg: to-struct message! buffer
			any [cmd = "ALL" cmd = recv-cmd]
		]
		switch cmd [
			"ALL"  [buffer]
			"OKAY" [
				device/remote-id: msg/arg0
			]
			"CNXN" [
				if positive? msg/data-length [buffer: receive-message device "ALL"]
			]
			"WRTE" [
				data: receive-message device "ALL"
				if ID_FAIL = copy/part data 4 [
					close-device device
					print ["**ADB**: Error:" data]
					halt
				]
				send-message device A_OKAY ""
			]
			"CLSE" [
				send-message device A_CLSE ""
			]
		]
		buffer
	]

	send-message: func [
		device		[object!]
		cmd			[integer!]
		data		[string! binary!]
		/local len sum msg magic
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
			any [cmd = A_WRTE cmd = A_OKAY] [
				msg: [cmd device/local-id device/remote-id len sum magic]
			]
		]
		write-device device form-struct make struct! message! reduce msg
		unless empty? data [write-device device data]
		if cmd = A_WRTE [
			if empty? receive-message device "OKAY" [
				print "**ADB**: Error: Send message failed"
				print ["message: " data]
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
		data: receive-message device "CNXN"
		unless empty? data [
			print ["** Installing to device:" get-device-name data]
		]
		send-message device A_OPEN "sync:^@"
		receive-message device "OKAY"

		remote-path: push device apk-path

		prin "** Installing..."
		cmd: rejoin ["shell:pm install " remote-path #"^@"]
		device/local-id: 3
		send-message device A_OPEN cmd
		receive-message device "OKAY"
		for x 1 3 1 [
			until [
				data: receive-message device "WRTE"
				prin "."
				not empty? data
			]
		]
		print [lf "** Success."]
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
