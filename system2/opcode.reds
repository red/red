Red/System [
	File: 	 %opcode.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum opcode! [
	INS_NEW_PARAM
	INS_NEW_VAR
	INS_UPDATE_VAR
	INS_PHI
	INS_IF
	INS_SWITCH
	INS_CONST
	INS_GOTO
	INS_RETURN
	INS_THROW
	INS_END

	OP_BOOL_EQ
	OP_BOOL_AND
	OP_BOOL_OR
	OP_BOOL_NOT

	OP_DEFAULT_VALUE
	
	OP_CALL

	OP_GET_GLOBAL
	OP_SET_GLOBAL
]