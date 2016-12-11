Red/System [
	Title:	"Text Box Windows Uniscribe Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#import [
	"usp10.dll" stdcall [
		ScriptGetCMap: "ScriptGetCMap" [
			hdc			[handle!]
			psc			[int-ptr!]
			text		[c-string!]
			len			[integer!]
			flags		[integer!]
			glyphs		[int-ptr!]
			return:		[integer!]
		]
		ScriptTextOut: "ScriptTextOut" [
			hdc			[handle!]
			psc			[int-ptr!]
			x			[integer!]
			y			[integer!]
			options		[integer!]
			lprc		[RECT_STRUCT]
			psa			[int-ptr!]
			pwcReserved [byte-ptr!]
			iReserved	[integer!]
			pwGlyphs	[int-ptr!]
			cGlyphs		[integer!]
			piAdvance	[int-ptr!]
			piJustify	[int-ptr!]
			pGoffset	[int-ptr!]
			return:		[integer!]
		]
	]
]