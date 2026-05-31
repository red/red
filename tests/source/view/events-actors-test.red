Red [
	Title:	"Headless View test: event dispatch, bubbling & actors"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

kid: kid2: bk: ck: none
parent-hit: parent-hit2: got-ctrl: changed?: no
got-key: none

~~~start-file~~~ "events-actors-test"

===start-group=== "event bubbling"
	--test-- "click on a child with no on-click bubbles to the parent"
		parent-hit: no
		view/no-wait [
			panel 200x200 on-click [parent-hit: yes] [
				kid: field
			]
		]
		set-focus kid
		do-event 'click
		--assert parent-hit
		unview/all
	--test-- "returning 'done from the child stops propagation"
		parent-hit2: no
		view/no-wait [
			panel 200x200 on-click [parent-hit2: yes] [
				kid2: field on-click ['done]
			]
		]
		set-focus kid2
		do-event 'click
		--assert not parent-hit2
		unview/all
===end-group===

===start-group=== "event fields readable in actors"
	--test-- "actor reads event/key"
		got-key: none
		view/no-wait [bk: base 40x40 on-key [got-key: event/key]]
		set-focus bk
		do-event/with 'key #"Z"
		--assert got-key = #"Z"
		unview/all
	;; NOTE: do-event declares /flags but does not apply it, so synthesized
	;; modifier state (event/ctrl?, event/shift?, ...) is not testable yet.
===end-group===

===start-group=== "click maps to change for check/radio"
	--test-- "clicking a check fires on-change"
		changed?: no
		view/no-wait [ck: check on-change [changed?: yes]]
		set-focus ck
		do-event 'click
		--assert changed?
		unview/all
===end-group===

~~~end-file~~~
