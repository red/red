Red [
	Title:   "GTK3 face/size client area test"
	Purpose: "Verify that face/size reports the client area, not the full window allocation"
	Needs:   'View
]

view/flags [
	title "GTK3 face/size test"
	size 400x300
	on-resize [probe face/size]
	button "Print face/size" [probe face/parent/size]
] [resize]