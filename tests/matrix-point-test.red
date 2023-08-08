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
		pen yellow
		line-width 3
		spline (50,50) (100,50) (50,120) (150,150)
		translate (200,0)
		arc (100,100) (60,40) 0 270
		translate (0,200)
		ellipse (60,40) (90,110)
		translate (-200,0)
		curve (50,50) (100,50) (50,120) (150,150)
	]

	"rotate arc"
	[
		pen yellow
		line-width 3
		arc (100,100) (50,50) 0 270

		reset-matrix
		rotate 45 (100,100)
		translate (200,0)
		arc (100,100) (50,50) 0 270

		reset-matrix
		rotate 90 (100,100)
		translate (0,200)
		arc (100,100) (50,50) 0 270

		reset-matrix
		rotate 135 (100,100)
		translate (200,200)
		arc (100,100) (50,50) 0 270
	]

	"scale circle"
	[
		pen yellow
		line-width 3
		circle (100,100) 50

		reset-matrix
		translate (-100,-100)
		scale 0.5 1.5
		translate (100,100)
		translate (200,0)
		circle (100,100) 50

		reset-matrix
		translate (-100,-100)
		scale 1.5 0.5
		translate (100,100)
		translate (0,200)
		circle (100,100) 50

		reset-matrix
		translate (-100,-100)
		scale 1.5 1.5
		translate (100,100)
		translate (200,200)
		circle (100,100) 50
	]

	"skew box"
	[
		pen yellow
		line-width 3
		box (50,50) (150,150)

		reset-matrix
		translate (-50,-50)
		skew 20 0
		translate (50,50)
		translate (200,0)
		box (50,50) (150,150)

		reset-matrix
		translate (-50,-50)
		skew 0 20
		translate (50,50)
		translate (0,200)
		box (50,50) (150,150)

		reset-matrix
		translate (-50,-50)
		skew 20
		translate (50,50)
		translate (200,200)
		box (50,50) (150,150)
	]

	"matrix ellipse"
	[
		pen yellow
		line-width 3
		ellipse (50,50) (100,100)

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [0.5 0 0 1.5 0 0]
		matrix [1 0 0 1 100 100]
		translate (200,0)
		ellipse (50,50) (100,100)

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [1.5 0 0 0.5 0 0]
		matrix [1 0 0 1 100 100]
		translate (0,200)
		ellipse (50,50) (100,100)

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [1.5 0 0 1.5 0 0]
		matrix [1 0 0 1 100 100]
		translate (200,200)
		ellipse (50,50) (100,100)
	]

	"invert ellipse"
	[
		pen yellow
		line-width 3
		ellipse (50,50) (100,100)

		reset-matrix
		matrix [1 0 0 1 -100 -100]
		matrix [2 0 0 0.6667 0 0]
		matrix [1 0 0 1 100 100]
		invert-matrix
		translate (200,0)
		ellipse (50,50) (100,100)

		reset-matrix
		translate (-100,-100)
		matrix [0.6667 0 0 2 0 0]
		translate (100,100)
		invert-matrix
		translate (0,200)
		ellipse (50,50) (100,100)

		reset-matrix
		translate (-100,-100)
		scale 0.6667 0.6667
		translate (100,100)
		invert-matrix
		translate (200,200)
		ellipse (50,50) (100,100)
	]

	"transform graphics"
	[
		line-width 3
		pen yellow
		line (50,20) (150,20)
		pen red
		polygon (150,20) (120,50) (60,50) (60,100) (150,150)
		pen green
		curve (50,50) (100,50) (50,120) (150,150)
		pen black
		triangle (100,50) (50,150) (150,150)

		reset-matrix
		transform (100,100) 45 1 1 (200,0)
		pen yellow
		line (50,20) (150,20)
		pen red
		polygon (150,20) (120,50) (60,50) (60,100) (150,150)
		pen green
		curve (50,50) (100,50) (50,120) (150,150)
		pen black
		triangle (100,50) (50,150) (150,150)

		reset-matrix
		transform (100,100) 90 1 1 (0,200)
		pen yellow
		line (50,20) (150,20)
		pen red
		polygon (150,20) (120,50) (60,50) (60,100) (150,150)
		pen green
		curve (50,50) (100,50) (50,120) (150,150)
		pen black
		triangle (100,50) (50,150) (150,150)

		reset-matrix
		transform (100,100) 135 0.5 0.5 (200,200)
		pen yellow
		line (50,20) (150,20)
		pen red
		polygon (150,20) (120,50) (60,50) (60,100) (150,150)
		pen green
		curve (50,50) (100,50) (50,120) (150,150)
		pen black
		triangle (100,50) (50,150) (150,150)
	]
]

index: 2
board: layout [
	below
	label: text "" 300 font [size: 16]
	canvas: base (400,400)
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
