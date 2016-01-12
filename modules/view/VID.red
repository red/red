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
	#include %styles.red
	
	reactors: make block! 20
	
	default-font: [name "Tahoma" size 9 color 'black]
	
	throw-error: func [spec [block!]][
		cause-error 'script 'vid-invalid-syntax [mold copy/part spec 3]
	]
	
	react-ctx: context [face: none]
	
	process-reactors: function [][
		foreach [f blk] reactors [
			bind blk ctx: make react-ctx [face: f]
			react/with blk ctx
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
	
	pre-load: func [value][
		if word? value [attempt [value: get value]]
		if find [file! url!] type?/word value [value: load value]
		value
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
	
	fetch-value: function [blk][
		value: blk/1
		any [all [word? :value get :value] value]
	]
	
	fetch-argument: function [expected [datatype! typeset!] spec [block!]][
		either expected = type: type? value: spec/1 [
			value
		][
			if all [
				type = word!
				value: get value
				any [
					all [datatype? expected expected = type? value]
					all [typeset? expected find expected type? value]
				]
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
				| 'extra	  (opts/extra: fetch-value spec: next spec)
				| 'data		  (opts/data: fetch-value spec: next spec)
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
					opt?: switch/default type?/word value: pre-load value [
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
				if none? font/:field [font/:field: value]
			]
		]
		set/some face opts
		
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
		spec		  [block!]	"Dialect block of styles, attributes, and layouts"
		/tight					"Zero offset and origin"
		/options
			user-opts [block!]	"Optional features in [name: value] format"
		/flags
			flgs [block! word!]	"One or more window flags"
		/parent
			panel	  [object!]
			divides   [integer! none!]
		/local axis anti								;-- defined in a SET block
	][
		background!:  make typeset! [image! file! tuple! word!]
		list:		  make block! 4						;-- panel's pane block
		local-styles: make block! 2						;-- panel-local styles definitions
		pane-size:	  0x0								;-- panel's content dynamic size
		direction: 	  'across
		max-sz:		  0									;-- maximum width/height of current column/row
		current:	  0									;-- layout's cursor position
		global?: 	  yes								;-- TRUE: panel options expected
		
		cursor:	origin: spacing: pick [0x0 10x10] tight
		react-ctx/face: none
		clear reactors
		
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
		
		while [all [global? not tail? spec]][			;-- process wrapping panel options
			switch/default spec/1 [
				title	 [panel/text: fetch-argument string! spec: next spec]
				size	 [panel/size: fetch-argument pair! spec: next spec]
				backdrop [
					value: pre-load fetch-argument background! spec: next spec
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
				space	[spacing: fetch-argument pair! spec: next spec]
				origin	[origin: cursor: fetch-argument pair! spec: next spec]
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
		if options [set panel make object! user-opts]
		if flags [spec/flags: either spec/flags [unique union spec/flags flgs][flgs]]
		
		unless parent [process-reactors]
		panel
	]
]