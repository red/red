REBOL [
	Title:   "Android Debug Bridge - USB Linux"
	Author:  "Qingtian Xie"
	File: 	 %usb-linux.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

context [
	any [
		exists? libc: %libc.so.6
		exists? libc: %/lib32/libc.so.6
		exists? libc: %/lib/i386-linux-gnu/libc.so.6	; post 11.04 Ubuntu
		exists? libc: %/usr/lib32/libc.so.6				; e.g. 64-bit Arch Linux
		exists? libc: %/lib/libc.so.6
		exists? libc: %/System/Index/lib/libc.so.6  	; GoboLinux package
		exists? libc: %/system/index/framework/libraries/libc.so.6  ; Syllable
		exists? libc: %/lib/libc.so.5
	]
	libc: load/library libc

	O_RDONLY:	0
	O_WRONLY:	1
	O_RDWR: 	2
	O_CLOEXEC:	524288
	
	USB_DT_DEVICE_SIZE:				18
	USB_DT_CONFIG_SIZE:				9
	USB_DT_INTERFACE_SIZE:			9
	USB_DT_ENDPOINT_SIZE:			7
	USB_DT_ENDPOINT_AUDIO_SIZE:		9

	USBDEVFS_URB_SHORT_NOT_OK:		to-integer #{01}
    USBDEVFS_URB_ISO_ASAP:			to-integer #{02}
    USBDEVFS_URB_BULK_CONTINUATION:	to-integer #{04}
    USBDEVFS_URB_NO_FSBR:			to-integer #{20}
    USBDEVFS_URB_ZERO_PACKET:		to-integer #{40}
    USBDEVFS_URB_NO_INTERRUPT:		to-integer #{80}

    USBDEVFS_URB_TYPE_ISO:			0
    USBDEVFS_URB_TYPE_INTERRUPT:	1
    USBDEVFS_URB_TYPE_CONTROL:		2
    USBDEVFS_URB_TYPE_BULK:			3

	USBDEVFS_CONTROL:				-1072671488
	USBDEVFS_BULK:              	-1072671486
	USBDEVFS_SUBMITURB:         	-2144578294
	USBDEVFS_DISCARDURB:        	21771
	USBDEVFS_REAPURB:           	1074025740
	USBDEVFS_REAPURBNDELAY:     	1074025741
	USBDEVFS_CLAIMINTERFACE:    	-2147199729

	device-descriptor!: make struct! [
		length				[char]
		type				[char]
		bcd-USB				[short]
		class				[char]
		subclass			[char]
		protocol			[char]
		max-packet-size		[char]
		vendor-id			[short]
		product-id			[short]
		bcd-device			[short]
		manufacturer		[char]
		product				[char]
		serial-number		[char]
		num-of-configs		[char]
	] none

	config-descriptor!: make struct! [
		length				[char]
		type				[char]
		total-length		[short]
		num-of-interfaces	[char]
		value				[char]
		config				[char]
		attributes			[char]
		max-power			[char]
	] none

	interface-descriptor!: make struct! [
		length				[char]
		type				[char]
		interface-number	[char]
		alt-setting			[char]
		num-of-endpoints	[char]
		class				[char]
		subclass			[char]
		protocol			[char]
		interface			[char]
	] none

	endpoint-descriptor!: make struct! [
		length				[char]
		type				[char]
		address				[char]
		attributes			[char]
		max-packet-size		[short]
		interval			[char]

		;-- NOTE: these two are _only_ in audio endpoints.
		;-- use USB_DT_ENDPOINT*_SIZE in length, not sizeof.
		refresh				[char]
		sync-address		[char]
	] none

	devfs-bulktransfer!: make struct! [
		endpoint	[integer!]
		data-len	[integer!]
		timeout		[integer!]
		data		[string!]
	] none

	unix-open: make routine! [
		name		[string!]
		flags		[integer!]
		return:		[integer!]
	] libc "open"

	unix-close: make routine! [
		fd			[integer!]
		return:		[integer!]
	] libc "close"

	ioctl: make routine! [
		descriptor	[integer!]
		request		[integer!]
		arg			[struct! [a [integer!]]]
		return:		[integer!]
	] libc "ioctl"

	recognize-device: func [
		pathname	[file!]
		/local data device config length type interface int-ptr ep1 ep2 usb
	][
		unless attempt [						;-- device's name must be digits
			to-integer pick split-path pathname 2
		][return none]

		usb: make usb-info! []
		usb/device: unix-open to-string pathname O_RDWR or O_CLOEXEC
		if negative? usb/device [return none]	;-- read-only, we need write permission
	
		data: read/binary pathname
		if USB_DT_DEVICE_SIZE + USB_DT_CONFIG_SIZE > length? data [return none]

		device: to-struct device-descriptor! data
		data: skip data USB_DT_DEVICE_SIZE
		if any [
			device/length <> USB_DT_DEVICE_SIZE 
			device/type <> USB_DT_DEVICE
		][return none]

		config: to-struct config-descriptor! data
		data: skip data USB_DT_CONFIG_SIZE
		if any [
			config/length <> USB_DT_CONFIG_SIZE
			config/type <> USB_DT_CONFIG
		][return none]
		
		while [not empty? data][
			length: data/1
			type: data/2
			either type = USB_DT_INTERFACE [
				interface: to-struct interface-descriptor! data
				data: skip data length
				if all [
					interface/num-of-endpoints = 2
					adb-interface? device/vendor-id interface/class interface/subclass interface/protocol
				][
					ep1: to-struct endpoint-descriptor! data
					data: skip data USB_DT_ENDPOINT_SIZE
					ep2: to-struct endpoint-descriptor! data
					data: skip data USB_DT_ENDPOINT_SIZE
					if any [
						ep1/length <> USB_DT_ENDPOINT_SIZE
						ep1/type <> USB_DT_ENDPOINT
						ep2/length <> USB_DT_ENDPOINT_SIZE
						ep2/type <> USB_DT_ENDPOINT
					][return none]

					if all [
						ep1/attributes = USB_ENDPOINT_XFER_BULK
						ep2/attributes = USB_ENDPOINT_XFER_BULK
					][
						if interface/protocol = 1 [
							usb/zero-mask: ep1/max-packet-size - 1
						]
						either zero? ep1/address and USB_ENDPOINT_DIR_MASK [
							usb/read-id: ep2/address
							usb/write-id: ep1/address
						][
							usb/read-id: ep1/address
							usb/write-id: ep2/address			
						]
						int-ptr: make-int-ptr interface/interface-number
						unless zero? ioctl usb/device USBDEVFS_CLAIMINTERFACE int-ptr [
							unix-close usb/device
							return none
						]
						return usb					;-- find the first android device
					]
				]
			][
				data: skip data length
			]
		]
	]

	init-device: func [
		/local bus-dir dev-dir usb-devs devices device
	][
		bus-dir: %/dev/bus/usb/
		usb-devs: load bus-dir
		foreach dir usb-devs [
			dev-dir: join bus-dir dir
			devices: load dev-dir
			foreach dev devices [
				if device: recognize-device join dev-dir dev [
					break
				]
			]
		]
		device
	]

	close-device: func [
		usb		[object!]
	][
		unless negative? usb/device [unix-close usb/device]
	]

	pipe: func [
		usb		[object!]
		data	[string! binary!]
		/write /read
		/local data-len bulk transferred
	][
		data-len: length? data
		bulk: make struct! devfs-bulktransfer! reduce [usb/write-id data-len 1000 data]
		either write [
			transferred: ioctl usb/device USBDEVFS_BULK bulk
			if all [
				positive? usb/zero-mask
				not empty? data
				zero? (usb/zero-mask and data-len)
			][
				pipe/write usb ""
			]
		][
			bulk/endpoint: usb/read-id
			transferred: ioctl usb/device USBDEVFS_BULK bulk
		]
		if write [
			if transferred <> data-len [
				close-device usb
				print ["**ADB**: Error: Write data failed"] halt
			]
		]
	]
]
