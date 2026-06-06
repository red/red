Red [
	Title:	"Headless View test: event dispatch, bubbling & actors"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

parent-hit: parent-hit2: got-ctrl: got-shift: changed?: no
got-key: none
got-face: got-offset: got-picked: bx: e: none

~~~start-file~~~ "events-actors-test"

===start-group=== "event bubbling via awake (synthetic events)"
	--test-- "click on a child with no on-click bubbles to the parent"
		parent-hit: no
		p: layout [
			panel 200x200 on-click [parent-hit: yes] [
				field
			]
		]
		kid: p/pane/1/pane/1
		system/view/awake/with make event! [type: 'click] kid
		--assert parent-hit
	--test-- "returning 'done from the child stops propagation"
		parent-hit2: no
		p: layout [
			panel 200x200 on-click [parent-hit2: yes] [
				field on-click ['done]
			]
		]
		kid: p/pane/1/pane/1
		system/view/awake/with make event! [type: 'click] kid
		--assert not parent-hit2
===end-group===

===start-group=== "event fields readable in actors"
	--test-- "actor reads event/key from a synthetic key event"
		got-key: none
		p: layout [base 40x40 on-key [got-key: event/key]]
		do-actor p/pane/1 make event! [type: 'key key: #"Z"] 'key
		--assert got-key = #"Z"
	--test-- "actor reads modifier state (event/ctrl?, event/shift?)"
		got-ctrl: got-shift: no
		p: layout [base 40x40 on-key [got-ctrl: event/ctrl?  got-shift: event/shift?]]
		do-actor p/pane/1 make event! [type: 'key key: #"Z" flags: [control]] 'key
		--assert got-ctrl
		--assert not got-shift
===end-group===

===start-group=== "fully-specified synthetic event (face/offset/picked, evaluated)"
	--test-- "actor reads event/face, event/offset, event/picked (survives GC)"
		got-face: got-offset: got-picked: none
		p: layout [base 40x40 on-down [got-face: event/face  got-offset: event/offset  got-picked: event/picked]]
		bx: p/pane/1
		e: make event! [type: 'down face: bx offset: 25x30 picked: 3]	;-- `face: bx` is evaluated -- no compose
		recycle															;-- the extras node must survive GC (collector marks it)
		do-actor bx e 'down
		--assert same? bx got-face
		--assert got-offset = 25x30
		--assert got-picked = 3
	--test-- "an event with no extras falls back to defaults"
		got-face: got-offset: got-picked: none
		p: layout [base 40x40 on-down [got-face: event/face  got-offset: event/offset  got-picked: event/picked]]
		do-actor p/pane/1 make event! [type: 'down] 'down
		--assert none? got-face
		--assert got-offset = 0x0
		--assert got-picked = 0
===end-group===

===start-group=== "dispatching a change event fires on-change"
	--test-- "check on-change fires"
		changed?: no
		p: layout [check on-change [changed?: yes]]
		do-actor p/pane/1 make event! [type: 'change] 'change
		--assert changed?
===end-group===

~~~end-file~~~
