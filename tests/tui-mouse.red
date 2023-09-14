Red [
	Needs: 'View
	Config: [GUI-engine: 'terminal]
]

system/view/platform/mouse-event?: yes

view/tight [
	on-key [if event/key = #"^[" [unview/all]]
	origin 5x2 space 1x2
	t: text 30x1  "0x0" return
	b: base 10x1 red return
	button 15x1 "mouse click me" [
		b/visible?: not b/visible?
		b2/enabled?: not b2/enabled?
		t/text: "click"
	] on-dbl-click [t/text: "double click"] return
	b2: base 30x5 all-over center middle "moving mouse on here"
		on-over		[t/text: rejoin [mold event/offset " " mold event/flags]]
		on-down		[t/text: rejoin ["mouse down " mold event/offset]]
		on-up		[t/text: rejoin ["mouse up " mold event/offset]]
		on-mid-down	[t/text: rejoin ["mouse mid down " mold event/offset]]
		on-mid-up	[t/text: rejoin ["mouse mid up " mold event/offset]]
		on-alt-down	[t/text: rejoin ["mouse alt down " mold event/offset]]
		on-alt-up	[t/text: rejoin ["mouse alt up " mold event/offset]]
		on-wheel	[t/text: rejoin ["mouse wheel " mold event/picked " " mold event/offset]]
]