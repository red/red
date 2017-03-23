Red/System [
	Title:	"Windows classes handling"
	Author: "Qingtian Xie"
	File: 	%classes.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
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

add-method!: alias function! [class [integer!]]

add-base-handler: func [class [integer!]][
	flipp-coord class
	class_addMethod class sel_getUid "drawRect:" as-integer :draw-rect "v@:{_NSRect=ffff}"
	class_addMethod class sel_getUid "red-menu-action:" as-integer :red-menu-action "v@:@"
	class_addMethod class sel_getUid "acceptsFirstResponder" as-integer :accepts-first-responder "B@:"
	class_addMethod class sel_getUid "scrollWheel:" as-integer :scroll-wheel "@:@"

	class_addMethod class sel_getUid "keyDown:" as-integer :key-down-base "v@:@"
	class_addMethod class sel_getUid "insertText:" as-integer :insert-text "v@:@"
	class_addMethod class sel_getUid "hasMarkedText" as-integer :has-marked-text "B@:"
	class_addMethod class sel_getUid "markedRange" as-integer :marked-range "{_NSRange=ii}@:"
	class_addMethod class sel_getUid "selectedRange" as-integer :selected-range "{_NSRange=ii}@:"
	class_addMethod class sel_getUid "setMarkedText:selectedRange:replacementRange:" as-integer :set-marked-text "v@:@{_NSRange=ii}{_NSRange=ii}"
	class_addMethod class sel_getUid "unmarkText" as-integer :unmark-text "v@:"
	class_addMethod class sel_getUid "validAttributesForMarkedText" as-integer :valid-attrs-marked-text "@@:"
	class_addMethod class sel_getUid "attributedSubstringForProposedRange:actualRange:" as-integer :attr-str-range "@@:{_NSRange=ii}^{_NSRange=ii}"
	class_addMethod class sel_getUid "insertText:replacementRange:" as-integer :insert-text-range "v@:@{_NSRange=ii}"
	class_addMethod class sel_getUid "characterIndexForPoint:" as-integer :char-idx-point "I@:{_NSPoint=ff}"
	class_addMethod class sel_getUid "firstRectForCharacterRange:actualRange:" as-integer :first-rect-range "{_NSRect=ffff}@:{_NSRange=ii}^{_NSRange=ii}"
	class_addMethod class sel_getUid "doCommandBySelector:" as-integer :do-cmd-selector "v@::"
	class_addMethod class sel_getUid "windowLevel" as-integer :win-level "i@:"
]

add-scrollview-handler: func [class [integer!]][
	class_addMethod class sel_getUid "setNeedsDisplay:" as-integer :refresh-scrollview "v@:B"
	class_addMethod class sel_getUid "_doScroller:" as-integer :scroller-change "v@:@"
	class_addMethod class sel_getUid "reflectScrolledClipView:" as-integer :empty-func "@:@"
]

win-add-subview: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	view	[integer!]
][
	objc_msgSend [
		objc_msgSend [self sel_getUid "contentView"]
		sel_getUid "addSubview:" view
	]
]

win-convert-point: func [
	[cdecl]
	self	[integer!]
	cmd		[integer!]
	x		[integer!]
	y		[integer!]
	view	[integer!]
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

add-window-handler: func [class [integer!]][
	class_addMethod class sel_getUid "windowWillClose:" as-integer :win-will-close "v12@0:4@8"
	class_addMethod class sel_getUid "windowShouldClose:" as-integer :win-should-close "B@:@"
	class_addMethod class sel_getUid "windowDidMove:" as-integer :win-did-move "v12@0:4@8"
	class_addMethod class sel_getUid "windowDidResize:" as-integer :win-did-resize "v12@0:4@8"
	class_addMethod class sel_getUid "windowWillReturnFieldEditor:toObject:" as-integer :return-field-editor "@@:@@"
	class_addMethod class sel_getUid "windowDidEndLiveResize:" as-integer :win-live-resize "v12@0:4@8"
	;class_addMethod class sel_getUid "windowWillResize:toSize:" as-integer :win-will-resize "{_NSSize=ff}20@0:4@8{_NSSize=ff}12"
	class_addMethod class sel_getUid "red-menu-action:" as-integer :red-menu-action "v@:@"
	class_addMethod class sel_getUid "sendEvent:" as-integer :win-send-event "@:@"
	class_addMethod class sel_getUid "addSubview:" as-integer :win-add-subview "v12@0:4@8"
	class_addMethod class sel_getUid "convertPoint:fromView:" as-integer :win-convert-point "{_NSPoint=ff}20@0:4{_NSPoint=ff}8@16"
]

add-button-handler: func [class [integer!]][
	class_replaceMethod class sel_getUid "mouseDown:" as-integer :button-mouse-down "v@:@"
]

add-slider-handler: func [class [integer!]][
	class_addMethod class sel_getUid "slider-change:" as-integer :slider-change "v@:@"
]

add-text-field-handler: func [class [integer!]][
	class_addMethod class sel_getUid "textDidChange:" as-integer :text-did-change "v@:@"
	class_addMethod class sel_getUid "textDidEndEditing:" as-integer :text-did-end-editing "v@:@"
	class_addMethod class sel_getUid "becomeFirstResponder" as-integer :become-first-responder "B@:"
	class_addMethod class sel_getUid "performKeyEquivalent:" as-integer :perform-key-equivalent "B@:@"
]

add-area-handler: func [class [integer!]][
	add-text-field-handler class
	class_replaceMethod class sel_getUid "textDidChange:" as-integer :area-text-change "v@:@"
	class_replaceMethod class sel_getUid "textDidEndEditing:" as-integer :area-did-end-editing "v@:@"
]

add-combo-box-handler: func [class [integer!]][
	add-text-field-handler class
	class_addMethod class sel_getUid "comboBoxSelectionDidChange:" as-integer :selection-change "v@:@"
]

add-table-view-handler: func [class [integer!]][
	class_addMethod class sel_getUid "numberOfRowsInTableView:" as-integer :number-of-rows "l@:@"
	class_addMethod class sel_getUid "tableView:objectValueForTableColumn:row:" as-integer :object-for-table "@20@0:4@8@12l16"
	class_addMethod class sel_getUid "tableViewSelectionDidChange:" as-integer :table-select-did-change "v@:@"
	class_addMethod class sel_getUid "tableView:shouldEditTableColumn:row:" as-integer :table-cell-edit "B@:@@l"
]

add-camera-handler: func [class [integer!]][
	0
]

add-tabview-handler: func [class [integer!]][
	class_addMethod class sel_getUid "tabView:shouldSelectTabViewItem:" as-integer :tabview-should-select "B@:@@"
]

add-filedialog-handler: func [class [integer!]][
	class_addMethod class sel_getUid "filter-filetype:" as-integer :filter-filetype-action "v@:@"
]

add-text-layout-handler: func [class [integer!]][
	class_addMethod class sel_getUid "layoutManager:lineSpacingAfterGlyphAtIndex:withProposedLineFragmentRect:" as-integer :set-line-spacing "f@:@I{_NSRect=ffff}"
]

add-app-delegate: func [class [integer!]][
	class_addMethod class sel_getUid "applicationWillFinishLaunching:" as-integer :will-finish "v12@0:4@8"
	class_addMethod class sel_getUid "applicationShouldTerminateAfterLastWindowClosed:" as-integer :destroy-app "B12@0:4@8"
]

add-panel-delegate: func [class [integer!]][
	class_addMethod class sel_changeFont as-integer :dialog-proc "v@:@"
	class_addMethod class sel_windowWillClose as-integer :dialog-proc "v@:@"
]

flipp-coord: func [class [integer!]][
	class_addMethod class sel_getUid "isFlipped" as-integer :is-flipped "B@:"
]

make-super-class: func [
	new		[c-string!]
	base	[c-string!]
	method	[integer!]				;-- override functions or add functions
	flags	[integer!]
	return:	[integer!]
	/local
		new-class	[integer!]
		add-method	[add-method!]
][
	new-class: objc_allocateClassPair objc_getClass base new 0
	if flags and EXTRA_DATA_FLAG <> 0 [
		class_addIvar new-class IVAR_RED_DATA 4 2 "i"
	]
	if flags and STORE_FACE_FLAG <> 0 [
		class_addIvar new-class IVAR_RED_FACE 16 2 "{red-face=iiii}"
		class_addMethod new-class sel-on-timer as-integer :red-timer-action "v@:@"
		class_addMethod new-class sel_getUid "mouseEntered:" as-integer :mouse-entered "v@:@"
		class_addMethod new-class sel_getUid "mouseExited:" as-integer :mouse-exited "v@:@"
		class_addMethod new-class sel_getUid "mouseMoved:" as-integer :mouse-moved "v@:@"
		class_addMethod new-class sel_getUid "mouseDown:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "mouseUp:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "mouseDragged:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseDown:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseUp:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "rightMouseDragged:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseDown:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseUp:" as-integer :mouse-events "v@:@"
		class_addMethod new-class sel_getUid "otherMouseDragged:" as-integer :mouse-events "v@:@"

		class_addMethod new-class sel_getUid "keyUp:" as-integer :on-key-up "v@:@"
	]
	unless zero? method [
		add-method: as add-method! method
		add-method new-class
	]
	if all [new/4 = #"B" new/5 = #"a" new/6 = #"s" new/7 = #"e"][
		class_addProtocol new-class objc_getProtocol "NSTextInputClient"
	]
	objc_registerClassPair new-class
]

register-classes: does [
	make-super-class "RedAppDelegate"	"NSObject"				as-integer :add-app-delegate	0
	make-super-class "RedPanelDelegate"	"NSObject"				as-integer :add-panel-delegate	0
	make-super-class "RedView"			"NSView"				as-integer :flipp-coord			0
	make-super-class "RedBase"			"NSView"				as-integer :add-base-handler	STORE_FACE_FLAG or EXTRA_DATA_FLAG
	make-super-class "RedWindow"		"NSWindow"				as-integer :add-window-handler	STORE_FACE_FLAG
	make-super-class "RedButton"		"NSButton"				as-integer :add-button-handler	STORE_FACE_FLAG
	make-super-class "RedSlider"		"NSSlider"				as-integer :add-slider-handler	STORE_FACE_FLAG
	make-super-class "RedTextField"		"NSTextField"			as-integer :add-text-field-handler STORE_FACE_FLAG
	make-super-class "RedTextView"		"NSTextView"			as-integer :add-area-handler STORE_FACE_FLAG
	make-super-class "RedComboBox"		"NSComboBox"			as-integer :add-combo-box-handler STORE_FACE_FLAG
	make-super-class "RedTableView"		"NSTableView"			as-integer :add-table-view-handler STORE_FACE_FLAG
	make-super-class "RedCamera"		"NSView"				as-integer :add-camera-handler STORE_FACE_FLAG
	make-super-class "RedTabView"		"NSTabView"				as-integer :add-tabview-handler STORE_FACE_FLAG
	make-super-class "RedOpenPanel"		"NSOpenPanel"			as-integer :add-filedialog-handler EXTRA_DATA_FLAG
	make-super-class "RedSavePanel"		"NSSavePanel"			as-integer :add-filedialog-handler EXTRA_DATA_FLAG
	make-super-class "RedScrollBase"	"NSScrollView"			as-integer :add-scrollview-handler STORE_FACE_FLAG
	make-super-class "RedScrollView"	"NSScrollView"			0	STORE_FACE_FLAG
	make-super-class "RedBox"			"NSBox"					0	STORE_FACE_FLAG
	make-super-class "RedProgress"		"NSProgressIndicator"	0	STORE_FACE_FLAG
	make-super-class "RedLayoutManager" "NSLayoutManager"		as-integer :add-text-layout-handler 0
]
