REBOL [
	Title:   "Android APK Signing Tool"
	Author:  "Qingtian Xie"
	File: 	 %signapk.r
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Acknowledgements: {
		Inspired by Tamas's (onetom@hackerspace.sg) jarsigner studying code.
	}
]

signapk: context [

	test-key: make object! [
		n: #{
			A126AF491CA4A84FC29AC4A0F69E66FECA11E4B1687D042A65A9BB9AD12BD3EB
			FB1B07002FCF88EA441A9FAB5A60FFC1148DDAA7D9791AADB3F8D5B08FF7C42B
			81414E66BDDA9F458A66C4909B73DA6AF0A8F2527B05CA4D24C5374AAD50DE81
			8D0F16351F51DC324F5D0A9FD5C61A5B7C6ABB2393E3302D84D88EB24B18C7BE
			CD0966FE173695E1D380BBD09F295B8CA97B2B7392E3C8275E3E0C0B5ED9AC44
			B2750CACF7DE78A052DB138AFCF650D2E86EACDFCC564368EC49CF0A2796250D
			5C610FC186B0674011A37AB361483E481AE3A3ACBF7143F265DEEAF7C5F8FA37
			0AE7C4516531D9DF126AD057502B515056126F7A2D50DB657EA6AFCBFB3FC4FF
		}
		e: 65537
		d: #{
			51E8D6C9839C91CC50AED7E8B4D198AA42CD4B7F7D0BA635628D1E4537B25E3A
			20DD00F6F0563D524DA176ACE2F850A6B42AD20BE4B6F07F7FEDA7B7E1C55ED9
			7A0E56AA542FAE2AEB8906BA35B972384EF0A09299E33C8B6F782A7D73909A38
			21199D010D554F65E6FEF4AA7F3EFD20A9219AD31F952764CB94431B8E9E1ED0
			23872CDCF847C0AD96C7D423F9DA43B052631E42A9FF39C210B4D1A5F5B27DD7
			317E4D4CC2CDDB2CAEBD5106FED5EA4F0489ADDFB41A54E896DDF1E7F2086F39
			5AC24FE27CF974C5BB1CF97F51510BA621A11D8C39B8859DBA273874B02F6464
			E5BEE73E8668AE95934656B209F5934A21157C2E88B75C3407C0E19B654EA091
		}
		p: #{
			F381487C173D72A2DE7D5D32C4F2AE892BBCEBFB27FEA5E2D4295E752BD3D14C
			C3EFA3FA9DA24D3C4DE1A0C2C5F160402EB511BEEA48E99268194E70A67D2FAE
			0795D574FE2C8975C6108F71F22F669883C75543EA92C0F5924EA6E249B89861
			E5674D9349504604CEE039098361B460772F386BBBD6AE4FB79C21ADFB9E3A27
		}
		q: #{
			A96B96C197E9252C1A1546CF3CBA47A45B2C067A9F082E15D35235D89AA16DEB
			2BFBAF5C746BD92BBBEB5CFFFEAA2F48D386C2032A2B58920D14B6EF39939A92
			EFE7E175CDB8657468284089138C7B319B014AA8120F6EC80BED445696C9A65B
			DDB763C1CAF28013A469D068CAF8193D264F01429E580DFEE23F519052D09D69
		}
		dmp1: #{
			CF465B5715C93E8D98EA09AD2FAC8C19435BDB5BBD1DAC433AE9C3F7E548B6BE
			AB828F88C329E6A8D07AA1076ACB1E6D43D4E9B82361D140C8CFD1CF5E48ED8F
			2BF1C4F3837091C9E8C12BF9887804D30A49613120B9AEFADA818CD8CE7C0D6A
			378609A8B81D569CBD246C28C6E7224D82E675166F9C3C60AB208222C12E5CBD
		}
		dmq1: #{
			347AF46721B481E4486C20D41F3EA0E4A3AD5E906B64F049A87D45DAC4038F76
			12D8D2F873C3D8B0F8742F09C98C543B5DF2D7747D8291DC241B2F93A92534F3
			A147160B14DFB2E5BD4202C3B37F87C5D4FB307221AE1025FDB3D0C075D31F2A
			43E3040ECADC159A800A9B196B0E315B44DBA24B4D9B7F325E4938EDD9097049
		}
		iqmp: #{
			02C71888CE59BB7864293E30DEA119EFEB29F0445E5570AF24C8D7519A31663B
			D6FA7F16051C6D222E34484539441D183F5CF12D4B7CAC4F3AED910083DA2871
			F273D645F206B33AB8D1E91199820F77EA857B1F2272CFE501FD9F6F0A73C184
			5ADFDEEC2C76E6F03FF428EC51733B0694A607765B8F88141C6417051ED2CCF2
		}
		n-mont-ri: none
		n-mont-rr: none
		n-mont-n: none
		n-mont-ni: none
		n-mont-n0: none
		n-mont-flags: none
		p-mont-ri: none
		p-mont-rr: none
		p-mont-n: none
		p-mont-ni: none
		p-mont-n0: none
		p-mont-flags: none
		q-mont-ri: none
		q-mont-rr: none
		q-mont-n: none
		q-mont-ni: none
		q-mont-n0: none
		q-mont-flags: none
	]

	test-cert: #{
		3082056306092A864886F70D010702A082055430820550020101310B30090605
		2B0E03021A0500300B06092A864886F70D010701A0820389308203853082026D
		A003020102020413224882300D06092A864886F70D01010B05003073310B3009
		060355040613025553310E300C0603550408130573746174653111300F060355
		040713086C6F636174696F6E31153013060355040A130C6F7267616E69736174
		696F6E311C301A060355040B13136F7267616E69736174696F6E616C20756E69
		74310C300A06035504031303526564301E170D3134303731353039323733335A
		170D3431313133303039323733335A3073310B3009060355040613025553310E
		300C0603550408130573746174653111300F060355040713086C6F636174696F
		6E31153013060355040A130C6F7267616E69736174696F6E311C301A06035504
		0B13136F7267616E69736174696F6E616C20756E6974310C300A060355040313
		0352656430820122300D06092A864886F70D01010105000382010F003082010A
		0282010100A126AF491CA4A84FC29AC4A0F69E66FECA11E4B1687D042A65A9BB
		9AD12BD3EBFB1B07002FCF88EA441A9FAB5A60FFC1148DDAA7D9791AADB3F8D5
		B08FF7C42B81414E66BDDA9F458A66C4909B73DA6AF0A8F2527B05CA4D24C537
		4AAD50DE818D0F16351F51DC324F5D0A9FD5C61A5B7C6ABB2393E3302D84D88E
		B24B18C7BECD0966FE173695E1D380BBD09F295B8CA97B2B7392E3C8275E3E0C
		0B5ED9AC44B2750CACF7DE78A052DB138AFCF650D2E86EACDFCC564368EC49CF
		0A2796250D5C610FC186B0674011A37AB361483E481AE3A3ACBF7143F265DEEA
		F7C5F8FA370AE7C4516531D9DF126AD057502B515056126F7A2D50DB657EA6AF
		CBFB3FC4FF0203010001A321301F301D0603551D0E041604147FAE8DCF31300B
		0905625F4092887C2F7BB26773300D06092A864886F70D01010B050003820101
		0083A5EA73ED2F3419B2B0B5CF96BEB847C8B468810D92AE41FDDB127396D357
		2CE201E9684D85E807F38462ABDFEF20B085309DE1AF78238279B57898AAB277
		47B5FCF86471301EAA6BB8B5ADE84E0941956AC533FBE8DE1CF7BD7C88CCBD6A
		A8EAB83F54226408BB5EEA50C138F6544F8775F9B759B9F1D0F9BA29C782FABC
		098C12631ED1FA5FC1A2212588DBDE8757FD088010D63443363DFF97E24482CD
		88CC013AD89E0EABFDD3656C3694F62EE767D8D86EBBA196F5648CDD190408F3
		23B250FB046748519CCDCD8985C5B976C349CCB76615E0FC02E9CECA98ACAF50
		F58752F5677DF90C3ACA564084AF73BCF3BB298D2AFB29F89BE1BDA825984907
		56318201A23082019E020101307B3073310B3009060355040613025553310E30
		0C0603550408130573746174653111300F060355040713086C6F636174696F6E
		31153013060355040A130C6F7267616E69736174696F6E311C301A060355040B
		13136F7267616E69736174696F6E616C20756E6974310C300A06035504031303
		526564020413224882300906052B0E03021A0500300D06092A864886F70D0101
		01050004820100
	}

	sign-info!: context [
		keystore-path:       none
		keystore-password:   none
		key-password:        none
		key:                 none
		keysize:             2048
		alias:               none
		validity:            none
		name:                none
		locality:            none
		state:               none
		country:             none
		organisation:        none
		organisational-unit: none
		issuer:              none
		serial-number:       none
	]

	PKCS7-spec: [											;-- http://tools.ietf.org/html/rfc2315
		#{30} [												;-- signedData
			#{06} #{2A864886F70D010702}						;-- ID: signedData PKCS #7
			#{A0} [
				#{30} [
					#{02} #{01}								;-- version
					#{31} #{300906052B0E03021A0500}			;-- digestAlgorithm: sha1 OIW
					#{30} #{06092A864886F70D010701}			;-- contentInfo: data PKCS #7
					#{A0} X509								;-- certificates, optional.
					#{31} signer-info
				]
			]
		]
	]

	signer-info-spec: [
		#{30} [
			#{02} #{01}										;-- version
			#{30} [											;;- ver.1 use issuerAndSerialNumber as SignerIdentifier
				#{30} issuer								;;- ver.3 use subjectKeyIdentifier as SignerIdentifier
				#{02} serial-number
			]
			#{30} #{06052B0E03021A0500}					;-- digestAlgorithm: sha1 OIW
			#{30} #{06092A864886F70D0101010500}				;-- rsaEncryption
			#{04} signature									;-- octet string: signature value
		]
	]

	X509-spec: [												;-- http://tools.ietf.org/html/rfc5280#section-4
		#{30} [
			#{30} tbs-certificate							;-- TBS certificates
			#{30} #{06092A864886F70D0101050500}				;-- signature algorithm: sha1withRSA
			#{03} signature-value							;-- signature value
		]
	]

	tbs-certificate-spec: [
		#{A0} #{020102}
		#{02} serial-number
		#{30} #{06092A864886F70D0101050500}					;-- sha1withRSA: 010105 sha256withRSA: 01010B
		#{30} issuer
		#{30} validity
		#{30} subject
		#{30} public-key-info
		#{A3} subject-key-identifier
	]

	public-key-info-spec:[
		#{30} #{06092A864886F70D0101010500}					;-- rsaEncryption
		#{03} [#{0030} [#{02} modulus #{02} public-exponent]]
	]

	int-to-hex: func [int [integer!] /local out b][
		out: debase/base to-hex int 16
		until [
			either zero? to integer! out/1 [remove out][break]
			empty? out
		]
		out
	]

	encode-len: func [data [series!] /local len xlen xtra][
		either 127 < len: length? data [
			xlen: int-to-hex len
			xtra: int-to-hex 128 + length? xlen
			head insert tail xtra xlen
		][to char! length? data]
	]

	DER-encode: func [spec [block!] data [block!] /local out tag value][
		out: make binary! 128
		foreach [tag value] spec [
			value: either block? value [
				DER-encode value data
			][
				if word? value [value: select data value]
				value
			]
			unless empty? value [repend out [tag encode-len value value]]
		]
		out
	]

	add-leading-zero: func [d [integer!] /local s rem][
		s: to-string d
		unless zero? rem: (length? s) // 2 [
			insert s #"0"
		]
		s
	]

	encode-date: func [date [date!] /local str year tag][
		year: date/year
		str: to-string either year > 2049 [
			tag: #{18}									;-- GeneralizedTime
			year
		][
			tag: #{17}									;-- UTCTime
			mod year 100
		]
		repend str [
			add-leading-zero date/month
			add-leading-zero date/day
			add-leading-zero date/time/hour
			add-leading-zero date/time/minute
			add-leading-zero to-integer date/time/second
			#"Z"
		]
		DER-encode reduce [tag str] []
	]

	encode-validity: func [year [integer!] /local current expire][
		current: expire: now
		expire/year: expire/year + year
		join encode-date current encode-date expire
	]

	encode-issuer: func [sign-info [object!] /local info value data][
		data: make binary! 128
		info: [
			country				#{0603550406}
			state				#{0603550408}
			locality			#{0603550407}
			organisation		#{060355040A}
			organisational-unit	#{060355040B}
			name				#{0603550403}
		]
		foreach [item id] info [
			value: select sign-info item
			if value [											;TBD handle non-ASCII String
				value: DER-encode reduce [#{13} value] []		;-- Tag: PrintableString
				value: DER-encode reduce [#{30} join id value] []
				value: DER-encode reduce [#{31} value] []
				append data value
			]
		]
		data
	]

	encode-public-key: func [key [object!] /local data][
		data: reduce [
			'modulus join #{00} key/n
			'public-exponent key/e
		]
		DER-encode public-key-info-spec data
	]

	encode-tbs-cert: func [sign-info [object!] /local data][
		data: reduce [
			'serial-number		sign-info/serial-number
			'issuer				sign-info/issuer
			'validity			encode-validity sign-info/validity
			'subject			sign-info/issuer
			'public-key-info	encode-public-key sign-info/key
			'subject-key-identifier #{}
		]
		DER-encode tbs-certificate-spec data
	]

	encode-X509: func [
		sign-info [object!]
		/local data tbs-cert tbs-cert-der digest digest-der sig-value
	][
		tbs-cert: encode-tbs-cert sign-info
		tbs-cert-der: DER-encode reduce [#{30} tbs-cert] []
		digest: checksum/method tbs-cert-der 'sha1
		digest-der: join #{3021300906052B0E03021A05000414} digest
		sig-value: rsa-encrypt/private sign-info/key digest-der
		insert sig-value #{00}
		data: reduce [
			'tbs-certificate tbs-cert
			'signature-value sig-value
		]
		DER-encode X509-spec data
	]

	encode-signer-info: func [sign-info [object!] /local data sig len][
		len: select [512 64 1024 128 2048 256] sign-info/keysize
		sig: make binary! len
		insert/dup sig null len
		data: reduce [
			'issuer			sign-info/issuer
			'serial-number	sign-info/serial-number
			'signature		sig
		]
		DER-encode signer-info-spec data
	]

	encode-PKCS7: func [sign-info [object!] /local data sig-len][
		sig-len: select [512 64 1024 128 2048 256] sign-info/keysize
		data: reduce [
			'X509			encode-X509 sign-info
			'signer-info	encode-signer-info sign-info
		]
		data: DER-encode PKCS7-spec data
		clear skip tail data negate sig-len
		data
	]

	generate-keystore: func [sign-info [object!] /local key keystore][
		key: rsa-make-key
		rsa-generate-key key 2048 65537
		sign-info/key: key
		sign-info/issuer: encode-issuer sign-info
		sign-info/serial-number: int-to-hex random 2147483647
		keystore: reduce [key encode-PKCS7 sign-info]
		write/binary sign-info/keystore-path mold keystore		;TBD encrypt keystore file
		keystore
	]

	sign: func [
		keystore [block! none!]
		entries  [block!]
		/local
			mf sf m-entries m-entry digest sig-data
			z-entry filename sha1 key cert
	][
		mf: make binary! 4096
		sf: make binary! 4096
		m-entries: make block! 16

		repend mf [										;-- MANIFEST.MF
			"Manifest-Version: 1.0" crlf
			"Created-By: 1.0 (Red SignApk)" crlf
			crlf
		]
		foreach entry entries [
			set [z-entry filename sha1] entry
			m-entry: join #{} [
				"Name: " filename crlf
				"SHA1-Digest: " enbase sha1 crlf
				crlf
			]
			append mf m-entry
			repend m-entries [filename checksum/method m-entry 'sha1]
		]

		repend sf [										;-- CERT.SF
			"Signature-Version: 1.0" crlf
			"Created-By: 1.0 (Red SignApk)" crlf
			"SHA1-Digest-Manifest: " enbase checksum/method mf 'sha1 crlf
			crlf
		]
		foreach [filename sha1] m-entries [
			repend sf [
				"Name: " filename crlf
				"SHA1-Digest: " enbase sha1 crlf
				crlf
			]
		]

		digest: checksum/method sf 'sha1				;-- CERT.RSA
		sig-data: join #{3021300906052B0E03021A05000414} digest		;-- DER encode
		either none? keystore [
			key: test-key cert: test-cert
		][
			set [key cert] keystore
		]
		cert: join cert rsa-encrypt/private key sig-data
		reduce [mf sf cert]
	]
]