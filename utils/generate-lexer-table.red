Red [
	Title:   "Generates low-level lexer table"
	Author:  "Nenad Rakocevic"
	File: 	 %generate-lexer-tables.r
	Tabs:	 4
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Note: {
		Outputs: %runtime/lexer-transitions.reds
	}
]

context [
	states: [
	;-- State ------------- Predicted type ----
		S_START				TYPE_VALUE			;-- 0
		S_LINE_CMT			TYPE_VALUE			;-- 1
		S_LINE_STR			TYPE_STRING			;-- 2
		S_SKIP_STR			TYPE_STRING			;-- 3
		S_M_STRING			TYPE_STRING			;-- 4
		S_SKIP_MSTR			TYPE_STRING			;-- 5
		S_FILE_1ST			TYPE_FILE			;-- 6
		S_FILE				TYPE_FILE			;-- 7
		S_FILE_HEX1			TYPE_FILE			;-- 8
		S_FILE_HEX2			TYPE_FILE			;-- 9
		S_FILE_STR			TYPE_FILE			;-- 10
		S_SLASH				TYPE_REFINEMENT		;-- 11
		S_SLASH_N			TYPE_WORD			;-- 12
		S_SHARP				TYPE_ISSUE			;-- 13
		S_BINARY			TYPE_BINARY			;-- 14
		S_LINE_CMT2			TYPE_VALUE			;-- 15
		S_CHAR				TYPE_CHAR			;-- 16
		S_SKIP_CHAR			TYPE_CHAR			;-- 17
		S_CONSTRUCT			TYPE_VALUE			;-- 18
		S_ISSUE				TYPE_ISSUE			;-- 19
		S_NUMBER			TYPE_INTEGER		;-- 20
		S_DOTNUM			TYPE_FLOAT			;-- 21
		S_DECIMAL			TYPE_FLOAT			;-- 22
		S_DECEXP			TYPE_FLOAT			;--	23
		S_DECX				TYPE_FLOAT			;-- 24
		S_DEC_SPECIAL		TYPE_FLOAT			;-- 25
		S_TUPLE				TYPE_TUPLE			;-- 26
		S_DATE				TYPE_DATE			;-- 27
		S_TIME_1ST			TYPE_TIME			;-- 28
		S_TIME				TYPE_TIME			;-- 29
		S_PAIR_1ST			TYPE_PAIR			;-- 30
		S_PAIR				TYPE_PAIR			;-- 31
		S_MONEY_1ST			TYPE_MONEY			;-- 32
		S_MONEY				TYPE_MONEY			;-- 33
		S_MONEY_DEC			TYPE_MONEY			;-- 34
		S_HEX				TYPE_INTEGER		;-- 35
		S_HEX_END			TYPE_WORD			;--	36
		S_HEX_END2			TYPE_INTEGER		;--	37
		S_LESSER			TYPE_TAG			;-- 38
		S_TAG				TYPE_TAG			;-- 39
		S_TAG_STR			TYPE_TAG			;-- 40
		S_TAG_STR2			TYPE_TAG			;-- 41
		S_SIGN				TYPE_WORD			;-- 42
		S_DOTWORD			TYPE_WORD			;-- 43
		S_DOTDEC			TYPE_FLOAT			;-- 44
		S_WORD_1ST			TYPE_WORD			;--	45
		S_WORD				TYPE_WORD			;-- 46
		S_WORDSET			TYPE_SET_WORD		;-- 47
		S_URL				TYPE_URL			;-- 48
		S_EMAIL				TYPE_EMAIL			;-- 49
		S_PATH				TYPE_PATH			;-- 50
		S_PATH_NUM			TYPE_INTEGER		;--	51
		S_PATH_W1ST			TYPE_WORD			;-- 52
		S_PATH_WORD			TYPE_WORD			;-- 53
		S_PATH_SHARP		TYPE_ISSUE			;--	54
		S_PATH_SIGN			TYPE_WORD			;--	55
		--EXIT_STATES--		-					;-- 56
		T_EOF				-					;-- 57
		T_ERROR				-					;-- 58
		T_BLK_OP			-					;-- 59
		T_BLK_CL			-					;-- 60
		T_PAR_OP			-					;-- 61
		T_PAR_CL			-					;-- 62
		T_MSTR_OP			-					;-- 63
		T_MSTR_CL			TYPE_STRING			;-- 64
		T_MAP_OP			-					;-- 65
		T_PATH				-					;-- 66
		T_CONS_MK			-					;-- 67
		T_CMT				-					;-- 68
		T_INTEGER			TYPE_INTEGER		;-- 69 
		T_WORD				-					;-- 70
		T_REFINE			TYPE_REFINEMENT		;-- 71
		T_CHAR				TYPE_CHAR			;-- 72
		T_ISSUE				TYPE_ISSUE			;-- 73
		T_STRING			TYPE_STRING			;-- 74
		T_FILE				TYPE_FILE			;-- 75
		T_BINARY			TYPE_BINARY			;-- 76
		T_PERCENT			TYPE_PERCENT		;-- 77
		T_FLOAT				TYPE_FLOAT			;-- 78
		T_FLOAT_SP			TYPE_FLOAT			;-- 79
		T_TUPLE				TYPE_TUPLE			;-- 80
		T_DATE				TYPE_DATE			;-- 81
		T_PAIR				TYPE_PAIR			;-- 82
		T_TIME				TYPE_TIME			;-- 83
		T_MONEY				TYPE_MONEY			;-- 84
		T_TAG				TYPE_TAG			;-- 85
		T_URL				TYPE_URL			;-- 86
		T_EMAIL				TYPE_EMAIL			;-- 87
		T_HEX				TYPE_INTEGER		;-- 88
	]

	CSV-table: %../docs/lexer/lexer-FSM.csv
	;-- Read states from CSV file
	csv: read CSV-table

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 > b/2]

	;-- Decode CSV
	matrix: load-csv/with read CSV-table first sep

	;-- Generate the lexer table content
	table: make binary! 2000
	
	foreach line next matrix [
		out: make block! 50	
		foreach s next line [
			either pos: find/skip states to-word s  2[
				append out (index? pos) + 1 / 2 - 1
			][
				do make error! form reduce ["Error: state" s "not found"]
			]
		]
		append/only table out
	]
	
	;-- Generate the type-table content
	type-table: make binary! 2000
	types: load %../runtime/macros.reds
	types: select types 'datatypes!
	
	foreach [s t] states [append type-table either t = '- [0][(index? find types t) - 1]]

	;-- Generate the ending-skip table content
	ending-table: make binary! 2000
	list: skip find states '--EXIT_STATES-- 2
	
	foreach [s t] list [
		append ending-table pick 1x0 to-logic find [
			T_STRING T_BINARY T_PERCENT T_TAG
		] s
	]
	
	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(extract states 2)
	]
	
	ending-skip: (ending-table)
	
	type-table: (type-table)
		
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()