Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian, RCqls"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw-d2d.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_SIZE			3
#define TBOX_METRICS_LINE_COUNT		4
#define TBOX_METRICS_CHAR_INDEX?	5
#define TBOX_METRICS_OFFSET_LOWER	6

#define PANGO_TEXT_MARKUP_SIZED		500

max-line-cnt:  0

pango-opt-tag!: alias struct! [
	opt 	[c-string!]
	pos 	[integer!]
	len		[integer!]
]

pango-compare-tag: func [
	[cdecl] 
	tag1 	[pango-opt-tag!] 
	tag2 	[pango-opt-tag!] 
	return:	[integer!]
	/local
		comp 	[integer!]
][
	;; DEBUG: print ["pango-compare-tag: (" tag1/pos "," tag1/len "," tag1/opt ") and ("  tag2/pos "," tag2/len "," tag2/opt  ") -> " ]
	either tag1/pos = tag2/pos [
		either tag1/len = tag2/len [comp: 0][
			comp: either tag1/len > tag2/len [-1][1]
		]
	][
		comp: either tag1/pos > tag2/pos [1][-1]
	]
	comp
]

make-pango-opt-tag: func [
	opt 	[c-string!]
	pos		[integer!]
	len		[integer!]
	return:	[handle!]
	/local
		tag 	[pango-opt-tag!]
][
	tag: as pango-opt-tag! allocate size? pango-opt-tag!
	tag/opt: opt tag/pos: pos tag/len: len
	as handle! tag
]

pango-insert-tag: func [
	lc 		[layout-ctx!]
	opt 	[c-string!]
	pos		[integer!]
	len		[integer!]
	/local
		tag 	[handle!]
		tag2 	[handle!]
][
	if pos + len > lc/text-len [len: lc/text-len - pos]
	tag: make-pango-opt-tag opt pos len
	;; DEBUG: print ["insert tag: " tag  lf ]; "<span " tag/opt "> at (" tag/pos "," tag/len ")" lf ]
	lc/tag-list: g_list_insert_sorted lc/tag-list tag as-integer :pango-compare-tag
]

pango-append-open-tag: func [
	gstr	[GString!]
	ot 		[c-string!]
][
	g_string_append gstr "<span "
	g_string_append gstr ot
	g_string_append gstr ">"
	g_free as handle! ot
]

layout-preamble?: func [
	gstr		[GString!]
	fd			[handle!]
	color 		[integer!]
	/local
		ot		[c-string!]
		rgba	[c-string!]
][
	g_string_assign gstr "<markup>"

	ot: pango-open-tag-string? "face" pango_font_description_get_family fd
	pango-append-open-tag gstr ot

	ot: pango-open-tag-int? "size" pango_font_description_get_size fd
	pango-append-open-tag gstr ot

	rgba: int-to-bgra-hex color
	;; DEBUG: print ["col(" rgba ")[" pos "," pos + len - 1 "]" lf]
	
	ot: pango-open-tag-string? "color" rgba
	pango-append-open-tag gstr ot
]

layout-postamble?: func [
	gstr		[GString!]
][
	g_string_append gstr "</span></span></span>"
	g_string_append gstr "</markup>"
	;; DEBUG: print ["text: " lc/text lf]
	;; DEBUG: print ["text-markup: " text/str lf]
]

layout-ctx-init: func [
	lc 			[layout-ctx!]
	text 		[c-string!]
	text-len	[integer!]
	/local
		gstr 	[GString!]
][
	lc/closed-tags: null
	lc/text: text
	lc/text-len: text-len
	lc/text-pos: 0
	lc/text-markup: as handle! g_string_sized_new PANGO_TEXT_MARKUP_SIZED
	lc/tag-list: null
	gstr: as GString! lc/text-markup
	g_string_assign gstr ""
]

pango-add-open-tag: func [
	lc 			[layout-ctx!]
	open-tag	[c-string!]
	pos			[integer!]
	/local
		gstr		[GString!]
][
	gstr: as GString! lc/text-markup
	if lc/text-pos < pos [ ; add text until pos
		g_string_append_len gstr lc/text + lc/text-pos pos - lc/text-pos
		lc/text-pos: pos
	]
	pango-append-open-tag gstr open-tag
	; g_string_append gstr "<span "
	; g_string_append gstr open-tag
	; g_string_append gstr ">"
	; g_free as handle! open-tag
]

pango-open-tag-string?: func [
	attr-key	[c-string!]
	attr-val	[c-string!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%s'" attr-key attr-val]
	str
]

pango-open-tag-int?: func [
	attr-key	[c-string!]
	attr-val	[integer!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%d'" attr-key attr-val]
	str
]

pango-open-tag-float?: func [
	attr-key	[c-string!]
	attr-val	[float!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%f'" attr-key attr-val]
 	str
]

pango-add-closed-tag: func [
	lc 			[layout-ctx!]
	level 		[integer!]
][
	;; DEBUG: print ["add-closed-tag: " level lf]
	lc/closed-tags: g_list_prepend lc/closed-tags as int-ptr! (level + 1)
]

pango-last-closed-tag?: func [ ; last in time not in the GList
	lc 			[layout-ctx!]
	return: 	[integer!]
	/local
		current 	[int-ptr!]
][
	current: g_list_nth_data lc/closed-tags 0
	either null? current [-1][(as integer! current) - 1]
]

pango-next-closed-tag: func [
	lc 		[layout-ctx!]
	/local
		first 	[handle!]
][
	first: g_list_first lc/closed-tags
	lc/closed-tags: g_list_delete_link lc/closed-tags first
]

pango-close-tags: func [
	lc					[layout-ctx!]
	pos-last-closed-tag	[integer!]
	/local
		text-len		[integer!]
		gstr 			[GString!]
		last? 			[logic!]
][
	;; DEBUG: print ["pango-close-tags: " lc " text-markup: "  lc/text-markup lf]
	last?: no
	gstr: as GString! lc/text-markup
	if pos-last-closed-tag = -1 [
		last?: yes
		;; DEBUG: print ["pos-last-closed-tag = -1" lf]
		pos-last-closed-tag: pango-last-closed-tag? lc
	]
	text-len: either pos-last-closed-tag > lc/text-len [lc/text-len][pos-last-closed-tag]
	text-len: text-len - lc/text-pos
	;; DEBUG: print ["pango-close-tags -> append: (" text-len ")" lc/text + lc/text-pos  lf]
	if text-len > 0 [
		g_string_append_len gstr lc/text + lc/text-pos text-len
		lc/text-pos: lc/text-pos + text-len
	]
	if 0 < g_list_length lc/closed-tags [
		; Add closed tags
		;; DEBUG: print ["close-tags: " pos-last-closed-tag " "  pango-last-closed-tag? lc  lf]
		while [ pos-last-closed-tag = pango-last-closed-tag? lc ][
			;; DEBUG: print ["close-tags: </span>" lf]
			g_string_append  gstr "</span>"
			;; DEBUG: print ["text-markup after close-tag: " gstr/str lf]
			pango-next-closed-tag lc

		]
	]
	;; DEBUG: print ["size? lc/closed-tags: " g_list_length lc/closed-tags lf]
	if all[ last? 0 < g_list_length lc/closed-tags] [pango-close-tags lc -1]
]

pango-process-closed-tags: func [
	lc 			[layout-ctx!]
	pos 		[integer!]
	len 		[integer!]
	/local
		text 					[c-string!]
		tmp 					[c-string!]
		pos-current-closed-tag 	[integer!]
		pos-last-closed-tag 	[integer!]
][	
	pos-last-closed-tag: pango-last-closed-tag? lc
	pos-current-closed-tag: pos + len
	;; DEBUG: print ["process closed tags: current=" pos-current-closed-tag " last=" pos-last-closed-tag lf]
	; Close tags with text first if any
	if all[
		pos-last-closed-tag <> -1 
		pos-current-closed-tag > pos-last-closed-tag
	][
		pango-close-tags lc pos-last-closed-tag
	]
]

pango-process-tag: func [
	lc 			[layout-ctx!]
	open-tag	[c-string!]
	pos 		[integer!]
	len 		[integer!]
][
	pango-process-closed-tags lc pos len
	pango-add-open-tag lc open-tag pos
	pango-add-closed-tag lc pos + len
]

layout-ctx-do: func [
	lc 			[layout-ctx!]
	fd 			[handle!]
	color 		[integer!]
	/local
		gl		[GList!]
		last	[GList!]
		tag		[pango-opt-tag!]
		len		[integer!]
		pos		[integer!]
		opt		[c-string!]
		gstr	[GString!]
][
	gstr: as GString! lc/text-markup
	;; DEBUG: print ["layout-ctx-do layout: " lc/layout " " pango_font_description_get_family fd " " pango_font_description_get_size fd lf]
	layout-preamble? gstr fd color
	either null? lc/tag-list [
		g_string_append gstr lc/text
	][
		last: as GList! g_list_last lc/tag-list
		gl: as GList! g_list_first lc/tag-list

		lc/text-pos: 0 lc/closed-tags: null
		until [
			tag: as pango-opt-tag! gl/data
			;; DEBUG: print ["<span "  tag/opt "> at (" tag/pos "," tag/len ")" lf]
			pango-process-tag lc tag/opt tag/pos tag/len
			
			gl: gl/next
			null? gl
		]
		pango-close-tags lc -1
	]
	layout-postamble? gstr
]

int-to-rgba: func [
	color		[integer!]
	r			[int-ptr!]
	b			[int-ptr!]
	g			[int-ptr!]
	a			[int-ptr!]
][
	;; TODO:
	r/value: (color >> 24 and FFh) << 8
	g/value: (color >> 16 and FFh) << 8
	b/value: (color >> 8 and FFh) << 8
	a/value: (color  and FFh) << 8
	;; DEBUG: print ["color: " color " " r/value "." g/value "." b/value "." a/value lf ]
]

int-to-bgra-hex: func [
	color		[integer!]
	return: 	[c-string!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	a: (color >> 24 and FFh) 
	r: (color >> 16 and FFh) 
	g: (color >> 8 and FFh) 
	b: (color  and FFh)
	color: (b << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( r << 8 and FF00h) or ( a and FFh)
	;; DEBUG: print ["col(#" string/to-hex color no ")" lf]
	g_strdup_printf ["#%s" string/to-hex  color no]
]

OS-text-box-color: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		lc		[layout-ctx!]
		rgba	[c-string!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout

	rgba: int-to-bgra-hex color
	;; DEBUG: print ["col(" rgba ")[" pos "," pos + len - 1 "]" lf]
	
	ot: pango-open-tag-string? "color" rgba
	pango-insert-tag lc ot pos len
]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		lc		[layout-ctx!]
		rgba	[c-string!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	
	rgba: int-to-bgra-hex color
	;; DEBUG: print ["bgcol(" rgba ")[" pos "," pos + len - 1 "]" lf]
	
	ot: pango-open-tag-string? "bgcolor" rgba
	pango-insert-tag lc ot pos len

]



OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
	/local
		lc		[layout-ctx!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout

	ot: pango-open-tag-int? "weight" weight pos len
	pango-insert-tag lc ot pos len

]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	/local
		lc		[layout-ctx!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout

	ot: pango-open-tag-string? "style" "italic"
	pango-insert-tag lc ot pos len
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		lc		[layout-ctx!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout

	ot: pango-open-tag-string? "underline" "single"
	pango-insert-tag lc ot pos len
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]
	/local
		lc		[layout-ctx!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	
	ot: pango-open-tag-string? "strikethrough" "true"
	pango-insert-tag lc ot pos len
]

OS-text-box-border: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		lc		[layout-ctx!]
][
	lc: as layout-ctx! layout
]

OS-text-box-font-name: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
	/local
		lc		[layout-ctx!]
		strlen	[integer!]
		str		[c-string!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	strlen: -1
	str: unicode/to-utf8 name :strlen

	ot: pango-open-tag-string? "face" str
	pango-insert-tag lc ot pos len
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		lc		[layout-ctx!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout

	ot: pango-open-tag-int? "font" as integer! size
	pango-insert-tag lc ot pos len
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
	/local
		int		[red-integer!]
		rstate	[red-integer!]
		layout	[handle!]
		x		[float!]
		y		[float!]
		width	[integer!]
		height	[integer!]
		pos		[red-pair!]
		rect	[tagRECT value]
		lrect	[tagRECT value]
		pline	[handle!]
		idx		[integer!]
		trail	[integer!]
		ok?		[logic!]
		;; DEBUG: fd		[handle!]
][
	;; DEBUG: print ["OS-text-box-metrics: " get-symbol-name type lf]
	rstate: as red-integer! block/rs-head state
	layout: as handle! rstate/value
	;; DEBUG: print ["layout: " layout lf]
	;; DEBUG: fd: pango_layout_get_font_description layout print ["OS-text-box-metrics layout: " layout " " pango_font_description_get_family fd " " pango_font_description_get_size fd lf]
	if null? layout [return as red-value! none-value]
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER [ ; caret-to-offset 
			int: as red-integer! arg0
			pango_layout_index_to_pos layout int/value - 1 :rect
			;; DEBUG: print ["TBOX_METRICS_OFFSET? " rect/x / PANGO_SCALE "x" rect/y / PANGO_SCALE "x" rect/width / PANGO_SCALE "x" rect/height / PANGO_SCALE lf] 
			pair/push rect/x / PANGO_SCALE  rect/y / PANGO_SCALE
		]
		TBOX_METRICS_INDEX? 
		TBOX_METRICS_CHAR_INDEX? [ ; offset-to-caret
			pos: as red-pair! arg0
			idx: -1 trail: -1
			;; DEBUG: print ["TBOX_METRICS_INDEX? pos: " pos/x "x" pos/y lf]
			ok?: pango_layout_xy_to_index layout (pos/x * PANGO_SCALE) (pos/y * PANGO_SCALE) :idx :trail
			;; DEBUG: print ["TBOX_METRICS_INDEX? " pos/x "x" pos/y  " " ok? " index: " idx + 1   lf]
			if all[type = TBOX_METRICS_INDEX? 0 <> trail] [idx: idx + 1]
			integer/push idx + 1
		]
		TBOX_METRICS_SIZE [
			pline: pango_layout_get_line layout 0
			pango_layout_line_get_pixel_extents pline rect lrect
			width: -1 height: -1
			;pango_layout_get_pixel_size layout :width :height
			; width: (pango_layout_get_width layout) / PANGO_SCALE
			height: (pango_layout_get_line_count layout) * lrect/height 
			width: lrect/width
			;; DEBUG: print ["TBOX_METRICS_SIZE: " width "x" height " " pango_layout_get_line_count layout lf]
			;print ["text: " layout/text lf]
			pair/push width height
		]
		TBOX_METRICS_LINE_COUNT [
			idx: pango_layout_get_line_count layout
			;; DEBUG: print ["TBOX_METRICS_LINE_COUNT: " idx lf]
			integer/push idx
		]
		TBOX_METRICS_LINE_HEIGHT [
			int: as red-integer! arg0
			pango_layout_index_to_pos layout int/value :rect
			height: rect/height / PANGO_SCALE
			;; DEBUG: print ["TBOX_METRICS_LINE_HEIGHT " height  " (" rect/x "x" rect/y "x" rect/width "x" rect/height ")" lf]
			integer/push height
		]
		default [
			none-value
		]
	]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[int-ptr!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [handle!]
	/local
		hWnd	[handle!]
		values	[red-value!]
		size	[red-pair!]
		rstate	[red-integer!]
		bool	[red-logic!]
		state	[red-block!]
		styles	[red-block!]
		pval	[red-value!]
		vec		[red-vector!]
		obj		[red-object!]
		w		[integer!]
		h		[integer!]
		dc 		[draw-ctx!]
		lc 		[layout-ctx!]
		cached? [logic!]
		force?	[logic!]
		font 	[red-object!]
		hFont	[handle!]
		clr		[integer!]
		text	[red-string!]
		len		[integer!]
		str		[c-string!]
		pc		[handle!]
		ft-ok?	[logic!]
][	
	;; DEBUG: print ["OS-text-box-layout: " box " " face-handle? box " target: " target lf]
	values: object/get-values box
	state: as red-block! values + FACE_OBJ_EXT3
	cached?: TYPE_OF(state) = TYPE_BLOCK
	;; DEBUG: print ["cached?: " cached? " state: " state lf]
	force?: either cached? [
		rstate: as red-integer! block/rs-head state
		bool: as red-logic! rstate + 1
		;; DEBUG: print ["rstate: " rstate " -> " rstate/value " bool: " bool " -> " bool/value  lf]
		bool/value
	][true]
	;; DEBUG: print ["force?: " force? lf]

	lc: declare layout-ctx! ; this is not dynamic but lc/layout would change dynamically for each rich-text
	text: as red-string! values + FACE_OBJ_TEXT
	font: as red-object! values + FACE_OBJ_FONT
	ft-ok?: TYPE_OF(font) = TYPE_OBJECT ;all[not null? target TYPE_OF(font) = TYPE_OBJECT]
	hFont: default-font 
	if ft-ok? [
		hFont: get-font-handle font 0
		if null? hFont [hFont: default-font]
	]

	len: -1
	str: unicode/to-utf8 text :len
	;str: g_markup_escape_text str len

	layout-ctx-init lc str length? str

	size: as red-pair! values + FACE_OBJ_SIZE

	either force? [
		;; create lc/layout
		;; DEBUG: print ["create layout: " target  lf]
		either null? target [
			either cached? [lc/layout: as handle! rstate/value]
			[
				; this is when OS-text-box-metrics is used before drawing
				if null? pango-context [pango-context: gdk_pango_context_get]
				lc/layout: pango_layout_new pango-context
				;; DEBUG: print ["rich-text layout: " lc/layout " " pango_font_description_get_family hFont " " pango_font_description_get_size hFont lf]
				pango_layout_set_font_description lc/layout hFont 
			]
		][
			dc: as draw-ctx! target
			dc/font-desc: hFont
			lc/layout: make-pango-cairo-layout dc/raw dc/font-desc
			;; DEBUG: print ["rich-text layout with target: " lc/layout lf]
		]
		;; DEBUG: print ["with  target: " target " lc/layout: " lc/layout lf]
		either cached? [
			rstate/value: as integer! lc/layout
			bool/value: false
			;; DEBUG: print ["lc/layout force to be updated: " lc/layout " bool: " bool/value lf]
		][
			block/make-at state 3 									;maybe more later
			;; DEBUG: print ["lc/layout newly created: " lc/layout lf]
			integer/make-in state as integer! lc/layout				; handle for lc/layout
			logic/make-in state either null? target [true][false] 	; force build lc/layout
			logic/make-in state true								; possible use for redraw used in gui.red/update-richtext
		]
	][
		lc/layout: as handle! rstate/value
		;; DEBUG: print ["lc/layout cached: " lc/layout lf]
	]

	styles: as red-block! values + FACE_OBJ_DATA
	either all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		parse-text-styles target as handle! lc styles 7FFFFFFFh catch?
	][
		g_string_assign as GString! lc/text-markup lc/text
	]
	pango_layout_set_font_description lc/layout hFont
	layout-ctx-do lc hFont either ft-ok? [font-color? font][ft-clr]
	if null? target [
		pango-layout-set-text lc size
	]
	as handle! lc
]

pango-layout-set-text: func [
	lc 		[layout-ctx!]
	size	[red-pair!]
	/local
		gstr 	[GString!]
][
	gstr: as GString! lc/text-markup
	;; DEBUG: print ["pango-layout-set-text:<<-" gstr/str "->>" lf]
	;;pango_layout_set_markup lc/layout gstr/str -1
	pango-layout-set-markup lc/layout gstr/str -1 false
	pango_layout_set_width lc/layout PANGO_SCALE * size/x
	pango_layout_set_height lc/layout PANGO_SCALE * size/y
	pango_layout_set_wrap lc/layout PANGO_WRAP_WORD_CHAR
]

; pango-layout-styled-set-text: func [

; ]
