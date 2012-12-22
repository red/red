Red/System [
	Title:   "Common datatypes utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

names!: alias struct! [
	buffer	[c-string!]								;-- datatype name string
	size	[integer!]								;-- buffer size - 1 (not counting terminal `!`)
	word	[red-word!]								;-- datatype name as word! value
]

name-table: as names! allocate 50 * size? names!	 ;-- datatype names table

action-table: as int-ptr! allocate 256 * 50 * size? pointer! ;-- actions jump table	


set-type: func [										;@@ convert to macro?
	cell [cell!]
	type [integer!]
][
	cell/header: cell/header and type-mask or type
]

alloc-at-tail: func [
	blk		[red-block!]
	return: [cell!]
][
	alloc-tail as series! blk/node/value
]

alloc-tail: func [
	s		 [series!]
	return:  [cell!]
	/local 
		cell [red-value!]
][
	if (as byte-ptr! s/tail + 1) > ((as byte-ptr! s + 1) + s/size) [
		s: expand-series s 0
	]
	
	cell: s/tail
	;-- ensure that cell is within series upper boundary
	assert (as byte-ptr! cell) < ((as byte-ptr! s + 1) + s/size)
	
	s/tail: cell + 1									;-- move tail to next cell
	cell
]

alloc-tail-unit: func [
	s		 [series!]
	return:  [byte-ptr!]
	/local 
		p	 [byte-ptr!]
		unit [integer!]
][
	unit: GET_UNIT(s)
	if ((as byte-ptr! s/tail) + unit) > ((as byte-ptr! s + 1) + s/size) [
		s: expand-series s 0
	]
	
	p: as byte-ptr! s/tail
	;-- ensure that cell is within series upper boundary
	assert p < ((as byte-ptr! s + 1) + s/size)
	
	s/tail: as cell! p + unit							;-- move tail to next unit slot
	p
]

copy-cell: func [
	src		[cell!]
	dst		[cell!]
	return: [red-value!]
][
	copy-memory											;@@ optimize for 16 bytes copying
		as byte-ptr! dst
		as byte-ptr! src
		size? cell!
	dst
]


words: context [
	_spec:	as red-word! 0
	_body:	as red-word! 0
	_words:	as red-word! 0
	
	spec: 	-1
	body:	-1
	words:	-1
	
	build: does [
		_spec:	word/load "spec"
		_body:	word/load "body"
		_words:	word/load "words"
		
		spec:  _spec/symbol
		body:  _body/symbol
		words: _words/symbol
	]
]