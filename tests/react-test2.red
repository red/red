Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test2.red
	Needs:	 'View
]

view [
	below
	A: field "0" right
	B: field "0" right
	panel [
		text "Total:" 50
		text "0" 20 react [face/text: form (to integer! A/text) + (to integer! B/text)]
	]
]