Red [
	Title:   "Merge R/S runtime into one file"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

data: []
rt-dir: %runtime/
files: read rt-dir
foreach f files [
	repend data [f read/binary rejoin [rt-dir f]]
]

blk: [rs-runtime:]
append/only blk data
save/header %rs-runtime.red blk []