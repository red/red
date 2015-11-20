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
	styles: #(
		window: [
			default-actor: on-click
			template: [type: 'window]
		]
		base: [
			default-actor: on-click
			template: [type: 'base size: 80x80 color: 128.128.128]
		]
		button: [
			default-actor: on-click
			template: [type: 'button size: 60x30]
		]
		text: [
			default-actor: on-change
			template: [type: 'text size: 80x24]
		]
		field: [
			default-actor: on-change					;@@ on-enter?
			template: [type: 'field size: 80x24]
		]
		area: [
			default-actor: on-change					;@@ on-enter?
			template: [type: 'area size: 150x150]
		]
		check: [
			default-actor: on-change
			template: [type: 'check size: 80x24]
		]
		radio: [
			default-actor: on-change
			template: [type: 'radio size: 80x24]
		]
		progress: [
			default-actor: on-change
			template: [type: 'progress size: 140x16]
		]
		slider: [
			default-actor: on-change
			template: [type: 'slider size: 150x24]
		]
		image: [
			default-actor: on-down
			template: [type: 'base size: 100x100]
		]
		camera: [
			default-actor: on-down
			template: [type: 'camera size: 250x250]
		]
		text-list: [
			default-actor: on-change
			template: [type: 'text-list size: 100x140]
		]
		drop-list: [
			default-actor: on-change
			template: [type: 'drop-list size: 100x24]
		]
		drop-down: [
			default-actor: on-change
			template: [type: 'drop-down size: 100x24]
		]
		panel: [
			default-actor: on-click						;@@ something better?
			template: [type: 'panel]
		]
		group-box: [
			default-actor: on-click						;@@ something better?
			template: [type: 'group-box]
		]
		tab-panel: [
			default-actor: on-select
			template: [type: 'tab-panel]
		]
	)
	
	reactors: make block! 20
	
	default-font: [name "Tahoma" size 9 color 'black]
	
	throw-error: func [spec [block!]][
		cause-error 'script 'vid-invalid-syntax [mold copy/part spec 3]
	]
	
	react-ctx: context [face: none]
	
	process-reactors: function [][
		foreach [f blk] reactors [
			bind blk ctx: make react-ctx [face: f]
			
			parse blk rule: [
				any [
					item: [path! | lit-path! | get-path!] (
						if unset? get/any item: item/1 [
							cause-error 'script 'no-value [item]
						]
						if all [
							object? obj: get item/1
							in obj 'type
							in obj 'offset
						][
							append system/view/reactors reduce [obj item/2 blk ctx]
						]
					)
					| set-path!
					| into rule
					| skip
				]
			]
		]
	]
	
	calc-size: function [face [object!]][
		either all [
			block? data: face/data
			not empty? data 
			find [text-list drop-list drop-down] face/type
		][
			saved: face/text
			min-sz: 0x0
			foreach txt data [
				face/text: txt
				size: size-text face
				if size/x > min-sz/x [min-sz/x: size/x]
				if size/y > min-sz/y [min-sz/y: size/y]
			]
			face/text: saved
			size: size-text face
			if size/x > min-sz/x [min-sz/x: size/x]
			if size/y > min-sz/y [min-sz/y: size/y]
			min-sz
		][
			size-text face
		]
	]

	add-flag: function [obj [object!] facet [word!] field [word!] flag return: [logic!]][
		unless obj/:facet [
			obj/:facet: make get select [font font! para para!] facet []
		]
		obj: obj/:facet
		
		make logic! either blk: obj/:field [
			unless block? blk [obj/:field: blk: reduce [blk]]
			alter blk flag
		][
			obj/:field: flag
		]
	]													;-- returns TRUE if added
	
	fetch-argument: function [expected [datatype!] spec [block!]][
		either expected = type: type? value: spec/1 [
			value
		][
			if all [
				type = word!
				expected = type? value: get value 
			][
				return value
			]
			throw-error spec
		]
	]
	
	fetch-options: function [face [object!] opts [object!] style [block!] spec [block!] return: [block!]][
		set opts none
		opt?: yes
		divides: none
		
		;-- process style options --
		until [
			value: first spec: next spec
			match?: parse spec [[
				  ['left | 'center | 'right]	 (opt?: add-flag opts 'para 'align value)
				| ['top  | 'middle | 'bottom]	 (opt?: add-flag opts 'para 'v-align value)
				| ['bold | 'italic | 'underline] (opt?: add-flag opts 'font 'style value)
				| 'extra	  (opts/extra: first spec: next spec)
				| 'data		  (opts/data:  first spec: next spec)
				| 'draw		  (opts/draw: fetch-argument block! spec: next spec)
				| 'font		  (opts/font: make font! fetch-argument block! spec: next spec)
				| 'para		  (opts/para: make para! fetch-argument block! spec: next spec)
				| 'wrap		  (opt?: add-flag opts 'para 'wrap? yes)
				| 'no-wrap	  (opt?: add-flag opts 'para 'wrap? no)
				| 'font-size  (add-flag opts 'font 'size  fetch-argument integer! spec: next spec)
				| 'font-color (add-flag opts 'font 'color fetch-argument tuple! spec: next spec)
				| 'font-name  (add-flag opts 'font 'name  fetch-argument string! spec: next spec)
				| 'react	  (append reactors reduce [face fetch-argument block! spec: next spec])
				] to end
			]
			unless match? [
				either all [word? value find/skip next system/view/evt-names value 2][
					make-actor opts value spec/2 spec spec: next spec
				][
					if word? value [attempt [value: get value]]
					if find [file! url!] type?/word value [value: load value]

					opt?: switch/default type?/word value [
						pair!	 [unless opts/size  [opts/size:  value]]
						tuple!	 [unless opts/color [opts/color: value]]
						string!	 [unless opts/text  [opts/text:  value]]
						percent! [unless opts/data  [opts/data:  value]]
						image!	 [unless opts/image [opts/image: value]]
						integer! [
							unless opts/size [
								either find [panel group-box] face/type [
									divides: value
								][
									opts/size: as-pair value face/size/y
								]
							]
						]
						block!	 [
							switch/default face/type [
								panel	  [layout/parent value face divides]
								group-box [layout/parent value face divides]
								tab-panel [
									face/pane: make block! (length? value) / 2
									opts/data: extract value 2
									max-sz: 0x0
									foreach p extract next value 2 [
										layout/parent reduce ['panel copy p] face divides
										p: last face/pane
										if p/size/x > max-sz/x [max-sz/x: p/size/x]
										if p/size/y > max-sz/y [max-sz/y: p/size/y]
									]
									unless opts/size [opts/size: max-sz + 0x25] ;@@ extract the right metrics from OS
								]
							][make-actor opts style/default-actor spec/1 spec]
							yes
						]
						char!	 [yes]
					][no]
				]
			]
			any [not opt? tail? spec]
		]
		unless opt? [spec: back spec]

		if font: opts/font [
			foreach [field value] default-font [
				unless font/:field [font/:field: value]
			]
		]
		foreach facet words-of opts [if value: opts/:facet [face/:facet: value]]
		if block? face/actors [face/actors: make object! face/actors]
		
		if all [not opts/size opts/text min-size: calc-size face][
			if face/size/x < min-size/x [face/size/x: min-size/x + 10]	;@@ hardcoded margins
			if face/size/y < min-size/y [face/size/y: min-size/y + 10]	;@@ not taking widgets margins into account
		]
		spec
	]
	
	make-actor: function [obj [object!] name [word!] body spec [block!]][
		unless any [name block? body][throw-error spec]
		unless obj/actors [obj/actors: make block! 4]
		
		append obj/actors reduce [
			load append form name #":"	;@@ to set-word!
			'func [face [object!] event [event! none!]]
			body
		]
	]
	
	set 'layout function [
		"Return a face with a pane built from a VID description"
		spec [block!]
		/parent
			panel	[object!]
			divides [integer! none!]
		/local axis anti								;-- defined in a SET block
	][
		list:		  make block! 4
		local-styles: make block! 2
		pane-size:	  0x0
		direction: 	  'across
		origin:		  10x10
		spacing:	  10x10
		max-sz:	  	  0
		current:	  0
		cursor:		  origin
		
		opts: object [
			type: offset: size: text: color: image: font: para: data:
			extra: actors: draw: none
		]
		
		reset: [
			cursor: as-pair origin/:axis cursor/:anti + max-sz + spacing/:anti
			if direction = 'below [cursor: reverse cursor]
			max-sz: 0
		]
		
		unless panel [panel: make face! styles/window/template]
		
		while [not tail? spec][
			value: spec/1
			set [axis anti] pick [[x y][y x]] direction = 'across
			
			switch/default value [
				across	[direction: value]				;@@ fix this
				below	[direction: value]
				title	[panel/text: fetch-argument string! spec: next spec]
				space	[spacing: fetch-argument pair! spec: next spec]
				origin	[cursor: fetch-argument pair! spec: next spec]
				size	[panel/size: fetch-argument pair! spec: next spec]
				at		[at-offset: fetch-argument pair! spec: next spec]
				pad		[cursor: cursor + fetch-argument pair! spec: next spec]
				do		[do-safe fetch-argument block! spec: next spec]
				return	[do reset]
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
					select styles value
					select local-styles value
				][
					throw-error spec
				]
				face: make face! style/template
				spec: fetch-options face opts style spec
				
				either styling? [
					value: copy style
					parse value/template: body-of face [
						some [remove [set-word! [none! | function!]] | skip]
					]
					reduce/into [to word! form name value] tail local-styles
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
				]
			]
			spec: next spec
		]
		either block? panel/pane [append panel/pane list][
			panel/pane: list
			modify panel/pane 'owned none
		]
		
		unless panel/size [
			panel/size: either pane-size <> 0x0 [pane-size][200x200]
		]
		unless parent [process-reactors]
		panel
	]
]