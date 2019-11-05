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
		S_DOTWORD						;-- 39
		S_DOTDEC						;-- 40
		S_WORD							;-- 41
		S_WORDSET						;-- 42
		S_URL							;-- 43
		S_EMAIL							;-- 44
		S_PATH							;-- 45
		S_PATH_NUM						;--	46
		S_PATH_WORD						;-- 47
		S_PATH_SHARP					;--	48
		S_PATH_SIGN						;--	49
		--EXIT_STATES--					;-- 50
		T_EOF							;-- 51
		T_ERROR							;-- 52
		T_BLK_OP						;-- 53
		T_BLK_CL						;-- 54
		T_PAR_OP						;-- 55
		T_PAR_CL						;-- 56
		T_STRING						;-- 57
		T_MSTR_OP						;-- 58
		T_MSTR_CL						;-- 59
		T_WORD							;-- 60
		T_FILE							;-- 61
		T_REFINE						;-- 62
		T_BINARY						;-- 63
		T_CHAR							;-- 64
		T_MAP_OP						;-- 65
		T_CONS_MK						;-- 66
		T_ISSUE							;-- 67
		T_PERCENT						;-- 68
		T_INTEGER						;-- 69
		T_FLOAT							;-- 70
		T_FLOAT_SP						;-- 71
		T_TUPLE							;-- 72
		T_DATE							;-- 73
		T_PAIR							;-- 74
		T_TIME							;-- 75
		T_MONEY							;-- 76
		T_TAG							;-- 77
		T_URL							;-- 78
		T_EMAIL							;-- 79
		T_PATH							;-- 80
	]
	
	date-states: [
	;trash		1
	;year   	2
	;month  	3
	;day    	4
	;hour   	5
	;minute 	6
	;second 	7
	;nsec		8
	;tz-hour	9
	;tz-min		10
	;week		11
	;weekday	12
	;yearday	13
	;word-start 14
	;word-end   15
	;sep2		16
	;TZ-sign    17
	;-- state ----------- reset -- field -- ptr --
		S_DT_START			1		4		1		;-- 0
		S_DT_D				1		4		1		;--	1
		S_DT_DD				1		4		1		;--	2
		S_DT_YYY			1		2		1		;--	3
		S_DT_YYYY			0		2		1		;--	4
		F_DT_YEARL			0		1		14		;--	5
		F_DT_YEARL2			0		1		14		;--	6
		F_DT_DAYL			0		1		14		;--	7
		S_DT_YM				1		3		1		;--	8
		S_DT_YMM			0		3		1		;--	9
		S_DT_YM2			1		3		1		;-- 10
		S_DT_YMM2			1		3		1		;--	11
		F_DT_YMONTH			0		1		16		;--	12
		F_DT_DDD			0		13		1		;--	13
		S_DT_YV				0		11		1		;--	14
		S_DT_YW				1		11		1		;--	15
		S_DT_YWW			1		11		1		;--	16
		S_DT_YWD			0		1		1		;--	17
		S_DT_WD				1		12		1		;--	18
		S_DT_YMON			1		3		15		;--	19
		F_DT_YMD			1		4		1		;--	20
		F_DT_YMDD			0		4		1		;--	21
		S_DT_DM				1		3		1		;--	22
		S_DT_DMM			0		3		1		;--	23
		F_DT_DMONTH			0		1		16		;--	24
		S_DT_DMON			1		3		15		;--	25
		F_DT_DMY			1		2		1		;--	26
		F_DT_DMYY			1		2		1		;--	27
		F_DT_DMYYY			1		2		1		;--	28
		F_DT_DMYYYY			0		2		1		;--	29
		S_TM_START			0		1		1		;--	30
		F_TM_H				1		5		1		;-- 31
		F_TM_HH				0		5		1		;--	32
		S_TM_HM				0		1		1		;--	33
		F_TM_M				1		6		1		;--	34
		F_TM_MM				0		6		1		;--	35
		S_TM_HMS			0		1		1		;--	36
		F_TM_S				1		7		1		;--	37
		F_TM_SS				0		7		1		;--	38
		F_TM_N1				0		1		1		;--	39
		F_TM_N				1		8		1		;--	40
		S_TM_HMZ			0		1		17		;--	41
		S_TZ_H				1		9		1		;--	42
		F_TZ_HH				0		9		1		;--	43
		F_TZ_HM				0		1		1		;--	44
		S_TZ_M				1		10		1		;--	45
		T_DT_ERROR			0		1		1		;-- 46
		T_DT_YMDAY			0		1		1		;-- 47
		T_DT_DMYEAR			0		1		1		;-- 48
		T_DT_YDDD			0		1		1		;--	49
		T_DT_YWWD			0		1		1		;--	50
		T_DT_WEEK			0		1		1		;--	51
		T_TM_HM				0		1		1		;--	52
		T_TM_HMS			0		1		1		;-- 53
		T_TM_NZ				0		8		1		;--	54
		T_TZ_H				0		9		1		;--	55
		T_TZ_HH				0		9		1		;-- 56
		T_TZ_M				0		10		1		;-- 57
		T_TZ_MM				0		10		1		;-- 58
	]

	CSV-table: %../docs/lexer/lexer-FSM.csv
	date-table: %../docs/lexer/lexer-FSM.csv
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
	
	date-table: %../docs/lexer/date-FSM.csv
	;-- Read states from CSV file
	csv: read date-table

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 > b/2]

	;-- Decode CSV
	matrix: load-csv/with read date-table first sep

	;-- Generate the date tables
	dt-table: make binary! 2000
	reset-table: make binary! 100
	fields-table: make binary! 100
	fields-ptr-table: make binary! 100
	
	foreach [state reset pos ptr] date-states [
		append reset-table to-char reset
		append fields-table to-char pos
		append fields-ptr-table to-char ptr
	]

	foreach line next matrix [
		out: make block! 50	
		foreach s next line [
			either pos: find date-states to-word s [
				append out ((3 + index? pos) / 4) - 1
			][
				do make error! form reduce ["Error: state" s "not found"]
			]
		]
		append/only dt-table out
	]

	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(states)
	]
	
	#enum date-states! [
		(extract date-states 4)
	]
	
	fields-ptr-table: (fields-ptr-table)
	
	fields-table: (fields-table)
	
	reset-table: (reset-table)
	
	date-transitions: (dt-table)
	
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()