Red [
	Title:   "Macros definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %macros.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#macro [#include64 file!] func [
	"Inlines a file, encoding it to base64; decode it as an image when possible"
	s e /local bin file code
][
	unless exists? file: s/2 [
		print ["*** Error #include64:" mold file "not found"]
		halt
	]
	bin: enbase read/binary s/2

	s: suffix? file: s/2
	if s = %.jpg [s: %.jpeg]

	code: either find [%.png %jpeg %.bmp %gif] s [
		[load/as debase (bin) (to-lit-word form next s)]
	][
		[load debase (bin)]
	]
	compose code
]