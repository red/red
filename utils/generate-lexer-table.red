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
		S_START
		S_BLANK
		S_LINE_CMT
		S_LINE_STR
		S_SKIP_STR
		S_M_STRING
		S_SKIP_MSTR
		S_FILE_1ST
		S_FILE
		S_SKIP_FILE
		S_SLASH
		S_SHARP
		S_BINARY
		S_LINE_CMT2
		S_CHAR
		S_SKIP_CHAR
		S_CONSTRUCT
		S_ISSUE
		S_NUMBER
		S_DOTNUM
		S_DECIMAL
		S_DEC_SPECIAL
		S_TUPLE
		S_DATE
		S_TIME_1ST
		S_TIME
		S_PAIR_1ST
		S_PAIR
		S_MONEY_1ST
		S_MONEY
		S_MONEY_DEC
		S_LESSER
		S_TAG
		S_TAG_STR
		S_SKIP_STR2
		S_TAG_STR2
		S_SKIP_STR3
		S_SIGN
		S_WORD
		S_WORDSET
		S_URL
		S_EMAIL
		--EXIT_STATES--
		T_EOF
		T_ERROR
		T_BLK_OP
		T_BLK_CL
		T_PAR_OP
		T_PAR_CL
		T_STRING
		T_STR_ALT
		T_WORD
		T_FILE
		T_REFINE
		T_BINARY
		T_CHAR
		T_MAP_OP
		T_CONS_MK
		T_ISSUE
		T_PERCENT
		T_INTEGER
		T_FLOAT
		T_TUPLE
		T_DATE
		T_PAIR
		T_TIME
		T_MONEY
		T_TAG
		T_URL
		T_EMAIL
		T_PATH
	]

	;-- Read states from CSV file
	csv: read %../docs/lexer-FSM.csv

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 > b/2]

	;-- Decode CSV
	matrix: load-csv/with read %../docs/lexer-FSM.csv first sep

	table: make binary! 2000

	;-- Generate the table content
	classes: clear []
	foreach line next matrix [
		append classes to-word line/1
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