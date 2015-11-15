Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test.red
	Needs:	 'View
]

as-color: func [r g b][
	color: 0.0.0
	if r [color/1: to integer! 256 * r]
	if g [color/2: to integer! 256 * g]
	if b [color/3: to integer! 256 * b]
	color
]

to-text: func [val][form to integer! 0.5 + round 255 * val]

view [
	style txt: text right
	style value: text "0" 30 right bold
	
	across
	txt "Red:"   R: slider 256 vR: value react [vR/text: to-text R/data] return
	txt "Green:" G: slider 256 vG: value react [vG/text: to-text G/data] return
	txt "Blue:"  B: slider 256 vB: value react [vB/text: to-text B/data]
	
	pad 0x-65 box: base react [box/color: as-color R/data G/data B/data]
]