Red [
	Purpose: "Test text selection in field and area widgets"
]

view [
	f: field "Hello World!"
	a: area "This is a^/multi-line area widget^/where you can write long text" 
	panel [
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
			f/selected: 1x5
			f/parent/selected: f
		]
	]
	;text "" react [face/data: f/selected]]
]