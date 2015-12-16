Red/System [
	Title:   "Red/System lib osx test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-test-source.reds
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

;; library declarations

#import [
	"/usr/lib/libsqlite3.dylib" cdecl [
		sqlite3_libversion_number: "sqlite3_libversion_number" [
			return:     [integer!]
		]
	]
]

~~~start-file~~~ "lib osx"

===start-group=== "OS X SQLite"

	--test-- "libsql1"		--assert (0 < sqlite3_libversion_number)
  
===end-group===

~~~end-file~~~
