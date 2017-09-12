Red [
	Title:   "Red dynamic GUI test script"
	Author:  "Nenad Rakocevic"
	File: 	 %dyn-gui.red
	Needs:	 'View
]

langs:  ["English" "French" "中文"]
labels: [
	["Name" "Age" "Phone" "Cancel" "Submit"]
	["Nom" "Age" "Tél." "Abandon" "Envoyer"]
	["名字" "年龄" "电话" "取消" "提交"]
]

set-lang: function [f event][
	root: f/parent
	condition: [all [face/text face/type <> 'drop-list]]

	list: collect [foreach-face/with root [keep face/text] condition]
	forall list [append clear list/1 labels/(f/selected)/(index? list)]

	foreach-face/with root [
		pads: any [metrics?/total face 'paddings 'x 0]
		prev: face/size/x
		face/size/x: pads + first size-text face
		face/offset/x: face/offset/x + ((prev - face/size/x) / 2)
	][face/type = 'button]
]

view [
	style txt: text right 45
	drop-list data langs select 1 on-change :set-lang return
	group-box [
		txt "Name"  field return
		txt "Age"   field return
		txt "Phone" field
	] return
	pad 15x0 button "Cancel" button "Submit"
]

