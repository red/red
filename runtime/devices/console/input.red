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

default-input-completer: func [
	str [string!]
	/local word result sys-word ws?
][
	ws?: no
	str: head str
	result: make block! 4
	either word: find/last/tail str #" " [ws?: yes][word: str]
	unless empty? word [
		foreach w system/words [
			unless unset? get/any w [
				sys-word: mold w
				if find/match sys-word word [
					append result sys-word
				]
			]
		]
	]
	if 1 = length? result [
		either word = result/1 [
			clear result
		][
			if ws? [
				poke result 1 append copy/part str word result/1
			]
		]
	]
	result
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
		buf-size:	128
		columns:	-1
		rows:		-1
		output?:	yes

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
			offset: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
			cp: 0
			if offset < as byte-ptr! s/tail [cp: string/get-char offset unit]
			cp > FFh
		]

		on-resize: does [
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
		][
			#call [default-input-completer str]					;@@ need to call twice, a bug?
			#call [default-input-completer str]
			result: as red-block! stack/arguments
			num: block/rs-length? result
			unless zero? num [
				line: input-line
				if num > 1 [
					str/head: 0
					string/copy str saved-line stack/arguments yes stack/arguments
				]

				string/rs-reset line
				until [
					string/concatenate line as red-string! block/rs-head result -1 0 yes no
					string/append-char GET_BUFFER(line) 32
					block/rs-next result
					block/rs-tail? result
				]

				line/head: string/get-length line yes
				refresh
			]
			num
		]

		add-history: func [
			str			[red-string!]
			/local
				saved	[integer!]
		][
			str/head: 0
			unless zero? string/rs-length? str [
				block/rs-append history as red-value! str		;TBD Don't add duplicated lines.
			]
		]

		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/get-length input-line yes
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
			size: (string/get-length str yes) << (unit >> 1)
			size: size + (string/get-length prompt yes) << (unit >> 1)
			if size > buf-size [
				buf-size: size
				free buffer
				buffer: allocate size
			]
			pbuffer: buffer
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
		][
			x:		0
			w:		0
			cnt:	0
			bytes:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (unit >> 1))
			tail:   as byte-ptr! series/tail
			if head-as-tail? [
				tail: offset
				offset: as byte-ptr! series/offset
			]
			until [
				while [
					all [offset < tail cnt < size]
				][
					cp: string/get-char offset unit
					w: wcwidth? cp
					cnt: switch w [
						1  [cnt + 1]
						2  [either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]]	;-- reach screen edge, handle wide char
						default [0]
					]
					emit-red-char cp
					offset: offset + unit
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
		][
			line: input-line
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: block/rs-length? history		;@@ set history list to tail (temporary)
				
			get-window-size
			unless zero? string/rs-length? saved-line [
				string/concatenate line saved-line -1 0 yes no
				line/head: string/get-length line yes
			]
			refresh

			while [true][
				output?: yes
				c: fd-read
				if c = KEY_TAB [
					if (complete-line line) > 1 [
						string/rs-reset line
						exit
					]
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
					KEY_CTRL_D [halt]
					default [
						if c > 31 [
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
	print-line ""
]

default-input-history: []

ask: function [
	question [string!]
	return: [string!]
][
	buffer: make string! 100
	set-buffer-history buffer head default-input-history
	_input question
	buffer
]

input: does [ask ""]