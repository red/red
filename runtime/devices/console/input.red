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
			KEY_ENTER:		-30
			KEY_BACKSPACE:	-31
		]

		#define KEY-CTRL-A	#"^A"
		#define	KEY-CTRL-E	#"^E"

		buffer:		declare byte-ptr!
		pbuffer:	declare byte-ptr!
		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		buf-size:	512
		columns:	-1
		rows:		-1

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
				x	   [integer!]
				y	   [integer!]
				saved  [integer!]
				psize  [integer!]
		][
			line: input-line
			erase-to-bottom					;-- erase down to the bottom of the screen

			init-buffer line
			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			output-to-screen
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

				switch c [
					KEY_ENTER [
						exit
					]
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							refresh
						]
					]
					KEY_LEFT [
						unless zero? line/head [
							line/head: line/head - 1
							refresh
						]
					]
					KEY_RIGHT [
						if 0 < string/rs-length? line [
							line/head: line/head + 1
							refresh
						]
					]
					KEY_UP [
						unless zero? history/head [
							history/head: history/head - 1
							fetch-history
							line/head: string/get-length line yes
							refresh
						]
					]
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
					KEY_HOME 
					KEY-CTRL-A [
						line/head: 0
						refresh
					]
					KEY_END
					KEY-CTRL-E [
						line/head: string/get-length line yes
						refresh
					]
					KEY_DELETE [
						unless string/rs-tail? line [
							string/remove-char line line/head
							refresh
						]
					]
					KEY_PAGE_UP
					KEY_PAGE_DOWN
					KEY_UNSET
					KEY_NONE []						;-- do nothing
					
					default [
						either zero? string/rs-length? line [
							string/append-char GET_BUFFER(line) c
						][
							string/insert-char GET_BUFFER(line) line/head c
						]
						line/head: line/head + 1
						refresh
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
		"add-3 1 2 3"
		"add-3 1.1 2.2 3.3"
		{checksum/method "1234" 'MD5}
		{checksum/method "1234" 'SHA1}
	]
	set-buffer-history buffer hist
	_input question
	print ""
	buffer
]

input: does [ask ""]