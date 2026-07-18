Red/System [
	Title:	"Cocoa imports"
	Author: "Qingtian Xie"
	File: 	%cocoa.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#either ABI = 'apple-aarch64 [
	#define Cocoa-handle! int64!
	#define Cocoa-uhandle! uint64!
	#define Cocoa-handle-ptr! [pointer! [int64!]]
	#define Cocoa-float! float!
	#define Cocoa-float-ptr! [pointer! [float!]]
	#define NSInteger! int64!
	#define NSUInteger! uint64!
	#define COCOA_TO_F32(value) [as float32! value]
	#define F32_TO_COCOA [as float!]
][
	#define Cocoa-handle! integer!
	#define Cocoa-uhandle! integer!
	#define Cocoa-handle-ptr! int-ptr!
	#define Cocoa-float! float32!
	#define Cocoa-float-ptr! float32-ptr!
	#define NSInteger! integer!
	#define NSUInteger! integer!
	#define COCOA_TO_F32(value) [value]
	#define F32_TO_COCOA []
]

#define NSNotFound					7FFFFFFFh			;@@ should be NSIntegerMax

#define OBJC_ASSOCIATION_ASSIGN		0
#define OBJC_ASSOCIATION_RETAIN		0301h
#define OBJC_ASSOCIATION_COPY		0303h

#define NSAnyEventMask				-1

#define NSUtilityWindowMask         16
#define NSDocModalWindowMask        32
#define NSBorderlessWindowMask      0
#define NSTitledWindowMask          1
#define NSClosableWindowMask        2
#define NSMiniaturizableWindowMask  4
#define NSResizableWindowMask       8
#define NSIconWindowMask            64
#define NSMiniWindowMask            128

#define NSAlphaShiftKeyMask			65536
#define NSShiftKeyMask				131072
#define NSControlKeyMask			262144
#define NSAlternateKeyMask			524288
#define NSCommandKeyMask			1048576
#define NSNumericPadKeyMask			2097152
#define NSHelpKeyMask				4194304
#define NSFunctionKeyMask			8388608
#define NSDeviceIndependentModifierFlagsMask FFFF0000h

#define NSViewNotSizable			0
#define NSViewMinXMargin			1
#define NSViewWidthSizable			2
#define NSViewMaxXMargin			4
#define NSViewMinYMargin			8
#define NSViewHeightSizable			16
#define NSViewMaxYMargin			32

#define NSRoundedBezelStyle			1
#define NSRegularSquareBezelStyle	2

#define NSPushOnPushOffButton		1
#define NSSwitchButton				3
#define NSRadioButton				4

#define NSNoBorder					0
#define NSLineBorder				1
#define NSBezelBorder				2
#define NSGrooveBorder				3

#define NSNoTitle					0
#define NSAboveTop					1
#define NSAtTop						2
#define NSBelowTop					3
#define NSAboveBottom				4
#define NSAtBottom					5
#define NSBelowBottom				6

#define NSMixedState				-1
#define NSOffState					0
#define NSOnState					1

#define NSLeftMouseDown				1
#define NSLeftMouseUp				2
#define NSRightMouseDown			3
#define NSRightMouseUp				4
#define NSMouseMoved				5
#define NSLeftMouseDragged			6
#define NSRightMouseDragged			7
#define NSMouseEntered				8
#define NSMouseExited				9
#define NSKeyDown					10
#define NSKeyUp						11
#define NSFlagsChanged				12
#define NSAppKitDefined				13
#define NSSystemDefined				14
#define NSApplicationDefined		15
#define NSPeriodic					16
#define NSCursorUpdate				17
#define NSScrollWheel				22
#define NSTabletPoint				23
#define NSTabletProximity			24
#define NSOtherMouseDown			25
#define NSOtherMouseUp				26
#define NSOtherMouseDragged			27
#define NSEventTypeGesture			29
#define NSEventTypeMagnify			30
#define NSEventTypeSwipe			31
#define NSEventTypeRotate			18
#define NSEventTypeBeginGesture		19
#define NSEventTypeEndGesture		20
#define NSEventTypeSmartMagnify		32
#define NSEventTypeQuickLook		33
#define NSEventTypePressure			34

#define NSLeftMouseDownMask			2
#define NSLeftMouseUpMask			4
#define NSMouseMovedMask			32
#define NSLeftMouseDraggedMask		64

#define NSItalicFontMask			1
#define NSBoldFontMask				2
#define NSFixedPitchFontMask		0400h

#define NSFontMonoSpaceTrait		1024

#define NSTrackingMouseEnteredAndExited		1
#define NSTrackingMouseMoved				2
#define NSTrackingCursorUpdate				4
#define NSTrackingActiveWhenFirstResponder	16
#define NSTrackingActiveInKeyWindow			32
#define NSTrackingActiveInActiveApp			64
#define NSTrackingActiveAlways				128
#define NSTrackingAssumeInside				256
#define NSTrackingInVisibleRect				512
#define NSTrackingEnabledDuringMouseDrag	1024

#define NSDatePickerModeSingle				0
#define NSDatePickerStyleClockAndCalendar 	1
#define NSDatePickerElementFlagYearMonthDay 00E0h

#define NSCalendarUnitYear 			4
#define NSCalendarUnitMonth 		8
#define NSCalendarUnitDay 			16

#define kCGLineJoinMiter			0
#define kCGLineJoinRound			1
#define kCGLineJoinBevel			2

#define kCGLineCapButt				0
#define kCGLineCapRound				1
#define kCGLineCapSquare			2

#define kCGPathFill					0
#define kCGPathEOFill				1
#define kCGPathStroke				2
#define kCGPathFillStroke			3
#define kCGPathEOFillStroke			4

#define NSTextAlignmentLeft			0
#define NSTextAlignmentRight		1
#define NSTextAlignmentCenter		2

#define NSASCIIStringEncoding		1
#define NSUTF8StringEncoding		4
#define NSISOLatin1StringEncoding	5
#define NSWindowsCP1251StringEncoding	11
#define NSWindowsCP1252StringEncoding	12
#define NSWindowsCP1250StringEncoding	15
#define NSUTF16LittleEndianStringEncoding	94000100h

#define IVAR_RED_FACE		"red-face"		;-- struct! 16 bytes, for storing red face object
#define IVAR_RED_DATA		"red-data"		;-- integer! 4 bytes, for storing extra red data
#define IVAR_RED_DRAW_CTX	"red-draw-ctx"	;-- pointer! 4 bytes, for storing draw-ctx!
#define NSString(cStr) [objc_msgSend [objc_getClass "NSString" sel_getUid "stringWithUTF8String:" cStr]] 

#define RedNSEventKey			4000FFF0h
#define RedCameraSessionKey		4000FFF1h
#define RedCameraDevicesKey		4000FFF2h
#define RedCameraDevInputKey	4000FFF3h
#define RedCameraImageKey		4000FFF4h
#define RedSecureFieldKey		4000FFF5h
#define RedPairSizeKey			4000FFF6h
#define RedTimerKey				4000FFFAh
#define RedFieldEditorKey		4000FFFBh
#define RedAllOverFlagKey		4000FFFCh
#define RedAttachedWidgetKey	4000FFFDh
#define RedCursorKey			4000FFFEh
#define RedEnableKey			4000FFFFh

#define RedRichTextKey			4000FFF1h

#define QuitMsgData				12321

#define OBJC_ALLOC(class) [objc_msgSend [objc_getClass class sel_alloc]]

objc_super!: alias struct! [
	receiver	[Cocoa-handle!]
	superclass	[Cocoa-handle!]
]

NSRect!: alias struct! [
	x		[Cocoa-float!]
	y		[Cocoa-float!]
	w		[Cocoa-float!]
	h		[Cocoa-float!]
]

NSColor!: alias struct! [
	r		[Cocoa-float!]
	g		[Cocoa-float!]
	b		[Cocoa-float!]
	a		[Cocoa-float!]
]

NSSize!: alias struct! [
	w		[Cocoa-float!]
	h		[Cocoa-float!]
]

NSRange!: alias struct! [
	idx		[NSUInteger!]
	len		[NSUInteger!]
]

CGPoint!: alias struct! [
	x		[Cocoa-float!]
	y		[Cocoa-float!]
]

Cocoa-handle-array!: alias struct! [
	v1	[Cocoa-handle!]
	v2	[Cocoa-handle!]
	v3	[Cocoa-handle!]
	v4	[Cocoa-handle!]
	v5	[Cocoa-handle!]
]

CGPatternCallbacks!: alias struct! [
	version		[integer!]
	drawPattern [int-ptr!]
	releaseInfo [int-ptr!]
]

RECT_STRUCT: alias struct! [
	left		[integer!]
	top			[integer!]
	right		[integer!]
	bottom		[integer!]
]

tagPOINT: alias struct! [
	x		[integer!]
	y		[integer!]
]

tagSIZE: alias struct! [
	width	[integer!]
	height	[integer!]
]

#import [
	LIBC-file cdecl [
		strrchr: "strrchr" [
			str			[c-string!]
			c			[integer!]
			return:		[c-string!]
		]
		_NSConcreteStackBlock: "_NSConcreteStackBlock" [Cocoa-handle!]
		objc_getClass: "objc_getClass" [
			class		[c-string!]
			return:		[Cocoa-handle!]
		]
		objc_allocateClassPair: "objc_allocateClassPair" [
			superclass	[Cocoa-handle!]
			name		[c-string!]
			extraBytes	[Cocoa-uhandle!]
			return:		[Cocoa-handle!]
		]
		objc_registerClassPair: "objc_registerClassPair" [
			class		[Cocoa-handle!]
		]
		objc_setAssociatedObject: "objc_setAssociatedObject" [
			obj			[Cocoa-handle!]
			key			[Cocoa-handle!]
			value		[Cocoa-handle!]
			policy		[integer!]
		]
		objc_getAssociatedObject: "objc_getAssociatedObject" [
			obj			[Cocoa-handle!]
			key			[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		sel_getUid: "sel_getUid" [
			name		[c-string!]
			return:		[Cocoa-handle!]
		]
		;ivar_getOffset: "ivar_getOffset" [
		;	ivar		[integer!]
		;	return:		[integer!]
		;]
		;class_getInstanceVariable: "class_getInstanceVariable" [
		;	class		[integer!]
		;	name		[c-string!]
		;	return:		[integer!]
		;]
		class_addIvar: "class_addIvar" [
			class		[Cocoa-handle!]
			name		[c-string!]
			size		[Cocoa-uhandle!]
			alignment	[byte!]
			types		[c-string!]
			return:		[logic!]
		]
		class_addMethod: "class_addMethod" [
			class		[Cocoa-handle!]
			name		[Cocoa-handle!]
			implement	[int-ptr!]
			types		[c-string!]
			return:		[logic!]
		]
		class_replaceMethod: "class_replaceMethod" [
			class		[Cocoa-handle!]
			name		[Cocoa-handle!]
			implement	[int-ptr!]
			types		[c-string!]
			return:		[int-ptr!]
		]
		class_getSuperclass: "class_getSuperclass" [
			cls			[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		class_addProtocol: "class_addProtocol" [
			cls			[Cocoa-handle!]
			protocol	[Cocoa-handle!]
			return:		[logic!]
		]
		object_getClass: "object_getClass" [
			id			[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		object_setInstanceVariable: "object_setInstanceVariable" [
			id			[Cocoa-handle!]
			name		[c-string!]
			value		[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		object_getInstanceVariable: "object_getInstanceVariable" [
			id			[Cocoa-handle!]
			name		[c-string!]
			out			[Cocoa-handle-ptr!]
			return:		[Cocoa-handle!]
		]
		objc_getProtocol: "objc_getProtocol" [
			name		[c-string!]
			return:		[Cocoa-handle!]
		]
		objc_msgSend: "objc_msgSend" [[variadic objc] return: [Cocoa-handle!]]
		objc_msgSend_pt: "objc_msgSend" [[variadic objc] return: [CGPoint! value]]
		objc_msgSend_sz: "objc_msgSend" [[variadic objc] return: [NSSize! value]]
		objc_msgSend_range: "objc_msgSend" [[variadic objc] return: [NSRange! value]]
		objc_msgSendSuper: "objc_msgSendSuper" [
			[variadic objc]
			super		[objc_super!]
			selector	[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		#either ABI = 'apple-aarch64 [
			objc_msgSend_f32: "objc_msgSend" [[variadic objc] return: [Cocoa-float!]]
			objc_msgSend_fpret: "objc_msgSend" [[variadic objc] return: [float!]]
			objc_msgSend_rect: "objc_msgSend" [[variadic objc] return: [NSRect! value]]
		][
			objc_msgSend_f32: "objc_msgSend_fpret" [[variadic] return: [Cocoa-float!]]
			objc_msgSend_fpret: "objc_msgSend_fpret" [[variadic] return: [float!]]
			objc_msgSend_stret: "objc_msgSend_stret" [[custom]]
			objc_msgSend_rect: "objc_msgSend_stret" [[variadic] return: [NSRect! value]]
		]
		_Block_object_assign: "_Block_object_assign" [
			destAddr	[Cocoa-handle!]
			obj			[Cocoa-handle!]
			flags		[integer!]
		]
		_Block_object_dispose: "_Block_object_dispose" [
			obj			[Cocoa-handle!]
			flags		[integer!]
		]
	]
	"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
		kCFRunLoopDefaultMode: "kCFRunLoopDefaultMode" [Cocoa-handle!]
		CFAttributedStringCreate: "CFAttributedStringCreate" [
			allocator	[Cocoa-handle!]
			str			[Cocoa-handle!]
			attributes	[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		CFGetTypeID: "CFGetTypeID" [
			cf			[Cocoa-handle!]
			return:		[Cocoa-uhandle!]
		]
		CFNumberGetTypeID: "CFNumberGetTypeID" [
			return:		[Cocoa-uhandle!]
		]
		CFNumberGetValue: "CFNumberGetValue" [
			number		[Cocoa-handle!]
			theType		[integer!]
			valuePtr	[int-ptr!]
			return:		[logic!]
		]
		CFRunLoopGetCurrent: "CFRunLoopGetCurrent" [
			return:		[Cocoa-handle!]
		]
		;CFAttributedStringCreateMutable: "CFAttributedStringCreateMutable" [
		;	allocator	[integer!]
		;	max-length	[integer!]
		;	return:		[integer!]
		;]
		;CFAttributedStringReplaceString: "CFAttributedStringReplaceString" [
		;	aStr		[integer!]
		;	location	[integer!]			;-- CFRange -
		;	length		[integer!]			;-- CFRange -
		;	string		[integer!]			;-- CFString
		;]
		;CFAttributedStringSetAttribute: "CFAttributedStringSetAttribute" [
		;	aStr		[integer!]
		;	location	[integer!]
		;	length		[integer!]
		;	attrName	[integer!]
		;	value		[integer!]
		;]
		;CFAttributedStringGetLength: "CFAttributedStringGetLength" [
		;	aStr		[integer!]
		;	return:		[integer!]
		;]
		;CFAttributedStringBeginEditing: "CFAttributedStringBeginEditing" [
		;	aStr		[integer!]
		;]
		;CFAttributedStringEndEditing: "CFAttributedStringEndEditing" [
		;	aStr		[integer!]
		;]
		CFStringCreateWithCString: "CFStringCreateWithCString" [
			allocator	[Cocoa-handle!]
			cStr		[c-string!]
			encoding	[integer!]
			return:		[Cocoa-handle!]
		]
		CFNumberCreate: "CFNumberCreate" [
			allocator	[Cocoa-handle!]
			type		[integer!]
			valuePtr	[int-ptr!]
			return:		[Cocoa-handle!]
		]
		CFRelease: "CFRelease" [
			cf			[Cocoa-handle!]
		]
	]
	"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation" cdecl [
		NSStringFromClass: "NSStringFromClass" [
			class		[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
	]
	"/System/Library/Frameworks/AVFoundation.framework/AVFoundation" cdecl [
		AVMediaTypeVideo: "AVMediaTypeVideo" [Cocoa-handle!]
		AVVideoCodecKey: "AVVideoCodecKey" [Cocoa-handle!]
		AVVideoCodecJPEG: "AVVideoCodecJPEG" [Cocoa-handle!]
	]
	"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit" cdecl [
		NSBeep: "NSBeep" []
		NSDeviceResolution: "NSDeviceResolution" [Cocoa-handle!]
		NSDefaultRunLoopMode: "NSDefaultRunLoopMode" [Cocoa-handle!]
		NSModalPanelRunLoopMode: "NSModalPanelRunLoopMode" [Cocoa-handle!]
		NSFontAttributeName: "NSFontAttributeName" [Cocoa-handle!]
		NSParagraphStyleAttributeName: "NSParagraphStyleAttributeName" [Cocoa-handle!]
		NSForegroundColorAttributeName: "NSForegroundColorAttributeName" [Cocoa-handle!]
		NSBackgroundColorAttributeName: "NSBackgroundColorAttributeName" [Cocoa-handle!]
		NSUnderlineStyleAttributeName: "NSUnderlineStyleAttributeName" [Cocoa-handle!]
		NSStrikethroughStyleAttributeName: "NSStrikethroughStyleAttributeName" [Cocoa-handle!]
		NSMarkedClauseSegmentAttributeName: "NSMarkedClauseSegmentAttributeName" [Cocoa-handle!]
		NSGlyphInfoAttributeName: "NSGlyphInfoAttributeName" [Cocoa-handle!]
	]
	"/System/Library/Frameworks/CoreServices.framework/CoreServices" cdecl [
		Gestalt: "Gestalt" [
			selector	[integer!]
			response	[int-ptr!]
			return:		[integer!]
		]
	]
	"/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices" cdecl [
		CGWindowLevelForKey: "CGWindowLevelForKey" [
			key			[integer!]
			return:		[integer!]
		]
		CGWindowListCreateImage: "CGWindowListCreateImage" [
			bounds		[NSRect! value]
			listOption	[integer!]
			windowID	[integer!]
			imageOption [integer!]
			return:		[Cocoa-handle!]
		]
		CTLineCreateWithAttributedString: "CTLineCreateWithAttributedString" [
			aStr		[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		CTLineDraw: "CTLineDraw" [
			line		[Cocoa-handle!]
			c			[handle!]
		]
		CGRectContainsPoint: "CGRectContainsPoint" [
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
			x1			[Cocoa-float!]
			y1			[Cocoa-float!]
			return:		[logic!]
		]
		CGColorSpaceCreatePattern: "CGColorSpaceCreatePattern" [
			baseSpace	[Cocoa-handle!]
			return:		[Cocoa-handle!]
		]
		CGColorSpaceCreateDeviceRGB: "CGColorSpaceCreateDeviceRGB" [
			return:		[Cocoa-handle!]
		]
		CGContextSetFillColorSpace: "CGContextSetFillColorSpace" [
			ctx			[handle!]
			space		[Cocoa-handle!]
		]
		CGColorSpaceRelease: "CGColorSpaceRelease" [
			colorspace	[Cocoa-handle!]
		]
		CGGradientCreateWithColorComponents: "CGGradientCreateWithColorComponents" [
			colorspace	[Cocoa-handle!]
			components	[Cocoa-float-ptr!]
			locations	[Cocoa-float-ptr!]
			nlocations	[integer!]
			return:		[Cocoa-handle!]
		]
		CGGradientRelease: "CGGradientRelease" [
			gradient	[Cocoa-handle!]
		]
		CGContextDrawLinearGradient: "CGContextDrawLinearGradient" [
			ctx			[handle!]
			gradient	[Cocoa-handle!]
			start-x		[Cocoa-float!]
			start-y		[Cocoa-float!]
			end-x		[Cocoa-float!]
			end-y		[Cocoa-float!]
			options		[integer!]
		]
		CGContextDrawRadialGradient: "CGContextDrawRadialGradient" [
			ctx			[handle!]
			gradient	[Cocoa-handle!]
			start-x		[Cocoa-float!]
			start-y		[Cocoa-float!]
			start-r		[Cocoa-float!]
			end-x		[Cocoa-float!]
			end-y		[Cocoa-float!]
			end-r		[Cocoa-float!]
			options		[integer!]
		]
		CGContextSaveGState: "CGContextSaveGState" [
			c			[handle!]
		]
		CGContextRestoreGState: "CGContextRestoreGState" [
			c			[handle!]
		]
		CGContextSetTextPosition: "CGContextSetTextPosition" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextSetRGBStrokeColor: "CGContextSetRGBStrokeColor" [
			c			[handle!]
			red			[Cocoa-float!]
			green		[Cocoa-float!]
			blue		[Cocoa-float!]
			alpha		[Cocoa-float!]
		]
		CGContextSetRGBFillColor: "CGContextSetRGBFillColor" [
			c			[handle!]
			red			[Cocoa-float!]
			green		[Cocoa-float!]
			blue		[Cocoa-float!]
			alpha		[Cocoa-float!]
		]
		CGContextStrokeRect: "CGContextStrokeRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextFillRect: "CGContextFillRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextFillEllipseInRect: "CGContextFillEllipseInRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextStrokeEllipseInRect: "CGContextStrokeEllipseInRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextAddEllipseInRect: "CGContextAddEllipseInRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextSetLineWidth: "CGContextSetLineWidth" [
			c			[handle!]
			width		[Cocoa-float!]
		]
		CGContextSetLineJoin: "CGContextSetLineJoin" [
			c			[handle!]
			join		[integer!]
		]
		CGContextSetLineCap: "CGContextSetLineCap" [
			c			[handle!]
			cap			[integer!]
		]
		CGContextSetLineDash: "CGContextSetLineDash" [
			c			[handle!]
			phase		[Cocoa-float!]
			lengths		[Cocoa-float-ptr!]
			count		[integer!]
		]
		CGContextSetAllowsAntialiasing: "CGContextSetAllowsAntialiasing" [
			c			[handle!]
			anti-alias? [logic!]
		]
		CGContextSetAllowsFontSmoothing: "CGContextSetAllowsFontSmoothing" [
			c			[handle!]
			smooth?		[logic!]
		]
		CGContextSetMiterLimit: "CGContextSetMiterLimit" [
			c			[handle!]
			limit		[Cocoa-float!]
		]
		CGContextBeginPath: "CGContextBeginPath" [
			c			[handle!]
		]
		CGContextClosePath: "CGContextClosePath" [
			c			[handle!]
		]
		CGContextCopyPath: "CGContextCopyPath" [
			ctx			[handle!]
			return:		[Cocoa-handle!]
		]
		CGContextAddPath: "CGContextAddPath" [
			ctx			[handle!]
			path		[Cocoa-handle!]
		]
		CGContextClip: "CGContextClip" [
			c			[handle!]
		]
		CGContextMoveToPoint: "CGContextMoveToPoint" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextAddLineToPoint: "CGContextAddLineToPoint" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextAddCurveToPoint: "CGContextAddCurveToPoint" [
			c			[handle!]
			cp1x		[Cocoa-float!]
			cp1y		[Cocoa-float!]
			cp2x		[Cocoa-float!]
			cp2y		[Cocoa-float!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextAddQuadCurveToPoint: "CGContextAddQuadCurveToPoint" [
			c			[handle!]
			cp1x		[Cocoa-float!]
			cp1y		[Cocoa-float!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextAddLines: "CGContextAddLines" [
			c			[handle!]
			points		[CGPoint!]
			count		[integer!]
		]
		CGContextAddArc: "CGContextAddArc" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			radius		[Cocoa-float!]
			startAngle	[Cocoa-float!]
			endAngle	[Cocoa-float!]
			clockwise	[integer!]
		]
		CGContextAddArcToPoint: "CGContextAddArcToPoint" [
			c			[handle!]
			x1			[Cocoa-float!]
			y1			[Cocoa-float!]
			x2			[Cocoa-float!]
			y2			[Cocoa-float!]
			radius		[Cocoa-float!]
		]
		CGContextAddRect: "CGContextAddRect" [
			c			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			width		[Cocoa-float!]
			height		[Cocoa-float!]
		]
		CGContextStrokePath: "CGContextStrokePath" [
			c			[handle!]
		]
		CGContextDrawPath: "CGContextDrawPath" [
			c			[handle!]
			mode		[integer!]
		]
		CGContextSetStrokePattern: "CGContextSetStrokePattern" [
			ctx			[handle!]
			pattern		[Cocoa-handle!]
			components	[Cocoa-float-ptr!]
		]
		CGContextSetFillPattern: "CGContextSetFillPattern" [
			ctx			[handle!]
			pattern		[Cocoa-handle!]
			components	[Cocoa-float-ptr!]
		]
		CGPatternCreate: "CGPatternCreate" [
			info		[int-ptr!]
			rc			[NSRect! value]
			matrix		[CGAffineTransform! value]
			xStep		[Cocoa-float!]
			yStep		[Cocoa-float!]
			tiling		[integer!]
			isColored	[logic!]
			callbacks	[CGPatternCallbacks!]
			return:		[Cocoa-handle!]
		]
		CGPatternRelease: "CGPatternRelease" [
			pattern		[Cocoa-handle!]
		]
		CGContextConcatCTM: "CGContextConcatCTM" [
			ctx			[handle!]
			m			[CGAffineTransform! value]
		]
		CGContextSetCTM: "CGContextSetCTM" [
			ctx			[handle!]
			m			[CGAffineTransform! value]
		]
		CGContextGetCTM: "CGContextGetCTM" [
			ctx			[handle!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformInvert: "CGAffineTransformInvert" [
			matrix		[CGAffineTransform! value]
			return:		[CGAffineTransform! value]
		]
		CGContextRotateCTM: "CGContextRotateCTM" [
			c			[handle!]
			angle		[Cocoa-float!]
		]
		CGContextScaleCTM: "CGContextScaleCTM" [
			c			[handle!]
			sx			[Cocoa-float!]
			sy			[Cocoa-float!]
		]
		CGContextTranslateCTM: "CGContextTranslateCTM" [
			c			[handle!]
			tx			[Cocoa-float!]
			ty			[Cocoa-float!]
		]
		CGContextSetTextMatrix: "CGContextSetTextMatrix" [
			ctx			[handle!]
			a			[Cocoa-float!]
			b			[Cocoa-float!]
			c			[Cocoa-float!]
			d			[Cocoa-float!]
			tx			[Cocoa-float!]
			ty			[Cocoa-float!]
		]
		CGContextGetPathBoundingBox: "CGContextGetPathBoundingBox" [
			ctx			[handle!]
			return:		[NSRect! value]
		]
		CGAffineTransformMake: "CGAffineTransformMake" [
			a			[Cocoa-float!]
			b			[Cocoa-float!]
			c			[Cocoa-float!]
			d			[Cocoa-float!]
			tx			[Cocoa-float!]
			ty			[Cocoa-float!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformMakeScale: "CGAffineTransformMakeScale" [
			sx			[Cocoa-float!]
			sy			[Cocoa-float!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformMakeTranslation: "CGAffineTransformMakeTranslation" [
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			return:		[CGAffineTransform! value]
		]
		CGPointApplyAffineTransform: "CGPointApplyAffineTransform" [
			pt			[CGPoint! value]
			m			[CGAffineTransform! value]
			return:		[CGPoint! value]
		]
		CGAffineTransformConcat: "CGAffineTransformConcat" [
			m1			[CGAffineTransform! value]
			m2			[CGAffineTransform! value]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformRotate: "CGAffineTransformRotate" [
			m			[CGAffineTransform! value]
			angle		[Cocoa-float!]						;-- angle in radians
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformTranslate: "CGAffineTransformTranslate" [
			m			[CGAffineTransform! value]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformScale: "CGAffineTransformScale" [
			m			[CGAffineTransform! value]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			return:		[CGAffineTransform! value]
		]
		CGPathCreateMutable: "CGPathCreateMutable" [
			return:		[Cocoa-handle!]
		]
		CGPathRelease: "CGPathRelease" [
			path		[Cocoa-handle!]
		]
		CGPathCloseSubpath: "CGPathCloseSubpath" [
			path		[Cocoa-handle!]
		]
		CGPathMoveToPoint: "CGPathMoveToPoint" [
			path		[Cocoa-handle!]
			m			[CGAffineTransform!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGPathAddLineToPoint: "CGPathAddLineToPoint" [
			path		[Cocoa-handle!]
			m			[CGAffineTransform!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGPathAddRelativeArc: "CGPathAddRelativeArc" [
			path		[Cocoa-handle!]
			m			[CGAffineTransform!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			radius		[Cocoa-float!]
			startAngle	[Cocoa-float!]
			delta		[Cocoa-float!]
		]
		CGPathAddCurveToPoint: "CGPathAddCurveToPoint" [
			path		[Cocoa-handle!]
			m			[CGAffineTransform!]
			cp1x		[Cocoa-float!]
			cp1y		[Cocoa-float!]
			cp2x		[Cocoa-float!]
			cp2y		[Cocoa-float!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGPathAddQuadCurveToPoint: "CGPathAddQuadCurveToPoint" [
			path		[Cocoa-handle!]
			m			[CGAffineTransform!]
			cp1x		[Cocoa-float!]
			cp1y		[Cocoa-float!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
		]
		CGContextDrawImage: "CGContextDrawImage" [
			ctx			[handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			w			[Cocoa-float!]
			h			[Cocoa-float!]
			src			[Cocoa-handle!]
		]
		CGImageCreateWithImageInRect: "CGImageCreateWithImageInRect" [
			image		[Cocoa-handle!]
			x			[Cocoa-float!]
			y			[Cocoa-float!]
			w			[Cocoa-float!]
			h			[Cocoa-float!]
			return:		[Cocoa-handle!]
		]
		CGBitmapContextCreateImage: "CGBitmapContextCreateImage" [
			ctx			[handle!]
			return:		[Cocoa-handle!]
		]
		CGImageRelease: "CGImageRelease" [
			image		[Cocoa-handle!]
		]
	]
	LIBM-file cdecl [
		dlopen:	"dlopen" [
			dllpath		[c-string!]
			flags		[integer!]
			return:		[Cocoa-handle!]
		]
	]
]

#define BLOCK_FIELD_IS_OBJECT	3

make-NSDictionary: func [
	objects	[Cocoa-handle-array!]
	keys		[Cocoa-handle-array!]
	count	[NSUInteger!]
	return: [Cocoa-handle!]
	/local
		dict [Cocoa-handle!]
][
	dict: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
	objc_msgSend [
		dict sel_getUid "initWithObjects:forKeys:count:"
		as Cocoa-handle-ptr! objects
		as Cocoa-handle-ptr! keys
		count
	]
]

;-- https://opensource.apple.com/source/libclosure/libclosure-38/BlockImplementation.txt
objc_block_descriptor: declare struct! [
	reserved		[Cocoa-uhandle!]
	size			[Cocoa-uhandle!]
	copy_helper		[function! [dst [int-ptr!] src [int-ptr!]]]
	dispose_helper	[function! [src [int-ptr!]]]
]

block_literal!: alias struct! [
	isa			[Cocoa-handle!]
	flags		[integer!]
	reserved	[integer!]
	invoke		[int-ptr!]
	descriptor	[int-ptr!]
	value		[int-ptr!]
]

get-super-obj: func [
	id		[Cocoa-handle!]
	return: [objc_super!]
	/local
		super [objc_super! value]
][
	super/receiver: id
	super/superclass: objc_msgSend [id sel_getUid "superclass"]
	super
]

msg-send-super-logic: func [
	id		[Cocoa-handle!]
	sel		[Cocoa-handle!]
	return: [logic!]
	/local
		super [objc_super! value]
][
	super/receiver: id
	super/superclass: objc_msgSend [id sel_getUid "superclass"]
	as logic! objc_msgSendSuper [super sel]
]

msg-send-super: func [
	id		[Cocoa-handle!]
	sel		[Cocoa-handle!]
	arg		[Cocoa-handle!]
	return: [Cocoa-handle!]
	/local
		super [objc_super! value]
		cls   [Cocoa-handle!]
		result [Cocoa-handle!]
][
	cls: objc_msgSend [id sel_getUid "superclass"]
	result: as Cocoa-handle! 0
	if cls <> nsview-id [
		super/receiver: id
		super/superclass: cls
		result: objc_msgSendSuper [super sel arg]
	]
	result
]

to-red-string: func [
	nsstr	[Cocoa-handle!]
	slot	[red-value!]
	return: [red-string!]
	/local
		str  [red-string!]
		size [integer!]
		cstr [c-string!]
][
	size: as integer! objc_msgSend [nsstr sel_getUid "lengthOfBytesUsingEncoding:" NSUTF8StringEncoding]
	cstr: as c-string! objc_msgSend [nsstr sel_getUid "UTF8String"]
	if null? slot [slot: stack/push*]
	str: string/make-at slot size Latin1
	unicode/load-utf8-stream cstr size str null
	str
]

to-NSString: func [str [red-string!] return: [Cocoa-handle!] /local len][
	len: -1
	objc_msgSend [
		objc_getClass "NSString"
		sel_getUid "stringWithUTF8String:"
		unicode/to-utf8 str :len
	]
]

to-CFString: func [str [red-string!] return: [Cocoa-handle!] /local len][
	len: -1
	CFStringCreateWithCString 0 unicode/to-utf8 str :len kCFStringEncodingUTF8
]

rs-to-NSColor: func [
	clr		[integer!]
	return: [Cocoa-handle!]
	/local
		c	[NSColor!]
][
	c: declare NSColor!
	c/r: (as Cocoa-float! clr and FFh) / 255.0
	c/g: (as Cocoa-float! clr >> 8 and FFh) / 255.0
	c/b: (as Cocoa-float! clr >> 16 and FFh) / 255.0
	c/a: (as Cocoa-float! 255 - (clr >>> 24)) / 255.0

	objc_msgSend [
		objc_getClass "NSColor"
		sel_getUid "colorWithDeviceRed:green:blue:alpha:"
		c/r c/g c/b c/a
	]
]

to-NSColor: func [
	color	[red-tuple!]
	return: [Cocoa-handle!]
][
	if TYPE_OF(color) <> TYPE_TUPLE [return as Cocoa-handle! 0]
	rs-to-NSColor get-tuple-color color
]

make-CGMatrix: func [
	a		[integer!]
	b		[integer!]
	c		[integer!]
	d		[integer!]
	tx		[integer!]
	ty		[integer!]
	return: [CGAffineTransform!]
	/local
		m	[CGAffineTransform!]
][
	m: declare CGAffineTransform!
	m/a: as Cocoa-float! a
	m/b: as Cocoa-float! b
	m/c: as Cocoa-float! c
	m/d: as Cocoa-float! d
	m/tx: as Cocoa-float! tx
	m/ty: as Cocoa-float! ty
	m
]
