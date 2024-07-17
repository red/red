Red/System [
	Title:   "Hash Map"
	File: 	 %hashmap.red
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"	
]

hashmap: context [
	make: func [
		size	[integer!]
		return: [node!]
	][
		red/_hashtable/init size null 1 1
	]

	put: func [
		m	[node!]
		key [cell!]
		val [int-ptr!]
	][
		
	]
]