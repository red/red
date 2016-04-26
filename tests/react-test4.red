Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test4.red
	Needs:	 'View
]

view [
	sld: slider return
	base 200x200 
		draw  [circle 100x100 5]
		react [face/draw/3: to integer! 100 * sld/data]
]


