Red [
	Title:	"Color requester"
	Author: "Nenad Rakocevic"
	File: 	%request-color.red
	Tabs: 	4
	Rights: "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

request-color: function [
	"Asks user to pick a color; returns it as a tuple, or NONE if cancelled"
	/color	"Sets the initial color"
		init [tuple!]
	/native	"Uses the system's color requester, where there is one"
][
	do [												;-- interpreted, so the inner functions share these words
		recent: []										;-- kept across calls
		named: [										;-- Red's color words: light row, dark row
			white snow ivory linen beige wheat yello yellow gold orange papaya red crimson pink magenta sky cyan green tanned khaki silver pewter
			black coal gray rebolor mint olive oldrab forest leaf teal aqua water reblue navy blue violet purple maroon brick sienna brown coffee
		]
		units: [360 100 100 255 255 255 255]			;-- channels: H S V R G B A
		hexa: charset "0123456789abcdefABCDEF"
		rows: collect [									;-- a slider per channel: label, track, value
			repeat i 7 [keep compose [return label (form pick "HSVRGBA" i) channel extra (i) num extra (i)]]
		]

		component: func [c [block!] n [integer!] /local k][	;-- R, G or B (N: 5, 3, 1) of HSV color C
			k: c/1 * 6 + n % 6
			to integer! round 255 * c/3 * (1 - (c/2 * max 0 min 1 min k 4 - k))
		]

		to-rgb: func [c [block!]][as-color component c 5 component c 3 component c 1]	;-- [H S V] in 0..1

		set-color: func [c [tuple!]][					;-- keeps hue and saturation where undefined
			mx: max c/1 max c/2 c/3
			d: mx - min c/1 min c/2 c/3
			if d > 0 [
				hsv/1: (case [
					mx = c/1 [c/2 - c/3 / d // 6]
					mx = c/2 [c/3 - c/1 / d + 2]
					true	 [c/1 - c/2 / d + 4]
				]) / 6
			]
			if mx > 0 [hsv/2: d / mx]
			hsv/3: mx / 255
			a: either 3 < length? c [c/4][0]
		]

		load-color: func [text [string!]][				;-- #RGB, #RRGGBB(AA) (# optional), a tuple or a color word
			attempt [
				c: either parse text [opt #"#" copy c some hexa][hex-to-rgb to issue! c][load text]
				if word? c [c: get c]
				all [find [3 4] length? c  to tuple! c]
			]
		]

		level: func [i [integer!]][either i < 4 [hsv/:i][rgba/(i - 3) / 255]]	;-- channel I in 0..1
		amount: func [i [integer!]][form round/to units/:i * level i 1]			;-- channel I in its unit, as text

		tint: func [i [integer!] x [number!] /local c][	;-- current color with channel I at X, opaque but for A
			either i < 4 [
				c: copy hsv
				c/:i: x
				if i = 1 [c/2: c/3: 1]					;-- pure hues
				to-rgb c
			][
				c: rgb + 0.0.0.0						;-- 4 components, for A
				c/(i - 3): to integer! round 255 * x
				c
			]
		]

		set-channel: func [i [integer!] x [number!]][	;-- clamps X to 0..1
			x: max 0 min 1 x
			either i < 4 [hsv/:i: x][
				c: rgba
				c/(i - 3): to integer! round 255 * x
				set-color c
			]
		]

		refresh: func [src [object! none!]][			;-- redraws, then updates the fields but SRC
			rgb: to-rgb hsv
			rgba: rgb + as-rgba 0 0 0 a
			current: either a > 0 [rgba][rgb]
			name: foreach w named [if rgba = get w [break/return w]]
			redraw
			foreach f parts [
				if all [f/extra  not same? f src][
					case [
						block? f/extra	[f/text: do f/extra]
						f/type = 'base	[bar f]
						true			[f/text: amount f/extra]
					]
				]
			]
		]

		done: func [c [tuple! none!]][
			if picked: c [
				remove find recent c
				insert recent c
				clear skip recent 18
			]
			if dialog [unview/only dialog]
		]

		#either config/GUI-engine = 'terminal [			;-- cells: images show as truecolor half blocks
			native: no									;-- no system requester: this one
			moves: [left -1x0 right 1x0 up 0x1 down 0x-1]
			steps: [left -1 right 1 page-down -10 page-up 10 home -999 end 999]	;-- in channel units
			spot: 0x0									;-- swatch grid cursor

			shade: func [c [tuple!] /local t][			;-- C as shown: transparency blended on dark gray
				t: either 3 < length? c [c/4 / 255][0]
				(as-color c/1 c/2 c/3) * (1 - t) + (40.40.40 * t)
			]

			ink: func [c [tuple!]][						;-- black or white, readable over C
				c: shade c
				either 382 < (c/1 + c/2 + c/3) [black][white]
			]

			pixels: func [size [pair!] colors [block!] /local c][
				make image! reduce [size to binary! collect [foreach c colors [keep shade c]]]
			]

			mark: func [f [object!] p [pair!] c [tuple!]][	;-- a cursor, a diamond while F has the focus
				compose [pen (ink c) text (p) (either same? f focused ["◆"]["●"])]
			]

			swatch: func [p [pair!]][either p/y < 2 [get named/(p/y * 22 + p/x + 1)][recent/(p/x + 1)]]

			bar: func [f [object!]][
				row: collect [repeat k 24 [keep tint f/extra k - 1 / 23]]
				f/image: pixels 24x2 append copy row row
				f/draw: mark f as-pair round 23 * level f/extra 0 tint f/extra level f/extra
			]

			redraw: does [
				canvas/image: pixels 32x16 collect [
					repeat y 16 [repeat x 32 [keep to-rgb reduce [hsv/1  x - 1 / 31  1 - (y - 1 / 15)]]]
				]
				canvas/draw: mark canvas as-pair round 31 * hsv/2 15 - (15 * hsv/3) / 2 rgb
				preview/image: pixels 32x4 collect [loop 4 [loop 16 [keep old] loop 16 [keep rgba]]]
				preview/draw: compose [pen (ink old) text 1x0 "Original" pen (ink rgba) text 17x0 "New"]
				grid/image: pixels 22x6 collect [
					foreach y [0 0 1 1 2 2][repeat x 22 [keep any [swatch as-pair x - 1 y  60.60.60]]]
				]
				grid/draw: either same? grid focused [mark grid spot any [swatch spot black]][[]]
			]

			point: func [f [object!] p [pair!]][		;-- picks the color at cell P of picker F
				case [
					same? f canvas [
						set-channel 2 p/x / 31
						set-channel 3 1 - (p/y / 7)
					]
					same? f grid [
						spot: max 0x0 min 21x2 p
						if c: swatch spot [set-color c]
					]
					true [set-channel f/extra p/x / 23]
				]
				refresh none
			]

			body: compose/only [
				style picker: base with [flags: [focusable all-over]]
					on-focus [focused: face  refresh none]
					on-unfocus [focused: none  refresh none]
					on-down [point face event/offset]	;-- the pressed picker follows the mouse until the button is up
					on-over [if event/down? [point face event/offset]]
				canvas: picker 32x8 focus on-key [
					if d: select moves event/key [
						set-channel 2 hsv/2 + (d/x / 31)
						set-channel 3 hsv/3 + (d/y / 15)
						refresh none
					]
				]
				sliders: panel (compose [
					origin 0x0 space 1x0
					style channel: picker 24x1 on-key [
						switch/default event/key [
							up	 [set-focus/before face]
							down [set-focus/after face]
						][
							if d: select steps event/key [
								set-channel face/extra (level face/extra) + (d / units/(face/extra))
								refresh none
							]
						]
					]
					style label: text 2x1
					style num: text 4x1 right
					preview: base 32x2 on-down [if event/offset/x < 16 [set-color old  refresh none]]	;-- the original color: back to it
					(rows)
				])
				return
				grid: picker 22x3 on-key [
					if d: select moves event/key [point face spot + (d * 1x-1)]
				]
				pad 0x2 text 6x1 "Recent"
				return
				entry 20 extra [form any [name current]]
				entry 10 extra [mold to issue! enbase/base to binary! current 16]
				button " OK " [done current]
				button " Cancel " [done none]
			]
			body: compose/only [group-box " Color " options [border-corners: round border-color: 64.64.64] (body)]	;-- framed, as REQUEST-FILE
		][
			checker: [fill-pen pattern 8x8 [pen off fill-pen white box 0x0 8x8 fill-pen 204.204.204 box 0x0 4x4 box 4x4 8x8]]
			caption: make font! [size: 8 color: 110.110.110]

			knob: func [p [point2D!] c [tuple!]][
				compose [fill-pen (c) pen 0.0.0.150 line-width 4 circle (p) 7 pen white line-width 2 circle (p) 7]
			]

			bar: func [f [object!]][					;-- slider of channel F/EXTRA
				i: f/extra
				f/draw: compose/deep [
					pen off
					push [(checker) box 10x6 166x18 6]	;-- push: GTK crashes on a pattern to gradient switch
					fill-pen linear (collect [repeat k 7 [keep tint i k - 1 / 6]]) box 10x6 166x18 6
					(knob as-point2D 10 + (156 * level i) 12 tint i level i)
				]
			]

			redraw: does [
				if plane <> (canvas/size - 20x72) [arrange]	;-- a new canvas size
				canvas/draw: compose/only [				;-- /only: the swatches are nested, not copied
					pen off
					fill-pen linear white (to-rgb reduce [hsv/1 1 1]) box 10x10 (10x10 + plane) 6
					pen 0.0.0.220 fill-pen linear 0.0.0.255 black 10x10 (as-pair 10 10 + plane/y) box 10x10 (10x10 + plane) 6
					(swatches)
					(knob as-point2D 10 + (plane/x * hsv/2) 10 + plane/y - (plane/y * hsv/3) rgb)
				]
				preview/draw: compose/deep [			;-- one swatch: the original color, then the new one
					pen off
					(checker) box 1x15 241x55 6
					clip 0x0 121x56 [fill-pen (old) box 1x15 241x55 6]
					clip 121x0 242x56 [fill-pen (rgba) box 1x15 241x55 6]
					pen 0.0.0.150 fill-pen off box 1x15 241x55 6 line 121x15 121x55
					font caption text 1x0 "Original" text 121x0 "New"
				]
			]

			drag: func [ofs [point2D! pair!]][
				if zone [
					p: max 0x0 min zone/2 ofs - zone/1
					n: p / zone/2
					do zone/3
					refresh none
				]
			]

			slide: func [f [object!] ofs [point2D! pair!]][
				set-channel f/extra ofs/x - 10 / 156
				refresh none
			]

			cell: func [col [integer!] y [integer!] c [tuple!]][	;-- a swatch in column COL of the grid, on whole pixels
				compose [fill-pen (c) box (as-pair 10 + round col * pitch y) (as-pair 9 + round col + 1 * pitch y + 13) 2]
			]

			arrange: func [/local y i][					;-- the canvas parts for its size: plane, swatch grid, zones
				plane: canvas/size - 20x72
				pitch: plane/x / 22							;-- 22 swatches per row
				y: plane/y + 22								;-- top of the swatch rows
				zones: reduce [								;-- [offset size action], N: position in 0..1
					reduce [10x10 plane [hsv/2: n/x  hsv/3: 1 - n/y]]
					reduce [as-pair 10 y  as-pair plane/x 28  [c: min 21x1 as-pair p/x / pitch p/y / 14  set-color get named/(c/y * 22 + c/x + 1)]]
					reduce [as-pair 10 + round 4 * pitch y + 36  as-pair plane/x - round 4 * pitch 14  [if c: recent/(1 + min 17 to integer! p/x / pitch) [set-color c]]]
				]
				swatches: collect [							;-- named colors, then the recent ones from column 4
					repeat i 44 [keep cell i - 1 % 22 either i > 22 [y + 14][y] get named/:i]
					keep compose [font caption text (as-pair 10 y + 34) "Recent"]
					repeat i 18 [keep cell i + 3 y + 36 any [recent/:i 0.0.0.235]]
				]
			]

			reflow: func [size [pair! point2D!] /local d][	;-- the plane takes the new room, the panel and the buttons follow
				size: to pair! size
				d: max 0x0 size - frame/1						;-- never below the laid-out size, where it snaps back
				if size <> max size frame/1 - 8x8 [canvas/rate: 4]	;-- once resizing stops (8 px slack: GTK stays 4x5 short)
				foreach [f ofs sz] next frame [
					case [
						same? f canvas	[f/size: sz + d]
						same? f sliders	[f/offset: ofs + (d * 1x0)]
						true			[f/offset: ofs + (d * either f/type = 'button [1x1][0x1])]
					]
				]
				refresh none
			]
			margin: any [select system/view/metrics/margins 'button [0x0]]	;-- buttons' invisible borders

			body: compose/only [
				origin 2x10 space 10x12 pad -2x-10		;-- the canvas spreads over the margins: room for the knobs
				canvas: box 328x300 all-over
					on-created [								;-- the laid-out window, base of REFLOW
						frame: reduce [face/parent/size]
						foreach f face/parent/pane [repend frame [f f/offset f/size]]
					]
					on-down [
						zone: foreach z zones [if within? event/offset z/1 z/2 [break/return z]]
						drag event/offset
					]
					on-over [if event/down? [drag event/offset]]
					on-time [face/rate: none  face/parent/size: max frame/1 to pair! face/parent/size]	;-- the snap back of REFLOW
				pad -8x0
				sliders: panel (compose [
					origin 8x10 space 4x6 across middle
					style channel: box 176x24 all-over
						on-down [slide face event/offset]
						on-over [if event/down? [slide face event/offset]]
					style num: field 44 right on-change [
						if all [face/text <> amount face/extra  x: attempt [to integer! face/text]][
							set-channel face/extra x / units/(face/extra)
							refresh face
						]
					]
					style label: text 14x24
					preview: box 242x56 on-down [if event/offset/x < 121 [set-color old  refresh none]]
					(rows)
				])
				return middle pad 8x0
				entry 140 extra [form any [name current]]
				entry 104 extra [mold to issue! enbase/base to binary! current 16]
				pad (as-pair 136 - (3 * margin/1/x) 0)	;-- right-aligns the buttons
				button 80 "Cancel" [done none]
				button 80 "OK" [done current]
				react later [if frame [reflow canvas/parent/size]]	;-- once the canvas is shown
			]
		]
		hsv: reduce [0 0 0]
		set-color old: any [init white]

		either native [
			c: system/view/platform/request-color any [init white] recent	;-- 4 components, or none
			done all [c  either zero? c/4 [as-color c/1 c/2 c/3][c]]
		][
			view/flags compose [
				title "Color"
				on-key [if event/key = #"^M" [done current]]
				on-key-down [if event/key = #"^[" [done none]]	;-- before the terminal's Esc handler (UNVIEW/ALL on the key event)
				on-enter [								;-- bubbled up from the fields (terminal ones send no change)
					if all [block? event/face/extra  c: load-color event/face/text][set-color c  refresh none]
					done current
				]
				style entry: field on-change [
					if all [face/text <> do face/extra  c: load-color face/text][set-color c  refresh face]
				]
				(body)
				do [
					dialog: self							;-- the window: VID binds DO blocks to it
					parts: append copy canvas/parent/pane sliders/pane
					refresh none
				]
			] [modal resize]
		]
		picked
	]
]
