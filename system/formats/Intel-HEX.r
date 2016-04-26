REBOL [
	Title:   "Red/System Intel Hex 8-bit format emitter"
	Author:  "Nenad Rakocevic"
	File: 	 %Intel-hex.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	defs: [
		extensions [
			exe %.hex
			obj %.hex
			lib %.hex
			dll %.hex
		]
		;-- ArduinoUno specific runtime code (extract from Arduino's Core lib)
		;-- BSD license an copyrights are available here: http://www.nongnu.org/avr-libc/LICENSE.txt
		init-code #{
			0C9462000C948A000C948A000C948A000C948A000C948A000C948A000C948A00
			0C948A000C948A000C948A000C948A000C948A000C948A000C948A000C948A00
			0C94D7000C948A000C94B3020C948A000C948A000C948A000C948A000C948A00
			0C948A000C948A0000000000240027002A0000000000250028002B0000000000
			2300260029000404040404040404020202020202030303030303010204081020
			4080010204081020010204081020000000070002010000030406000000000000
			0000AF0311241FBECFEFD8E0DEBFCDBF11E0A0E0B1E0EEEAFAE002C005900D92
			AE31B107D9F711E0AEE1B1E001C01D92AE3BB107E1F710E0C4ECD0E004C02297
			FE010E945105C23CD107C9F70E94E9030C9455050C9400008DE061E00E945B02
			68EE73E080E090E00E941F018DE060E00E945B0268EE73E080E090E00E941F01
			89E060E070E00E94D5018BEA91E060E071E00E9427048BEA91E040E452EE61E0
			70E02AE030E00E94C9048EE00E94B301BC018BEA91E04AE050E00E94FF048BEA
			91E00E944103892B21F08BEA91E00E946C0308958DE061E00E9435028BEA91E0
			40E855E260E070E00E94E40208951F920F920FB60F9211242F933F938F939F93
			AF93BF938091220190912301A0912401B0912501309126010196A11DB11D232F
			2D5F2D3720F02D570196A11DB11D209326018093220190932301A0932401B093
			250180911E0190911F01A0912001B09121010196A11DB11D80931E0190931F01
			A0932001B0932101BF91AF919F918F913F912F910F900FBE0F901F9018959B01
			AC017FB7F89480911E0190911F01A0912001B091210166B5A89B05C06F3F19F0
			0196A11DB11D7FBFBA2FA92F982F8827860F911DA11DB11D62E0880F991FAA1F
			BB1F6A95D1F7BC012DC0FFB7F89480911E0190911F01A0912001B0912101E6B5
			A89B05C0EF3F19F00196A11DB11DFFBFBA2FA92F982F88278E0F911DA11DB11D
			E2E0880F991FAA1FBB1FEA95D1F7861B970B885E9340C8F22150304040405040
			68517C4F211531054105510571F60895789484B5826084BD84B5816084BD85B5
			826085BD85B5816085BDEEE6F0E0808181608083E1E8F0E01082808182608083
			808181608083E0E8F0E0808181608083E1EBF0E0808184608083E0EBF0E08081
			81608083EAE7F0E0808184608083808182608083808181608083808180688083
			1092C1000895982F8E3008F09E50977080910A018295880F880F807C892B8093
			7C0080917A00806480937A0080917A0086FDFCCF2091780040917900942F80E0
			30E0282B392BC90108951F93CF93DF93182FEB0161E00E943502209709F44AC0
			CF3FD10509F449C0E12FF0E0E255FF4F84918330C1F0843028F4813051F08230
			B1F50CC0863019F1873049F1843079F514C084B5806884BDC7BD33C084B58062
			84BDC8BD2EC080918000806880938000D0938900C093880024C0809180008062
			80938000D0938B00C0938A001AC08091B00080688093B000C093B30012C08091
			B00080628093B000C093B4000AC0C038D1051CF4812F60E002C0812F61E00E94
			5B02DF91CF911F910895482F50E0CA0186569F4FFC0124914A575F4FFA018491
			8823C1F0E82FF0E0EE0FFF1FE859FF4FA591B491662341F49FB7F8948C912095
			82238C939FBF08959FB7F8948C91822B8C939FBF0895482F50E0CA0182559F4F
			FC012491CA0186569F4FFC0134914A575F4FFA019491992309F444C0222351F1
			233071F0243028F42130A1F0223011F514C02630B1F02730C1F02430D9F404C0
			809180008F7703C0809180008F7D8093800010C084B58F7702C084B58F7D84BD
			09C08091B0008F7703C08091B0008F7D8093B000E92FF0E0EE0FFF1FEE58FF4F
			A591B491662341F49FB7F8948C91309583238C939FBF08959FB7F8948C91832B
			8C939FBF08951F920F920FB60F9211242F933F934F938F939F93EF93FF934091
			C600E091A701F091A80131969F012F77307031978091A9019091AA0128173907
			39F0E95DFE4F40833093A8012093A701FF91EF919F918F914F913F912F910F90
			0FBE0F901F901895CF93DF93EC019A01AB01E885F985203081EE380780E04807
			80E0580709F449C081E090E00A8802C0880F991F0A94E2F7808360E079E08DE3
			90E00E9434052150304040405040CA01B90122E030E040E050E00E943405EC81
			FD813083EE81FF812083EA85FB85208141E050E0CA010E8402C0880F991F0A94
			E2F7282B2083EA85FB852081CA010F8402C0880F991F0A94E2F7282B2083EA85
			FB858081088802C0440F551F0A94E2F7842B8083DF91CF910895108220E130E0
			CECFDC011296ED91FC911397E058FF4F2191319180819181281B390B2F773070
			C9010895DC011296ED91FC911397EE57FF4F2081318192918291E058F0408217
			930719F42FEF3FEF05C0E20FF31F8081282F30E0C9010895DC011296ED91FC91
			1397DF01AE57BF4F2D913C911197E058FF4F80819181E058F0408217930719F4
			2FEF3FEF0BC0E20FF31F80812F5F3F4F2F7730702D933C93282F30E0C9010895
			DC011296ED91FC911397EE57FF4F80819181929382930895FC01A085B1852189
			8C9190E0022E02C0959587950A94E2F780FFF6CF0484F585E02D608308958FE0
			91E09093AC018093AB0187E291E09093AE018093AD0185EC90E09093B0018093
			AF0184EC90E09093B2018093B10180EC90E09093B4018093B30181EC90E09093
			B6018093B50186EC90E09093B8018093B70184E08093B90183E08093BA0187E0
			8093BB0185E08093BC0181E08093BD0108950E9478010E94CA000E948C00FDCF
			0F931F93CF93DF938C01EB0109C02196D801ED91FC910190F081E02DC8010995
			68816623A1F7DF91CF911F910F910895EF92FF920F931F93CF93DF938C017B01
			EA010CC0D7016D917D01D801ED91FC910190F081E02DC80109952197209791F7
			DF91CF911F910F91FF90EF900895DC01ED91FC910280F381E02D099508952F92
			3F924F925F926F927F928F929F92AF92BF92CF92DF92EF92FF920F931F93DF93
			CF93CDB7DEB7A0970FB6F894DEBF0FBECDBF1C016A017B014115510561057105
			49F440E350E060E070E020E030E00E94C90456C0882499245401422E55246624
			772401E010E00C0F1D1F080D191DC701B601A30192010E941205F80160830894
			811C911CA11CB11CC701B601A30192010E941205C901DA016C017D01C114D104
			E104F104F1F681E0E82EF12CEC0EFD1EE80CF91C3E010894611C711CD501C401
			0197A109B1096C01C818D90816C0F601EE0DFF1D40814A3010F4405D01C0495C
			552747FD5095652F752FC10120E030E00E94C9040894E108F1086E147F0439F7
			A0960FB6F894DEBF0FBECDBFCF91DF911F910F91FF90EF90DF90CF90BF90AF90
			9F908F907F906F905F904F903F902F900895EF92FF920F931F93CF93DF93EC01
			7A018B012115310541F4E881F9810190F081E02D642F09951BC02A303105B1F4
			77FF10C04DE250E060E070E020E030E00E94C90410950095F094E094E11CF11C
			011D111DCE01B801A7012AE00E942F04DF91CF911F910F91FF90EF900895EF92
			FF920F931F937B019A010027F7FC0095102FB801A7010E94C9041F910F91FF90
			EF900895A1E21A2EAA1BBB1BFD010DC0AA1FBB1FEE1FFF1FA217B307E407F507
			20F0A21BB30BE40BF50B661F771F881F991F1A9469F760957095809590959B01
			AC01BD01CF01089597FB092E05260ED057FD04D0D7DF0AD0001C38F450954095
			309521953F4F4F4F5F4F0895F6F790958095709561957F4F8F4F9F4F0895EE0F
			FF1F0590F491E02D0994F894FFCF
		}
		init-data #{
			73656E736F72203D200001000000009C03F003080441036C035203900300
			000000000000000000
		}
	]
	
	data-ptr: to-integer #{0100}
	code-ptr: (length? defs/init-code) - 1

	pointer: make-struct [value [short]] none
	
	to-bin16: func [v [integer! char!]][
		skip debase/base to-hex to integer! v 16 2
	]
	
	checksum: func [data [binary!] /local sum][
		sum: 0
		foreach byte data [sum: sum + byte]
		to-bin8 256 - sum
	]
	
	;resolve-data-refs: func [job [object!] /local cbuf dbuf][
	;	cbuf: job/sections/code/2
	;	dbuf: job/sections/data/2
	;	linker/resolve-symbol-refs job cbuf dbuf code-ptr data-ptr pointer
	;]
	
	format-hex: func [buf [binary!] data [binary!] adr [integer!] /local line][
		forskip data 16 [	
			line: rejoin [
				to-bin8 either 16 < length? data [16][length? data] ;-- data size
				to-bin16 adr						;-- data memory address
				#{00}								;-- data record type
				copy/part data 16					;-- insert 16 bytes of data
			]
			repend buf [
				#":"
				enbase/base line 16
				enbase/base checksum line 16
				newline
			]
			adr: adr + 16
		]
		adr
	]
	
	mix: func [data [binary!] value [binary!]][
		chunk: copy chunk
		chunk/1: to char! chunk/1 or (value/2 and 15)
		chunk/2: to char! chunk/2 or shift value/2 4
		chunk/3: to char! chunk/1 or (value/1 and 15)
		chunk/4: to char! chunk/2 or shift value/1 4
		chunk
	]
	
	patch: func [runtime [binary!] /local offset][
		;-- jump over bss section clearing routine
		offset: 1 + to-integer #{00EC}				;-- 01 C0 rmp +2
		change/part at runtime offset #{04} 1		;-- 04 C0 rmp +8
		
		;-- inject Red/System entry point
		offset: 3 + to-integer #{010C}				;-- 0e 94 d9 03   call	0x7B2; <main>
		change/part at runtime offset #{5705} 2		;-- 0e 94 57 05   call	0xAAE; <main>
		
		runtime
	]
	
	
	init-data-copy: func [code data][				;-- (temporary) use Core data copy routine
		chunk: copy #{E0E0F0E0}
		value: length? code
		if odd? value [value: value + 1] 			;-- align on 16-bit word
		value: to-bin16 value
		
		chunk/1: to char! chunk/1 or (value/2 and 15)
		chunk/2: to char! chunk/2 or shift value/2 4
		chunk/3: to char! chunk/3 or (value/1 and 15)
		chunk/4: to char! chunk/4 or shift value/1 4

		replace code #{EEEAFAE0} chunk				;-- start address
	
		chunk: copy #{A030}
		value: (length? data) 						;-- 256 bytes of data only for now

		chunk/1: to char! chunk/1 or (value and 15)
		chunk/2: to char! chunk/2 or shift value 4
		
		replace code #{AE31} chunk					;-- end address		
	]

	build: func [job [object!] /local out][
		;resolve-data-refs job
		
		
		out: job/buffer
		
		code: patch copy defs/init-code
		code: append code job/sections/code/2
		append code #{FFCF}
		;append code #{FDCFFFCF}
		
		insert job/sections/data/2 defs/init-data
		init-data-copy code job/sections/data/2
		if odd? length? code [append code #{00}]	;-- align data start on word boundary
		append code job/sections/data/2
		
		format-hex out code 0
		append out ":00000001FF^/"					;-- end record
	]
]