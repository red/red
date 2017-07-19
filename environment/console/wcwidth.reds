Red/System [
	Title:	"Implementation of wcwidth() and wcswidth() for Unicode."
	Author: "Xie Qingtian"
	File: 	%win32.reds
	Tabs: 	4
	Rights: "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		This code was originally derived directly from C code of the same name, 
		whose latest version is available at: wcwidth.c by Markus Kuhn.
		See http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
	}
]
combining-table: [
	0300h 036Fh 0483h 0486h 0488h 0489h
	0591h 05BDh 05BFh 05BFh 05C1h 05C2h
	05C4h 05C5h 05C7h 05C7h 0600h 0603h
	0610h 0615h 064Bh 065Eh 0670h 0670h
	06D6h 06E4h 06E7h 06E8h 06EAh 06EDh
	070Fh 070Fh 0711h 0711h 0730h 074Ah
	07A6h 07B0h 07EBh 07F3h 0901h 0902h
	093Ch 093Ch 0941h 0948h 094Dh 094Dh
	0951h 0954h 0962h 0963h 0981h 0981h
	09BCh 09BCh 09C1h 09C4h 09CDh 09CDh
	09E2h 09E3h 0A01h 0A02h 0A3Ch 0A3Ch
	0A41h 0A42h 0A47h 0A48h 0A4Bh 0A4Dh
	0A70h 0A71h 0A81h 0A82h 0ABCh 0ABCh
	0AC1h 0AC5h 0AC7h 0AC8h 0ACDh 0ACDh
	0AE2h 0AE3h 0B01h 0B01h 0B3Ch 0B3Ch
	0B3Fh 0B3Fh 0B41h 0B43h 0B4Dh 0B4Dh
	0B56h 0B56h 0B82h 0B82h 0BC0h 0BC0h
	0BCDh 0BCDh 0C3Eh 0C40h 0C46h 0C48h
	0C4Ah 0C4Dh 0C55h 0C56h 0CBCh 0CBCh
	0CBFh 0CBFh 0CC6h 0CC6h 0CCCh 0CCDh
	0CE2h 0CE3h 0D41h 0D43h 0D4Dh 0D4Dh
	0DCAh 0DCAh 0DD2h 0DD4h 0DD6h 0DD6h
	0E31h 0E31h 0E34h 0E3Ah 0E47h 0E4Eh
	0EB1h 0EB1h 0EB4h 0EB9h 0EBBh 0EBCh
	0EC8h 0ECDh 0F18h 0F19h 0F35h 0F35h
	0F37h 0F37h 0F39h 0F39h 0F71h 0F7Eh
	0F80h 0F84h 0F86h 0F87h 0F90h 0F97h
	0F99h 0FBCh 0FC6h 0FC6h 102Dh 1030h
	1032h 1032h 1036h 1037h 1039h 1039h
	1058h 1059h 1160h 11FFh 135Fh 135Fh
	1712h 1714h 1732h 1734h 1752h 1753h
	1772h 1773h 17B4h 17B5h 17B7h 17BDh
	17C6h 17C6h 17C9h 17D3h 17DDh 17DDh
	180Bh 180Dh 18A9h 18A9h 1920h 1922h
	1927h 1928h 1932h 1932h 1939h 193Bh
	1A17h 1A18h 1B00h 1B03h 1B34h 1B34h
	1B36h 1B3Ah 1B3Ch 1B3Ch 1B42h 1B42h
	1B6Bh 1B73h 1DC0h 1DCAh 1DFEh 1DFFh
	200Bh 200Fh 202Ah 202Eh 2060h 2063h
	206Ah 206Fh 20D0h 20EFh 302Ah 302Fh
	3099h 309Ah A806h A806h A80Bh A80Bh
	A825h A826h FB1Eh FB1Eh FE00h FE0Fh
	FE20h FE23h FEFFh FEFFh FFF9h FFFBh
	00010A01h 00010A03h 00010A05h 00010A06h 00010A0Ch 00010A0Fh
	00010A38h 00010A3Ah 00010A3Fh 00010A3Fh 0001D167h 0001D169h
	0001D173h 0001D182h 0001D185h 0001D18Bh 0001D1AAh 0001D1ADh
	0001D242h 0001D244h 000E0001h 000E0001h 000E0020h 000E007Fh
	000E0100h 000E01EFh
]

in-table?: func [
	cp		[integer!]
	table	[int-ptr!]
	max		[integer!]
	return: [logic!]
	/local
		a	[integer!]
		b	[integer!]
][
	if any [cp < table/1 cp > table/max][return no]

	a: -1
	until [
		a: a + 2
		b: a + 1
		if all [cp >= table/a cp <= table/b][return yes]
		b = max
	]
	no
]

wcwidth?: func [
	cp		[integer!]
	return: [integer!]
][
	if zero? cp [return 0]
	if any [						;-- tests for 8-bit control characters
		cp < 32
		all [cp >= 7Fh cp < A0h]
	][return 1]

	if in-table? cp combining-table size? combining-table [return 0]

	if any [
		all [
			cp >= 1100h
			any [
				cp <= 115Fh									;-- Hangul Jamo init. consonants
				cp = 2329h
				cp = 232Ah
				all [cp >= 2E80h cp <= A4CFh cp <> 303Fh]	;-- CJK ... Yi
				all [cp >= AC00h cp <= D7A3h]				;-- Hangul Syllables
				all [cp >= F900h cp <= FAFFh]				;-- CJK Compatibility Ideographs
				all [cp >= FE10h cp <= FE19h]				;-- Vertical forms
				all [cp >= FE30h cp <= FE6Fh]				;-- CJK Compatibility Forms
				all [cp >= FF00h cp <= FF60h]				;-- Fullwidth Forms
				all [cp >= FFE0h cp <= FFE6h]
				all [cp >= 00020000h cp <= 0002FFFDh]
				all [cp >= 00030000h cp <= 0003FFFDh]
			]
		]
		cp = 0D0Ah
	][return 2]
	1
]

#if OS = 'Windows [
	ambiguous-table: [
		00A1h 00A1h 00A4h 00A4h 00A7h 00A8h
		00AAh 00AAh 00AEh 00AEh 00B0h 00B4h
		00B6h 00BAh 00BCh 00BFh 00C6h 00C6h
		00D0h 00D0h 00D7h 00D8h 00DEh 00E1h
		00E6h 00E6h 00E8h 00EAh 00ECh 00EDh
		00F0h 00F0h 00F2h 00F3h 00F7h 00FAh
		00FCh 00FCh 00FEh 00FEh 0101h 0101h
		0111h 0111h 0113h 0113h 011Bh 011Bh
		0126h 0127h 012Bh 012Bh 0131h 0133h
		0138h 0138h 013Fh 0142h 0144h 0144h
		0148h 014Bh 014Dh 014Dh 0152h 0153h
		0166h 0167h 016Bh 016Bh 01CEh 01CEh
		01D0h 01D0h 01D2h 01D2h 01D4h 01D4h
		01D6h 01D6h 01D8h 01D8h 01DAh 01DAh
		01DCh 01DCh 0251h 0251h 0261h 0261h
		02C4h 02C4h 02C7h 02C7h 02C9h 02CBh
		02CDh 02CDh 02D0h 02D0h 02D8h 02DBh
		02DDh 02DDh 02DFh 02DFh 0391h 03A1h
		03A3h 03A9h 03B1h 03C1h 03C3h 03C9h
		0401h 0401h 0410h 044Fh 0451h 0451h
		2010h 2010h 2013h 2016h 2018h 2019h
		201Ch 201Dh 2020h 2022h 2024h 2027h
		2030h 2030h 2032h 2033h 2035h 2035h
		203Bh 203Bh 203Eh 203Eh 2074h 2074h
		207Fh 207Fh 2081h 2084h 20ACh 20ACh
		2103h 2103h 2105h 2105h 2109h 2109h
		2113h 2113h 2116h 2116h 2121h 2122h
		2126h 2126h 212Bh 212Bh 2153h 2154h
		215Bh 215Eh 2160h 216Bh 2170h 2179h
		2190h 2199h 21B8h 21B9h 21D2h 21D2h
		21D4h 21D4h 21E7h 21E7h 2200h 2200h
		2202h 2203h 2207h 2208h 220Bh 220Bh
		220Fh 220Fh 2211h 2211h 2215h 2215h
		221Ah 221Ah 221Dh 2220h 2223h 2223h
		2225h 2225h 2227h 222Ch 222Eh 222Eh
		2234h 2237h 223Ch 223Dh 2248h 2248h
		224Ch 224Ch 2252h 2252h 2260h 2261h
		2264h 2267h 226Ah 226Bh 226Eh 226Fh
		2282h 2283h 2286h 2287h 2295h 2295h
		2299h 2299h 22A5h 22A5h 22BFh 22BFh
		2312h 2312h 2460h 24E9h 24EBh 254Bh
		2550h 2573h 2580h 258Fh 2592h 2595h
		25A0h 25A1h 25A3h 25A9h 25B2h 25B3h
		25B6h 25B7h 25BCh 25BDh 25C0h 25C1h
		25C6h 25C8h 25CBh 25CBh 25CEh 25D1h
		25E2h 25E5h 25EFh 25EFh 2605h 2606h
		2609h 2609h 260Eh 260Fh 2614h 2615h
		261Ch 261Ch 261Eh 261Eh 2640h 2640h
		2642h 2642h 2660h 2661h 2663h 2665h
		2667h 266Ah 266Ch 266Dh 266Fh 266Fh
		273Dh 273Dh 2776h 277Fh E000h F8FFh
		FFFDh FFFDh 000F0000h 000FFFFDh 00100000h 0010FFFDh
	]

	cjk-wcwidth?: func [
		cp		[integer!]
		return: [integer!]
	][
		if in-table? cp ambiguous-table size? ambiguous-table [return 2]
		wcwidth? cp
	]
]