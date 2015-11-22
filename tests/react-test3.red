Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test3.red
	Needs:	 'View
]

digit: charset "0123456789"

view [
	text "Number" right num: field "" return
	text "Invalid input" font [color: red style: 'bold] react [
		face/visible?: not parse num/text [any digit]
	]
]
