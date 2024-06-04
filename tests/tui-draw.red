Red [
	Title:  "Red TUI Draw test script"
	Needs:  'View
	Config: [GUI-engine: 'terminal]
]

paint: function [][
	list: make block! 100
	loop 20 [repend list ['pen random white 'line random 80x40 random 80x40]]
	view compose/deep [base black 80x40 draw [(list)]]
]

paint