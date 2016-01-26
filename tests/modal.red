Red [Needs: 'View]

view [
	below
	button "ok" [print "ok"]
	modal?: check "Modal window" data yes
	popup?: check "Popup window" data yes
	button "new" [
		flags: clear []
		if modal?/data [append flags 'modal]
		if popup?/data [append flags 'popup]
		
		view/flags [button "hi" [print "hi"]] flags
	]
]