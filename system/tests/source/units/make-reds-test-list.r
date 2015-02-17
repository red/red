REBOL [
	Title: "Generates all-reds-tests.txt"
	Author: "Joshua Shireman"
	Version: 0.0.1
	Tabs:	4
	Rights: "Copyright (C) 2015 Joshua Shireman. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; This scans the current Red/System tests directory for filenames with "test-reds" 
;; and generates a file %all-reds-tests.txt file with a list of names.  

all-reds-test-file: %all-reds-tests.txt
all-reds-tests: copy []

write all-reds-test-file {}

find-reds-tests: func [dir /local all-dir-files] [
	all-dir-files: read dir
	foreach file all-dir-files [
		if (find file "test.reds") [
			either (dir = %.) [
				append all-reds-tests reduce file
			] [
				append all-reds-tests reduce dir/(file)
			]
		]
		if (dir? file) [
			either (dir = %.) [
				find-reds-tests file
			] [
				find-reds-tests dir/(file)
			]
		]
	]
] 

find-reds-tests %.

foreach test all-reds-tests [
	write/append all-reds-test-file reduce [test newline] 
]