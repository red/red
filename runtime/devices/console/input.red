Red [
	Title:	"INPUT prototype for Unix platforms"
	Author: "Nenad Rakocevic"
	File: 	%input.red
	Tabs: 	4
	Rights: "Copyright (C) 2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

#system [
	terminal: context [
		#include %wcwidth.reds

		#either OS = 'Windows [
			#include %win32.reds
		][
			#include %POSIX.reds
		]

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
		]

		#define KEY_CTRL_A		1
		#define KEY_CTRL_B		2
		#define KEY_CTRL_C		3
		#define KEY_CTRL_D		4
		#define KEY_CTRL_E		5
		#define KEY_CTRL_F		6
		#define KEY_CTRL_H		8
		#define KEY_TAB			9
		#define KEY_CTRL_K		11
		#define KEY_CTRL_L		12
		#define KEY_ENTER		13
		#define KEY_CTRL_N		14
		#define KEY_CTRL_P		16
		#define KEY_CTRL_T		20
		#define KEY_CTRL_U		21
		#define KEY_CTRL_W		23
		#define KEY_BACKSPACE	127

		buffer:		declare byte-ptr!
		pbuffer:	declare byte-ptr!
		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		buf-size:	512
		columns:	-1
		rows:		-1
		output?:	yes

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
			offset: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
			cp: 0
			if offset < as byte-ptr! s/tail [cp: string/get-char offset unit]
			cp > FFh
		]

		on-resize: does [
			get-window-size
			refresh
		]

		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/get-length input-line yes
		]

		init-buffer: func [
			str			[red-string!]
			/local
				unit	[integer!]
				s		[series!]
				size	[integer!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			if unit < 2 [unit: 2]			;-- always treat string as widechar string
			size: (string/rs-length? str) << (unit >> 1)
			if size > buf-size [
				buf-size: size
				free buffer
				buffer: allocate size
			]
			pbuffer: buffer
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
				#either OS <> 'Windows [
					if positive? lines-y [emit-string-int "^[[" lines-y #"A"]	;-- move to origin row
				][0]
			]

			init-buffer line
			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			either output? [
				output-to-screen
			][
				#if OS <> 'Windows [
					psize: bytes / columns
					if positive? psize [
						emit-string-int "^[[" psize  #"B"
					]
				][0]
			]
			set-cursor-pos line offset bytes
		]

		edit: func [
			prompt-str [red-string!]
			/local
				line   [red-string!]
				c	   [integer!]
				offset [integer!]
		][
			line: input-line			
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: block/rs-length? history		;@@ set history list to tail (temporary)
				
			get-window-size
			refresh

			while [true][
				c: fd-read
				#if OS <> 'Windows [if c = 27 [c: check-special]]
				output?: yes
				switch c [
					KEY_ENTER [
						exit
					]
					KEY_CTRL_H
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							if string/rs-tail? line [output?: no]
							refresh
							if not output? [erase-to-bottom]
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
							line/head: string/get-length line yes
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
						line/head: string/get-length line yes
						refresh
					]
					KEY_DELETE [
						unless string/rs-tail? line [
							string/remove-char line line/head
							refresh
						]
					]
					default [
						if any [c = KEY_TAB c > 31] [
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
	]
]

set-buffer-history: routine [line [string!] hist [block!]][
	terminal/init line hist
]

_input: routine [prompt [string!]][
	terminal/edit prompt
	terminal/restore
]

ask: function [
	question [string!]
	return: [string!]
][
	buffer: make string! 100
	hist: [
		"1 + 2"
		"1.2 + 1.3"
		{add-3: function [a b c][a + b + c]}
	]
	set-buffer-history buffer hist
	_input question
	print ""
	buffer
]

input: does [ask ""]