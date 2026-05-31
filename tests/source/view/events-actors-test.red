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

===start-group=== "dispatching a change event fires on-change"
	--test-- "check on-change fires"
		changed?: no
		p: layout [check on-change [changed?: yes]]
		do-actor p/pane/1 make event! [type: 'change] 'change
		--assert changed?
===end-group===

~~~end-file~~~
