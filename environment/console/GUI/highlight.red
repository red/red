Red [
	Title:   "Red language syntax highlight lexer"
	Author:  "Nenad Rakocevic & Xie Qingtian"
	File: 	 %highlight.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

highlight: context [
	_dst:   none
	_theme: none

	lex: func [
		event	[word!]
		input	[string! binary!]
		type	[datatype! word! none!]
		line	[integer!]
		token
		return:	[logic!]
		/local style
	][
		[scan error]
		switch event [
			scan [
				if all [type style: select _theme type][
					append _dst as-pair token/x token/y - token/x
					append _dst style
				]
			]
			error [input: next input]
		]
		false
	]

	add-styles: func [
		src		[string!]
		dst		[block! none!]
		theme	[map!]
		return: [block!]
	][
		_dst: dst
		_theme: theme
		transcode/trace src :lex
		dst
	]
]