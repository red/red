Red/System [
	Title:	"Draw dialect"
	Author: "Nenad Rakocevic"
	File: 	%draw.red
	Tabs: 	4
	Rights: "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [
	with gui [
		line:			symbol/make "line"
		line-width:		symbol/make "line-width"
		box:			symbol/make "box"
		triangle:		symbol/make "triangle"
		pen:			symbol/make "pen"
		fill-pen:		symbol/make "fill-pen"
		_polygon:		symbol/make "polygon"
		circle:			symbol/make "circle"
		anti-alias: 	symbol/make "anti-alias"
		font:			symbol/make "font"
		text:			symbol/make "text"
		_ellipse:		symbol/make "ellipse"
		_arc:			symbol/make "arc"
		curve:			symbol/make "curve"
		line-join:		symbol/make "line-join"
		line-cap:		symbol/make "line-cap"
		
		_off:			symbol/make "off"
		closed:			symbol/make "closed"
		miter:			symbol/make "miter"
		miter-bevel:	symbol/make "miter-bevel"
		_round:			symbol/make "round"
		bevel:			symbol/make "bevel"
		square:			symbol/make "square"
		flat:			symbol/make "flat"
		key-color:		symbol/make "key-color"
		border:			symbol/make "border"
		repeat:			symbol/make "repeat"
		reflect:		symbol/make "reflect"

		throw-draw-error: func [
			cmds [red-block!]
			cmd  [red-value!]
			/local
				base [red-value!]
		][
			base: block/rs-head cmds
			cmds: as red-block! stack/push as red-value! cmds
			cmds/head: (as-integer cmd - base) >> 4
			fire [TO_ERROR(script invalid-draw) cmds]
		]
		
		draw-line: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			
			while [all [TYPE_OF(pos) = TYPE_PAIR pos < tail]][
				pos: pos + 1
			]
			pos: pos - 1
			if cmd + 2 > pos [throw-draw-error cmds cmd]
			
			OS-draw-line DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]
		
		draw-line-width: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
				int [red-integer!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]

			switch TYPE_OF(pos) [
				TYPE_INTEGER [int: as red-integer! pos]
				TYPE_WORD  [
					int: as red-integer! _context/get as red-word! pos
					if TYPE_OF(int) <> TYPE_INTEGER [
						throw-draw-error cmds cmd
					]
				]
				default [throw-draw-error cmds cmd]
			]
			OS-draw-line-width DC int/value
			pos
		]
		
		draw-pen: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
				color [red-tuple!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]
			
			switch TYPE_OF(pos) [
				TYPE_TUPLE [color: as red-tuple! pos]
				TYPE_WORD  [
					color: as red-tuple! _context/get as red-word! pos
					if TYPE_OF(color) <> TYPE_TUPLE [
						throw-draw-error cmds cmd
					]
				]
				default [throw-draw-error cmds cmd]
			]
			OS-draw-pen DC color/array1
			pos
		]
		
		draw-fill-pen: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
				color [red-tuple!]
				w	  [red-word!]
				value [integer!]
				off?  [logic!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]
			off?: no

			switch TYPE_OF(pos) [
				TYPE_TUPLE [color: as red-tuple! pos value: color/array1]
				;TYPE_IMAGE [img: as red-image! pos]
				TYPE_WORD  [
					w: as red-word! pos
					either _off = symbol/resolve w/symbol [
						value: -1
						off?: yes
					][
						color: as red-tuple! _context/get as red-word! pos
						if TYPE_OF(color) <> TYPE_TUPLE [
							throw-draw-error cmds cmd
						]
						value: color/array1
					]
				]
				default [throw-draw-error cmds cmd]
			]
			OS-draw-fill-pen DC value off?
			pos
		]
		
		draw-box: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_INTEGER][	;-- optional radius argument
				pos: pos - 1
			]
			OS-draw-box DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]
		
		draw-triangle: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			OS-draw-triangle DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]
		
		draw-polygon: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			while [all [TYPE_OF(pos) = TYPE_PAIR pos < tail]][
				pos: pos + 1
			]
			pos: pos - 1
			
			OS-draw-polygon DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]
		
		draw-circle: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_INTEGER][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_INTEGER][	;-- optional radius-y argument
				pos: pos - 1
			]
			OS-draw-circle DC as red-pair! cmd + 1 as red-integer! pos
			pos
		]

		draw-ellipse: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			OS-draw-ellipse DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]

		draw-curve: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
				w	[red-word!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][		;-- optional point 4
				pos: pos - 1
			]
			OS-draw-curve DC as red-pair! cmd + 1 as red-pair! pos
			pos
		]

		draw-arc: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	[red-value!]
				w	[red-word!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_INTEGER][	;-- angle-begin argument
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_INTEGER][	;-- angle-length argument
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_WORD][		;-- optional closed argument
				pos: pos - 1
			]
			w: as red-word! pos
			if all [TYPE_OF(w) = TYPE_WORD closed <> symbol/resolve w/symbol][
				pos: pos - 1
			]
			OS-draw-arc DC as red-pair! cmd + 1 as red-value! pos
			pos
		]

		draw-anti-alias: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
				w	  [red-word!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]

			either TYPE_OF(pos) = TYPE_WORD  [
				w: as red-word! pos
				OS-draw-anti-alias DC either _off = symbol/resolve w/symbol [no][yes]
			][throw-draw-error cmds cmd]
			pos
		]

		draw-font: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				font [red-value!]
				pos	 [red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]

			font: pos
			if TYPE_OF(pos) = TYPE_WORD [
				font: _context/get as red-word! pos
			]
			if TYPE_OF(font) <> TYPE_OBJECT [throw-draw-error cmds cmd]

			OS-draw-font DC as red-object! font
			pos
		]

		draw-text: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
		][
			pos: cmd + 1								;-- skip the keyword
			if any [pos >= tail TYPE_OF(pos) <> TYPE_PAIR][
				throw-draw-error cmds cmd
			]
			pos: pos + 1
			if any [pos >= tail TYPE_OF(pos) <> TYPE_STRING][
				throw-draw-error cmds cmd
			]
			OS-draw-text DC as red-pair! cmd + 1 as red-string! pos
			pos
		]

		draw-line-join: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
				mode  [red-word!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]
			
			either TYPE_OF(pos) = TYPE_WORD  [
				mode: as red-word! pos
			][throw-draw-error cmds cmd]

			OS-draw-line-join DC symbol/resolve mode/symbol
			pos
		]

		draw-line-cap: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos	  [red-value!]
				mode  [red-word!]
		][
			pos: cmd + 1								;-- skip the keyword
			if pos >= tail [throw-draw-error cmds cmd]
			
			either TYPE_OF(pos) = TYPE_WORD  [
				mode: as red-word! pos
			][throw-draw-error cmds cmd]

			OS-draw-line-cap DC symbol/resolve mode/symbol
			pos
		]

		draw-image: func [
			DC		[handle!]
			cmds	[red-block!]
			cmd		[red-value!]
			tail	[red-value!]
			return: [red-value!]
			/local
				pos			[red-value!]
				w			[red-word!]
				sym			[integer!]
				image		[red-image!]
				upper-left	[red-pair!]
				key-color	[red-tuple!]
				border?		[logic!]
				pattern		[red-word!]
		][
			pos:		cmd
			image:		null
			upper-left: null
			border?:	no
			key-color:	null
			pattern:	null
			while [pos: pos + 1 pos < tail][
				switch TYPE_OF(pos) [
					TYPE_IMAGE [
						image: as red-image! pos
					]
					TYPE_PAIR [
						upper-left: as red-pair! pos
						until [
							pos: pos + 1
							TYPE_OF(pos) <> TYPE_PAIR
						]
						pos: pos - 1
					]
					TYPE_TUPLE [key-color: as red-tuple! pos]
					TYPE_WORD [
						w: as red-word! pos
						either cmd + 1 = pos [
							image: as red-image! _context/get w
						][
							sym: symbol/resolve w/symbol
							case [
								sym = border [border?: yes]
								any [sym = repeat sym = reflect][
									pattern: as red-word! pos
									;@@ TBD check if followed by four integers
								]
								true [
									break
								]
							]
						]
					]
					default [break]
				]
			]

			if null? image [throw-draw-error cmds cmd]
			OS-draw-image DC image upper-left key-color border? pattern
			pos - 1
		]

		do-draw: func [
			handle		[handle!]
			img			[red-image!]
			cmds		[red-block!]
			on-graphic? [logic!]
			cache?		[logic!]
			paint?		[logic!]
			/local
				cmd	   [red-value!]
				tail   [red-value!]
				pos	   [red-value!]
				w	   [red-word!]
				DC	   [handle!]						;-- drawing context (opaque handle)
				sym	   [integer!]
		][
			if all [
				null? handle
				any [TYPE_OF(cmds) <> TYPE_BLOCK zero? block/rs-length? cmds]
			][exit]

			DC: draw-begin handle img on-graphic? paint?

			if TYPE_OF(cmds) = TYPE_BLOCK [
				cmd:  block/rs-head cmds
				tail: block/rs-tail cmds
				
				while [cmd < tail][
					w: as red-word! cmd
					if TYPE_OF(w) <> TYPE_WORD [throw-draw-error cmds cmd]
					sym: symbol/resolve w/symbol
					
					case [
						sym = pen		 [cmd: draw-pen			DC cmds cmd tail]
						sym = box		 [cmd: draw-box			DC cmds cmd tail]
						sym = line		 [cmd: draw-line		DC cmds cmd tail]
						sym = line-width [cmd: draw-line-width	DC cmds cmd tail]
						sym = fill-pen	 [cmd: draw-fill-pen	DC cmds cmd tail]
						sym = triangle	 [cmd: draw-triangle	DC cmds cmd tail]
						sym = _polygon	 [cmd: draw-polygon		DC cmds cmd tail]
						sym = circle	 [cmd: draw-circle		DC cmds cmd tail]	
						sym = _ellipse	 [cmd: draw-ellipse		DC cmds cmd tail]	
						sym = anti-alias [cmd: draw-anti-alias	DC cmds cmd tail]
						sym = font		 [cmd: draw-font		DC cmds cmd tail]
						sym = text		 [cmd: draw-text		DC cmds cmd tail]
						sym = _arc		 [cmd: draw-arc			DC cmds cmd tail]
						sym = curve		 [cmd: draw-curve		DC cmds cmd tail]
						sym = line-join	 [cmd: draw-line-join	DC cmds cmd tail]
						sym = line-cap	 [cmd: draw-line-cap	DC cmds cmd tail]
						sym = _image	 [cmd: draw-image		DC cmds cmd tail]
						true 			 [throw-draw-error cmds cmd]
					]
					cmd: cmd + 1
				]
			]

			draw-end DC handle on-graphic? cache? paint?
		]
	]
]

draw: function [
	"Draws scalable vector graphics to an image"
	image [image! pair!] "Image or size for an image"
	cmd	  [block!] "Draw commands"
][
	if pair? image [
		image: make image! image
	]
	system/view/platform/draw-image image cmd
]