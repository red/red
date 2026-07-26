Red [
	Title:	"Headless View test: VID built-in & user styles"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "vid-styles-test"

===start-group=== "built-in styles: type & default size"
	--test-- "base 80x80"
		p: layout [base]      --assert p/pane/1/type = 'base       --assert p/pane/1/size = 80x80
	--test-- "button 60x23"
		p: layout [button]    --assert p/pane/1/type = 'button     --assert p/pane/1/size = 60x23
	--test-- "text 80x23"
		p: layout [text]      --assert p/pane/1/type = 'text       --assert p/pane/1/size = 80x23
	--test-- "field 80x23"
		p: layout [field]     --assert p/pane/1/type = 'field      --assert p/pane/1/size = 80x23
	--test-- "area 150x150"
		p: layout [area]      --assert p/pane/1/type = 'area       --assert p/pane/1/size = 150x150
	--test-- "toggle 60x23"
		p: layout [toggle]    --assert p/pane/1/type = 'toggle     --assert p/pane/1/size = 60x23
	--test-- "check 80x23"
		p: layout [check]     --assert p/pane/1/type = 'check      --assert p/pane/1/size = 80x23
	--test-- "radio 80x23"
		p: layout [radio]     --assert p/pane/1/type = 'radio      --assert p/pane/1/size = 80x23
	--test-- "progress 150x16"
		p: layout [progress]  --assert p/pane/1/type = 'progress   --assert p/pane/1/size = 150x16
	--test-- "slider 150x23"
		p: layout [slider]    --assert p/pane/1/type = 'slider     --assert p/pane/1/size = 150x23
	--test-- "text-list 100x140"
		p: layout [text-list] --assert p/pane/1/type = 'text-list  --assert p/pane/1/size = 100x140
	--test-- "drop-list 100x23"
		p: layout [drop-list] --assert p/pane/1/type = 'drop-list  --assert p/pane/1/size = 100x23
	--test-- "drop-down 100x23"
		p: layout [drop-down] --assert p/pane/1/type = 'drop-down  --assert p/pane/1/size = 100x23
===end-group===

===start-group=== "default data"
	--test-- "slider data = 0%"
		p: layout [slider] --assert p/pane/1/data = 0%
	--test-- "check data = none"
		p: layout [check]  --assert none? p/pane/1/data
===end-group===

===start-group=== "default colors"
	--test-- "base defaults to 128.128.128"
		p: layout [base] --assert p/pane/1/color = 128.128.128
	--test-- "box is base + transparent"
		p: layout [box]  --assert p/pane/1/type = 'base  --assert none? p/pane/1/color
===end-group===

===start-group=== "heading styles map to text with fixed font sizes"
	--test-- "h1 = 32"
		p: layout [h1 "X"] --assert p/pane/1/type = 'text --assert p/pane/1/font/size = 32
	--test-- "h2 = 26"
		p: layout [h2 "X"] --assert p/pane/1/font/size = 26
	--test-- "h3 = 22"
		p: layout [h3 "X"] --assert p/pane/1/font/size = 22
	--test-- "h4 = 17"
		p: layout [h4 "X"] --assert p/pane/1/font/size = 17
	--test-- "h5 = 13"
		p: layout [h5 "X"] --assert p/pane/1/font/size = 13
===end-group===

===start-group=== "containers"
	--test-- "panel 200x200"
		p: layout [panel []]               --assert p/pane/1/type = 'panel     --assert p/pane/1/size = 200x200
	--test-- "group-box 50x50"
		p: layout [group-box []]           --assert p/pane/1/type = 'group-box --assert p/pane/1/size = 50x50
	--test-- "tab-panel"
		p: layout [tab-panel ["t" [base]]] --assert p/pane/1/type = 'tab-panel
===end-group===

===start-group=== "user style (panel-local)"
	--test-- "style inherits base + applied options"
		p: layout [style base2: base 30x30 red  base2]
		--assert p/pane/1/type = 'base
		--assert p/pane/1/size = 30x30
		--assert p/pane/1/color = 255.0.0
===end-group===

~~~end-file~~~
