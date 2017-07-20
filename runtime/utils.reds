Red/System [
	Title:   "Red runtime utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %utils.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#either OS = 'Windows [
	get-cmdline-args: func [
		return: [red-value!]
		/local
			args [byte-ptr!]
	][
		args: platform/GetCommandLine
		as red-value! string/load as-c-string args platform/lstrlen args UTF-16LE
	]

	list-env: func [
		return: [red-value!]							;-- return a map!
		/local
			env		[c-string!]
			str		[c-string!]
			p		[c-string!]
			blk		[red-block!]
			len		[integer!]
	][
		env: platform/GetEnvironmentStrings
		blk: null
		len: 0

		if env <> null [
			blk: block/push-only* 100
			str: env
			p: str
			while [true][
				if all [len <> 0 str/1 = #"=" str/2 = #"^@"][
					string/load-in p len blk UTF-16LE
					p: str + 2
					len: platform/lstrlen as byte-ptr! p
					string/load-in p len blk UTF-16LE
					str: p + (len * 2)
					if all [str/3 = #"^@" str/4 = #"^@"][break]
					p: str + 2
					len: -1
				]
				str: str + 2
				len: len + 1
			]
			len: block/rs-length? blk
			platform/FreeEnvironmentStrings env
		]
		as red-value! map/make-at as red-value! blk blk len
	]
][
	get-cmdline-args: func [
		return: [red-value!]
		/local
			str		[red-string!]
			args	[str-array!]
			src		[c-string!]
			s		[series!]
			cnt		[integer!]
			size	[integer!]
			cp		[integer!]
			offset	[integer!]
			delim	[integer!]
			end?	[logic!]
			ws?		[logic!]
			dq?		[logic!]
	][
		cnt: 0
		size: 4'000									;-- enough?
		str: string/rs-make-at ALLOC_TAIL(root) size
		s: GET_BUFFER(str)
		args: system/args-list
		
		until [
			src: args/item
			ws?: no
			dq?: no
			offset: string/rs-abs-length? str
			
			until [
				cnt: unicode/utf8-char-size? as-integer src/1
				cp: unicode/decode-utf8-char src :cnt
				switch cp [
					#" "	[ws?: yes]
					#"^""	[dq?: yes]
					default [0]
				]
				s: string/append-char s cp
				src: src + cnt
				size: size - 1
				any [src/1 = null-byte zero? size]
			]
			
			case [
				ws? [
					delim: as-integer either dq? [#"'"][#"^""]
					s: string/insert-char s offset delim
					s: string/append-char s delim
				]
				dq? [
					s: string/insert-char s offset as-integer #"'"
					s: string/append-char s delim  as-integer #"'"
				]
				true [0]
			]
			args: args + 1
			end?: null? args/item
			unless end? [s: string/append-char s as-integer #" "] ;-- add a space as separation
			end?
		]
		as red-value! str
	]

	list-env: func [
		return: [red-value!]							;-- return a map!
		/local
			handle	[integer!]
			p-int	[int-ptr!]
			env		[int-ptr!]
			str		[c-string!]
			p		[c-string!]
			blk		[red-block!]
			len		[integer!]
	][
		env: as int-ptr! platform/environ
		blk: null
		len: 0

		if env <> null [
			blk: block/push-only* 100
			while [
				str: as c-string! env/1
				str <> null
			][
				len: 0
				p: str
				while [true][
					if p/1 = #"=" [
						string/load-in str len blk UTF-8
						str: p + 1
						string/load-in str length? str blk UTF-8
						break
					]
					len: len + 1
					p: p + 1
				]
				env: env + 1
			]
			len: block/rs-length? blk
		]
		as red-value! map/make-at as red-value! blk blk len
	]
]

check-arg-type: func [
	arg		[red-value!]
	type	[integer!]
][
	if TYPE_OF(arg) <> type [
		fire [TO_ERROR(script invalid-arg) arg]
	]
]