Red [
	Title:   "View Interface Dialect"
	Author:  "Nenad Rakocevic"
	File: 	 %VID.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

system/view/VID: context [
	styles: #include %styles.red
	
	focal-face: none
	reactors: make block! 20
	
	default-font: [
		name	system/view/fonts/system
		size	system/view/fonts/size
		color	black
	]
	
	throw-error: func [spec [block!]][
		either system/view/silent? [
			throw 'silent
		][
			cause-error 'script 'vid-invalid-syntax [copy/part spec 3]
		]
	]
	
	process-reactors: function [][
		foreach [f blk] reactors [
			either f [
				bind blk ctx: context [face: f]
				react/with blk ctx
			][
				react blk
			]
		]
		clear reactors
	]
	
	calc-size: function [face [object!]][
		case [
			all [
				block? data: face/data
				not empty? data 
				find [text-list drop-list drop-down] face/type
			][
				min-sz: 0x0
				foreach txt data [
					if string? txt [
						size: size-text/with face txt
						if size/x > min-sz/x [min-sz/x: size/x]
						if size/y > min-sz/y [min-sz/y: size/y]
					]
				]
				if all [face/text face/type <> 'drop-list][
					size: size-text face
					if size/x > min-sz/x [min-sz/x: size/x]
					if size/y > min-sz/y [min-sz/y: size/y]
				]
				min-sz + 24x0							;@@ hardcoded offset for scrollbar
			]
			all [face/type = 'area string? face/text not empty? face/text][
				len: 0
				parse mark: face/text [
					any [s: to [CR | end] e: (if len < new: offset? s e [len: new mark: s]) opt LF skip]
				]
				size-text/with face copy/part mark len
			]
			'else [either face/text [size-text face][size-text/with face "X"]]
		]
	]
	
	process-draw: function [code [block!]][
		parse code rule: [
			any [
				pos: issue! (if color: hex-to-rgb pos/1 [pos/1: color])
				| set-word! (set pos/1 next pos)		;-- preset set-words
				| any-string! | any-path!
				| into rule
				| skip
			]
		]
		code
	]
	
	pre-load: function [value][
		if word? value [attempt [value: get value]]
		if all [issue? value not color: hex-to-rgb value][
			throw-error reduce [value]
		]
		if color [value: color]
		if find [file! url!] type?/word value [value: load value]
		value
	]
	
	add-option: function [opts [object!] spec [block!]][
		either block? opts/options [
			foreach [field value] spec [put opts/options field value]
		][
			opts/options: copy spec
		]
		last spec
	]

	add-flag: function [obj [object!] facet [word!] field [word!] flag return: [logic!]][
		unless obj/:facet [
			obj/:facet: make get select [font font! para para!] facet []
			if field = 'color [obj/font/color: none]	;-- fixes #1458
		]
		obj: obj/:facet
		
		make logic! either blk: obj/:field [
			unless block? blk [obj/:field: blk: reduce [blk]]
			alter blk flag
		][
			obj/:field: flag
		]
	]													;-- returns TRUE if added
	
	fetch-value: function [blk][
		value: blk/1
		any [all [any [word? :value path? :value] get :value] value]
	]
	
	fetch-argument: function [expected [datatype! typeset!] 'pos [word!]][
		spec: next get pos
		either any [
			expected = type: type? value: spec/1
			all [typeset? expected find expected type]
		][
			value
		][
			unless all [
				any [type = word! type = path!]
				value: get value
				any [
					all [datatype? expected expected = type? value]
					all [typeset? expected find expected type? value]
				]
			][throw-error spec]
		]
		set pos spec
		value
	]
	
	fetch-options: function [
		face [object!] opts [object!] style [block!] spec [block!] css [block!]
		/extern focal-face
		return: [block!]
	][
		opt?: 	 yes
		divides: none
		calc-y?: no
		
		obj-spec!:	make typeset! [block! object!]
		rate!:		make typeset! [integer! time!]
		color!:		make typeset! [tuple! issue!]
		
		set opts none
		
		;-- process style options --
		until [
			value: first spec: next spec
			match?: parse spec [[
				  ['left | 'center | 'right]	 (opt?: add-flag opts 'para 'align value)
				| ['top  | 'middle | 'bottom]	 (opt?: add-flag opts 'para 'v-align value)
				| ['bold | 'italic | 'underline] (opt?: add-flag opts 'font 'style value)
				| 'extra	  (opts/extra: fetch-value spec: next spec)
				| 'data		  (opts/data: fetch-value spec: next spec)
				| 'draw		  (opts/draw: process-draw fetch-argument block! spec)
				| 'font		  (opts/font: make any [opts/font font!] fetch-argument obj-spec! spec)
				| 'para		  (opts/para: make any [opts/para para!] fetch-argument obj-spec! spec)
				| 'wrap		  (opt?: add-flag opts 'para 'wrap? yes)
				| 'no-wrap	  (opt?: add-flag opts 'para 'wrap? no)
				| 'focus	  (focal-face: face)
				| 'font-name  (add-flag opts 'font 'name  fetch-argument string! spec)
				| 'font-size  (add-flag opts 'font 'size  fetch-argument integer! spec)
				| 'font-color (add-flag opts 'font 'color pre-load fetch-argument color! spec)
				| 'react	  (append reactors reduce [face fetch-argument block! spec])
				| 'loose	  (add-option opts [drag-on: 'down])
				| 'all-over   (set-flag opts 'flags 'all-over)
				| 'hidden	  (opts/visible?: no)
				| 'disabled	  (opts/enable?: no)
				| 'select	  (opts/selected: fetch-argument integer! spec)
				| 'rate		  (opts/rate: fetch-argument rate! spec)
				   opt [rate! 'now (opts/now?: yes spec: next spec)]
				| 'default 	  (opts/data: add-option opts append copy [default: ] fetch-value spec: next spec)
				| 'no-border  (set-flag opts 'flags 'no-border)
				| 'space	  (opt?: no)				;-- avoid wrongly reducing that word
				] to end
			]
			unless match? [
				either all [word? value find/skip next system/view/evt-names value 2][
					make-actor opts value spec/2 spec spec: next spec
				][
					opt?: switch/default type?/word value: pre-load value [
						pair!	 [unless opts/size  [opts/size:  value]]
						string!	 [unless opts/text  [opts/text:  value]]
						percent! [unless opts/data  [opts/data:  value]]
						image!	 [unless opts/image [opts/image: value]]
						tuple!	 [
							either opts/color [
								add-flag opts 'font 'color value
							][
								opts/color: value
							]
						]
						integer! [
							unless opts/size [
								either find [panel group-box] face/type [
									divides: value
								][
									opts/size: as-pair value face/size/y
									calc-y?: yes		;-- force size/y calculation
								]
							]
						]
						block!	 [
							switch/default face/type [
								panel	  [layout/parent/styles value face divides css]
								group-box [layout/parent/styles value face divides css]
								tab-panel [
									face/pane: make block! (length? value) / 2
									opts/data: extract value 2
									max-sz: 0x0
									foreach p extract next value 2 [
										layout/parent/styles reduce ['panel copy p] face divides css
										p: last face/pane
										if p/size/x > max-sz/x [max-sz/x: p/size/x]
										if p/size/y > max-sz/y [max-sz/y: p/size/y]
									]
									unless opts/size [opts/size: max-sz + 0x25] ;@@ extract the right metrics from OS
								]
							][make-actor opts style/default-actor spec/1 spec]
							yes
						]
						get-word! [make-actor opts style/default-actor spec/1 spec]
						char!	  [yes]
					][no]
				]
			]
			any [not opt? tail? spec]
		]
		unless opt? [spec: back spec]

		if all [opts/image not opts/size][opts/size: opts/image/size]
		
		font: opts/font
		
		if any [face-font: face/font font][
			unless face-font [face-font: face/font: make font! []]
			foreach [field value] default-font [
				if none? face-font/:field [face-font/:field: get value]
			]
		]
		if all [font face/font][set/some opts/font: face/font font] ;-- merge face and opts font objects
		
		set/some face opts
		
		if block? face/actors [face/actors: make object! face/actors]
		
		if all [any [calc-y? not opts/size] any [calc-y? opts/text opts/data] min-size: calc-size face][
			if all [not calc-y? face/size/x < min-size/x][face/size/x: min-size/x + 10]	;@@ hardcoded margins
			if face/size/y < min-size/y [face/size/y: min-size/y + 10]	;@@ not taking widgets margins into account
		]
		spec
	]
	
	make-actor: function [obj [object!] name [word!] body spec [block!]][
		unless any [name block? body][throw-error spec]
		unless obj/actors [obj/actors: make block! 4]
		
		append obj/actors load append form name #":"	;@@ to set-word!
		append obj/actors either get-word? body [body][
			reduce [
				'func [face [object!] event [event! none!]]
				copy/deep body
			]
		]
	]
	
	set 'layout function [
		"Return a face with a pane built from a VID description"
		spec		  [block!]	"Dialect block of styles, attributes, and layouts"
		/tight					"Zero offset and origin"
		/options
			user-opts [block!]	"Optional features in [name: value] format"
		/flags
			flgs [block! word!]	"One or more window flags"
		/only					"Returns only the pane block"
		/parent
			panel	  [object!]
			divides   [integer! none!]
		/styles					"Use an existing styles list"
			css		  [block!]	"Styles list"
		/local axis anti								;-- defined in a SET block
		/extern focal-face
	][
		background!:  make typeset! [image! file! tuple! word! issue!]
		list:		  make block! 4						;-- panel's pane block
		local-styles: any [css make block! 2]			;-- panel-local styles definitions
		pane-size:	  0x0								;-- panel's content dynamic size
		direction: 	  'across
		size:		  none								;-- user-set panel's size
		max-sz:		  0									;-- maximum width/height of current column/row
		current:	  0									;-- layout's cursor position
		global?: 	  yes								;-- TRUE: panel options expected
		
		cursor:	origin: spacing: pick [0x0 10x10] tight
		
		opts: object [
			type: offset: size: text: color: enable?: visible?: selected: image: 
			rate: font: flags: options: para: data: extra: actors: draw: now?: none
		]
		
		reset: [
			cursor: as-pair origin/:axis cursor/:anti + max-sz + spacing/:anti
			if direction = 'below [cursor: reverse cursor]
			max-sz: 0
		]
		
		unless panel [
			focal-face: none
			panel: make face! system/view/VID/styles/window/template  ;-- absolute path to avoid clashing with /styles
		]
		
		while [all [global? not tail? spec]][			;-- process wrapping panel options
			switch/default spec/1 [
				title	 [panel/text: fetch-argument string! spec]
				size	 [size: fetch-argument pair! spec]
				backdrop [
					value: pre-load fetch-argument background! spec
					switch type?/word value [
						tuple! [panel/color: value]
						image! [panel/image: value]
					]
				]
			][global?: no]
			
			if global? [spec: next spec]
		]
		
		while [not tail? spec][							;-- process panel's content
			value: spec/1
			set [axis anti] pick [[x y][y x]] direction = 'across
			
			switch/default value [
				across	[direction: value]				;@@ fix this
				below	[direction: value]
				space	[spacing: fetch-argument pair! spec]
				origin	[origin: cursor: fetch-argument pair! spec]
				at		[at-offset: fetch-argument pair! spec]
				pad		[cursor: cursor + fetch-argument pair! spec]
				do		[do-safe bind fetch-argument block! spec panel]
				return	[either divides [throw-error spec][do reset]]
				react	[repend reactors [none fetch-argument block! spec]]
				style	[
					unless set-word? name: first spec: next spec [throw-error spec]
					styling?: yes
				]
			][
				unless styling? [
					name: none
					if set-word? value [
						name: value
						value: first spec: next spec
					]
				]
				unless style: any [
					select local-styles value
					select system/view/VID/styles value
				][
					throw-error spec
				]
				if style/template/type = 'window [throw-error spec]
				face: make face! copy/deep style/template
				spec: fetch-options face opts style spec local-styles
				if style/init [do bind style/init 'face]
				
				either styling? [
					if same? css local-styles [local-styles: copy css]
					name: to word! form name
					value: copy style
					parse value/template: body-of face [
						some [remove [set-word! [none! | function!]] | skip]
					]
					either pos: find local-styles name [pos/2: value][ 
						reduce/into [name value] tail local-styles
					]
					styling?: off
				][
					;-- update cursor position --
					either at-offset [
						face/offset: at-offset
						at-offset: none
					][
						either all [
							divide?: all [divides divides <= length? list]
							zero? index: (length? list) // divides
						][
							do reset
						][
							if cursor/:axis <> origin/:axis [
								cursor/:axis: cursor/:axis + spacing/:axis
							]
						]
						max-sz: max max-sz face/size/:anti
						face/offset: cursor
						cursor/:axis: cursor/:axis + face/size/:axis
						
						if all [divide? index > 0][
							index: index + 1
							face/offset/:axis: list/:index/offset/:axis
						]
					]
					append list face
					if name [set name face]

					box: face/offset + face/size + spacing
					if box/x > pane-size/x [pane-size/x: box/x]
					if box/y > pane-size/y [pane-size/y: box/y]
					
					if opts/now? [do-actor face none 'time]
				]
			]
			spec: next spec
		]
		process-reactors						;-- Needs to be after [set name face]
		
		either block? panel/pane [append panel/pane list][
			unless only [panel/pane: list]
		]
		either size [panel/size: size][
			if pane-size <> 0x0 [panel/size: pane-size - spacing + origin]
		]
		if image: panel/image [
			x: image/size/x
			y: image/size/y
			if panel/size/x < x [panel/size/x: x]
			if panel/size/y < y [panel/size/y: y]
		]

		if all [focal-face not parent][panel/selected: focal-face]
		
		if options [set/some panel make object! user-opts]
		if flags [spec/flags: either spec/flags [unique union spec/flags flgs][flgs]]
		
		either only [list][panel]
	]
]
