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
		return: [int-ptr!]
	][
		red/_hashtable/rs-init size
	]

	put: func [
		m	[int-ptr!]
		key [integer!]
		val [int-ptr!]
	][
		red/_hashtable/rs-put m key as-integer val
	]

	get: func [
		m	[int-ptr!]
		key [integer!]
		return: [ptr-ptr!]
	][
		as ptr-ptr! red/_hashtable/rs-get m key
	]
]