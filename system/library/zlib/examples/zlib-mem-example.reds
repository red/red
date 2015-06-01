Red/System [
	Title:   "ZLib, memory compression example"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %zlib-mem-example.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.3.2
		zlib       >= 1.2.6
	}
]

#include %../zlib.reds

print [ "Memory compression example" lf ]
print [ "Zlib version : " zlib/version lf ]

test-mem-compress: func [
	text      [c-string!]
	/local byte-count buffer decomp-text
][
	print [ lf "----------------------------------------" lf ]
	byte-count: 0
	buffer: zlib/compress (as byte-ptr! text) ((length? text) + 1) :byte-count Z_DEFAULT_COMPRESSION	;-- length + 1 to include ending null char

	either buffer = NULL [
		print [ "Error compressing..." lf ]
	][
		decomp-text: as c-string! zlib/decompress buffer byte-count
		print [ "Original text     : " lf text lf ]
		print [ "Compressed data   : " lf zlib/bin-to-str buffer byte-count lf ]
		print [ "Text size         : " length? text " bytes" lf ]
		print [ "Compressed size   : " byte-count " bytes" lf ]
		print [ "Compression ratio : " (100 * byte-count / (length? text)) "%" lf ]
		print [ "Decompressed text : " lf decomp-text lf ]
		free as byte-ptr! decomp-text
		free buffer
	]
]

  test-mem-compress {Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.}

  ;-- Repeated string, highly compressible
  test-mem-compress {Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world.}
