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

~~~end-file~~~
