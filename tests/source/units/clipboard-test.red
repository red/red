Red [
	Title:   "Red Clipboard test"
	Author:  "hiiamboris"
	File: 	 %clipboard-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "clipboard"

===start-group=== "text IO"

	do [if system/platform <> 'Linux [

		--test-- "text-io-1"
			--assert false <> write-clipboard ""
			--assert "" = read-clipboard

		--test-- "text-io-2"
			--assert false <> write-clipboard "text"
			--assert "text" = read-clipboard

		--test-- "text-io-3"
			--assert false <> write-clipboard "1^/2^/3^/"
			--assert "1^/2^/3^/" = read-clipboard

		--test-- "text-io-long-1"
			til1: append/dup copy "" "data " 1000
			--assert false <> write-clipboard til1
			--assert til1 = read-clipboard
			unset 'til1
	]]


	do [if system/platform = 'Windows [

		--test-- "emptying"
			--assert false <> write-clipboard none
			--assert none? read-clipboard

		
		--test-- "list-io-1"
			--assert false <> write-clipboard []
			--assert [] = read-clipboard

		--test-- "list-io-2"
			li2: [%/dir1/file1 %/dir2/file2]
			--assert false <> write-clipboard li2
			--assert li2 = read-clipboard
			unset 'li2

		--test-- "list-io-long-1"
			lil1: reduce [%/dir1/file1 %/dir2/file2
				to-red-file %"C:\So many autumn, ay, and winter days, spent outside the town, trying to hear what was in the wind, to hear and carry it express!.txt"
			]
			--assert false <> write-clipboard lil1
			--assert lil1 = read-clipboard
			unset 'lil1


		--test-- "image-io-1"
			--assert false <> write-clipboard make image! 0x0
			--assert none? read-clipboard

		--test-- "image-io-2"
			ii2: make image! 1x1
			--assert false <> write-clipboard ii2
			--assert ii2 = read-clipboard
			unset 'ii2

		unless unset? :draw [
		--test-- "image-io-3"
			ii3: draw make image! [100x100 0.200.200.200] [pen purple line-width 5 circle 50x50 40]
			--assert false <> write-clipboard ii3
			--assert ii3 = read-clipboard
			unset 'ii3

		--test-- "image-io-long-1"
			iil1: draw make image! [3000x3000 0.200.200.200] [pen purple line-width 50 circle 1500x1500 1300]
			--assert false <> write-clipboard iil1
			--assert iil1 = read-clipboard
			unset 'iil1
		]

	]];; do [if system/platform = 'Windows [

	do [if system/platform <> 'Linux [
		write-clipboard ""								;-- clean it up
	]]

===end-group===

~~~end-file~~~
