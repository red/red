Red/System [
	Title:	"inflate tests(include fixed-tree/dynamic-tree/inflate-umcompressed-block func)"
	Author: "Yongzhao Huang"
	File: 	%infalte-test.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Yongzhao Huang. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	]
	;----------------------
	;----test function-----
	;----------------------
	#include %inflate.reds   ;which is in the red/runtime
	#import [
		"zlib.dll" cdecl [
			compress: "compress" [
				dst 	[byte-ptr!]
				dstLen 	[int-ptr!]
				src 	[c-string!]
				srcLen 	[integer!]
				return: [integer!]
			]
		]
	]


	;--test 1 : use the dynamic tree
	;--compress data
	res: declare integer!
	src: "tomorrow,	i will try my best to steady, even though there are many difficulties "
	probe src
	dst: allocate 1000000
	dstLen: 1024
	srcLen: declare integer!
	srcLen: length? src
	res: compress dst :dstLen src srcLen
	print-line ["return :" res ]
	j: 0
	;--decompress data
	srcLen: dstLen
	src1: dst
	dst1: allocate 100000
	dstLen1: 1024
	src1: src1 + 1
	srcLen: srcLen - 6
	deflate/uncompress dst1 :dstLen1 src1 srcLen
	probe as-c-string dst1

	;test 2: use fixed  tree
	--compress data
	res: declare integer!
	src: "abc"
	probe src
	dst: allocate 1000000
	dstLen: 1024
	srcLen: declare integer!
	srcLen: length? src
	res: compress dst :dstLen src srcLen
	print-line ["return :" res ]
	j: 0
	file: 0
	file: CreateFileA
			"compressdata.txt"
			40000000h
			0
			null
			1
			80h
			null
	probe ["the file's value is"file]
	buffer: as byte-ptr! allocate 1000
	size: 0
	read-sz: 0
	buffer: dst
	WriteFile file buffer 50 :read-sz null
	probe [as-c-string buffer]
	;--decompress data
	srcLen: dstLen
	src1: dst
	dst1: allocate 100000
	dstLen1: 1024
	src1: src1 + 1
	srcLen: srcLen - 6
	deflate/uncompress dst1 :dstLen1 src1 srcLen
	probe as-c-string dst1

	;test3 use inflate-uncompress-block func
	#import [
			LIBC-file cdecl [
				fopen:	"fopen" [
					filename	[c-string!]
					mode 		[c-string!]
					return:		[int-ptr!]
				]
				fread:	"fread" [
					buffer		[byte-ptr!]
					size 		[integer!]
					bytes		[integer!]
					file		[int-ptr!]
					return:		[integer!]
				]	
			]
		]	
		file: declare int-ptr!
		file: fopen "test12.gz" "r"
		buffer: as byte-ptr! allocate 10000
		srcLen: 0
		srcLen: fread buffer size? byte! 10000 file
		src: allocate 1000
		src: buffer
		src: src + 15   ;this according to the gzip format,we just need the compressed part
		dst1: allocate 100000
		dstLen1: 1024
		res: 2
		res: deflate/uncompress dst1 :dstLen1 src srcLen
		probe ["res is"res]
		probe as-c-string dst1


