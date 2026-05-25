Red [
	Title:  "SDL3 View backend event smoke test"
	Needs:  View
	Config: [GUI-engine: 'SDL3]
]

events: copy []

view/no-wait layout [
	title "SDL3 events"
	field "edit me" on-key [append events 'key] on-change [append events 'change]
	button "Click" on-click [append events 'click]
	base 100x40 on-over [append events 'over]
	base 1x1 rate 20 on-time [append events 'time]
]

repeat i 5 [do-events/no-wait]
repeat i 10 [do-events]
unless find events 'time [1 / 0]
unview/all
