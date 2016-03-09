Red/System [
	Title:   "Red/System lib osx test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-test-source.reds
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; This test cannot be run on its own; it is included in lib-test.reds

#include %../../../../quick-test/quick-test.reds

;; library declarations

#import [
	"/usr/lib/libsqlite3.dylib" cdecl [
		sqlite3_libversion_number: "sqlite3_libversion_number" [
			return:     [integer!]
		]
	]
]


===start-group=== "OS X SQLite"

	--test-- "libsql1"		--assert (3 < sqlite3_libversion_number)
  
===end-group===
