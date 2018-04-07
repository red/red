Red [
	Title:	 "GUI console plugins management"
	Author:	 "Nenad Rakocevic"
	File:	 %plugins.red
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

context [
	show-menu?: no

	widget-panel: make face! [
		type: 'panel
		offset: 0x0
		size: 100x20
		color: system/view/metrics/colors/panel
	]

	do-show: func [menu [block!] /local off-y][
		menu/1: rejoin [pick ["Hide" "Show"] show-menu?: not show-menu? " Notification Bar"]

		widget-panel/size/x: console/size/x
		off-y: widget-panel/size/y * pick 1x-1 show-menu?
		win/size/y: win/size/y + off-y
		console/offset/y: console/offset/y + off-y
		caret/offset/y: caret/offset/y + off-y

		either show-menu? [
			insert win/pane widget-panel
		][
			remove find win/pane widget-panel
		]
		unless system/view/auto-sync? [show win]
	]

	do-manage: does []
]