Red/System [
	Title:   "Alias definitions for datatype structures"
	Author:  "Nenad Rakocevic"
	File: 	 %structures.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
	Note: {
		Putting all aliases in this file for early inclusion in %red.reds solves
		cross-referencing issues in datatypes definitions.
	}
]

#define red-value!	cell!

red-datatype!: alias struct! [
	header 	[integer!]								;-- cell header
	value	[integer!]								;-- datatype ID
	_pad2	[integer!]
	_pad3	[integer!]
]

red-unset!: alias struct! [
	header 	[integer!]								;-- cell header only, no payload
	_pad1	[integer!]
	_pad2	[integer!]
	_pad3	[integer!]
]

red-none!: alias struct! [
	header 	[integer!]								;-- cell header only, no payload
	_pad1	[integer!]
	_pad2	[integer!]
	_pad3	[integer!]
]

red-logic!: alias struct! [
	header 	[integer!]								;-- cell header
	value	[logic!]								;-- 1: TRUE, 0: FALSE
	_pad1	[integer!]
	_pad2	[integer!]
]

red-block!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- block's head index (zero-based)
	node	[node!]									;-- series node pointer
	_pad	[integer!]
]

red-string!: alias struct! [
	header 	[integer!]								;-- cell header
	head	[integer!]								;-- string's head index (zero-based)
	node	[node!]									;-- series node pointer
	cache	[c-string!]								;-- UTF-8 cached version of the string (experimental)
]

red-symbol!: alias struct! [
	header 	[integer!]								;-- cell header
	buffer	[c-string!]								;-- string buffer pointer
	_pad1	[integer!]
	_pad2	[integer!]
]

red-integer!: alias struct! [
	header 	[integer!]								;-- cell header
	padding	[integer!]								;-- align value on 64-bit boundary
	value	[integer!]								;-- 32-bit signed integer value
	_pad	[integer!]	
]

red-context!: alias struct! [
	header 	[integer!]								;-- cell header
	symbols	[node!]									;-- array of 32-bit symbols ID
	values	[node!]									;-- block of values
	_pad	[integer!]
]

red-word!: alias struct! [
	header 	[integer!]								;-- cell header
	ctx		[red-context!]
	symbol	[integer!]								;-- index in symbol table
	index	[integer!]								;-- index in context
]

red-char!: alias struct! [
	header 	[integer!]								;-- cell header
	value	[integer!]								;-- UCS-4 codepoint
	_pad1	[integer!]
	_pad2	[integer!]	
]

red-action!: alias struct! [
	header 	[integer!]								;-- cell header
	spec	[node!]									;-- action spec block reference
	symbols	[node!]									;-- action cleaned-up spec block reference
	_pad	[integer!]	
]

red-native!: alias struct! [
	header 	[integer!]								;-- cell header
	spec	[node!]									;-- native spec block reference
	symbols	[node!]									;-- native cleaned-up spec block reference
	_pad	[integer!]	
]

red-op!: alias struct! [
	header 	[integer!]								;-- cell header
	spec	[node!]									;-- op spec block reference
	symbols	[node!]									;-- op cleaned-up spec block reference
	_pad	[integer!]	
]
