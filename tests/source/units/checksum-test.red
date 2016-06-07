Red [
	Title:   "Red/System checksum function test script"
	Author:  "Gregg Irwin"
	File: 	 %checksum-test.red
	Version: "0.0.1"
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Gregg Irwin. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Notes:   {
		https://defuse.ca/checksums.htm
		http://tools.bin63.com/hmac-generator
		http://www.freeformatter.com/hmac-generator.html
	}
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "checksum"

===start-group=== "Unknown method tests"
	--test-- "ERR MD4" --assert error? try [#{} = checksum "" 'md4]
	--test-- "ERR MD4/with" --assert error? try [#{} = checksum/with "" 'md4 ""]
===end-group===


===start-group=== "Invalid args"
	--test-- "ERR string method" --assert error? try [#{} = checksum "123" ""]
	--test-- "ERR word! spec" --assert error? try [#{} = checksum/with "123" 'crc32 'xxx]
	--test-- "ERR CRC32 + /with" --assert error? try [#{} = checksum/with "123" 'crc32 2]
	--test-- "ERR TCP + /with" --assert error? try [#{} = checksum/with "123" 'tcp 2]
	--test-- "ERR string spec for hash method" --assert error? try [#{} = checksum/with "123" 'hash ""]
===end-group===


===start-group=== "TCP CRC tests"
	--test-- ""   --assert 65535 = checksum ""   'tcp
	--test-- "^@" --assert 65535 = checksum "^@" 'tcp
	--test-- "^A" --assert 65534 = checksum "^A" 'tcp
	--test-- "^_" --assert 65504 = checksum "^_" 'tcp
	--test-- " "  --assert 65503 = checksum " "  'tcp
	--test-- "Z"  --assert 65445 = checksum "Z"  'tcp
	--test-- "char 127" --assert 65408	= checksum form make char! 127 'tcp
	--test-- "char 255" --assert 15424	= checksum form make char! 255 'tcp
	data: "12"
	--test-- data --assert 52941 = checksum data 'tcp
	data: "123"
	--test-- data --assert 52890 = checksum data 'tcp
	data: "123456789"
	--test-- data --assert 12018 = checksum data 'tcp
	data: "0123456789"
	--test-- data --assert 64245 = checksum data 'tcp
	data: "The quick brown fox jumps over the lazy dog"
	--test-- data --assert 55613 = checksum data 'tcp
===end-group===


===start-group=== "CRC32 tests"
	--test-- ""   --assert 0			= checksum ""   'crc32
	--test-- "^@" --assert -771559539	= checksum "^@" 'crc32
	--test-- "^A" --assert -1526341861	= checksum "^A" 'crc32
	--test-- "^_" --assert 1594548856	= checksum "^_" 'crc32
	--test-- " "  --assert -378745019	= checksum " "  'crc32
	--test-- "Z"  --assert 1505515367	= checksum "Z"  'crc32
	--test-- "char 127" --assert 314082080	= checksum form make char! 127 'crc32
	--test-- "char 255" --assert -87017361	= checksum form make char! 255 'crc32
	data: "12"
	--test-- data --assert 1330857165	= checksum data 'crc32
	data: "123"
	--test-- data --assert -2008521774	= checksum data 'crc32
	data: "123456789"
	--test-- data --assert -873187034	= checksum data 'crc32
	data: "0123456789"
	--test-- data --assert -1501247546	= checksum data 'crc32
	data: "The quick brown fox jumps over the lazy dog"
	--test-- data --assert 1095738169	= checksum data 'crc32
===end-group===



===start-group=== "MD5 tests"
	data: ""
	expected: #{D41D8CD98F00B204E9800998ECF8427E}
	--test-- "MD5_empty" --assert expected = checksum data 'md5
	data: "The quick brown fox jumps over the lazy dog"
	expected: #{9E107D9D372BB6826BD81D3542A419D6}
	--test-- "MD5_quick" --assert expected = checksum data 'md5
	data: "123456789"
	expected: #{25F9E794323B453885F5181F1B624D0B}
	--test-- "MD5_1-9" --assert expected = checksum data 'md5
	data: "0123456789"
	expected: #{781E5E245D69B566979B86E28D23F2C7}
	--test-- "MD5_0-9" --assert expected = checksum data 'md5
===end-group===


===start-group=== "SHA1 tests"
	data: ""
	expected: #{DA39A3EE5E6B4B0D3255BFEF95601890AFD80709}
	--test-- "SHA1_empty" --assert expected = checksum data 'sha1
	data: "The quick brown fox jumps over the lazy dog"
	expected: #{2FD4E1C67A2D28FCED849EE1BB76E7391B93EB12}
	--test-- "SHA1_quick" --assert expected = checksum data 'sha1
	data: "123456789"
	expected: #{F7C3BC1D808E04732ADF679965CCC34CA7AE3441}
	--test-- "SHA1_1-9" --assert expected = checksum data 'sha1
	data: "0123456789"
	expected: #{87ACEC17CD9DCD20A716CC2CF67417B71C8A7016}
	--test-- "SHA1_0-9" --assert expected = checksum data 'sha1
===end-group===


===start-group=== "SHA256 tests"
	data: ""
	expected: #{E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855}
   --test-- "SHA256_empty" --assert expected = checksum data 'sha256
	data: "The quick brown fox jumps over the lazy dog"
	expected: #{D7A8FBB307D7809469CA9ABCB0082E4F8D5651E46D3CDB762D02D0BF37C9E592}
   --test-- "SHA256_quick" --assert expected = checksum data 'sha256
	data: "123456789"
	expected: #{15E2B0D3C33891EBB0F1EF609EC419420C20E320CE94C65FBC8C3312448EB225}
   --test-- "SHA256_1-9" --assert expected = checksum data 'sha256
	data: "0123456789"
	expected: #{84D89877F0D4041EFB6BF91A16F0248F2FD573E6AF05C19F96BEDB9F882F7882}
   --test-- "SHA256_0-9" --assert expected = checksum data 'sha256
===end-group===


===start-group=== "SHA384 tests"
	data: ""
	expected: #{
		38B060A751AC96384CD9327EB1B1E36A21FDB71114BE07434C0CC7BF63F6E1DA
		274EDEBFE76F65FBD51AD2F14898B95B
	}
	--test-- "SHA384_empty" --assert expected = checksum data 'sha384
	data: "The quick brown fox jumps over the lazy dog"
	expected: #{
		CA737F1014A48F4C0B6DD43CB177B0AFD9E5169367544C494011E3317DBF9A50
		9CB1E5DC1E85A941BBEE3D7F2AFBC9B1
	}
	--test-- "SHA384_quick" --assert expected = checksum data 'sha384
	data: "123456789"
	expected: #{
		EB455D56D2C1A69DE64E832011F3393D45F3FA31D6842F21AF92D2FE469C499D
		A5E3179847334A18479C8D1DEDEA1BE3
	}
	--test-- "SHA384_1-9" --assert expected = checksum data 'sha384
	data: "0123456789"
	expected: #{
		90AE531F24E48697904A4D0286F354C50A350EBB6C2B9EFCB22F71C96CEAEFFC
		11C6095E9CA0DF0EC30BF685DCF2E5E5
	}
	--test-- "SHA384_0-9" --assert expected = checksum data 'sha384
===end-group===


===start-group=== "SHA512 tests"
	data: ""
	expected: #{
		CF83E1357EEFB8BDF1542850D66D8007D620E4050B5715DC83F4A921D36CE9CE
		47D0D13C5D85F2B0FF8318D2877EEC2F63B931BD47417A81A538327AF927DA3E
	}
	--test-- "SHA512_empty" --assert expected = checksum data 'sha512
	data: "The quick brown fox jumps over the lazy dog"
	expected: #{
		07E547D9586F6A73F73FBAC0435ED76951218FB7D0C8D788A309D785436BBB64
		2E93A252A954F23912547D1E8A3B5ED6E1BFD7097821233FA0538F3DB854FEE6
	}
	--test-- "SHA512_quick" --assert expected = checksum data 'sha512
	data: "123456789"
	expected: #{
		D9E6762DD1C8EAF6D61B3C6192FC408D4D6D5F1176D0C29169BC24E71C3F274A
		D27FCD5811B313D681F7E55EC02D73D499C95455B6B5BB503ACF574FBA8FFE85
	}
	--test-- "SHA512_1-9" --assert expected = checksum data 'sha512
	data: "0123456789"
	expected: #{
		BB96C2FC40D2D54617D6F276FEBE571F623A8DADF0B734855299B0E107FDA32C
		F6B69F2DA32B36445D73690B93CBD0F7BFC20E0F7F28553D2A4428F23B716E90
	}
	--test-- "SHA512_0-9" --assert expected = checksum data 'sha512
===end-group===


===start-group=== "/with (HMAC) empty data and key tests"

	data: ""
	key:  ""

	expected: #{74E6F7298A9C2D168935F58C001BAD88}
	--test-- "MD5" --assert expected = checksum/with data 'md5 key

	expected: #{FBDB1D1B18AA6C08324B7D64B71FB76370690E1D}
	--test-- "SHA1" --assert expected = checksum/with data 'sha1 key

	expected: #{B613679A0814D9EC772F95D778C35FC5FF1697C493715653C6C712144292C5AD}
	--test-- "SHA256" --assert expected = checksum/with data 'sha256 key

	expected: #{
		6C1F2EE938FAD2E24BD91298474382CA218C75DB3D83E114B3D4367776D14D35
		51289E75E8209CD4B792302840234ADC
	}
	--test-- "SHA384" --assert expected = checksum/with data 'sha384 key

	expected: #{
		B936CEE86C9F87AA5D3C6F2E84CB5A4239A5FE50480A6EC66B70AB5B1F4AC673
		0C6C515421B327EC1D69402E53DFB49AD7381EB067B338FD7B0CB22247225D47
	}
	--test-- "SHA512" --assert expected = checksum/with data 'sha512 key

===end-group===
  

===start-group=== "/with (HMAC) standard test vectors"

	data: "The quick brown fox jumps over the lazy dog"
	key:  "key"

	expected: #{80070713463E7749B90C2DC24911E275}
	--test-- "MD5" --assert expected = checksum/with data 'md5 key

	expected: #{DE7C9B85B8B78AA6BC8A7A36F70A90701C9DB4D9}
	--test-- "SHA1" --assert expected = checksum/with data 'sha1 key

	expected: #{F7BC83F430538424B13298E6AA6FB143EF4D59A14946175997479DBC2D1A3CD8}
	--test-- "SHA256" --assert expected = checksum/with data 'sha256 key

	expected: #{
		D7F4727E2C0B39AE0F1E40CC96F60242D5B7801841CEA6FC592C5D3E1AE50700
		582A96CF35E1E554995FE4E03381C237
	}
	--test-- "SHA384" --assert expected = checksum/with data 'sha384 key

	expected: #{
		B42AF09057BAC1E2D41708E48A902E09B5FF7F12AB428A4FE86653C73DD248FB
		82F948A549F7B791A5B41915EE4D1EC3935357E4E2317250D0372AFA2EBEEB3A
	}
	--test-- "SHA512" --assert expected = checksum/with data 'sha512 key

===end-group===


~~~end-file~~~
