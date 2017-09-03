Red/System [
	Title:	"Build a set of Red & Red/System Tests for inflate func"
	Author: "Yongzhao Huang"
	File: 	%crypto.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Yongzhao Huang. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

	#include %../runtime/inflate.reds
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

	;--test 1 : use the fixed tree
	file31: declare int-ptr!
	file31: fopen "test6" "r"
	srcLen31: 0
	buffer31: allocate 10000
	srcLen31: fread buffer31 size? byte! 10000 file31
	file32: declare int-ptr!
	file32: fopen "test6.gz" "r"
	buffer32: as byte-ptr! allocate 10000
	srcLen32: 0
	srcLen32: fread buffer32 size? byte! 10000 file32
	src32: allocate 1000
	src32: buffer32
	src32: src32 + 16   ;this according to the gzip format,we just need the compressed part
	dst32: allocate 100000
	dstLen32: 1024
	res: 2
	res: deflate/uncompress dst32 :dstLen32 src32 srcLen32
	i: 1
	until [
		if buffer31/i <> dst32/i [
			probe "the fixed trees func is false"
			break
		]
		buffer31: buffer31 + 1
		dst32: dst32 + 1
		i: i + 1
		i = srcLen31
	]
	if i = srcLen31 [
		probe "the fixed trees func is ture"
	]

	;--test 2: use the dynamic tree
	file21: declare int-ptr!
	file21: fopen "test51" "r"
	srcLen21: 0
	buffer21: allocate 10000
	srcLen21: fread buffer21 size? byte! 10000 file21
	file22: declare int-ptr!
	file22: fopen "test51.gz" "r"
	buffer22: as byte-ptr! allocate 10000
	srcLen22: 0
	srcLen22: fread buffer22 size? byte! 10000 file22
	src22: allocate 1000
	src22: buffer22
	src22: src22 + 17   ;this according to the gzip format,we just need the compressed part
	dst22: allocate 100000
	dstLen22: 1024
	res: 2
	res: deflate/uncompress dst22 :dstLen22 src22 srcLen22
	i: 1
	until [
		if buffer21/i <> dst22/i [
			probe "the dynamic trees func is false"
			break
		]
		buffer21: buffer21 + 1
		dst22: dst22 + 1
		i: i + 1
		i = srcLen21
	]
	if i = srcLen21 [
		probe "the dynamic trees func is ture"
	]
	
	;--test3 use inflate-uncompress-block func
	file11: declare int-ptr!
	file11: fopen "test12" "r"
	srcLen11: 0
	buffer11: allocate 10000
	srcLen11: fread buffer11 size? byte! 10000 file11
	file12: declare int-ptr!
	file12: fopen "test12.gz" "r"
	buffer12: as byte-ptr! allocate 10000
	srcLen12: 0
	srcLen12: fread buffer12 size? byte! 10000 file12
	src12: allocate 1000
	src12: buffer12
	src12: src12 + 16   ;this according to the gzip format,we just need the compressed part
	dst12: allocate 100000
	dstLen12: 1024
	res: 2
	res: deflate/uncompress dst12 :dstLen12 src12 srcLen12
	i: 1
	until [
		if buffer11/i <> dst12/i [
			probe "the inflate-uncompressed-block func is false"
			break
		]
		buffer11: buffer11 + 1
		dst12: dst12 + 1
		i: i + 1
		i = srcLen11
	]
	if i = srcLen11 [
		probe "the inflate-uncompressed-block func is ture"
	]
	


