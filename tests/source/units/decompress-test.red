Red [
	Title:   "Compress & Decompress function test script"
	Author:  "Xie Qingtian"
	File: 	 %decompress.red
	Tabs:	 4
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "decompress"

===start-group=== "gzip format"
	--test-- "dynamic trees"
		data: #{1F8B08088C57A6590400746573743531000DC6C10DC0200C03C0553C40978A086A2DA5B8020A627BB8D775BDAA55136C3084468E05B77581988CC02DE8EF8D9E61C5F1D838C1C7549836AB6E73E93D000000}
		origin: #{746F6D6F72726F772069732061206C6F76656C79206461792C20692077696C6C20676F206F75747369646520616E6420686176652061207069636E6963}
		--assert origin = decompress data 'gzip
	--test-- "fixed trees"
		data: #{1F8B08088A61A65900037465737436004B4C4A36343206005CBB02CF06000000}
		origin: #{616263313233}
		--assert origin = decompress data 'gzip
	--test-- "uncompressed block"
		data: #{1F8B08085920A559040074657374313200011100EEFF61626331323378797A313233616263730ACFE22BA611000000}
		origin: #{61626331323378797A313233616263730A}
		--assert origin = decompress data 'gzip
===end-group===

===start-group=== "zlib format"
	--test-- "zlib 1"
		data: #{789C35C6C10980301005D156A6009B5AD8A00BAB1F929890EECD45E6F0A6EB56AD9A44C3488D920BB77510CCC8E4147A7B0B2FD8E35C36F66CFE3E0CC71765}
		origin: "tomorrow is a lovely day, i will go outside and have a hahahahaha"
		--assert origin = to-string decompress data 'zlib
	--test-- "zlib 2"
		data: #{789C4B4C4A363432060006EC01BD}
		origin: "abc123"
		--assert origin = to-string decompress data 'zlib
	--test-- "zlib 3"
		data: #{789C7BD631F1E9B439CFD62C0A4A4D79B17EED8B150D00713E0BBA}
		origin: "我喜欢Red语言"			;-- utf8 encoding
		--assert origin = to-string decompress data 'zlib
	--test-- "zlib 4"						;-- long data with high byte values: valid Adler-32 sum
		data: #{78DAEDC13101000000C2A0FEA9670D0FA00000000000000000000000000000000000000078309F51D664}
		--assert (append/dup copy #{} #{FF} 20000) = decompress data 'zlib
===end-group===

===start-group=== "stored blocks"
	--test-- "stored zlib"
		data: #{7801010600F9FF61626331323306EC01BD}
		--assert "abc123" = to string! decompress data 'zlib
		--assert "abc123" = to string! decompress/size data 'zlib 6
	--test-- "stored one byte"
		--assert #{41} = decompress #{7801010100FEFF4100420042} 'zlib
		--assert #{41} = decompress #{010100FEFF41} 'deflate
	--test-- "stored final block, then other bytes"
		--assert "abc" = to string! decompress #{010300FCFF616263DEADBEEF} 'deflate
		--assert "abc123" = to string! decompress skip #{7801010600F9FF61626331323306EC01BD} 2 'deflate
	--test-- "stored blocks, then an empty final one"
		--assert "abc" = to string! decompress #{7801000300FCFF616263000000FFFF010000FFFF024D0127} 'zlib
	--test-- "stored blocks, 70000 bytes"
		dc-raw: make binary! 70000
		repeat dc-i 70000 [append dc-raw dc-i * 7 + 3 and 255]
		dc-z: copy #{7801}
		dc-pos: dc-raw
		until [
			dc-len: min 65535 length? dc-pos
			append dc-z either dc-len = length? dc-pos [#{01}][#{00}]
			append dc-z reverse to binary! (dc-len xor 65535 << 16) or dc-len
			append/part dc-z dc-pos dc-len
			tail? dc-pos: skip dc-pos dc-len
		]
		append dc-z to binary! checksum dc-raw 'adler32
		--assert dc-raw = decompress dc-z 'zlib
		--assert dc-raw = decompress/size dc-z 'zlib 70000
===end-group===

===start-group=== "zstd format"
	zd-text: "Red is a new programming language strongly inspired by Rebol, but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing modern support for concurrency and multi-core CPUs."
	--test-- "zstd frames of the reference library"
		zd-1: #{
			28B52FFD04004D0500328E261A80A56D0360D66BA5455AF87EBF74A32E40EA49
			111402C149EC3402160800F8AD96011BAD7493F6A4E4EDAE925ABE5ABC57955A
			FCDC339A7E120D1E87D0402E9CC456B8858FEE383418078D6BA76B4EF849B7B8
			B08750252D3FA365B803DBF2DC78EDF3409AD1BC5EE80D3A2CBE674C97B8DD68
			44DE8BB88094B8C113E2E61615273E4127759B7FC7D649433F8929D91E5D75E4
			F276C69B1B0403003A0DDC0D76850B82100541DE2DDA
		}
		zd-2: #{
			28B52FFD60E801DD0F00E6266E18507931EAEF3F9CA879E53A11280444193755
			1F9D5155D543630069006B0039D3FFEA58BFA0E36C77BCC1BA75A90FE2BC1DC8
			F5B32188B3570D67411DEDA6F77ADBE37DED5DDA6D2D7EC3D7BE6AB7E7AA519C
			B1D377DB92DF2276E0C3589D2FB16B35DB505FFBF2E32ECE5BBF7254E42EFDCE
			5D0B823473388727EB3DBDB6D7EA0CCFA04C127504BAD11C0BF279180334890F
			57A6C5FA4411071A8838E62F6289A467F9D5240F3427E9473250C933344F9EC5
			7186994033BA753C1F2E2D378E29682A2A5EB3DD9F085EBBF465766BCE627671
			F68CB7EF8CC350D4BFB96A18D4EC583FDB9107B86B77680335DF6B310C71DEDF
			707E866F26E65C6F569E5EEDA0F86D1B6438D71711A505413AE632359473E319
			7E15CF3127553C50F109219F26144594F407728CA552AC0353B4CC427A735447
			1328C9A238C7245DD21D682207E6D12C9103153F0CA8088E6A9986E7D2B41C9A
			2E3101B36AB7FAF4B7921FBD9CA877C697FBCADBAB439BAB76ACFCAC18FE8063
			E23E6977777A2C63AAD5FCCDD64F3BDE2E6ACAD5EF8E5E4FDBAD7FE9B663D5EA
			330C8619F89675A97705B94C4170E37796EB82EB2CDB7003273BFBD587198F56
			B3973B88B51A2810102122D503C0B8AD03062A1170F03A6FC3219DE2D4CC1CEE
			99EDA0337BB7F14D7A8DC1DD2C57725DBC066E5041B0C6990D1ECDE47481F906
			6A2E20280A
		}
		zd-3: #{28B52FFDA0E09304005400001000000100FBFF39C00202001000039F0400}
		zd-f1: #{28B52FFD2403190000616263990977AD}
		zd-f2: #{28B52FFD20124D0000186465660100766E08}
		--assert zd-text = to string! decompress zd-1 'zstd		;-- no content size, checksum
		--assert (rejoin [zd-text uppercase copy zd-text reverse copy zd-text]) = to string! decompress zd-2 'zstd	;-- FSE tables, 4 Huffman streams
		--assert (append/dup copy #{} #{00} 300000) = decompress zd-3 'zstd		;-- RLE blocks
		--assert "abcdefdefdefdefdefdef" = to string! decompress rejoin [zd-f1 #{502A4D1803000000414243} zd-f2] 'zstd	;-- with a skippable frame
		--assert zd-text = to string! decompress/size zd-1 'zstd 1000

	--test-- "zstd invalid data"
		--assert error? try [decompress copy/part zd-1 100 'zstd]
		--assert error? try [decompress head change back tail copy zd-1 #{00} 'zstd]	;-- checksum
		--assert error? try [decompress #{28B52FFE2403190000616263990977AD} 'zstd]
		--assert error? try [decompress #{28B52FFD2C03190000616263990977AD} 'zstd]	;-- reserved bit
		--assert error? try [decompress append copy zd-f1 #{00} 'zstd]
		--assert error? try [decompress #{28B52FFD400003070220004102200042450000000154000A00D307} 'zstd]	;-- a match beyond the 1 KB window
		--assert 2051 = length? decompress #{28B52FFD400003070220004102200042450000000154000A000304} 'zstd	;-- one at its limit

	--test-- "zstd round trips"
		random/seed 2
		zd-words: make binary! 120000
		loop 20000 [append zd-words random/only ["red " "blue " "green " "draw " "view " "parse " "series " "block "]]
		zd-rnd: make binary! 70000
		loop 70000 [append zd-rnd random 255]
		zd-zeros: append/dup make binary! 300000 #{00} 300000
		foreach zd-data reduce [#{} #{41} to binary! zd-text zd-words zd-rnd zd-zeros rejoin [zd-words zd-rnd zd-words]][
			--assert zd-data = decompress compress zd-data 'zstd 'zstd
		]
		--assert zd-text = to string! decompress compress zd-text 'zstd 'zstd
		zd-c: compress zd-words 'zstd
		--assert 20000 > length? zd-c
		--assert 2 = (3 and shift pick zd-c 10 1)		;-- first block compressed
		--assert 40 > length? compress zd-zeros 'zstd		;-- RLE blocks
		--assert 70030 > length? compress zd-rnd 'zstd		;-- raw block

===end-group===

===start-group=== "compress & decompress"
	data: "Red is a new programming language strongly inspired by Rebol, but with a broader field of usage thanks to its native-code compiler, from system programming to high-level scripting, while providing modern support for concurrency and multi-core CPUs."
	--test-- "deflate"
		--assert data = to string! decompress compress to binary! data 'deflate 'deflate

	--test-- "gzip"
		--assert data = to string! decompress compress to binary! data 'gzip 'gzip

	--test-- "zlib"
		--assert data = to string! decompress compress to binary! data 'gzip 'gzip

	--test-- "cascaded"
		;-- gzip format only compressed once
		--assert data = to string! decompress compress compress data 'gzip 'gzip 'gzip
		--assert data = to string! decompress compress compress compress data 'gzip 'gzip 'gzip 'gzip
		;-- deflate/zlib format support nested call
		--assert data = to string! decompress decompress compress compress data 'deflate 'deflate 'deflate 'deflate
		--assert data = to string! decompress decompress decompress compress compress compress data 'deflate 'deflate 'deflate 'deflate 'deflate 'deflate
		--assert data = to string! decompress decompress compress compress data 'zlib 'zlib 'zlib 'zlib
		--assert data = to string! decompress decompress decompress compress compress compress data 'zlib 'zlib 'zlib 'zlib 'zlib 'zlib

	--test-- "stored, fixed and dynamic blocks"
		random/seed 1
		dc-text: make binary! 120000
		loop 20000 [append dc-text random/only ["red " "blue " "green " "draw " "view " "parse " "series " "block "]]
		dc-rnd: make binary! 70000
		loop 70000 [append dc-rnd random 255]
		foreach dc-data reduce [#{} #{41} dc-text dc-rnd rejoin [dc-text dc-rnd dc-text]][
			foreach dc-m [deflate zlib gzip][--assert dc-data = decompress compress dc-data dc-m dc-m]
		]
		--assert 20000 > length? compress dc-text 'deflate		;-- long matches
		--assert 2 = (3 and shift first compress dc-text 'deflate 1)	;-- first block: dynamic codes
		--assert 70100 > length? compress dc-rnd 'deflate		;-- stored blocks

	--test-- "no padding byte after a byte-aligned end"
		dc-data: #{FFFEFDFCFBFA}
		--assert #{FBFFEFEF9FDFBF00} = compress dc-data 'deflate
		--assert #{7801FBFFEFEF9FDFBF0014CE05EC} = compress dc-data 'zlib
		--assert #{1F8B0800000000000404FBFFEFEF9FDFBF00E983F0C006000000} = compress dc-data 'gzip

	--test-- "compression levels"
		foreach dc-m [deflate zlib gzip zstd][
			foreach dc-l either dc-m = 'zstd [[1 3 4 5 6 9 12 14 17 19]][[1 6 9]][
				--assert dc-text = decompress compress/level dc-text dc-m dc-l dc-m
			]
		]
		--assert (compress dc-text 'deflate) = compress/level dc-text 'deflate 6
		--assert (compress dc-text 'zstd) = compress/level dc-text 'zstd 3
		--assert (length? compress/level dc-text 'deflate 9) < length? compress/level dc-text 'deflate 1
		--assert (length? compress/level dc-text 'zstd 19) < length? compress/level dc-text 'zstd 1
		--assert error? try [compress/level dc-text 'zstd 20]
		--assert error? try [compress/level dc-text 'deflate 0]
		--assert [#{7801} #{785E} #{789C} #{78DA}] = collect [foreach dc-l [1 5 6 9][keep copy/part compress/level dc-text 'zlib dc-l 2]]	;-- FLEVEL
		--assert [4 0 0 2] = collect [foreach dc-l [1 5 6 9][keep pick compress/level dc-text 'gzip dc-l 9]]	;-- XFL

===end-group===

~~~end-file~~~
