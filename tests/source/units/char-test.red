Red [
	Title:   "Red/System char! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %char-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "char"

===start-group=== "+ tests"
	--test-- "char+1"
	--assert #"^(01)" = #"^(01)" + #"^(00)"
	--assert #"^(00)" = #"^(01)" + #"^(10FFFF)"
===end-group===

===start-group=== "- tests"
===end-group===

===start-group=== "* tests"
===end-group===

===start-group=== "/ tests"
===end-group===

===start-group=== "mod tests"
===end-group===

~~~end-file~~~
