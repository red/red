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

	--test-- "no padding byte after a byte-aligned end"
		dc-data: #{FFFEFDFCFBFA}
		--assert #{FBFFEFEF9FDFBF00} = compress dc-data 'deflate
		--assert #{7801FBFFEFEF9FDFBF0014CE05EC} = compress dc-data 'zlib
		--assert #{1F8B0800000000000404FBFFEFEF9FDFBF00E983F0C006000000} = compress dc-data 'gzip

===end-group===

~~~end-file~~~
