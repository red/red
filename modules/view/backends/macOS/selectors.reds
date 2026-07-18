Red/System [
	Title:	"Objective-C Selectors"
	Author: "Qingtian Xie"
	File: 	%selectors.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- Cocoa framework selectors



;-- User's define selectors

sel-on-timer:					as Cocoa-handle! 0
sel_release:					as Cocoa-handle! 0
sel_alloc:						as Cocoa-handle! 0
sel_init:						as Cocoa-handle! 0
sel_initWithFrame:				as Cocoa-handle! 0
sel_changeFont:					as Cocoa-handle! 0
sel_windowWillClose:			as Cocoa-handle! 0
sel_addObject:					as Cocoa-handle! 0
sel_addAttributes:				as Cocoa-handle! 0
sel_addAttribute:				as Cocoa-handle! 0
sel_arrayWithObject:			as Cocoa-handle! 0
sel_length:						as Cocoa-handle! 0

cls_NSArray:					as Cocoa-handle! 0

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
	sel_arrayWithObject:		sel_getUid "arrayWithObject:"
	sel_length:					sel_getUid "length"

	cls_NSArray:				objc_getClass "NSArray"
]
