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
		line:	symbol/make "line"
		box:	symbol/make "box"
		pen:	symbol/make "pen"

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

		do-draw: func [
			handle [handle!]
			cmds   [red-block!]
			/local
				cmd	   [red-value!]
				tail   [red-value!]
				base   [red-value!]
				pos	   [red-value!]
				w	   [red-word!]
				DC	   [handle!]						;-- drawing context (opaque handle)
				sym	   [integer!]
				
		][
			cmd:  block/rs-head cmds
			tail: block/rs-tail cmds
			base: cmd

			DC: draw-begin handle
			
			while [cmd < tail][
				w: as red-word! cmd
				if TYPE_OF(w) <> TYPE_WORD [throw-draw-error cmds cmd]
				sym: symbol/resolve w/symbol
				case [
					sym = line [ 
						pos: cmd + 1					;-- skip the keyword
						while [all [TYPE_OF(pos) = TYPE_PAIR pos < tail]][
							pos: pos + 1
						]
						pos: pos - 1
						if cmd + 2 > pos [throw-draw-error cmds cmd]
						draw-line DC handle as red-pair! cmd + 1 as red-pair! pos
						cmd: pos
					]
					sym = box [
						0
					]
					sym = pen [
						0
					]
					true [
						0 ;; throw error
					]
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