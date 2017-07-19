Red [
	Title:   "Red VID reactive test"
	Author:  "Nenad Rakocevic"
	File: 	 %react-test6.red
	Needs:	 View
]

view [
	style txt: text right
	txt "Text" f: area 200x80 
		font [name: "Comic Sans MS" size: 15 color: black]
		return

	txt "Size in pixels" text "0x0"
		react [[f/text f/font] face/text: form size-text f]
		return
	
	txt "Font name" drop-list 120
		data  ["Arial" "Consolas" "Comic Sans MS" "Times"]
		react [f/font/name: pick face/data any [face/selected 3]]
		return
		
	txt "Font size" s: field "15" react [f/font/size: s/data]
	button "+" bold 40 [s/data: s/data + 1]
	button "-" bold 40 [s/data: max 1 s/data - 1]
	return
]

