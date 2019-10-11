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
		S_SKIP_FILE						;-- 8
		S_SLASH							;-- 9
		S_SHARP							;-- 10
		S_BINARY						;-- 11
		S_LINE_CMT2						;-- 12
		S_CHAR							;-- 13
		S_SKIP_CHAR						;-- 14
		S_CONSTRUCT						;-- 15
		S_ISSUE							;-- 16
		S_NUMBER						;-- 17
		S_DOTNUM						;-- 18
		S_DECIMAL						;-- 19
		S_DEC_SPECIAL					;-- 20
		S_TUPLE							;-- 21
		S_DATE							;-- 22
		S_TIME_1ST						;-- 23
		S_TIME							;-- 24
		S_PAIR_1ST						;-- 25
		S_PAIR							;-- 26
		S_MONEY_1ST						;-- 27
		S_MONEY							;-- 28
		S_MONEY_DEC						;-- 29
		S_LESSER						;-- 30
		S_TAG							;-- 31
		S_TAG_STR						;-- 32
		S_SKIP_STR2						;-- 33
		S_TAG_STR2						;-- 34
		S_SKIP_STR3						;-- 35
		S_SIGN							;-- 36
		S_WORD							;-- 37
		S_WORDSET						;-- 38
		S_URL							;-- 39
		S_EMAIL							;-- 40
		--EXIT_STATES--					;-- 41
		T_EOF							;-- 42
		T_ERROR							;-- 43
		T_BLK_OP						;-- 44
		T_BLK_CL						;-- 45
		T_PAR_OP						;-- 46
		T_PAR_CL						;-- 47
		T_STRING						;-- 48
		T_STR_ALT						;-- 49
		T_WORD							;-- 50
		T_FILE							;-- 51
		T_REFINE						;-- 52
		T_BINARY						;-- 53
		T_CHAR							;-- 54
		T_MAP_OP						;-- 55
		T_CONS_MK						;-- 56
		T_ISSUE							;-- 57
		T_PERCENT						;-- 58
		T_INTEGER						;-- 59
		T_FLOAT							;-- 60
		T_TUPLE							;-- 61
		T_DATE							;-- 62
		T_PAIR							;-- 63
		T_TIME							;-- 64
		T_MONEY							;-- 65
		T_TAG							;-- 66
		T_URL							;-- 67
		T_EMAIL							;-- 68
		T_PATH							;-- 69
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