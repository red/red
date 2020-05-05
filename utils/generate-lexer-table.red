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
		S_HDPER_ST			TYPE_STRING			;--	11
		S_HERDOC_ST			TYPE_STRING			;--	12
		S_HDPER_C0			TYPE_STRING			;--	13
		S_HDPER_CL			TYPE_STRING			;--	14
		S_SLASH				TYPE_REFINEMENT		;-- 15
		S_SLASH_N			TYPE_WORD			;-- 16
		S_SHARP				TYPE_ISSUE			;-- 17
		S_BINARY			TYPE_BINARY			;-- 18
		S_LINE_CMT2			TYPE_VALUE			;-- 19
		S_CHAR				TYPE_CHAR			;-- 20
		S_SKIP_CHAR			TYPE_CHAR			;-- 21
		S_CONSTRUCT			TYPE_VALUE			;-- 22
		S_ISSUE				TYPE_ISSUE			;-- 23
		S_NUMBER			TYPE_INTEGER		;-- 24
		S_DOTNUM			TYPE_FLOAT			;-- 25
		S_DECIMAL			TYPE_FLOAT			;-- 26
		S_DECEXP			TYPE_FLOAT			;--	27
		S_DECX				TYPE_FLOAT			;-- 28
		S_DEC_SPECIAL		TYPE_FLOAT			;-- 29
		S_TUPLE				TYPE_TUPLE			;-- 30
		S_DATE				TYPE_DATE			;-- 31
		S_TIME_1ST			TYPE_TIME			;-- 32
		S_TIME				TYPE_TIME			;-- 33
		S_PAIR_1ST			TYPE_PAIR			;-- 34
		S_PAIR				TYPE_PAIR			;-- 35
		S_MONEY_1ST			TYPE_MONEY			;-- 36
		S_MONEY				TYPE_MONEY			;-- 37
		S_MONEY_DEC			TYPE_MONEY			;-- 38
		S_HEX				TYPE_INTEGER		;-- 39
		S_HEX_END			TYPE_WORD			;--	40
		S_HEX_END2			TYPE_INTEGER		;--	41
		S_LESSER			TYPE_TAG			;-- 42
		S_TAG				TYPE_TAG			;-- 43
		S_TAG_STR			TYPE_TAG			;-- 44
		S_TAG_STR2			TYPE_TAG			;-- 45
		S_SIGN				TYPE_WORD			;-- 46
		S_DOTWORD			TYPE_WORD			;-- 47
		S_DOTDEC			TYPE_FLOAT			;-- 48
		S_WORD_1ST			TYPE_WORD			;--	49
		S_WORD				TYPE_WORD			;-- 50
		S_WORDSET			TYPE_SET_WORD		;-- 51
		S_PERCENT			TYPE_WORD			;--	52
		S_URL				TYPE_URL			;-- 53
		S_EMAIL				TYPE_EMAIL			;-- 54
		S_REF				TYPE_REF			;-- 55
		S_PATH				TYPE_PATH			;-- 56
		S_PATH_NUM			TYPE_INTEGER		;--	57
		S_PATH_W1ST			TYPE_WORD			;-- 58
		S_PATH_WORD			TYPE_WORD			;-- 59
		S_PATH_SHARP		TYPE_ISSUE			;--	60
		S_PATH_SIGN			TYPE_WORD			;--	61
		--EXIT_STATES--		-					;-- 62
		T_EOF				-					;-- 63
		T_ERROR				TYPE_ERROR			;-- 64
		T_BLK_OP			-					;-- 65
		T_BLK_CL			-					;-- 66
		T_PAR_OP			-					;-- 67
		T_PAR_CL			-					;-- 68
		T_MSTR_OP			-					;-- 69
		T_MSTR_CL			TYPE_STRING			;-- 70
		T_MAP_OP			-					;-- 71
		T_PATH				-					;-- 72
		T_CONS_MK			-					;-- 73
		T_CMT				-					;-- 74
		T_STRING			TYPE_STRING			;-- 75
		T_WORD				TYPE_WORD			;-- 76
		T_ISSUE				TYPE_ISSUE			;-- 77
		T_INTEGER			TYPE_INTEGER		;-- 78 
		T_REFINE			TYPE_REFINEMENT		;-- 79
		T_CHAR				TYPE_CHAR			;-- 80
		T_FILE				TYPE_FILE			;-- 81
		T_BINARY			TYPE_BINARY			;-- 82
		T_PERCENT			TYPE_PERCENT		;-- 83
		T_FLOAT				TYPE_FLOAT			;-- 84
		T_FLOAT_SP			TYPE_FLOAT			;-- 85
		T_TUPLE				TYPE_TUPLE			;-- 86
		T_DATE				TYPE_DATE			;-- 87
		T_PAIR				TYPE_PAIR			;-- 88
		T_TIME				TYPE_TIME			;-- 89
		T_MONEY				TYPE_MONEY			;-- 90
		T_TAG				TYPE_TAG			;-- 91
		T_URL				TYPE_URL			;-- 92
		T_EMAIL				TYPE_EMAIL			;-- 93
		T_HEX				TYPE_INTEGER		;-- 94
		T_RAWSTRING			TYPE_STRING			;-- 95
		T_REF				TYPE_REF			;-- 96
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


	;-- Generate the skip-table content
	skip-table: make binary! 50	
	foreach [s t] states [append skip-table pick #{0100} s = 'S_START]

	;-- Template --
	
	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(extract states 2)
	]
	
	skip-table: (skip-table)
	
	type-table: (type-table)
		
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()