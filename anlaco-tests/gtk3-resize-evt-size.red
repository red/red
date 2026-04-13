Red [
	Title:   "GTK3 Bug A: on-resize not fired on maximize/restore"
	Purpose: "Verify that on-resize fires directly when maximizing and restoring"
	Needs:   'View
]

view/flags [
	title "Bug A: on-resize on maximize/restore"
	size 600x400
	on-resize [probe reduce ["on-resize" face/size]]
	on-focus  [probe reduce ["on-focus"  face/size]]
	on-unfocus[probe reduce ["on-unfocus" face/size]]
] [resize]