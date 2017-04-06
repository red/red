Red/System [
	Title:   "Common datatypes utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

object!-type: declare red-datatype!
object!-type/header: TYPE_DATATYPE
object!-type/value: TYPE_OBJECT

names!: alias struct! [
	buffer	[c-string!]								;-- datatype name string
	size	[integer!]								;-- buffer size - 1 (not counting terminal `!`)
	word	[red-word!]								;-- datatype name as word! value
]

name-table:	  as names! 0	 						;-- datatype names table
action-table: as int-ptr! 0							;-- actions jump table

get-build-date: func [return: [c-string!]][			;-- used by red.r
	#build-date
]

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
	
	if (as byte-ptr! s/tail) = ((as byte-ptr! s + 1) + s/size) [
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
	unit 	 [integer!]
	return:  [byte-ptr!]
	/local 
		p	 [byte-ptr!]
		size [integer!]
][
	if ((as byte-ptr! s/tail) + unit) > ((as byte-ptr! s + 1) + s/size) [
		size: either unit > s/size [unit << 1][0]
		s: expand-series s size
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

get-root: func [
	idx		[integer!]
	return: [red-block!]
][
	as red-block! redbin/root-base + idx
]

get-root-node: func [
	idx		[integer!]
	return: [node!]
	/local
		obj [red-object!]
][
	obj: as red-object! get-root idx
	obj/ctx
]

get-root-node2: func [									;-- alias used by libRedRT
	idx		[integer!]
	return: [node!]
][
	get-root-node idx
]

report: func [
	type  [red-value!]
	id    [red-value!]
	arg1  [red-value!]
	arg2  [red-value!]
	arg3  [red-value!]
][	
	stack/mark-native words/_body
	stack/set-last as red-value! error/create type id arg1 arg2 arg3
	natives/print* no
	stack/set-last unset-value
	stack/unwind
]

fire: func [
	[variadic]
	count	[integer!]
	list	[int-ptr!]
	/local
		arg1 [red-value!]
		arg2 [red-value!]
		arg3 [red-value!]
][
	assert count <= 5
	arg1: null
	arg2: null
	arg3: null
	
	count: count - 2
	unless zero? count [
		arg1: as red-value! list/3
		count: count - 1
		unless zero? count [
			arg2: as red-value! list/4
			count: count - 1
			unless zero? count [arg3: as red-value! list/5]
		]
	]
	stack/throw-error error/create as red-value! list/1 as red-value! list/2 arg1 arg2 arg3
]

throw-make: func [
	proto [red-value!]
	spec  [red-block!]
][
	fire [TO_ERROR(script bad-make-arg) proto spec]
]

type-check-opt: func [									;-- used by #typecheck
	ref		 [integer!]
	expected [red-typeset!]
	index	 [integer!]
][
	if ref > -1 [type-check expected index stack/arguments + ref]
]

type-check-alt: func [									;-- for compiled user code
	ref		 [red-value!]
	expected [red-typeset!]
	index	 [integer!]
	arg		 [red-value!]
	return:  [red-value!]
	/local
		bool [red-logic!]
][
	bool: as red-logic! ref
	either bool/value [type-check expected index arg][arg]
]

type-check: func [
	expected [red-typeset!]
	index	 [integer!]
	arg		 [red-value!]
	return:  [red-value!]
	/local
		type [integer!]
		bits [byte-ptr!]
		pos	 [byte-ptr!]								;-- required by BS_TEST_BIT
		set? [logic!]									;-- required by BS_TEST_BIT
][
	type: TYPE_OF(arg)
	bits: (as byte-ptr! expected) + 4
	BS_TEST_BIT(bits type set?)
	unless set? [ERR_EXPECT_ARGUMENT(type index)]
	arg													;-- pass-thru argument
]

set-path*: func [
	parent  [red-value!]
	element [red-value!]
][
	stack/set-last actions/eval-path parent element stack/arguments null no
	object/path-parent/header: TYPE_NONE				;-- disables owner checking
]

set-int-path*: func [
	parent  [red-value!]
	index 	[integer!]
][
	stack/set-last actions/eval-path
		parent
		as red-value! integer/push index
		stack/arguments									;-- value to set
		null
		no
	object/path-parent/header: TYPE_NONE				;-- disables owner checking
]

eval-path*: func [
	parent  [red-value!]
	element [red-value!]
][
	stack/set-last actions/eval-path parent element null null no ;-- no value to set
]

eval-path: func [
	parent  [red-value!]
	element [red-value!]
	return: [red-value!]
][
	actions/eval-path parent element null null no 		;-- pass the value reference directly (no copying!)
]

eval-int-path*: func [
	parent	[red-value!]
	index	[integer!]
	/local
		int	[red-value!]
][
	int: as red-value! integer/push index
	stack/set-last actions/eval-path parent int null null no ;-- no value to set
]

eval-int-path: func [
	parent  [red-value!]
	index 	[integer!]
	return: [red-value!]
	/local
		int	[red-value!]
][
	int: as red-value! integer/push index
	actions/eval-path parent int null null no			;-- pass the value reference directly (no copying!)
]

select-key*: func [										;-- called by compiler for SWITCH
	sub?	[logic!]
	fetch?	[logic!]
	return: [red-value!]
	/local
		blk	  [red-block!]
		key	  [red-value!]
		value [red-value!]
		tail  [red-value!]
		s	  [series!]
		step  [integer!]
][
	key: as red-value! stack/arguments
	blk: as red-block! key + 1
	assert TYPE_OF(blk) = TYPE_BLOCK
	
	unless TYPE_OF(key) = TYPE_BLOCK [
		s: GET_BUFFER(blk)
		value: s/offset + blk/head
		tail:  s/tail
		step:  either sub? [1][2]

		while [value < tail][
			if TYPE_OF(key) = TYPE_OF(value) [
				if actions/compare key value COMP_EQUAL [
					either fetch? [
						value: value + 1
						while [value < tail][
							if TYPE_OF(value) = TYPE_BLOCK [break]
							value: value + 1
						]
					][
						value: either value + 1 < tail [value + 1][value]
					]
					either sub? [stack/push value][stack/set-last value]
					return value
				]
			]
			value: value + step
		]
	]
	either sub? [as red-value! none/push][
		value: stack/arguments
		value/header: TYPE_NONE
		value
	]
]

load-value: func [
	str		[red-string!]
	return: [red-value!]
	/local
		blk	  [red-block!]
		value [red-value!]
][
	#call [system/lexer/transcode/one/only str none no]

	blk: as red-block! stack/arguments
	assert TYPE_OF(blk) = TYPE_BLOCK

	either zero? block/rs-length? blk [
		value: as red-value! blk
		value/header: TYPE_UNSET
	][
		value: block/rs-head blk
	]
	value
]

form-value: func [
	arg		[red-value!]
	part	[integer!]								;-- pass 0 for full string
	return: [red-string!]
	/local
		buffer [red-string!]
		limit  [integer!]
][
	buffer: string/rs-make-at stack/push* 16
	limit: actions/form stack/arguments buffer arg part

	if all [part >= 0 negative? limit][
		string/truncate-from-tail GET_BUFFER(buffer) limit
	]
	buffer
]

cycles: context [
	size: 1000											;-- max depth allowed (arbitrary)
	stack: as node! allocate size * size? node!			;-- cycles detection stack
	top: stack
	end: stack + size

	push: func [node [node!]][
		top/value: as-integer node
		top: top + 1
		if top = end [fire [TO_ERROR(internal too-deep)]]
	]
	
	pop: does [
		if top > stack [top: top - 1]
	]
	
	find?: func [
		value	[red-value!]
		return: [logic!]
		/local
			obj	 [red-object!]
			blk	 [red-block!]
			node [node!]
			p	 [node!]
	][
		if top = stack [return no]
		
		node: either TYPE_OF(value) = TYPE_OBJECT [
			obj: as red-object! value
			obj/ctx
		][
			blk: as red-block! value
			blk/node
		]
		p: stack
		until [
			if node = as node! p/value [return yes]
			p: p + 1
			p = top
		]
		no
	]
	
	detect?: func [
		value	[red-value!]
		buffer	[red-string!]
		part	[int-ptr!]
		mold?	[logic!]
		return: [logic!]
		/local
			s	 [c-string!]
			size [integer!]
	][
		either find? value [
			either mold? [
				switch TYPE_OF(value) [
					TYPE_BLOCK	[s: "[...]"				 size: 5 ]
					TYPE_PAREN	[s: "(...)"				 size: 5 ]
					TYPE_MAP	[s: "#(...)"			 size: 6 ]
					TYPE_HASH	[s: "make hash! [...]"	 size: 16]
					TYPE_OBJECT [s: "make object! [...]" size: 18]
					default		[assert false]
				]
			][
				s: "..."
				size: 3
			]
			string/concatenate-literal buffer s
			part/value: part/value - size
			yes
		][
			no
		]
	]
]

words: context [
	spec:			-1
	body:			-1
	words:			-1
	class:			-1
	logic!:			-1
	integer!:		-1
	char!:			-1
	float!:			-1
	percent!:		-1
	any-type!:		-1
	repeat:			-1
	foreach:		-1
	map-each:		-1
	remove-each:	-1
	exit*:			-1
	return*:		-1
	self:			-1
	values:			-1
	owner:			-1
	owned:			-1
	
	windows:		-1
	syllable:		-1
	macOS:			-1
	linux:			-1
	
	any*:			-1
	break*:			-1
	copy:			-1
	end:			-1
	fail:			-1
	into:			-1
	opt:			-1
	not*:			-1
	quote:			-1
	reject:			-1
	set:			-1
	skip:			-1
	some:			-1
	thru:			-1
	to:				-1
	none:			-1
	pipe:			-1
	dash:			-1
	then:			-1
	if*:			-1
	remove:			-1
	while*:			-1
	insert:			-1
	only:			-1
	collect:		-1
	keep:			-1
	pick:			-1
	ahead:			-1
	after:			-1
	x:				-1
	y:				-1
	
	_true:			-1
	_false:			-1
	_yes:			-1
	_no:			-1
	_on:			-1
	_off:			-1
	
	type:			-1
	face:			-1
	window:			-1
	offset:			-1
	key:			-1
	flag:			-1
	code:			-1
	picked:			-1
	flags:			-1
	away?:			-1
	ctrl?:			-1
	shift?:			-1
	down?:			-1
	mid-down?:		-1
	alt-down?:		-1
	aux-down?:		-1

	get:			-1
	put:			-1
	post:			-1
	head:			-1

	size:			-1
	rgb:			-1
	alpha:			-1
	argb:			-1
	
	hour:			-1
	minute:			-1
	second:			-1
	
	user:			-1
	host:			-1
	
	system:			-1
	system-global:	-1

	_body:			as red-word! 0
	_windows:		as red-word! 0
	_syllable:		as red-word! 0
	_macOS:			as red-word! 0
	_linux:			as red-word! 0
	
	_push:			as red-word! 0
	_pop:			as red-word! 0
	_fetch:			as red-word! 0
	_match:			as red-word! 0
	_iterate:		as red-word! 0
	_paren:			as red-word! 0
	_anon:			as red-word! 0
	_body:			as red-word! 0
	_end:			as red-word! 0
	_not-found:		as red-word! 0
	
	_to:			as red-word! 0
	_thru:			as red-word! 0
	_not:			as red-word! 0
	_then:			as red-word! 0
	_remove:		as red-word! 0
	_while:			as red-word! 0
	_collect:		as red-word! 0
	_keep:			as red-word! 0
	_ahead:			as red-word! 0
	_pipe:			as red-word! 0
	_any:			as red-word! 0
	_some:			as red-word! 0
	_copy:			as red-word! 0
	_opt:			as red-word! 0
	_into:			as red-word! 0
	_insert: 		as red-word! 0
	_if: 			as red-word! 0
	_quote: 		as red-word! 0
	_collect: 		as red-word! 0
	_set: 			as red-word! 0
	
	;-- modifying actions
	_change:		as red-word! 0
	_changed:		as red-word! 0
	_clear:			as red-word! 0
	_cleared:		as red-word! 0
	_set-path:		as red-word! 0
	_insert:		as red-word! 0
	_poke:			as red-word! 0
	_put:			as red-word! 0
	;_remove:		as red-word! 0
	_removed:		as red-word! 0
	_random:		as red-word! 0
	_reverse:		as red-word! 0
	_sort:			as red-word! 0
	_swap:			as red-word! 0
	_take:			as red-word! 0
	_taken:			as red-word! 0
	_move:			as red-word! 0
	_moved:			as red-word! 0
	_trim:			as red-word! 0

	;-- modifying natives
	_uppercase:		as red-word! 0
	_lowercase:		as red-word! 0
	_checksum:		as red-word! 0
	
	_on-parse-event: as red-word! 0
	_on-change*:	 as red-word! 0
	_on-deep-change*: as red-word! 0
	
	_type:			as red-word! 0
	_id:			as red-word! 0
	_try:			as red-word! 0
	_catch:			as red-word! 0
	_name:			as red-word! 0
	
	_multiply:		as red-word! 0
	_browse:		as red-word! 0
	
	errors: context [
		throw:		as red-word! 0
		note:		as red-word! 0
		syntax:		as red-word! 0
		script:		as red-word! 0
		math:		as red-word! 0
		access:		as red-word! 0
		user:		as red-word! 0
		internal:	as red-word! 0
	]

	build: does [
		spec:			symbol/make "spec"
		body:			symbol/make "body"
		words:			symbol/make "words"
		class:			symbol/make "class"
		logic!:			symbol/make "logic!"
		integer!:		symbol/make "integer!"
		char!:			symbol/make "char!"
		float!:			symbol/make "float!"
		percent!:		symbol/make "percent!"
		any-type!:		symbol/make "any-type!"
		exit*:			symbol/make "exit"
		return*:		symbol/make "return"

		windows:		symbol/make "Windows"
		syllable:		symbol/make "Syllable"
		macOS:			symbol/make "macOS"
		linux:			symbol/make "Linux"
		
		repeat:			symbol/make "repeat"
		foreach:		symbol/make "foreach"
		map-each:		symbol/make "map-each"
		remove-each:	symbol/make "remove-each"
		
		any*:			symbol/make "any"
		break*:			symbol/make "break"
		copy:			symbol/make "copy"
		end:			symbol/make "end"
		fail:			symbol/make "fail"
		into:			symbol/make "into"
		opt:			symbol/make "opt"
		not*:			symbol/make "not"
		quote:			symbol/make "quote"
		reject:			symbol/make "reject"
		set:			symbol/make "set"
		skip:			symbol/make "skip"
		some:			symbol/make "some"
		thru:			symbol/make "thru"
		to:				symbol/make "to"
		none:			symbol/make "none"
		pipe:			symbol/make "|"
		dash:			symbol/make "-"
		then:			symbol/make "then"
		if*:			symbol/make "if"
		remove:			symbol/make "remove"
		while*:			symbol/make "while"
		insert:			symbol/make "insert"
		only:			symbol/make "only"
		collect:		symbol/make "collect"
		keep:			symbol/make "keep"
		pick:			symbol/make "pick"
		ahead:			symbol/make "ahead"
		after:			symbol/make "after"

		x:				symbol/make "x"
		y:				symbol/make "y"
		
		self:			symbol/make "self"
		values:			symbol/make "values"
		owner:			symbol/make "owner"
		owned:			symbol/make "owned"

		_true:			symbol/make "true"
		_false:			symbol/make "false"
		_yes:			symbol/make "yes"
		_no:			symbol/make "no"
		_on:			symbol/make "on"
		_off:			symbol/make "off"
		
		type:			symbol/make "type"
		face:			symbol/make "face"
		window:			symbol/make "window"
		offset:			symbol/make "offset"
		key:			symbol/make "key"
		flag:			symbol/make "flag"
		code:			symbol/make "code"
		picked:			symbol/make "picked"
		flags:			symbol/make "flags"
		away?:			symbol/make "away?"
		ctrl?:			symbol/make "ctrl?"
		shift?:			symbol/make "shift?"
		down?:			symbol/make "down?"
		mid-down?:		symbol/make "mid-down?"
		alt-down?:		symbol/make "alt-down?"
		aux-down?:		symbol/make "aux-down?"

		get:			symbol/make "get"
		put:			symbol/make "put"
		post:			symbol/make "post"
		head:			symbol/make "head"

		size:			symbol/make "size"
		rgb:			symbol/make "rgb"
		alpha:			symbol/make "alpha"
		argb:			symbol/make "argb"
		
		hour:			symbol/make "hour"
		minute:			symbol/make "minute"
		second:			symbol/make "second"
		
		user:			symbol/make "user"
		host:			symbol/make "host"
		
		system:			symbol/make "system"
		system-global:	symbol/make "system-global"

		_windows:		_context/add-global windows
		_syllable:		_context/add-global syllable
		_macOS:			_context/add-global macOS
		_linux:			_context/add-global linux
		
		_to:			_context/add-global to
		_thru:			_context/add-global thru
		_not:			_context/add-global not*
		_then:			_context/add-global then
		_remove:		_context/add-global remove
		_while:			_context/add-global while*
		_collect:		_context/add-global collect
		_keep:			_context/add-global keep
		_ahead:			_context/add-global ahead
		_pipe:			_context/add-global pipe
		_any:			_context/add-global any*
		_some:			_context/add-global some
		_copy:			_context/add-global copy
		_opt:			_context/add-global opt
		_into:			_context/add-global into
		_insert: 		_context/add-global insert
		_if: 			_context/add-global if*
		_quote: 		_context/add-global quote
		_collect: 		_context/add-global collect
		_set: 			_context/add-global set
		
		;-- modifying actions
		_change:		word/load "change"
		_changed:		word/load "changed"
		_clear:			word/load "clear"
		_cleared:		word/load "cleared"
		_set-path:		word/load "set-path"
		_insert:		word/load "insert"
		_move:			word/load "move"
		_moved:			word/load "moved"
		_poke:			word/load "poke"
		_put:			word/load "put"
		;_remove:		word/load "remove"
		_removed:		word/load "removed"
		_random:		word/load "random"
		_reverse:		word/load "reverse"
		_sort:			word/load "sort"
		_swap:			word/load "swap"
		_take:			word/load "take"
		_taken:			word/load "taken"
		_trim:			word/load "trim"

		;-- modifying natives
		_uppercase:		word/load "uppercase"
		_lowercase:		word/load "lowercase"
		_checksum:		word/load "checksum"
		
		_push:			word/load "push"
		_pop:			word/load "pop"
		_fetch:			word/load "fetch"
		_match:			word/load "match"
		_iterate:		word/load "iterate"
		_paren:			word/load "paren"
		_anon:			word/load "<anon>"				;-- internal usage
		_body:			word/load "<body>"				;-- internal usage
		_not-found:		word/load "<not-found>"			;-- internal usage
		_end:			_context/add-global end
		
		_on-parse-event: word/load "on-parse-event"
		_on-change*:	 word/load "on-change*"
		_on-deep-change*: word/load "on-deep-change*"
		
		_type:			word/load "type"
		_id:			word/load "id"
		_try:			word/load "try"
		_catch:			word/load "catch"
		_name:			word/load "name"
		
		_multiply:		word/load "multiply"
		_browse:		word/load "browse"
		
		errors/throw:	 word/load "throw"
		errors/note:	 word/load "note"
		errors/syntax:	 word/load "syntax"
		errors/script:	 word/load "script"
		errors/math:	 word/load "math"
		errors/access:	 word/load "access"
		errors/user:	 word/load "user"
		errors/internal: word/load "internal"
		
	]
]

refinements: context [
	local: 		as red-refinement! 0
	extern: 	as red-refinement! 0

	_part:		as red-refinement! 0
	_skip:		as red-refinement! 0

	build: does [
		local:	refinement/load "local"
		extern:	refinement/load "extern"

		_part:	refinement/load "part"
		_skip:	refinement/load "skip"
	]
]

issues: context [
	ooo:	as red-word! 0
	
	build: does [
		ooo: issue/load "ooo"
	]
]