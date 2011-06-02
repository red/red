REBOL [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %return-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;==== Helper functions ====
test-file: %runnable/return.reds

--clean: does [
    if exists? test-file [delete test-file]
    if all [exe exists? exe][delete exe]
]

compile: func [src /full][
	unless full [insert src "Red/System []^/"]		;-- add a default header if not provided
	write test-file src
	exe: --compile test-file
]

--assert-error?: func [msg][
	--assert found? find qt/comp-output msg
]
;==== end of helper functions ===


~~~start-file~~~ "return-err"

  --test-- "return as last statement in until block"
	compile "until [return]"
	--assert-error? "*** Compilation Error: return is not allowed outside of a function"
	--clean
	
	compile "foo: func [][until [return]]"
	--assert-error? "*** Compilation Error: RETURN keyword used without return: declaration in foo"
	--clean
	
	compile "foo: func [return: [integer!]][until [return]]"
	--assert-error? "*** Compilation Error: missing argument"
	--clean
	
	compile "foo: func [return: [integer!]][until [return true]]"
	--assert-error? "*** Compilation Error: wrong return type in function: foo"
	--clean
	
	compile "foo: func [return: [integer!]][until [return 123]]"
	--assert-error? "*** Compilation Error: UNTIL requires a conditional expression"
	--clean
	
~~~end-file~~~


