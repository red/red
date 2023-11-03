Red [
	Title:   "Red VID and Draw simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %shield.red
	Needs:	 'View
]

shield: [
	fill-pen red   circle (50,50) 50
	pen gray
	fill-pen white circle (50,50) 40
	fill-pen red   circle (50,50) 30
	fill-pen blue  circle (50,50) 20

	pen blue fill-pen white
	polygon (32,44) (45,44) (50,30) (55,44) (68,44) (57,53) (60,66) (50,58) (39,66) (43,53)
]

;-- Draw in a draggable face, in realtime.
view [
	size (300,300)
	img: box (101,101) draw shield loose
	at (200,200) base white bold react [
		[img/offset]
		over?: overlap? face img
		face/color: get pick [red white] over?
		face/text: pick ["Hit!" ""] over?
	]
	button "Hulk-ize!" [replace/all shield 'red 'green]
	button "Restore"   [replace/all shield 'green 'red]
]