Red/System [
	Title:	"macOS Camera widget"
	Author: "Xie Qingtian"
	File: 	%camera.reds
	Tabs: 	4
	Notes:  {
		For 10.7+, use AVFoundation, iOS will also use it.
		For 10.0 ~ 10.6, use QTKit.(TBD)
	}
	References: {
		https://developer.apple.com/library/ios/samplecode/AVCam/Listings/AVCam_AAPLCameraViewController_m.html#//apple_ref/doc/uid/DTS40010112-AVCam_AAPLCameraViewController_m-DontLinkElementID_6
		https://opensource.apple.com/source/libclosure/libclosure-38/BlockImplementation.txt
	}
	Rights: "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

camera-ratio:	 0.0									;-- used to pass ratio info from deep code to init-camera 

init-camera: func [
	camera	[integer!]
	rc		[NSRect!]
	data	[red-block!]
	/local
		devices	[integer!]
		session	[integer!]
		preview	[integer!]
		layer	[integer!]
		n		[integer!]
		cnt		[integer!]
		dev		[integer!]
		name	[integer!]
		size	[integer!]
		str		[red-string!]
		cstr	[c-string!]
		img-out [integer!]
		setting [integer!]
][
	rc/x: as float32! 0.0
	rc/y: as float32! 0.0

	layer: objc_msgSend [camera sel_getUid "setWantsLayer:" yes]
	layer: objc_msgSend [camera sel_getUid "layer"]
	n: objc_msgSend [objc_getClass "NSColor" sel_getUid "blackColor"]
	objc_msgSend [
		layer sel_getUid "setBackgroundColor:" objc_msgSend [n sel_getUid "CGColor"]
	]
	objc_msgSend [layer sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]

	;-- get all devices name
	devices: objc_msgSend [objc_getClass "AVCaptureDevice" sel_getUid "devicesWithMediaType:" AVMediaTypeVideo]
	if zero? devices [exit]
	cnt: objc_msgSend [devices sel_getUid "count"]
	if zero? cnt [exit]

	if TYPE_OF(data) <> TYPE_BLOCK [
		block/make-at data cnt
	]
	n: 0
	while [n < cnt] [
		dev: objc_msgSend [devices sel_getUid "objectAtIndex:" n]
		name: objc_msgSend [dev sel_getUid "localizedName"]
		size: objc_msgSend [name sel_getUid "lengthOfBytesUsingEncoding:" NSUTF8StringEncoding]
		cstr: as c-string! objc_msgSend [name sel_getUid "UTF8String"]
		str: string/make-at ALLOC_TAIL(data) size Latin1
		unicode/load-utf8-stream cstr size str null
		n: n + 1
	]

	session: objc_msgSend [objc_getClass "AVCaptureSession" sel_getUid "alloc"]
	session: objc_msgSend [session sel_getUid "init"]

	objc_msgSend [session sel_getUid "beginConfiguration"]
	img-out: objc_msgSend [objc_getClass "AVCaptureStillImageOutput" sel_getUid "alloc"]
	img-out: objc_msgSend [img-out sel_getUid "init"]
	setting: objc_msgSend [objc_getClass "NSDictionary" sel_getUid "alloc"]
	setting: objc_msgSend [setting sel_getUid "initWithObjectsAndKeys:" AVVideoCodecJPEG AVVideoCodecKey 0]
	objc_msgSend [img-out sel_getUid "setOutputSettings:" setting]
	objc_msgSend [session sel_getUid "addOutput:" img-out]
	objc_msgSend [session sel_getUid "commitConfiguration"]

	objc_setAssociatedObject camera RedCameraSessionKey session OBJC_ASSOCIATION_ASSIGN
	objc_setAssociatedObject camera RedCameraDevicesKey devices OBJC_ASSOCIATION_RETAIN
	objc_setAssociatedObject camera RedCameraImageKey   img-out OBJC_ASSOCIATION_ASSIGN

	preview: objc_msgSend [objc_getClass "AVCaptureVideoPreviewLayer" sel_getUid "layerWithSession:" session]
	objc_msgSend [preview sel_getUid "setAutoresizingMask:" NSViewWidthSizable or NSViewHeightSizable]
	objc_msgSend [preview sel_getUid "setFrame:" rc/x rc/y rc/w rc/h]
	objc_msgSend [layer sel_getUid "addSublayer:" preview]
]

select-camera: func [
	camera		[integer!]
	idx			[integer!]
	/local
		session [integer!]
		devices [integer!]
		dev		[integer!]
		dev-in	[integer!]
		cur-dev	[integer!]
][
	session: objc_getAssociatedObject camera RedCameraSessionKey
	devices: objc_getAssociatedObject camera RedCameraDevicesKey
	cur-dev: objc_getAssociatedObject camera RedCameraDevInputKey		;-- current device input

	dev: objc_msgSend [devices sel_getUid "objectAtIndex:" idx]
	dev-in: objc_msgSend [objc_getClass "AVCaptureDeviceInput" sel_getUid "deviceInputWithDevice:error:" dev 0]
	if zero? dev-in [exit]

	objc_msgSend [session sel_getUid "beginConfiguration"]
	if cur-dev <> 0 [
		objc_msgSend [session sel_getUid "removeInput:" cur-dev]
		objc_setAssociatedObject camera RedCameraDevInputKey 0 OBJC_ASSOCIATION_ASSIGN
	]
	objc_msgSend [session sel_getUid "addInput:" dev-in]
	objc_setAssociatedObject camera RedCameraDevInputKey dev-in OBJC_ASSOCIATION_ASSIGN
	objc_msgSend [session sel_getUid "commitConfiguration"]
]

toggle-preview: func [
	camera		[integer!]
	enabled?	[logic!]
	/local
		session [integer!]
		face	[red-object!]
		ratio	[red-float!]
		img		[red-image!]
		w h		[integer!]
][
	session: objc_getAssociatedObject camera RedCameraSessionKey
	either enabled? [
		objc_msgSend [session sel_getUid "startRunning"]
		face: get-face-obj camera
		ratio: get-ratio face
		if TYPE_OF(ratio) = TYPE_FLOAT [
			snap-camera camera
			img: as red-image! get-node-facet face/ctx FACE_OBJ_IMAGE
			w: IMAGE_WIDTH(img/size)
			h: IMAGE_HEIGHT(img/size)
			camera-ratio: (as-float w) / (as-float h)
			ratio/value: camera-ratio
		]
	][
		objc_msgSend [session sel_getUid "stopRunning"]
	]
]

still-image-handler: func [
	[cdecl]
	block	[int-ptr!]
	buffer	[integer!]
	error	[integer!]
	/local
		values	[red-value!]
		data	[integer!]
][
	if error <> 0 [exit]		;-- error occur

	values: get-face-values block/6
	data: objc_msgSend [
		objc_getClass "AVCaptureStillImageOutput"
		sel_getUid "jpegStillImageNSDataRepresentation:"
		buffer
	]
	image/init-image
		as red-image! values + FACE_OBJ_IMAGE
		OS-image/load-nsdata as int-ptr! data
]

snap-camera: func [				;-- capture an image of current preview window
	camera		[integer!]
	/local
		blk			[block_literal!]
		isa			[integer!]
		image		[integer!]
		connection	[integer!]
		layer		[integer!]
		orientation [integer!]
		sel			[integer!]
][
	blk: declare block_literal!
	isa: objc_getAssociatedObject camera RedCameraSessionKey
	if zero? objc_msgSend [isa sel_getUid "isRunning"][exit]

	objc_block_descriptor/reserved: 0
	objc_block_descriptor/size: 4 * 6

	blk/isa: _NSConcreteStackBlock
	blk/flags: 1 << 29				;-- BLOCK_HAS_DESCRIPTOR, no copy and dispose helpers
	blk/reserved: 0
	blk/invoke: as int-ptr! :still-image-handler
	blk/descriptor: as int-ptr! objc_block_descriptor
	blk/value: as int-ptr! camera
	image: objc_getAssociatedObject camera RedCameraImageKey
	connection: objc_msgSend [image sel_getUid "connectionWithMediaType:" AVMediaTypeVideo]

	;-- Update the orientation on the still image output video connection before capturing
	;layer: objc_msgSend [camera sel_getUid "layer"]
	;orientation: objc_msgSend [layer sel_getUid "connection"]
	;orientation: objc_msgSend [orientation sel_getUid "videoOrientation"]
	;objc_msgSend [connection sel_getUid "setVideoOrientation:" orientation]

	objc_msgSend [
		image
		sel_getUid "captureStillImageAsynchronouslyFromConnection:completionHandler:"
		connection
		blk
	]
	sel: sel_getUid "isCapturingStillImage"
	until [zero? objc_msgSend [image sel]]
]