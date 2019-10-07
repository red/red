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
		S_BLANK							;-- 1
		S_LINE_CMT						;-- 2
		S_LINE_STR						;-- 3
		S_SKIP_STR						;-- 4
		S_M_STRING						;-- 5
		S_SKIP_MSTR						;-- 6
		S_FILE_1ST						;-- 7
		S_FILE							;-- 8
		S_SKIP_FILE						;-- 9
		S_SLASH							;-- 10
		S_SHARP							;-- 11
		S_BINARY						;-- 12
		S_LINE_CMT2						;-- 13
		S_CHAR							;-- 14
		S_SKIP_CHAR						;-- 15
		S_CONSTRUCT						;-- 16
		S_ISSUE							;-- 17
		S_NUMBER						;-- 18
		S_DOTNUM						;-- 19
		S_DECIMAL						;-- 20
		S_DEC_SPECIAL					;-- 21
		S_TUPLE							;-- 22
		S_DATE							;-- 23
		S_TIME_1ST						;-- 24
		S_TIME							;-- 25
		S_PAIR_1ST						;-- 26
		S_PAIR							;-- 27
		S_MONEY_1ST						;-- 28
		S_MONEY							;-- 29
		S_MONEY_DEC						;-- 30
		S_LESSER						;-- 31
		S_TAG							;-- 32
		S_TAG_STR						;-- 33
		S_SKIP_STR2						;-- 34
		S_TAG_STR2						;-- 35
		S_SKIP_STR3						;-- 36
		S_SIGN							;-- 37
		S_WORD							;-- 38
		S_WORDSET						;-- 39
		S_URL							;-- 40
		S_EMAIL							;-- 41
		--EXIT_STATES--					;-- 42
		T_EOF							;-- 43
		T_ERROR							;-- 44
		T_BLK_OP						;-- 45
		T_BLK_CL						;-- 46
		T_PAR_OP						;-- 47
		T_PAR_CL						;-- 48
		T_STRING						;-- 49
		T_STR_ALT						;-- 50
		T_WORD							;-- 51
		T_FILE							;-- 52
		T_REFINE						;-- 53
		T_BINARY						;-- 54
		T_CHAR							;-- 55
		T_MAP_OP						;-- 56
		T_CONS_MK						;-- 57
		T_ISSUE							;-- 58
		T_PERCENT						;-- 59
		T_INTEGER						;-- 60
		T_FLOAT							;-- 61
		T_TUPLE							;-- 62
		T_DATE							;-- 63
		T_PAIR							;-- 64
		T_TIME							;-- 65
		T_MONEY							;-- 66
		T_TAG							;-- 67
		T_URL							;-- 68
		T_EMAIL							;-- 69
		T_PATH							;-- 70
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

	table: make binary! 2000

	;-- Generate the table content
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