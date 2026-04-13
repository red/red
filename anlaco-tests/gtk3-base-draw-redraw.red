Red [
	Title:   "GTK3 Bug B2+B3: base face draw not redrawn after resize"
	Purpose: "Verify that a base face with a draw block redraws correctly after maximize/restore"
	Needs:   'View
]

canvas: make face! [
	type:   'base
	size:   580x380
	offset: 5x5
	color:  240.240.245
	draw:   []
]

render-canvas: func [win /local cw ch] [
	cw: win/size/x - 20
	ch: win/size/y - 20
	if cw < 50 [cw: 50]
	if ch < 50 [ch: 50]
	canvas/size: as-pair cw ch
	canvas/draw: compose [
		pen red line-width 3
		fill-pen off
		box 1x1 (canvas/size - 2x2)
		pen black
		text 10x8  (rejoin ["canvas/size: " canvas/size])
		text 10x26 (rejoin ["win/size:    " win/size])
	]
]

view/flags [
	title "Bug B2+B3: base draw redraw"
	size 600x400
	canvas
	on-resize [render-canvas face]
] [resize]