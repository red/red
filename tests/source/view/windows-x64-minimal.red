Red [
	Title: "Windows x86-64 minimal View smoke test"
	Needs: View
]

closed?: false
window: view/no-wait [
	title "Windows x64 View smoke"
	text "ready" rate 10 on-time [
		closed?: true
		unview/all
	]
]

repeat count 200 [
	do-events/no-wait
	if closed? [break]
	wait 0.01
]

unless closed? [
	print "FAIL: View window did not close"
	unview/all
	quit/return 1
]

repeat count 10 [do-events/no-wait]
write %windows-x64-view-smoke.ok "X64-VIEW-OK"
print "X64-VIEW-OK"
