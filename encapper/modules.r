REBOL [
	Title:   "Red core modules"
	Author:  "Nenad Rakocevic"
	File: 	 %modules.r
	Tabs:	 4
	Rights:  "Copyright (C) 2022 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Note: {
		Use `all` keyword in "OS availability" field to include the module for all target platforms.
	}
]

;-- Name ------ Entry file ------------------------ OS availability -----
	View		%modules/view/view.red				all
	JSON		%environment/codecs/JSON.red		all
	CSV 		%environment/codecs/CSV.red			all