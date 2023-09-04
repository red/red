Red [
	Title:  "Red TUI test script"
	Needs:	'View
	Config: [GUI-engine: 'terminal]
]

page-3: layout/tight [
	origin 2x1
	text 10x2 font-color yellow "Page 3" return

	panel 30x2 [
		bar: progress 20x1 30% rate 10 on-time [
			data: face/data + 10%
			face/data: either data > 100% [0%][data]
			bar-txt/text: form face/data
			bar-txt/font/color: random white
		] pad 1x0
		bar-txt: text 4x1 font-color white "30%"
	] return

	button 8x2 "Prev" [unview]
	button 8x2 "Home" [show page-1]
	button 4x2 "Quit" [unview/all]
]

page-2: layout/tight [
 	on-key [
		switch event/key [
			left	[cat/offset: cat/offset - 1x0]
			right	[cat/offset: cat/offset + 1x0]
			up 		[cat/offset: cat/offset - 0x1]
			down	[cat/offset: cat/offset + 0x1]
		]
	]
	origin 1x1 space 1x1
	text 10x1 font-color green "Page 2" return

	text-list 15x3 select 2 data [
		"1 apple"
		"2 orange"
		"3 banana"
		"4 grape"
		"5 lychee"
		"6 pear"
		"7 watermelon"
	] return

	text 30x1 "Use arrow keys to move the cat" return
	cat: base transparent 2x1 "🐱" return

	button 10x1 "Prev" [show page-1]
	button 4x1 "Next" [show page-3]
]

page-1: layout/tight [
	on-key [if event/key = #"^[" [unview/all]]
	style txt: text 10x1 font-color 255.0.127
	style field: field 10x1
	style b3: base black 4x3

	origin 1x1 space 0x1 below
	base 20x5 red wrap "I can eat glass, it does not hurt me^/^/我能吞下玻璃而不伤身体"

	panel 9x9 [
		b3 blue left "😀" b3 center "😆" b3 green right "🙂" return
		b3 middle "😂"   b3 red middle center "😎" b3 middle right "😍" return
		b3 green bottom left "😛" b3 bottom center "😋" b3 blue bottom right "😭"
	]

	panel 30x2 [
		txt 13 "Card Number" return
		field 19 hint "8888 **** **** 1234"
	]

	panel 30x2 [
		txt 8 "EXP" txt 3 "CVV" return
		field 5 hint "MM/YY" pad 3x0 field 3 hint "999"
	]

	button font-color gray 20x2 "Next ->" [show page-2]
]

view page-1