Red [
	Title: "macOS ARM64 native View smoke test"
	Needs: View
]

marker: %macos-arm64-view-smoke.ok
error-file: %macos-arm64-view-smoke.error
if exists? marker [delete marker]
if exists? error-file [delete error-file]

fail: func [message [string!]][
	print rejoin ["MACOS-ARM64-VIEW-ERROR: " message]
	write error-file message
	unview/all
	quit/return 1
]

unless system/platform = 'macOS [fail "wrong platform"]
unless all [block? system/view/screens not empty? system/view/screens][
	fail "no screens discovered"
]

screen-face: first system/view/screens
unless all [
	pair? screen-face/size
	screen-face/size/x > 0
	screen-face/size/y > 0
	block? screen-face/state
	handle? screen-face/state/1
][fail "invalid screen face"]

click-count: 0
create-count: 0
clicker: none
field-face: none
check-face: none
slider-face: none
progress-face: none
drop-face: none
list-face: none
tabs-face: none
canvas: none
window: none
result: none

result: try/all [
	window: view/no-wait [
		title "Red Apple Silicon View smoke"
		on-created [create-count: create-count + 1]
		below
		text "Native controls" font-size 16
		across
		clicker: button "Dispatch" 100x28 [click-count: click-count + 1]
		field-face: field "initial" 150x28
		check-face: check "Enabled"
		return
		slider-face: slider 35% 150x24
		progress-face: progress 45% 150x18
		drop-face: drop-list 130x26 data ["One" "Two" "Three"] select 1
		return
		list-face: text-list 170x90 data ["Alpha" "Beta" "Gamma"] select 1
		tabs-face: tab-panel 240x90 [
			"First" [text "First tab"]
			"Second" [base 80x30 230.240.250]
		]
		return
		canvas: base 180x120 white draw [
			pen red
			line 5x5 175x115
			fill-pen blue
			box 30x20 150x100 6
			fill-pen yellow
			circle 90x60 22
		]
	]
]
if error? result [fail mold result]

repeat count 20 [
	do-events/no-wait
	wait 0.01
]

unless create-count = 1 [fail "on-created actor was not dispatched"]
do-actor clicker none 'click
unless click-count = 1 [fail "click actor was not dispatched"]

field-face/text: "updated"
check-face/data: true
slider-face/data: 70%
progress-face/data: 80%
list-face/selected: 2
drop-face/selected: 2
tabs-face/selected: 2
show [field-face check-face slider-face progress-face list-face drop-face tabs-face]

repeat count 20 [
	do-events/no-wait
	wait 0.01
]

unless all [
	field-face/text = "updated"
	check-face/data = true
	list-face/selected = 2
	drop-face/selected = 2
	tabs-face/selected = 2
][fail "native facet update failed"]

snapshot: to-image canvas
unless all [image? snapshot snapshot/size/x > 0 snapshot/size/y > 0][
	fail "to-image returned an invalid image"
]

corner: snapshot/(1x1)
center: snapshot/(as-pair (snapshot/size/x / 2) (snapshot/size/y / 2))
if corner = center [fail "Draw capture appears blank"]

unview/all
repeat count 20 [do-events/no-wait]

write marker "MACOS-ARM64-VIEW-OK"
print "MACOS-ARM64-VIEW-OK"
