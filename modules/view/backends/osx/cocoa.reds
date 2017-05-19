Red/System [
	Title:	"Cocoa imports"
	Author: "Qingtian Xie"
	File: 	%cocoa.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define NSNotFound					7FFFFFFFh			;@@ should be NSIntegerMax

#define OBJC_ASSOCIATION_ASSIGN		0
#define OBJC_ASSOCIATION_RETAIN		0301h
#define OBJC_ASSOCIATION_COPY		0303h

#define gestaltSystemVersion		1937339254			;-- "sysv"
#define gestaltSystemVersionMajor	1937339185			;-- "sys1"
#define gestaltSystemVersionMinor	1937339186			;-- "sys2"
#define gestaltSystemVersionBugFix	1937339187			;-- "sys3"

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

#define NSToggleButton				2
#define NSSwitchButton				3
#define NSRadioButton				4
#define NSMomentaryPushInButton		7

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

#define IVAR_RED_FACE	"red-face"				;-- struct! 16 bytes, for storing red face object
#define IVAR_RED_DATA	"red-data"				;-- integer! 4 bytes, for storing extra red data
#define NSString(cStr) [objc_msgSend [objc_getClass "NSString" sel_getUid "stringWithUTF8String:" cStr]] 

#define RedNSEventKey			4000FFF0h
#define RedCameraSessionKey		4000FFF1h
#define RedCameraDevicesKey		4000FFF2h
#define RedCameraDevInputKey	4000FFF3h
#define RedCameraImageKey		4000FFF4h
#define RedTimerKey				4000FFFAh
#define RedFieldEditorKey		4000FFFBh
#define RedAllOverFlagKey		4000FFFCh
#define RedAttachedWidgetKey	4000FFFDh


objc_super!: alias struct! [
	receiver	[integer!]
	superclass	[integer!]
]

NSRect!: alias struct! [
	x		[float32!]
	y		[float32!]
	w		[float32!]
	h		[float32!]
]

NSColor!: alias struct! [
	r		[float32!]
	g		[float32!]
	b		[float32!]
	a		[float32!]
]

NSSize!: alias struct! [
	w		[float32!]
	h		[float32!]
]

CGPoint!: alias struct! [
	x		[float32!]
	y		[float32!]
]

CGPatternCallbacks!: alias struct! [
	version		[integer!]
	drawPattern [integer!]
	releaseInfo [integer!]
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
		objc_getClass: "objc_getClass" [
			class		[c-string!]
			return:		[integer!]
		]
		objc_allocateClassPair: "objc_allocateClassPair" [
			superclass	[integer!]
			name		[c-string!]
			extraBytes	[integer!]
			return:		[integer!]
		]
		objc_registerClassPair: "objc_registerClassPair" [
			class		[integer!]
			return:		[integer!]
		]
		objc_setAssociatedObject: "objc_setAssociatedObject" [
			obj			[integer!]
			key			[integer!]
			value		[integer!]
			policy		[integer!]
		]
		objc_getAssociatedObject: "objc_getAssociatedObject" [
			obj			[integer!]
			key			[integer!]
			return:		[integer!]
		]
		sel_getUid: "sel_getUid" [
			name		[c-string!]
			return:		[integer!]
		]
		ivar_getOffset: "ivar_getOffset" [
			ivar		[integer!]
			return:		[integer!]
		]
		class_getInstanceVariable: "class_getInstanceVariable" [
			class		[integer!]
			name		[c-string!]
			return:		[integer!]
		]
		class_addIvar: "class_addIvar" [
			class		[integer!]
			name		[c-string!]
			size		[integer!]
			alignment	[integer!]
			types		[c-string!]
			return:		[logic!]
		]
		class_addMethod: "class_addMethod" [
			class		[integer!]
			name		[integer!]
			implement	[integer!]
			types		[c-string!]
			return:		[integer!]
		]
		class_replaceMethod: "class_replaceMethod" [
			class		[integer!]
			name		[integer!]
			implement	[integer!]
			types		[c-string!]
			return:		[integer!]
		]
		class_getSuperclass: "class_getSuperclass" [
			cls			[integer!]
			return:		[integer!]
		]
		class_addProtocol: "class_addProtocol" [
			cls			[integer!]
			protocol	[integer!]
			return:		[logic!]
		]
		object_getClass: "object_getClass" [
			id			[integer!]
			return:		[integer!]
		]
		object_setInstanceVariable: "object_setInstanceVariable" [
			id			[integer!]
			name		[c-string!]
			value		[integer!]
			return:		[integer!]
		]
		object_getInstanceVariable: "object_getInstanceVariable" [
			id			[integer!]
			name		[c-string!]
			out			[int-ptr!]
			return:		[integer!]
		]
		objc_getProtocol: "objc_getProtocol" [
			name		[c-string!]
			return:		[integer!]
		]
		objc_msgSend: "objc_msgSend" [[variadic] return: [integer!]]
		objc_msgSendSuper: "objc_msgSendSuper" [[variadic] return: [integer!]]
		objc_msgSend_f32: "objc_msgSend_fpret" [[variadic] return: [float32!]]
		objc_msgSend_fpret: "objc_msgSend_fpret" [[variadic] return: [float!]]
		objc_msgSend_stret: "objc_msgSend_stret" [[custom]]
		_Block_object_assign: "_Block_object_assign" [
			destAddr	[integer!]
			obj			[integer!]
			flags		[integer!]
		]
		_Block_object_dispose: "_Block_object_dispose" [
			obj			[integer!]
			flags		[integer!]
		]
	]
	"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
		CFAttributedStringCreate: "CFAttributedStringCreate" [
			allocator	[integer!]
			str			[integer!]
			attributes	[integer!]
			return:		[integer!]
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
			allocator	[integer!]
			cStr		[c-string!]
			encoding	[integer!]
			return:		[integer!]
		]
		CFNumberCreate: "CFNumberCreate" [
			allocator	[integer!]
			type		[integer!]
			valuePtr	[int-ptr!]
			return:		[integer!]
		]
		CFRelease: "CFRelease" [
			cf			[integer!]
		]
	]
	"/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation" cdecl [
		NSStringFromClass: "NSStringFromClass" [
			class		[integer!]
			return:		[integer!]
		]
		_NSConcreteStackBlock: "_NSConcreteStackBlock" [integer!]
	]
	"/System/Library/Frameworks/AVFoundation.framework/AVFoundation" cdecl [
		AVMediaTypeVideo: "AVMediaTypeVideo" [integer!]
		AVVideoCodecKey: "AVVideoCodecKey" [integer!]
		AVVideoCodecJPEG: "AVVideoCodecJPEG" [integer!]
	]
	"/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit" cdecl [
		NSBeep: "NSBeep" []
		NSDeviceResolution: "NSDeviceResolution" [integer!]
		NSDefaultRunLoopMode: "NSDefaultRunLoopMode" [integer!]
		NSModalPanelRunLoopMode: "NSModalPanelRunLoopMode" [integer!]
		NSFontAttributeName: "NSFontAttributeName" [integer!]
		NSParagraphStyleAttributeName: "NSParagraphStyleAttributeName" [integer!]
		NSForegroundColorAttributeName: "NSForegroundColorAttributeName" [integer!]
		NSBackgroundColorAttributeName: "NSBackgroundColorAttributeName" [integer!]
		NSUnderlineStyleAttributeName: "NSUnderlineStyleAttributeName" [integer!]	
		NSStrikethroughStyleAttributeName: "NSStrikethroughStyleAttributeName" [integer!]
		NSMarkedClauseSegmentAttributeName: "NSMarkedClauseSegmentAttributeName" [integer!]
		NSGlyphInfoAttributeName: "NSGlyphInfoAttributeName" [integer!]
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
		CTLineCreateWithAttributedString: "CTLineCreateWithAttributedString" [
			aStr		[integer!]
			return:		[integer!]
		]
		CTLineDraw: "CTLineDraw" [
			line		[integer!]
			c			[handle!]
		]
		CGRectContainsPoint: "CGRectContainsPoint" [
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
			x1			[float32!]
			y1			[float32!]
			return:		[logic!]
		]
		CGColorSpaceCreatePattern: "CGColorSpaceCreatePattern" [
			baseSpace	[integer!]
			return:		[integer!]
		]
		CGColorSpaceCreateDeviceRGB: "CGColorSpaceCreateDeviceRGB" [
			return:		[integer!]
		]
		CGContextSetFillColorSpace: "CGContextSetFillColorSpace" [
			ctx			[handle!]
			space		[integer!]
		]
		CGColorSpaceRelease: "CGColorSpaceRelease" [
			colorspace	[integer!]
		]
		CGGradientCreateWithColorComponents: "CGGradientCreateWithColorComponents" [
			colorspace	[integer!]
			components	[pointer! [float32!]]
			locations	[pointer! [float32!]]
			nlocations	[integer!]
			return:		[integer!]
		]
		CGGradientRelease: "CGGradientRelease" [
			gradient	[integer!]
		]
		CGContextDrawLinearGradient: "CGContextDrawLinearGradient" [
			ctx			[handle!]
			gradient	[integer!]
			start-x		[float32!]
			start-y		[float32!]
			end-x		[float32!]
			end-y		[float32!]
			options		[integer!]
		]
		CGContextDrawRadialGradient: "CGContextDrawRadialGradient" [
			ctx			[handle!]
			gradient	[integer!]
			start-x		[float32!]
			start-y		[float32!]
			start-r		[float32!]
			end-x		[float32!]
			end-y		[float32!]
			end-r		[float32!]
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
			x			[float32!]
			y			[float32!]
		]
		CGContextSetRGBStrokeColor: "CGContextSetRGBStrokeColor" [
			c			[handle!]
			red			[float32!]
			green		[float32!]
			blue		[float32!]
			alpha		[float32!]
		]
		CGContextSetRGBFillColor: "CGContextSetRGBFillColor" [
			c			[handle!]
			red			[float32!]
			green		[float32!]
			blue		[float32!]
			alpha		[float32!]
		]
		CGContextStrokeRect: "CGContextStrokeRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
		]
		CGContextFillRect: "CGContextFillRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
		]
		CGContextFillEllipseInRect: "CGContextFillEllipseInRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
		]
		CGContextStrokeEllipseInRect: "CGContextStrokeEllipseInRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
		]
		CGContextAddEllipseInRect: "CGContextAddEllipseInRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
		]
		CGContextSetLineWidth: "CGContextSetLineWidth" [
			c			[handle!]
			width		[float32!]
		]
		CGContextSetLineJoin: "CGContextSetLineJoin" [
			c			[handle!]
			join		[integer!]
		]
		CGContextSetLineCap: "CGContextSetLineCap" [
			c			[handle!]
			cap			[integer!]
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
			limit		[float32!]
		]
		CGContextBeginPath: "CGContextBeginPath" [
			c			[handle!]
		]
		CGContextClosePath: "CGContextClosePath" [
			c			[handle!]
		]
		CGContextCopyPath: "CGContextCopyPath" [
			ctx			[handle!]
			return:		[integer!]
		]
		CGContextAddPath: "CGContextAddPath" [
			ctx			[handle!]
			path		[integer!]
		]
		CGContextClip: "CGContextClip" [
			c			[handle!]
		]
		CGContextMoveToPoint: "CGContextMoveToPoint" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
		]
		CGContextAddLineToPoint: "CGContextAddLineToPoint" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
		]
		CGContextAddCurveToPoint: "CGContextAddCurveToPoint" [
			c			[handle!]
			cp1x		[float32!]
			cp1y		[float32!]
			cp2x		[float32!]
			cp2y		[float32!]
			x			[float32!]
			y			[float32!]
		]
		CGContextAddQuadCurveToPoint: "CGContextAddQuadCurveToPoint" [
			c			[handle!]
			cp1x		[float32!]
			cp1y		[float32!]
			x			[float32!]
			y			[float32!]
		]
		CGContextAddLines: "CGContextAddLines" [
			c			[handle!]
			points		[CGPoint!]
			count		[integer!]
		]
		CGContextAddArc: "CGContextAddArc" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			radius		[float32!]
			startAngle	[float32!]
			endAngle	[float32!]
			clockwise	[integer!]
		]
		CGContextAddArcToPoint: "CGContextAddArcToPoint" [
			c			[handle!]
			x1			[float32!]
			y1			[float32!]
			x2			[float32!]
			y2			[float32!]
			radius		[float32!]
		]
		CGContextAddRect: "CGContextAddRect" [
			c			[handle!]
			x			[float32!]
			y			[float32!]
			width		[float32!]
			height		[float32!]
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
			pattern		[integer!]
			components	[float32-ptr!]
		]
		CGContextSetFillPattern: "CGContextSetFillPattern" [
			ctx			[handle!]
			pattern		[integer!]
			components	[float32-ptr!]
		]
		CGPatternCreate: "CGPatternCreate" [
			info		[int-ptr!]
			rc			[NSRect! value]
			matrix		[CGAffineTransform! value]
			xStep		[float32!]
			yStep		[float32!]
			tiling		[integer!]
			isColored	[logic!]
			callbacks	[CGPatternCallbacks!]
			return:		[integer!]
		]
		CGPatternRelease: "CGPatternRelease" [
			pattern		[integer!]
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
			angle		[float32!]
		]
		CGContextScaleCTM: "CGContextScaleCTM" [
			c			[handle!]
			sx			[float32!]
			sy			[float32!]
		]
		CGContextTranslateCTM: "CGContextTranslateCTM" [
			c			[handle!]
			tx			[float32!]
			ty			[float32!]
		]
		CGContextSetTextMatrix: "CGContextSetTextMatrix" [
			ctx			[handle!]
			a			[float32!]
			b			[float32!]
			c			[float32!]
			d			[float32!]
			tx			[float32!]
			ty			[float32!]
		]
		CGContextGetPathBoundingBox: "CGContextGetPathBoundingBox" [
			ctx			[handle!]
			return:		[NSRect! value]
		]
		CGAffineTransformMake: "CGAffineTransformMake" [
			a			[float32!]
			b			[float32!]
			c			[float32!]
			d			[float32!]
			tx			[float32!]
			ty			[float32!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformMakeScale: "CGAffineTransformMakeScale" [
			sx			[float32!]
			sy			[float32!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformMakeTranslation: "CGAffineTransformMakeTranslation" [
			x			[float32!]
			y			[float32!]
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
			angle		[float32!]						;-- angle in radians
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformTranslate: "CGAffineTransformTranslate" [
			m			[CGAffineTransform! value]
			x			[float32!]
			y			[float32!]
			return:		[CGAffineTransform! value]
		]
		CGAffineTransformScale: "CGAffineTransformScale" [
			m			[CGAffineTransform! value]
			x			[float32!]
			y			[float32!]
			return:		[CGAffineTransform! value]
		]
		CGPathCreateMutable: "CGPathCreateMutable" [
			return:		[integer!]
		]
		CGPathRelease: "CGPathRelease" [
			path		[integer!]
		]
		CGPathMoveToPoint: "CGPathMoveToPoint" [
			path		[integer!]
			m			[CGAffineTransform!]
			x			[float32!]
			y			[float32!]
		]
		CGPathAddRelativeArc: "CGPathAddRelativeArc" [
			path		[integer!]
			m			[CGAffineTransform!]
			x			[float32!]
			y			[float32!]
			radius		[float32!]
			startAngle	[float32!]
			delta		[float32!]
		]
		CGContextDrawImage: "CGContextDrawImage" [
			ctx			[handle!]
			x			[float32!]
			y			[float32!]
			w			[float32!]
			h			[float32!]
			src			[integer!]
		]
		CGImageCreateWithImageInRect: "CGImageCreateWithImageInRect" [
			image		[integer!]
			x			[float32!]
			y			[float32!]
			w			[float32!]
			h			[float32!]
			return:		[integer!]
		]
		CGBitmapContextCreateImage: "CGBitmapContextCreateImage" [
			ctx			[integer!]
			return:		[integer!]
		]
		CGImageRelease: "CGImageRelease" [
			image		[integer!]
		]
	]
	LIBM-file cdecl [
		dlopen:	"dlopen" [
			dllpath		[c-string!]
			flags		[integer!]
			return:		[integer!]
		]
	]
]

#define BLOCK_FIELD_IS_OBJECT	3

;-- https://opensource.apple.com/source/libclosure/libclosure-38/BlockImplementation.txt
objc_block_descriptor: declare struct! [
	reserved		[integer!]
	size			[integer!]
	copy_helper		[function! [dst [int-ptr!] src [int-ptr!]]]
	dispose_helper	[function! [src [int-ptr!]]]
]

get-super-obj: func [
	id		[integer!]
	return: [objc_super!]
	/local
		super [objc_super!]
][
	super: declare objc_super!
	super/receiver: id
	super/superclass: objc_msgSend [id sel_getUid "superclass"]
	super
]

msg-send-super-logic: func [
	id		[integer!]
	sel		[integer!]
	return: [logic!]
	/local
		super [objc_super!]
][
	super: declare objc_super!
	super/receiver: id
	super/superclass: objc_msgSend [id sel_getUid "superclass"]
	as logic! objc_msgSendSuper [super sel]
]

msg-send-super: func [
	id		[integer!]
	sel		[integer!]
	arg		[integer!]
	return: [integer!]
	/local
		super [objc_super!]
][
	super: declare objc_super!
	super/receiver: id
	super/superclass: objc_msgSend [id sel_getUid "superclass"]
	objc_msgSendSuper [super sel arg]
]

to-red-string: func [
	nsstr	[integer!]
	slot	[red-value!]
	return: [red-string!]
	/local
		str  [red-string!]
		size [integer!]
		cstr [c-string!]
][
	size: objc_msgSend [nsstr sel_getUid "lengthOfBytesUsingEncoding:" NSUTF8StringEncoding]
	cstr: as c-string! objc_msgSend [nsstr sel_getUid "UTF8String"]
	if null? slot [slot: stack/push*]
	str: string/make-at slot size Latin1
	unicode/load-utf8-stream cstr size str null
	str
]

to-NSString: func [str [red-string!] return: [integer!] /local len][
	len: -1
	objc_msgSend [
		objc_getClass "NSString"
		sel_getUid "stringWithUTF8String:"
		unicode/to-utf8 str :len
	]
]

to-CFString: func [str [red-string!] return: [integer!] /local len][
	len: -1
	CFStringCreateWithCString 0 unicode/to-utf8 str :len kCFStringEncodingUTF8
]

rs-to-NSColor: func [
	clr		[integer!]
	return: [integer!]
	/local
		r	[integer!]
		g	[integer!]
		b	[integer!]
		a	[integer!]
		c	[NSColor!]
][
	a: 0
	c: as NSColor! :a
	c/r: (as float32! clr and FFh) / 255.0
	c/g: (as float32! clr >> 8 and FFh) / 255.0
	c/b: (as float32! clr >> 16 and FFh) / 255.0
	c/a: (as float32! 255 - (clr >>> 24)) / 255.0

	objc_msgSend [
		objc_getClass "NSColor"
		sel_getUid "colorWithDeviceRed:green:blue:alpha:"
		c/r c/g c/b c/a
	]
]

to-NSColor: func [
	color	[red-tuple!]
	return: [integer!]
][
	if TYPE_OF(color) <> TYPE_TUPLE [return 0]
	rs-to-NSColor color/array1
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
	m/a: as float32! a
	m/b: as float32! b
	m/c: as float32! c
	m/d: as float32! d
	m/tx: as float32! tx
	m/ty: as float32! ty
	m
]