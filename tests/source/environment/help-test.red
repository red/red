Red [
	Title:   "Red HELP functions test script"
	Author:  "Gregg Irwin"
	File: 	 %functions-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

; See notes on https://github.com/red/red/pull/3490

; These tests are stubbed out until changes to the test engine or mdules
; make it possible to test included code both compiled and interpreted.

#include  %../../../quick-test/quick-test.red
;#include  %../../../environment/console/help.red

~~~start-file~~~ "help functions"

; help-string tests pass with quick-test, but full automated tests fail
; when trying to include %help.red. May require -r or -u compilation.
; #include with a relative path for it fails, but `help-string` also 
; doesn't exist if an absolute path is used for the #include.
;===start-group=== "help-string tests"
;	--test-- "help-string"
;		--assert {1 is an integer! value.^/} = help-string 1
;		--assert {func ["Convert to string! value" value][to string! :value]^/} = help-string :to-string
;		--assert {No handle values were found in the global context.^/} = help-string handle!
;		;--assert "" = help-string 
;	--test-- "help-string-20"
;		; Note that the help string is just the last part
;		help-ctx/NON_CONSOLE_SIZE: 20
;		--assert {Reverses the ord...^/} = find help-string verse "Reverses"
;		
;===end-group===

~~~end-file~~~
