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
	origin 1x1
	text 10x2 font-color green "Page 2" return
	text-list 10x3 select 2 data [
		"1 apple"
		"2 orange"
		"3 banana"
		"4 grape"
		"5 lychee"
		"6 pear"
		"7 watermelon"
	] return

	pad 0x1
	button 10x2 "Prev" [show page-1]
	button 4x2 "Next" [show page-3]
]

page-1: layout/tight [
	on-key [if event/key = #"^[" [unview/all]]
	style txt: text 10x1 font-color 255.0.127
	style field: field 10x2

	origin 1x1
	bar: progress 20x1 50% return
	button 19x1 "-" [bar/data: bar/data - 10%]
	button 1x1 "+" [bar/data: bar/data + 10%]
	return
	panel 30x5 [
		base 20x2 red return
		txt 13 "Card Number" return
		field 19 hint "8888 **** **** 1234"
	] return

	txt 8 "EXP" txt 3 "CVV" return
	field 5 hint "MM/YY" pad 3x0 field 3 hint "999" return

	button font-color gray 20x2 "Next ->" [show page-2]
]

view page-1