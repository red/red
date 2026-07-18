Red/System [
	Title:	"Windows classes handling"
	Author: "Qingtian Xie"
	File: 	%classes.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %delegates.reds
#include %camera.reds

#enum subclass-flags! [	
	STORE_FACE_FLAG: 1
	EXTRA_DATA_FLAG: 2
]

#either ABI = 'apple-aarch64 [
	#define SIG_DRAW_RECT		"v@:{CGRect={CGPoint=dd}{CGSize=dd}}"
	#define SIG_HIT_TEST		"@@:{CGPoint=dd}"
	#define SIG_RANGE_RETURN	"{_NSRange=QQ}@:"
	#define SIG_SET_MARKED		"v@:@{_NSRange=QQ}{_NSRange=QQ}"
	#define SIG_ATTR_SUBSTRING	"@@:{_NSRange=QQ}^{_NSRange=QQ}"
	#define SIG_INSERT_RANGE	"v@:@{_NSRange=QQ}"
	#define SIG_CHAR_POINT		"Q@:{CGPoint=dd}"
	#define SIG_FIRST_RECT		"{CGRect={CGPoint=dd}{CGSize=dd}}@:{_NSRange=QQ}^{_NSRange=QQ}"
	#define SIG_CONVERT_POINT	"{CGPoint=dd}@:{CGPoint=dd}@"
	#define SIG_TEXT_SELECT		"{_NSRange=QQ}@:@{_NSRange=QQ}{_NSRange=QQ}"
	#define SIG_TABLE_ROWS		"q@:@"
	#define SIG_TABLE_OBJECT	"@@:@@q"
	#define SIG_TABLE_EDIT		"B@:@@q"
	#define SIG_LINE_SPACING	"d@:@Q{CGRect={CGPoint=dd}{CGSize=dd}}"
	#define SIG_NSINTEGER		"q@:@"
	#define SIG_WINDOW_LEVEL	"q@:"
	#define RED_IVAR_SIZE		8
	#define RED_IVAR_ALIGN		3
	#define RED_IVAR_TYPE		"^v"
][
	#define SIG_DRAW_RECT		"v@:{_NSRect=ffff}"
	#define SIG_HIT_TEST		"@@:{_NSPoint=ff}"
	#define SIG_RANGE_RETURN	"{_NSRange=ii}@:"
	#define SIG_SET_MARKED		"v@:@{_NSRange=ii}{_NSRange=ii}"
	#define SIG_ATTR_SUBSTRING	"@@:{_NSRange=ii}^{_NSRange=ii}"
	#define SIG_INSERT_RANGE	"v@:@{_NSRange=ii}"
	#define SIG_CHAR_POINT		"I@:{_NSPoint=ff}"
	#define SIG_FIRST_RECT		"{_NSRect=ffff}@:{_NSRange=ii}^{_NSRange=ii}"
	#define SIG_CONVERT_POINT	"{_NSPoint=ff}20@0:4{_NSPoint=ff}8@16"
	#define SIG_TEXT_SELECT		"{_NSRange=ii}@:@{_NSRange=ii}{_NSRange=ii}"
	#define SIG_TABLE_ROWS		"l@:@"
	#define SIG_TABLE_OBJECT	"@20@0:4@8@12l16"
	#define SIG_TABLE_EDIT		"B@:@@l"
	#define SIG_LINE_SPACING	"f@:@I{_NSRect=ffff}"
	#define SIG_NSINTEGER		"i12@0:4@8"
	#define SIG_WINDOW_LEVEL	"i@:"
	#define RED_IVAR_SIZE		4
	#define RED_IVAR_ALIGN		2
	#define RED_IVAR_TYPE		"i"
]

add-method!: alias function! [class [Cocoa-handle!]]

add-content-view-handler: func [class [Cocoa-handle!]][
	flip-coord class
	class_addMethod class sel_getUid "drawRect:" as int-ptr! :draw-rect SIG_DRAW_RECT
]

add-base-handler: func [class [Cocoa-handle!]][
	flip-coord class
	class_addMethod class sel_getUid "drawRect:" as int-ptr! :draw-rect SIG_DRAW_RECT
	class_addMethod class sel_getUid "red-menu-action:" as int-ptr! :red-menu-action "v@:@"
	class_addMethod class sel_getUid "acceptsFirstResponder" as int-ptr! :accepts-first-responder "B@:"
	class_addMethod class sel_getUid "scrollWheel:" as int-ptr! :scroll-wheel "@:@"
	class_addMethod class sel_getUid "hitTest:" as int-ptr! :hit-test SIG_HIT_TEST
	class_replaceMethod class sel_getUid "rightMouseDown:" as int-ptr! :mouse-events-base "v@:@"
	class_replaceMethod class sel_getUid "rightMouseUp:" as int-ptr! :mouse-events-base "v@:@"

	class_addMethod class sel_getUid "keyDown:" as int-ptr! :key-down-base "v@:@"
	class_addMethod class sel_getUid "insertText:" as int-ptr! :insert-text "v@:@"
	class_addMethod class sel_getUid "hasMarkedText" as int-ptr! :has-marked-text "B@:"
	class_addMethod class sel_getUid "markedRange" as int-ptr! :marked-range SIG_RANGE_RETURN
	class_addMethod class sel_getUid "selectedRange" as int-ptr! :selected-range SIG_RANGE_RETURN
	class_addMethod class sel_getUid "setMarkedText:selectedRange:replacementRange:" as int-ptr! :set-marked-text SIG_SET_MARKED
	class_addMethod class sel_getUid "unmarkText" as int-ptr! :unmark-text "v@:"
	class_addMethod class sel_getUid "validAttributesForMarkedText" as int-ptr! :valid-attrs-marked-text "@@:"
	class_addMethod class sel_getUid "attributedSubstringForProposedRange:actualRange:" as int-ptr! :attr-str-range SIG_ATTR_SUBSTRING
	class_addMethod class sel_getUid "insertText:replacementRange:" as int-ptr! :insert-text-range SIG_INSERT_RANGE
	class_addMethod class sel_getUid "characterIndexForPoint:" as int-ptr! :char-idx-point SIG_CHAR_POINT
	class_addMethod class sel_getUid "firstRectForCharacterRange:actualRange:" as int-ptr! :first-rect-range SIG_FIRST_RECT
	class_addMethod class sel_getUid "doCommandBySelector:" as int-ptr! :do-cmd-selector "v@::"
	class_addMethod class sel_getUid "windowLevel" as int-ptr! :win-level SIG_WINDOW_LEVEL
]

add-scrollview-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "setNeedsDisplay:" as int-ptr! :refresh-scrollview "v@:B"
	class_addMethod class sel_getUid "_doScroller:" as int-ptr! :scroller-change "v@:@"
	class_addMethod class sel_getUid "reflectScrolledClipView:" as int-ptr! :empty-func "@:@"
]

win-add-subview: func [
	[cdecl]
	self	[Cocoa-handle!]
	cmd		[Cocoa-handle!]
	view	[Cocoa-handle!]
][
	objc_msgSend [
		objc_msgSend [self sel_getUid "contentView"]
		sel_getUid "addSubview:" view
	]
]

#either ABI = 'apple-aarch64 [
	win-convert-point: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		point	[CGPoint! value]
		view	[Cocoa-handle!]
		return: [CGPoint! value]
	][
		objc_msgSend_pt [
			objc_msgSend [self sel_getUid "contentView"]
			sel_getUid "convertPoint:fromView:" point/x point/y view
		]
	]
][
	win-convert-point: func [
		[cdecl]
		self	[Cocoa-handle!]
		cmd		[Cocoa-handle!]
		x		[integer!]
		y		[integer!]
		view	[Cocoa-handle!]
		/local
			rc	[NSRect!]
	][
		x: objc_msgSend [
			objc_msgSend [self sel_getUid "contentView"]
			sel_getUid "convertPoint:fromView:" x y view
		]
		y: system/cpu/edx
		rc: as NSRect! :x
		system/cpu/edx: y
		system/cpu/eax: x
	]
]

add-window-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "windowWillClose:" as int-ptr! :win-will-close "v12@0:4@8"
	class_addMethod class sel_getUid "windowShouldClose:" as int-ptr! :win-should-close "B@:@"
	class_addMethod class sel_getUid "windowDidMove:" as int-ptr! :win-did-move "v12@0:4@8"
	class_addMethod class sel_getUid "windowDidResize:" as int-ptr! :win-did-resize "v12@0:4@8"
	class_addMethod class sel_getUid "windowWillReturnFieldEditor:toObject:" as int-ptr! :return-field-editor "@@:@@"
	class_addMethod class sel_getUid "windowDidEndLiveResize:" as int-ptr! :win-live-resize "v12@0:4@8"
	;class_addMethod class sel_getUid "windowWillResize:toSize:" as int-ptr! :win-will-resize "{_NSSize=ff}20@0:4@8{_NSSize=ff}12"
	class_addMethod class sel_getUid "red-menu-action:" as int-ptr! :red-menu-action "v@:@"
	class_addMethod class sel_getUid "addSubview:" as int-ptr! :win-add-subview "v12@0:4@8"
	class_addMethod class sel_getUid "convertPoint:fromView:" as int-ptr! :win-convert-point SIG_CONVERT_POINT
]

add-button-handler: func [class [Cocoa-handle!]][
	class_replaceMethod class sel_getUid "mouseDown:" as int-ptr! :button-mouse-down "v@:@"
]

add-slider-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "slider-change:" as int-ptr! :slider-change "v@:@"
]

add-droplist-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "popup-button-action:" as int-ptr! :popup-button-action "v@:@"
]

add-text-field-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "textDidChange:" as int-ptr! :text-did-change "v@:@"
	class_addMethod class sel_getUid "textDidEndEditing:" as int-ptr! :text-did-end-editing "v@:@"
	;class_addMethod class sel_getUid "textViewDidChangeSelection:" as int-ptr! :text-change-selection "v@:@"
	class_addMethod class sel_getUid "textView:willChangeSelectionFromCharacterRange:toCharacterRange:" as int-ptr! :text-will-selection SIG_TEXT_SELECT
	class_addMethod class sel_getUid "becomeFirstResponder" as int-ptr! :become-first-responder "B@:"
	class_addMethod class sel_getUid "performKeyEquivalent:" as int-ptr! :perform-key-equivalent "B@:@"
]

add-area-handler: func [class [Cocoa-handle!]][
	add-text-field-handler class
	class_replaceMethod class sel_getUid "textDidChange:" as int-ptr! :area-text-change "v@:@"
	class_replaceMethod class sel_getUid "textDidEndEditing:" as int-ptr! :area-did-end-editing "v@:@"
]

add-combo-box-handler: func [class [Cocoa-handle!]][
	add-text-field-handler class
	class_addMethod class sel_getUid "comboBoxSelectionDidChange:" as int-ptr! :selection-change "v@:@"
]

add-table-view-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "numberOfRowsInTableView:" as int-ptr! :number-of-rows SIG_TABLE_ROWS
	class_addMethod class sel_getUid "tableView:objectValueForTableColumn:row:" as int-ptr! :object-for-table SIG_TABLE_OBJECT
	class_addMethod class sel_getUid "tableViewSelectionDidChange:" as int-ptr! :table-select-did-change "v@:@"
	class_addMethod class sel_getUid "tableView:shouldEditTableColumn:row:" as int-ptr! :table-cell-edit SIG_TABLE_EDIT
	class_addMethod class sel_getUid "red-menu-action:" as int-ptr! :red-menu-action "v@:@"
]

add-camera-handler: func [class [Cocoa-handle!]][
	0
]

add-calendar-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "calendar-change" as int-ptr! :calendar-change "v@"
]

add-tabview-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "tabView:shouldSelectTabViewItem:" as int-ptr! :tabview-should-select "B@:@@"
]

add-filedialog-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "filter-filetype:" as int-ptr! :filter-filetype-action "v@:@"
]

add-text-layout-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "layoutManager:lineSpacingAfterGlyphAtIndex:withProposedLineFragmentRect:" as int-ptr! :set-line-spacing SIG_LINE_SPACING
]

add-app-handler: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "sendEvent:" as int-ptr! :app-send-event "v@:@"
	;class_addMethod class sel_getUid "stop:" as int-ptr! :stop-app "v@:@"
]

add-app-delegate: func [class [Cocoa-handle!]][
	;class_addMethod class sel_getUid "applicationWillFinishLaunching:" as int-ptr! :will-finish "v12@0:4@8"
	;class_addMethod class sel_getUid "dealloc" as int-ptr! :dealloc-app "v@:"
	class_addMethod class sel_getUid "applicationShouldTerminate:" as int-ptr! :should-terminate SIG_NSINTEGER
	class_addMethod class sel_getUid "applicationShouldTerminateAfterLastWindowClosed:" as int-ptr! :destroy-app "B12@0:4@8"
]

add-panel-delegate: func [class [Cocoa-handle!]][
	class_addMethod class sel_changeFont as int-ptr! :dialog-proc "v@:@"
	class_addMethod class sel_windowWillClose as int-ptr! :dialog-proc "v@:@"
]

flip-coord: func [class [Cocoa-handle!]][
	class_addMethod class sel_getUid "isFlipped" as int-ptr! :is-flipped "B@:"
]

make-super-class: func [
	new		[c-string!]
	base	[c-string!]
	method	[int-ptr!]				;-- override functions or add functions
	flags	[integer!]
	return:	[Cocoa-handle!]
	/local
		new-class	[Cocoa-handle!]
		add-method	[add-method!]
		protocol	[c-string!]
][
	new-class: objc_allocateClassPair objc_getClass base new as Cocoa-uhandle! 0
	if flags and EXTRA_DATA_FLAG <> 0 [
		class_addIvar new-class IVAR_RED_DATA as Cocoa-uhandle! RED_IVAR_SIZE as byte! RED_IVAR_ALIGN RED_IVAR_TYPE
		class_addIvar new-class IVAR_RED_DRAW_CTX as Cocoa-uhandle! RED_IVAR_SIZE as byte! RED_IVAR_ALIGN RED_IVAR_TYPE
	]
	if flags and STORE_FACE_FLAG <> 0 [
		class_addIvar new-class IVAR_RED_FACE as Cocoa-uhandle! RED_IVAR_SIZE as byte! RED_IVAR_ALIGN RED_IVAR_TYPE
		class_addMethod new-class sel-on-timer as int-ptr! :red-timer-action "v@:@"
		class_addMethod new-class sel_getUid "mouseEntered:" as int-ptr! :mouse-entered "v@:@"
		class_addMethod new-class sel_getUid "mouseExited:" as int-ptr! :mouse-exited "v@:@"
		class_addMethod new-class sel_getUid "mouseMoved:" as int-ptr! :mouse-moved "v@:@"
		class_addMethod new-class sel_getUid "mouseDown:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "mouseUp:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "mouseDragged:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseDown:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseUp:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseDragged:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseDown:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseUp:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseDragged:" as int-ptr! :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "resetCursorRects" as int-ptr! :reset-cursor-rects "v@:"

		class_addMethod new-class sel_getUid "keyUp:" as int-ptr! :on-key-up "v@:@"
		class_addMethod new-class sel_getUid "flagsChanged:" as int-ptr! :on-flags-changed "v@:@"
	]
	if method <> null [
		add-method: as add-method! method
		add-method new-class
	]

	protocol: case [
		all [new/4 = #"B" new/5 = #"a" new/6 = #"s" new/7 = #"e"]["NSTextInputClient"]
		all [new/4 = #"A" new/5 = #"p" new/6 = #"p" new/7 = #"D"]["NSApplicationDelegate"]
		true [null]
	]
	if protocol <> null [class_addProtocol new-class objc_getProtocol protocol]

	objc_registerClassPair new-class
	new-class
]

init-proc!: alias function! [
	hWnd	[int-ptr!]
	values	[red-value!]
	return: [logic!]
]

ext-class!: alias struct! [
	symbol		 [integer!]								;-- symbol ID
	class		 [c-string!]							;-- UTF-8 encoded
	parent-class [c-string!]							;-- UTF-8 encoded
	new-proc	 [int-ptr!]								;-- optional custom event handler
	init-proc	 [init-proc!]
]

max-ext-styles: 	20
ext-classes:		as ext-class! allocate max-ext-styles * size? ext-class!
ext-cls-tail:		ext-classes							;-- tail pointer

find-class: func [
	name	[red-word!]
	return: [ext-class!]
	/local
		sym [integer!]
		p	[ext-class!]
][
	sym: symbol/resolve name/symbol
	p: ext-classes
	while [p < ext-cls-tail][
		if p/symbol = sym [return p]
		p: p + 1
	]
	null
]

register-class: func [
	[typed]
	count	[integer!]
	list	[typed-value!]
	/local
		p		[ext-class!]
		flags	[integer!]
		arg1 arg2 arg3 arg4 arg6 [int-ptr!]
		arg5	[integer!]
][
	if count <> 6 [print-line "gui/register-class error: invalid spec block"]

	arg1: typed-value-as-pointer list	;-- Red-level style name (c-string!)
	list: list + 1
	arg2: typed-value-as-pointer list	;-- new class name (c-string!)
	list: list + 1
	arg3: typed-value-as-pointer list	;-- parent class name (c-string!)
	list: list + 1
	arg4: typed-value-as-pointer list	;-- add-method! function (function!)
	list: list + 1
	arg5: typed-value-as-integer list	;-- store extra data? (logic!)
	list: list + 1
	arg6: typed-value-as-pointer list	;-- init-view! function (function!)

	if any [null? arg2 null? arg3][
		print-line "gui/register-class error: class name cannot be null"
		exit
	]

	flags: either zero? arg5 [STORE_FACE_FLAG][STORE_FACE_FLAG or EXTRA_DATA_FLAG]

	make-super-class
		as-c-string arg2
		as-c-string arg3
		arg4
		flags

	p: ext-cls-tail
	ext-cls-tail: ext-cls-tail + 1
	assert ext-classes + max-ext-styles > ext-cls-tail

	p/symbol:		symbol/make as-c-string arg1
	p/class:		as-c-string arg2
	p/parent-class:	as-c-string arg3
	p/new-proc:		arg4
	p/init-proc:	as init-proc! arg6
]

register-classes: does [
	make-super-class "RedApplication"	"NSApplication"			as int-ptr! :add-app-handler		0
	make-super-class "RedAppDelegate"	"NSObject"				as int-ptr! :add-app-delegate	0
	make-super-class "RedPanelDelegate"	"NSObject"				as int-ptr! :add-panel-delegate	0
	make-super-class "NSViewFlip"		"NSView"				as int-ptr! :flip-coord			0
	make-super-class "RedView"			"NSView"				as int-ptr! :add-content-view-handler STORE_FACE_FLAG or EXTRA_DATA_FLAG
	make-super-class "RedBase"			"NSView"				as int-ptr! :add-base-handler	STORE_FACE_FLAG or EXTRA_DATA_FLAG
	make-super-class "RedWindow"		"NSWindow"				as int-ptr! :add-window-handler	STORE_FACE_FLAG
	make-super-class "RedButton"		"NSButton"				as int-ptr! :add-button-handler	STORE_FACE_FLAG
	make-super-class "RedSlider"		"NSSlider"				as int-ptr! :add-slider-handler	STORE_FACE_FLAG
	make-super-class "RedTextField"		"NSTextField"			as int-ptr! :add-text-field-handler STORE_FACE_FLAG
	make-super-class "RedSecureField"	"NSSecureTextField"		as int-ptr! :add-text-field-handler STORE_FACE_FLAG
	make-super-class "RedTextView"		"NSTextView"			as int-ptr! :add-area-handler STORE_FACE_FLAG
	make-super-class "RedComboBox"		"NSComboBox"			as int-ptr! :add-combo-box-handler STORE_FACE_FLAG
	make-super-class "RedPopUpButton"	"NSPopUpButton"			as int-ptr! :add-droplist-handler STORE_FACE_FLAG
	make-super-class "RedTableView"		"NSTableView"			as int-ptr! :add-table-view-handler STORE_FACE_FLAG
	make-super-class "RedCamera"		"NSView"				as int-ptr! :add-camera-handler STORE_FACE_FLAG
	make-super-class "RedCalendar"		"NSDatePicker"			as int-ptr! :add-calendar-handler STORE_FACE_FLAG
	make-super-class "RedTabView"		"NSTabView"				as int-ptr! :add-tabview-handler STORE_FACE_FLAG
	make-super-class "RedOpenPanel"		"NSOpenPanel"			as int-ptr! :add-filedialog-handler EXTRA_DATA_FLAG
	make-super-class "RedSavePanel"		"NSSavePanel"			as int-ptr! :add-filedialog-handler EXTRA_DATA_FLAG
	make-super-class "RedScrollBase"	"NSScrollView"			as int-ptr! :add-scrollview-handler STORE_FACE_FLAG
	make-super-class "RedScrollView"	"NSScrollView"			null STORE_FACE_FLAG
	make-super-class "RedBox"			"NSBox"					null STORE_FACE_FLAG
	make-super-class "RedProgress"		"NSProgressIndicator"	null STORE_FACE_FLAG
	make-super-class "RedLayoutManager" "NSLayoutManager"		as int-ptr! :add-text-layout-handler 0
]
