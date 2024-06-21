Red [
	Title:  "Red TUI test script"
	Needs:  'View
	Config: [GUI-engine: 'terminal]
]

rt-quit: rtd-layout [i/green ["Q"] "uit"]

page-3: layout/tight compose/deep [
	origin 2x1
	text 24x2 center font-color yellow "Page 3" return

	panel 30x2 [
		bar: progress 30% rate 10 on-time [
			data: face/data + 10%
			face/data: either data > 100% [0%][data]
			bar-txt/text: form face/data
			bar-txt/font/color: random white
		] pad 1x0
		bar-txt: text 4 font-color white "30%"
	] return

	rich-text 40x3 transparent data [
		yellow "Hello" <bg> white red " Red " </bg> green "World!^/"
		u "Underline" /u " " s "Strike" /s i " Italic" /i
	] return

	button 8x2 "Prev" [unview]
	button 8x2 "Home" [show page-1]
	button 4x2 draw [text 0x0 (rt-quit)] [unview/all]
]

page-2: layout [
 	on-key [
		switch event/key [
			left	[cat/offset: cat/offset - 1x0]
			right	[cat/offset: cat/offset + 1x0]
			up 		[cat/offset: cat/offset - 0x1]
			down	[cat/offset: cat/offset + 0x1]
		]
	]

	text 10 font-color green "Page 2" return

	image 60x30 %../../bridges/android/samples/eval/res/drawable-xxhdpi/ic_launcher.png return

	text-list 13x3 select 2 data [
		"1 apple"
		"2 orange"
		"3 banana"
		"4 grape"
		"5 lychee"
		"6 pear"
		"7 watermelon"
	]

	base 5x4 center middle "X^/Y"
	base 5x4 wrap middle "abcdefgh" return

	text 30 "Use arrow keys to move the cat" return

	button 10 "Prev" [show page-1]
	button 4 "Next" [show page-3]
	cat: base transparent 2x1 "🐱"
]

page-1: layout/tight [
	on-key [if event/key = #"^[" [unview/all]]
	style txt: text 10x1 font-color 255.0.127
	style field: field 10x1
	style b3: base black 4x3

	origin 1x1 space 1x1

	panel 20x9 [
		base 20x5 red wrap "I can eat glass, it does not hurt me^/^/我能吞下玻璃而不伤身体" return
		base 20x4 transparent draw [pen yellow text 15x1 "~~~"]
{          __
     (___()'`;
     /,    /`
     \\"--\\}
	]

	panel 12x9 [
		b3 blue left "😀" b3 center "😆" b3 green right "🙂" return
		b3 middle "😂"   b3 red middle center "😎" b3 middle right "😍" return
		b3 green bottom left "😛" b3 bottom center "😋" b3 blue bottom right "😭"
	] return

	panel 30x2 [
		txt 13 "Card Number" return
		field 19 hint "8888 **** **** 1234"
	] return

	panel 30x2 [
		txt 8 "EXP" txt 3 "CVV" return
		field 5 hint "MM/YY" pad 3x0 field 3 password hint "999"
	] return

	button font-color gray 20x2 "^[[32mN^[[39mext ->" [show page-2]
]

view page-1