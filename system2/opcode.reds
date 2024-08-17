Red/System [
	File: 	 %opcode.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum opcode! [
	INS_NEW_VAR
	INS_UPDATE_VAR
	INS_PARAM
	INS_PHI
	INS_CONST
	INS_IF
	INS_SWITCH
	INS_GOTO
	INS_RETURN
	INS_THROW

	OP_BOOL_EQ
	OP_BOOL_AND
	OP_BOOL_OR
	OP_BOOL_NOT

	OP_INT_ADD
	OP_INT_SUB
	OP_INT_MUL
	OP_INT_DIV
	OP_INT_MOD
	OP_INT_REM
	OP_INT_AND
	OP_INT_OR
	OP_INT_XOR
	OP_INT_SHL
	OP_INT_SAR
	OP_INT_SHR
	OP_INT_EQ
	OP_INT_NE
	OP_INT_LT
	OP_INT_LTEQ

	OP_FLT_ADD
	OP_FLT_SUB
	OP_FLT_MUL
	OP_FLT_DIV
	OP_FLT_MOD
	OP_FLT_REM
	OP_FLT_ABS
	OP_FLT_CEIL
	OP_FLT_FLOOR
	OP_FLT_SQRT
	OP_FLT_UNUSED
	OP_FLT_BITEQ
	OP_FLT_EQ
	OP_FLT_NE
	OP_FLT_LT
	OP_FLT_LTEQ

	OP_DEFAULT_VALUE
	
	OP_CALL

	OP_GET_GLOBAL
	OP_SET_GLOBAL
]