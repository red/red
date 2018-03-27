Red [
	Purpose: "Test text selection in field and area widgets"
]

view [
	f: field "Hello World!"
	a: area "This is a^/multi-line area widget^/where you can write long text" 
	panel [
		origin 0x0
		below
		style but: button 100
		but "selected" [print [f/selected a/selected]]
		but "select" [
			len: length? f/text
			f/selected: as-pair s: random len s + random len - s

			len: length? a/text
			a/selected: as-pair s: random len s + random len - s
		]
		but "select && edit" [
			f/parent/selected: f
			f/selected: 1x5
		]
		across
		text "Field:" 30 text "" left react [face/data: f/selected] return
		text "Area:"  30 text "" left react [face/data: a/selected]
	]
]