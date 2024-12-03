Red/System [
	Title:   "External Red values reference management"
	Author:  "Nenad Rakocevic"
	File: 	 %references.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

references: context [									;-- Red values list management
	verbose: 0
	
	list: declare red-block!
	size: 100
	free: -1
	
	format: func [
		start [integer!]
		/local
			int tail [red-integer!]
			s [series!]
			i [integer!]
	][
		s: GET_BUFFER(list)
		int:  as red-integer! s/offset + start
		tail: as red-integer! s/offset + size
		i: start + 1
		while [int < tail][
			int/header: TYPE_INTEGER
			int/value: i
			i: i + 1
			int: int + 1
		]
		int: int - 1
		int/value: -1								;-- special value for list's tail
		free: start									;-- set list's head
		s/tail: as red-value! tail
	]
	
	get: func [
		id		[integer!]
		return: [red-value!]
		/local
			s 	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["reference/get " id]]]
		id: id - 1
		assert id < size
		s: GET_BUFFER(list)
		s/offset + id
	]
	
	store: func [
		value	[red-value!]
		return: [integer!]
		/local
			int [red-integer!]
			s	[series!]
			id next half [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["reference/store (type: " TYPE_OF(value) ")"]]]
		s: GET_BUFFER(list)
		if free = -1 [
			half: size
			size: size * 2
			#if debug? = yes [if verbose > 0 [print-line ["reference/store: expand storage to " size]]]
			s: expand-series s size * size? cell!			;-- convert size to bytes
			format half
		]
		id: free
		int: as red-integer! s/offset + id
		next: int/value
		copy-cell value as red-value! int
		free: next
		#if debug? = yes [if verbose > 0 [print-line ["reference/stored at: " id + 1]]]
		id + 1
	]
	
	remove: func [
		id [integer!]
		/local
			int [red-integer!]
			s	[series!]
	][
		if zero? id [exit]								;-- filter out double removing
		assert id > 0
		#if debug? = yes [if verbose > 0 [print-line ["reference/remove " id]]]
		id: id - 1
		assert id < size
		s: GET_BUFFER(list)	
		int: as red-integer! s/offset + id
		assert TYPE_OF(int) <> TYPE_INTEGER
		int/header: TYPE_INTEGER
		int/value: free
		free: id
	]
	
	init: func [][
		block/make-at list size
		format 0
	]

	#if debug? = yes [
		check-leaks: func [
			/local
				slot tail [red-integer!]
				s [series!]
				c [integer!]
		][
			s: GET_BUFFER(list)
			assert s/offset + size = s/tail
			slot: as red-integer! s/offset
			tail: as red-integer! s/tail
			c: 0
			while [slot < tail][
				if TYPE_OF(slot) <> TYPE_INTEGER [c: c + 1]
				slot: slot + 1
			]
			if c > 0 [print-line ["*** Warning: " c " leaked reference values!"]]
		]
	]
]
