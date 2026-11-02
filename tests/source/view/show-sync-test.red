Red [
	Title:	"Headless View test: show / auto-sync / deferred changes"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

bx: win: none

~~~start-file~~~ "show-sync-test"

===start-group=== "auto-sync applies facet changes immediately"
	--test-- "color change reflects without an explicit show"
		view/no-wait [bx: base 30x30]
		bx/color: 1.2.3
		--assert bx/color = 1.2.3
		unview/all
===end-group===

===start-group=== "auto-sync? default and toggling"
	--test-- "auto-sync? defaults to yes"
		--assert system/view/auto-sync?
	--test-- "toggling auto-sync? off and on"
		system/view/auto-sync?: no
		--assert not system/view/auto-sync?
		system/view/auto-sync?: yes
		--assert system/view/auto-sync?
===end-group===

===start-group=== "do-no-sync runs with auto-sync off, then restores"
	--test-- "auto-sync? is no inside, yes after"
		--assert system/view/auto-sync?
		do-no-sync [--assert not system/view/auto-sync?]
		--assert system/view/auto-sync?
===end-group===

===start-group=== "appending to pane shows the new child (auto-sync)"
	--test-- "appended face is added and gets state"
		win: view/no-wait [base 20x20]
		append win/pane make-face/offset/size 'button 50x10 40x12
		--assert 2 = length? win/pane
		--assert block? win/pane/2/state
		--assert same? win/pane/2/parent win
		unview/all
===end-group===

===start-group=== "SHOW applies the changes of a face tree together"
	--test-- "changes deferred in a tree are all applied by one SHOW"
		system/view/auto-sync?: no
		win: view/no-wait [
			sg-p1: panel 200x100 [sg-b1: base 20x20 sg-b2: base 20x20]
			sg-p2: panel 200x100 [sg-b3: base 20x20]
		]
		sg-b1/offset: 50x50
		sg-b2/visible?: no
		sg-p2/offset: sg-p2/offset + 10x10
		sg-b3/size: 30x30
		show win
		--assert zero? sg-b1/state/2
		--assert zero? sg-b2/state/2
		--assert zero? sg-p2/state/2
		--assert zero? sg-b3/state/2
	--test-- "a deferred draw change is applied with the group"
		sg-b1/draw: [box 0x0 5x5]
		show win
		append sg-b1/draw [box 1x1 3x3]
		show win
		--assert zero? sg-b1/state/2
		--assert empty? sg-b1/state/3
	--test-- "a SHOW run inside a group loses none of the group's changes"
		sg-b1/offset: 70x70
		sg-b3/offset: 15x15
		append sg-p2/pane layout/only [base 10x10 on-created [sg-b3/size: 25x25 show sg-p2]]
		show win
		--assert zero? sg-b1/state/2
		--assert zero? sg-b3/state/2
		--assert zero? sg-p2/state/2
		--assert block? sg-p2/pane/2/state
	--test-- "update-view rejects what is not a face"
		--assert error? try [system/view/platform/update-view 1]
		--assert error? try [system/view/platform/update-view [1]]
	--test-- "changes collected by an aborted SHOW are applied by the next SHOW"
		sg-b1/offset: 80x80
		modify sg-p1/pane 'owned none					;-- a non-face in the pane, unnoticed until SHOW
		append sg-p1/pane 'oops
		--assert error? try [show win]
		remove back tail sg-p1/pane
		modify sg-p1/pane 'owned reduce [sg-p1 'pane]
		show sg-p2										;-- any later SHOW of a face tree
		--assert zero? sg-b1/state/2
		system/view/auto-sync?: yes
		unview/all
===end-group===

~~~end-file~~~
