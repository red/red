Red [
	Title:   "font! weight demo"
	Needs:   View
	Version: 1.0.0
]

weight-demo: context [
	families: select [
		Windows ["Segoe UI" "Arial" "Bahnschrift" "Calibri" "Consolas"]
		Linux	["Ubuntu Sans" "Ubuntu" "DejaVu Sans" "Noto Sans" "Cantarell"]
		macOS	["Helvetica Neue" "Avenir Next" "Gill Sans" "Futura" "Menlo"]
	] system/platform
	classes: ["Thin" "ExtraLight" "Light" "Regular" "Medium" "SemiBold" "Bold" "ExtraBold" "Black"]
	sample:	 "The quick brown fox jumps over the lazy dog"

	live:	 make font! [name: families/1 size: 15 weight: 400]	;-- font of every face in the "shared" box
	ladder:	 make block! 9										;-- fonts of the 100 to 900 rows
	weight:	 400
	weight?: yes
	italic?: bold?: no
	shared: steps: canvas: info: none

	update: function [][										;-- applies the controls to the fonts
		live/style: case [
			all [bold? italic?] [[bold italic]]
			bold?				['bold]
			italic?				['italic]
		]
		live/weight: if weight? [weight]
		foreach fnt ladder [fnt/style: if italic? ['italic]]
		info/text: either weight? [
			rejoin [weight " (" classes/(to integer! weight + 50 / 100) ")"]
		]["none: style decides"]
		canvas/draw: canvas/draw								;-- Draw text is not linked to its font
	]

	set-family: function [list [object!]][
		live/name: copy list/data/(list/selected)
		foreach fnt ladder [fnt/name: live/name]
		canvas/draw: canvas/draw
	]

	show-demo: func [/local rows win face i][
		rows: make block! 9 * 6
		repeat i 9 [
			repend rows ['text 130 rejoin [i * 100 " " classes/:i] 'text 560x30 sample 'return]
		]
		win: layout compose/deep [
			title "font! weight demo"
			below
			group-box "Controls" [
				text 60 "Family"
				drop-list 180 data [(families)] select 1 [set-family face]
				check "Italic" [
					italic?: face/data
					update
				]
				check "Bold" [
					bold?: face/data
					update
				]
				check "Weight" data yes [
					weight?: face/data
					update
				]
				return
				text 60 "Weight"
				slider 440 data 0.375 [
					weight: 100 + to integer! face/data * 800
					update
				]
				info: text 160 "400 (Regular)"
			]
			shared: group-box "One font! object shared by all these faces" [
				text 690x30 (sample)
				return
				button 140x34 "A button"
				field 260x34 "A field"
				check 170x34 "A check box"
				return
				base 690x36 white (sample)
				return
				canvas: base 690x36 white draw [font live text 8x6 "Draw: The quick brown fox jumps over the lazy dog"]
				return
				rich-text 690x36 data ["Rich-text: the " b "bold" /b " range is 700, the rest has the font's weight"]
			]
			steps: group-box "Weights 100 to 900 of the same family" [(rows)]
		]
		foreach face shared/pane [face/font: live]
		foreach face steps/pane [
			if face/text = sample [
				append ladder face/font: make font! [name: live/name size: 15 weight: (length? ladder) + 1 * 100]
			]
		]
		view win
	]
]

weight-demo/show-demo
