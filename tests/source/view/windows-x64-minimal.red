Red [
	Title: "Windows x86-64 minimal View smoke test"
	Needs: View
]

default-text: none

window: view/no-wait [
	title "Windows x64 View smoke"
	default-text: text "This window is a workaround for R2 call bug which hides first one (or more??) windows"
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

unless default-text/size/x > 200 [
	print rejoin ["DEFAULT-TEXT-SIZE-ERROR: " mold default-text/size]
	quit/return 1
]

unview/all
repeat count 20 [do-events/no-wait]
write %windows-x64-view-smoke.ok "X64-VIEW-OK"
print "X64-VIEW-OK"
