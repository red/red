Red [
	Title:  "Red TUI test script"
	Needs:	'View
	Config: [GUI-engine: 'terminal]
]

system/view/platform/mouse-event?: yes

view [
	rich-text transparent wrap data [ "Select some text with your mouse"]
	on-down [
		bkg: reduce [ ; Background for selected text
			as-pair caret: offset-to-caret face event/offset 0
			'backdrop purple
		]
		either zero? length? face/data [ ; On first selection
			pos: tail face/data
			append face/data bkg
		][ ; Changing starting pos on subsequent selections
			change pos bkg/1
		]
	] all-over
	on-over [
		if event/down? [ ; On dragging change only length
			pos/1/2: (offset-to-caret face event/offset) - caret
		]
	]
]

view [
    t: rich-text 3x3 wrap data ["abcabc"]
    button "check" [
	    repeat idx 6 [
		    print ["Position:" idx "Offset:" caret-to-offset t idx "lower: " caret-to-offset/lower t idx]
		]
	]
]