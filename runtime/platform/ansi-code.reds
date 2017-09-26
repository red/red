Red/System [
	Title:   "ANSI Escape sequences support"
	Author:  "Oldes"
	File: 	 %ansi-code.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#case [
	all [sub-system = 'console OS = 'Windows] [
		#include %ansi-code-cli.reds
	]
	true [
		;this version is simplified version, which is just used to get number of chars which valid escape sequence has 
		process-ansi-sequence: func [
			str 	[byte-ptr!]
			tail	[byte-ptr!]
			unit    [integer!]
			return: [integer!]
			/local
				cp      [integer!]
				bytes   [integer!]
				state   [integer!]
		][
			cp: string/get-char str unit
			if all [
				cp <> as-integer #"["
				cp <> as-integer #"("
			][return 0]

			str: str + unit
			bytes: unit
			state: 1
			while [all [state > 0 str < tail]] [
				cp: string/get-char str unit
				str: str + unit
				bytes: bytes + unit
				switch state [
					1 [
						unless any [
							cp = as-integer #";"
							all [cp >= as-integer #"0" cp <= as-integer #"9"]
						][state: -1]
					]
					2 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 3]
							true [ state: -1 ]
						]
					]
					3 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][state: 4]
							cp = as-integer #";" [0] ;do nothing
							true [ state: -1 ]
						]
					]
					4 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 1]
							true [ state: -1 ]
						]
					]
				]
			]
			bytes
		]
	]
]
