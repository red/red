REBOL [
  	Title:   "Red Run All Finalisation "
	Author:  "Peter W A Wood"
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
	Purpose: {Defines tests to be run in red/run-all.r and red/tests/run-all.r}
]

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
either batch-mode [
	quit/return either qt/test-run/failures > 0 [1] [0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	qt/test-run/failures
]