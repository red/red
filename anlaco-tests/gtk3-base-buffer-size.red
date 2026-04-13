Red [
	Title:   "GTK3 Bug B3: base buffer size after resize (transparent)"
	Purpose: "Verify that the cairo offscreen buffer resizes with the base face"
	Needs:   'View
]

canvas: make face! [
	type:   'base
	size:   580x380
	offset: 5x5
	color:  none
	draw:   []
]

render-canvas: func [win /local cw ch] [
	cw: win/size/x - 20
	ch: win/size/y - 20
	if cw < 50 [cw: 50]
	if ch < 50 [ch: 50]
	canvas/size: as-pair cw ch
	canvas/draw: compose [
		pen cyan line-width 3
		fill-pen 200.220.255.180
		box 1x1 (canvas/size - 2x2)
		pen black
		text 10x8  (rejoin ["canvas/size: " canvas/size])
		text 10x26 (rejoin ["win/size:    " win/size])
		text 10x44 "color: none (transparent base)"
	]
]

view/flags [
	title "Bug B3: base buffer size (transparent)"
	size 600x400
	canvas
	on-resize [render-canvas face probe reduce ["on-resize" face/size canvas/size]]
] [resize]