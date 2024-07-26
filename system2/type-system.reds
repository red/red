Red/System [
	File: 	 %type-system.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum type-conv-result! [
	conv_illegal
	conv_void
	conv_same			;-- same type
	conv_promote_ii		;-- promote int to int
	conv_promote_if		;-- promote int to float
	conv_promote_ff		;-- promote float to float
	conv_cast_ii
	conv_cast_if
	conv_cast_fi
	conv_cast_ff
]

type-system: context [
	promotable-int?: func [		;-- check if int x is promotable to int y
		x	[int-type!]
		y	[int-type!]
		return: [logic!]
	][
		if x/header = y/header [return true]
		all [
			INT_WIDTH(x) < INT_WIDTH(y)
			any [INT_SIGNED?(y) INT_SIGNED?(y) = INT_SIGNED?(x)]
		]
	]
	convert: func [				;-- convert type x to type y
		x	[rst-type!]
		y	[rst-type!]
		return: [type-conv-result!]
		/local
			int-x int-y [int-type!]
	][
		switch TYPE_KIND(x) [
			RST_TYPE_INT [
				int-x: as int-type! x
				switch TYPE_KIND(y) [
					RST_TYPE_INT	[0]
					RST_TYPE_FLOAT	[0]
					RST_TYPE_BYTE	[0]
					default [0]
				]
			]
		]
		conv_illegal
	]
]