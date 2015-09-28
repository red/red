Red/System [
	Title:   "Red ownership functions"
	Author:  "Nenad Rakocevic"
	File: 	 %ownership.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ownership: context [

	size:	1000
	table:	declare node!

	unbind: func [
		value [red-value!]
		/local
			owner  [red-object!]
			series [red-series!]
			tail   [red-value!]
			node   [node!]
			type   [integer!]
			s	   [series!]
	][
		type: TYPE_OF(value)
		case [
			type = TYPE_OBJECT [
				owner: as red-object! value
				_hashtable/delete-key table as-integer owner/ctx
				;@@ free object's fields and unflag it
			]
			ANY_SERIES?(type) [
				series: as red-series! value
				s: GET_BUFFER(series)
				_hashtable/delete-key table as-integer series/node
				s/flags: s/flags and not flag-series-owned
				
				if ANY_BLOCK?(type) [
					value: s/offset + series/head
					tail:  s/tail

					while [value < tail][
						unbind value
						value: value + 1
					]
				]
			]
			true [assert false]
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
			type   [integer!]
			s	   [series!]
	][
		type: TYPE_OF(container)
		case [
			ANY_SERIES?(type) [
				series: as red-series! container
				s: GET_BUFFER(series)
				
				if s/flags and flag-series-owned = 0 [	;-- process series if not already owned
					s/flags: s/flags or flag-series-owned

					slot: as red-value! _hashtable/put-key table as-integer series/node
					copy-cell container slot
					copy-cell as red-value! owner slot + 1
					either null? word [
						slot: slot + 2
						slot/header: TYPE_NONE
					][
						copy-cell as red-value! word slot + 2
					]
				]
				if ANY_BLOCK?(type) [
					value: s/offset + series/head
					tail:  s/tail
					
					while [value < tail][
						bind value owner null
						value: value + 1
					]
				]
			]
			type = TYPE_OBJECT [
				obj: as red-object! container
				ctx: GET_CTX(obj)
				
				if ctx/header and flag-owner = 0 [		;-- stop if another owner is met
					ctx/header: ctx/header or flag-owner
					s: as series! ctx/values/value
					
					value: s/offset
					tail:  s/tail
					
					s: as series! ctx/symbols/value
					word: as red-word! s/offset
					
					while [value < tail][
						bind value owner word
						value: value + 1
						word: word + 1
					]
				]
			]
			true [0]
		]
	]
	
	owned?: func [
		node	[node!]
		return: [red-object!]							;-- returns null if not found
		/local
			slot   [red-value!]
	][
		slot: _hashtable/get-value table as-integer node
		if null? slot [return null]
		as red-object! slot + 1
	]
	
	check: func [
		value  [red-value!]								;-- series or object where a change occurs
		action [red-word!]								;-- series: type of change, object: field
		index  [integer!]								;-- start position of the change
		part   [integer!]								;-- nb of values affected
		/local
			node   [node!]
			slot   [red-value!]
			parent [red-value!]
			owner  [red-object!]
			ctx	   [red-context!]
			series [red-series!]
			word   [red-word!]
			type   [integer!]
	][
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
			true [assert false]
		]
		slot: _hashtable/get-value table as-integer node
		
		if all [null? slot type = TYPE_OBJECT][
			ctx: GET_CTX(owner)
			if ctx/header and flag-owner <> 0 [			;-- test if object is an owner
				value: as red-value! owner
				word: action
			]
		]
		
		unless null? slot [
			parent: slot
			owner:  as red-object! slot + 1
			word:	as red-word! slot + 2
			object/fire-on-deep owner word value action index part 
		]
	]
	
	init: does [
		table: _hashtable/init size null HASH_TABLE_INTEGER 3
	]
]