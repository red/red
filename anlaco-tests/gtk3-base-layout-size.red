Red [
	Title:   "GTK3 Bug B2: gtk_layout_set_size not called for base"
	Purpose: "Verify that a base face with draw updates its layout size when resized (opaque color)"
	Needs:   'View
]

canvas: make face! [
	type:   'base
	size:   580x380
	offset: 5x5
	color:  white
	draw:   []
]

render-canvas: func [win /local cw ch] [
	cw: win/size/x - 20
	ch: win/size/y - 20
	if cw < 50 [cw: 50]
	if ch < 50 [ch: 50]
	canvas/size: as-pair cw ch
	canvas/draw: compose [
		pen blue line-width 2
		fill-pen off
		box 1x1 (canvas/size - 2x2)
		pen black
		text 10x8  (rejoin ["canvas/size: " canvas/size])
		text 10x26 (rejoin ["win/size:    " win/size])
		text 10x44 "color: white (opaque base)"
	]
]

view/flags [
	title "Bug B2: layout size for base (opaque)"
	size 600x400
	canvas
	on-resize [render-canvas face]
] [resize]