Red/System [
	Title:   "Hash! datatype runtime functions"
	Author:  "Qingtian Xie"
	File:	 %hash.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

hash: context [
	verbose: 0

	;--- Actions ---

	make: func [
		proto	[red-block!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-hash!]
		/local
			hash	[red-hash!]
			size	[integer!]
			int		[red-integer!]
			table	[node!]
			blk		[red-block!]
			blk?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/make"]]

		blk?: no
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
				if negative? size [fire [TO_ERROR(script out-of-range) spec]]
			]
			TYPE_BLOCK [
				size: block/rs-length? as red-block! spec
				blk?: yes
			]
			default [
				return to proto spec type
			]
		]

		unless positive? size [size: 1]
		either type = -1 [							;-- called by TO
			blk: as red-block! spec
		][
			blk: block/make-at as red-block! stack/push* size
			if blk? [block/copy as red-block! spec blk null no null]
		]
		table: _hashtable/init size blk HASH_TABLE_HASH 1
		hash: as red-hash! blk
		hash/header: TYPE_HASH						;-- implicit reset of all header flags
		hash/table: table
		hash
	]

	to: func [
		proto	[red-block!]
		spec	[red-value!]
		type	[integer!]
		return: [red-hash!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/to"]]

		make proto (as red-value! block/to proto spec TYPE_BLOCK) -1
	]

	mold: func [
		hash	[red-hash!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/mold"]]

		string/concatenate-literal buffer "make hash! "
		block/mold as red-block! hash buffer no all? flat? arg part - 11 indent
	]

	clear: func [
		hash	[red-hash!]
		return:	[red-value!]
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/clear"]]

		blk: as red-block! hash
		_hashtable/clear hash/table blk/head block/rs-length? blk
		block/rs-clear blk
		as red-value! hash
	]

	copy: func [
		hash    	[red-hash!]
		new			[red-block!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-series!]
		/local
			size	[integer!]
			table	[node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/copy"]]

		block/copy as red-block! hash new part-arg deep? types
		size: block/rs-length? new
		table: _hashtable/init size new HASH_TABLE_HASH 1
		hash: as red-hash! new
		hash/header: TYPE_HASH							;-- implicit reset of all header flags
		hash/table: table
		as red-series! hash
	]

	sort: func [
		hash		[red-hash!]
		case?		[logic!]
		skip		[red-integer!]
		comparator	[red-function!]
		part		[red-value!]
		all?		[logic!]
		reverse?	[logic!]
		stable?		[logic!]
		return:		[red-hash!]
		/local
			blk		[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/sort"]]

		blk: as red-block! hash
		block/sort blk case? skip comparator part all? reverse? stable?
		_hashtable/clear hash/table blk/head block/rs-length? blk
		_hashtable/put-all hash/table blk/head 1
		hash
	]

	trim: func [
		hash		[red-hash!]
		head?		[logic!]
		tail?		[logic!]
		auto?		[logic!]
		lines?		[logic!]
		all?		[logic!]
		with-arg	[red-value!]
		return:		[red-hash!]
		/local
			blk		[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "hash/trim"]]

		blk: as red-block! hash
		block/trim blk head? tail? auto? lines? all? with-arg
		_hashtable/clear hash/table blk/head block/rs-length? blk
		_hashtable/put-all hash/table blk/head 1
		hash
	]

	init: does [
		datatype/register [
			TYPE_HASH
			TYPE_BLOCK
			"hash!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			INHERIT_ACTION	;form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			INHERIT_ACTION	;change
			:clear
			:copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;move
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			INHERIT_ACTION	;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			:sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			:trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]