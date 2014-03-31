Red/System [
	Title:   "Red/System lib osx test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-test-source.reds
	Rights:  "Copyright (C) 2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; library declarations

#import [
  "/usr/lib/libsqlite3.dylib" cdecl [
    sqlite3_libversion_number: "sqlite3_libversion_number" [
      return:     [integer!]
    ]
  ]
]

===start-group=== "OS X Core Foundation"

  --test-- "libosx1"
  --assert 0 < sqlite3_libversion_number

===end-group===
