Red [
	Purpose: "Shows all the available monitors position and relative sizes"
	Needs: 'View
]

context [
	list: []
	
	draw-displays: function [parent [object!]][
		bound: (0,0)
		foreach s system/view/screens [
			s-off: s/offset * s/data
			s-size: s/size * s/data
			repend list [s-off s-size s/data]
			bound: max bound s-off + s-size
		]

		ratio: bound/x / (parent/size/x - 20)
		off-y: parent/size/y - (bound/y / ratio) / 2
		parent/pane: make block! length? list
		c: 0
		foreach [s-off s-size scaling] list [
			append parent/pane face: make-face 'base
			face/offset: s-off / ratio + as-pair 10 off-y
			face/size:   s-size / ratio
			face/color:  cyan
			face/text:   form c: c + 1
			face/font:   make font! [size: 12 style: 'bold]
			
			print [c "- offset:" s-off "size:" s-size "scaling:" to-percent scaling]
		]
	]

	view [
		title "Displays Geometry"
		p: panel 400x400 gray on-created [draw-displays face]
	]
]