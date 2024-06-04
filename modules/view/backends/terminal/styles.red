Red [
	Title:   "VID built-in styles"
	Author:  "Nenad Rakocevic"
	File: 	 %styles.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#[
	@origin	 1x1
	@spacing 1x1
	
	window: [
		default-actor: on-down
		template: [type: 'window size: 80x24]
	]
	base: [
		default-actor: on-down
		template: [type: 'base size: 10x5 color: 128.128.128]
	]
	button: [
		default-actor: on-click
		template: [type: 'button size: 5x1 flags: 'focusable]
	]
	text: [
		default-actor: on-down
		template: [type: 'text size: 10x1]
	]
	field: [
		default-actor: on-enter
		template: [type: 'field size: 10x1 flags: 'focusable]
	]
	area: [
		default-actor: on-change
		template: [type: 'area size: 20x10 flags: 'focusable]
	]
	rich-text: [
		default-actor: on-change
		template: [
			type: 'rich-text size: 10x5 color: 255.255.255
			tabs: none line-spacing: 'default handles: none
		]
	]
	toggle: [
		default-actor: on-change
		template: [type: 'toggle size: 5x1 flags: 'focusable]
	]
	check: [
		default-actor: on-change
		template: [type: 'check size: 5x1 flags: 'focusable]
	]
	radio: [
		default-actor: on-change
		template: [type: 'radio size: 5x1 flags: 'focusable]
	]
	progress: [
		default-actor: on-change
		template: [type: 'progress size: 20x1]
	]
	slider: [
		default-actor: on-change
		template: [type: 'slider size: 20x1 data: 0% flags: 'focusable]
	]
	scroller: [
		default-actor: on-change
		template: [type: 'scroller size: 20x1 data: 0.0 steps: 0.1]
	]
	camera: [
		default-actor: on-down
		template: [type: 'camera size: 10x5]
	]
	calendar: [
		default-actor: on-change
		template: [type: 'calendar size: 10x5 flags: 'focusable]
	]
	text-list: [
		default-actor: on-change
		template: [type: 'text-list size: 20x10 flags: 'focusable]
	]
	drop-list: [
		default-actor: on-change
		template: [type: 'drop-list size: 20x1 flags: 'focusable]
	]
	drop-down: [
		default-actor: on-enter
		template: [type: 'drop-down size: 20x1 flags: 'focusable]
	]
	panel: [
		default-actor: on-down						;@@ something better?
		template: [type: 'panel size: 80x24]
	]
	group-box: [
		default-actor: on-down						;@@ something better?
		template: [type: 'group-box size: 50x20]
	]
	tab-panel: [
		default-actor: on-select
		template: [type: 'tab-panel size: 50x20 flags: 'focusable]
	]
	h1:  [
		default-actor: on-down
		template: [type: 'text size: 10x1 font: make font! [size: 32]]
	]
	h2:  [
		default-actor: on-down
		template: [type: 'text size: 10x1 font: make font! [size: 26]]
	]
	h3:  [
		default-actor: on-down
		template: [type: 'text size: 10x1 font: make font! [size: 22]]
	]
	h4:  [
		default-actor: on-down
		template: [type: 'text size: 10x1 font: make font! [size: 17]]
	]
	h5:  [
		default-actor: on-down
		template: [type: 'text size: 10x1 font: make font! [size: 13]]
	]
	box: [
		default-actor: on-down
		template: [type: 'base size: 10x5 color: none]
	]
	image: [
		default-actor: on-down
		template: [type: 'base size: 40x20]
		init: [unless image [image: make image! size]]
	]
]