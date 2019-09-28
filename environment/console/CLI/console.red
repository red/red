Red [
	Title:	"Red console"
	Author: ["Nenad Rakocevic" "Kaj de Vos"]
	File: 	%console.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %input.red
#include %../help.red
#include %../engine.red

cli-console-ctx: context [
	settings: #include %settings.red

	launch: does [
		settings/load-cfg

		system/console/init "Red Console"
		system/console/launch
	]
]

_save-cfg: function [][
	cli-console-ctx/settings/save-cfg
]

cli-console-ctx/launch