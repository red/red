Red [
	Title:  "Red TUI test script"
	Needs:	'View
	Config: [GUI-engine: 'terminal]
]

page-3: layout/tight [
	origin 2x2
	text 10x3 font-color blue "Page 3" return

	button 8x2 "Prev" [unview]
	button 8x2 "Home" [show page-1]
	button 4x2 "Quit" [unview/all]
]

page-2: layout/tight [
	origin 2x2
	text 10x3 font-color green "Page 2" return

	button 10x2 "Prev" [unview]
	button 4x2 "Next" [show page-3]
]

page-1: layout/tight [
	on-key [if event/key = #"^[" [unview/all]]
	style txt: text 10x1 font-color 255.0.127
	style field: field 10x2

	origin 1x1
	txt 13 "Card Number" return
	field 19 hint "8888 **** **** 1234" return

	txt 8 "EXP" txt 3 "CVV" return
	field 5 hint "MM/YY" pad 3x0 field 3 hint "999" return

	button font-color gray 20x2 "Next ->" [show page-2]
]

view page-1