Red [
	Title:   "Mouse cursors test script"
	Author:  "Nenad Rakocevic"
	File: 	 %cursor.red
	Needs:	 'View
]

img: draw 20x20 [fill-pen red triangle 10x0 19x19 0x19]
forall img [if img/1 = 255.255.255.0 [img/1: transparent]]

view [
	style box: base beige 60x30
	box "Arrow"
	box "I-beam" cursor I-beam
	box "Hand"   cursor hand
	box "Cross"  cursor cross
	box "Custom" cursor img
]