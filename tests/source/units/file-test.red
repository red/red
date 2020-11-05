Red [
	Title:   "Red file! test script"
	Author:  "bitbegin"
	File: 	 %file-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "file"

===start-group=== "file!"

	--test-- "file-1"
		--assert %"d:/folder 1/中文" = load {%"d:/folder 1/中文"}
	
	--test-- "file-2"
		--assert %"d:/folder%201/中文" =  load {%"d:/folder%201/中文"}

	--test-- "file-3"
		--assert %"d:/folder 1/中文" = make file! "d:/folder 1/中文"

	--test-- "file-4"
		--assert %"d:/folder%201/中文" = make file! "d:/folder%201/中文"

	--test-- "file-5"
		--assert %"d:/folder%201/%E4%B8%AD%E6%96%87" = make file! "d:/folder%201/%E4%B8%AD%E6%96%87"

	--test-- "file-6"
		--assert %"d:/folder 1/中文" = to file! "d:/folder 1/中文"

	--test-- "file-7"
		--assert %"d:/folder%201/中文" = to file! "d:/folder%201/中文"

	--test-- "file-8"
		--assert %"d:/folder%201/%E4%B8%AD%E6%96%87" = to file! "d:/folder%201/%E4%B8%AD%E6%96%87"

	--test-- "file-9"
		--assert %"d:/folder 1/中文" = make file! d:/folder%201/%E4%B8%AD%E6%96%87

	--test-- "file-10"
		--assert %"d:/folder 1/中文" = to file! d:/folder%201/%E4%B8%AD%E6%96%87

	--test-- "url-11"
		--assert %"d:/folder 1/中文" = make file! ["d:" "/folder 1/中文"]

	--test-- "url-12"
		--assert %"d:/folder 1/中%20文" = make file! ["d:" "/folder 1/中%20文"]

	--test-- "url-13"
		--assert %"d:/folder 1/中文" = to file! ["d:" "/folder 1/中文"]

	--test-- "url-14"
		--assert %"d:/folder 1/中%20文" = to file! ["d:" "/folder 1/中%20文"]

	--test-- "url-15"
		--assert "d:/folder 1/中文" = to string! %"d:/folder 1/中文"
	
	--test-- "url-16"
		--assert "d:/folder 1/中文" = to file! d:/folder%201/%E4%B8%AD%E6%96%87

	--test-- "url-17"
		--assert d:/folder%201/%E4%B8%AD%E6%96%87 = to url! %"d:/folder 1/中文"

	--test-- "url-18"
		--assert %"/d/folder 1/中文" = %/d/folder%201/%E4%B8%AD%E6%96%87

===end-group===

~~~end-file~~~
