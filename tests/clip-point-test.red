Red [
	Title:  "Red clip test"
	Author: "bitbegin"
	Tabs:   4
	File: 	%clip-test.red
	Needs:	View
]


drawings: [
	"default replace"
	[
		clip [move (50,50) line (50,50) (150,50) (150,150) (50,150)]
		fill-pen 0.255.0.128
		box (0,0) (200,200)
	]
	"intersect"
	[
		clip [move (50,50) line (50,50) (150,50) (150,150) (50,150)] intersect
		fill-pen 0.255.0.128
		box (0,0) (200,200)
	]
	"union"
	[
		clip [move (50,50) line (50,50) (150,50) (150,150) (50,150)] union
		fill-pen 0.255.0.128
		box (0,0) (200,200)
	]
	"xor"
	[
		clip (50,50) (150,150) xor
		fill-pen 0.255.0.128
		box (0,0) (200,200)
	]
	"exclude"
	[
		clip (50,50) (150,150) exclude
		fill-pen 0.255.0.128
		box (0,0) (200,200)
	]
	"commands replace" [
		fill-pen 0.0.255.128
		clip (50,50) (150,150) [
			fill-pen 0.255.0.128
			box (0,0) (200,200)
		]
		box (150,150) (200,200)
	]
	"commands intersect" [
		fill-pen 0.0.255.0
		clip (50,50) (150,150) intersect [
			fill-pen 0.255.0.128
			box (0,0) (200,200)
		]
		box (150,150) (200,200)
	]
]

index: 2
board: layout [
	below
	label: text "" (200,30) font [size: 14]
	canvas: base (200,200) 255.0.0.128
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
board/text: "clip demos"
view board 
