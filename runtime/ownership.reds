Red/System [
	Title:   "Red ownership functions"
	Author:  "Nenad Rakocevic"
	File: 	 %ownership.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ownership: context [

	size:	1000
	table:	as node! 0

	unbind: func [
		value [red-value!]
		/local
			obj    [red-object!]
			series [red-series!]
			tail   [red-value!]
			ctx	   [red-context!]
			bits   [red-bitset!]
			node   [node!]
			type   [integer!]
			s	   [series!]
	][
		type: TYPE_OF(value)
		case [
			type = TYPE_OBJECT [
				obj: as red-object! value
				if cycles/find? obj/ctx [exit]
				ctx: GET_CTX(obj)

				if ctx/header and flag-owner = 0 [		;-- stop if another owner is met
					s: as series! ctx/values/value
					value: s/offset
					tail:  s/tail
					cycles/push obj/ctx

					while [value < tail][
						unbind value
						value: value + 1
					]
					cycles/pop
				]
			]
			ANY_SERIES?(type) [
				series: as red-series! value
				node: series/node
				
				either type = TYPE_IMAGE [
					series/header: series/header and not flag-owned
				][
					s: GET_BUFFER(series)
					s/flags: s/flags and not flag-series-owned
				]
				value: _hashtable/get-value table as-integer node
				unless null? value [
					_hashtable/delete-key table as-integer node

					if ANY_BLOCK?(type) [
						value: s/offset + series/head
						tail:  s/tail

						while [value < tail][
							unbind value
							value: value + 1
						]
					]
				]
			]
			type = TYPE_BITSET [
				bits: as red-bitset! value
				node: bits/node
				s: GET_BUFFER(bits)
				s/flags: s/flags and not flag-series-owned
				value: _hashtable/get-value table as-integer node
				unless null? value [_hashtable/delete-key table as-integer node]
			]
			true [0]
		]
	]
	
	unbind-each: func [
		list  [red-block!]
		index [integer!]
		nb	  [integer!]
		/local
			value [red-value!]
			s	  [series!]
	][
		s: GET_BUFFER(list)
		value: s/offset + index
		
		loop nb [
			unbind value
			value: value + 1
		]
	]

	bind: func [
		container [red-value!]
		owner	  [red-object!]
		word	  [red-word!]
		/local
			value  [red-value!]
			tail   [red-value!]
			slot   [red-value!]
			obj	   [red-object!]
			ctx	   [red-context!]
			series [red-series!]
			bits   [red-bitset!]
			type   [integer!]
			s	   [series!]
			put?   [logic!]
	][
		type: TYPE_OF(container)
		case [
			ANY_SERIES?(type) [
				put?: no
				series: as red-series! container
				either type = TYPE_IMAGE [
					if series/header and flag-owned = 0 [
						series/header: series/header or flag-owned
						put?: yes
					]
				][
					s: GET_BUFFER(series)
					if s/flags and flag-series-owned = 0 [
						s/flags: s/flags or flag-series-owned
						put?: yes
					]
				]

				if put? [								;-- process series if not already owned
					slot: as red-value! _hashtable/put-key table as-integer series/node
					copy-cell container slot
					copy-cell as red-value! owner slot + 1
					copy-cell as red-value! word  slot + 2
				]
				if ANY_BLOCK?(type) [
					if cycles/find? series/node [exit]
					value: s/offset + series/head
					tail:  s/tail
					cycles/push series/node
					
					while [value < tail][
						bind value owner word
						value: value + 1
					]
					cycles/pop
				]
			]
			type = TYPE_BITSET [
				bits: as red-bitset! container
				s: GET_BUFFER(bits)
				if s/flags and flag-series-owned = 0 [
					s/flags: s/flags or flag-series-owned
					slot: as red-value! _hashtable/put-key table as-integer bits/node
					copy-cell container slot
					copy-cell as red-value! owner slot + 1
					copy-cell as red-value! word  slot + 2
				]
			]
			type = TYPE_OBJECT [
				obj: as red-object! container
				ctx: GET_CTX(obj)
				
				if ctx/header and flag-owner = 0 [		;-- stop if another owner is met
					if cycles/find? ctx/values [exit]
					s: as series! ctx/values/value
					
					value: s/offset
					tail:  s/tail
					cycles/push ctx/values
					
					s: _hashtable/get-ctx-words ctx
					word: as red-word! s/offset
					
					while [value < tail][
						obj: as red-object! value
						if any [
							TYPE_OF(value) <> TYPE_OBJECT
							obj/ctx <> owner/ctx		;-- avoid infinite recursion (#3253)
						][
							bind value owner word
						]
						value: value + 1
						word: word + 1
					]
					cycles/pop
				]
			]
			true [0]
		]
	]
	
	set-owner: func [
		container [red-value!]
		owner	  [red-object!]
		word	  [red-word!]
		/local
			ctx	  [red-context!]
	][
		assert TYPE_OF(owner) = TYPE_OBJECT
		bind container owner word
		ctx: GET_CTX(owner)
		ctx/header: ctx/header or flag-owner
	]
	
	owned?: func [
		node	[node!]
		return: [red-object!]							;-- returns null if not found
		/local
			slot [red-value!]
	][
		slot: _hashtable/get-value table as-integer node
		if null? slot [return null]
		as red-object! slot + 1
	]
	
	check: func [
		value   [red-value!]							;-- series or object where a change occurs
		action  [red-word!]								;-- series: type of change, object: field
		new	    [red-value!]							;-- newly inserted value or null
		index   [integer!]								;-- start position of the change
		part    [integer!]								;-- nb of values affected
		return: [logic!]								;-- TRUE: value is owned
		/local
			node   [node!]
			slot   [red-value!]
			owner  [red-object!]
			series [red-series!]
			bits   [red-bitset!]
			word   [red-word!]
			type   [integer!]
	][
		;@@ check owned flag first
		;@@ image! use a different flag in series/header than other series
		type: TYPE_OF(value)
		case [
			type = TYPE_OBJECT [
				owner: as red-object! value
				node: owner/ctx
			]
			ANY_SERIES?(type) [
				series: as red-series! value
				node: series/node
			]
			type = TYPE_BITSET [
				bits: as red-bitset! value
				node: bits/node
			]
			true [assert false]
		]
		slot: _hashtable/get-value table as-integer node
		
		either null? slot [false][
			owner:  as red-object! slot + 1
			word:	as red-word! slot + 2
			if null? owner/on-set [return false]
			object/fire-on-deep owner word value action new index part
			true
		]
	]
	
	init: does [
		table: _hashtable/init size null HASH_TABLE_OWNERSHIP 3
	]
]