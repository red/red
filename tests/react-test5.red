Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test5.red
	Needs:	 'View
]

as-color: function [r g b][
	color: 0.0.0
	if r [color/1: to integer! 256 * r]
	if g [color/2: to integer! 256 * g]
	if b [color/3: to integer! 256 * b]
	color
]

to-text: function [val][form to integer! 0.5 + 255 * any [val 0]]

view [
	style txt: text 40 right
	style value: text "0" 30 right bold
	
	across
	txt "Red:"   R: slider 256 vR: value return
	txt "Green:" G: slider 256 vG: value return
	txt "Blue:"  B: slider 256 VB: value
	
	pad 0x-65 box: base return
	pad 0x20 txt: text "The quick brown fox jumps over the lazy dog." font [size: 14]
		
	do [
		react [vR/text: to-text R/data]
		react [vG/text: to-text G/data]
		react [vB/text: to-text B/data]
		react [box/color: as-color R/data G/data B/data]
		react [txt/font/color: box/color]
	]
]

