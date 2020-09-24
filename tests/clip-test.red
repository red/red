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
		clip [move 50x50 line 50x50 150x50 150x150 50x150]
		fill-pen 0.255.0.128
		box 0x0 200x200
	]
	"intersect"
	[
		clip [move 50x50 line 50x50 150x50 150x150 50x150] intersect
		fill-pen 0.255.0.128
		box 0x0 200x200
	]
	"union"
	[
		clip [move 50x50 line 50x50 150x50 150x150 50x150] union
		fill-pen 0.255.0.128
		box 0x0 200x200
	]
	"xor"
	[
		clip 50x50 150x150 xor
		fill-pen 0.255.0.128
		box 0x0 200x200
	]
	"exclude"
	[
		clip 50x50 150x150 exclude
		fill-pen 0.255.0.128
		box 0x0 200x200
	]
	"commands replace" [
		fill-pen 0.0.255.128
		clip 50x50 150x150 [
			fill-pen 0.255.0.128
			box 0x0 200x200
		]
		box 150x150 200x200
	]
	"commands intersect" [
		fill-pen 0.0.255.0
		clip 50x50 150x150 intersect [
			fill-pen 0.255.0.128
			box 0x0 200x200
		]
		box 150x150 200x200
	]
]

index: 2
board: layout [
	below
	label: text "" 200x30 font [size: 14]
	canvas: base 200x200 255.0.0.128
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
