Red [
	Title:   "Native scheme example"
	Author:  "Nenad Rakocevic"
	File: 	 %simple-scheme.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [
	custom-device: context [

		open: func [
			port	[red-object!]
			new?	[logic!]
			read?	[logic!]
			write?	[logic!]
			seek?	[logic!]
			allow	[red-value!]
			return:	[red-value!]
		][
			probe "native port/open"
			as red-value! port
		]
		
		close: func [
			port	[red-object!]
			return:	[red-value!]
		][
			probe "native port/close"
			as red-value! port
		]

		table: [
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			:close
			null			;delete
			null			;modify
			:open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]	
	]
]

actor: #system [handle/push custom-device/table]

register-scheme/native make system/standard/scheme [
	name: 'custom
	title: "Example of native scheme implementation"
] actor

p: open custom://
?? p
;insert p none
close p