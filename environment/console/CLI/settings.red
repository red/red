Red [
	Title:	 "Red CLI Console Settings"
	Author:	 "bitbegin"
	File:	 %settings.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

context [
	cfg-dir:	none
	cfg-path:	none
	cfg:		none

	apply-cfg: function [][
		system/console/history: cfg/history
	]

	save-cfg: function [/local saved][
		unless exists? cfg-dir [make-dir/deep cfg-dir]
		clear skip cfg/history 100
		save/header cfg-path cfg [Purpose: "Red Console Configuration File"]
	]

	load-cfg: func [/local cfg-content cli-default][
		cfg-dir: append copy system/options/cache
				#either config/OS = 'Windows [%Red-Console/][%.Red-Console/]

		unless exists? cfg-dir [make-dir/deep cfg-dir]
		cfg-path: append copy cfg-dir %console-cfg.red

		cfg: either all [
			exists? cfg-path
			attempt [select cfg-content: load cfg-path 'Red]
		][
			skip cfg-content 2
		][
			[]
		]
		unless find cfg 'buffer-lines [
			append cfg [buffer-lines: 10000]
		]
		unless find cfg 'history [
			append cfg [history: []]
		]
		apply-cfg
	]
]