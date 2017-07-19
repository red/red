Red/System [
	Title:	"Objective-C Selectors"
	Author: "Qingtian Xie"
	File: 	%selectors.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- Cocoa framework selectors



;-- User's define selectors

sel-on-timer:					0
sel_release:					0
sel_alloc:						0
sel_init:						0
sel_initWithFrame:				0
sel_changeFont:					0
sel_windowWillClose:			0
sel_addObject:					0
sel_addAttributes:				0
sel_addAttribute:				0
sel_initWithObjectsAndKeys:		0
sel_arrayWithObject:			0

cls_NSArray:					0

init-selectors: does [
	sel-on-timer:				sel_getUid "on-timer:"
	sel_release:				sel_getUid "release"
	sel_alloc:					sel_getUid "alloc"
	sel_init:					sel_getUid "init"
	sel_initWithFrame:			sel_getUid "initWithFrame:"
	sel_changeFont:				sel_getUid "changeFont:"
	sel_windowWillClose:		sel_getUid "windowWillClose:"
	sel_addObject:				sel_getUid "addObject:"
	sel_addAttributes:			sel_getUid "addAttributes:range:"
	sel_addAttribute:			sel_getUid "addAttribute:value:range:"
	sel_initWithObjectsAndKeys:	sel_getUid "initWithObjectsAndKeys:"
	sel_arrayWithObject:		sel_getUid "arrayWithObject:"

	cls_NSArray:				objc_getClass "NSArray"
]