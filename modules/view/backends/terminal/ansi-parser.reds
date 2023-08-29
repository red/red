Red/System [
	Title:	"ANSI escape sequences parser"
	Author: "Xie Qingtian"
	File: 	%asni-parser.reds
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
		collector/keep buffer
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
		pressed? [logic!]
		args	 [int-ptr!]
		/local
			evt		[integer!]
			arg1	[integer!]
			btn		[integer!]
			motion	[integer!]
			x y		[float32!]
			flags	[integer!]
	][
		arg1: args/1
		btn: arg1 and 3 + (arg1 and 64 >> 4)
		x: as float32! args/2 - 1	;-- use 0-based index
		y: as float32! args/3 - 1
		flags: 0
		if arg1 and 4 <> 0  [flags: flags or EVT_FLAG_SHIFT_DOWN]
		if arg1 and 8 <> 0  [flags: flags or EVT_FLAG_MENU_DOWN]
		if arg1 and 16 <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
		case [
			btn < 3 [
				evt: btn * 2 + 1 + as-integer pressed?
				do-mouse-press evt screen/active-win/window x y flags
			]
			btn = 3 [do-mouse-move EVT_OVER screen/active-win/window x y flags yes]
			btn = 4 [do-mouse-wheel 1 x y flags]
			btn = 5 [do-mouse-wheel -1 x y flags]
			true	[0]
		]
	]

	parse-cursor: func [][
		
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
					#"A" [RED_VK_UP]
					#"B" [RED_VK_DOWN]
					#"C" [RED_VK_RIGHT]
					#"D" [RED_VK_LEFT]
					#"F" [RED_VK_END]
					#"H" [RED_VK_HOME]
					#"Z" [RED_VK_BACKTAB]
					#"3" [either e = #"~" [RED_VK_DELETE][0]]
					#"1" [
						either e = #"~" [
							switch p/3 [
								#"5" [RED_VK_F5]	;-- ^[[15~
								#"7" [RED_VK_F6]
								#"8" [RED_VK_F7]
								#"9" [RED_VK_F8]
								default [0]
							]
						][0]
					]
					#"2" [
						either e = #"~" [
							switch p/3 [
								#"0" [RED_VK_F9]	;-- ^[[20~
								#"1" [RED_VK_F10]
								#"3" [RED_VK_F11]
								#"4" [RED_VK_F12]
								default [0]
							]
						][0]
					]
					#"5" [
						either e = #"~" [RED_VK_PRIOR][0]
					]
					#"6" [
						either e = #"~" [RED_VK_NEXT][0]
					]
					default [0]
				]
			]
			#"O" [
				key: switch p/2 [
					#"P" [RED_VK_F1]
					#"Q" [RED_VK_F2]
					#"R" [RED_VK_F3]
					#"S" [RED_VK_F4]
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
					#"M"	[if n = 3 [parse-mouse altered? true pargs]]
					#"m"	[if n = 3 [parse-mouse altered? false pargs]]
					#"R"	[if n = 2 [parse-cursor]]
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

while [pos <= end][
	c: current-char
	LOG_MSG(["char: " as-integer c])
	pos: pos + 1
]
pos: 1
		c: null-byte
		while [pos <= end][
			c: current-char
			cur: pos
			case [
				all [end > 1 c = #"^["][parse-ESC]
				c = #"^C" [break]
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