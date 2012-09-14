Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]


natives: context [
	verbose: 1

	print: func [
		/local
			str		[red-string!]
			series	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/print"]]
		
		actions/form off
		str: as red-string! stack/arguments + 1	
		series: as series! str/node/value
		print-line as c-string! series/offset	;@@ unicode print!
		stack/push-last unset-value
	]
	
]
