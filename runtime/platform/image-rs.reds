Red/System [
	Title:   "Image routine functions in Red/System"
	Author:  "Qingtian Xie"
	File: 	 %image-rs.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

OS-image: context [
	width?: func [
		handle		[node!]
		return:		[integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]

	height?: func [
		handle		[node!]
		return:		[integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]
	
	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]

	unlock-bitmap: func [					;-- do nothing on Quartz backend
		img			[red-image!]
		data		[integer!]
	][]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
	][
		--NOT_IMPLEMENTED--
		null
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]

	delete: func [img [red-image!]][
		--NOT_IMPLEMENTED--
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
	][
		--NOT_IMPLEMENTED--
		0
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
	][
		--NOT_IMPLEMENTED--
		null
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
	][
		--NOT_IMPLEMENTED--
		null
	]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb-bin	[red-binary!]
		alpha-bin [red-binary!]
		color	[red-tuple!]
		return: [node!]
	][
		--NOT_IMPLEMENTED--
		null
	]


	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
	][
		--NOT_IMPLEMENTED--
		null
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
	][
		--NOT_IMPLEMENTED--
		null
	]
]