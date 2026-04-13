Red [
	Title:   "GTK3 Bug A: on-resize not fired on maximize/restore"
	Purpose: "Verify that on-resize fires directly when maximizing and restoring without needing focus change"
	Needs:   'View
]

_spec-size: 600x400
_log: copy []

log-size: func [label sz /local delta] [
	delta: ""
	if _last-size <> 0x0 [
		if any [_last-size/x <> sz/x  _last-size/y <> sz/y] [
			delta: rejoin [" Δ=" sz/x - _last-size/x "x" sz/y - _last-size/y]
		]
	]
	append _log rejoin [label " " sz delta]
	probe rejoin [label " win:" sz delta]
	_last-size: sz
]
_last-size: 0x0

view/flags [
	title "Bug A: on-resize on maximize/restore"
	size _spec-size
	text "Maximize and restore the window."
	text "on-resize should fire WITHOUT needing Alt+Tab."
	text 200 wrap: "If on-resize only fires after Alt+Tab, Bug A is present."
	button "Print log" [probe _log]
	on-resize [log-size "on-resize" face/size]
	on-focus [log-size "on-focus" face/size]
	on-unfocus [log-size "on-unfocus" face/size]
] [resize]