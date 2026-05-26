Red/System [
	Title:	"SDL3 imports and definitions"
	File: 	%sdl3.reds
	Tabs: 	4
]

#define SDL_INIT_TIMER		00000001h
#define SDL_INIT_VIDEO		00000020h
#define SDL_INIT_EVENTS		00004000h

#define SDL_WINDOW_FULLSCREEN	00000001h
#define SDL_WINDOW_RESIZABLE	00000020h
#define SDL_WINDOW_HIDDEN		00000008h

#define SDL_EVENT_FIRST					0
#define SDL_EVENT_QUIT					100h
#define SDL_EVENT_TERMINATING			101h
#define SDL_EVENT_LOW_MEMORY			102h
#define SDL_EVENT_WILL_ENTER_BACKGROUND	103h
#define SDL_EVENT_DID_ENTER_BACKGROUND	104h
#define SDL_EVENT_WILL_ENTER_FOREGROUND	105h
#define SDL_EVENT_DID_ENTER_FOREGROUND	106h
#define SDL_EVENT_LOCALE_CHANGED		107h
#define SDL_EVENT_SYSTEM_THEME_CHANGED	108h

#define SDL_EVENT_WINDOW_FIRST					200h
#define SDL_EVENT_WINDOW_SHOWN					202h
#define SDL_EVENT_WINDOW_HIDDEN					203h
#define SDL_EVENT_WINDOW_EXPOSED				204h
#define SDL_EVENT_WINDOW_MOVED					205h
#define SDL_EVENT_WINDOW_RESIZED				206h
#define SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED		207h
#define SDL_EVENT_WINDOW_METAL_VIEW_RESIZED		208h
#define SDL_EVENT_WINDOW_MINIMIZED				209h
#define SDL_EVENT_WINDOW_MAXIMIZED				20Ah
#define SDL_EVENT_WINDOW_RESTORED				20Bh
#define SDL_EVENT_WINDOW_MOUSE_ENTER			20Ch
#define SDL_EVENT_WINDOW_MOUSE_LEAVE			20Dh
#define SDL_EVENT_WINDOW_FOCUS_GAINED			20Eh
#define SDL_EVENT_WINDOW_FOCUS_LOST				20Fh
#define SDL_EVENT_WINDOW_CLOSE_REQUESTED		210h
#define SDL_EVENT_USER							8000h

#define SDL_EVENT_KEY_DOWN		300h
#define SDL_EVENT_KEY_UP		301h
#define SDL_EVENT_TEXT_EDITING	302h
#define SDL_EVENT_TEXT_INPUT	303h

#define SDL_EVENT_MOUSE_MOTION	400h
#define SDL_EVENT_MOUSE_BUTTON_DOWN 401h
#define SDL_EVENT_MOUSE_BUTTON_UP	402h
#define SDL_EVENT_MOUSE_WHEEL		403h

#define SDL_BUTTON_LEFT		1
#define SDL_BUTTON_MIDDLE	2
#define SDL_BUTTON_RIGHT	3
#define SDL_BUTTON_X1		4
#define SDL_BUTTON_X2		5

#either OS = 'Windows [
	#define VK_BACK		08h
	#define VK_TAB		09h
	#define VK_CLEAR	0Ch
	#define VK_RETURN	0Dh
	#define VK_SHIFT	10h
	#define VK_CONTROL	11h
	#define VK_PRIOR	21h
	#define VK_NEXT		22h
	#define VK_END		23h
	#define VK_HOME		24h
	#define VK_LEFT		25h
	#define VK_UP		26h
	#define VK_RIGHT	27h
	#define VK_DOWN		28h
	#define VK_SELECT	29h
	#define VK_INSERT	2Dh
	#define VK_DELETE	2Eh
][]

#define SDL_PIXELFORMAT_ARGB8888	16362004h
#define SDL_TEXTUREACCESS_STATIC	0
#define SDL_BLENDMODE_BLEND			00000001h

#define TTF_STYLE_NORMAL			00h
#define TTF_STYLE_BOLD				01h
#define TTF_STYLE_ITALIC			02h
#define TTF_STYLE_UNDERLINE			04h
#define TTF_STYLE_STRIKETHROUGH		08h

SDL_Rect!: alias struct! [
	x [integer!]
	y [integer!]
	w [integer!]
	h [integer!]
]

SDL_FRect!: alias struct! [
	x [float32!]
	y [float32!]
	w [float32!]
	h [float32!]
]

SDL_CommonEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
]

SDL_WindowEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	data1		[integer!]
	data2		[integer!]
]

SDL_KeyboardEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	which		[integer!]
	scancode	[integer!]
	key			[integer!]
	mod			[integer!]
	raw1		[byte!]
	raw2		[byte!]
	down		[byte!]
	repeat		[byte!]
	padding1	[byte!]
	padding2	[byte!]
]

SDL_TextInputEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	text		[c-string!]
]

SDL_MouseMotionEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	which		[integer!]
	state		[integer!]
	x			[float32!]
	y			[float32!]
	xrel		[float32!]
	yrel		[float32!]
]

SDL_MouseButtonEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	which		[integer!]
	button		[byte!]
	down		[byte!]
	clicks		[byte!]
	padding		[byte!]
	x			[float32!]
	y			[float32!]
]

SDL_MouseWheelEvent!: alias struct! [
	type		[integer!]
	reserved	[integer!]
	timestamp	[float!]
	windowID	[integer!]
	which		[integer!]
	x			[float32!]
	y			[float32!]
	direction	[integer!]
	mouse_x		[float32!]
	mouse_y		[float32!]
	integer_x	[integer!]
	integer_y	[integer!]
]

SDL_DisplayMode!: alias struct! [
	displayID		[integer!]
	format			[integer!]
	w				[integer!]
	h				[integer!]
	pixel_density	[float32!]
	refresh_rate	[float32!]
	refresh_rate_num [integer!]
	refresh_rate_den [integer!]
	internal		[handle!]
]

SDL_Surface!: alias struct! [
	flags		[integer!]
	format		[integer!]
	w			[integer!]
	h			[integer!]
	pitch		[integer!]
	pixels		[byte-ptr!]
	refcount	[integer!]
	reserved	[handle!]
]

SDL_Color!: alias struct! [
	r [byte!]
	g [byte!]
	b [byte!]
	a [byte!]
]

sdl-event!: alias struct! [
	data [integer!]
	pad1 [integer!]
	pad2 [integer!]
	pad3 [integer!]
	pad4 [integer!]
	pad5 [integer!]
	pad6 [integer!]
	pad7 [integer!]
	pad8 [integer!]
	pad9 [integer!]
	pad10 [integer!]
	pad11 [integer!]
	pad12 [integer!]
	pad13 [integer!]
	pad14 [integer!]
	pad15 [integer!]
	pad16 [integer!]
	pad17 [integer!]
	pad18 [integer!]
	pad19 [integer!]
	pad20 [integer!]
	pad21 [integer!]
	pad22 [integer!]
	pad23 [integer!]
	pad24 [integer!]
	pad25 [integer!]
	pad26 [integer!]
	pad27 [integer!]
	pad28 [integer!]
	pad29 [integer!]
	pad30 [integer!]
	pad31 [integer!]
]

#import [
	"SDL3.lib" cdecl [
		SDL_Init: "SDL_Init" [
			flags	[integer!]
			return: [logic!]
		]
		SDL_Quit: "SDL_Quit" []
		SDL_GetError: "SDL_GetError" [
			return: [c-string!]
		]
		SDL_GetTicks: "SDL_GetTicks" [
			return: [integer!]
		]

		SDL_CreateWindow: "SDL_CreateWindow" [
			title	[c-string!]
			w		[integer!]
			h		[integer!]
			flags-lo [integer!]
			flags-hi [integer!]
			return: [handle!]
		]
		SDL_DestroyWindow: "SDL_DestroyWindow" [
			window	[handle!]
		]
		SDL_ShowWindow: "SDL_ShowWindow" [
			window	[handle!]
			return: [logic!]
		]
		SDL_HideWindow: "SDL_HideWindow" [
			window	[handle!]
			return: [logic!]
		]
		SDL_SetWindowTitle: "SDL_SetWindowTitle" [
			window	[handle!]
			title	[c-string!]
			return: [logic!]
		]
		SDL_SetWindowSize: "SDL_SetWindowSize" [
			window	[handle!]
			w		[integer!]
			h		[integer!]
			return: [logic!]
		]
		SDL_SetWindowPosition: "SDL_SetWindowPosition" [
			window	[handle!]
			x		[integer!]
			y		[integer!]
			return: [logic!]
		]
		SDL_SetWindowFullscreen: "SDL_SetWindowFullscreen" [
			window		[handle!]
			fullscreen?	[logic!]
			return:		[logic!]
		]
		SDL_GetWindowID: "SDL_GetWindowID" [
			window	[handle!]
			return: [integer!]
		]
		SDL_GetWindowFromID: "SDL_GetWindowFromID" [
			id		[integer!]
			return: [handle!]
		]
		SDL_GetDisplays: "SDL_GetDisplays" [
			count	[int-ptr!]
			return: [int-ptr!]
		]
		SDL_GetPrimaryDisplay: "SDL_GetPrimaryDisplay" [
			return: [integer!]
		]
		SDL_GetDisplayBounds: "SDL_GetDisplayBounds" [
			displayID [integer!]
			rect	  [SDL_Rect!]
			return:	  [logic!]
		]
		SDL_StartTextInput: "SDL_StartTextInput" [
			window	[handle!]
			return: [logic!]
		]
		SDL_StopTextInput: "SDL_StopTextInput" [
			window	[handle!]
			return: [logic!]
		]

		SDL_CreateRenderer: "SDL_CreateRenderer" [
			window	[handle!]
			name	[c-string!]
			return: [handle!]
		]
		SDL_DestroyRenderer: "SDL_DestroyRenderer" [
			renderer [handle!]
		]
		SDL_SetRenderDrawColor: "SDL_SetRenderDrawColor" [
			renderer [handle!]
			r		 [byte!]
			g		 [byte!]
			b		 [byte!]
			a		 [byte!]
			return:	 [logic!]
		]
		SDL_RenderClear: "SDL_RenderClear" [
			renderer [handle!]
			return:	 [logic!]
		]
		SDL_RenderPresent: "SDL_RenderPresent" [
			renderer [handle!]
			return:	 [logic!]
		]
		SDL_RenderFillRect: "SDL_RenderFillRect" [
			renderer [handle!]
			rect	 [SDL_FRect!]
			return:	 [logic!]
		]
		SDL_RenderLine: "SDL_RenderLine" [
			renderer [handle!]
			x1		 [float32!]
			y1		 [float32!]
			x2		 [float32!]
			y2		 [float32!]
			return:	 [logic!]
		]
		SDL_SetRenderClipRect: "SDL_SetRenderClipRect" [
			renderer [handle!]
			rect	 [int-ptr!]
			return:	 [logic!]
		]
		SDL_CreateTexture: "SDL_CreateTexture" [
			renderer [handle!]
			format	 [integer!]
			access	 [integer!]
			w		 [integer!]
			h		 [integer!]
			return:	 [handle!]
		]
		SDL_CreateTextureFromSurface: "SDL_CreateTextureFromSurface" [
			renderer [handle!]
			surface	 [handle!]
			return:	 [handle!]
		]
		SDL_UpdateTexture: "SDL_UpdateTexture" [
			texture [handle!]
			rect	[int-ptr!]
			pixels	[int-ptr!]
			pitch	[integer!]
			return: [logic!]
		]
		SDL_SetTextureBlendMode: "SDL_SetTextureBlendMode" [
			texture	[handle!]
			mode	[integer!]
			return: [logic!]
		]
		SDL_RenderTexture: "SDL_RenderTexture" [
			renderer [handle!]
			texture	 [handle!]
			srcrect	 [int-ptr!]
			dstrect	 [int-ptr!]
			return:	 [logic!]
		]
		SDL_DestroyTexture: "SDL_DestroyTexture" [
			texture	[handle!]
		]
		SDL_RenderReadPixels: "SDL_RenderReadPixels" [
			renderer [handle!]
			rect	 [int-ptr!]
			return:	 [handle!]
		]
		SDL_ConvertSurface: "SDL_ConvertSurface" [
			surface [handle!]
			format	[integer!]
			return: [handle!]
		]
		SDL_DestroySurface: "SDL_DestroySurface" [
			surface [handle!]
		]

		SDL_PollEvent: "SDL_PollEvent" [
			event	[sdl-event!]
			return: [logic!]
		]
		SDL_FlushEvent: "SDL_FlushEvent" [
			type	[integer!]
		]
		SDL_WaitEventTimeout: "SDL_WaitEventTimeout" [
			event	[sdl-event!]
			timeout	[integer!]
			return: [logic!]
		]
		SDL_PushEvent: "SDL_PushEvent" [
			event	[sdl-event!]
			return: [logic!]
		]
		SDL_ShowSimpleMessageBox: "SDL_ShowSimpleMessageBox" [
			flags	[integer!]
			title	[c-string!]
			message	[c-string!]
			window	[handle!]
			return: [logic!]
		]
	]
	"../../../../build/sdl_ttf-msvc-x86-min/SDL_ttf/Release/SDL3_ttf-static.lib" cdecl [
		TTF_Init: "TTF_Init" [
			return: [logic!]
		]
		TTF_OpenFont: "TTF_OpenFont" [
			file	[c-string!]
			ptsize	[float32!]
			return: [handle!]
		]
		TTF_CloseFont: "TTF_CloseFont" [
			font	[handle!]
		]
		TTF_SetFontSize: "TTF_SetFontSize" [
			font	[handle!]
			ptsize	[float32!]
			return: [logic!]
		]
		TTF_SetFontStyle: "TTF_SetFontStyle" [
			font	[handle!]
			style	[integer!]
		]
		TTF_GetStringSize: "TTF_GetStringSize" [
			font	[handle!]
			text	[c-string!]
			length	[integer!]
			w		[int-ptr!]
			h		[int-ptr!]
			return: [logic!]
		]
		TTF_GetStringSizeWrapped: "TTF_GetStringSizeWrapped" [
			font		[handle!]
			text		[c-string!]
			length		[integer!]
			wrap-width	[integer!]
			w			[int-ptr!]
			h			[int-ptr!]
			return: 	[logic!]
		]
		TTF_RenderText_Blended: "TTF_RenderText_Blended" [
			font	[handle!]
			text	[c-string!]
			length	[integer!]
			fg		[SDL_Color! value]
			return: [handle!]
		]
		TTF_RenderText_Blended_Wrapped: "TTF_RenderText_Blended_Wrapped" [
			font		[handle!]
			text		[c-string!]
			length		[integer!]
			fg			[SDL_Color! value]
			wrap-width	[integer!]
			return: 	[handle!]
		]
		TTF_Quit: "TTF_Quit" []
	]
	"../../../../build/sdl_ttf-msvc-x86-min/SDL_ttf/external/freetype-build/Release/freetype.lib" cdecl [
		FT_Init_FreeType: "FT_Init_FreeType" [
			library	[int-ptr!]
			return:	[integer!]
		]
	]
]
