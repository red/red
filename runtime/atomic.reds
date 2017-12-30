Red/System [
	Title:	"Functions for Atomic Operations"
	Author: "Xie Qingtian"
	File: 	%atomic.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		@@ Implement it using CPU instructions later. @@
	}
]

atomic: context [

#either OS = 'Windows [
	#import [
		"kernel32.dll" stdcall [
			InterlockedExchange: "InterlockedExchange" [
				target	[int-ptr!]
				value	[integer!]
				return:	[integer!]
			]
			InterlockedCompareExchange: "InterlockedCompareExchange" [
				Destination	[int-ptr!]
				Exchange	[integer!]
				Comparand	[integer!]
				return:		[integer!]
			]
			InterlockedExchangeAdd: "InterlockedExchangeAdd" [
				Addend	[int-ptr!]
				Value	[integer!]
				return:	[integer!]
			]
			InterlockedIncrement: "InterlockedIncrement" [
				Addend	[int-ptr!]
				return:	[integer!]
			]
			InterlockedDecrement: "InterlockedDecrement" [
				Addend	[int-ptr!]
				return:	[integer!]
			]
		]
	]

	exchange: func [
		target	[int-ptr!]
		value	[integer!]
		return:	[integer!]
	][
		InterlockedExchange target value
	]

	compare-exchange: func [
		dest		[int-ptr!]
		exchange	[integer!]
		comparand	[integer!]
		return:		[integer!]
	][
		InterlockedCompareExchange dest exchange comparand
	]

	get: func [
		src		[int-ptr!]
		return: [integer!]
	][
		InterlockedCompareExchange src 0 0
	]

	set: func [
		target	[int-ptr!]
		value	[integer!]
		return: [integer!]
	][
		InterlockedExchange target value
	]

	add: func [
		addend	[int-ptr!]
		value	[integer!]
		return:	[integer!]
	][
		InterlockedExchangeAdd addend value
	]

	subtract: func [
		addend	[int-ptr!]
		value	[integer!]
		return: [integer!]
	][
		InterlockedExchangeAdd addend 0 - value
	]

	increment: func [
		addend	[int-ptr!]
		return:	[integer!]
	][
		InterlockedIncrement addend
	]
	
	decrement: func [
		addend	[int-ptr!]
		return:	[integer!]
	][
		InterlockedDecrement addend
	]
][
	exchange: func [
		target	[int-ptr!]
		value	[integer!]
		return:	[integer!]
	][
		0
	]

	compare-exchange: func [
		dest		[int-ptr!]
		exchange	[integer!]
		comparand	[integer!]
		return:		[integer!]
	][
		0
	]

	get: func [
		src		[int-ptr!]
		return: [integer!]
	][
		0
	]

	set: func [
		target	[int-ptr!]
		value	[integer!]
		return: [integer!]
	][
		0
	]

	add: func [
		addend	[int-ptr!]
		value	[integer!]
		return:	[integer!]
	][
		0
	]

	subtract: func [
		addend	[int-ptr!]
		value	[integer!]
		return: [integer!]
	][
		0
	]

	increment: func [
		addend	[int-ptr!]
		return:	[integer!]
	][
		0
	]
	
	decrement: func [
		addend	[int-ptr!]
		return:	[integer!]
	][
		0
	]
]

]