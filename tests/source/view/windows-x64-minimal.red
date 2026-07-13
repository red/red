Red [
	Title: "Windows x86-64 minimal View smoke test"
	Needs: View
]

window: view/no-wait [
	title "Windows x64 View smoke"
	text "ready"
	panel 200x200 [
		backdrop black
		origin 0x0
		space 0x0
		at 60x0 base 140x140 0.0.255.128
		at 0x60 base 140x140 0.0.255.128
	]
]

repeat count 20 [
	do-events/no-wait
	wait 0.01
]

unview/all
repeat count 20 [do-events/no-wait]
write %windows-x64-view-smoke.ok "X64-VIEW-OK"
print "X64-VIEW-OK"
