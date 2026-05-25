Red [
	Title:  "SDL3 View backend smoke test"
	Needs:  View
	Config: [GUI-engine: 'SDL3]
]

img: make image! [8x8 #{
	FF0000 FF0000 FF0000 FF0000 00AA00 00AA00 00AA00 00AA00
	FF0000 FF0000 FF0000 FF0000 00AA00 00AA00 00AA00 00AA00
	FF0000 FF0000 FF0000 FF0000 00AA00 00AA00 00AA00 00AA00
	FF0000 FF0000 FF0000 FF0000 00AA00 00AA00 00AA00 00AA00
	0000FF 0000FF 0000FF 0000FF FFFF00 FFFF00 FFFF00 FFFF00
	0000FF 0000FF 0000FF 0000FF FFFF00 FFFF00 FFFF00 FFFF00
	0000FF 0000FF 0000FF 0000FF FFFF00 FFFF00 FFFF00 FFFF00
	0000FF 0000FF 0000FF 0000FF FFFF00 FFFF00 FFFF00 FFFF00
}]

main: layout [
	title "SDL3 basic"
	text "Hello SDL3"
	button "OK"
	check "Check" true
	radio "Radio" true
	field "Field"
	area 160x60 "Area"
	progress 50%
	slider 50%
	text-list 120x70 data ["one" "two" "three"] select 2
	image 80x60 img
	base 120x70 draw [
		pen red line-width 3 line 5x5 70x20 5x35
		line-width 1
		fill-pen 0.180.220 box 8x40 58x64
		pen black fill-pen 220.220.255 circle 86x48 14
		pen 0.90.180 fill-pen off ellipse 68x4 114x24
		pen black text 12x8 "Draw"
		pen 120.0.120 fill-pen 255.210.120 triangle 6x6 22x30 3x30
		pen 0.120.80 fill-pen 190.255.210 polygon 35x6 58x12 52x32 30x28
		pen 0.0.150 fill-pen 220.230.255 arc 94x34 18x12 20 230 closed
		push [pen 0.0.0 line-width 2 line 6x36 36x36]
		pen 40.40.40 curve 4x66 30x50 56x66
		pen 80.0.0 spline 60x66 72x54 84x66 96x54 108x66
		clip 84x38 112x62 [fill-pen 255.120.120 box 70x30 118x68]
		image img 72x12 112x52
	]
	base 80x40 blue
]

view/no-wait main
repeat i 5 [do-events/no-wait]
shot: to-image main
if any [not image? shot shot/size <> main/size][1 / 0]
unview/all
