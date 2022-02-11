Red [
	Title:   "Localization core functions and data"
	Author:  @hiiamboris
	Rights:  "Copyright (C) 2021 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
]

#include %numbering-systems.red
#include %plural.red

system/locale/tools: context [
	#either config/OS = 'Windows [
		;; setlocale is useless on Windows, will just always return "C", so have to use winape
		#system [
			#define LOCALE_NAME_MAX_LENGTH 85			;-- in Wchars
			#import [
				"kernel32.dll" stdcall [
					GetUserDefaultLocaleName: "GetUserDefaultLocaleName" [
						lpLocaleName  [byte-ptr!]
						cchLocaleName [integer!]
						return:       [integer!]
					]
				]
			]
		]
		
		get-user-locale-id*: routine [
			return: [string!]
			/local wchars [byte-ptr!] len [integer!] str [red-string!]
		][
			wchars: allocate LOCALE_NAME_MAX_LENGTH * 2
			len: GetUserDefaultLocaleName wchars LOCALE_NAME_MAX_LENGTH
			assert len > 0
			str: string/load as c-string! wchars len - 1 UTF-16LE
			free wchars
			str
		]
	][
		#system [
			#define __LC_CTYPE 0
			#import [									;@@ why doesn't it import it from the runtime?
				LIBC-file cdecl [
					setlocale: "setlocale" [
						category	[integer!]
						locale		[c-string!]
						return:		[c-string!]
					]
				]
			]
		]
		
		get-user-locale-id*: routine [
			return: [string!]
			/local s [c-string!]
		][
			s: setlocale __LC_CTYPE null
			string/load s length? s UTF-8
		]
	]		

	get-user-locale-id: function [/local lang regn] [	;-- returns 'en_US or something
		lower: charset [#"a" - #"z"]
		upper: charset [#"A" - #"Z"]
		non-alpha: negate union lower upper
		sep:   [#"_" | #"-"]
		=language=: [2 lower ahead [non-alpha | end]]
		=region=:   [2 upper ahead [non-alpha | end]]
		parse s: get-user-locale-id* [
			["C" | "POSIX"] opt ["." to end] end (return 'red)	;-- portable POSIX locale, 'red' is our portable locale
		|	copy lang =language= opt [to =region= copy regn =region=] (
				if regn [repend lang ["_" regn]]
				return to word! lang
			)
		|	(return 'red)										;-- unindentified, default to 'red'
		]
	]
	
	get-best-locale-id: function [] [					;-- returns best locale from those supported
		loc: get-user-locale-id
		case [
			system/locale/list/:loc [loc]
			all [
				formed: form loc
				clear find loc "_"
				lang: to word! formed
				system/locale/list/:lang 
			] [lang]
			'fallback ['red]
		]
	]
	
	inherit: function [src dst] [						;-- links data between maps without override
		foreach [key srcval] src [
			case [
				not find dst key [dst/:key: srcval]		;-- carry over as reference when possible
				all [map? dst/:key  map? srcval] [
					inherit srcval dst/:key
				]
			]
		]
		foreach key keys-of dst [
			if 'unset == dst/:key [remove/key dst key]	;@@ this should be real #[unset] but it won't compile #4126
		]
	]

	;; useful when we want to use a locale without loading it as default
	expand-locale: function [
		"Expand given locale from minimized form into a working state"
		name [word!]
	][
		loc: system/locale/list/:name
		unless loc/parent [exit]						;-- already expanded
		
		expand-locale loc/parent
		inherit system/locale/list/(loc/parent) loc
		remove/key loc 'parent							;-- mark as expanded
	]
	
	load-locale: function [
		"Load given locale as default into system/locale"
		name [word!]
	][
		expand-locale name
		sl: system/locale
		unless data: sl/list/:name [
			do make error! rejoin ["Data for locale '" name "' is not loaded"]
		]
		foreach [key val] data [if word: in sl key [set word val]]
		sl/locale: name
		set  bind [language region] sl  split form name #"_"
		sl/name: copy data/lang-name
		if sl/region [repend sl/name [" (" data/region-name ")"]]
		sl/currencies/names: data/currency-names
		;; for R2 compatibility:
		sl/months: data/calendar/standalone/months/full
		m: data/calendar/standalone/days/full
		sl/days: reduce [m/mon m/tue m/wed m/thu m/fri m/sat m/sun]		;-- in R2 it started from monday always
		()												;-- no return value
	]
	
	system/words/expand-locale: :expand-locale
	system/words/load-locale:   :load-locale
]

