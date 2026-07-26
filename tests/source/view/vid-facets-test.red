Red [
	Title:	"Headless View test: VID facet setters (literals & keywords)"
	Author:	"Red test suite"
	Needs:	View
	Config:	[GUI-engine: 'test]
]

#include %../../../quick-test/quick-test.red

system/view/VID/GUI-rules/active?: no

~~~start-file~~~ "vid-facets-test"

===start-group=== "literal value -> facet"
	--test-- "pair -> size"
		p: layout [base 50x40]            --assert p/pane/1/size = 50x40
	--test-- "string -> text"
		p: layout [button "Hi"]           --assert p/pane/1/text = "Hi"
	--test-- "tuple -> color"
		p: layout [base red]              --assert p/pane/1/color = 255.0.0
	--test-- "second tuple -> font color"
		p: layout [text "x" red blue]
		--assert p/pane/1/color = 255.0.0
		--assert p/pane/1/font/color = 0.0.255
	--test-- "issue hex -> color"
		p: layout [base #FF8800]          --assert p/pane/1/color = 255.136.0
	--test-- "percent -> data"
		p: layout [progress 50%]          --assert p/pane/1/data = 50%
	--test-- "logic -> data"
		p: layout [check true]            --assert p/pane/1/data
	--test-- "integer -> width"
		p: layout [base 100]              --assert p/pane/1/size = 100x80
===end-group===

===start-group=== "flag keywords"
	--test-- "hidden -> visible? false"
		p: layout [field hidden]          --assert not p/pane/1/visible?
	--test-- "disabled -> enabled? false"
		p: layout [field disabled]        --assert not p/pane/1/enabled?
	--test-- "all-over -> flags"
		p: layout [base all-over]         --assert not none? find to-block p/pane/1/flags 'all-over
	--test-- "focus -> window/selected is the face"
		p: layout [field focus]           --assert same? p/selected p/pane/1
===end-group===

===start-group=== "font keywords"
	--test-- "font-size"
		p: layout [text "x" font-size 18]        --assert p/pane/1/font/size = 18
	--test-- "font-name"
		p: layout [text "x" font-name "Arial"]   --assert p/pane/1/font/name = "Arial"
	--test-- "font-color"
		p: layout [text "x" font-color green]    --assert p/pane/1/font/color = 0.255.0
	--test-- "bold + italic accumulate in font/style"
		p: layout [text "x" bold italic]
		--assert not none? find to-block p/pane/1/font/style 'bold
		--assert not none? find to-block p/pane/1/font/style 'italic
===end-group===

===start-group=== "alignment & paragraph"
	--test-- "left -> para/align"
		p: layout [text "x" left]    --assert p/pane/1/para/align = 'left
	--test-- "center -> para/align"
		p: layout [text "x" center]  --assert p/pane/1/para/align = 'center
	--test-- "right -> para/align"
		p: layout [text "x" right]   --assert p/pane/1/para/align = 'right
	--test-- "wrap -> para/wrap?"
		p: layout [area "x" wrap]    --assert p/pane/1/para/wrap?
===end-group===

===start-group=== "value keywords"
	--test-- "extra"
		p: layout [base extra 42]                          --assert p/pane/1/extra = 42
	--test-- "data <expr> is evaluated"
		p: layout [base data 1 + 2]                        --assert p/pane/1/data = 3
	--test-- "select -> selected"
		p: layout [text-list data ["a" "b" "c"] select 2]  --assert p/pane/1/selected = 2
===end-group===

~~~end-file~~~
