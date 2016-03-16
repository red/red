Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test.red
	Needs:	 'View
]

to-color: function [r g b][
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
	txt "Red:"   R: slider 256 value react [face/text: to-text R/data] return
	txt "Green:" G: slider 256 value react [face/text: to-text G/data] return
	txt "Blue:"  B: slider 256 value react [face/text: to-text B/data]
	
	pad 0x-65 box: base react [face/color: to-color R/data G/data B/data] return
	
	pad 0x20 text "The quick brown fox jumps over the lazy dog." 
		font  [size: 14]
		react [face/font/color: box/color]
]

