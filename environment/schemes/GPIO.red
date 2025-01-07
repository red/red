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
	Notes: {
		For Raspberry Pi boards only for now.
		Low-level GPIO code largely inspired by http://wiringpi.com/
	}
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

			#define RPI_GPIO_PERIPH_RPI5	00000000h	;-- RPi 5 (unsupported global mem access!)
			#define RPI_GPIO_PERIPH_RPI4	FE000000h	;-- RPi 4 & 400 peripherals
			#define RPI_GPIO_PERIPH_RPI23	3F000000h	;-- RPi 2 & 3 peripherals
			#define RPI_GPIO_PERIPH_RPI01	20000000h	;-- RPi zero & 1 peripherals
			#define RPI_GPIO_OFFSET			00200000h
			#define RPI_GPIO_PWM			0020C000h
			#define RPI_GPIO_CLOCK_BASE		00101000h
			
			#define RPI_BCM_PASSWORD		5A000000h
			
			#define RPI_PWMCLK_CNTL			40
			#define RPI_PWMCLK_DIV			41
			
			;-- 2711 has a different mechanism for pin pull-up/down/enable
			#define RPI_GPPUPPDN0			57			;-- Pin pull-up/down for pins 15:0
			#define RPI_GPPUPPDN1			58			;-- Pin pull-up/down for pins 31:16
			#define RPI_GPPUPPDN2			59			;-- Pin pull-up/down for pins 47:32
			#define RPI_GPPUPPDN3			60			;-- Pin pull-up/down for pins 57:48

			#enum gpio-pins! [
				GPFSEL0:	00h
				GPFSEL1:	01h
				GPFSEL2:	02h
				GPFSEL3:	03h
				GPFSEL4:	04h
				GPFSEL5:	05h
				GPSET0:		07h
				GPSET1:		08h
				GPCLR0:		0Ah
				GPCLR1:		0Bh
				GPLEV0:		0Dh
				GPLEV1:		0Eh
				GPEDS0:		10h
				GPEDS1:		11h
				GPREN0:		13h
				GPREN1:		14h
				GPFEN0:		16h
				GPFEN1:		17h
				GPHEN0:		19h
				GPHEN1:		1Ah
				GPLEN0:		1Ch
				GPLEN1:		1Dh
				GPAREN0:	1Fh
				GPAREN1:	20h
				GPAFEN0:	22h
				GPAFEN1:	23h
				GPPUD:		25h
				GPPUDCLK0:	26h
				GPPUDCLK1:	27h
			]

			#enum pin-modes! [
				MODE_INPUT: 0
				MODE_OUTPUT
				MODE_PWM_OUTPUT
				MODE_GPIO_CLOCK
				MODE_SOFT_PWM_OUTPUT
				MODE_SOFT_TONE_OUTPUT
				MODE_PWM_TONE_OUTPUT
				MODE_PM_OFF
				MODE_PWM_MS_OUTPUT
				MODE_PWM_BAL_OUTPUT
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
			
			#enum pwm-control! [
				PWM_CONTROL:	0
				PWM_STATUS:		1
				PWM0_RANGE:		4
				PWM0_DATA:		5
				PWM1_RANGE:		8
				PWM1_DATA:		9
			]
			
			#enum pwm-modes! [
				PWM0_MS_MODE:	0080h					;-- Run in MS mode
				PWM0_USEFIFO:	0020h					;-- Data from FIFO
				PWM0_REVPOLAR:	0010h					;-- Reverse polarity
				PWM0_OFFSTATE:	0008h					;-- Ouput Off state
				PWM0_REPEATFF:	0004h					;-- Repeat last value if FIFO empty
				PWM0_SERIAL:	0002h					;-- Run in serial mode
				PWM0_ENABLE:	0001h					;-- Channel Enable
				PWM1_MS_MODE:	8000h					;-- Run in MS mode
				PWM1_USEFIFO:	2000h					;-- Data from FIFO
				PWM1_REVPOLAR:	1000h					;-- Reverse polarity
				PWM1_OFFSTATE:	0800h					;-- Ouput Off state
				PWM1_REPEATFF:	0400h					;-- Repeat last value if FIFO empty
				PWM1_SERIAL:	0200h					;-- Run in serial mode
				PWM1_ENABLE:	0100h					;-- Channel Enable
			]
			
			regions: [RPI_GPIO_OFFSET RPI_GPIO_PWM RPI_GPIO_CLOCK_BASE]
			
			gpio-to-FSEL: #{
				00 00 00 00 00 00 00 00 00 00
				01 01 01 01 01 01 01 01 01 01
				02 02 02 02 02 02 02 02 02 02
				03 03 03 03 03 03 03 03 03 03
				04 04 04 04 04 04 04 04 04 04
				05 05 05 05 05 05 05 05 05 05
			}
			
			gpio-to-shift: #{
				00 03 06 09 0C 0F 12 15 18 1B
				00 03 06 09 0C 0F 12 15 18 1B
				00 03 06 09 0C 0F 12 15 18 1B
				00 03 06 09 0C 0F 12 15 18 1B
				00 03 06 09 0C 0F 12 15 18 1B
				00 03 06 09 0C 0F 12 15 18 1B
			}
			
			debug?: no

			set-mode: func [
				base [int-ptr!]
				pwm	 [int-ptr!]
				clk	 [int-ptr!]
				pin	 [integer!]
				mode [integer!]
				/local
					GPFSEL [int-ptr!]
					index  [integer!]
					shift  [integer!]
					mask   [integer!]
					bits   [integer!]
					idx	   [integer!]
			][
				if debug? [probe ["---- PIN: " pin ", MODE: " mode ", BASE: " base ", PWM: " pwm ", CLK: " clk]]
				
				idx: pin + 1
				index: as-integer gpio-to-FSEL/idx
				shift: as-integer gpio-to-shift/idx
				GPFSEL: base + index
				mask: GPFSEL/value and not (7 << shift)
				bits: either mode <> MODE_PWM_OUTPUT [mode][
					switch pin [
						18 19		   [2]				;-- FSEL_ALT5
						12 13 40 41 45 [4]				;-- FSEL_ALT0
						default [probe "invalid PWM pin" 0]	;@@ needs to return or throw an error!
					]
				]
				GPFSEL/value: bits << shift or mask
				
				if mode = MODE_PWM_OUTPUT [
					platform/usleep 110
					pwm-set-mode pwm 1					;-- PWM_MODE_BAL
					pwm-set-range pwm 1024
					pwm-set-clock pwm clk 32			;-- 600KHz, starts the PWM
				]
			]

			set: func [
				base  [int-ptr!]
				pin	  [integer!]
				high? [logic!]
				/local
					p	  [int-ptr!]
					index [integer!]
					bit	  [integer!]
					mode  [integer!]
			][
				index: pin >> 5
				bit: 1 << (pin and 31)

				mode: either high? [GPSET0][GPCLR0]
				p: base + mode + index
				p/value: bit
			]

			get: func [
				base    [int-ptr!]
				pin	    [integer!]
				return: [integer!]
				/local
					p	  [int-ptr!]
					bit	  [integer!]
			][
				bit: 1 << (pin and 31)
				p: base + GPLEV0
				either p/value and bit <> 0 [1][0]
			]

			set-pull: func [
				base	[int-ptr!]
				pin		[integer!]
				pud		[integer!]
				/local
					p	[int-ptr!]
			][
				p: base + GPPUD
				p/value: pud and 3
				platform/usleep 5

				p: base + GPPUDCLK0
				p/value: 1 << (pin and 31)
				platform/usleep 5

				p: base + GPPUD
				p/value: 0
				platform/usleep 5

				p: base + GPPUDCLK0
				p/value: 0
				platform/usleep 5
			]
			
			set-pwm: func [
				pwm	  [int-ptr!]
				pin	  [integer!]
				value [integer!]
				/local
					p	 [int-ptr!]
					port [integer!]
			][
				port: either pin and 1 = 0 [PWM0_DATA][PWM1_DATA]
				p: pwm + port
				p/value: value
			]
			
			;-- Select the native "balanced" mode, or standard mark:space mode
			pwm-set-mode: func [
				pwm	 [int-ptr!]
				mode [integer!]							;-- 0: PWM_MODE_MS, 1: PWM_MODE_BAL
				/local
					p	 [int-ptr!]
					bits [integer!]
			][
				bits: PWM0_ENABLE or PWM1_ENABLE
				if zero? mode [bits: bits or PWM0_MS_MODE or PWM1_MS_MODE]
				p: pwm + PWM_CONTROL
				p/value: bits
			]
			
			pwm-set-range: func [
				pwm	  [int-ptr!]
				range [integer!]
				/local
					p [int-ptr!]
			][
				p: pwm + PWM0_RANGE
				p/value: range
				platform/usleep 10
				
				p: pwm + PWM1_RANGE
				p/value: range
				platform/usleep 10
			]
			
			pwm-set-clock: func [
				pwm		[int-ptr!]
				clk		[int-ptr!]
				divisor [integer!]
				/local
					p	  [int-ptr!]
					c	  [int-ptr!]
					cd	  [int-ptr!]
					saved [integer!]
			][
				divisor: divisor and 4095
				p: pwm + PWM_CONTROL
			
				saved: p/value
				p/value: 0								;-- stop PWM

				c: clk + RPI_PWMCLK_CNTL
				c/value: RPI_BCM_PASSWORD or 1			;-- stop PWM clock
				platform/usleep 110
				
				while [c/value and 80h <> 0][platform/usleep 1]
				
				cd: clk + RPI_PWMCLK_DIV
				cd/value: RPI_BCM_PASSWORD or (divisor << 12)
				c/value: RPI_BCM_PASSWORD or 11h		;-- start PWM clock
				p/value: saved
			]
		]
	]
		
	models: [
	;-- Name -------- Generation --
		"Model A"		1
		"Model B"		1
		"Model A+"		1
		"Model B+"		1
		"Pi 2"			2
		"Alpha"			1
		"CM"			1
		"Unknown07"		2
		"Pi 3"			2
		"Pi Zero"		1
		"CM3"			2
		"Unknown11"		2
		"Pi Zero-W"		1
		"Pi 3B+"		2
		"Pi 3A+"		2
		"Unknown15"		2
		"CM3+"			2
		"Pi 4B"			4
		"Pi Zero2-W"	2
		"Pi 400"		4
		"CM4"			4
		"CM4S"			4
		"Unknown22"		4
		"Pi 5"			5
	]
	
	gpio.open: routine [
		state [block!]
		model [integer!]
		/local
			handle [red-handle!]
			fd	   [integer!]
			base   [byte-ptr!]
			i	   [integer!]
	][
		fd: platform/io-open "/dev/mem" 00101002h		;-- O_RDWR or O_SYNC
		either fd < 0 [
			fd: platform/io-open "/dev/gpiomem" 00101002h ;-- O_RDWR or O_SYNC
			either fd < 0 [exit][model: 0]				;-- relative addressing
		][
			model: switch model [						;-- absolute addressing
				1 [RPI_GPIO_PERIPH_RPI01]
				2 [RPI_GPIO_PERIPH_RPI23]
				4 [RPI_GPIO_PERIPH_RPI4]
				5 [RPI_GPIO_PERIPH_RPI5]				;@@ unsupported
				default [0]
			]
		]
		handle: as red-handle! block/rs-head state
		handle/header: TYPE_HANDLE
		handle/value: fd

		i: 1
		until [
			base: gpio/mmap null 4096 MMAP_PROT_RW MMAP_MAP_SHARED fd model or gpio/regions/i
			handle: handle + 1
			if -1 <> as-integer base [
				handle/header: TYPE_HANDLE
				handle/value: as-integer base
			]
			i: i + 1
			i > size? gpio/regions
		]
	]
	
	gpio.set-mode: routine [base [handle!] pwm [handle!] clk [handle!] pin [integer!] mode [integer!]][
		gpio/set-mode as int-ptr! base/value as int-ptr! pwm/value as int-ptr! clk/value pin mode - 1
	]
	
	gpio.set: routine [base [handle!] pin [integer!] value [integer!]][
		gpio/set as int-ptr! base/value pin as-logic value
	]
	
	gpio.set-pull: routine [base [handle!] pin [integer!] value [integer!]][
		gpio/set-pull as int-ptr! base/value pin value - 1
	]
	
	gpio.set-pwm: routine [pwm [handle!] pin [integer!] value [integer!]][
		gpio/set-pwm as int-ptr! pwm/value pin value
	]
	
	gpio.get: routine [base [handle!] pin [integer!] return: [integer!]][
		gpio/get as int-ptr! base/value pin
	]

	gpio.close: routine [
		state [block!]
		/local
			handle [red-handle!]
	][
		handle: as red-handle! (block/rs-head state) + 3
		loop 3 [
			if zero? gpio/munmap as byte-ptr! handle/value 4096 [handle/header: TYPE_NONE]
			handle: handle - 1
		]
		if zero? platform/io-close handle/value [handle/header: TYPE_NONE]
	]
	
	gpio.pause: routine [us [integer!]][platform/usleep us * 1000]
	
	fade: function [p [port!] pin [integer!] from [integer!] _to [integer!] delay [integer! time!]][
		delay: delay / absolute delta: _to - i: from
		looping?: pick [[i <= _to][_to <= i]] positive? step: sign? delta
		
		do [
			while looping? [
				insert p [set-pwm pin i]
				wait delay
				i: i + step
			]
		]
	]

	;--- Port actions ---

	open: func [port /local state info revision model err i][
		unless attempt [info: read %/proc/cpuinfo][
			cause-error 'access 'cannot-open ["cannot access /proc/cpuinfo"]
		]
		parse/case info [thru "Revision" thru #":" any #" " copy revision to lf]
		revision: to-integer debase/base revision 16
		model: FFh << 4 and revision >> 4
		
		;-- fd (handle!), base (handle!), pwm (handle!), clk (handle!)
		state: port/state: copy [none none none none]
		gpio.open state pick models model + 1 * 2 	;-- model is 0-based
		
		err: [
			"failed to open /dev/mem and /dev/gpiomem, retry with `sudo`"
			"base mmap() failed"
			"pwm mmap() failed"
			"clk mmap() failed"
		]
		repeat i 4 [unless state/:i [cause-error 'access 'cannot-open [err/:i]]]
	]
	
	insert: func [port data [block!] /local state base modes value pulls pos m list v p f t expr int-expr][
		unless all [block? state: port/state parse state [4 handle!]][
			cause-error 'access 'not-open ["port/state is invalid"]
		]
		expr:  [m: [word! | path!] (v: get m/1) | paren! (v: do m/1)]
		int-expr: [m: integer! (v: m/1) | expr [if (not integer? v) fail | none]]
		
		modes: [['in | 'input] (m: 1) | ['out | 'output] (m: 2) | 'pwm (m: 3)]
		
		value: [m: logic! | ['on | 'high] (m: yes) | ['off | 'low] (m: no) | m: integer!]
		
		pulls: ['pull-off (m: 1) | 'pull-down (m: 2) | 'pull-up (m: 3)]
		
		duty:  [
			[m: percent! (v: m/1) | int-expr]
			[if (not integer? m: either percent? v [to integer! 1024 * v][v]) fail | none]
		]
		base:  state/2
		list:  none
		
		unless parse data [
			some [pos:
				  'set-mode    int-expr modes       (gpio.set-mode base state/3 state/4 v m)
				| 'set         int-expr value       (gpio.set base v make integer! m)
				| pulls (p: m) int-expr             (gpio.set-pull base v p)
				| 'set-pwm     int-expr (p: v) duty (gpio.set-pwm state/3 p m)
				| 'get         int-expr             (d: gpio.get base v
					switch/default type?/word list [
						block! [append list d]
						none!  [list: d]
					][append list: reduce [list] d]
				)
				| 'fade   int-expr (p: v)
					'from int-expr (f: v)
					'to   int-expr (t: v)
					[m: time! (v: m/1) | expr [if (not time? v) fail | none]] 
					(fade port p f t v)
				| 'pause [integer! | float!] (
					gpio.pause either float? v: pos/2 [to-integer v * 1000][v]
				)
			]
		][cause-error 'access 'invalid-cmd [data]]
		
		port/data: list
	]

	close: func [port /local state err i][
		gpio.close state: port/state
		err: [
			"failed to close /dev/gpiomem"
			"base mmunap() failed"
			"pwm mmunap() failed"
			"clk mmunap() failed"
		]
		repeat i 4 [if handle? state/:i [cause-error 'access 'cannot-close [err/:i]]]
	]
]

register-scheme make system/standard/scheme [
	name: 'GPIO
	title: "GPIO access for Raspberry Pi boards"
	actor: gpio-scheme
]


#example [
	p: open gpio://

	LED-green: 18
	LED-red: 4
	
	insert p [set-mode (LED-green) pwm]
	
	delay: 0:0:3
	insert p [fade LED-green from 0 to 500 delay]
	insert p [fade LED-green from 500 to 0 delay]
	
	insert p [
		set-pwm LED-green 50%
		pause 1.0
		set-pwm LED-green 30%
		pause 1.0
		set-pwm LED-green 15%
		pause 1.0
		set-pwm LED-green 0%
		pause 1.0
		set-mode LED-green in
	]

	insert p [set-mode LED-green out]
	loop 20 [
		insert p [set LED-green on]
		wait 0.1
		insert p [set LED-green off]
		wait 0.1
	]
	
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
