Red [Needs: 'View]

view [
	button "ok" [print "ok"]
	button "new" [
		view/options [button "hi" [print "hi"]][flags: 'modal]
	]
]