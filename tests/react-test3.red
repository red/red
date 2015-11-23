Red [
	Title:   "Red VID reactive script"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test3.red
	Needs:	 'View
]

digit: charset "0123456789"

view [
	text "Number" right num1: field "" return
	text "Number" right num2: field "" return
	
	text "Invalid input" font [color: red style: 'bold] react [
		face/visible?: not all [
			parse num1/text [any digit]
			parse num2/text [any digit]
		]
	]
]
