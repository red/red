Red [
	Title:   "GPIO port scheme"
	Author:  "Nenad Rakocevic"
	File: 	 %GPIO.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {Low-level GPIO code largely inspired by http://wiringpi.com/}
]

gpio-scheme: context [

	#system [
		gpio: context [
			#import [
				LIBC-file cdecl [
					mmap: "mmap" [
						address		[byte-ptr!]
						size		[integer!]
						protection	[integer!]
						flags		[integer!]
						fd			[integer!]
						offset		[integer!]
						return:		[byte-ptr!]
					]
					munmap: "munmap" [
						address		[byte-ptr!]
						size		[integer!]
						return:		[integer!]
					]
				]
			]

			#define GPIO_PERIPH_RPI23	3F000000h		;-- RPi 2 & 3 peripherals
			#define GPIO_PERIPH_RPI01	20000000h		;-- RPi zero & 1 peripherals
			#define GPIO_OFFSET			00200000h

			#enum gpio-pins! [
				GPFSEL0:   	00h
				GPFSEL1:   	04h
				GPFSEL2:   	08h
				GPFSEL3:   	0Ch
				GPFSEL4:   	10h
				GPFSEL5:   	14h
				GPSET0:    	1Ch
				GPSET1:    	20h
				GPCLR0:    	28h
				GPCLR1:    	2Ch
				GPLEV0:    	34h
				GPLEV1:    	38h
				GPEDS0:    	40h
				GPEDS1:    	44h
				GPREN0:    	4Ch
				GPREN1:    	50h
				GPFEN0:    	58h
				GPFEN1:    	5Ch
				GPHEN0:    	64h
				GPHEN1:    	68h
				GPLEN0:    	70h
				GPLEN1:    	74h
				GPAREN0:   	7Ch
				GPAREN1:   	80h
				GPAFEN0:   	88h
				GPAFEN1:   	8Ch
				GPPUD:     	94h
				GPPUDCLK0: 	98h
				GPPUDCLK1: 	9Ch
			]

			#enum pin-modes! [
				MODE_INPUT: 0
				MODE_OUTPUT
				MODE_PWM_OUTPUT
				MODE_GPIO_CLOCK
				MODE_4									;-- not defined yet
				MODE_5
				MODE_6
			]

			#enum pull-updown! [
				PUD_OFF: 0
				PUD_DOWN
				PUD_UP
			]

			#enum pin-values! [
				LOW: 0
				HIGH
			]

			set-mode: func [
				base [byte-ptr!]
				pin	 [integer!]
				mode [integer!]
				/local
					GPFSEL [int-ptr!]
					index  [integer!]
					shift  [integer!]
					mask   [integer!]
			][
				index: pin * CDh >> 11
				shift: pin - (index * 10) * 3
				GPFSEL: as int-ptr! (base + (index << 2))
				mask: GPFSEL/value and not (7 << shift)
				GPFSEL/value: mode << shift or mask
			]

			set: func [
				base [byte-ptr!]
				pin	  [integer!]
				high? [logic!]
				/local
					p	  [int-ptr!]
					index [integer!]
					bit	  [integer!]
					mode  [integer!]
			][
				index: pin >> 3							;-- pin >> 5 * 4
				bit: 1 << (pin and 31)

				mode: either high? [GPSET0][GPCLR0]
				p: as int-ptr! (base + mode + index)
				p/value: bit
			]

			get: func [
				base    [byte-ptr!]
				pin	    [integer!]
				return: [integer!]
				/local
					p	  [int-ptr!]
					bit	  [integer!]
			][
				bit: 1 << (pin and 31)
				p: as int-ptr! (base + GPLEV0)
				either p/value and bit <> 0 [1][0]
			]

			set-pull: func [
				base	[byte-ptr!]
				pin		[integer!]
				pud		[integer!]
				/local
					p	[int-ptr!]
			][
				p: as int-ptr! (base + GPPUD)
				p/value: pud and 3
				platform/usleep 5

				p: as int-ptr! (base + GPPUDCLK0)
				p/value: 1 << (pin and 31)
				platform/usleep 5

				p: as int-ptr! (base + GPPUD)
				p/value: 0
				platform/usleep 5

				p: as int-ptr! (base + GPPUDCLK0)
				p/value: 0
				platform/usleep 5
			]
		]
	]
	
	models: [
	;-- Name ---------- Mapping --
		"Model A"		old
		"Model B"		old
		"Model A+"		old
		"Model B+"		old
		"Pi 2"			new
		"Alpha"			old
		"CM"			old
		"Unknown07"		new
		"Pi 3"			new
		"Pi Zero"		old
		"CM3"			new
		"Unknown11"		new
		"Pi Zero-W"		old
		"Pi 3B+"		new
		"Pi 3A+"		new
		"Unknown15"		new
		"CM3+"			new
		"Unknown17"		new
		"Unknown18"		new
		"Unknown19"		new
	]
	
	gpio.open: routine [
		state [block!]
		old?  [logic!]
		/local
			handle [red-handle!]
			fd	   [integer!]
			model  [integer!]
			base   [byte-ptr!]
	][
		fd: platform/io-open "/dev/gpiomem" 00101002h	;-- O_RDWR or O_SYNC
		if fd > 0 [
			handle: as red-handle! block/rs-head state
			handle/header: TYPE_HANDLE
			handle/value: fd
			model: either old? [GPIO_PERIPH_RPI01][GPIO_PERIPH_RPI23]

			base: gpio/mmap null 4096 MMAP_PROT_RW MMAP_MAP_SHARED fd model or GPIO_OFFSET
			if any [
				(as-integer base) > 0
				-1024 < as-integer base					;-- check if not in the error codes range
			][
				handle: handle + 1
				handle/header: TYPE_HANDLE
				handle/value: as-integer base
			]
		]
	]
	
	gpio.set-mode: routine [base [handle!] pin [integer!] mode [integer!]][
		gpio/set-mode as byte-ptr! base/value pin mode - 1
	]
	
	gpio.set: routine [base [handle!] pin [integer!] value [integer!]][
		gpio/set as byte-ptr! base/value pin as-logic value
	]
	
	gpio.set-pull: routine [base [handle!] pin [integer!] value [integer!]][
		gpio/set-pull as byte-ptr! base/value pin value - 1
	]
	
	gpio.get: routine [base [handle!] pin [integer!] return: [integer!]][
		gpio/get as byte-ptr! base/value pin
	]

	gpio.close: routine [
		state [block!]
		/local
			handle [red-handle!]
	][
		handle: as red-handle! (block/rs-head state) + 1
		if zero? gpio/munmap as byte-ptr! handle/value 4096 [handle/header: TYPE_NONE]
		handle: handle - 1
		if zero? platform/io-close handle/value [handle/header: TYPE_NONE]
	]
	
	gpio.pause: routine [us [integer!]][platform/usleep us]

	;--- Port actions ---

	open: func [port /local state info revision model][
		unless attempt [info: read %/proc/cpuinfo][
			cause-error 'access 'cannot-open ["cannot access /proc/cpuinfo"]
		]
		parse/case info [thru "Revision" thru #":" any #" " copy revision to lf]
		revision: to-integer debase/base revision 16
		model: FFh << 4 and revision >> 4
		
		state: port/state: copy [none none]				;-- fd (handle!), base (handle!)
		gpio.open port/state 'old = pick models model + 1 * 2 	;-- model is 0-based
		
		case [
			none? state/1 [cause-error 'access 'cannot-open ["failed to open /dev/gpiomem"]]
			none? state/2 [cause-error 'access 'cannot-open ["mmap() failed"]]
		]
	]
	
	insert: func [port data [block!] /local s base modes value pulls pos m list d][
		unless all [block? s: port/state parse s [2 handle!]][
			cause-error 'access 'not-open ["port/state is invalid"]
		]
		base: port/state/2
		
		modes: ['in (m: 1) | 'out (m: 2) | 'pwm (m: 3)]					;-- order matters
		value: [m: logic! | ['on | 'high] (m: yes) | ['off | 'low] (m: no) | m: integer!]
		pulls: ['pull-off (m: 1) | 'pull-down (m: 2) | 'pull-up (m: 3)] ;-- order matters
		list: none
		
		unless parse data [
			some [pos:
				  'set-mode    integer! modes (gpio.set-mode base pos/2 m)
				| 'set         integer! value (gpio.set base pos/2 make integer! m)
				| pulls        integer!       (gpio.set-pull base pos/2 m)
				| 'get         integer!       (d: gpio.get base pos/2
					switch/default type?/word list [
						block! [append list d]
						none!  [list: d]
					][append list: reduce [list] d]
				)
				| 'pause integer! (gpio.pause pos/2)
			]
		][cause-error 'access 'invalid-cmd [data]]
		
		port/data: list
	]

	close: func [port /local state][
		gpio.close state: port/state
		case [
			handle? state/1 [cause-error 'access 'cannot-close ["failed to close /dev/gpiomem"]]
			handle? state/2 [cause-error 'access 'cannot-close ["mmunap() failed"]]
		]
	]
]

register-scheme make system/standard/scheme [
	name: 'GPIO
	title: "GPIO access for Raspberry Pi boards"
	actor: gpio-scheme
]


#example [
	p: open gpio://

	insert p [set-mode 4 out]
	loop 20 [
		insert p [set 4 on]
		wait 0.1
		insert p [set 4 off]
		wait 0.1
	]

	insert p [
		set-mode 17 in
		pull-down 17
	]
	loop 10 [
		insert p [get 17]
		probe p/data
		wait 0.5
	]

	close p
 ]
