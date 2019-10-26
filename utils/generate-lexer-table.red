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
		S_DEC_SPECIAL					;-- 22
		S_TUPLE							;-- 23
		S_DATE							;-- 24
		S_TIME_1ST						;-- 25
		S_TIME							;-- 26
		S_PAIR_1ST						;-- 27
		S_PAIR							;-- 28
		S_MONEY_1ST						;-- 29
		S_MONEY							;-- 30
		S_MONEY_DEC						;-- 31
		S_LESSER						;-- 32
		S_TAG							;-- 33
		S_TAG_STR						;-- 34
		S_SKIP_STR2						;-- 35
		S_TAG_STR2						;-- 36
		S_SKIP_STR3						;-- 37
		S_SIGN							;-- 38
		S_WORD							;-- 39
		S_WORDSET						;-- 40
		S_URL							;-- 41
		S_EMAIL							;-- 42
		S_PATH							;-- 43
		S_PATH_NUM						;--	44
		S_PATH_WORD						;-- 45
		S_PATH_SHARP					;--	46
		S_PATH_SIGN						;--	47
		--EXIT_STATES--					;-- 48
		T_EOF							;-- 49
		T_ERROR							;-- 50
		T_BLK_OP						;-- 51
		T_BLK_CL						;-- 52
		T_PAR_OP						;-- 53
		T_PAR_CL						;-- 54
		T_STRING						;-- 55
		T_WORD							;-- 56
		T_FILE							;-- 57
		T_REFINE						;-- 58
		T_BINARY						;-- 59
		T_CHAR							;-- 60
		T_MAP_OP						;-- 61
		T_CONS_MK						;-- 62
		T_ISSUE							;-- 63
		T_PERCENT						;-- 64
		T_INTEGER						;-- 65
		T_FLOAT							;-- 66
		T_TUPLE							;-- 67
		T_DATE							;-- 68
		T_PAIR							;-- 69
		T_TIME							;-- 70
		T_MONEY							;-- 71
		T_TAG							;-- 72
		T_URL							;-- 73
		T_EMAIL							;-- 74
		T_PATH							;-- 75
	]
;trash		1
;year   	2
;month  	3
;day    	4
;hour   	5
;minute 	6
;second 	7
;nsec		8
;week		9
;weekday	10
;tz-hour	11
;tz-min		12

	date-states: [
	;-- state ----------- reset? -- field --
		S_DT_START			1		1		;-- 0
		S_DT_D				1		4		;--	1
		S_DT_DD				1		4		;--	2
		S_DT_YYY			1		2		;--	3
		F_DT_YEARL			0		2		;--	4
		F_DT_YEARL2			0		2		;--	5
		F_DT_DAYL			0		4		;--	6
		S_DT_YM				1		3		;--	7
		S_DT_YMM			1		3		;--	8
		F_DT_YMONTH			0		3		;--	9
		F_DT_DDD			0		4		;--	10
		S_DT_YV				1		9		;--	11
		S_DT_YW				1		9		;--	12
		S_DT_YWW			1		9		;--	13
		F_DT_WEEK			0		9		;--	14
		S_DT_WD				1		10		;--	15
		F_DT_YWWD			0		10		;--	16
		S_DT_YMON			1		3		;--	17
		F_DT_YMD			1		4		;--	18
		F_DT_YMDD			0		4		;--	19
		S_DT_DM				1		3		;--	20
		S_DT_DMM			1		3		;--	21
		F_DT_DMONTH			0		3		;--	22
		S_DT_DMON			1		3		;--	23
		F_DT_DMY			1		2		;--	24
		F_DT_DMYY			1		2		;--	25
		F_DT_DMYYY			1		2		;--	26
		F_DT_DMYYYY			0		2		;--	27
		S_TM_START			0		1		;--	28
		F_TM_H				1		5		;--	29
		F_TM_HH				1		5		;--	30
		S_TM_HM				0		5		;--	31
		F_TM_M				1		6		;--	32
		F_TM_MM				1		6		;--	33
		S_TM_HMS			0		6		;--	34
		F_TM_S				1		7		;--	35
		F_TM_SS				0		7		;--	36
		F_TM_N1				1		8		;--	37
		F_TM_N				1		8		;--	38
		S_TZ_START			0		1		;--	39
		S_TZ_H				1		11		;--	40
		F_TZ_HH				1		11		;--	41
		F_TZ_HM				0		12		;--	42
		S_TZ_M				1		12		;--	43
		--FINAL-STATES--	0		1		;--	44
		T_DT_ERROR			0		1		;-- 45
		T_DT_YMDAY			0		1		;-- 46
		T_DT_DMYEAR			0		1		;-- 47
		T_TM_NZ				0		1		;--	48
		T_TZ_H				0		1		;--	49
		T_TZ_HH				0		1		;-- 50
		T_TZ_M				0		1		;-- 51
		T_TZ_MM				0		1		;-- 52
	]

	CSV-table: %../docs/lexer/lexer-FSM.csv
	date-table: %../docs/lexer/lexer-FSM.csv
	;-- Read states from CSV file
	csv: read CSV-table

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 < b/2]

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
	
	date-table: %../docs/lexer/date-FSM.csv
	;-- Read states from CSV file
	csv: read date-table

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 < b/2]

	;-- Decode CSV
	matrix: load-csv/with read date-table first sep

	;-- Generate the date table content
	dt-table: make binary! 2000
	reset-table: make binary! 100
	fields-table: make binary! 100

	foreach line next matrix [
		out: make block! 50	
		foreach s next line [
			either pos: find date-states to-word s [
				append out ((2 + index? pos) / 3) - 1
			][
				do make error! form reduce ["Error: state" s "not found"]
			]
		]
		append reset-table to-char pick 0x31 (select date-states to-word line/1) = 1
		append fields-table to-char third find date-states to-word line/1
		append/only dt-table out
	]

	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(states)
	]
	
	#enum date-states! [
		(extract date-states 3)
	]
	
	fields-table: (fields-table)
	
	reset-table: (reset-table)
	
	date-transitions: (dt-table)
	
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()