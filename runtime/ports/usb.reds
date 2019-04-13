Red/System [
	Title: "title"
]

#if OS = 'Windows [
	#include %usb-windows.reds
]

#define MAX-DEVICE-FIELD	9
#define MAX-CHILDREN		8

usb-device: context [

	alloc-device: func [
		return:		[red-block!]
	][
		block/push-only* MAX-DEVICE-FIELD * 2
	]
	update-name: func [
		dev			[red-block!]
		name		[c-string!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_name no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "name" dev
			string/load-in name length? name dev UTF-8
		][
			string/load-at name length? name slot UTF-8
		]
	]
	update-class: func [
		dev			[red-block!]
		class		[c-string!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_class no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "class" dev
			word/load-in class dev
		][
			word/make-at symbol/make class slot
		]
	]
	update-vid: func [
		dev			[red-block!]
		vid			[integer!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_vendor-id no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "vendor-id" dev
			integer/make-in dev vid
		][
			integer/make-at slot vid
		]
	]
	update-pid: func [
		dev			[red-block!]
		pid			[integer!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_product-id no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "product-id" dev
			integer/make-in dev pid
		][
			integer/make-at slot pid
		]
	]
	update-revision: func [
		dev			[red-block!]
		rev			[integer!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_revision no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "revision" dev
			integer/make-in dev rev
		][
			integer/make-at slot rev
		]
	]
	update-serial: func [
		dev			[red-block!]
		ser			[c-string!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_serial-number no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "serial-number" dev
			string/load-in ser length? ser dev UTF-8
		][
			string/load-at ser length? ser slot UTF-8
		]
	]
	update-path: func [
		dev			[red-block!]
		path		[c-string!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_path no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "path" dev
			string/load-in path length? path dev UTF-8
		][
			string/load-at path length? path slot UTF-8
		]
	]
	update-handle: func [
		dev			[red-block!]
		handle		[c-string!]
		/local
			slot	[red-value!]
	][
		slot: block/select-word dev words/_handle no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "handle" dev
			string/load-in handle length? handle dev UTF-8
		][
			string/load-at handle length? handle slot UTF-8
		]
	]
	update-children: func [
		dev			[red-block!]
		child		[red-block!]
		/local
			slot	[red-value!]
			blk		[red-block!]
	][
		slot: block/select-word dev words/_children no
		either TYPE_OF(slot) = TYPE_NONE [
			set-word/load-in "children" dev
			blk: block/make-in dev MAX-CHILDREN
			block/rs-append blk as red-value! child
		][
			block/rs-append as red-block! slot as red-value! child
		]
	]
]