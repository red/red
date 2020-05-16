Red [
	Title:  "Red matrix test"
	Author: "bitbegin"
	Tabs:   4
	File: 	%matrix-test.red
	Needs:	View
]

drawings: [
	"geometric matrix"
	[
		line 200x0 200x400
		line 400x0 400x400
		line 0x200 600x200
		reset-matrix
		translate 100x100
		rotate 90
		scale 1.5 1
		circle 0x0 50

		reset-matrix
		rotate 90 300x100
		scale 1.5 1 300x100
		circle 300x100 50

		reset-matrix
		matrix [1 0 0 1 500 100]
		matrix [0 1 -1 0 0 0]
		matrix [1.5 0 0 1 0 0]
		circle 0x0 50

		matrix-order append
		reset-matrix
		scale 1.5 1
		rotate 90
		translate 100x300
		circle 0x0 50

		reset-matrix
		scale 1.5 1 300x300
		rotate 90 300x300
		circle 300x300 50

		reset-matrix
		matrix [1.5 0 0 1 0 0]
		matrix [0 1 -1 0 0 0]
		matrix [1 0 0 1 500 300]
		circle 0x0 50
	]
	"transform test" [
		line 200x0 200x400
		line 400x0 400x400
		line 0x200 600x200
		reset-matrix
		transform 0x0 90 1 3 100x100
		arc 0x0 25x50 0 360

		reset-matrix
		transform 300x100 90 1 3 0x0
		arc 300x100 25x50 0 360

		reset-matrix
		translate 500x100
		scale 1 3
		rotate 90
		arc 0x0 25x50 0 360

		matrix-order append
		reset-matrix
		transform 0x0 90 1 3 100x300
		arc 0x0 25x50 0 360

		reset-matrix
		transform 300x300 90 1 3 0x0
		arc 300x300 25x50 0 360

		reset-matrix
		rotate 90
		scale 1 3
		translate 500x300
		arc 0x0 25x50 0 360
	]
]

index: 2
board: layout [
	below
	label: text "" 200x30 font [size: 14]
	canvas: base 600x400
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
board/text: "matrix demos"
view board 
