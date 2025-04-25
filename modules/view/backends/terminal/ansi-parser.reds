Red/System [
	Title:	"ANSI escape sequences parser"
	Author: "Xie Qingtian"
	File: 	%ansi-parser.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ansi-parser: context [
	buffer: as node! 0
	pbuffer: as byte-ptr! 0
	pos: 1
	mouse-down: 1
	incomplete?: no

	_8bytes!: alias struct! [
		pad1 [integer!]
		pad2 [integer!]
	]

	args!: alias struct! [
		val1 [integer!]
		val2 [integer!]
		val3 [integer!]
		val4 [integer!]
	]

	#define current-char [pbuffer/pos]

	init: func [][
		buffer: array/make 100 1
	]

	on-gc-mark: does [
		collector/keep as int-ptr! :buffer
	]

	add-byte: func [
		c	[byte!]
	][
		array/append-byte buffer c
	]

	add-char: func [
		cp	[integer!]	;-- unicode codepoint
		/local
			n		[integer!]
			_8bytes [_8bytes! value]
			buf		[byte-ptr!]
	][
		buf: as byte-ptr! :_8bytes
		n: unicode/cp-to-utf8 cp buf
		while [n > 0][
			add-byte buf/value
			n: n - 1
			buf: buf + 1
		]
	]

	end-of-buffer?: func [
		return: [logic!]
	][
		pos > array/length? buffer
	]

	clear-buffer: does [
		array/clear buffer
		incomplete?: no
		pos: 1
	]

	next-byte: func [return: [logic!]][
		pos: pos + 1
		either end-of-buffer? [
			incomplete?: yes
			no
		][yes]
	]

	parse-mouse: func [
		altered? [logic!]
		pressed  [integer!]
		args	 [int-ptr!]
		/local
			evt		[integer!]
			arg1	[integer!]
			btn		[integer!]
			motion	[integer!]
			x y		[float32!]
			flags	[integer!]
			win		[widget!]
	][
		win: screen/active-win/window
		arg1: args/1
		btn: arg1 and 3 + (arg1 and 64 >> 4)
		x: as float32! args/2 - 1		;-- use 0-based index
		y: as float32! args/3 - screen/offset-y - 1
		flags: 0
		if arg1 and 4 <> 0  [flags: flags or EVT_FLAG_SHIFT_DOWN]
		if arg1 and 8 <> 0  [flags: flags or EVT_FLAG_MENU_DOWN]
		if arg1 and 16 <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
		case [
			btn < 3 [
				evt: btn * 2 + 1 + pressed
				either mouse-down <> pressed [
					mouse-down: pressed
					do-mouse-press evt win x y flags
				][
					do-mouse-move EVT_OVER win x y flags or EVT_FLAG_DOWN yes
				]
			]
			btn = 3 [do-mouse-move EVT_OVER win x y flags yes]
			btn = 4 [do-mouse-wheel 1 win x y flags]
			btn = 5 [do-mouse-wheel -1 win x y flags]
			true	[0]
		]
	]

	parse-cursor: func [args [int-ptr!]][
		screen/offset-y: args/1 - 1		;-- use 0-based index
		screen/offset-x: args/2 - 1
	]

	parse-key: func [
		p		[byte-ptr!]
		end		[byte-ptr!]
		/local
			key [integer!]
			e	[byte!]
	][
		e: end/1
		key: switch p/1 [
			#"[" [
				key: switch p/2 [
					#"A" [KEY_UP]
					#"B" [KEY_DOWN]
					#"C" [KEY_RIGHT]
					#"D" [KEY_LEFT]
					#"F" [KEY_END]
					#"H" [KEY_HOME]
					#"Z" [KEY_BACKTAB]
					#"3" [either e = #"~" [KEY_DELETE][0]]
					#"1" [
						either e = #"~" [
							switch p/3 [
								#"5" [KEY_F5]	;-- ^[[15~
								#"7" [KEY_F6]
								#"8" [KEY_F7]
								#"9" [KEY_F8]
								default [0]
							]
						][0]
					]
					#"2" [
						either e = #"~" [
							switch p/3 [
								#"0" [KEY_F9]	;-- ^[[20~
								#"1" [KEY_F10]
								#"3" [KEY_F11]
								#"4" [KEY_F12]
								default [0]
							]
						][0]
					]
					#"5" [
						either e = #"~" [KEY_PAGE_UP][0]
					]
					#"6" [
						either e = #"~" [KEY_PAGE_DOWN][0]
					]
					default [0]
				]
			]
			#"O" [
				key: switch p/2 [
					#"P" [KEY_F1]
					#"Q" [KEY_F2]
					#"R" [KEY_F3]
					#"S" [KEY_F4]
					default [0]
				]
			]
			default [0]
		]
		send-key-event null 0 key
	]

	parse-DSC: func [][
		forever [
			unless next-byte [exit]
			if current-char <> #"^[" [
				continue
			]
			unless next-byte [exit]
			if current-char <> #"\" [
				continue
			]
			break
		]
	]

	parse-CSI: func [
		/local
			altered? [logic!]
			arg	 	 [integer!]
			args	 [args! value]
			pargs	 [int-ptr!]
			n		 [integer!]
			c		 [byte!]
			start	 [byte-ptr!]
	][
		altered?: no
		n: 1
		arg: 0
		pargs: as int-ptr! :args
		start: pbuffer + (pos - 1)
		forever [
			unless next-byte [exit]

			c: current-char
			if c = #"<" [
				altered?: yes
				continue
			]

			if all [c >= #"0" c <= #"9"] [
				arg: arg * 10
				arg: arg + as-integer (c - #"0")
				continue
			]

			if c = #";" [
				pargs/n: arg
				arg: 0
				n: n + 1
			]

			if all [		;-- CSI is terminated by a character in the range 0x40–0x7E
				c >= #"@"
				c <= #"~"
				c <> #"<"
				c <> #"["
			][
				pargs/n: arg
				arg: 0

				switch c [
					#"M"	[if n = 3 [parse-mouse altered? 0 pargs]]
					#"m"	[if n = 3 [parse-mouse altered? 1 pargs]]
					#"R"	[if n = 2 [parse-cursor pargs]]
					default [parse-key start pbuffer + (pos - 1)]
				]
				exit
			]

			if c = #"^[" [exit]
		]
	]

	parse-OSC: func [][
		forever [
			unless next-byte [exit]
			if current-char <> #"^[" [
				continue
			]
			unless next-byte [exit]
			if current-char <> #"\" [
				continue
			]
			break
		]
	]

	parse-ESC: func [/local c [byte!] start [integer!]][
		unless next-byte [exit]
		c: current-char
		switch c [
			#"P" 	[parse-DSC]	;-- Device Control String
			#"[" 	[parse-CSI]	;-- Control Sequence Introducer
			#"]" 	[parse-OSC]	;-- Operating System Command
			default [
				start: pos
				unless next-byte [exit]
				parse-key pbuffer + (start - 1) pbuffer + (pos - 1)
			]
		]
		pos: pos + 1
	]

	parse-utf8: func [
		/local
			cp	[integer!]
			s	[byte-ptr!]
			ss	[byte-ptr!]
	][
		s: pbuffer + pos - 1
		cp: 0
		ss: unicode/fast-decode-utf8-char s :cp
		if cp = -1 [		;-- incomplete
			incomplete?: yes
			exit
		]
		pos: pos + (as-integer ss - s)
		send-key-event null cp 0
	]

	parse: func [
		/local
			c	[byte!]
			end [integer!]
			cur	[integer!]
	][
		incomplete?: no
		pbuffer: array/get-ptr buffer
		end: array/length? buffer

		c: null-byte
		while [pos <= end][
			c: current-char
			cur: pos
			case [
				all [end > 1 c = #"^["][parse-ESC]
				any [
					c < as byte! 32
					c = as byte! 127  ;-- delete char
				][
					case [
						c = #"^H" [c: as byte! 127]
						c = lf	  [c: cr]
						true	  [0]
					]
					send-key-event null as-integer c 0
					pos: pos + 1
				]
				true [parse-utf8]
			]
			if end-of-buffer? [exit]

			if incomplete? [
				if cur > 1 [
					move-memory pbuffer pbuffer + cur - 1 end - cur + 1
					array/clear-at buffer cur
					pos: 1
				]
				break
			]
		]
		unless incomplete? [
			array/clear buffer
			pos: 1
		]
	]
]