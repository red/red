Red [
	Title:	"Red console with call integration"
	Author: ["Nenad Rakocevic" "Bruno Anselme"]
  EMail: "be.red@free.fr"
  File: %console-call.red
	Tabs: 	4
	Rights: "Copyright (C) 2012-2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#include %../call.red
prin "-=== Call added to Red console ===-"
if system/platform = 'Windows [
  prin "^/ -== Limited Windows support, launch only GUI apps ==-"
]
#include %../../../../tests/console.red
