Red/System [
	Title:	"Red GUI console common data structures and functions"
	Author: "Qingtian Xie"
	File: 	%terminal.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

terminal: context [

	#define RS_KEY_UNSET		 -1
	#define RS_KEY_NONE			  0
	#define RS_KEY_UP			-20
	#define RS_KEY_DOWN			-21
	#define RS_KEY_RIGHT		-22
	#define RS_KEY_LEFT			-23
	#define RS_KEY_END			-24
	#define RS_KEY_HOME			-25
	#define RS_KEY_INSERT		-26
	#define RS_KEY_DELETE		-27
	#define RS_KEY_PAGE_UP		-28
	#define RS_KEY_PAGE_DOWN	-29
	#define RS_KEY_CTRL_LEFT	-30
	#define RS_KEY_CTRL_RIGHT	-31
	#define RS_KEY_SHIFT_LEFT	-32
	#define RS_KEY_SHIFT_RIGHT	-33
	#define RS_KEY_CTRL_A		1
	#define RS_KEY_CTRL_B		2
	#define RS_KEY_CTRL_C		3
	#define RS_KEY_CTRL_D		4
	#define RS_KEY_CTRL_E		5
	#define RS_KEY_CTRL_F		6
	#define RS_KEY_CTRL_H		8
	#define RS_KEY_TAB			9
	#define RS_KEY_CTRL_K		11
	#define RS_KEY_CTRL_L		12
	#define RS_KEY_ENTER		13
	#define RS_KEY_CTRL_N		14
	#define RS_KEY_CTRL_P		16
	#define RS_KEY_CTRL_T		20
	#define RS_KEY_CTRL_U		21
	#define RS_KEY_CTRL_V		22
	#define RS_KEY_CTRL_W		23
	#define RS_KEY_CTRL_Z		26
	#define RS_KEY_ESCAPE		27
	#define RS_KEY_BACKSPACE	127

	#define SCROLL_TOP		80000000h
	#define SCROLL_BOTTOM	7FFFFFFFh
	#define SCROLL_TRACK	7FFFFFFEh

	RECT_STRUCT: alias struct! [
		left		[integer!]
		top			[integer!]
		right		[integer!]
		bottom		[integer!]
	]

	line-node!: alias struct! [
		offset	[integer!]
		length	[integer!]
		nlines	[integer!]
	]

	ring-buffer!: alias struct! [
		lines	[line-node!]				;-- line-node! array
		head	[integer!]					;-- 1-based index
		tail	[integer!]					;-- 1-based index
		last	[integer!]					;-- index of last line
		nlines	[integer!]					;-- number of lines
		max		[integer!]					;-- maximum size of the line-node array
		h-idx	[integer!]					;-- offset of the first line
		s-head	[integer!]					;-- index of the first selected line
		s-tail	[integer!]					;-- index of the last selected line
		s-h-idx [integer!]					;-- offset of the first selected line
		s-t-idx [integer!]					;-- offset of the last selected line
		data	[red-string!]
	]

	terminal!: alias struct! [
		in			[red-string!]			;-- current input string
		buffer		[red-string!]			;-- line buffer for multiline support
		out			[ring-buffer!]			;-- output buffer
		history		[red-block!]
		history-end [integer!]
		history-cnt [integer!]
		history-max [integer!]				;-- maximum number of lines in history block
		pos			[integer!]				;-- position of the scroll bar
		top			[integer!]				;-- index of the first visible line in out ring-buffer!
		top-offset	[integer!]				;-- for multiline support
		scroll		[integer!]				;-- number of lines to scroll
		nlines		[integer!]				;-- number of lines
		cols		[integer!]
		rows		[integer!]
		win-w		[integer!]
		win-h		[integer!]
		char-w		[integer!]
		char-h		[integer!]
		caret-x		[integer!]
		caret-y		[integer!]
		caret?		[logic!]
		select?		[logic!]
		select-all? [logic!]
		ask?		[logic!]
		input?		[logic!]
		select-x	[integer!]
		select-y	[integer!]
		s-head		[integer!]
		s-h-idx		[integer!]
		cursor		[integer!]				;-- cursor of edit line
		width		[integer!]				;-- width of edit line
		prompt-len	[integer!]				;-- length of prompt
		prompt		[red-string!]
		hwnd		[int-ptr!]				;@@ OS-Dependent field
		scrollbar	[int-ptr!]				;@@
		font		[int-ptr!]				;@@
	]

	v-terminal: 0
	extra-table: [0]						;-- extra unicode check table for Windows
	stub-table: [0 0]

	#include %wcwidth.reds

	#either OS = 'Windows [
		char-width?: func [
			cp		[integer!]
			return: [integer!]
		][
			either in-table? cp extra-table size? extra-table [2][wcwidth? cp]
		]
	][
		char-width?: func [
			cp		[integer!]
			return: [integer!]
		][
			wcwidth? cp
		]
	]

	string-lines?: func [
		str		[red-string!]
		offset	[integer!]
		length	[integer!]
		cols	[integer!]
		return: [integer!]
		/local
			n	[integer!]
	][
		n: string-width? str offset length cols
		either zero? n [1][n + cols - 1 / cols]
	]

	count-chars: func [
		str		[red-string!]
		offset	[integer!]
		length	[integer!]
		width	[integer!]
		return: [integer!]
		/local
			unit [integer!]
			len  [integer!]
			cp	 [integer!]
			w	 [integer!]
			s	 [series!]
			p0	 [byte-ptr!]
			p	 [byte-ptr!]
			tail [byte-ptr!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (offset << (unit >> 1))
		tail: p + (length << (unit >> 1))
		p0: p

		len: 0
		until [
			cp: string/get-char p unit
			w: char-width? cp
			if all [w = 2 len + 1 % width = 0][w: 1]
			len: len + w
			p: p + unit
			any [len % width = 0 p = tail]
		]
		(as-integer p - p0) >> (unit >> 1)
	]

	string-width?: func [
		str		[red-string!]
		offset	[integer!]
		len		[integer!]
		column	[integer!]
		return: [integer!]
		/local
			unit [integer!]
			w	 [integer!]
			s	 [series!]
			p	 [byte-ptr!]
			tail [byte-ptr!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (offset << (unit >> 1))
		tail: either len = -1 [as byte-ptr! s/tail][p + (len << (unit >> 1))]

		len: 0
		while [p < tail][
			w: char-width? string/get-char p unit
			unless zero? column [
				either w = 2 [
					if len + 1 % column = 0 [w: 3]
				][w: 1]
			]
			len: len + w
			p: p + unit
		]
		len
	]

	reposition: func [
		vt		[terminal!]
		/local
			out		[ring-buffer!]
			data	[red-string!]
			lines	[line-node!]
			node	[line-node!]
			head	[integer!]
			tail	[integer!]
			cols	[integer!]
			w		[integer!]
			y		[integer!]
	][
		out: vt/out
		lines: out/lines
		head: vt/top
		tail: out/tail
		node: lines + head - 1
		y: node/nlines - vt/top-offset
		while [
			head: head % out/max + 1
			all [head <> tail y <= vt/rows]
		][
			node: lines + head - 1
			y: y + node/nlines
		]
		if y <= vt/rows [exit]

		cols: vt/cols
		data: out/data

		y: 0
		head: out/head
		until [
			tail: tail - 1
			if zero? tail [tail: out/max]
			if tail = head [break]
			node: lines + tail - 1
			w: string-width? data node/offset node/length cols
			y: w - 1 / cols + 1 + y
			y >= vt/rows
		]
		if tail <> head [
			vt/top: tail
			vt/scroll: y - vt/rows
			preprocess vt
		]
	]

	set-prompt: func [
		vt		[terminal!]
		prompt  [red-string!]
		/local
			input [red-string!]
	][
		input: vt/in
		string/rs-reset input
		if TYPE_OF(prompt) = TYPE_NONE [prompt: vt/prompt]
		string/concatenate input prompt -1 0 yes no
		vt/prompt-len: string/rs-length? prompt
		input/head: vt/prompt-len
		vt/cursor: vt/prompt-len
		emit-string vt prompt no no
	]

	emit-c-string: func [
		vt		[terminal!]
		p		[byte-ptr!]
		tail	[byte-ptr!]
		unit	[integer!]
		last?	[logic!]
		append? [logic!]
		/local
			out		[ring-buffer!]
			data	[red-string!]
			lines	[line-node!]
			node	[line-node!]
			nlines	[integer!]
			added	[integer!]
			head	[integer!]
			n		[integer!]
			delta	[integer!]
			cursor	[integer!]
			buf		[series!]
			offset	[integer!]
			cp		[integer!]
			max		[integer!]
	][
		out: vt/out
		nlines: out/nlines
		max: out/max
		data: out/data
		added: 0
		head:	out/head
		cursor: out/tail
		lines: out/lines
		node: lines + cursor - 1
		buf: GET_BUFFER(data)
		offset: either append? [node/offset][string/rs-length? data]

		if p = tail [p: as byte-ptr! "^/" tail: p + 1 unit: 1]
		until [
			cp: string/get-char p unit
			p: p + unit

			buf: string/append-char buf cp
			if any [cp = 10 p = tail][
				node/offset: offset
				offset: string/rs-length? data
				node/length: offset - node/offset
				unless last? [nlines: nlines + 1]
				if cp = 10 [node/length: node/length - 1]
				n: string-lines? data node/offset node/length vt/cols
				delta: either any [append? last?][n - node/nlines][n]
				node/nlines: n
				added: added + delta
				cursor: cursor + 1
				if cursor > max [buf/tail: buf/offset cursor: 1]
				if cursor = head [head: head % max + 1]
				node: lines + cursor - 1
				node/nlines: 0
			]
			p = tail
		]
		if all [cp <> 10 natives/lf?][string/append-char buf 10]
		node/offset: string/rs-length? data

		out/nlines: nlines
		out/head: head
		out/tail: cursor
		vt/nlines: vt/nlines + added

		reposition vt

		either nlines >= max [out/nlines: max vt/pos: vt/nlines - vt/rows + 1][
			offset: vt/nlines - vt/pos - vt/rows
			if positive? offset [vt/pos: vt/pos + offset + 1]
		]
	]

	emit-string: func [
		vt		[terminal!]
		str		[red-string!]
		last?	[logic!]
		append? [logic!]
		/local
			s		[series!]
			unit	[integer!]
			p		[byte-ptr!]
			tail	[byte-ptr!]
	][
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		emit-c-string vt p tail unit last? append?
	]

	emit-newline: func [vt [terminal!]][emit-c-string vt null null 1 no no]

	preprocess: func [
		vt		[terminal!]
		/local
			out		[ring-buffer!]
			data	[red-string!]
			lines	[line-node!]
			node	[line-node!]
			cols	[integer!]
			offset	[integer!]
			start	[integer!]
			w		[integer!]
			y		[integer!]
	][
		start: vt/top
		cols: vt/cols
		offset: vt/scroll
		out: vt/out
		data: out/data
		lines: out/lines
		node: lines + start - 1
		case [
			all [
				negative? offset
				start <> out/head
			][
				until [
					start: start - 1
					if zero? start [start: out/max]
					node: lines + start - 1
					if start = out/head [offset: 0 break]
					w: string-width? data node/offset node/length cols
					y: w + cols - 1 / cols
					offset: y + offset
					offset >= 0
				]
			]
			all [
				positive? offset
				start <> out/tail
			][
				until [
					if start = out/last [offset: 0 break]
					w: string-width? data node/offset node/length cols
					y: w + cols - 1 / cols
					offset: offset - y
					if offset >= 0 [
						start: start % out/max + 1
						node: lines + start - 1
					]
					offset <= 0
				]
				if offset < 0 [offset: y + offset]
			]
			true [offset: 0]
		]

		out/h-idx: either positive? offset [
			count-chars data node/offset node/length cols * offset
		][0]
		vt/top: start
		vt/top-offset: offset
		vt/scroll: 0
	]

	insert-into-line: func [
		line	[red-string!]
		head	[integer!]
		cp		[integer!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(line)
		either head = string/rs-abs-length? line [
			string/append-char s cp
		][
			string/insert-char s head cp
		]
	]

	emit-char: func [
		vt		[terminal!]
		cp		[integer!]
		del?	[logic!]
		return: [logic!]
		/local
			input	[red-string!]
			node	[line-node!]
			out		[ring-buffer!]
			pos		[integer!]
			head	[integer!]
			len		[integer!]
			w		[integer!]
			s		[series!]
			tail	[byte-ptr!]
	][
		input: vt/in
		out: vt/out
		head: vt/cursor
		len: string/rs-abs-length? input

		either del? [
			if any [
				head = vt/prompt-len
				head > len
			][
				return false
			]
			head: head - 1
			string/remove-char input head
		][
			insert-into-line input head cp
			head: head + 1
		]
		vt/cursor: head

		s: GET_BUFFER(out/data)
		s/tail: as cell! (as byte-ptr! s/tail) - (len << (GET_UNIT(s) >> 1))
		if any [not del? len > 1][
			s: GET_BUFFER(input)
			out/tail: out/last
			tail: as byte-ptr! s/tail
			w: GET_UNIT(s)
			if cp = as-integer #"^[" [string/poke-char s tail - w 10]
			emit-c-string vt as byte-ptr! s/offset tail w yes no
			if cp = as-integer #"^[" [string/poke-char s tail - w 27]
		]
		true
	]

	scroll: func [
		vt		 [terminal!]
		distance [integer!]
		/local
			bottom	[integer!]
	][
		bottom: vt/nlines - vt/rows + 1
		switch distance [
			SCROLL_TOP		[vt/top: vt/out/head vt/pos: 1]
			SCROLL_BOTTOM	[vt/top: vt/out/last vt/pos: bottom]
			default [
				vt/scroll: vt/top-offset + distance
				vt/pos: vt/pos + distance
				if vt/pos > bottom [vt/pos: bottom]
				if vt/pos <= 0 [vt/pos: 1]
			]
		]
		preprocess vt
		refresh vt
	]

	hide-caret: func [vt [terminal!]][
		if vt/caret? [
			vt/caret?: no
			OS-hide-caret vt
		]
	]

	update-caret: func [
		vt [terminal!]
		/local
			cols	[integer!]
			x		[integer!]
	][
		cols: vt/cols
		x: string-width? vt/in 0 vt/cursor cols
		if positive? x [
			x: x % cols
			if zero? x [x: cols]
		]
		vt/caret-x: x
		OS-update-caret vt
	]

	refresh: func [
		vt		[terminal!]
		/local
			rc	[RECT_STRUCT]
	][
		rc: null
		;@@ calculate invalid rect
		OS-refresh vt rc
	]

	update-font: func [
		vt		[terminal!]
		char-x	[integer!]
		char-y	[integer!]
	][
		vt/cols: vt/win-w / char-x
		vt/rows: vt/win-h / char-y
		vt/char-w: char-x
		vt/char-h: char-y
	]

	init: func [
		vt		[terminal!]
		win-x	[integer!]
		win-y	[integer!]
		char-x	[integer!]
		char-y	[integer!]
		/local
			out		[ring-buffer!]
	][
		out: as ring-buffer! allocate size? ring-buffer!
		out/max: 4000
		out/tail: 1
		out/head: 1
		out/last: 1
		out/lines: as line-node! allocate out/max * size? line-node!
		out/lines/offset: 0
		out/lines/nlines: 1
		out/data: as red-string! string/rs-make-at ALLOC_TAIL(root) 4000
		out/nlines: 1
		out/h-idx: 0
		out/s-head: -1

		vt/win-w: win-x
		vt/win-h: win-y
		update-font vt char-x char-y
		vt/out: out
		vt/in: as red-string! #get system/console/line
		vt/buffer: as red-string! #get system/console/buffer
		vt/history: as red-block! #get system/console/history
		vt/history-max: 200
		vt/history-end: 1
		vt/history-cnt: 0
		vt/pos: 1
		vt/top: 1
		vt/nlines: 0
		vt/scroll: 0
		vt/caret?: no
		vt/select?: no
		vt/select-all?: no
		vt/ask?: no
		vt/input?: yes
		vt/prompt: as red-string! #get system/console/prompt
		vt/prompt-len: string/rs-length? vt/prompt

		OS-init vt

		#call [system/console/launch]
		emit-newline vt
		set-prompt vt vt/prompt
		out/last: out/tail - 1
	]

	close: func [
		vt	[terminal!]
		/local
			ring [ring-buffer!]
	][
		unless null? vt [
			OS-close vt
			ring: vt/out
			free as byte-ptr! ring/lines
			free as byte-ptr! ring
			free as byte-ptr! vt
		]
	]

	cancel-select: func [
		vt [terminal!]
		/local
			out		[ring-buffer!]
			head	[integer!]
			tail	[integer!]
			max		[integer!]
			lines	[line-node!]
			node	[line-node!]
	][
		vt/select-all?: no
		out: vt/out
		lines: out/lines
		max: out/max
		head: out/s-head
		tail: out/s-tail % max + 1

		if head <> -1 [
			until [
				node: lines + head - 1
				node/nlines: node/nlines << 1 >>> 1
				head: head % max + 1
				head = tail
			]
		]
	]

	mark-select: func [
		vt [terminal!]
		/local
			out		[ring-buffer!]
			head	[integer!]
			tail	[integer!]
			max		[integer!]
			lines	[line-node!]
			node	[line-node!]
	][
		out: vt/out
		lines: out/lines
		max: out/max
		head: out/s-head
		tail: out/s-tail % max + 1

		if head <> -1 [
			until [
				node: lines + head - 1
				node/nlines: node/nlines or 80000000h
				head: head % max + 1
				head = tail
			]
		]
	]

	select: func [
		vt		[terminal!]
		x		[integer!]
		y		[integer!]
		start?	[logic!]
		return: [logic!]
		/local
			out		[ring-buffer!]
			cols	[integer!]
			head	[integer!]
			tail	[integer!]
			max		[integer!]
			len		[integer!]
			offset	[integer!]
			w		[integer!]
			lines	[line-node!]
			node	[line-node!]
			data	[red-string!]
			up?		[logic!]
	][
		up?: no
		cols: vt/cols
		out: vt/out
		data: out/data
		lines: out/lines
		max: out/max
		tail: out/tail
		y: y / vt/char-h

		head: vt/top
		either start? [
			vt/select-x: x
			vt/select-y: y
		][
			up?: any [
				y < vt/select-y
				all [y = vt/select-y x < vt/select-x]
			]
		]

		node: lines + head - 1
		offset: node/offset + out/h-idx
		len: node/length - out/h-idx
		while [all [y > 0 head <> tail]][
			w: string-lines? data offset len cols
			y: y - w
			if y < 0 [break]
			head: head % max + 1
			node: lines + head - 1
			offset: node/offset
			len: node/length
		]
		if head = tail [return false]

		unless zero? y [y: w + y]
		x: x / vt/char-w
		if any [zero? len y > 0 x <> 0][
			x: either zero? len [0][
				count-chars data offset len cols * y + x
			]
			if head = vt/top [x: out/h-idx + x]
		]
		either start? [
			vt/s-head: head
			vt/s-h-idx: x
			out/s-head: head
			out/s-h-idx: x
			out/s-tail: head
			out/s-t-idx: x
		][
			either up? [
				out/s-tail: vt/s-head
				out/s-t-idx: vt/s-h-idx
				out/s-head: head
				out/s-h-idx: x
			][
				out/s-head: vt/s-head
				out/s-h-idx: vt/s-h-idx
				out/s-tail: head
				out/s-t-idx: x
			]
		]
		vt/select?: yes
		true
	]

	select-all: func [
		vt		[terminal!]
		/local
			out  [ring-buffer!]
			node [line-node!]
	][
		out: vt/out
		node: out/lines + out/last - 1
		cancel-select vt
		vt/select-all?: yes
		out/s-head: out/head
		out/s-h-idx: 0
		out/s-tail: out/last
		out/s-t-idx: node/length
	]

	fetch-history: func [
		vt		[terminal!]
		up?		[logic!]
		/local
			hist	[red-block!]
			input	[red-string!]
			tail	[integer!]
			idx		[integer!]
	][
		hist: vt/history
		if zero? hist/head [exit]

		idx: hist/head
		tail: 1
		either up? [
			tail: idx - 1
			if zero? tail [tail: vt/history-cnt]
		][
			tail: idx % vt/history-cnt + 1
		]

		hist/head: idx - 1
		input: vt/in
		string/rs-reset input
		string/concatenate input vt/prompt -1 0 yes no
		string/concatenate input as red-string! block/rs-head hist -1 0 yes no

		vt/out/tail: vt/out/last
		emit-string vt input yes no
		input/head: vt/prompt-len
		vt/cursor: string/rs-abs-length? input
		hist/head: tail
	]

	add-history: func [
		vt		[terminal!]
		/local
			str		[red-value!]
			history [red-block!]
	][
		str: as red-value! vt/in
		history: vt/history
		history/head: 0
		unless zero? string/rs-length? as red-string! str [
			str: as red-value! _series/copy
				 as red-series! str
				 as red-series! stack/push*
				 stack/arguments true stack/arguments

			either vt/history-cnt = vt/history-max [
				_series/poke as red-series! history vt/history-end str null
			][
				block/rs-append history str
				vt/history-cnt: vt/history-cnt + 1
			]
			stack/pop 1
			history/head: vt/history-end
			vt/history-end: vt/history-end % vt/history-max + 1
		]
	]

	cut-red-string: func [
		str [red-string!]
		len [integer!]
		/local
			s [series!]
	][
		if len = -1 [len: string/rs-length? str]
		s: GET_BUFFER(str)
		s/tail: as cell! (as byte-ptr! s/tail) - (len << (GET_UNIT(s) >> 1))
	]

	complete-line: func [
		vt			[terminal!]
		str			[red-string!]
		return:		[integer!]
		/local
			out		[ring-buffer!]
			line	[red-string!]
			result	[red-block!]
			num		[integer!]
			str2	[red-string!]
			head	[integer!]
	][
		line: declare red-string!
		_series/copy
			as red-series! str
			as red-series! line
			stack/arguments
			yes
			stack/arguments

		line/head: vt/cursor - vt/prompt-len
		#call [default-input-completer line]
		result: as red-block! stack/arguments
		num: block/rs-length? result

		out: vt/out
		unless zero? num [
			cut-red-string out/data string/rs-length? str
			cut-red-string str -1

			either num = 1 [
				str2: as red-string! block/rs-head result
				vt/cursor: vt/prompt-len + str2/head
				str2/head: 0
				string/concatenate str str2 -1 0 yes no
			][
				until [
					string/concatenate str as red-string! block/rs-head result -1 0 yes no
					string/append-char GET_BUFFER(str) 32
					block/rs-next result
					block/rs-tail? result
				]
				string/append-char GET_BUFFER(str) 10
			]
			out/tail: out/last
			emit-string vt str yes yes
			if num > 1 [
				cut-red-string str -1
				line/head: 0
				string/concatenate str line -1 0 yes no
				head: str/head
				str/head: 0
				emit-string vt str no no
				str/head: head
				head: out/tail - 1
				out/last: either zero? head [out/max][head]
			]
		]
		num
	]

	edit: func [
		vt		[terminal!]
		cp		[integer!]
		/local
			out		[ring-buffer!]
			input	[red-string!]
			cursor	[integer!]
			cue		[red-string!]
	][
		unless vt/input? [exit]

		out: vt/out
		input: vt/in
		cursor: vt/cursor
		switch cp [
			RS_KEY_NONE [exit]
			RS_KEY_TAB [
				if zero? complete-line vt input [edit vt 32]
			]
			RS_KEY_ENTER [
				vt/input?: no
				hide-caret vt
				cursor: string/rs-abs-length? input
				vt/cursor: cursor
				unless 27 = string/rs-abs-at input cursor - 1 [
					add-history vt
					emit-char vt 10 no
				]
				out/last: out/tail
				#call [system/console/eval-command input]
				vt/input?: yes
				set-prompt vt as red-string! #get system/console/cue
				cursor: out/tail - 1
				out/last: either zero? cursor [out/max][cursor]
				update-caret vt
			]
			RS_KEY_CTRL_H
			RS_KEY_BACKSPACE [unless emit-char vt cp yes [exit]]
			RS_KEY_CTRL_B
			RS_KEY_LEFT [
				unless input/head = cursor [
					vt/cursor: cursor - 1
					update-caret vt
				]
				exit
			]
			RS_KEY_CTRL_F
			RS_KEY_RIGHT [
				unless cursor = string/rs-abs-length? input [
					vt/cursor: cursor + 1
					update-caret vt
				]
				exit
			]
			RS_KEY_UP
			RS_KEY_CTRL_P [fetch-history vt yes]
			RS_KEY_DOWN
			RS_KEY_CTRL_N [fetch-history vt no]
			RS_KEY_CTRL_A [select-all vt]
			RS_KEY_HOME [
				vt/cursor: input/head
				update-caret vt
			]
			RS_KEY_CTRL_E
			RS_KEY_END [
				vt/cursor: string/rs-abs-length? input
				update-caret vt
			]
			RS_KEY_DELETE [
				vt/cursor: vt/cursor + 1
				unless emit-char vt cp yes [
					vt/cursor: vt/cursor - 1
					exit
				]
			]
			RS_KEY_CTRL_C [
				copy-to-clipboard vt
				exit
			]
			RS_KEY_CTRL_V [
				paste-from-clipboard vt
				exit
			]
			RS_KEY_ESCAPE [
				vt/cursor: string/rs-abs-length? input
				emit-char vt cp no
				edit vt RS_KEY_ENTER
			]
			default [
				if cp < 32 [exit]
				emit-char vt cp no
			]
		]
		refresh vt
	]

	set-text-color: func [
		vt			[terminal!]
		select?		[logic!]
		inversed?	[logic!]
		return:		[logic!]
	][
		either select? [
			unless inversed? [
				inversed?: yes
				set-select-color vt
			]
		][
			if inversed? [
				inversed?: no
				set-normal-color vt
			]
		]
		inversed?
	]

	paint-select: func [
		vt		[terminal!]
		line	[red-string!]
		length	[integer!]
		start	[integer!]
		end		[integer!]
		y		[integer!]
		return: [integer!]
		/local
			offset	[integer!]
			cols	[integer!]
			x		[integer!]
			w		[integer!]
			s		[series!]
			unit	[integer!]
			cp		[integer!]
			char-h	[integer!]
			p		[byte-ptr!]
			str		[c-string!]
	][
		cols: vt/cols
		char-h: vt/char-h
		offset: line/head
		s: GET_BUFFER(line)
		unit: GET_UNIT(s)
		p: string/rs-head line
		x: 0
		while [length > 0][
			if offset = start [set-select-color vt]
			if offset = end	  [set-normal-color vt]
			cp: string/get-char p unit
			str: as c-string! :cp
			w: vt/char-w * char-width? cp
			length: length - 1
			offset: offset + 1
			p: p + unit
			if x + w > vt/win-w [
				x: 0
				y: y + char-h
			]
			OS-draw-text str 1 x y w char-h
			x: x + w
		]
		unless vt/select-all? [set-normal-color vt]
		y + char-h
	]

	paint: func [
		vt		[terminal!]
		/local
			y			[integer!]
			char-h		[integer!]
			win-w		[integer!]
			win-h		[integer!]
			out			[ring-buffer!]
			cnt			[integer!]
			start		[integer!]
			end			[integer!]
			tail		[integer!]
			len			[integer!]
			offset		[integer!]
			nlines		[integer!]
			lines		[line-node!]
			node		[line-node!]
			data		[red-string!]
			select?		[logic!]
			inversed?	[logic!]
			c-str		[c-string!]
			n			[integer!]
	][
		win-w: vt/win-w
		win-h: vt/win-h
		char-h: vt/char-h
		out: vt/out
		data: out/data
		lines: out/lines
		select?: no
		inversed?: no
		start: vt/top
		tail: out/tail
		node: lines + start - 1
		offset: node/offset + out/h-idx
		len: node/length - (offset - node/offset)
		y: 0

		if vt/select-all? [set-select-color vt]

		while [all [start <> tail y < win-h]][
			nlines: node/nlines
			select?: nlines and 80000000h <> 0
			either not zero? len [
				n: string-lines? data node/offset node/length vt/cols
				data/head: offset
				case [
					start = out/s-head [
						end: either out/s-head = out/s-tail [
							out/s-t-idx
						][
							node/length
						]
						y: paint-select vt data len node/offset + out/s-h-idx node/offset + end y
					]
					all [
						out/s-head <> out/s-tail
						start = out/s-tail
					][
						y: paint-select vt data len offset node/offset + out/s-t-idx y
					]
					true [
						inversed?: set-text-color vt select? inversed?
						while [len > 0][
							cnt: count-chars data offset len vt/cols
							data/head: offset
							len: len - cnt
							offset: offset + cnt
							c-str: unicode/to-utf16-len data :cnt
							OS-draw-text c-str cnt 0 y win-w char-h
							y: y + char-h
						]
						if n - nlines <> 0 [
							vt/nlines: vt/nlines + n - (nlines and 7FFFFFFFh)
							node/nlines: nlines and 80000000h or n
						]
					]
				]
			][
				inversed?: set-text-color vt select? inversed?
				OS-draw-text null 0 0 y win-w char-h
				y: y + char-h
			]
			start: start % out/max + 1
			node: lines + start - 1	
			offset: node/offset
			len: node/length
		]
		vt/caret-y: either all [
			start = tail
			y <= win-h
		][y / char-h - 1][vt/rows + 1]
		if any [vt/select-all? inversed?][set-normal-color vt]
		data/head: 0
		OS-draw-text null 0 0 y win-w win-h - y + char-h
	]

	with gui [
		#switch OS [
			Windows  [#include %windows.reds]
			Android  []
			MacOSX   []
			FreeBSD  []
			Syllable []
			#default []										;-- Linux
		]
	]

	vprint: func [
		str		[byte-ptr!]
		size	[integer!]
		unit	[integer!]
		/local
			vt	[terminal!]
			out [ring-buffer!]
	][
		if zero? size [exit]
		vt: as terminal! v-terminal
		out: vt/out
		out/tail: out/last
		out/nlines: out/nlines - 1
		emit-c-string vt str str + size unit no yes
		refresh vt
	]

	vprint-line: func [
		str		[byte-ptr!]
		size	[integer!]
		unit	[integer!]
		/local
			vt	[terminal!]
			out [ring-buffer!]
	][
		vt: as terminal! v-terminal
		out: vt/out
		out/tail: out/last
		emit-c-string vt str str + size unit no yes
		out/last: out/tail
		refresh vt
	]
]