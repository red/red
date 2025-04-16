Red [
	Purpose: "Shows all the available monitors position and relative sizes"
	Needs: 'View
]

context [
	list: []
	
	draw-displays: function [parent [object!]][
		bound: low: (0,0)
		foreach s system/view/screens [					;-- gather all screens offset and size
			s-off: s/offset * s/data					;-- multiply by screen scaling factor (to get a DPI-independent value)
			s-size: s/size * s/data						;-- multiply by screen scaling factor (to get a DPI-independent value)
			repend list [s-off s-size s/data]
			bound: max bound s-off + s-size				;-- calculate maximum bounding box for all screens
			low: min low s-off							;-- calculate lowest negative offset
		]

		bound: bound + low: absolute low				;-- translate coordinates, makes lowest offset the origin
		ratio: bound/x / (parent/size/x - 20)			;-- calculate X/Y ratio with container face with a padding of 20
		off-y: parent/size/y - (bound/y / ratio) / 2	;-- calculate the Y offset to center vertically
		parent/pane: make block! length? list
		c: 1											;-- screen ID (incremented)

		foreach [s-off s-size scaling] list [
			append parent/pane make face! [				;-- build a screen face for each monitor
				type:   'base
				offset: s-off + low / ratio + as-pair 10 off-y ;-- translate original screen offset, scale it to ratio, adds an X padding of 10
				size:   s-size / ratio					;-- scaled size
				color:  cyan
				text:   form c
				font:   make font! [size: 12 style: 'bold]
				draw:   compose [pen blue box (0x0) (size - 1x1)] ;-- border line around the screen
			]
			print [c "- offset:" s-off "size:" s-size "scaling:" to-percent scaling]
			c: c + 1
		]
	]

	view [
		title "Displays Geometry"
		p: panel 400x400 gray on-created [draw-displays face]
	]
]