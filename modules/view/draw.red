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
		line:		symbol/make "line"
		line-width:	symbol/make "line-width"
		box:		symbol/make "box"
		pen:		symbol/make "pen"

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
			pos: cmd + 1					;-- skip the keyword
			
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
			pos: cmd + 1
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
			pos: cmd + 1
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

		do-draw: func [
			handle [handle!]
			cmds   [red-block!]
			/local
				cmd	   [red-value!]
				tail   [red-value!]
				pos	   [red-value!]
				w	   [red-word!]
				DC	   [handle!]						;-- drawing context (opaque handle)
				sym	   [integer!]
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds

			DC: draw-begin handle
			
			while [cmd < tail][
				w: as red-word! cmd
				if TYPE_OF(w) <> TYPE_WORD [throw-draw-error cmds cmd]
				sym: symbol/resolve w/symbol
				case [
					sym = pen		 [cmd: draw-pen  DC cmds cmd tail]
					sym = line		 [cmd: draw-line DC cmds cmd tail]
					sym = line-width [cmd: draw-line-width DC cmds cmd tail]
					sym = box		 [0]
					true 			 [throw-draw-error cmds cmd]
				]
				cmd: cmd + 1
			]
			
			draw-end DC handle
		]
	]
]

draw: function [
	"Draws scalable vector graphics to an image"
	image [image! pair!] "Image or size for an image"
	cmd	  [block!] "Draw commands"
][
	;TBD
]