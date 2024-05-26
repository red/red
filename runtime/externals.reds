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
	size: 1000
	
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
	
	store: func [
		handle  [int-ptr!]
		type	[integer!]
		return: [integer!]								;-- array's index (zero-based)
		/local
			rec [record!]
			next new [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["externals/store: " handle]]]
	
		rec: list + free
		if rec/next = tail-record [
			;; realloc
			0
		]
		new: free
		free: rec/next
		rec/header: type								;-- implicit reset of flag-free
		rec/handle: as-integer handle
		rec/next: used
		used: new
		#if debug? = yes [if verbose > 0 [probe ["stored at: " new]]]
		new
	]
	
	remove: func [
		idx	  [integer!]
		call? [logic!]
		/local
			rec p [record!]
	][
		assert idx < size
		rec: as record! list + idx
		if call? [
			0 ;; call destructor
		]
		
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
			p	[int-ptr!]
			rec [record!]
			ext [ext-type!]
			i bits type next [integer!]
			head? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "externals/sweep"]]
		
		if used = tail-record [exit]					;-- early exit empty list
		next: used
		until [
			rec: as record! list + next
			head?: used = next
			next: rec/next
			
			either rec/header and flag-mark = 0 [
				type: rec/header and ext-type-mask
				assert type < (as-integer top - types)
				if type > 0 [							;-- if type id defined, call destructor
					ext: types + (type - 1)				;-- 1-based value
					#if debug? = yes [if verbose > 0 [probe ["destructor: " as int-ptr! :ext/destructor]]]
					if null <> :ext/destructor [ext/destructor as int-ptr! rec/handle]
				]
				if head? [used: next]					;-- removing record from head, move head to next record
				
				rec/header: flag-free					;-- no type when not in use
				rec/handle: 0
				rec/next:   free
				free: (as-integer rec - list) / size? record!
			][
				rec/header: rec/header and not flag-mark ;-- reset mark flag
			]
			next = tail-record
		]
	]
	
	init: func [
		/local
			rec [record!]
			i   [integer!]
	][
		types: as ext-type! allocate max-types * size? ext-type!
		top: types
		
		list: as record! allocate size * size? record!
		i: 1											;-- build free slots list, first subsequent idx: 1
		rec:  list
		loop size [
			rec/header: flag-free						;-- no type when not in use (disables destructor)
			rec/handle: 0
			rec/next:   i								;-- store index of next slot
			i: i + 1
			rec: rec + 1
		]
		rec: rec - 1
		rec/next: tail-record							;-- -1: last slot
		free: 0											;-- all records are free, start list from 1st one
	]
]