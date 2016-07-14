Red [
	Title:   "Red VID reactive test"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test6.red
	Needs:	 View
]

view [
	text "Text:" f: area 200x80 font [name: "Comic Sans MS" size: 15 color: black] return

	text "Size in pixels:" sz: text "0x0" react [sz/text: form size-text f [f/text f/font]] return
	
	text "Font name:" drop-list
		data  ["Arial" "Consolas" "Comic Sans MS" "Times"]
		react [f/font/name: pick face/data any [face/selected 3]]
		return
		
	text "Font size:" s: field "15" react [f/font/size: s/data]
	button "+" bold 24x24 [s/data: s/data + 1]
	button "-" bold 24x24 [s/data: max 1 s/data - 1]
	return
]

