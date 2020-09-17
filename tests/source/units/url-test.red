Red [
	Title:   "Red url! test script"
	Author:  "bitbegin"
	File: 	 %url-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "url"

===start-group=== "url!"

	--test-- "url-1"
		--assert https://www.red-lang.org/ = load "https://www.red-lang.org/"

	--test-- "url-2"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = https://www.red-lang.org/中%20文

	--test-- "url-3"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = make url! "https://www.red-lang.org/中 文"

	--test-- "url-4"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = make url! "https://www.red-lang.org/中%20文"
	
	--test-- "url-5"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = make url! "https://www.red-lang.org/%E4%B8%AD%20%E6%96%87"

	--test-- "url-6"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = to url! "https://www.red-lang.org/中 文"

	--test-- "url-7"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = to url! "https://www.red-lang.org/中%20文"
	
	--test-- "url-8"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = to url! "https://www.red-lang.org/%E4%B8%AD%20%E6%96%87"

	--test-- "url-9"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = make url! %"https://www.red-lang.org/中 文"

	--test-- "url-10"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = to url! %"https://www.red-lang.org/中 文"

	--test-- "url-11"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = make url! ["https" "www.red-lang.org/中 文"]

	--test-- "url-12"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = to url! ["https" "www.red-lang.org/中 文"]
	
	--test-- "url-13"
		--assert "https://www.red-lang.org/中 文" = to string! https://www.red-lang.org/%E4%B8%AD%20%E6%96%87
	
	--test-- "url-14"
		--assert https://www.red-lang.org/%E4%B8%AD%20%E6%96%87 = load mold https://www.red-lang.org/中%20文

	--test-- "url-15"
		--assert {https%3A%2F%2Fwww.red-lang.org%2F%E4%B8%AD%20%E6%96%87} = enhex https://www.red-lang.org/%E4%B8%AD%20%E6%96%87

	--test-- "url-16"
		--assert "https://www.red-lang.org/中 文" = dehex https://www.red-lang.org/%E4%B8%AD%20%E6%96%87

	--test-- "url-17"
		--assert %"https://www.red-lang.org/中 文" = to file! https://www.red-lang.org/%E4%B8%AD%20%E6%96%87

===end-group===


~~~end-file~~~
