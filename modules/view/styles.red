Red [
	Title:   "VID built-in styles"
	Author:  "Nenad Rakocevic"
	File: 	 %styles.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

styles: #(
	window: [
		default-actor: on-click
		template: [type: 'window]
	]
	base: [
		default-actor: on-click
		template: [type: 'base size: 80x80 color: 128.128.128]
	]
	button: [
		default-actor: on-click
		template: [type: 'button size: 60x30]
	]
	text: [
		default-actor: on-change
		template: [type: 'text size: 80x24]
	]
	field: [
		default-actor: on-change					;@@ on-enter?
		template: [type: 'field size: 80x24]
	]
	area: [
		default-actor: on-change					;@@ on-enter?
		template: [type: 'area size: 150x150]
	]
	check: [
		default-actor: on-change
		template: [type: 'check size: 80x24]
	]
	radio: [
		default-actor: on-change
		template: [type: 'radio size: 80x24]
	]
	progress: [
		default-actor: on-change
		template: [type: 'progress size: 140x16]
	]
	slider: [
		default-actor: on-change
		template: [type: 'slider size: 150x24]
	]
	image: [
		default-actor: on-down
		template: [type: 'base size: 100x100]
	]
	camera: [
		default-actor: on-down
		template: [type: 'camera size: 250x250]
	]
	text-list: [
		default-actor: on-change
		template: [type: 'text-list size: 100x140]
	]
	drop-list: [
		default-actor: on-change
		template: [type: 'drop-list size: 100x24]
	]
	drop-down: [
		default-actor: on-change
		template: [type: 'drop-down size: 100x24]
	]
	panel: [
		default-actor: on-click						;@@ something better?
		template: [type: 'panel]
	]
	group-box: [
		default-actor: on-click						;@@ something better?
		template: [type: 'group-box]
	]
	tab-panel: [
		default-actor: on-select
		template: [type: 'tab-panel]
	]
)