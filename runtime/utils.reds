Red/System [
	Title:   "Red runtime utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

get-cmdline-args: func [
	return: [red-value!]
	/local
		args [byte-ptr!]
][
	#either OS = 'Windows [
		args: platform/GetCommandLine
		as red-value! string/load as-c-string args platform/lstrlen args UTF-16LE
	][
		;; TODO
		as red-value! none-value
	]
]

check-arg-type: func [
	arg		[red-value!]
	type	[integer!]
][
	if TYPE_OF(arg) <> type [
		fire [TO_ERROR(script invalid-arg) arg]
	]
]