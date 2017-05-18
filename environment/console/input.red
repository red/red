Red [
	Title:	"INPUT prototype for Unix platforms"
	Author: "Nenad Rakocevic"
	File: 	%input.red
	Tabs: 	4
	Rights: "Copyright (C) 2014-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

;;@@ Temporary patch to allow inclusion in user code.
unless system/console [
	system/console: context [
		history: make block! 200
		size: 0x0
	]
]
;; End patch

#include %auto-complete.red

#system [
	terminal: context [
	
		#enum special-key! [
			KEY_UNSET:		 -1
			KEY_NONE:		  0
			KEY_UP:			-20
			KEY_DOWN:		-21
			KEY_RIGHT:		-22
			KEY_LEFT:		-23
			KEY_END:		-24
			KEY_HOME:		-25
			KEY_INSERT:		-26
			KEY_DELETE:		-27
			KEY_PAGE_UP:	-28
			KEY_PAGE_DOWN:	-29
			KEY_ESC:		-30
			KEY_CTRL_A:		  1
			KEY_CTRL_B:		  2
			KEY_CTRL_C:		  3
			KEY_CTRL_D:		  4
			KEY_CTRL_E:		  5
			KEY_CTRL_F:		  6
			KEY_CTRL_H:		  8
			KEY_TAB:		  9
			KEY_CTRL_K:		 11
			KEY_CTRL_L:		 12
			KEY_ENTER:		 13
			KEY_CTRL_N:		 14
			KEY_CTRL_P:		 16
			KEY_CTRL_T:		 20
			KEY_CTRL_U:		 21
			KEY_CTRL_W:		 23
			KEY_ESCAPE:		 27
			KEY_BACKSPACE:	127
		]
		
		#include %wcwidth.reds
		
		#either OS = 'Windows [
			#include %win32.reds
		][
			#include %POSIX.reds
		]

		console?:	yes
		buffer:		declare byte-ptr!
		pbuffer:	declare byte-ptr!
		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		buf-size:	128
		columns:	-1
		rows:		-1
		output?:	yes
		pasting?:	no

		string/rs-make-at as cell! saved-line 1

		widechar?: func [
			str			[red-string!]
			return:		[logic!]
			/local
				cp		[integer!]
				unit	[integer!]
				s		[series!]
				offset	[byte-ptr!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			offset: (as byte-ptr! s/offset) + (str/head << (log-b unit))
			cp: 0
			if offset < as byte-ptr! s/tail [cp: string/get-char offset unit]
			cp > FFh
		]

		on-resize: func [[cdecl] sig [integer!]][
			get-window-size
			refresh
		]

		complete-line: func [
			str			[red-string!]
			return:		[integer!]
			/local
				line	[red-string!]
				result	[red-block!]
				num		[integer!]
				str2	[red-string!]
				head	[integer!]
		][
			#call [red-complete-input str yes]
			stack/top: stack/arguments + 1
			result: as red-block! stack/top
			num: block/rs-length? result
			unless zero? num [
				head: str/head
				str/head: 0
				_series/copy
					as red-series! str
					as red-series! saved-line
					stack/arguments
					yes
					stack/arguments
				saved-line/head: head
				line: input-line
				string/rs-reset line

				str2: as red-string! block/rs-head result
				head: str2/head
				str2/head: 0
				either num = 1 [
					string/concatenate line str2 -1 0 yes no
					line/head: head
				][
					string/rs-reset saved-line
					string/concatenate saved-line str2 -1 0 yes no
					saved-line/head: head
					block/rs-next result				;-- skip first one
					until [
						string/concatenate line as red-string! block/rs-head result -1 0 yes no
						string/append-char GET_BUFFER(line) 32
						block/rs-next result
						block/rs-tail? result
					]
					line/head: string/rs-abs-length? line
				]
				refresh
			]
			num
		]

		add-history: func [
			str	[red-string!]
		][
			str/head: 0
			unless zero? string/rs-length? str [
				block/rs-append history as red-value! str		;TBD Don't add duplicated lines.
			]
		]

		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/rs-abs-length? input-line
		]

		init-buffer: func [
			str			[red-string!]
			prompt		[red-string!]
			/local
				unit	[integer!]
				s		[series!]
				size	[integer!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			if unit < 2 [unit: 2]			;-- always treat string as widechar string
			size: (string/rs-abs-length? str) << (log-b unit)
			size: size + (string/rs-abs-length? prompt) << (log-b unit)
			if size > buf-size [
				buf-size: size
				free buffer
				buffer: allocate size
			]
			pbuffer: buffer
		]

		process-ansi-sequence: func [
			str 	[byte-ptr!]
			tail	[byte-ptr!]
			unit    [integer!]
			print?	[logic!]
			return: [integer!]
			/local
				cp      [integer!]
				bytes   [integer!]
				state   [integer!]
		][
			cp: string/get-char str unit
			if all [
				cp <> as-integer #"["
				cp <> as-integer #"("
			][return 0]

			if print? [emit-red-char cp]
			str: str + unit
			bytes: unit
			state: 1
			while [all [state > 0 str < tail]] [
				cp: string/get-char str unit
				if print? [emit-red-char cp]
				str: str + unit
				bytes: bytes + unit
				switch state [
					1 [
						unless any [
							cp = as-integer #";"
							all [cp >= as-integer #"0" cp <= as-integer #"9"]
						][state: -1]
					]
					2 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 3]
							true [ state: -1 ]
						]
					]
					3 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][state: 4]
							cp = as-integer #";" [0] ;do nothing
							true [ state: -1 ]
						]
					]
					4 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 1]
							true [ state: -1 ]
						]
					]
				]
			]
			bytes
		]

		emit-red-string: func [
			str			[red-string!]
			size		[integer!]
			head-as-tail? [logic!]
			return: 	[integer!]
			/local
				series	[series!]
				offset	[byte-ptr!]
				tail	[byte-ptr!]
				unit	[integer!]
				cp		[integer!]
				bytes	[integer!]
				cnt		[integer!]
				x		[integer!]
				w		[integer!]
				sn		[integer!]
		][
			x:		0
			w:		0
			cnt:	0
			bytes:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
			tail:   as byte-ptr! series/tail
			if head-as-tail? [
				tail: offset
				offset: as byte-ptr! series/offset
			]
			sn: 0
			until [
				while [
					all [offset < tail cnt < size]
				][
					either zero? sn [
						cp: string/get-char offset unit
						if cp = 9 [			;-- convert a tab to 4 spaces
							offset: offset - unit
							cp: 32
							sn: 3
						]
						emit-red-char cp
						offset: offset + unit
						if cp = as-integer #"^[" [
							cnt: cnt - 1
							offset: offset + process-ansi-sequence offset tail unit yes
						]
					][
						emit-red-char cp
						sn: sn - 1
						if zero? sn [offset: offset + unit]
					]
					w: either all [0001F300h <= cp cp <= 0001F5FFh][2][wcwidth? cp]
					cnt: switch w [
						1  [cnt + 1]
						2  [either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]]	;-- reach screen edge, handle wide char
						default [0]
					]
				]
				bytes: bytes + cnt
				size: columns - x
				x: 0
				cnt: 0
				offset >= tail
			]
			bytes
		]

		refresh: func [
			/local
				line   [red-string!]
				offset [integer!]
				bytes  [integer!]
				psize  [integer!]
		][
			line: input-line

			either output? [					;-- erase down to the bottom of the screen
				reset-cursor-pos
				erase-to-bottom
			][
				#if OS <> 'Windows [reset-cursor-pos][0]
			]
			init-buffer line prompt
			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			either output? [
				output-to-screen
			][
				#if OS <> 'Windows [
					if all [
						bytes > columns
						positive? (bytes // columns)
					][
						psize: bytes / columns
						emit-string-int "^[[" psize  #"B"
					]
				][0]
			]
			set-cursor-pos line offset bytes
		]

		console-edit: func [
			prompt-str [red-string!]
			/local
				line   [red-string!]
				head   [integer!]
				c	   [integer!]
				n	   [integer!]
		][
			line: input-line
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: block/rs-length? history		;@@ set history list to tail (temporary)
				
			get-window-size
			unless zero? string/rs-abs-length? saved-line [
				head: saved-line/head
				saved-line/head: 0
				string/concatenate line saved-line -1 0 yes no
				line/head: head
			]
			refresh

			while [true][
				output?: yes
				c: fd-read
				n: 0

				if all [c = KEY_TAB not pasting?][
					n: complete-line line
					if n > 1 [
						string/rs-reset line
						exit
					]
					if n = 1 [c: 32]						;-- convert TAB to SPACE
				]

				#if OS <> 'Windows [if c = 27 [c: check-special]]

				switch c [
					KEY_ENTER [
						add-history line
						string/rs-reset saved-line
						exit
					]
					KEY_CTRL_H
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							if string/rs-tail? line [output?: no]
							refresh
							unless output? [erase-to-bottom]
						]
					]
					KEY_CTRL_B
					KEY_LEFT [
						unless zero? line/head [
							line/head: line/head - 1
							output?: no
							refresh
						]
					]
					KEY_CTRL_F
					KEY_RIGHT [
						if 0 < string/rs-length? line [
							line/head: line/head + 1
							output?: no
							refresh
						]
					]
					KEY_CTRL_P
					KEY_UP [
						unless zero? history/head [
							history/head: history/head - 1
							fetch-history
							line/head: string/rs-abs-length? line
							refresh
						]
					]
					KEY_CTRL_N
					KEY_DOWN [
						unless block/rs-tail? history [
							history/head: history/head + 1
							either block/rs-tail? history [
								string/rs-reset line
							][
								fetch-history
							]
							refresh
						]
					]
					KEY_CTRL_A
					KEY_HOME [
						line/head: 0
						refresh
					]
					KEY_CTRL_E
					KEY_END [
						line/head: string/rs-abs-length? line
						refresh
					]
					KEY_DELETE [
						unless string/rs-tail? line [
							string/remove-char line line/head
							refresh
						]
					]
					KEY_CTRL_K [
						unless string/rs-tail? line [
							string/remove-part line line/head string/rs-length? line
							refresh
						]
					]
					KEY_CTRL_D [
						either string/rs-tail? line [
							if zero? line/head [
								string/rs-reset line
								string/append-char GET_BUFFER(line) as-integer #"q"
								exit
							]
						][
							string/remove-char line line/head
							refresh
						]
					]
					KEY_CTRL_C [
						string/rs-reset line
						string/append-char GET_BUFFER(line) as-integer #"q"
						exit
					]
					KEY_ESCAPE [
						string/append-char GET_BUFFER(line) c
						exit
					]
					default [
						if any [c > 31 c = KEY_TAB][
							#if OS = 'Windows [						;-- optimize for Windows
								if all [D800h <= c c <= DF00h][		;-- USC-4
									c: c and 03FFh << 10			;-- lead surrogate decoding
									c: (03FFh and fd-read) or c + 00010000h
								]
							]
							either string/rs-tail? line [
								string/append-char GET_BUFFER(line) c
								#if OS = 'Windows [					;-- optimize for Windows
									pbuffer: buffer
									emit-red-char c
									output-to-screen
									pbuffer: buffer
									output?: no
								]
							][
								string/insert-char GET_BUFFER(line) line/head c
							]
							line/head: line/head + 1
							refresh
						]
					]
				]
			]
			line/head: 0
		]

		stdin-readline: func [
			/local
				c	 [integer!]
				s	 [series!]
		][
			s: GET_BUFFER(input-line)
			while [true][
				#either OS = 'Windows [
					c: stdin-read
				][
					c: fd-read
				]
				either any [c = -1 c = as-integer lf][exit][
					s: string/append-char s c
				]
			]
		]

		edit: func [
			prompt-str [red-string!]
		][
			either console? [
				console-edit prompt-str
				restore
				print-line ""
			][
				stdin-readline
			]
		]

		setup: func [
			line [red-string!]
			hist [red-block!]
		][
			copy-cell as red-value! line as red-value! input-line
			copy-cell as red-value! hist as red-value! history

			init		;-- enter raw mode
		]
	]
]

_set-buffer-history: routine [line [string!] hist [block!]][
	terminal/setup line hist
]

_read-input: routine [prompt [string!]][
	terminal/edit prompt
]

ask: function [
	question [string!]
	return:  [string!]
][
	buffer: make string! 1
	_set-buffer-history buffer head system/console/history
	_read-input question
	buffer
]

input: does [ask ""]
