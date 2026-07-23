Red [
	Title:	"Headless View test: VID window facets & layout return value"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

fld: none

~~~start-file~~~ "vid-window-test"

===start-group=== "layout return value"
	--test-- "layout returns a window face with a pane"
		p: layout [button "x"]
		--assert object? p
		--assert p/type = 'window
		--assert block? p/pane
		--assert 1 = length? p/pane
	--test-- "/only returns the pane block, no window"
		pane: layout/only [button "a" button "b"]
		--assert block? pane
		--assert 2 = length? pane
		--assert pane/1/type = 'button
===end-group===

===start-group=== "window facets from VID settings"
	--test-- "title sets window text"
		p: layout [title "My Win" button "x"]
		--assert p/text = "My Win"
	--test-- "size sets window size"
		p: layout [size 300x200 button "x"]
		--assert p/size = 300x200
	--test-- "backdrop sets window color"
		p: layout [backdrop blue button "x"]
		--assert p/color = 0.0.255
	--test-- "window auto-sizes to its content"
		p: layout [base 50x40]
		--assert p/size/x >= 60
		--assert p/size/y >= 50
===end-group===

===start-group=== "named faces resolvable after layout"
	--test-- "set-word binds the live face object"
		p: layout [fld: field "hi"]
		--assert object? fld
		--assert fld/type = 'field
		--assert same? fld p/pane/1
===end-group===

===start-group=== "GUI-rules: OK/Cancel button ordering"
	--test-- "rules off: declared order kept (cancel left of ok)"
		system/view/VID/GUI-rules/active?: no
		p: layout [button "cancel" button "ok"]
		--assert p/pane/1/text = "cancel"
		--assert p/pane/1/offset/x < p/pane/2/offset/x
	if system/platform = 'Windows [					;-- OK-Cancel reorder is a Windows-only rule (macOS: Cancel-OK/capitalize, Linux: no rules)
		--test-- "rules on: cancel pushed to the right of ok"
			system/view/VID/GUI-rules/active?: yes
			p: layout [button "cancel" button "ok"]
			ok-face: cancel-face: none
			foreach face p/pane [
				if face/text = "ok"     [ok-face: face]
				if face/text = "cancel" [cancel-face: face]
			]
			--assert cancel-face/offset/x > ok-face/offset/x
			system/view/VID/GUI-rules/active?: no
	]
	if system/platform = 'Linux [					;-- no GUI rules on Linux: rules on must keep the declared order
		--test-- "rules on: declared order kept (no rules on this platform)"
			system/view/VID/GUI-rules/active?: yes
			p: layout [button "cancel" button "ok"]
			--assert p/pane/1/text = "cancel"
			--assert p/pane/1/offset/x < p/pane/2/offset/x
			system/view/VID/GUI-rules/active?: no
	]
	if system/platform = 'macOS [					;-- macOS rules: adjust-buttons + capitalize + Cancel-OK
		--test-- "rules on: ok pushed to the right of cancel, captions title-ized"
			system/view/VID/GUI-rules/active?: yes
			p: layout [button "ok" button "cancel"]	;-- declared ok-first: Cancel-OK must put OK last
			ok-face: cancel-face: none
			foreach face p/pane [					;-- = is case-insensitive: finds them capitalized or not
				if face/text = "ok"     [ok-face: face]
				if face/text = "cancel" [cancel-face: face]
			]
			--assert "Ok" == ok-face/text			;-- capitalize: title-ized captions (strict compare)
			--assert "Cancel" == cancel-face/text
			--assert ok-face/offset/x > cancel-face/offset/x	;-- Cancel-OK: the OK button goes last
			--assert ok-face/size/y = 28			;-- adjust-buttons: 23 -> 'small class -> 28
			system/view/VID/GUI-rules/active?: no
	]
===end-group===

~~~end-file~~~
