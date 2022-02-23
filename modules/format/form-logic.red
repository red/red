Red [
	Title:       "Form-logic function"
	Description: https://github.com/hiiamboris/red-formatting/discussions/12
	Author:      [@hiiamboris @greggirwin]
	Rights:      "Copyright (C) 2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
]


formatting/logic-formats: #(
	true-false ["True" "False"]
	on-off     ["On" "Off"]
	yes-no     ["Yes" "No"]
	YN         ["Y" "N"]
)

;@@ this deserves to be global, but first we will need to design it
;@@ right now it's just an adhoc helper
;@@ TODO: allow warnings when no translation is found
formatting/translate: function [
	"Return translation of a string"
	string [string!] "Returned as is if no translation is found"
	/in locale [word! none!] "Locale to translate into"
][
	locale: system/locale/tools/expand-locale locale
	any [
		select system/locale/list/:locale/strings string
		string
	]
]

formatting/form-logic: form-logic: function [
	"Format a logic value as a string"
	value [logic!]
	fmt   [word! string! block!] {One of [true-false on-off yes-no YN] or custom ["True" "False"] format}
	/in locale [word! none!] "Locale to express value in"
][
	fmts: formatting/logic-formats
	if word? fmt [										;-- Named formats
		fmt: any [
			select fmts fmt
			do make error! rejoin ["Unknown named format: " fmt]
		]
	]
	if 2 <> length? fmt [
		do make error! rejoin ["Format " mold fmt " must contain 2 values"]
	]
	formatting/translate/in form pick fmt value locale	;-- form is used here to support custom values
]

#assert [
	fmt-en: func [val fmt] [formatting/form-logic/in val fmt 'en_US] 
	fmt-ru: func [val fmt] [formatting/form-logic/in val fmt 'ru_RU]
	
	"True"  = fmt-en yes 'true-false 
	"False" = fmt-en no  'true-false 
	"Yes"   = fmt-en yes 'yes-no
	"No"    = fmt-en no  'yes-no
	"On"    = fmt-en yes 'on-off
	"Off"   = fmt-en no  'on-off
	"Y"     = fmt-en yes 'YN
	"N"     = fmt-en no  'YN
	"1"     = fmt-en yes "10"
	"0"     = fmt-en no  "10"
	"RIGHT" = fmt-en yes ["RIGHT" "WRONG"]
	"WRONG" = fmt-en no  ["RIGHT" "WRONG"]
	
	"Вкл."  = fmt-ru yes 'on-off
	"Выкл." = fmt-ru no  'on-off
	"Да"    = fmt-ru yes 'YN
	"Нет"   = fmt-ru no  'YN
]