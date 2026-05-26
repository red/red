Red/System [
	Title:	"SDL3 text-box support"
	File: 	%text-box.reds
	Tabs: 	4
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_SIZE			3
#define TBOX_METRICS_LINE_COUNT		4
#define TBOX_METRICS_CHAR_INDEX?	5
#define TBOX_METRICS_OFFSET_LOWER	6

#define TBOX_STYLE_BOLD			1
#define TBOX_STYLE_ITALIC		2
#define TBOX_STYLE_UNDERLINE	4
#define TBOX_STYLE_STRIKE		8

tbox-attr!: alias struct! [
	fg		[integer!]
	bg		[integer!]
	style	[integer!]
	size	[integer!]
]

set-text-box-color: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	fg?		[logic!]
	/local
		max-len [integer!]
		p		[int-ptr!]
		attr	[tbox-attr!]
		end		[tbox-attr!]
][
	if layout = null [exit]
	p: layout
	max-len: p/value
	if any [pos < 0 len <= 0 pos >= max-len][exit]
	if pos + len > max-len [len: max-len - pos]
	attr: (as tbox-attr! layout) + 1 + pos
	end: attr + len
	while [attr < end][
		either fg? [attr/fg: color][attr/bg: color]
		attr: attr + 1
	]
]

set-text-box-style: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	flag	[integer!]
	/local
		max-len [integer!]
		p		[int-ptr!]
		attr	[tbox-attr!]
		end		[tbox-attr!]
][
	if layout = null [exit]
	p: layout
	max-len: p/value
	if any [pos < 0 len <= 0 pos >= max-len][exit]
	if pos + len > max-len [len: max-len - pos]
	attr: (as tbox-attr! layout) + 1 + pos
	end: attr + len
	while [attr < end][
		attr/style: attr/style or flag
		attr: attr + 1
	]
]

OS-text-box-color: func [dc [handle!] layout [handle!] pos [integer!] len [integer!] color [integer!]][
	set-text-box-color layout pos len color yes
]
OS-text-box-background: func [dc [handle!] layout [handle!] pos [integer!] len [integer!] color [integer!]][
	set-text-box-color layout pos len color no
]
OS-text-box-weight: func [layout [handle!] pos [integer!] len [integer!] weight [integer!]][
	set-text-box-style layout pos len TBOX_STYLE_BOLD
]
OS-text-box-italic: func [layout [handle!] pos [integer!] len [integer!]][
	set-text-box-style layout pos len TBOX_STYLE_ITALIC
]
OS-text-box-underline: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!]][
	set-text-box-style layout pos len TBOX_STYLE_UNDERLINE
]
OS-text-box-strikeout: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!]][
	set-text-box-style layout pos len TBOX_STYLE_STRIKE
]
OS-text-box-border: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!] return: [integer!]][0]
OS-text-box-font-name: func [font [handle!] layout [handle!] pos [integer!] len [integer!] name [red-string!]][]
OS-text-box-font-size: func [
	font	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		max-len [integer!]
		p		[int-ptr!]
		attr	[tbox-attr!]
		end		[tbox-attr!]
][
	if layout = null [exit]
	p: layout
	max-len: p/value
	if any [pos < 0 len <= 0 pos >= max-len][exit]
	if pos + len > max-len [len: max-len - pos]
	attr: (as tbox-attr! layout) + 1 + pos
	end: attr + len
	while [attr < end][
		attr/size: as-integer size
		attr: attr + 1
	]
]

tbox-ttf-style: func [
	flags [integer!]
	return: [integer!]
	/local style [integer!]
][
	style: TTF_STYLE_NORMAL
	if flags and TBOX_STYLE_BOLD <> 0 [style: style or TTF_STYLE_BOLD]
	if flags and TBOX_STYLE_ITALIC <> 0 [style: style or TTF_STYLE_ITALIC]
	if flags and TBOX_STYLE_UNDERLINE <> 0 [style: style or TTF_STYLE_UNDERLINE]
	if flags and TBOX_STYLE_STRIKE <> 0 [style: style or TTF_STYLE_STRIKETHROUGH]
	style
]

text-box-line-height: func [
	font	[red-object!]
	return: [integer!]
][
	as-integer font-size-facet font
]

text-box-measure-char: func [
	str		[red-string!]
	cp		[integer!]
	font	[red-object!]
	return: [integer!]
	/local
		w h n fs [integer!]
][
	;-- TTF per-codepoint shaping is deferred. Use average default glyph width
	;-- for caret hit-testing, while full layout size uses TTF string metrics.
	w: 0
	h: 0
	either get-text-size-px str font :w :h [
		either w > 0 [
			n: string/rs-length? str
			if n < 1 [n: 1]
			w / n
		][
			fs: as-integer font-size-facet font
			fs / 2
		]
	][
		fs: as-integer font-size-facet font
		fs / 2
	]
]

text-box-text-size: func [
	text	[red-string!]
	font	[red-object!]
	max-w	[integer!]
	w-out	[int-ptr!]
	h-out	[int-ptr!]
	lines-out [int-ptr!]
	/local
		len [integer!]
		series [series!]
		unit [integer!]
		offset [byte-ptr!]
		tail [byte-ptr!]
		cp [integer!]
		w h line-w line-h char-w lines [integer!]
][
	w-out/value: 0
	h-out/value: 0
	lines-out/value: 1
	if any [text = null TYPE_OF(text) <> TYPE_STRING][exit]
	len: string/rs-length? text
	if len <= 0 [
		h-out/value: text-box-line-height font
		exit
	]
	if get-text-size-wrapped-px text font max-w w-out h-out [
		line-h: text-box-line-height font
		either all [line-h > 0 h-out/value > 0][
			lines-out/value: h-out/value / line-h
			if lines-out/value < 1 [lines-out/value: 1]
		][
			lines-out/value: 1
		]
		exit
	]
	line-h: text-box-line-height font
	if line-h <= 0 [line-h: as-integer font-size-facet font]
	series: GET_BUFFER(text)
	unit: GET_UNIT(series)
	offset: (as byte-ptr! series/offset) + (text/head << (log-b unit))
	tail: as byte-ptr! series/tail
	w: 0
	line-w: 0
	lines: 1
	while [offset < tail][
		cp: string/get-char offset unit
		either cp = as-integer lf [
			if line-w > w [w: line-w]
			line-w: 0
			lines: lines + 1
		][
			char-w: text-box-measure-char text cp font
			if all [max-w > 0 line-w > 0 line-w + char-w > max-w][
				if line-w > w [w: line-w]
				line-w: 0
				lines: lines + 1
			]
			line-w: line-w + char-w
		]
		offset: offset + unit
	]
	if line-w > w [w: line-w]
	w-out/value: w
	h-out/value: lines * line-h
	lines-out/value: lines
]

text-box-face-color: func [
	box		[red-object!]
	fallback [integer!]
	return: [integer!]
	/local
		values [red-value!]
		color  [red-tuple!]
][
	values: object/get-values box
	color: as red-tuple! values + FACE_OBJ_COLOR
	either TYPE_OF(color) = TYPE_TUPLE [
		color/array1 and 00FFFFFFh
	][fallback]
]

make-text-box-attrs: func [
	text	[red-string!]
	color	[integer!]
	return: [handle!]
	/local
		len [integer!]
		buf [int-ptr!]
		attr [tbox-attr!]
		i	 [integer!]
][
	len: string/rs-length? text
	if len <= 0 [return null]
	buf: as int-ptr! zero-alloc (len + 1) * size? tbox-attr!
	buf/value: len
	attr: (as tbox-attr! buf) + 1
	i: 0
	while [i < len][
		attr/fg: color
		attr/bg: -1
		attr/style: 0
		attr/size: 0
		attr: attr + 1
		i: i + 1
	]
	as handle! buf
]

draw-text-box-attrs: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	box		 [red-object!]
	text	 [red-string!]
	font	 [red-object!]
	layout	 [handle!]
	color	 [integer!]
	wrap-w	 [integer!]
	/local
		series	[series!]
		unit	[integer!]
		offset	[byte-ptr!]
		tail	[byte-ptr!]
		cp		[integer!]
		attr	[tbox-attr!]
		tmp		[red-string!]
		cw ch	[integer!]
		xx yy	[integer!]
		line-h	[integer!]
		style	[integer!]
][
	if layout = null [draw-text-wrapped renderer x y text color font wrap-w exit]
	line-h: text-box-line-height font
	if line-h <= 0 [line-h: 20]
	tmp: string/rs-make-at ALLOC_TAIL(root) 2
	series: GET_BUFFER(text)
	unit: GET_UNIT(series)
	offset: (as byte-ptr! series/offset) + (text/head << (log-b unit))
	tail: as byte-ptr! series/tail
	attr: (as tbox-attr! layout) + 1
	xx: 0
	yy: 0
	while [offset < tail][
		cp: string/get-char offset unit
		either cp = as-integer lf [
			xx: 0
			yy: yy + line-h
		][
			string/rs-reset tmp
			string/append-char GET_BUFFER(tmp) cp
			cw: 0
			ch: 0
			style: tbox-ttf-style attr/style
			if not get-text-size-styled-px tmp font style :cw :ch [
				cw: line-h / 2
				ch: line-h
			]
			if all [wrap-w > 0 xx > 0 xx + cw > wrap-w][
				xx: 0
				yy: yy + line-h
			]
			if attr/bg <> -1 [
				rect-fill renderer x + xx y + yy cw line-h attr/bg
			]
			draw-text-styled renderer x + xx y + yy tmp attr/fg font style
			xx: xx + cw
		]
		offset: offset + unit
		attr: attr + 1
	]
]

text-box-caret-offset: func [
	text	[red-string!]
	font	[red-object!]
	max-w	[integer!]
	idx		[integer!]
	lower?	[logic!]
	return: [red-value!]
	/local
		len cnt limit [integer!]
		series [series!]
		unit [integer!]
		offset [byte-ptr!]
		tail [byte-ptr!]
		cp [integer!]
		x y line-h char-w [integer!]
][
	if idx < 1 [idx: 1]
	len: either TYPE_OF(text) = TYPE_STRING [string/rs-length? text][0]
	limit: len + 1
	if idx > limit [idx: limit]
	line-h: text-box-line-height font
	x: 0
	y: 0
	cnt: 1
	if len > 0 [
		series: GET_BUFFER(text)
		unit: GET_UNIT(series)
		offset: (as byte-ptr! series/offset) + (text/head << (log-b unit))
		tail: as byte-ptr! series/tail
		while [all [offset < tail cnt < idx]][
			cp: string/get-char offset unit
			either cp = as-integer lf [
				x: 0
				y: y + line-h
			][
				char-w: text-box-measure-char text cp font
				if all [max-w > 0 x > 0 x + char-w > max-w][
					x: 0
					y: y + line-h
				]
				x: x + char-w
			]
			offset: offset + unit
			cnt: cnt + 1
		]
	]
	if lower? [y: y + line-h]
	as red-value! point2D/push as float32! x as float32! y
]

text-box-index-at: func [
	text	[red-string!]
	font	[red-object!]
	max-w	[integer!]
	arg0	[red-value!]
	char?	[logic!]
	return: [red-value!]
	/local
		pos [red-pair!]
		pt	[red-point2D!]
		x y [integer!]
		line-h [integer!]
		series [series!]
		unit [integer!]
		offset [byte-ptr!]
		tail [byte-ptr!]
		cp [integer!]
		xx yy char-w cnt bottom edge mid [integer!]
][
	pos: as red-pair! arg0
	GET_PAIR_XY_INT(pos x y)
	line-h: text-box-line-height font
	xx: 0
	yy: 0
	cnt: 1
	if TYPE_OF(text) = TYPE_STRING [
		series: GET_BUFFER(text)
		unit: GET_UNIT(series)
		offset: (as byte-ptr! series/offset) + (text/head << (log-b unit))
		tail: as byte-ptr! series/tail
		while [offset < tail][
			cp: string/get-char offset unit
			either cp = as-integer lf [
				bottom: yy + line-h
				if y < bottom [return as red-value! integer/push cnt]
				xx: 0
				yy: yy + line-h
			][
				char-w: text-box-measure-char text cp font
				if all [max-w > 0 xx > 0 xx + char-w > max-w][
					xx: 0
					yy: yy + line-h
				]
				bottom: yy + line-h
				mid: xx + (char-w / 2)
				if all [y < bottom x < mid][
					return as red-value! integer/push cnt
				]
				edge: xx + char-w
				if all [y < bottom x < edge][
					return as red-value! integer/push either char? [cnt][cnt + 1]
				]
				xx: xx + char-w
			]
			offset: offset + unit
			cnt: cnt + 1
		]
	]
	as red-value! integer/push cnt
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
	/local
		cell	[red-value!]
		text	[red-string!]
		font	[red-object!]
		int		[red-integer!]
		w h lines max-w [integer!]
][
	if TYPE_OF(state) <> TYPE_BLOCK [return as red-value! none-value]
	cell: block/rs-head state
	text: as red-string! cell
	font: as red-object! cell + 1
	int: as red-integer! cell + 2
	max-w: either TYPE_OF(int) = TYPE_INTEGER [int/value][0]
	as red-value! switch type [
		TBOX_METRICS_OFFSET? [
			int: as red-integer! arg0
			text-box-caret-offset text font max-w int/value no
		]
		TBOX_METRICS_OFFSET_LOWER [
			int: as red-integer! arg0
			text-box-caret-offset text font max-w int/value yes
		]
		TBOX_METRICS_INDEX? [
			text-box-index-at text font max-w arg0 no
		]
		TBOX_METRICS_CHAR_INDEX? [
			text-box-index-at text font max-w arg0 yes
		]
		TBOX_METRICS_LINE_HEIGHT [
			float/push as float! text-box-line-height font
		]
		TBOX_METRICS_SIZE [
			w: 0
			h: 0
			lines: 0
			text-box-text-size text font max-w :w :h :lines
			point2D/push as float32! w as float32! h
		]
		TBOX_METRICS_LINE_COUNT [
			w: 0
			h: 0
			lines: 0
			text-box-text-size text font max-w :w :h :lines
			integer/push lines
		]
		default [none-value]
	]
]

OS-text-box-layout: func [
	box			[red-object!]
	target		[int-ptr!]
	nscolor		[integer!]
	catch?		[logic!]
	return:		[integer!]
	/local
		values	[red-value!]
		state	[red-block!]
		size	[red-pair!]
		pt		[red-point2D!]
		font	[red-object!]
		parent	[red-object!]
		cell	[red-value!]
		bool	[red-logic!]
		styles	[red-block!]
		text	[red-string!]
		layout	[handle!]
		h		[red-handle!]
		sx sy	[integer!]
][
	values: object/get-values box
	state: as red-block! values + FACE_OBJ_EXT3
	text: as red-string! values + FACE_OBJ_TEXT
	size: as red-pair! values + FACE_OBJ_SIZE
	font: as red-object! values + FACE_OBJ_FONT
	parent: as red-object! values + FACE_OBJ_PARENT
	styles: as red-block! values + FACE_OBJ_DATA
	if all [TYPE_OF(font) <> TYPE_OBJECT TYPE_OF(parent) = TYPE_OBJECT][
		font: as red-object! (object/get-values parent) + FACE_OBJ_FONT
	]
	either TYPE_OF(size) = TYPE_PAIR [
		sx: size/x
		sy: size/y
	][
		pt: as red-point2D! size
		either TYPE_OF(pt) = TYPE_POINT2D [
			sx: as-integer pt/x
			sy: as-integer pt/y
		][
			sx: 0
			sy: 0
		]
	]
	if sx < 0 [sx: 0]
	either TYPE_OF(state) = TYPE_BLOCK [
		cell: block/rs-head state
		h: as red-handle! cell + 5
		layout: as handle! h/value
		if layout <> null [free as byte-ptr! layout]
	][
		block/make-at state 6
		none/make-in state
		none/make-in state
		integer/make-in state 0
		integer/make-in state 0
		logic/make-in state false
		handle/make-in state 0 handle/CLASS_RICHTEXT
		cell: block/rs-head state
	]
	copy-cell values + FACE_OBJ_TEXT cell
	copy-cell as red-value! font cell + 1
	integer/make-at cell + 2 sx
	integer/make-at cell + 3 sy
	bool: as red-logic! cell + 4
	bool/value: false
	layout: null
	if all [
		TYPE_OF(text) = TYPE_STRING
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		layout: make-text-box-attrs text nscolor
		parse-text-styles target layout styles text catch?
	]
	handle/make-at cell + 5 as-integer layout handle/CLASS_RICHTEXT
	0
]

draw-text-box: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	box		 [red-object!]
	color	 [integer!]
	catch?	 [logic!]
	/local
		values [red-value!]
		text   [red-string!]
		font   [red-object!]
		parent [red-object!]
		size   [red-pair!]
		pt	   [red-point2D!]
		state  [red-block!]
		styles [red-block!]
		layout [handle!]
		h	   [red-handle!]
		w	   [integer!]
][
	values: object/get-values box
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [exit]
	font: as red-object! values + FACE_OBJ_FONT
	parent: as red-object! values + FACE_OBJ_PARENT
	if all [TYPE_OF(font) <> TYPE_OBJECT TYPE_OF(parent) = TYPE_OBJECT][
		font: as red-object! (object/get-values parent) + FACE_OBJ_FONT
	]
	size: as red-pair! values + FACE_OBJ_SIZE
	either TYPE_OF(size) = TYPE_PAIR [
		w: size/x
	][
		pt: as red-point2D! size
		w: either TYPE_OF(pt) = TYPE_POINT2D [as-integer pt/x][0]
	]
	state: as red-block! values + FACE_OBJ_EXT3
	layout: null
	if TYPE_OF(state) = TYPE_BLOCK [
		h: as red-handle! (block/rs-head state) + 5
		layout: as handle! h/value
	]
	styles: as red-block! values + FACE_OBJ_DATA
	if all [
		layout = null
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		OS-text-box-layout box null color catch?
		state: as red-block! values + FACE_OBJ_EXT3
		if TYPE_OF(state) = TYPE_BLOCK [
			h: as red-handle! (block/rs-head state) + 5
			layout: as handle! h/value
		]
	]
	either layout <> null [
		draw-text-box-attrs renderer x y box text font layout color w
	][
		either w > 0 [
			draw-text-wrapped renderer x y text color font w
		][
			draw-text renderer x y text color font
		]
	]
]

adjust-index: func [
	str		[red-string!]
	offset	[integer!]
	idx		[integer!]
	adjust	[integer!]
	return: [integer!]
	/local
		s		[series!]
		unit	[integer!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		c		[integer!]
][
	assert TYPE_OF(str) = TYPE_STRING
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	if unit = UCS-4 [
		head: (as byte-ptr! s/offset) + (str/head + offset << 2)
		tail: head + (idx * 4)
		while [head < tail][
			c: string/get-char head unit
			if c >= 00010000h [
				idx: idx + adjust
				if adjust < 0 [tail: tail - unit]
			]
			head: head + unit
		]
	]
	idx
]
