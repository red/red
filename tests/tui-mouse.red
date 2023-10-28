Red [
	Needs: 'View
	Config: [GUI-engine: 'terminal]
]

system/view/platform/mouse-event?: yes

view/tight [
	on-key [if event/key = #"^[" [unview/all]]
	origin 5x2 space 1x2
	t: text 30 "0x0" return
	b: base 30x5 all-over center middle "moving mouse on here"
		on-over		[t/text: rejoin [mold event/offset " " mold event/flags]]
		on-down		[t/text: rejoin ["mouse down " mold event/offset]]
		on-up		[t/text: rejoin ["mouse up " mold event/offset]]
		on-mid-down	[t/text: rejoin ["mouse mid down " mold event/offset]]
		on-mid-up	[t/text: rejoin ["mouse mid up " mold event/offset]]
		on-alt-down	[t/text: rejoin ["mouse alt down " mold event/offset]]
		on-alt-up	[t/text: rejoin ["mouse alt up " mold event/offset]]
		on-wheel	[t/text: rejoin ["mouse wheel " mold event/picked " " mold event/offset]]
	base 11x1 center "drag me" red loose
	return
	text 7 "Input: " field "Hello 😀 World!" on-click [t/text: "click"] return
	button "Click here to hide face" [
		b/visible?: not b/visible?
		face/text: either b/visible? [
			"Click here to hide face"
		][
			"Click here to show face"
		]
		t/text: "click"
	] return
	button "Dbl-click here to disable face" on-dbl-click [
		b/enabled?: not b/enabled?
		face/text: either b/enabled? [
			"Dbl-click here to disable face"
		][
			"Dbl-click here to enable face"
		]
		t/text: "double click"
	] return

	text font-color gray "ESC to quit"
]