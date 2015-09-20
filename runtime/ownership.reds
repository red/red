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

	set: func [
		container [red-value!]
		owner	  [red-object!]
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
print-line ["ownership/set, type: " type]
		case [
			ANY_SERIES?(type) [
				series: as red-series! container
				s: GET_BUFFER(series)
				s/flags: s/flags or flag-series-owned
probe series/node				
				slot: as red-value! _hashtable/put-key table as-integer series/node
				copy-cell container slot
				copy-cell as red-value! owner slot + 1
				
				if ANY_BLOCK?(type) [
					value: s/offset + series/head
					tail:  s/tail
					
					while [value < tail][
						set value owner
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
					
					while [value < tail][
						set value owner
						value: value + 1
					]
				]
			]
			true [0]
		]
	]
	
	check: func [
		value  [red-value!]								;-- series or object where a change occurs
		action [red-word!]								;-- type of change
		index  [integer!]								;-- start position of the change
		part   [integer!]								;-- nb of values affected
		/local
			node   [node!]
			slot   [red-value!]
			parent [red-value!]
			owner  [red-object!]
			series [red-series!]
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
		
		unless null? slot [
			parent: slot
			owner:  as red-object! slot + 1
			object/fire-on-deep owner value action index part 
		]
	]
	
	init: does [
		table: _hashtable/init size null HASH_TABLE_INTEGER 2
	]
]