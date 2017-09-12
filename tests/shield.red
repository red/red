Red [
	Title:   "Red VID and Draw simple test script"
	Author:  "Nenad Rakocevic"
	File: 	 %shield.red
	Needs:	 'View
]

shield: [
	fill-pen red   circle 50x50 50
	pen gray
	fill-pen white circle 50x50 40
	fill-pen red   circle 50x50 30
	fill-pen blue  circle 50x50 20

	pen blue fill-pen white
	polygon 32x44 45x44 50x30 55x44 68x44 57x53 60x66 50x58 39x66 43x53
]

;-- Draw in a draggable face, in realtime.
view [
	size 300x300
	img: box 101x101 draw shield loose
	at 200x200 base white bold react [
		[img/offset]
		over?: overlap? face img
		face/color: get pick [red white] over?
		face/text: pick ["Hit!" ""] over?
	]
	button "Hulk-ize!" [replace/all shield 'red 'green]
	button "Restore"   [replace/all shield 'green 'red]
]