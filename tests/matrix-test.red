Red [
	Title:  "Red draw matrix test"
	Author: "bitbegin"
	Tabs:   4
	File: 	%matrix-test.red
	Needs:	View
]

drawings: [
	"translate"
	[
		matrix-order append
		pen yellow
		line-width 3
		spline 50x50 100x50 50x120 150x150
		translate 200x0
		arc 100x100 60x40 0 270
		translate 0x200
		ellipse 60x40 90x110
		translate -200x0
		curve 50x50 100x50 50x120 150x150
	]

	"rotate arc"
	[
		matrix-order append
		pen yellow
		line-width 3
		arc 100x100 50x50 0 270

		reset-matrix
		rotate 45 100x100
		translate 200x0
		arc 100x100 50x50 0 270

		reset-matrix
		rotate 90 100x100
		translate 0x200
		arc 100x100 50x50 0 270

		reset-matrix
		rotate 135 100x100
		translate 200x200
		arc 100x100 50x50 0 270
	]

	"scale circle"
	[
		matrix-order append
		pen yellow
		line-width 3
		circle 100x100 50

		reset-matrix
		translate -100x-100
		scale 0.5 1.5
		translate 100x100
		translate 200x0
		circle 100x100 50

		reset-matrix
		translate -100x-100
		scale 1.5 0.5
		translate 100x100
		translate 0x200
		circle 100x100 50

		reset-matrix
		translate -100x-100
		scale 1.5 1.5
		translate 100x100
		translate 200x200
		circle 100x100 50
	]

	"skew box"
	[
		matrix-order append
		pen yellow
		line-width 3
		box 50x50 150x150

		reset-matrix
		translate -50x-50
		skew 20 0
		translate 50x50
		translate 200x0
		box 50x50 150x150

		reset-matrix
		translate -50x-50
		skew 0 20
		translate 50x50
		translate 0x200
		box 50x50 150x150

		reset-matrix
		translate -50x-50
		skew 20
		translate 50x50
		translate 200x200
		box 50x50 150x150
	]

	"matrix ellipse"
	[
		matrix-order append
		pen yellow
		line-width 3
		ellipse 50x50 100x100

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [0.5 0 0 1.5 0 0]
		matrix [1 0 0 1 100 100]
		translate 200x0
		ellipse 50x50 100x100

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [1.5 0 0 0.5 0 0]
		matrix [1 0 0 1 100 100]
		translate 0x200
		ellipse 50x50 100x100

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [1.5 0 0 1.5 0 0]
		matrix [1 0 0 1 100 100]
		translate 200x200
		ellipse 50x50 100x100
	]

	"invert ellipse"
	[
		matrix-order append
		pen yellow
		line-width 3
		ellipse 50x50 100x100

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [2 0 0 0.6667 0 0]
		matrix [1 0 0 1 100 100]
		invert-matrix
		translate 200x0
		ellipse 50x50 100x100

		reset-matrix
		translate -100x-100
		matrix [0.6667 0 0 2 0 0]
		translate 100x100
		invert-matrix
		translate 0x200
		ellipse 50x50 100x100

		reset-matrix
		translate -100x-100
		scale 0.6667 0.6667
		translate 100x100
		invert-matrix
		translate 200x200
		ellipse 50x50 100x100
	]

	"transform graphics"
	[
		matrix-order append
		line-width 3
		pen yellow
		line 50x20 150x20
		pen red
		polygon 150x20 120x50 60x50 60x100 150x150
		pen green
		curve 50x50 100x50 50x120 150x150
		pen black
		triangle 100x50 50x150 150x150

		reset-matrix
		transform 100x100 45 1 1 200x0
		pen yellow
		line 50x20 150x20
		pen red
		polygon 150x20 120x50 60x50 60x100 150x150
		pen green
		curve 50x50 100x50 50x120 150x150
		pen black
		triangle 100x50 50x150 150x150

		reset-matrix
		transform 100x100 90 1 1 0x200
		pen yellow
		line 50x20 150x20
		pen red
		polygon 150x20 120x50 60x50 60x100 150x150
		pen green
		curve 50x50 100x50 50x120 150x150
		pen black
		triangle 100x50 50x150 150x150

		reset-matrix
		transform 100x100 135 0.5 0.5 200x200
		pen yellow
		line 50x20 150x20
		pen red
		polygon 150x20 120x50 60x50 60x100 150x150
		pen green
		curve 50x50 100x50 50x120 150x150
		pen black
		triangle 100x50 50x150 150x150
	]
]

index: 2
board: layout [
	below
	label: text "" 300 font [size: 16]
	canvas: base 400x400
	below
	across
	btn-prev: button "previous" [
		unless btn-next/enabled? [ btn-next/enabled?: true ]
		either index > 2 [
			index: index - 2
			label/text: drawings/(index - 1)
			canvas/draw: drawings/:index
			show canvas
		][ btn-prev/enabled?: false ]
	]
	btn-next: button "next" [
		unless btn-prev/enabled? [ btn-prev/enabled?: true ]
		either index < length? drawings [
			index: index + 2
			label/text: drawings/(index - 1)
			canvas/draw: drawings/:index
			show canvas
		][ btn-next/enabled?: false ]
	]
	do [
		label/text: drawings/(index - 1)
		canvas/draw: drawings/:index
		btn-prev/enabled?: false
	]
]
board/text: "draw matrix demo"
view board
