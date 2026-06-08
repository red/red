Red [
	Title:  "Red - send-event multi-widget demo"
	Needs:  View
]

AUTOPLAY: no			;-- no = click Start to run; set to  yes  to run automatically

;-- faces + run state
hit: fld: echo: lst: rate-dd: status: go: reset-btn: items: btn: chk: base-status: btn-status: chk-status: none
clicks: 0
btn-clicks: 0
got-keydown: none
got-aux: none
got-wheel-sel: none
over-fired?: dbl-fired?: chk-changed?: no
started?: no
n: 0

list-data:   collect [repeat i 12 [keep rejoin ["item " i]]]
rate-labels: ["1 / sec" "1.5 / sec" "2 / sec" "3 / sec" "5 / sec"]
rate-values: [1 0:0:0.66 2 3 5]		;-- parallel to rate-labels: Hz integers or time! intervals for the on-time facet

;-- the action list: each entry is [ make-event-spec-block  delivery-mode ].
;-- the SAME spec block is both sent (make event! spec) and shown in the queue (mold spec).
;-- sync for the actor-drawn base/list; /no-wait (full pump) for native widgets (field/button/check).
actions: collect [
	keep/only reduce [[type: 'down      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'down      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'over      face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'dbl-click  face: hit offset: 90x22] 'sync]
	keep/only reduce [[type: 'key-down   key: #"r" face: hit] 'sync]		;-- char->VK: lowercase r must arrive as 'R, not VK_F3
	keep/only reduce [[type: 'aux-down   face: hit] 'sync]				;-- aux/X1 button (newly dispatched on Windows)
	keep/only reduce [[type: 'aux-up     face: hit] 'sync]
	keep/only reduce [[type: 'wheel      picked: 5 face: lst] 'sync]		;-- wheel delta -> scrolls the list selection
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
rows: collect [repeat i length? actions [keep compose [text 440x22 (row-label " " i me-text i)]]]

win: layout compose/deep [
	title "Red - self-driving UI via send-event"
	backdrop 245.245.250
	across
	panel 250x470 [
		below  space 0x5
		text "Live widgets (internal name in parens)" font [style: 'bold size: 9]
		hit: base 200x40 200.220.255 "click target  (hit)" center middle
			on-down      [clicks: clicks + 1  hit/color: random 200.230.255  base-status/text: rejoin ["on-down x" clicks]]
			on-over      [over-fired?: yes  hit/color: 255.255.140  base-status/text: "on-over (highlight)"]
			on-dbl-click [dbl-fired?: yes  hit/color: 255.180.180  base-status/text: "on-dbl-click!"]
			on-key-down  [got-keydown: event/key  base-status/text: rejoin ["on-key-down: event/key = " mold event/key]]
			on-aux-down  [got-aux: 'down  base-status/text: "on-aux-down (X1)"]
			on-aux-up    [got-aux: 'up    base-status/text: "on-aux-up (X1)"]
		base-status: text 200 "(base idle)" font [color: 90.90.90 size: 9]
		btn: button "a button  (btn)" 200 on-click [btn-clicks: btn-clicks + 1  btn-status/text: rejoin ["on-click x" btn-clicks]]
		btn-status: text 200 "(button idle)" font [color: 90.90.90 size: 9]
		chk: check "a checkbox  (chk)" on-change [chk-changed?: yes  chk-status/text: either chk/data ["on-change: checked"]["on-change: unchecked"]]
		chk-status: text 200 "(checkbox idle)" font [color: 90.90.90 size: 9]
		text "field  (fld):"  fld: field 200 on-key [echo/text: append echo/text event/key]
		echo: text 200 "(on-key echo)" font [color: 0.120.0 size: 9]
		text "list  (lst) -- on-wheel scrolls selection:"
		lst: text-list 200x72
			on-wheel [
				d: to integer! event/picked
				pos: any [lst/selected 0]
				if pos < 1 [pos: 0]
				pos: pos + d
				if pos < 1 [pos: 1]
				if pos > length? lst/data [pos: length? lst/data]
				lst/selected: pos
				got-wheel-sel: pos
			]
	]
	panel 470x470 [
		below
		text "Event queue  (the make event! sent per action)" font [style: 'bold size: 9]
		items: panel 450x430 [below space 0x2 (rows)]
	]
	return
	across
	go:        button "Start" 90 [start-run]
	reset-btn: button "Reset" 90 [reset-demo]
	text "rate:"
	rate-dd:   drop-list 110 on-change [status/rate: pick rate-values face/selected]	;-- pick the timer rate from the list
	status:    text "Click Start to run." 320 font [size: 9]
	rate 0:0:0.66 on-time [if started? [step-once]]		;-- default ~1.5/sec; overridden by the drop-list
]

;-- each row gets its own (small) font so greying one doesn't grey them all
foreach row items/pane [row/font: make font! [name: font-fixed size: 9 color: 30.30.30]]	;-- font-fixed = platform monospace
lst/data: list-data									;-- populate the list after layout (not via compose, which would splice the block)
rate-dd/data: rate-labels  rate-dd/selected: 2		;-- default "1.5 / sec" (matches the layout's rate 0:0:0.66)

start-run: does [
	started?: yes
	go/enabled?: no
	n: 0
	status/text: "Running -- sending events at the selected rate..."
]

;-- restore everything to the initial state so Start can run again, no app restart
reset-demo: does [
	started?: no
	n: 0
	clicks: 0  btn-clicks: 0
	over-fired?: dbl-fired?: chk-changed?: no
	got-keydown: none  got-aux: none  got-wheel-sel: none
	hit/color: 200.220.255
	base-status/text: "(base idle)"
	btn-status/text:  "(button idle)"
	chk-status/text:  "(checkbox idle)"
	chk/data: false
	lst/selected: 1		;-- first scroll the list back to the top (LB_SETCURSEL 0)...
	show lst
	lst/selected: -1	;-- ...then clear the selection (engine fix: selected < 1 -> LB_SETCURSEL -1)
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
			print ["key-down=" mold got-keydown " aux=" mold got-aux " wheel->list selected=" got-wheel-sel]
			print ["field=" mold fld/text " row1=" mold items/pane/1/text]
			reset-demo
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
