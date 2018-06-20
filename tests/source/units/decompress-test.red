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
		--assert origin = decompress data
	--test-- "fixed trees"
		data: #{1F8B08088A61A65900037465737436004B4C4A36343206005CBB02CF06000000}
		origin: #{616263313233}
		--assert origin = decompress data
	--test-- "uncompressed block"
		data: #{1F8B08085920A559040074657374313200011100EEFF61626331323378797A313233616263730ACFE22BA611000000}
		origin: #{61626331323378797A313233616263730A}
		--assert origin = decompress data
===end-group===

===start-group=== "zlib format"
	--test-- "zlib 1"
		data: #{789C35C6C10980301005D156A6009B5AD8A00BAB1F929890EECD45E6F0A6EB56AD9A44C3488D920BB77510CCC8E4147A7B0B2FD8E35C36F66CFE3E0CC71765}
		origin: "tomorrow is a lovely day, i will go outside and have a hahahahaha"
		--assert origin = to-string decompress/zlib data 65
	--test-- "zlib 2"
		data: #{789C4B4C4A363432060006EC01BD}
		origin: "abc123"
		--assert origin = to-string decompress/zlib data 6
	--test-- "zlib 3"
		data: #{789C7BD631F1E9B439CFD62C0A4A4D79B17EED8B150D00713E0BBA}
		origin: "我喜欢Red语言"			;-- utf8 encoding
		--assert origin = to-string decompress/zlib data 18
===end-group===

~~~end-file~~~
