Red [Needs: 'View]

system/view/platform/mouse-event?: yes

view/tight [
	on-key [if event/key = #"^[" [unview/all]]
	origin 5x3 space 1x2
	t: text 30x1  "abc" return
	base 30x5 all-over 
		on-over		[t/text: rejoin [mold event/offset " " mold event/flags]]
		on-down		[t/text: "mouse down"]
		on-up		[t/text: "mouse up"]
		on-mid-down	[t/text: "mouse mid down"]
		on-mid-up	[t/text: "mouse mid up"]
		on-alt-down	[t/text: "mouse alt down"]
		on-alt-up	[t/text: "mouse alt up"]
		on-wheel	[t/text: mold event/picked]
]