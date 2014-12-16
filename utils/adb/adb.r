REBOL [
	Title:   "Android Debug Bridge"
	Author:  "Qingtian Xie"
	File: 	 %adb.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

adb: context [
	PACKET_SIZE:   1024 * 64			;-- 64KB
	MAX_PAYLOAD:   4096
	A_SYNC:        to-integer #{434e5953}
	A_CNXN:        to-integer #{4e584e43}
	A_OPEN:        to-integer #{4e45504f}
	A_OKAY:        to-integer #{59414b4f}
	A_CLSE:        to-integer #{45534c43}
	A_WRTE:        to-integer #{45545257}
	A_VERSION:     to-integer #{01000000}

	message: make struct! [
		command 	[integer!]			;-- command identifier constant
		arg0		[integer!]			;-- first argument
		arg1		[integer!]			;-- second argument
		data-length	[integer!]			;-- length of payload (0 is allowed)
		data-crc32	[integer!]			;-- crc32 of data payload
		magic		[integer!]			;-- command ^ 0xffffffff
	] none

	syncmsg: make struct! [
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
	lpDWORD: 	  make struct! [int [integer!]] none
	make-lpDWORD: does [make struct! lpDWORD [0]]

	make-null-string: func [len [integer!]][
		head insert/dup make string! len null len
	]

	usb-mode: no
	usb: none
	switch/default fourth system/version [
		2 [print "Not Support yet" "Darwin"]
		3 [usb: do bind load %usb-windows.r 'self]
		7 [print "Not Support yet" "FreeBSD"]
	][
		print "Not Support yet" "Linux"
	]

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

	receive-message: func [
		device		[object!]
		cmd			[string!]
	][
		either usb-mode [
			usb/receive-message device cmd
		][
			;-- TCP mode
		]
	]

	send-message: func [
		device		[object!]
		cmd			[integer!]
		data		[string! binary!]
	][
		either usb-mode [
			usb/send-message device cmd data
		][
			;-- TCP mode
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
		msg: make struct! syncmsg reduce [ID_SEND length? data]
		send-message device A_WRTE third msg

		file: read/binary apk-path
		until [
			packet: copy/part file file: skip file PACKET_SIZE
			msg: make struct! syncmsg reduce [ID_DATA length? packet]
			append data third msg
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

		msg: make struct! syncmsg reduce [ID_DONE modified-time? apk-path]
		send-message device A_WRTE third msg
		receive-message device "WRTE"

		msg: make struct! syncmsg reduce [ID_QUIT 0]
		send-message device A_WRTE third msg
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
