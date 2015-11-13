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
			template: [type: 'window size: 300x300]
		]
		base: [
			default-actor: on-click
			template: [type: 'base size: 80x80]
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
			template: [type: 'image size: 100x100]
		]
		camera: [
			default-actor: on-down
			template: [type: 'camera size: 250x250]
		]
		text-list: [
			default-actor: on-select
			template: [type: 'text-list size: 100x140]
		]
		drop-list: [
			default-actor: on-select
			template: [type: 'drop-list size: 100x24]
		]
		drop-down: [
			default-actor: on-select
			template: [type: 'drop-down size: 100x24]
		]
		panel: [
			default-actor: on-click						;@@ something better?
			template: [type: 'panel size: 200x200]
		]
		group-box: [
			default-actor: on-click						;@@ something better?
			template: [type: 'group-box size: 200x200]
		]
		tab-panel: [
			default-actor: on-select
			template: [type: 'tab-panel size: 200x200]
		]
	)
	
	default-font: [name "Tahoma" size 9 color 'black]
	
	raise-error: func [spec [block!]][
		cause-error 'script 'vid-invalid-syntax [mold copy/part spec 3]
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
			raise-error spec
		]
	]
	
	fetch-options: function [face [object!] opts [object!] style [block!] spec [block!] return: [block!]][
		set opts none
		opt?: yes
		
		;-- process style options --
		until [
			value: first spec: next spec
			case [
				find [left center right] value [
					opt?: add-flag opts 'para 'align value
				]
				find [top middle bottom] value [
					opt?: add-flag opts 'para 'v-align value
				]
				find [bold italic underline] value [
					opt?: add-flag opts 'font 'style value
				]
				value = 'data [opts/data: first spec: next spec]
				value = 'font [opts/font: make font! fetch-argument block! spec: next spec]
				value = 'para [opts/para: make para! fetch-argument block! spec: next spec]

				all [word? value find/skip next system/view/evt-names value 2][
					make-actor opts value spec/2 spec spec: next spec
				]
				'else [
					if word? value [attempt [value: get value]]
					if find [file! url!] type?/word value [value: load value]

					opt?: switch/default type?/word value [
						integer! [unless opts/size  [opts/size:  as-pair value face/size/y]]
						pair!	 [unless opts/size  [opts/size:  value]]
						tuple!	 [unless opts/color [opts/color: value]]
						string!	 [unless opts/text  [opts/text:  value]]
						percent! [unless opts/data  [opts/data:  value]]
						image!	 [unless opts/image [opts/image: value]]
						block!	 [
							switch/default face/type [
								panel	  [layout/parent value face]
								group-box [layout/parent value face]
								tab-panel [
									face/pane: make block! (length? value) / 2
									opts/data: extract value 2
									foreach p extract next value 2 [
										layout/parent reduce ['panel copy p] face
									]
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
		;if all [not opts/size opts/text][face/size: spacing + size-text face]
		spec
	]
	
	make-actor: function [obj [object!] name [word!] body spec [block!]][
		unless any [name block? body][raise-error spec]
		unless obj/actors [obj/actors: make block! 4]
		
		append obj/actors reduce [
			load append form name #":"	;@@ to set-word!
			'func [face [object!] event [event!]]
			body
		]
	]
	
	set 'layout function [
		"Return a face with a pane built from a VID description"
		spec [block!]
		/parent panel [object!]
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
			extra: actors: none
		]
		
		unless panel [panel: make face! styles/window/template]
		
		while [not tail? spec][
			value: spec/1
			
			switch/default value [
				across	[direction: value]				;@@ fix this
				below	[direction: value]
				title	[panel/text: fetch-argument string! spec: next spec]
				space	[spacing: fetch-argument pair! spec: next spec]
				origin	[cursor: fetch-argument pair! spec: next spec]
				return	[
					cursor: either direction = 'across [
						as-pair origin/x cursor/y + max-sz + spacing/y
					][
						as-pair cursor/x + max-sz + spacing/x origin/y
					]
					max-sz: 0
				]
				at		[at-offset: fetch-argument pair! spec: next spec]
				pad		[cursor: cursor + fetch-argument pair! spec: next spec]
				style	[
					unless set-word? name: first spec: next spec [raise-error spec]
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
					raise-error spec
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
						either direction = 'across [
							if cursor/x <> origin/x [cursor/x: cursor/x + spacing/x]
							max-sz: max max-sz face/size/y
							face/offset: cursor
							cursor/x: cursor/x + face/size/x
						][
							if cursor/y <> origin/y [cursor/y: cursor/y + spacing/y]
							max-sz: max max-sz face/size/x
							face/offset: cursor
							cursor/y: cursor/y + face/size/y
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
		either block? panel/pane [append panel/pane list][panel/pane: list]
		
		unless parent [
			;center-face panel
			if pane-size <> 0x0 [panel/size: pane-size]
		]
		panel
	]
]