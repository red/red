Red/System [
	Title:   "External resources registry"
	Author:  "Nenad Rakocevic"
	File: 	 %externals.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

externals: context [
	verbose: 0
	
	flag-mark:	   80000000h
	flag-free:	   40000000h
	ext-type-mask: 000000FFh
	tail-record:   FFFFFFFFh
	
	destructor!: alias function! [handle [int-ptr!]]
	
	ext-type!: alias struct! [
		name		[c-string!]
		destructor	[destructor!]
	]
	
	record!: alias struct! [
		header [integer!]
		handle [integer!]								;-- stored external handle
		next   [integer!]
	]
	
	types: as ext-type! 0
	top:   as ext-type! 0
	max-types: 20
	
	list: as record! 0
	used: tail-record									;-- head of used slots list (index)
	free: tail-record									;-- head of free slots list (index)
	size: 1000											;-- starting records pool
	
	register: func [
		name	[c-string!]
		fun		[integer!]
		return: [integer!]								;-- return assigned type ID
		/local
			id  [integer!]
	][
		top/name: name
		top/destructor: as destructor! fun
		id: (as-integer top - types) / size? ext-type!
		assert id + 1 < max-types
		top: top + 1
		id + 1											;-- return a 1-based value (0 reserved for "no type")
	]
	
	format: func [
		p  [record!]
		nb [integer!]
		/local
			i [integer!]
	][
		i: ((as-integer p - list) / size? record!) + 1	;-- first subsequent index
		loop nb [										;-- build free slots list
			p/header: flag-free							;-- no type when not in use (disables destructor)
			p/handle: 0
			p/next:   i									;-- store index of next slot
			i: i + 1
			p: p + 1
		]
		p: p - 1
		p/next: tail-record								;-- -1: last slot
	]
	
	store: func [
		handle  [int-ptr!]
		type	[integer!]
		return: [integer!]								;-- array's index (zero-based)
		/local
			rec [record!]
			next new half [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["externals/store: " handle]]]
	
		rec: list + free
		if rec/next = tail-record [
			assert free < size
			half: size
			size: size * 2
			list: as record! realloc as byte-ptr! list size * size? record!
			format list + half half
			rec: list + free
			rec/next: half
		]
		new: free
		free: rec/next
		rec/header: type								;-- implicit reset of flag-free
		rec/handle: as-integer handle
		rec/next: used
		used: new
		#if debug? = yes [if verbose > 0 [print-line ["stored at: " new]]]
		new
	]
	
	release: func [
		rec [record!]
		/local
			ext  [ext-type!]
			type [integer!]
	][
		type: rec/header and ext-type-mask
		assert type < (as-integer top - types)
		if type > 0 [									;-- if type id defined, call destructor
			ext: types + (type - 1)						;-- 1-based value
			#if debug? = yes [if verbose > 0 [print-line ["destructor: " as int-ptr! :ext/destructor ", on: " as int-ptr! rec/handle]]]
			if null <> :ext/destructor [ext/destructor as int-ptr! rec/handle]
		]
	]
	
	remove: func [										;-- remove a record directly
		idx		[integer!]
		call?	[logic!]								;-- YES: call destructor also
		return: [integer!]
		/local
			rec p [record!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["externals/remove: " idx ", " call?]]]
		
		assert idx < size
		rec: as record! list + idx
		if call? [release rec]
		
		p: list + used									;-- update the used list
		either idx = used [
			used: p/next								;-- drop record from used head
		][
			while [(list + p/next) <> rec][p: list + p/next] ;-- find the rec's precursor in the used list
			p/next: rec/next							;-- drop record from used list
		]
		
		rec/header: flag-free
		rec/handle: 0
		rec/next:   free
		free: (as-integer rec - list) / size? record!	;-- insert rec at head of free list
		-1
	]

	mark: func [idx [integer!] /local rec [record!]][
		#if debug? = yes [if verbose > 0 [print-line ["externals/mark: " idx]]]
		assert idx < size
		rec: as record! list + idx
		assert rec/header and flag-free = 0
		rec/header: rec/header or flag-mark
	]
	
	sweep: func [
		/local
			p		  [int-ptr!]
			rec prev  [record!]
			next c c0 [integer!]
			head?	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "externals/sweep"]]
		
		if used = tail-record [exit]					;-- early exit empty list
		
		#if debug? = yes [
			if verbose > 0 [probe "externals: checking linked lists..."]
			next: free									;-- verify integrity of free records list
			c: 0
			while [next <> tail-record][
				c: c + 1
				assert used <> next
				rec: list + next
				assert all [
					rec/header and flag-mark = 0
					rec/header and flag-free <> 0 
				]
				next: rec/next
			]
			if verbose > 0 [probe ["externals/free size: " c]]
			c0: c

			next: used									;-- verify integrity of used records list
			c: 0
			while [next <> tail-record][
				c: c + 1
				assert free <> next
				rec: list + next
				assert rec/header and flag-free = 0
				assert next <> rec/next
				next: rec/next
			]
			if verbose > 0 [probe ["externals/used size: " c]]
			assert c0 + c = size
		]

		next: used
		prev: null
		until [
			rec: list + next
			head?: used = next
			next: rec/next
			
			either rec/header and flag-mark = 0 [		;-- not marked, free the record, release resource
				release rec
				either head? [used: next][prev/next: rec/next]	;-- connect previous/head record to next one (skipping current)
				
				rec/header: flag-free					;-- no type when not in use
				rec/handle: 0
				rec/next:   free
				free: (as-integer rec - list) / size? record!
			][
				rec/header: rec/header and not flag-mark ;-- reset mark flag
				prev: rec								 ;-- save last used record in the list
			]
			next = tail-record
		]
		;; TBD: add list shrinking if used/free ratio too small
	]
	
	init: func [][
		types: as ext-type! allocate max-types * size? ext-type!
		top: types
		
		list: as record! allocate size * size? record!
		format list size
		free: 0											;-- all records are free, start list from 1st one
	]
]