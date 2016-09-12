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
			str	 [red-string!]
			args [str-array!]
			new	 [c-string!]
			dst	 [c-string!]
			tail [c-string!]
			s	 [c-string!]
			size [integer!]
	][
		size: 10'000									;-- enough?
		new: as-c-string allocate size
		args: system/args-list 
		dst: new
		tail: new + size - 2							;-- leaving space for a terminal null

		until [
			s: args/item

			dst/1: #"^""
			dst: dst + 1
			until [
				dst/1: s/1
				dst: dst + 1
				s: s + 1
				any [s/1 = null-byte dst = tail]
			]
			dst/1: #"^""
			dst/2: #" "
			dst: dst + 2
			args: args + 1 
			any [args/item = null dst >= tail]
		]
		dst: dst - 1
		dst/1: null-byte
		str: string/load new length? new UTF-8
		free as byte-ptr! new
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
		env: platform/environ
		if null? env [
			handle: platform/dlopen LIBC-file RTLD_LAZY
			p-int: platform/dlsym handle "environ"
			env: as int-ptr! p-int/value
			platform/environ: env
		]

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