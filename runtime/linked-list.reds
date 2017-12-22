Red/System [
	Title:	"Doubly Linked List implementation"
	Author: "Xie Qingtian"
	File: 	%linked-list.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

list-entry!: alias struct! [
	next	[list-entry!]
	prev	[list-entry!]
]

list!: alias struct! [
	next	[list-entry!]
	prev	[list-entry!]
	size	[integer!]			;-- list size
	offset	[integer!]			;-- data offset in list entry
]

list: context [

	init: func [
		list	[list!]
		offset	[integer!]
	][
		list/next: as list-entry! list
		list/prev: as list-entry! list
		list/size: 0
		list/offset: offset
	]
	
	insert: func [
		list	[list!]
		entry	[list-entry!]
	][
		insert-next list as list-entry! list entry
	]

	append: func [
		list	[list!]
		entry	[list-entry!]
	][
		insert-next list list/prev entry
	]

	insert-next: func [
		"insert an entry next to the node entry"
		list	[list!]
		node	[list-entry!]
		entry	[list-entry!]
	][
		node/next/prev: entry
		entry/next: node/next
		entry/prev: node
		node/next: entry

		list/size: list/size + 1
	]

	remove: func [
		"remove an entry next to the node entry"
		list	[list!]
		entry	[list-entry!]
	][
		remove-entry list entry/prev entry/next
	]

	remove-head: func [
		list	[list!]
	][
		remove-entry list as list-entry! list list/next/next
	]

	remove-last: func [
		list	[list!]
	][
		remove-entry list list/prev/prev as list-entry! list
	]

	remove-entry: func [
		"remove an entry between entry1 and entry2"
		list	[list!]
		entry1	[list-entry!]
		entry2	[list-entry!]
	][
		entry1/next: entry2
		entry2/prev: entry1

		list/size: list/size - 1
	]
]