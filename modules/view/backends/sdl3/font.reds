Red/System [
	Title:	"SDL3 TTF font support"
	File: 	%font.reds
	Tabs: 	4
]

#define SDL3_DEFAULT_FONT_SIZE 20.0
#define SDL3_FONT_POINT_SCALE 1.3333333

ttf-initialized?: no
default-font: declare handle!
default-font: null

font-size-facet: func [
	font [red-object!]
	return: [float32!]
	/local
		values [red-value!]
		int	 [red-integer!]
][
	if font = null [return as float32! SDL3_DEFAULT_FONT_SIZE]
	if TYPE_OF(font) <> TYPE_OBJECT [return as float32! SDL3_DEFAULT_FONT_SIZE]
	values: object/get-values font
	int: as red-integer! values + FONT_OBJ_SIZE
	if all [TYPE_OF(int) = TYPE_INTEGER int/value > 0][
		return (as float32! int/value) * as float32! SDL3_FONT_POINT_SCALE
	]
	as float32! SDL3_DEFAULT_FONT_SIZE
]

font-style-facet: func [
	font	[red-object!]
	return: [integer!]
	/local
		values [red-value!]
		style  [red-word!]
		blk	   [red-block!]
		len	   [integer!]
		sym	   [integer!]
		flags  [integer!]
][
	flags: TTF_STYLE_NORMAL
	if font = null [return flags]
	if TYPE_OF(font) <> TYPE_OBJECT [return flags]

	values: object/get-values font
	style: as red-word! values + FONT_OBJ_STYLE
	len: switch TYPE_OF(style) [
		TYPE_BLOCK [
			blk: as red-block! style
			style: as red-word! block/rs-head blk
			block/rs-length? blk
		]
		TYPE_WORD [1]
		default	  [0]
	]
	loop len [
		sym: symbol/resolve style/symbol
		case [
			sym = _bold		 [flags: flags or TTF_STYLE_BOLD]
			sym = _italic	 [flags: flags or TTF_STYLE_ITALIC]
			sym = _underline [flags: flags or TTF_STYLE_UNDERLINE]
			sym = _strike	 [flags: flags or TTF_STYLE_STRIKETHROUGH]
			true			 [0]
		]
		style: style + 1
	]
	flags
]

open-default-font: func [
	size [float32!]
	return: [handle!]
	/local
		font [handle!]
][
	if default-font <> null [return default-font]
	#either OS = 'Windows [
		font: TTF_OpenFont "C:\Windows\Fonts\segoeui.ttf" size
		if font = null [font: TTF_OpenFont "C:\Windows\Fonts\arial.ttf" size]
		if font = null [font: TTF_OpenFont "C:\Windows\Fonts\tahoma.ttf" size]
	][
		font: TTF_OpenFont "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf" size
		if font = null [font: TTF_OpenFont "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf" size]
		if font = null [font: TTF_OpenFont "/usr/share/fonts/truetype/freefont/FreeSans.ttf" size]
		if font = null [font: TTF_OpenFont "/System/Library/Fonts/Supplemental/Arial.ttf" size]
	]
	if font <> null [
		default-font: font
		return default-font
	]
	null
]

select-font: func [
	font [red-object!]
	return: [handle!]
	/local
		size [float32!]
		tfont [handle!]
][
	size: font-size-facet font
	tfont: open-default-font size
	if tfont <> null [
		TTF_SetFontSize tfont size
		TTF_SetFontStyle tfont font-style-facet font
	]
	tfont
]

select-font-with-style: func [
	font	[red-object!]
	style	[integer!]
	return: [handle!]
	/local
		tfont [handle!]
][
	tfont: select-font font
	if tfont <> null [TTF_SetFontStyle tfont style]
	tfont
]

init-fonts: func [
	return: [logic!]
	/local
		font [handle!]
][
	if ttf-initialized? [return yes]
	if TTF_Init [
		ttf-initialized?: yes
		font: open-default-font as float32! SDL3_DEFAULT_FONT_SIZE
		return font <> null
	]
	no
]

shutdown-fonts: does [
	if default-font <> null [
		TTF_CloseFont default-font
		default-font: null
	]
	if ttf-initialized? [
		TTF_Quit
		ttf-initialized?: no
	]
]

draw-text: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	text	 [red-string!]
	color	 [integer!]
	font	 [red-object!]
	/local
		len w h	[integer!]
		utf8	[c-string!]
		tfont	[handle!]
		surface [SDL_Surface!]
		texture [handle!]
		fg		[SDL_Color!]
		dst		[SDL_FRect!]
][
	if any [text = null TYPE_OF(text) <> TYPE_STRING][exit]
	tfont: select-font font
	if tfont = null [exit]

	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][exit]

	fg: declare SDL_Color!
	fg/r: as byte! (color and FFh)
	fg/g: as byte! ((color >>> 8) and FFh)
	fg/b: as byte! ((color >>> 16) and FFh)
	fg/a: as byte! either color and FF000000h = 0 [255][(color >>> 24) and FFh]

	surface: as SDL_Surface! TTF_RenderText_Blended tfont utf8 len fg
	if surface = null [exit]
	texture: SDL_CreateTextureFromSurface renderer as handle! surface
	if texture <> null [
		dst: declare SDL_FRect!
		dst/x: as float32! x
		dst/y: as float32! y
		dst/w: as float32! surface/w
		dst/h: as float32! surface/h
		SDL_SetTextureBlendMode texture SDL_BLENDMODE_BLEND
		SDL_RenderTexture renderer texture null as int-ptr! dst
		SDL_DestroyTexture texture
	]
	SDL_DestroySurface as handle! surface
]

draw-text-wrapped: func [
	renderer	[handle!]
	x			[integer!]
	y			[integer!]
	text		[red-string!]
	color		[integer!]
	font		[red-object!]
	wrap-width	[integer!]
	/local
		len		[integer!]
		utf8	[c-string!]
		tfont	[handle!]
		surface [SDL_Surface!]
		texture [handle!]
		fg		[SDL_Color!]
		dst		[SDL_FRect!]
][
	if any [text = null TYPE_OF(text) <> TYPE_STRING][exit]
	tfont: select-font font
	if tfont = null [exit]

	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][exit]

	fg: declare SDL_Color!
	fg/r: as byte! (color and FFh)
	fg/g: as byte! ((color >>> 8) and FFh)
	fg/b: as byte! ((color >>> 16) and FFh)
	fg/a: as byte! either color and FF000000h = 0 [255][(color >>> 24) and FFh]

	surface: as SDL_Surface! TTF_RenderText_Blended_Wrapped tfont utf8 len fg wrap-width
	if surface = null [exit]
	texture: SDL_CreateTextureFromSurface renderer as handle! surface
	if texture <> null [
		dst: declare SDL_FRect!
		dst/x: as float32! x
		dst/y: as float32! y
		dst/w: as float32! surface/w
		dst/h: as float32! surface/h
		SDL_SetTextureBlendMode texture SDL_BLENDMODE_BLEND
		SDL_RenderTexture renderer texture null as int-ptr! dst
		SDL_DestroyTexture texture
	]
	SDL_DestroySurface as handle! surface
]

draw-text-styled: func [
	renderer [handle!]
	x		 [integer!]
	y		 [integer!]
	text	 [red-string!]
	color	 [integer!]
	font	 [red-object!]
	style	 [integer!]
	/local
		len		[integer!]
		utf8	[c-string!]
		tfont	[handle!]
		surface [SDL_Surface!]
		texture [handle!]
		fg		[SDL_Color!]
		dst		[SDL_FRect!]
][
	if any [text = null TYPE_OF(text) <> TYPE_STRING][exit]
	tfont: select-font-with-style font style
	if tfont = null [exit]

	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][exit]

	fg: declare SDL_Color!
	fg/r: as byte! (color and FFh)
	fg/g: as byte! ((color >>> 8) and FFh)
	fg/b: as byte! ((color >>> 16) and FFh)
	fg/a: as byte! either color and FF000000h = 0 [255][(color >>> 24) and FFh]

	surface: as SDL_Surface! TTF_RenderText_Blended tfont utf8 len fg
	if surface = null [exit]
	texture: SDL_CreateTextureFromSurface renderer as handle! surface
	if texture <> null [
		dst: declare SDL_FRect!
		dst/x: as float32! x
		dst/y: as float32! y
		dst/w: as float32! surface/w
		dst/h: as float32! surface/h
		SDL_SetTextureBlendMode texture SDL_BLENDMODE_BLEND
		SDL_RenderTexture renderer texture null as int-ptr! dst
		SDL_DestroyTexture texture
	]
	SDL_DestroySurface as handle! surface
]

get-text-size-styled-px: func [
	text	[red-string!]
	font	[red-object!]
	style	[integer!]
	w-out	[int-ptr!]
	h-out	[int-ptr!]
	return: [logic!]
	/local
		len [integer!]
		utf8 [c-string!]
		tfont [handle!]
][
	w-out/value: 0
	h-out/value: 0
	if any [text = null TYPE_OF(text) <> TYPE_STRING][return no]
	tfont: select-font-with-style font style
	if tfont = null [return no]
	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][return no]
	TTF_GetStringSize tfont utf8 len w-out h-out
]

get-bitmap-text-size: func [
	text	[red-string!]
	p		[red-point2D!]
	font	[red-object!]
	/local
		len w h	[integer!]
		utf8	[c-string!]
		tfont	[handle!]
][
	p/x: as float32! 0.0
	p/y: as float32! 0.0
	if any [text = null TYPE_OF(text) <> TYPE_STRING][exit]
	tfont: select-font font
	if tfont = null [exit]
	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][exit]
	w: 0
	h: 0
	if TTF_GetStringSize tfont utf8 len :w :h [
		p/x: as float32! w
		p/y: as float32! h
	]
]

get-text-size-px: func [
	text	[red-string!]
	font	[red-object!]
	w-out	[int-ptr!]
	h-out	[int-ptr!]
	return: [logic!]
	/local
		len [integer!]
		utf8 [c-string!]
		tfont [handle!]
][
	w-out/value: 0
	h-out/value: 0
	if any [text = null TYPE_OF(text) <> TYPE_STRING][return no]
	tfont: select-font font
	if tfont = null [return no]
	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][return no]
	TTF_GetStringSize tfont utf8 len w-out h-out
]

get-text-size-wrapped-px: func [
	text		[red-string!]
	font		[red-object!]
	wrap-width	[integer!]
	w-out		[int-ptr!]
	h-out		[int-ptr!]
	return: 	[logic!]
	/local
		len [integer!]
		utf8 [c-string!]
		tfont [handle!]
][
	w-out/value: 0
	h-out/value: 0
	if any [text = null TYPE_OF(text) <> TYPE_STRING][return no]
	tfont: select-font font
	if tfont = null [return no]
	len: -1
	utf8: unicode/to-utf8 text :len
	if any [utf8 = null len = 0][return no]
	either wrap-width > 0 [
		TTF_GetStringSizeWrapped tfont utf8 len wrap-width w-out h-out
	][
		TTF_GetStringSize tfont utf8 len w-out h-out
	]
]
