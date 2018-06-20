Red [
	Title:   "View Interface Dialect"
	Author:  "Nenad Rakocevic"
	File: 	 %VID.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

system/view/VID: context [
	styles: #include %styles.red
	
	GUI-rules: context [
		active?: yes
		debug?:  no
		
		processors: context [
			#include %rules.red
			#switch config/OS [
				Windows [#include %backends/windows/rules.red]
				macOS	[#include %backends/macOS/rules.red]
			]
		]
		
		general: []
		OS: [
			Windows [
				color-backgrounds
				color-tabpanel-children
				OK-Cancel
			]
			macOS [
				adjust-buttons
				capitalize
				Cancel-OK
			]
		]
		user: []
		
		process: function [root [object!]][
			unless active? [exit]
			actions: system/view/VID/GUI-rules/processors
			
			foreach list reduce [general select OS system/platform user][
				foreach name list [
					if debug? [print ["Applying rule:" name]]
					name: get in processors name
					do [name root]
				]
			]
		]
	]
	
	focal-face:	none
	reactors:	make block! 20
	debug?: 	no
	
	containers: [panel tab-panel group-box]
	
	default-font: [
		name	system/view/fonts/system
		size	system/view/fonts/size
	]
	
	opts-proto: object [
		type: offset: size: size-x: text: color: enabled?: visible?: selected: image: 
		rate: font: flags: options: para: data: extra: actors: draw: now?: init: none
	]
	
	throw-error: func [spec [block!]][
		either system/view/silent? [
			throw 'silent
		][
			cause-error 'script 'vid-invalid-syntax [copy/part spec 3]
		]
	]
	
	process-reactors: function [/local res][
		set 'res try/all [
			foreach [f blk later?] reactors [
				either f [
					bind blk ctx: context [face: f]
					either later? [react/later/with blk ctx][react/with blk ctx]
				][
					either later? [react/later blk][react blk]
				]
			]
		]
		clear reactors									;-- ensures clearing even if reaction fails
		if error? :res [do res]
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
					if any-string? txt [min-sz: max min-sz size-text/with face as string! txt]
				]
				if all [face/text face/type <> 'drop-list][
					min-sz: max min-sz size-text face
				]
				s: system/view/metrics/misc/scroller
				either s [as-pair min-sz/x + s/x min-sz/y][min-sz]
			]
			all [face/type = 'area string? face/text not empty? face/text][
				len: 0
				parse mark: face/text [					;-- find the longest line
					any [
						s: thru [CR | LF | end] e:
						(if len < new: offset? s e [len: new mark: s])
						opt LF skip
					]
				]
				size-text/with face copy/part mark len
			]
			'else [either face/text [size-text face][size-text/with face "X"]]
		]
	]
	
	align-faces: function [pane [block!] dir [word!] align [word!] max-sz [integer!]][
		if empty? pane [exit]

		edge?: any [
			all [dir = 'across align <> 'middle]
			all [dir = 'below  align <> 'center]
		]
		top-left?: find [top left] align
		axis:  pick [y x] dir = 'across
		svmm: system/view/metrics/margins

		foreach face pane [
			unless face/options/at-offset [				;-- exclude absolute-positioned faces
				offset: either top-left? [0][max-sz - face/size/:axis]
				mar: select system/view/metrics/margins face/type
				if type: face/options/class [mar: select mar type]
				if mar [
					offset: offset + either dir = 'across [
						switch align [
							top	   [negate mar/2/x]
							middle [to integer! round/floor mar/2/x + mar/2/y / 2.0]
							bottom [mar/2/y]
						]
					][
						switch align [
							left   [negate mar/1/x]
							center [to integer! round/floor mar/1/x + mar/1/y / 2.0]
							right  [mar/1/y]
						]
					]
				]
				if offset <> 0 [
					if find [center middle] align [offset: to integer! round/floor offset / 2.0]
					face/offset/:axis: face/offset/:axis + offset
				]
			]
		]
	]
	
	resize-child-panels: function [tab [object!]][		;-- ensures child panels fit accurately in tab-panels
		if block? tab/pane [
			tp-size: tab/size
			if pad: system/view/metrics/paddings/tab-panel [
				tp-size: tp-size - as-pair pad/1/x + pad/1/y pad/2/x + pad/2/y
			]
			foreach pane tab/pane [pane/size: tp-size]
		]
	]
	
	clean-style: func [tmpl [block!] type [word!] /local para font][ ;-- clean-up template from unwanted live values
		parse tmpl [
			some [remove [set-word! [none! | function!]] | skip]
		]
		if all [para: tmpl/para para/parent][
			tmpl/para: make para [parent: none]
		]
		if all [font: tmpl/font font/parent][
			tmpl/font: make font [parent: state: none]
		]
		if find [field text] type [
			remove/part find tmpl 'data 2
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
		
		make logic! either all [blk: obj/:field facet = 'font field = 'style][
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
	
	fetch-expr: func [code [word!]][do/next next get code code]
	
	fetch-options: function [
		face [object!] opts [object!] style [block!] spec [block!] css [block!] styling? [logic!]
		/no-skip
		/extern focal-face
		return: [block!]
	][
		opt?: 	 yes
		divides: none
		calc-y?: no
		do-with: none
		
		obj-spec!:	make typeset! [block! object!]
		rate!:		make typeset! [integer! time!]
		color!:		make typeset! [tuple! issue!]
		cursor!:	make typeset! [word! lit-word! image!]
		
		set opts none
		
		;-- process style options --
		until [
			unless no-skip [spec: next spec]
			value: first spec
			match?: parse spec [[
				  ['left | 'center | 'right]	 (opt?: add-flag opts 'para 'align value)
				| ['top  | 'middle | 'bottom]	 (opt?: add-flag opts 'para 'v-align value)
				| ['bold | 'italic | 'underline | 'strike] (opt?: add-flag opts 'font 'style value)
				| 'extra	  (opts/extra: fetch-expr 'spec spec: back spec)
				| 'data		  (opts/data: fetch-expr 'spec spec: back spec)
				| 'draw		  (opts/draw: process-draw fetch-expr 'spec spec: back spec)
				| 'font		  (opts/font: make any [opts/font font!] fetch-argument obj-spec! spec)
				| 'para		  (opts/para: make any [opts/para para!] fetch-argument obj-spec! spec)
				| 'wrap		  (opt?: add-flag opts 'para 'wrap? yes)
				| 'no-wrap	  (add-flag opts 'para 'wrap? no opt?: yes)
				| 'focus	  (focal-face: face)
				| 'font-name  (add-flag opts 'font 'name  fetch-argument string! spec)
				| 'font-size  (add-flag opts 'font 'size  fetch-argument integer! spec)
				| 'font-color (add-flag opts 'font 'color pre-load fetch-argument color! spec)
				| 'options	  (add-option opts fetch-argument block! spec)
				| 'loose	  (add-option opts [drag-on: 'down])
				| 'all-over   (set-flag opts 'flags 'all-over)
				| 'hidden	  (opts/visible?: no)
				| 'disabled	  (opts/enabled?: no)
				| 'select	  (opts/selected: fetch-argument integer! spec)
				| 'rate		  (opts/rate: fetch-argument rate! spec)
				   opt [rate! 'now (opts/now?: yes spec: next spec)]
				| 'default 	  (opts/data: add-option opts append copy [default: ] fetch-value spec: next spec)
				| 'no-border  (set-flag opts 'flags 'no-border)
				| 'space	  (opt?: no)				;-- avoid wrongly reducing that word
				| 'hint	  	  (add-option opts compose [hint: (fetch-argument string! spec)])
				| 'cursor	  (add-option opts compose [cursor: (pre-load fetch-argument cursor! spec)])
				| 'init		  (opts/init: fetch-argument block! spec)
				| 'with		  (do-with: fetch-argument block! spec)
				| 'tight	  (if opts/text [tight?: yes])
				| 'react	  (
					if later?: spec/2 = 'later [spec: next spec]
					repend reactors [face fetch-argument block! spec later?]
				)
				] to end
			]
			unless match? [
				case [
					all [
						word? value 
						any [
							select css value
							select system/view/VID/styles value
						]
					][
						opt?: no
					]
					all [word? value find/skip next system/view/evt-names value 2][
						make-actor opts value spec/2 spec spec: next spec
					]
					'else [
						opt?: switch/default type?/word value: pre-load value [
							pair!	 [unless opts/size  [opts/size:  value]]
							string!	 [unless opts/text  [opts/text:  value]]
							logic!
							percent! [unless opts/data  [opts/data:  value] yes]
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
										opts/size-x: value
									]
								]
							]
							block!	 [
								switch/default face/type [
									panel	  [layout/parent/styles value face divides css]
									group-box [layout/parent/styles value face divides css]
									tab-panel [
										unless parse value [some [string! block!]][throw-error spec]
										face/pane: make block! (length? value) / 2
										opts/data: extract value 2
										max-sz: 0x0
										foreach p extract next value 2 [
											layout/parent/styles reduce ['panel copy p] face divides css
											p: last face/pane
											max-sz: max max-sz p/offset + p/size
										]
										unless opts/size [opts/size: max-sz]
									]
								][make-actor opts style/default-actor value spec]
								yes
							]
							get-word! [make-actor opts style/default-actor value spec]
							char!	  [yes]
						][no]
					]
				]
			]
			any [not opt? tail? spec]
		]
		unless opt? [spec: back spec]

		words: select style 'styled
		if all [not opts/size-x	find words 'size-x][
			opts/size-x: style/template/size/x
		]
		user-size?: opts/size
		
		all [											;-- handle `image data`
			face/type = 'base
			image? opts/data
			opts/image: opts/data
			opts/data: none
		]
		if all [oi: opts/image any [opts/size-x not opts/size]][
			opts/size: either opts/size-x [
				x: either zero? oi/size/x [1][oi/size/x]
				as-pair opts/size/x opts/size * (oi/size/y / x)
			][
				oi/size
			]
		]
		all [											;-- preprocess RTD inputs
			face/type = 'rich-text
			opts/data
			rtd-layout/with opts/data face
			opts/data: none
		]

		font: opts/font
		if any [face-font: face/font font][
			either face-font [
				face-font: copy face-font				;-- @@ share font/state between faces ?
				if font [
					set/some face-font font				;-- overwrite face/font with opts/font
					opts/font: face-font
				]
			][
				face-font: font
			]
			foreach [field value] default-font [
				if none? face-font/:field [face-font/:field: get value]
			]
		]
		
		set/some face opts								;-- merge default+styles and user options
		
		if all [not styling? block? face/actors][face/actors: context face/actors]

		;-- size adjustments --
		all [											;-- account for hard paddings
			pad: select system/view/metrics/paddings face/type
			pad: as-pair pad/1/x + pad/1/y pad/2/x + pad/2/y
		]
		if all [
			any [not user-size? all [user-size? opts/size-x]]
			any [opts/size-x not find words 'size]
		][
			sz: any [face/size 0x0]
			min-sz: either find containers face/type [sz][
				(any [pad 0x0]) + any [
					all [
						any [face/text series? face/data]
						calc-size face
					]
					sz
				]
			]
			face/size: either opts/size-x [				;-- x size provided by user
				as-pair opts/size-x max sz/y min-sz/y
			][
				max sz min-sz
			]
		]
		if tight? [face/size: calc-size face]
		
		all [											;-- account for hard margins
			not styling?
			mar: select system/view/metrics/margins face/type
			face/size: face/size + as-pair mar/1/x + mar/1/y mar/2/x + mar/2/y
		]
		if face/type = 'tab-panel [resize-child-panels face]
		if do-with [do bind do-with face]
		spec
	]
	
	make-actor: function [obj [object!] name [word!] body spec [block!]][
		unless any [name block? body][throw-error spec]
		unless obj/actors [obj/actors: make block! 4]
		
		spec: [face [object!] event [event! none!]]
		if all [block? body body/1 = 'local block? body/2][
			append spec: copy spec /local
			append spec body/2
		]
		
		append obj/actors load append form name #":"	;@@ to set-word!
		append obj/actors either get-word? body [body][
			reduce [
				'func spec
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
		background!:  make typeset! [image! file! url! tuple! word! issue!]
		list:		  make block! 4						;-- panel's pane block
		local-styles: any [css make block! 2]			;-- panel-local styles definitions
		pane-size:	  0x0								;-- panel's content dynamic size
		direction: 	  'across
		align:		  'top
		begin:		  tail list
		size:		  none								;-- user-set panel's size
		max-sz:		  0									;-- maximum width/height of current column/row
		current:	  0									;-- layout's cursor position
		global?: 	  yes								;-- TRUE: panel options expected
		below?: 	  no
		
		top-left: bound: cursor: origin: spacing: pick [0x0 10x10] tight
		
		opts: copy opts-proto
		
		if empty? opt-words: [][append opt-words words-of opts] ;-- static cache
		
		re-align: [
			if all [debug? begin not empty? begin][
				sz: max-sz * pick [1x0 0x1] direction = 'below
				repend panel/draw [
					'line any [begin/1/offset 1x1] cursor
					'line (any [begin/1/offset 1x1]) + sz cursor + sz
				]
			]
			align-faces begin direction align max-sz
			begin: tail list
			
			words: pick [[left center right][top middle bottom]] below?
			align: any [								;-- set new alignment
				all [find words spec/2 first spec: next spec] ;-- user-provided mode
				all [value = 'return align]				;-- keep the same mode on `return` with no modifier
				all [below? 'left]						;-- default for below
				'top									;-- default for across
			]
		]
		
		reset: [
			bound: max bound cursor
			if zero? max-sz [							;-- if empty row/col, make some room
				max-sz: spacing/:anti
				cursor/:anti: cursor/:anti + max-sz
			]
			do re-align
			cursor: as-pair origin/:axis spacing/:anti + max bound/:anti cursor/:anti + max-sz 
			if direction = 'below [cursor: reverse cursor]
			max-sz: 0
		]
		
		unless panel [
			focal-face: none
			panel: make face! system/view/VID/styles/window/template  ;-- absolute path to avoid clashing with /styles
		]
		either block? panel/pane [list: panel/pane][panel/pane: list]
		
		any [
			all [										;-- account for container's hard paddings
				svmp: select system/view/metrics/paddings panel/type ;-- top-left padding
				bound: cursor: origin: origin + pad: as-pair svmp/1/x svmp/2/x
			]
			pad: 0x0
		]
		
		if debug? [append panel/draw: make block! 30 [pen red]]
		
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
			][
				either all [word? spec/1 find/skip next system/view/evt-names spec/1 2][
					make-actor panel spec/1 spec/2 spec spec: next spec
				][
					global?: no
				]
			]
			
			if global? [spec: next spec]
		]
		
		while [not tail? spec][							;-- process panel's content
			value: spec/1
			set [axis anti] pick [[x y][y x]] direction = 'across
			
			switch/default value [
				below
				across [
					below?: value = 'below
					do re-align
					all [
						direction <> value 				;-- if direction changed
						anti2: pick [y x] value = 'across
						cursor/:anti2 <> origin/:anti2	;-- and if not close to opposite edge
						cursor/:anti2: cursor/:anti2 + spacing/:anti2 ;-- ensure proper spacing when changing direction
					]
					direction: value
					bound: max bound cursor
					max-sz: 0
				]
				space	[spacing: fetch-argument pair! spec]
				origin	[origin: cursor: pad + top-left: fetch-argument pair! spec]
				at		[at-offset: fetch-expr 'spec spec: back spec]
				pad		[cursor: cursor + fetch-argument pair! spec]
				do		[do-safe bind fetch-argument block! spec panel]
				return	[either divides [throw-error spec][do reset]]
				react	[
					if later?: spec/2 = 'later [spec: next spec]
					repend reactors [none fetch-argument block! spec later?]
				]
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
					styled?: select local-styles value
					select system/view/VID/styles value
				][
					throw-error spec
				]
				st: style/template
				if st/type = 'window [throw-error spec]
				
				if actors: st/actors [st/actors: none]	;-- avoid binding actors bodies to face object
				face: make face! copy/deep st
				if actors [face/actors: copy/deep st/actors: actors]
				
				if h: select system/view/metrics/def-heights face/type [face/size/y: h]
				unless styling? [face/parent: panel]

				spec: fetch-options face opts style spec local-styles to-logic styling?
				if all [style/init not styling?][do bind style/init 'face]
				
				either styling? [
					if same? css local-styles [local-styles: copy css]
					name: to word! form name
					value: copy style
					clean-style value/template: body-of face face/type
					
					if opts/init [
						either value/init [append value/init opts/init][
							reduce/into [to-set-word 'init opts/init] tail value
						]
					]
					either pos: find local-styles name [pos/2: value][ 
						reduce/into [name value] tail local-styles
					]
					styled: make block! 4
					foreach w opt-words [if get in opts w [append styled w]]
					repend value [to-set-word 'styled styled]
					styling?: off
				][
					blk: [style: _ vid-align: _ at-offset: #[none]]
					blk/2: value
					blk/4: align
					add-option face new-line/all blk no
				
					;-- update cursor position --
					either at-offset [
						face/options/at-offset: face/offset: at-offset
						at-offset: none
						all [							;-- account for hard margins
							mar: select system/view/metrics/margins face/type
							face/offset: face/offset - as-pair mar/1/x mar/2/x
						]
					][
						either all [					;-- grid layout
							divide?: all [divides divides <= length? list]
							zero? index: (length? list) // divides
						][
							do reset
						][								;-- flow layout
							if all [max-sz > 0 cursor/:axis <> origin/:axis][
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
					unless any [face/color panel/type = 'tab-panel][
						face/color: system/view/metrics/colors/(face/type)
					]
					
					append list face
					if name [set name face]
					pane-size: max pane-size face/offset + face/size
					if opts/now? [do-actor face none 'time]
				]
			]
			spec: next spec
		]
		do re-align
		process-reactors								;-- Needs to be after [set name face]
		
		either size [panel/size: size][
			if pane-size <> 0x0 [
				if svmp [
					pad2: as-pair svmp/1/y svmp/2/y		;-- bottom-right padding
					origin: either top-left + pad = origin [top-left + pad2][max top-left pad2]
				]
				panel/size: pane-size + origin
			]
		]
		if all [not size image: panel/image][panel/size: max panel/size image/size]

		if all [focal-face not parent][panel/selected: focal-face]
		
		if options [set/some panel make object! user-opts]
		if flags [panel/flags: either panel/flags [unique union to-block panel/flags to-block flgs][flgs]]
		if block? panel/actors [panel/actors: context panel/actors]
		
		either only [
			panel/pane: none
			list
		][
			if panel/type = 'window [
				panel/parent: system/view/screens/1
				system/view/VID/GUI-rules/process panel
			]
			panel
		]
	]
]
