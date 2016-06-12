Red [
	Title:   "Red/System checksum function test script"
	Author:  "Gregg Irwin"
	File: 	 %checksum-test.red
	Version: "0.0.2"
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Gregg Irwin. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Notes:   {
		Online calculators used for result comparisons:
			http://www.fileformat.info/tool/hash.htm
			https://defuse.ca/checksums.htm
			http://tools.bin63.com/hmac-generator
			http://www.freeformatter.com/hmac-generator.html
	}
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "checksum"

===start-group=== "Unknown method tests"
	--test-- "ERR MD4"			 	--assert error? try [#{} = checksum "" 'md4]
	--test-- "ERR MD4/with" 		--assert error? try [#{} = checksum/with "" 'md4 ""]
===end-group===


===start-group=== "Invalid args"
	--test-- "ERR string method" 				--assert error? try [#{} = checksum "123" ""]
	--test-- "ERR word! spec" 					--assert error? try [#{} = checksum/with "123" 'crc32 'xxx]
	--test-- "ERR CRC32 + /with" 				--assert error? try [#{} = checksum/with "123" 'crc32 2]
	--test-- "ERR TCP + /with"					--assert error? try [#{} = checksum/with "123" 'tcp 2]
	--test-- "ERR string spec for hash method"	--assert error? try [#{} = checksum/with "123" 'hash ""]
===end-group===


===start-group=== "TCP CRC tests"
	--test-- ""   					--assert 65535 = checksum ""   'tcp
	--test-- "^@" 					--assert 65535 = checksum "^@" 'tcp
	--test-- "^A" 					--assert 65534 = checksum "^A" 'tcp
	--test-- "^_"					--assert 65504 = checksum "^_" 'tcp
	--test-- " "					--assert 65503 = checksum " "  'tcp
	--test-- "Z"					--assert 65445 = checksum "Z"  'tcp
	--test-- "char 127"				--assert 65408 = checksum form make char! 127 'tcp
	--test-- "char 255"				--assert 15424 = checksum form make char! 255 'tcp
	
	--test-- "tcpcrc1"
		data: "12"
		--assert 52941 = checksum data 'tcp
		
	--test-- "tcpcrc2"
		data: "123"
		--assert 52890 = checksum data 'tcp
		
	--test-- "tcpcrc3"
		data: "123456789"
		--assert 12018 = checksum data 'tcp
		
	--test-- "tcpcrc4" 
		data: "0123456789"
		--assert 64245 = checksum data 'tcp
		
	--test-- "tcpcrc5"
		data: "The quick brown fox jumps over the lazy dog"
		--assert 55613 = checksum data 'tcp
		
===end-group===


===start-group=== "CRC32 tests"
	--test-- ""						--assert 0 = checksum ""   'crc32
	--test-- "^@" 					--assert -771559539	= checksum "^@" 'crc32
	--test-- "^A" 					--assert -1526341861	= checksum "^A" 'crc32
	--test-- "^_"					--assert 1594548856	= checksum "^_" 'crc32
	--test-- " "					--assert -378745019	= checksum " "  'crc32
	--test-- "Z"					--assert 1505515367	= checksum "Z"  'crc32
	--test-- "char 127"				--assert 314082080	= checksum form make char! 127 'crc32
	--test-- "char 255"				--assert -87017361	= checksum form make char! 255 'crc32
	
	--test-- "crc32-1"
		data: "12"
		--assert 1330857165	= checksum data 'crc32
	
	--test-- "crc32-2"
		data: "123"
		--assert -2008521774	= checksum data 'crc32
	
	--test-- "crc32-3"
		data: "123456789"
		--assert -873187034	= checksum data 'crc32
		
	--test-- "crc32-4"
		data: "0123456789"
		--assert -1501247546	= checksum data 'crc32
		
	--test-- "crc32-5"
		data: "The quick brown fox jumps over the lazy dog"
		--assert 1095738169	= checksum data 'crc32
		
===end-group===


===start-group=== "MD5 tests"
	
	--test-- "MD5_empty"
		data: ""
		expected: #{D41D8CD98F00B204E9800998ECF8427E}
		 --assert expected = checksum data 'md5
		
	--test-- "MD5_quick"
		data: "The quick brown fox jumps over the lazy dog"
		expected: #{9E107D9D372BB6826BD81D3542A419D6}
		--assert expected = checksum data 'md5
	
	--test-- "MD5_1-9"
		data: "123456789"
		expected: #{25F9E794323B453885F5181F1B624D0B}
		 --assert expected = checksum data 'md5
	
	--test-- "MD5_0-9" 
		data: "0123456789"
		expected: #{781E5E245D69B566979B86E28D23F2C7}
		--assert expected = checksum data 'md5
		
===end-group===


===start-group=== "SHA1 tests"
	
	--test-- "SHA1_empty"
		data: ""
		expected: #{DA39A3EE5E6B4B0D3255BFEF95601890AFD80709}
	 	--assert expected = checksum data 'sha1
	
	--test-- "SHA1_quick"
		data: "The quick brown fox jumps over the lazy dog"
		expected: #{2FD4E1C67A2D28FCED849EE1BB76E7391B93EB12}
	 	--assert expected = checksum data 'sha1
	
	--test-- "SHA1_1-9" 
		data: "123456789"
		expected: #{F7C3BC1D808E04732ADF679965CCC34CA7AE3441}
		--assert expected = checksum data 'sha1
	
	--test-- "SHA1_0-9" 
		data: "0123456789"
		expected: #{87ACEC17CD9DCD20A716CC2CF67417B71C8A7016}
		--assert expected = checksum data 'sha1
	
===end-group===


===start-group=== "SHA256 tests"
	
	--test-- "SHA256_empty"
		data: ""
		expected: #{E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855}
    	--assert expected = checksum data 'sha256
	
	--test-- "SHA256_quick" 
		data: "The quick brown fox jumps over the lazy dog"
		expected: #{D7A8FBB307D7809469CA9ABCB0082E4F8D5651E46D3CDB762D02D0BF37C9E592}
		--assert expected = checksum data 'sha256
	
	--test-- "SHA256_1-9"
		data: "123456789"
		expected: #{15E2B0D3C33891EBB0F1EF609EC419420C20E320CE94C65FBC8C3312448EB225}
		--assert expected = checksum data 'sha256
	
	 --test-- "SHA256_0-9"
	 	data: "0123456789"
		expected: #{84D89877F0D4041EFB6BF91A16F0248F2FD573E6AF05C19F96BEDB9F882F7882}
		--assert expected = checksum data 'sha256
   
===end-group===


===start-group=== "SHA384 tests"
	
	--test-- "SHA384_empty"
		data: ""
		expected: #{
			38B060A751AC96384CD9327EB1B1E36A21FDB71114BE07434C0CC7BF63F6E1DA
			274EDEBFE76F65FBD51AD2F14898B95B
		}
		--assert expected = checksum data 'sha384
	
	--test-- "SHA384_quick"
		data: "The quick brown fox jumps over the lazy dog"
		expected: #{
			CA737F1014A48F4C0B6DD43CB177B0AFD9E5169367544C494011E3317DBF9A50
			9CB1E5DC1E85A941BBEE3D7F2AFBC9B1
		}
		--assert expected = checksum data 'sha384
	
	--test-- "SHA384_1-9"
		data: "123456789"
		expected: #{
			EB455D56D2C1A69DE64E832011F3393D45F3FA31D6842F21AF92D2FE469C499D
			A5E3179847334A18479C8D1DEDEA1BE3
		}
		--assert expected = checksum data 'sha384
	
	--test-- "SHA384_0-9" 
		data: "0123456789"
		expected: #{
			90AE531F24E48697904A4D0286F354C50A350EBB6C2B9EFCB22F71C96CEAEFFC
			11C6095E9CA0DF0EC30BF685DCF2E5E5
		}
		--assert expected = checksum data 'sha384
	
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

	--test-- "MD5"
		data: copy ""
		key:  copy ""
		expected: #{74E6F7298A9C2D168935F58C001BAD88}
		--assert expected = checksum/with data 'md5 key

	--test-- "SHA1"
		data: copy ""
		key:  copy ""
		expected: #{FBDB1D1B18AA6C08324B7D64B71FB76370690E1D}
		--assert expected = checksum/with data 'sha1 key

	--test-- "SHA256"
		data: copy ""
		key:  copy ""
		expected: #{B613679A0814D9EC772F95D778C35FC5FF1697C493715653C6C712144292C5AD}
		--assert expected = checksum/with data 'sha256 key

	--test-- "SHA384"
		data: copy ""
		key:  copy ""
		expected: #{
			6C1F2EE938FAD2E24BD91298474382CA218C75DB3D83E114B3D4367776D14D35
			51289E75E8209CD4B792302840234ADC
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "SHA512" 
		data: copy ""
		key:  copy ""
		expected: #{
			B936CEE86C9F87AA5D3C6F2E84CB5A4239A5FE50480A6EC66B70AB5B1F4AC673
			0C6C515421B327EC1D69402E53DFB49AD7381EB067B338FD7B0CB22247225D47
		}
		--assert expected = checksum/with data 'sha512 key

===end-group===
  

===start-group=== "/with (HMAC) standard test vectors"

	--test-- "MD5"
		data: copy "The quick brown fox jumps over the lazy dog"
		key:  copy "key"
		expected: #{80070713463E7749B90C2DC24911E275}
	 	--assert expected = checksum/with data 'md5 key

	--test-- "SHA1"
		data: copy "The quick brown fox jumps over the lazy dog"
		key:  copy "key"
		expected: #{DE7C9B85B8B78AA6BC8A7A36F70A90701C9DB4D9}
	 	--assert expected = checksum/with data 'sha1 key

	--test-- "SHA256"
		data: copy "The quick brown fox jumps over the lazy dog"
		key:  copy "key"
		expected: #{F7BC83F430538424B13298E6AA6FB143EF4D59A14946175997479DBC2D1A3CD8}
	 	--assert expected = checksum/with data 'sha256 key

	--test-- "SHA384"
		data: copy "The quick brown fox jumps over the lazy dog"
		key:  copy "key"
		expected: #{
			D7F4727E2C0B39AE0F1E40CC96F60242D5B7801841CEA6FC592C5D3E1AE50700
			582A96CF35E1E554995FE4E03381C237
		}
	 	--assert expected = checksum/with data 'sha384 key

	--test-- "SHA512"
		data: copy "The quick brown fox jumps over the lazy dog"
		key:  copy "key"
		expected: #{
			B42AF09057BAC1E2D41708E48A902E09B5FF7F12AB428A4FE86653C73DD248FB
			82F948A549F7B791A5B41915EE4D1EC3935357E4E2317250D0372AFA2EBEEB3A
		}
	 	--assert expected = checksum/with data 'sha512 key

;-------------------------------------------------------------------------------
; Test vectors from RFC 4231 (https://tools.ietf.org/html/rfc4231)
;-------------------------------------------------------------------------------

	--test-- "PRF-1-HMAC-SHA-256" 
		data: copy #{4869205468657265}							; "Hi There"
		key:  copy #{0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B}	; 20 bytes
		expected: #{B0344C61D8DB38535CA8AFCEAF0BF12B881DC200C9833DA726E9376C2E32CFF7}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-1-HMAC-SHA-384" 
		data: copy #{4869205468657265}							; "Hi There"
		key:  copy #{0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B}	; 20 bytes
		expected: #{
			AFD03944D84895626B0825F4AB46907F15F9DADBE4101EC682AA034C7CEBC59C
			FAEA9EA9076EDE7F4AF152E8B2FA9CB6
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-1-HMAC-SHA-512" 
		data: copy #{4869205468657265}							; "Hi There"
		key:  copy #{0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B}	; 20 bytes
		expected: #{
			87AA7CDEA5EF619D4FF0B4241A1D6CB02379F4E2CE4EC2787AD0B30545E17CDE
			DAA833B7D6B8A702038B274EAEA3F4E4BE9D914EEB61F1702E696C203A126854
		}
		--assert expected = checksum/with data 'sha512 key

	--test-- "PRF-2-HMAC-SHA-256"
		data: copy  "what do ya want for nothing?"
		key:  copy "Jefe"
		expected: #{5BDCC146BF60754E6A042426089575C75A003F089D2739839DEC58B964EC3843}
	 	--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-2-HMAC-SHA-384"
		data: copy  "what do ya want for nothing?"
		key:  copy "Jefe"
		expected: #{
			AF45D2E376484031617F78D2B58A6B1B9C7EF464F5A01B47E42EC3736322445E
			8E2240CA5E69E2C78B3239ECFAB21649
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-2-HMAC-SHA-512"
		data: copy  "what do ya want for nothing?"
		key:  copy "Jefe" 
		expected: #{
			164B7A7BFCF819E2E395FBE73B56E0A387BD64222E831FD610270CD7EA250554
			9758BF75C05A994A6D034F65F8F0E6FDCAEAB1A34D4A6B4B636E070A38BCE737
		}
		--assert expected = checksum/with data 'sha512 key

	--test-- "PRF-3-HMAC-SHA-256"
		data: copy #{											; 50 bytes
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
		}
		key: copy #{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA}	; 20 bytes
		expected: #{773EA91E36800E46854DB8EBD09181A72959098B3EF8C122D9635514CED565FE}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-3-HMAC-SHA-384"
		data: copy #{											; 50 bytes
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
		}
		key: copy #{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA}	; 20 bytes
		expected: #{
			88062608D3E6AD8A0AA2ACE014C8A86F0AA635D947AC9FEBE83EF4E55966144B
			2A5AB39DC13814B94E3AB6E101A34F27
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-3-HMAC-SHA-512"
		data: copy #{											; 50 bytes
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
			DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
		}
		key: copy #{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA}	; 20 bytes
		expected: #{
			FA73B0089D56A284EFB0F0756C890BE9B1B5DBDD8EE81A3655F83E33B2279D39
			BF3E848279A722C806B485A47E67C807B946A337BEE8942674278859E13292FB
		}
		--assert expected = checksum/with data 'sha512 key
	
	--test-- "PRF-4-HMAC-SHA-256"
		data: copy #{													; 50 bytes
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
		}
		key: copy #{0102030405060708090A0B0C0D0E0F10111213141516171819}	; 25 bytes
		expected: #{82558A389A443C0EA4CC819899F2083A85F0FAA3E578F8077A2E3FF46729665B}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-4-HMAC-SHA-384"
		data: copy #{													; 50 bytes
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
		}
		key: copy #{0102030405060708090A0B0C0D0E0F10111213141516171819}	; 25 bytes
		expected: #{
			3E8A69B7783C25851933AB6290AF6CA77A9981480850009CC5577C6E1F573B4E
			6801DD23C4A7D679CCF8A386C674CFFB
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-4-HMAC-SHA-512" 
		data: copy #{													; 50 bytes
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
			CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD
		}
		key: copy #{0102030405060708090A0B0C0D0E0F10111213141516171819}	; 25 bytes
		expected: #{
			B0BA465637458C6990E5A8C5F61D4AF7E576D97FF94B872DE76F8050361EE3DB
			A91CA5C11AA25EB4D679275CC5788063A5F19741120C4F2DE2ADEBEB10A298DD
		}
		--assert expected = checksum/with data 'sha512 key

	--test-- "PRF-5-HMAC-SHA-256"
		data: copy #{546573742057697468205472756e636174696f6e}	; "Test With Truncation"
		key:  copy #{0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C}	; 20 bytes
		expected: #{A3B6167473100EE06E0C796C2955552BFA6F7C0A6A8AEF8B93F860AAB0CD20C5}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-5-HMAC-SHA-384"
		data: copy #{546573742057697468205472756e636174696f6e}	; "Test With Truncation"
		key:  copy #{0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C}	; 20 bytes
		expected: #{
			3ABF34C3503B2A23A46EFC619BAEF897F4C8E42C934CE55CCBAE9740FCBC1AF4
			CA62269E2A37CD88BA926341EFE4AEEA
		}
	 	--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-5-HMAC-SHA-512"
		data: copy #{546573742057697468205472756e636174696f6e}	; "Test With Truncation"
		key:  copy #{0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C}	; 20 bytes
		expected: #{
			415FAD6271580A531D4179BC891D87A650188707922A4FBB36663A1EB16DA008
			711C5B50DDD0FC235084EB9D3364A1454FB2EF67CD1D29FE6773068EA266E96B
		}
		--assert expected = checksum/with data 'sha512 key

												; "Test Using Larger Than Block-Size Key - Hash Key First"
	data: copy#{											
		54657374205573696E67204C6172676572205468616E20426C6F636B2D53697A
		65204B6579202D2048617368204B6579204669727374
	}
	key:  #{											; 131 bytes
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAA
	}
                  
	--test-- "PRF-6-HMAC-SHA-256"
												; "Test Using Larger Than Block-Size Key - Hash Key First"
		data: copy#{											
			54657374205573696E67204C6172676572205468616E20426C6F636B2D53697A
			65204B6579202D2048617368204B6579204669727374
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		}
		expected: #{60E431591EE0B67F0D8A26AACBF5B77F8E0BC6213728C5140546040F0EE37F54}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-6-HMAC-SHA-384"
												; "Test Using Larger Than Block-Size Key - Hash Key First"
		data: copy#{											
			54657374205573696E67204C6172676572205468616E20426C6F636B2D53697A
			65204B6579202D2048617368204B6579204669727374
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		}
		expected: #{
			4ECE084485813E9088D2C63A041BC5B44F9EF1012A2B588F3CD11F05033AC4C6
			0C2EF6AB4030FE8296248DF163F44952
		}
	 	--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-6-HMAC-SHA-512"
												; "Test Using Larger Than Block-Size Key - Hash Key First"
		data: copy#{											
			54657374205573696E67204C6172676572205468616E20426C6F636B2D53697A
			65204B6579202D2048617368204B6579204669727374
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		} 
		expected: #{
			80B24263C7C1A3EBB71493C1DD7BE8B49B46D1F41B4AEEC1121B013783F8F352
			6B56D037E05F2598BD0FD2215D6A1E5295E64F73F63F0AEC8B915A985D786598
		}
		--assert expected = checksum/with data 'sha512 key
                  
	--test-- "PRF-7-HMAC-SHA-256"
														; data = "This is a test using a larger than block-size key
														; and a larger than block-size data. The key needs to be
														; hashed  before being used by the HMAC algorithm."
		data: #{
			5468697320697320612074657374207573696E672061206C6172676572207468
			616E20626C6F636B2D73697A65206B657920616E642061206C61726765722074
			68616E20626C6F636B2D73697A6520646174612E20546865206B6579206E6565
			647320746F20626520686173686564206265666F7265206265696E6720757365
			642062792074686520484D414320616C676F726974686D2E
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		}
		expected: #{9B09FFA71B942FCB27635FBCD5B0E944BFDC63644F0713938A7F51535C3A35E2}
		--assert expected = checksum/with data 'sha256 key

	--test-- "PRF-7-HMAC-SHA-384"
														; data = "This is a test using a larger than block-size key
														; and a larger than block-size data. The key needs to be
														; hashed  before being used by the HMAC algorithm."
		data: #{
			5468697320697320612074657374207573696E672061206C6172676572207468
			616E20626C6F636B2D73697A65206B657920616E642061206C61726765722074
			68616E20626C6F636B2D73697A6520646174612E20546865206B6579206E6565
			647320746F20626520686173686564206265666F7265206265696E6720757365
			642062792074686520484D414320616C676F726974686D2E
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		}
		expected: #{
			6617178E941F020D351E2F254E8FD32C602420FEB0B8FB9ADCCEBB82461E99C5
			A678CC31E799176D3860E6110C46523E
		}
		--assert expected = checksum/with data 'sha384 key

	--test-- "PRF-7-HMAC-SHA-512"
														; data = "This is a test using a larger than block-size key
														; and a larger than block-size data. The key needs to be
														; hashed  before being used by the HMAC algorithm."
		data: #{
			5468697320697320612074657374207573696E672061206C6172676572207468
			616E20626C6F636B2D73697A65206B657920616E642061206C61726765722074
			68616E20626C6F636B2D73697A6520646174612E20546865206B6579206E6565
			647320746F20626520686173686564206265666F7265206265696E6720757365
			642062792074686520484D414320616C676F726974686D2E
		}
		key:  #{											; 131 bytes
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAA
		}
		expected: #{
			E37B6A775DC87DBAA4DFA9F96E5E3FFDDEBD71F8867289865DF5A32D20CDC944
			B6022CAC3C4982B10D5EEB55C3E4DE15134676FB6DE0446065C97440FA8C6A58
		}
		 --assert expected = checksum/with data 'sha512 key

===end-group===


~~~end-file~~~
