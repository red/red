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
		S_START							;-- 0
		S_LINE_CMT						;-- 1
		S_LINE_STR						;-- 2
		S_SKIP_STR						;-- 3
		S_M_STRING						;-- 4
		S_SKIP_MSTR						;-- 5
		S_FILE_1ST						;-- 6
		S_FILE							;-- 7
		S_FILE_HEX1						;-- 8
		S_FILE_HEX2						;-- 9
		S_FILE_STR						;-- 10
		S_SLASH							;-- 11
		S_SHARP							;-- 12
		S_BINARY						;-- 13
		S_LINE_CMT2						;-- 14
		S_CHAR							;-- 15
		S_SKIP_CHAR						;-- 16
		S_CONSTRUCT						;-- 17
		S_ISSUE							;-- 18
		S_NUMBER						;-- 19
		S_DOTNUM						;-- 20
		S_DECIMAL						;-- 21
		S_DECX							;-- 22
		S_DEC_SPECIAL					;-- 23
		S_TUPLE							;-- 24
		S_DATE							;-- 25
		S_TIME_1ST						;-- 26
		S_TIME							;-- 27
		S_PAIR_1ST						;-- 28
		S_PAIR							;-- 29
		S_MONEY_1ST						;-- 30
		S_MONEY							;-- 31
		S_MONEY_DEC						;-- 32
		S_HEX							;-- 33
		S_LESSER						;-- 34
		S_TAG							;-- 35
		S_TAG_STR						;-- 36
		S_SKIP_STR2						;-- 37
		S_TAG_STR2						;-- 38
		S_SKIP_STR3						;-- 39
		S_SIGN							;-- 40
		S_DOTWORD						;-- 41
		S_DOTDEC						;-- 42
		S_WORD_1ST						;--	43
		S_WORD							;-- 44
		S_WORDSET						;-- 45
		S_URL							;-- 46
		S_EMAIL							;-- 47
		S_PATH							;-- 48
		S_PATH_NUM						;--	49
		S_PATH_W1ST						;-- 50
		S_PATH_WORD						;-- 51
		S_PATH_SHARP					;--	52
		S_PATH_SIGN						;--	53
		--EXIT_STATES--					;-- 54
		T_EOF							;-- 55
		T_ERROR							;-- 56
		T_BLK_OP						;-- 57
		T_BLK_CL						;-- 58
		T_PAR_OP						;-- 59
		T_PAR_CL						;-- 60
		T_STRING						;-- 61
		T_MSTR_OP						;-- 62
		T_MSTR_CL						;-- 63
		T_WORD							;-- 64
		T_FILE							;-- 65
		T_REFINE						;-- 66
		T_BINARY						;-- 67
		T_CHAR							;-- 68
		T_MAP_OP						;-- 69
		T_CONS_MK						;-- 70
		T_ISSUE							;-- 71
		T_PERCENT						;-- 72
		T_INTEGER						;-- 73
		T_FLOAT							;-- 74
		T_FLOAT_SP						;-- 75
		T_TUPLE							;-- 76
		T_DATE							;-- 77
		T_PAIR							;-- 78
		T_TIME							;-- 79
		T_MONEY							;-- 80
		T_TAG							;-- 81
		T_URL							;-- 82
		T_EMAIL							;-- 83
		T_PATH							;-- 84
		T_HEX							;-- 85
		T_CMT							;-- 86
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
			either pos: find states to-word s [
				append out (index? pos) - 1
			][
				do make error! form reduce ["Error: state" s "not found"]
			]
		]
		append/only table out
	]
	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(states)
	]
		
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()