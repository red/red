Red [
	Title:  "Red - send-event multi-widget demo"
	Needs:  View
]

AUTOPLAY: no			;-- no = click Start to run; set to  yes  to run automatically

;-- faces + run state
hit: fld: echo: status: go: reset-btn: items: btn: chk: base-status: btn-status: chk-status: none
clicks: 0
btn-clicks: 0
over-fired?: dbl-fired?: chk-changed?: no
started?: no
n: 0

;-- the action list: each entry is [ make-event-spec-block  delivery-mode ].
;-- the SAME spec block is both sent (make event! spec) and shown in the queue (mold spec).
;-- sync for the actor-drawn base; /no-wait (full pump) for native widgets (field/button/check).
actions: collect [
	keep/only reduce [[type: 'down      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'down      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'over      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'dbl-click face: hit offset: 90x22] 'sync]
	foreach ch "Red" [keep/only reduce [compose [type: 'key key: (ch) face: fld] 'nowait]]
	keep/only reduce [[type: 'down face: btn offset: 40x14] 'nowait]
	keep/only reduce [[type: 'up   face: btn offset: 40x14] 'nowait]
	keep/only reduce [[type: 'down face: chk offset: 8x8]   'nowait]
	keep/only reduce [[type: 'up   face: chk offset: 8x8]   'nowait]
]

me-text:   function [idx [integer!]][rejoin ["make event! " mold actions/:idx/1]]
row-label: function [mark [string!] idx [integer!] caption [string!]][
	num: form idx
	if 1 = length? num [insert num " "]
	rejoin [mark " " num ". " caption]
]

;-- one queue row per action, showing the make event! spec
rows: collect [repeat i length? actions [keep compose [text 410x22 (row-label " " i me-text i)]]]

win: layout compose/deep [
	title "Red - self-driving UI via send-event"
	backdrop 245.245.250
	across
	panel 250x360 [
		below  space 0x6
		text "Live widgets (internal name in parens)" font [style: 'bold]
		hit: base 200x40 200.220.255 "click target  (hit)" center middle
			on-down      [clicks: clicks + 1  hit/color: random 200.230.255  base-status/text: rejoin ["on-down x" clicks]]
			on-over      [over-fired?: yes  hit/color: 255.255.140  base-status/text: "on-over (highlight)"]
			on-dbl-click [dbl-fired?: yes  hit/color: 255.180.180  base-status/text: "on-dbl-click!"]
		base-status: text 200 "(base idle)" font [color: 90.90.90]
		btn: button "a button  (btn)" 200 on-click [btn-clicks: btn-clicks + 1  btn-status/text: rejoin ["on-click x" btn-clicks]]
		btn-status: text 200 "(button idle)" font [color: 90.90.90]
		chk: check "a checkbox  (chk)" on-change [chk-changed?: yes  chk-status/text: either chk/data ["on-change: checked"]["on-change: unchecked"]]
		chk-status: text 200 "(checkbox idle)" font [color: 90.90.90]
		text "field  (fld):"
		fld: field 200 on-key [echo/text: append echo/text event/key]
		text "echo  (what on-key received):"
		echo: text 200 "" font [color: 0.120.0]
	]
	panel 440x360 [
		below
		text "Event queue  (the make event! sent per action)" font [style: 'bold]
		items: panel 420x300 [below space 0x2 (rows)]
	]
	return
	across
	go:        button "Start" 90 [start-run]
	reset-btn: button "Reset" 90 [reset-demo]
	status:    text "Click Start to run." 380
	rate 0:0:0.66 on-time [if started? [step-once]]		;-- ~1.5 actions / second, gated by Start
]

;-- each row gets its own (small) font so greying one doesn't grey them all
foreach row items/pane [row/font: make font! [name: font-fixed size: 9 color: 30.30.30]]	;-- font-fixed = platform monospace (Consolas on Win Vista+, Courier New on XP, Menlo/SF Mono on macOS...)

start-run: does [
	started?: yes
	go/enabled?: no
	n: 0
	status/text: "Running -- ~1.5 events/second..."
]

;-- restore everything to the initial state so Start can run again, no app restart
reset-demo: does [
	started?: no
	n: 0
	clicks: 0  btn-clicks: 0
	over-fired?: dbl-fired?: chk-changed?: no
	hit/color: 200.220.255
	base-status/text: "(base idle)"
	btn-status/text:  "(button idle)"
	chk-status/text:  "(checkbox idle)"
	chk/data: false
	fld/text:  copy ""
	echo/text: copy ""
	repeat i length? actions [
		row: items/pane/:i
		row/text: row-label " " i me-text i
		row/font/color: 30.30.30
	]
	go/enabled?: yes
	status/text: "Reset -- click Start to run again."
	show win
]

step-once: does [
	either n >= length? actions [
		started?: no
		status/text: "Done -- all actions sent, no human input."
		if AUTOPLAY [
			print ["clicks=" clicks " over?=" over-fired? " dbl?=" dbl-fired? " btn=" btn-clicks " check=" chk/data]
			print ["field=" mold fld/text " row1=" mold items/pane/1/text]
			reset-demo
			print ["after reset -> clicks=" clicks " field=" mold fld/text " row1=" mold items/pane/1/text]
		]
	][
		n: n + 1
		spec: actions/:n/1
		either actions/:n/2 = 'nowait [send-event/no-wait make event! spec][send-event make event! spec]
		row: items/pane/:n
		row/text: row-label "✔" n me-text n
		row/font/color: 165.165.165
		show row
		if AUTOPLAY [print ["sent #" n ":" me-text n]]
	]
]

if AUTOPLAY [start-run]
view win
