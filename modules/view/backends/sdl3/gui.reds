Red/System [
	Title:	"SDL3 GUI backend"
	File: 	%gui.reds
	Tabs: 	4
]

#define EVT_NO_DISPATCH 0
#define EVT_DISPATCH	1

#include %sdl3.reds
#include %font.reds
#include %text-box.reds
#include %draw.reds
#include %events.reds

#define WIDGET_FLAG_HIDDEN		00020000h
#define WIDGET_FLAG_DISABLE		00040000h
#define WIDGET_FLAG_FOCUSABLE	00400000h
#define WIDGET_FLAG_FULLSCREEN	40000000h

#define S32_PAIR_X(pair) [as-integer pair/x]
#define S32_PAIR_Y(pair) [as-integer pair/y]

sdl-widget!: alias struct! [
	window		[handle!]
	renderer	[handle!]
	window-id	[integer!]
	face		[red-object! value]
	parent		[sdl-widget!]
	flags		[integer!]
	x			[integer!]
	y			[integer!]
	w			[integer!]
	h			[integer!]
	cursor		[integer!]
	timer-ms	[integer!]
	timer-next	[integer!]
	dirty?		[logic!]
]

screen-handle: as handle! 1
last-window: declare sdl-widget!
last-window: null
focused-widget: declare sdl-widget!
focused-widget: null
hover-widget: declare sdl-widget!
hover-widget: null
pressed-widget: declare sdl-widget!
pressed-widget: null
initialized?: no
quit?: no
exit-loop?: no

get-node-facet: func [
	node	[node!]
	facet	[integer!]
	return: [red-value!]
	/local
		ctx	 [red-context!]
		s	 [series!]
][
	ctx: TO_CTX(node)
	s: as series! ctx/values/value
	s/offset + facet
]

face-handle?: func [
	face	[red-object!]
	return: [handle!]
	/local
		state  [red-block!]
		hnd	   [red-handle!]
][
	state: as red-block! get-node-facet face/ctx FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		hnd: as red-handle! block/rs-head state
		if all [
			TYPE_OF(hnd) = TYPE_HANDLE
			hnd/type = handle/CLASS_WINDOW
			hnd/value > 1
		][return as handle! hnd/value]
	]
	null
]

get-face-handle: func [
	face	[red-object!]
	return: [handle!]
	/local
		h [handle!]
][
	h: face-handle? face
	assert h <> null
	h
]

get-face-values: func [
	face	[red-object!]
	return: [red-value!]
	/local
		ctx [red-context!]
		s	[series!]
][
	ctx: GET_CTX(face)
	s: as series! ctx/values/value
	s/offset
]

get-face-type: func [
	face	[red-object!]
	return: [integer!]
	/local
		word [red-word!]
][
	word: as red-word! get-face-values face + FACE_OBJ_TYPE
	symbol/resolve word/symbol
]

copy-face-to-widget: func [
	widget	[sdl-widget!]
	face	[red-object!]
][
	copy-cell as red-value! face as red-value! :widget/face
]

get-face-widget: func [
	face	[red-object!]
	return: [sdl-widget!]
][
	as sdl-widget! face-handle? face
]

set-color: func [
	renderer [handle!]
	color	 [integer!]
][
	SDL_SetRenderDrawColor
		renderer
		as byte! (color and FFh)
		as byte! ((color >>> 8) and FFh)
		as byte! ((color >>> 16) and FFh)
		as byte! either color and FF000000h = 0 [255][(color >>> 24) and FFh]
]

rect-fill: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	w		 [integer!]
	h		 [integer!]
	color	 [integer!]
	/local
		r [SDL_FRect!]
][
	if any [w <= 0 h <= 0][exit]
	r: declare SDL_FRect!
	r/x: as float32! x
	r/y: as float32! y
	r/w: as float32! w
	r/h: as float32! h
	set-color renderer color
	SDL_RenderFillRect renderer r
]

sdl-line: func [
	renderer [handle!]
	x1		 [integer!]
	y1		 [integer!]
	x2		 [integer!]
	y2		 [integer!]
	color	 [integer!]
][
	set-color renderer color
	SDL_RenderLine renderer as float32! x1 as float32! y1 as float32! x2 as float32! y2
]

rect-border: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	w		 [integer!]
	h		 [integer!]
	color	 [integer!]
][
	sdl-line renderer x y x + w - 1 y color
	sdl-line renderer x y x y + h - 1 color
	sdl-line renderer x + w - 1 y x + w - 1 y + h - 1 color
	sdl-line renderer x y + h - 1 x + w - 1 y + h - 1 color
]

get-color-facet: func [
	values	[red-value!]
	default [integer!]
	return: [integer!]
	/local
		tp [red-tuple!]
][
	tp: as red-tuple! values + FACE_OBJ_COLOR
	either TYPE_OF(tp) = TYPE_TUPLE [
		get-tuple-color tp
	][
		default
	]
]

get-text-facet: func [
	values	[red-value!]
	return: [red-string!]
	/local
		txt [red-string!]
][
	txt: as red-string! values + FACE_OBJ_TEXT
	either TYPE_OF(txt) = TYPE_STRING [txt][null]
]

get-image-facet: func [
	values	[red-value!]
	return: [red-image!]
	/local
		img [red-image!]
][
	img: as red-image! values + FACE_OBJ_IMAGE
	either TYPE_OF(img) = TYPE_IMAGE [img][null]
]

render-image: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	w		 [integer!]
	h		 [integer!]
	img		 [red-image!]
	/local
		iw		[integer!]
		ih		[integer!]
		bitmap	[integer!]
		stride	[integer!]
		pixels	[int-ptr!]
		texture [handle!]
		dst		[SDL_FRect!]
][
	if any [img = null TYPE_OF(img) <> TYPE_IMAGE w <= 0 h <= 0][exit]
	iw: IMAGE_WIDTH(img/size)
	ih: IMAGE_HEIGHT(img/size)
	if any [iw <= 0 ih <= 0][exit]

	bitmap: OS-image/lock-bitmap img no
	if bitmap = 0 [exit]
	stride: 0
	pixels: OS-image/get-data bitmap :stride
	if pixels = null [
		OS-image/unlock-bitmap img bitmap
		exit
	]

	texture: SDL_CreateTexture renderer SDL_PIXELFORMAT_ARGB8888 SDL_TEXTUREACCESS_STATIC iw ih
	either texture = null [
		OS-image/unlock-bitmap img bitmap
	][
		SDL_SetTextureBlendMode texture SDL_BLENDMODE_BLEND
		if SDL_UpdateTexture texture null pixels stride [
			dst: declare SDL_FRect!
			dst/x: as float32! x
			dst/y: as float32! y
			dst/w: as float32! w
			dst/h: as float32! h
			SDL_RenderTexture renderer texture null as int-ptr! dst
		]
		SDL_DestroyTexture texture
		OS-image/unlock-bitmap img bitmap
	]
]

mark-window-dirty: func [
	widget [sdl-widget!]
][
	while [all [widget <> null widget/parent <> null]][widget: widget/parent]
	if widget <> null [widget/dirty?: yes]
]

set-pressed-widget: func [
	widget [sdl-widget!]
][
	if pressed-widget = widget [exit]
	if pressed-widget <> null [mark-window-dirty pressed-widget]
	pressed-widget: widget
	if pressed-widget <> null [mark-window-dirty pressed-widget]
]

update-widget-geometry: func [
	widget	[sdl-widget!]
	face	[red-object!]
	/local
		values [red-value!]
		offset [red-value!]
		size   [red-value!]
		pair   [red-pair!]
		pt	   [red-point2D!]
][
	values: get-face-values face
	offset: values + FACE_OBJ_OFFSET
	size: values + FACE_OBJ_SIZE

	either TYPE_OF(offset) = TYPE_PAIR [
		pair: as red-pair! offset
		widget/x: pair/x
		widget/y: pair/y
	][
		pt: as red-point2D! offset
		if TYPE_OF(pt) = TYPE_POINT2D [
			widget/x: as-integer pt/x
			widget/y: as-integer pt/y
		]
	]

	either TYPE_OF(size) = TYPE_PAIR [
		pair: as red-pair! size
		widget/w: pair/x
		widget/h: pair/y
	][
		pt: as red-point2D! size
		if TYPE_OF(pt) = TYPE_POINT2D [
			widget/w: as-integer pt/x
			widget/h: as-integer pt/y
		]
	]
]

update-widget-flags: func [
	widget	[sdl-widget!]
	face	[red-object!]
	/local
		values [red-value!]
		show?  [red-logic!]
		enable? [red-logic!]
		bits   [integer!]
		type   [integer!]
][
	values: get-face-values face
	type: get-face-type face
	widget/flags: 0
	show?: as red-logic! values + FACE_OBJ_VISIBLE?
	enable?: as red-logic! values + FACE_OBJ_ENABLED?
	if all [TYPE_OF(show?) = TYPE_LOGIC not show?/value][widget/flags: widget/flags or WIDGET_FLAG_HIDDEN]
	if all [TYPE_OF(enable?) = TYPE_LOGIC not enable?/value][widget/flags: widget/flags or WIDGET_FLAG_DISABLE]
	bits: get-flags as red-block! values + FACE_OBJ_FLAGS
	if bits and FACET_FLAGS_FOCUSABLE <> 0 [widget/flags: widget/flags or WIDGET_FLAG_FOCUSABLE]
	if any [type = field type = area type = text-list type = rich-text][widget/flags: widget/flags or WIDGET_FLAG_FOCUSABLE]
	if bits and FACET_FLAGS_FULLSCREEN <> 0 [widget/flags: widget/flags or WIDGET_FLAG_FULLSCREEN]
]

render-face: func [
	renderer [handle!]
	face	 [red-object!]
	ox		 [integer!]
	oy		 [integer!]
	/local
		widget [sdl-widget!]
		values [red-value!]
		pane   [red-block!]
		child  [red-object!]
		tail   [red-object!]
		type   [integer!]
		x y w h color data-int row tx ty child-x child-y [integer!]
		txt    [red-string!]
		img	   [red-image!]
		datum  [red-value!]
		logic  [red-logic!]
		percent [red-float!]
		scale  [float!]
		blk	   [red-block!]
		cmds   [red-block!]
		root   [sdl-widget!]
		dc	   [draw-ctx! value]
		series [series!]
		selected [red-integer!]
][
	widget: get-face-widget face
	if any [widget = null widget/flags and WIDGET_FLAG_HIDDEN <> 0][exit]

	values: get-face-values face
	type: get-face-type face
	x: ox + widget/x
	y: oy + widget/y
	w: widget/w
	h: widget/h
	color: get-color-facet values 00F0F0F0h

	case [
		type = window [
			rect-fill renderer 0 0 w h color
		]
		any [type = base type = panel][
			rect-fill renderer x y w h color
			img: get-image-facet values
			if img <> null [render-image renderer x y w h img]
			rect-border renderer x y w h 00808080h
			cmds: as red-block! values + FACE_OBJ_DRAW
			unless any [TYPE_OF(cmds) <> TYPE_BLOCK zero? block/rs-length? cmds][
				draw-begin :dc renderer null no yes
				dc/x: x
				dc/y: y
				dc/left: x
				dc/top: y
				dc/right: x + w
				dc/bottom: y + h
				draw-set-clip-rect :dc 0 0 w h
				parse-draw :dc cmds yes
				draw-end :dc renderer no no yes
				draw-clear-clip :dc
			]
		]
		any [type = button type = toggle][
			data-int: either widget = pressed-widget [1][0]
			either data-int = 1 [
				rect-fill renderer x y w h 00C8C8C8h
				rect-border renderer x y w h 00383838h
				sdl-line renderer x + 1 y + 1 x + w - 2 y + 1 00606060h
				sdl-line renderer x + 1 y + 1 x + 1 y + h - 2 00606060h
				sdl-line renderer x + 2 y + h - 2 x + w - 2 y + h - 2 00F8F8F8h
				sdl-line renderer x + w - 2 y + 2 x + w - 2 y + h - 2 00F8F8F8h
			][
				rect-fill renderer x y w h 00F0F0F0h
				rect-border renderer x y w h 00686868h
				sdl-line renderer x + 1 y + 1 x + w - 3 y + 1 00FFFFFFh
				sdl-line renderer x + 1 y + 1 x + 1 y + h - 3 00FFFFFFh
				sdl-line renderer x + 1 y + h - 2 x + w - 2 y + h - 2 00A0A0A0h
				sdl-line renderer x + w - 2 y + 1 x + w - 2 y + h - 2 00A0A0A0h
			]
			txt: get-text-facet values
			data-int: 0
			row: 0
			if all [txt <> null get-text-size-px txt as red-object! values + FACE_OBJ_FONT :data-int :row][
				tx: x + ((w - data-int) / 2)
				ty: y + ((h - row) / 2)
				if widget = pressed-widget [tx: tx + 2 ty: ty + 1]
				draw-text renderer
					tx
					ty
					txt
					00000000h
					as red-object! values + FACE_OBJ_FONT
			]
		]
		any [type = check type = radio][
			rect-fill renderer x y 13 13 00FFFFFFh
			rect-border renderer x y 13 13 00606060h
			datum: values + FACE_OBJ_DATA
			if TYPE_OF(datum) = TYPE_LOGIC [
				logic: as red-logic! datum
				if logic/value [rect-fill renderer x + 3 y + 3 7 7 00202020h]
			]
			txt: get-text-facet values
			if txt <> null [draw-text renderer x + 18 y + 3 txt 00000000h as red-object! values + FACE_OBJ_FONT]
		]
		type = text [
			txt: get-text-facet values
			if txt <> null [draw-text renderer x y + 4 txt 00000000h as red-object! values + FACE_OBJ_FONT]
		]
		type = rich-text [
			rect-fill renderer x y w h color
			root: widget
			while [all [root <> null root/parent <> null]][root: root/parent]
			if root <> null [
				dispatch-event as red-object! :root/face face EVT_DRAWING 0 0 0 0 0
			]
			draw-text-box renderer x y face 00000000h no
		]
		any [type = field type = area][
			rect-fill renderer x y w h 00FFFFFFh
			rect-border renderer x y w h 00606060h
			txt: get-text-facet values
			if txt <> null [draw-text renderer x + 4 y + 5 txt 00000000h as red-object! values + FACE_OBJ_FONT]
			if all [widget = focused-widget txt <> null][
				clamp-edit-cursor widget txt
				rect-fill renderer x + 4 + (widget/cursor * 7) y + 4 1 h - 8 00000000h
			]
		]
		type = progress [
			rect-fill renderer x y w h 00D0D0D0h
			datum: values + FACE_OBJ_DATA
			data-int: 0
			if TYPE_OF(datum) = TYPE_PERCENT [
				percent: as red-float! datum
				scale: as float! w
				data-int: as-integer scale * percent/value
			]
			rect-fill renderer x y data-int h 0040A0E0h
			rect-border renderer x y w h 00606060h
		]
		type = slider [
			rect-fill renderer x y + (h / 2) - 2 w 4 00B0B0B0h
			datum: values + FACE_OBJ_DATA
			data-int: 0
			if TYPE_OF(datum) = TYPE_PERCENT [
				percent: as red-float! datum
				scale: as float! w
				scale: scale - 10.0
				data-int: as-integer scale * percent/value
			]
			rect-fill renderer x + data-int y 10 h 006080A0h
		]
		type = text-list [
			rect-fill renderer x y w h 00FFFFFFh
			rect-border renderer x y w h 00606060h
			datum: values + FACE_OBJ_DATA
			selected: as red-integer! values + FACE_OBJ_SELECTED
			if TYPE_OF(datum) = TYPE_BLOCK [
				blk: as red-block! datum
				series: GET_BUFFER(blk)
				child: as red-object! series/offset
				tail: as red-object! series/tail
				data-int: 0
				while [all [child < tail data-int < (h / 14)]][
					if TYPE_OF(child) = TYPE_STRING [
						row: data-int + 1
						either all [TYPE_OF(selected) = TYPE_INTEGER selected/value = row][
							rect-fill renderer x + 1 y + 1 + (data-int * 14) w - 2 14 0070A8E8h
							draw-text renderer x + 4 y + 3 + (data-int * 14) as red-string! child 00FFFFFFh as red-object! values + FACE_OBJ_FONT
						][
							draw-text renderer x + 4 y + 3 + (data-int * 14) as red-string! child 00000000h as red-object! values + FACE_OBJ_FONT
						]
					]
					child: child + 1
					data-int: data-int + 1
				]
			]
		]
		true [
			rect-border renderer x y w h 00A0A0A0h
		]
	]

	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		either type = window [
			child-x: 0
			child-y: 0
		][
			child-x: x
			child-y: y
		]
		child: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [child < tail][
			if TYPE_OF(child) = TYPE_OBJECT [render-face renderer child child-x child-y]
			child: child + 1
		]
	]
]

render-window: func [
	widget [sdl-widget!]
][
	if any [widget = null widget/window = null widget/renderer = null][exit]
	render-face widget/renderer as red-object! :widget/face 0 0
	SDL_RenderPresent widget/renderer
	widget/dirty?: no
]

surface-to-image: func [
	surface [handle!]
	return: [red-image!]
	/local
		src-surf	[SDL_Surface!]
		converted	[handle!]
		work		[handle!]
		work-surf	[SDL_Surface!]
		out			[red-image!]
		bitmap		[integer!]
		dst-stride	[integer!]
		dst-pixels	[byte-ptr!]
		src-pixels	[byte-ptr!]
		row-bytes	[integer!]
		rows		[integer!]
][
	if surface = null [return as red-image! none-value]
	src-surf: as SDL_Surface! surface
	work: surface
	if src-surf/format <> SDL_PIXELFORMAT_ARGB8888 [
		converted: SDL_ConvertSurface surface SDL_PIXELFORMAT_ARGB8888
		if converted = null [
			SDL_DestroySurface surface
			return as red-image! none-value
		]
		work: converted
	]

	work-surf: as SDL_Surface! work
	out: image/init-image as red-image! stack/push* OS-image/make-image work-surf/w work-surf/h null null null
	bitmap: OS-image/lock-bitmap out yes
	either bitmap = 0 [
		out/header: TYPE_NONE
	][
		dst-stride: 0
		dst-pixels: as byte-ptr! OS-image/get-data bitmap :dst-stride
		either dst-pixels = null [
			out/header: TYPE_NONE
		][
			src-pixels: work-surf/pixels
			row-bytes: work-surf/w * 4
			rows: work-surf/h
			loop rows [
				copy-memory dst-pixels src-pixels row-bytes
				src-pixels: src-pixels + work-surf/pitch
				dst-pixels: dst-pixels + dst-stride
			]
		]
		OS-image/unlock-bitmap out bitmap
	]

	if work <> surface [SDL_DestroySurface work]
	SDL_DestroySurface surface
	out
]

editable-widget?: func [
	widget	[sdl-widget!]
	return: [logic!]
	/local
		ftype [integer!]
][
	if widget = null [return no]
	ftype: get-face-type as red-object! :widget/face
	any [ftype = field ftype = area]
]

clamp-edit-cursor: func [
	widget [sdl-widget!]
	text   [red-string!]
	return: [integer!]
	/local
		len [integer!]
][
	len: either TYPE_OF(text) = TYPE_STRING [string/rs-length? text][0]
	if widget/cursor < 0 [widget/cursor: 0]
	if widget/cursor > len [widget/cursor: len]
	len
]

set-edit-cursor-from-x: func [
	widget [sdl-widget!]
	x	   [integer!]
	/local
		values [red-value!]
		text   [red-string!]
		lx	   [integer!]
		len	   [integer!]
][
	if (editable-widget? widget) = no [exit]
	values: get-face-values as red-object! :widget/face
	text: as red-string! values + FACE_OBJ_TEXT
	len: clamp-edit-cursor widget text
	lx: widget-local-x widget x
	widget/cursor: (lx - 4) / 7
	if widget/cursor < 0 [widget/cursor: 0]
	if widget/cursor > len [widget/cursor: len]
	mark-window-dirty widget
]

insert-edit-char: func [
	widget [sdl-widget!]
	text   [red-string!]
	cp	   [integer!]
][
	clamp-edit-cursor widget text
	string/insert-char GET_BUFFER(text) text/head + widget/cursor cp
	widget/cursor: widget/cursor + 1
]

edit-widget-text: func [
	win		[sdl-widget!]
	widget	[sdl-widget!]
	cstr	[c-string!]
	return: [logic!]
	/local
		values [red-value!]
		text   [red-string!]
		p	   [byte-ptr!]
		cp	   [integer!]
		changed? [logic!]
][
	if any [(editable-widget? widget) = no cstr = null][return no]

	values: get-face-values as red-object! :widget/face
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [
		string/rs-make-at as red-value! text 16
	]

	changed?: no
	p: as byte-ptr! cstr
	while [p/1 <> null-byte][
		cp: as-integer p/1
		if all [cp >= 32 cp < 127][
			insert-edit-char widget text cp
			changed?: yes
		]
		p: p + 1
	]

	if changed? [
		mark-window-dirty widget
		dispatch-event as red-object! :win/face as red-object! :widget/face EVT_CHANGE 0 0 0 0 0
	]
	changed?
]

edit-widget-key: func [
	win		[sdl-widget!]
	widget	[sdl-widget!]
	key		[integer!]
	scancode [integer!]
	return: [logic!]
	/local
		values [red-value!]
		text   [red-string!]
		ftype  [integer!]
		len	   [integer!]
		changed? [logic!]
][
	if (editable-widget? widget) = no [return no]

	values: get-face-values as red-object! :widget/face
	text: as red-string! values + FACE_OBJ_TEXT
	if TYPE_OF(text) <> TYPE_STRING [
		string/rs-make-at as red-value! text 16
	]

	ftype: get-face-type as red-object! :widget/face
	len: clamp-edit-cursor widget text
	changed?: no
	case [
		any [key = 8 scancode = 42][
			if widget/cursor > 0 [
				string/remove-char text text/head + widget/cursor - 1
				widget/cursor: widget/cursor - 1
				changed?: yes
			]
		]
		any [key = 127 scancode = 76][
			if widget/cursor < len [
				string/remove-char text text/head + widget/cursor
				changed?: yes
			]
		]
		any [key = 13 scancode = 40][
			if ftype <> area [return no]
			insert-edit-char widget text as-integer lf
			changed?: yes
		]
		scancode = 80 [
			if widget/cursor > 0 [widget/cursor: widget/cursor - 1]
		]
		scancode = 79 [
			if widget/cursor < len [widget/cursor: widget/cursor + 1]
		]
		scancode = 74 [
			widget/cursor: 0
		]
		scancode = 77 [
			widget/cursor: len
		]
		true [return no]
	]

	mark-window-dirty widget
	if changed? [dispatch-event as red-object! :win/face as red-object! :widget/face EVT_CHANGE 0 0 0 key 0]
	yes
]

window-widget?: func [
	widget [sdl-widget!]
	return: [logic!]
][
	all [widget <> null widget/parent = null]
]

find-window-by-id: func [
	id		[integer!]
	return: [sdl-widget!]
	/local
		win [sdl-widget!]
][
	win: last-window
	either all [win <> null win/window-id = id][win][null]
]

hit-test: func [
	face	[red-object!]
	px		[integer!]
	py		[integer!]
	ox		[integer!]
	oy		[integer!]
	return: [sdl-widget!]
	/local
		widget [sdl-widget!]
		values [red-value!]
		pane   [red-block!]
		child  [red-object!]
		tail   [red-object!]
		hit	   [sdl-widget!]
		x y	right bottom [integer!]
][
	widget: get-face-widget face
	if any [widget = null widget/flags and WIDGET_FLAG_HIDDEN <> 0 widget/flags and WIDGET_FLAG_DISABLE <> 0][return null]
	either widget/parent = null [
		x: 0
		y: 0
	][
		x: ox + widget/x
		y: oy + widget/y
	]
	right: x + widget/w
	bottom: y + widget/h
	if any [px < x py < y px >= right py >= bottom][return null]

	values: get-face-values face
	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		child: as red-object! block/rs-tail pane
		tail: as red-object! block/rs-head pane
		while [child > tail][
			child: child - 1
			if TYPE_OF(child) = TYPE_OBJECT [
				hit: hit-test child px py x y
				if hit <> null [return hit]
			]
		]
	]
	widget
]

widget-local-x: func [
	widget [sdl-widget!]
	x	   [integer!]
	return: [integer!]
][
	while [widget <> null][
		x: x - widget/x
		widget: widget/parent
	]
	x
]

widget-local-y: func [
	widget [sdl-widget!]
	y	   [integer!]
	return: [integer!]
][
	while [widget <> null][
		y: y - widget/y
		widget: widget/parent
	]
	y
]

text-list-length?: func [
	widget [sdl-widget!]
	return: [integer!]
	/local
		values [red-value!]
		data   [red-block!]
][
	if widget = null [return 0]
	values: get-face-values as red-object! :widget/face
	data: as red-block! values + FACE_OBJ_DATA
	either TYPE_OF(data) = TYPE_BLOCK [block/rs-length? data][0]
]

select-text-list: func [
	win	   [sdl-widget!]
	widget [sdl-widget!]
	idx	   [integer!]
	return: [logic!]
	/local
		values [red-value!]
		selected [red-integer!]
		len cur ret ftype [integer!]
][
	if widget = null [return no]
	ftype: get-face-type as red-object! :widget/face
	if ftype <> text-list [return no]
	len: text-list-length? widget
	if len <= 0 [return no]
	if idx < 1 [idx: 1]
	if idx > len [idx: len]

	values: get-face-values as red-object! :widget/face
	selected: as red-integer! values + FACE_OBJ_SELECTED
	if TYPE_OF(selected) <> TYPE_INTEGER [
		selected/header: TYPE_INTEGER
		selected/value: 0
	]
	cur: selected/value
	if cur = idx [return no]

	ret: dispatch-event as red-object! :win/face as red-object! :widget/face EVT_SELECT 0 0 0 0 idx
	values: get-face-values as red-object! :widget/face
	selected: as red-integer! values + FACE_OBJ_SELECTED
	if TYPE_OF(selected) <> TYPE_INTEGER [return no]
	if cur <> selected/value [return no]

	selected/value: idx
	mark-window-dirty widget
	if ret = EVT_DISPATCH [
		dispatch-event as red-object! :win/face as red-object! :widget/face EVT_CHANGE 0 0 0 0 idx
	]
	yes
]

text-list-key: func [
	win		 [sdl-widget!]
	widget	 [sdl-widget!]
	scancode [integer!]
	return: [logic!]
	/local
		values [red-value!]
		selected [red-integer!]
		idx ftype [integer!]
][
	if widget = null [return no]
	ftype: get-face-type as red-object! :widget/face
	if ftype <> text-list [return no]
	values: get-face-values as red-object! :widget/face
	selected: as red-integer! values + FACE_OBJ_SELECTED
	idx: either TYPE_OF(selected) = TYPE_INTEGER [selected/value][1]
	switch scancode [
		82 [select-text-list win widget idx - 1]		;-- up
		81 [select-text-list win widget idx + 1]		;-- down
		default [return no]
	]
	yes
]

set-focused-widget: func [
	win	   [sdl-widget!]
	widget [sdl-widget!]
][
	if focused-widget = widget [exit]
	if focused-widget <> null [
		dispatch-event as red-object! :win/face as red-object! :focused-widget/face EVT_UNFOCUS 0 0 0 0 0
		mark-window-dirty focused-widget
	]
	focused-widget: widget
	if focused-widget <> null [
		dispatch-event as red-object! :win/face as red-object! :focused-widget/face EVT_FOCUS 0 0 0 0 0
		mark-window-dirty focused-widget
	]
]

focus-selected-widget: func [
	win		[sdl-widget!]
	face	[red-object!]
	/local
		values	 [red-value!]
		selected [red-value!]
		target	 [sdl-widget!]
][
	if win = null [exit]
	values: get-face-values face
	selected: values + FACE_OBJ_SELECTED
	if TYPE_OF(selected) = TYPE_OBJECT [
		target: get-face-widget as red-object! selected
		if target <> null [set-focused-widget win target]
	]
]

activate-widget: func [
	win	   [sdl-widget!]
	widget [sdl-widget!]
	x	   [integer!]
	y	   [integer!]
	/local
		values [red-value!]
		data   [red-value!]
		logic  [red-logic!]
		pos	   [red-float!]
		ftype  [integer!]
		lx	   [integer!]
		ly	   [integer!]
		span   [integer!]
		f	   [float!]
][
	if widget = null [exit]
	ftype: get-face-type as red-object! :widget/face
	values: get-face-values as red-object! :widget/face
	data: values + FACE_OBJ_DATA
	case [
		any [ftype = check ftype = toggle ftype = radio][
			logic: as red-logic! data
			if TYPE_OF(logic) <> TYPE_LOGIC [
				logic/header: TYPE_LOGIC
				logic/value: no
			]
			either ftype = radio [
				logic/value: yes
			][
				logic/value: not logic/value
			]
			mark-window-dirty widget
			dispatch-event as red-object! :win/face as red-object! :widget/face EVT_CHANGE 0 0 0 0 0
		]
		ftype = slider [
			pos: as red-float! data
			if TYPE_OF(pos) <> TYPE_PERCENT [
				pos/header: TYPE_PERCENT
				pos/value: 0.0
			]
			lx: widget-local-x widget x
			span: widget/w - 10
			if span < 1 [span: 1]
			if lx < 0 [lx: 0]
			if lx > span [lx: span]
			f: as float! lx
			pos/value: f / as float! span
			mark-window-dirty widget
			dispatch-event as red-object! :win/face as red-object! :widget/face EVT_CHANGE 0 0 0 0 0
		]
		ftype = text-list [
			ly: widget-local-y widget y
			select-text-list win widget (ly / 14) + 1
		]
		true [0]
	]
]

free-face-tree: func [
	face	[red-object!]
	/local
		widget [sdl-widget!]
		values [red-value!]
		pane   [red-block!]
		child  [red-object!]
		tail   [red-object!]
		state  [red-value!]
][
	widget: get-face-widget face
	if widget = null [exit]

	values: get-face-values face
	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		child: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [child < tail][
			if TYPE_OF(child) = TYPE_OBJECT [free-face-tree child]
			child: child + 1
		]
	]

	if widget = focused-widget [focused-widget: null]
	if widget = hover-widget [hover-widget: null]
	if widget = pressed-widget [pressed-widget: null]
	if widget = last-window [last-window: null]
	if widget/parent = null [
		if widget/window <> null [SDL_StopTextInput widget/window]
		if widget/renderer <> null [SDL_DestroyRenderer widget/renderer]
		if widget/window <> null [SDL_DestroyWindow widget/window]
	]
	free as byte-ptr! widget
	state: values + FACE_OBJ_STATE
	state/header: TYPE_NONE
]

support-dark-mode?: func [return: [logic!]][false]
set-dark-mode: func [hWnd [handle!] dark? [logic!] top-level? [logic!]][]

on-gc-mark: does [
	collector/keep :flags-blk/node
]

init: func [
	/local
		ver [red-tuple!]
		int [red-integer!]
][
	if initialized? [exit]
	initialized?: yes
	SDL_Init SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER
	init-fonts

	ver: as red-tuple! #get system/view/platform/version
	ver/header: TYPE_TUPLE or (3 << 19)
	ver/array1: 00030000h

	int: as red-integer! #get system/view/platform/build
	int/header: TYPE_INTEGER
	int/value: 1

	int: as red-integer! #get system/view/platform/product
	int/header: TYPE_INTEGER
	int/value: 0

	collector/register as int-ptr! :on-gc-mark
]

clean-up: does [
	shutdown-fonts
	SDL_Quit
]

get-screen-size: func [
	id		[integer!]
	return: [red-pair!]
	/local
		rect [SDL_Rect!]
		display [integer!]
][
	rect: declare SDL_Rect!
	display: SDL_GetPrimaryDisplay
	either all [display <> 0 SDL_GetDisplayBounds display rect][
		pair/push rect/w rect/h
	][
		pair/push 800 600
	]
]

get-text-size: func [
	face 	[red-object!]
	text	[red-string!]
	p		[red-point2D!]
][
	get-bitmap-text-size text p as red-object! (get-face-values face) + FACE_OBJ_FONT
]

make-font: func [face [red-object!] font [red-object!] return: [handle!]][as handle! 1]
get-font-handle: func [font [red-object!] idx [integer!] return: [handle!]][as handle! 1]
update-para: func [para [red-object!] flags [integer!]][]
update-font: func [font [red-object!] flags [integer!]][]
OS-request-font: func [font [red-object!] selected [red-object!] mono? [logic!]][]
OS-request-file: func [title [red-string!] name [red-file!] filter [red-block!] save? [logic!] multi? [logic!] return: [red-value!]][as red-value! none-value]
OS-request-dir: func [title [red-string!] dir [red-file!] filter [red-block!] keep? [logic!] multi? [logic!] return: [red-value!]][as red-value! none-value]
update-scroller: func [scroller [red-object!] flags [integer!]][]

get-text-alt: func [
	face [red-object!]
	idx	 [integer!]
][
	exit
]

OS-get-current-screen: func [
	return: [red-handle!]
][
	handle/make-at stack/arguments as-integer screen-handle handle/CLASS_MONITOR
]

OS-fetch-all-screens: func [
	return: [red-block!]
	/local
		out [red-block!]
		spec [red-block!]
		s	 [series!]
		size [red-pair!]
][
	out: block/push-only* 2
	spec: block/make-at as red-block! ALLOC_TAIL(out) 4
	s: GET_BUFFER(spec)
	size: get-screen-size 0
	pair/make-at alloc-tail s 0 0
	pair/make-at alloc-tail s size/x size/y
	float/make-at alloc-tail s 1.0
	handle/make-at alloc-tail s as-integer screen-handle handle/CLASS_MONITOR
	out
]

OS-redraw: func [hWnd [integer!]][
	mark-window-dirty as sdl-widget! hWnd
]

OS-refresh-window: func [hWnd [integer!]][
	render-window as sdl-widget! hWnd
]

OS-show-window: func [
	hWnd [integer!]
	/local
		widget [sdl-widget!]
][
	widget: as sdl-widget! hWnd
	if all [widget <> null widget/window <> null][
		SDL_ShowWindow widget/window
		focus-selected-widget widget as red-object! :widget/face
		render-window widget
	]
]

change-rate: func [
	widget [sdl-widget!]
	rate   [red-value!]
	/local
		int [red-integer!]
		tm	[red-time!]
		ms	[integer!]
][
	if widget = null [exit]
	ms: 0
	switch TYPE_OF(rate) [
		TYPE_INTEGER [
			int: as red-integer! rate
			if int/value <= 0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			ms: 1000 / int/value
			if ms < 1 [ms: 1]
		]
		TYPE_TIME [
			tm: as red-time! rate
			if tm/time <= 0.0 [fire [TO_ERROR(script invalid-facet-type) rate]]
			ms: as-integer tm/time * 1000.0
			if ms < 1 [ms: 1]
		]
		TYPE_NONE [ms: 0]
		default [fire [TO_ERROR(script invalid-facet-type) rate]]
	]
	widget/timer-ms: ms
	widget/timer-next: either ms > 0 [SDL_GetTicks + ms][0]
]

OS-make-view: func [
	face	[red-object!]
	parent	[integer!]
	return: [integer!]
	/local
		widget [sdl-widget!]
		values [red-value!]
		type   [integer!]
		title  [red-string!]
		ctitle [c-string!]
		flags  [integer!]
		len	   [integer!]
		par	   [sdl-widget!]
		rate   [red-value!]
][
	widget: as sdl-widget! zero-alloc size? sdl-widget!
	copy-face-to-widget widget face
	update-widget-geometry widget face
	update-widget-flags widget face

	type: get-face-type face
	if any [type = field type = area][
		values: get-face-values face
		title: get-text-facet values
		widget/cursor: either title = null [0][string/rs-length? title]
	]
	either parent = 0 [par: null][par: as sdl-widget! parent]
	widget/parent: par

	either type = window [
		values: get-face-values face
		title: get-text-facet values
		flags: SDL_WINDOW_RESIZABLE
		if widget/flags and WIDGET_FLAG_HIDDEN <> 0 [flags: flags or SDL_WINDOW_HIDDEN]
		quit?: no
		SDL_FlushEvent SDL_EVENT_QUIT
		either title = null [
			ctitle: "Red SDL3"
		][
			len: -1
			ctitle: unicode/to-utf8 title :len
		]
		widget/window: SDL_CreateWindow ctitle widget/w widget/h flags 0
		widget/renderer: SDL_CreateRenderer widget/window null
		widget/window-id: SDL_GetWindowID widget/window
		widget/dirty?: yes
		last-window: widget
		SDL_StartTextInput widget/window
	][
		if par <> null [
			widget/window: par/window
			widget/renderer: par/renderer
			widget/window-id: par/window-id
		]
	]

	values: get-face-values face
	rate: values + FACE_OBJ_RATE
	change-rate widget rate

	as-integer widget
]

OS-update-view: func [
	face [red-object!]
	/local
		widget [sdl-widget!]
		values [red-value!]
		state  [red-block!]
		int	   [red-integer!]
		flags  [integer!]
		type   [integer!]
		title  [red-string!]
		ctitle [c-string!]
		len	   [integer!]
][
	widget: get-face-widget face
	if widget = null [exit]
	values: get-face-values face
	update-widget-geometry widget face
	update-widget-flags widget face
	type: get-face-type face
	if type = window [
		title: get-text-facet values
		if title <> null [
			len: -1
			ctitle: unicode/to-utf8 title :len
			SDL_SetWindowTitle widget/window ctitle
		]
		SDL_SetWindowPosition widget/window widget/x widget/y
		SDL_SetWindowSize widget/window widget/w widget/h
		SDL_SetWindowFullscreen widget/window widget/flags and WIDGET_FLAG_FULLSCREEN <> 0
		focus-selected-widget widget face
	]
	change-rate widget values + FACE_OBJ_RATE
	mark-window-dirty widget
	state: as red-block! values + FACE_OBJ_STATE
	if TYPE_OF(state) = TYPE_BLOCK [
		int: as red-integer! block/rs-head state
		int: int + 1
		int/value: 0
	]
]

OS-destroy-view: func [
	face   [red-object!]
	empty? [logic!]
][
	free-face-tree face
]

OS-update-facet: func [
	face   [red-object!]
	facet  [red-word!]
	value  [red-value!]
	action [red-word!]
	new	   [red-value!]
	index  [integer!]
	part   [integer!]
][
	OS-update-view face
]

OS-to-image: func [
	face	[red-object!]
	return: [red-image!]
	/local
		widget [sdl-widget!]
		surf   [handle!]
][
	widget: get-face-widget face
	if any [widget = null widget/renderer = null][return as red-image! none-value]
	while [all [widget/parent <> null]][widget: widget/parent]
	if any [widget = null widget/renderer = null][return as red-image! none-value]
	render-face widget/renderer as red-object! :widget/face 0 0
	surf: SDL_RenderReadPixels widget/renderer null
	SDL_RenderPresent widget/renderer
	widget/dirty?: no
	surface-to-image surf
]

OS-do-draw: func [
	img		[red-image!]
	cmds	[red-block!]
][
	do-draw null img cmds no no no no
]

OS-draw-face: func [
	hWnd	[handle!]
	cmds	[red-block!]
	flags	[integer!]
	/local
		widget [sdl-widget!]
		parent [sdl-widget!]
		dc	   [draw-ctx! value]
		x y	   [integer!]
][
	widget: as sdl-widget! hWnd
	if any [widget = null widget/renderer = null TYPE_OF(cmds) <> TYPE_BLOCK][exit]
	x: widget/x
	y: widget/y
	parent: widget/parent
	while [parent <> null][
		if parent/parent <> null [
			x: x + parent/x
			y: y + parent/y
		]
		parent: parent/parent
	]
	draw-begin :dc widget/renderer null no yes
	dc/x: x
	dc/y: y
	dc/left: x
	dc/top: y
	dc/right: x + widget/w
	dc/bottom: y + widget/h
	draw-set-clip-rect :dc 0 0 widget/w widget/h
	parse-draw :dc cmds yes
	draw-end :dc widget/renderer no no yes
	draw-clear-clip :dc
]

OS-alert: func [
	caption [c-string!]
	msg		[c-string!]
][
	SDL_ShowSimpleMessageBox 0 caption msg null
]

post-quit-msg: func [
	/local
	ev [sdl-event!]
][
	exit-loop?: yes
	ev: declare sdl-event!
	ev/data: SDL_EVENT_USER
	SDL_PushEvent ev
]

test-push-event: func [
	win-face [red-object!]
	type	 [integer!]
	x		 [integer!]
	y		 [integer!]
	key		 [integer!]
	extra	 [integer!]
	/local
		win	   [sdl-widget!]
		target [sdl-widget!]
		values [red-value!]
		facet  [red-value!]
		pair   [red-pair!]
		pt	   [red-point2D!]
		rtype  [integer!]
][
	win: get-face-widget win-face
	if win = null [exit]
	case [
		type = SDL_EVENT_WINDOW_RESIZED [
			win/w: x
			win/h: y
			values: get-face-values as red-object! :win/face
			facet: values + FACE_OBJ_SIZE
			either TYPE_OF(facet) = TYPE_PAIR [
				pair: as red-pair! facet
				pair/x: x
				pair/y: y
			][
				pt: as red-point2D! facet
				pt/x: as float32! x
				pt/y: as float32! y
			]
			dispatch-event as red-object! :win/face as red-object! :win/face EVT_SIZE 0 x y 0 0
			win/dirty?: yes
		]
		type = SDL_EVENT_MOUSE_MOTION [
			target: hit-test as red-object! :win/face x y 0 0
			if target <> hover-widget [
				if hover-widget <> null [
					dispatch-event as red-object! :win/face as red-object! :hover-widget/face EVT_OVER EVT_FLAG_AWAY x y 0 0
				]
				hover-widget: target
			]
			if hover-widget <> null [
				dispatch-event as red-object! :win/face as red-object! :hover-widget/face EVT_OVER 0 x y 0 0
			]
		]
		any [type = SDL_EVENT_MOUSE_BUTTON_DOWN type = SDL_EVENT_MOUSE_BUTTON_UP][
			target: hit-test as red-object! :win/face x y 0 0
			if target <> null [
				rtype: switch extra [
					SDL_BUTTON_LEFT [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_LEFT_DOWN][EVT_LEFT_UP]]
					SDL_BUTTON_MIDDLE [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_MIDDLE_DOWN][EVT_MIDDLE_UP]]
					SDL_BUTTON_RIGHT [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_RIGHT_DOWN][EVT_RIGHT_UP]]
					default [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_AUX_DOWN][EVT_AUX_UP]]
				]
				if extra = SDL_BUTTON_LEFT [
					either type = SDL_EVENT_MOUSE_BUTTON_DOWN [
						set-pressed-widget target
						render-window win
					][
						set-pressed-widget null
					]
				]
				dispatch-event as red-object! :win/face as red-object! :target/face rtype either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_FLAG_DOWN][0] x y 0 0
				if all [type = SDL_EVENT_MOUSE_BUTTON_UP extra = SDL_BUTTON_LEFT][
					dispatch-event as red-object! :win/face as red-object! :target/face EVT_CLICK 0 x y 0 0
					if last-window = null [exit]
					activate-widget win target x y
					if last-window = null [exit]
					if target/flags and WIDGET_FLAG_FOCUSABLE <> 0 [
						set-focused-widget win target
						set-edit-cursor-from-x target x
					]
				]
			]
		]
		type = SDL_EVENT_MOUSE_WHEEL [
			target: either hover-widget <> null [hover-widget][win]
			dispatch-event as red-object! :win/face as red-object! :target/face EVT_WHEEL 0 x y 0 extra
		]
		any [type = SDL_EVENT_KEY_DOWN type = SDL_EVENT_KEY_UP][
			target: either focused-widget <> null [focused-widget][win]
			dispatch-event as red-object! :win/face as red-object! :target/face either type = SDL_EVENT_KEY_DOWN [EVT_KEY_DOWN][EVT_KEY_UP] 0 0 0 key 0
			if type = SDL_EVENT_KEY_DOWN [
				dispatch-event as red-object! :win/face as red-object! :target/face EVT_KEY 0 0 0 key 0
				if (edit-widget-key win target key extra) = no [
					text-list-key win target extra
				]
			]
		]
		type = SDL_EVENT_WINDOW_CLOSE_REQUESTED [
			rtype: dispatch-event as red-object! :win/face as red-object! :win/face EVT_CLOSE 0 0 0 0 0
			if rtype = EVT_NO_DISPATCH [quit?: yes]
		]
		true [0]
	]
]

handle-sdl-event: func [
	ev		[sdl-event!]
	return: [logic!]
	/local
		type	[integer!]
		win		[sdl-widget!]
		target	[sdl-widget!]
		wev		[SDL_WindowEvent!]
		mev		[SDL_MouseMotionEvent!]
		bev		[SDL_MouseButtonEvent!]
		whev	[SDL_MouseWheelEvent!]
		keyev	[SDL_KeyboardEvent!]
		tev		[SDL_TextInputEvent!]
		values	[red-value!]
		facet	[red-value!]
		pair	[red-pair!]
		pt		[red-point2D!]
		x y flags rtype key button [integer!]
][
	type: ev/data
	if type = SDL_EVENT_QUIT [quit?: yes return no]

	case [
		any [
			type = SDL_EVENT_WINDOW_CLOSE_REQUESTED
			type = SDL_EVENT_WINDOW_RESIZED
			type = SDL_EVENT_WINDOW_MOVED
			type = SDL_EVENT_WINDOW_EXPOSED
			type = SDL_EVENT_WINDOW_FOCUS_GAINED
			type = SDL_EVENT_WINDOW_FOCUS_LOST
		][
			wev: as SDL_WindowEvent! ev
			win: find-window-by-id wev/windowID
			if win = null [return yes]
			if type = SDL_EVENT_WINDOW_RESIZED [
				win/w: wev/data1
				win/h: wev/data2
				values: get-face-values as red-object! :win/face
				facet: values + FACE_OBJ_SIZE
				either TYPE_OF(facet) = TYPE_PAIR [
					pair: as red-pair! facet
					pair/x: wev/data1
					pair/y: wev/data2
				][
					pt: as red-point2D! facet
					pt/x: as float32! wev/data1
					pt/y: as float32! wev/data2
				]
			]
			if type = SDL_EVENT_WINDOW_MOVED [
				win/x: wev/data1
				win/y: wev/data2
				values: get-face-values as red-object! :win/face
				facet: values + FACE_OBJ_OFFSET
				either TYPE_OF(facet) = TYPE_PAIR [
					pair: as red-pair! facet
					pair/x: wev/data1
					pair/y: wev/data2
				][
					pt: as red-point2D! facet
					pt/x: as float32! wev/data1
					pt/y: as float32! wev/data2
				]
			]
			rtype: switch type [
				SDL_EVENT_WINDOW_CLOSE_REQUESTED [EVT_CLOSE]
				SDL_EVENT_WINDOW_RESIZED [EVT_SIZE]
				SDL_EVENT_WINDOW_MOVED [EVT_MOVE]
				SDL_EVENT_WINDOW_EXPOSED [EVT_DRAWING]
				SDL_EVENT_WINDOW_FOCUS_GAINED [EVT_FOCUS]
				SDL_EVENT_WINDOW_FOCUS_LOST [EVT_UNFOCUS]
				default [EVT_DRAWING]
			]
			rtype: dispatch-event as red-object! :win/face as red-object! :win/face rtype 0 wev/data1 wev/data2 0 0
			if all [type = SDL_EVENT_WINDOW_CLOSE_REQUESTED rtype = EVT_NO_DISPATCH][
				quit?: yes
				return no
			]
			if last-window = null [return no]
			if type = SDL_EVENT_WINDOW_FOCUS_LOST [
				set-focused-widget win null
			]
			win/dirty?: yes
		]
		type = SDL_EVENT_WINDOW_MOUSE_LEAVE [
			wev: as SDL_WindowEvent! ev
			win: find-window-by-id wev/windowID
			if win = null [return yes]
			if hover-widget <> null [
				dispatch-event as red-object! :win/face as red-object! :hover-widget/face EVT_OVER EVT_FLAG_AWAY 0 0 0 0
				hover-widget: null
			]
		]
		type = SDL_EVENT_MOUSE_MOTION [
			mev: as SDL_MouseMotionEvent! ev
			win: find-window-by-id mev/windowID
			if win = null [return yes]
			x: as-integer mev/x
			y: as-integer mev/y
			target: hit-test as red-object! :win/face x y 0 0
			if target <> hover-widget [
				if hover-widget <> null [
					dispatch-event as red-object! :win/face as red-object! :hover-widget/face EVT_OVER EVT_FLAG_AWAY x y 0 0
				]
				hover-widget: target
			]
			if hover-widget <> null [
				dispatch-event as red-object! :win/face as red-object! :hover-widget/face EVT_OVER 0 x y 0 0
			]
		]
		any [type = SDL_EVENT_MOUSE_BUTTON_DOWN type = SDL_EVENT_MOUSE_BUTTON_UP][
			bev: as SDL_MouseButtonEvent! ev
			win: find-window-by-id bev/windowID
			if win = null [return yes]
			x: as-integer bev/x
			y: as-integer bev/y
			target: hit-test as red-object! :win/face x y 0 0
			if target <> null [
				flags: either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_FLAG_DOWN][0]
				button: as-integer bev/button
				rtype: switch button [
					SDL_BUTTON_LEFT [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_LEFT_DOWN][EVT_LEFT_UP]]
					SDL_BUTTON_MIDDLE [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_MIDDLE_DOWN][EVT_MIDDLE_UP]]
					SDL_BUTTON_RIGHT [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_RIGHT_DOWN][EVT_RIGHT_UP]]
					default [either type = SDL_EVENT_MOUSE_BUTTON_DOWN [EVT_AUX_DOWN][EVT_AUX_UP]]
				]
				if button = SDL_BUTTON_LEFT [
					either type = SDL_EVENT_MOUSE_BUTTON_DOWN [
						set-pressed-widget target
						render-window win
					][
						set-pressed-widget null
					]
				]
				dispatch-event as red-object! :win/face as red-object! :target/face rtype flags x y 0 0
				if all [type = SDL_EVENT_MOUSE_BUTTON_UP button = SDL_BUTTON_LEFT][
					dispatch-event as red-object! :win/face as red-object! :target/face EVT_CLICK 0 x y 0 0
					if last-window = null [return no]
					activate-widget win target x y
					if last-window = null [return no]
					if target/flags and WIDGET_FLAG_FOCUSABLE <> 0 [
						set-focused-widget win target
						set-edit-cursor-from-x target x
					]
				]
			]
		]
		type = SDL_EVENT_MOUSE_WHEEL [
			whev: as SDL_MouseWheelEvent! ev
			win: find-window-by-id whev/windowID
			if win <> null [
				target: either hover-widget <> null [hover-widget][win]
				dispatch-event as red-object! :win/face as red-object! :target/face EVT_WHEEL 0 as-integer whev/mouse_x as-integer whev/mouse_y 0 as-integer whev/y
			]
		]
		any [type = SDL_EVENT_KEY_DOWN type = SDL_EVENT_KEY_UP][
			keyev: as SDL_KeyboardEvent! ev
			win: find-window-by-id keyev/windowID
			if win = null [return yes]
			target: either focused-widget <> null [focused-widget][win]
			key: keyev/key and FFFFh
			dispatch-event as red-object! :win/face as red-object! :target/face either type = SDL_EVENT_KEY_DOWN [EVT_KEY_DOWN][EVT_KEY_UP] 0 0 0 key 0
			if type = SDL_EVENT_KEY_DOWN [
				dispatch-event as red-object! :win/face as red-object! :target/face EVT_KEY 0 0 0 key 0
				if (edit-widget-key win target key keyev/scancode) = no [
					text-list-key win target keyev/scancode
				]
			]
		]
		type = SDL_EVENT_TEXT_INPUT [
			tev: as SDL_TextInputEvent! ev
			win: find-window-by-id tev/windowID
			if win = null [return yes]
			target: either focused-widget <> null [focused-widget][win]
			edit-widget-text win target tev/text
		]
		true [0]
	]
	yes
]

process-widget-timers: func [
	win	   [sdl-widget!]
	widget [sdl-widget!]
	now	   [integer!]
	/local
		values [red-value!]
		pane   [red-block!]
		child  [red-object!]
		tail   [red-object!]
		cw	   [sdl-widget!]
][
	if widget = null [exit]
	if all [widget/timer-ms > 0 now >= widget/timer-next][
		widget/timer-next: now + widget/timer-ms
		dispatch-event as red-object! :win/face as red-object! :widget/face EVT_TIME 0 0 0 0 0
		if last-window = null [exit]
	]

	values: get-face-values as red-object! :widget/face
	pane: as red-block! values + FACE_OBJ_PANE
	if TYPE_OF(pane) = TYPE_BLOCK [
		child: as red-object! block/rs-head pane
		tail: as red-object! block/rs-tail pane
		while [child < tail][
			if TYPE_OF(child) = TYPE_OBJECT [
				cw: get-face-widget child
				if cw <> null [
					process-widget-timers win cw now
					if last-window = null [exit]
				]
			]
			child: child + 1
		]
	]
]

do-events: func [
	no-wait?	[logic!]
	_win		[handle!]
	return:		[logic!]
	/local
		ev		[sdl-event!]
		seen?	[logic!]
		ok?		[logic!]
][
	ev: declare sdl-event!
	seen?: no
	if all [last-window <> null focused-widget = null][
		focus-selected-widget last-window as red-object! :last-window/face
	]
	either no-wait? [
		ok?: SDL_PollEvent ev
		while [ok?][
			seen?: yes
			if not handle-sdl-event ev [ok?: no]
			if ok? [ok?: SDL_PollEvent ev]
		]
		if last-window <> null [process-widget-timers last-window last-window SDL_GetTicks]
		if all [last-window <> null last-window/dirty?][render-window last-window]
	][
		quit?: no
		exit-loop?: no
		while [all [not quit? not exit-loop? last-window <> null]][
			ok?: SDL_WaitEventTimeout ev 16
			while [ok?][
				seen?: yes
				if not handle-sdl-event ev [ok?: no quit?: yes]
				if all [ok? not quit? not exit-loop? last-window <> null][ok?: SDL_PollEvent ev]
			]
			if last-window <> null [process-widget-timers last-window last-window SDL_GetTicks]
			if all [last-window <> null last-window/dirty?][render-window last-window]
		]
	]
	seen?
]
