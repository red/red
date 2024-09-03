Red/System [
	File: 	 %opcode.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
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

	OP_INT_CAST
	OP_FLOAT_CAST
	OP_INT_TO_F
	OP_FLT_TO_I

	OP_DEFAULT_VALUE
	
	OP_CALL_FUNC

	OP_GET_GLOBAL
	OP_SET_GLOBAL
]

;-- mach instr opcode
#define I_ADDD		01h		#define I_ADDQ	11h
#define I_ORD		02h		#define I_ORQ	12h
#define I_ADCD		03h		#define I_ADCQ	13h
#define I_ANDD		04h		#define I_ANDQ	14h
#define I_SUBD		05h		#define I_SUBQ	15h
#define I_XORD		06h		#define I_XORQ	16h
#define I_CMPD		07h		#define I_CMPQ	17h
#define I_MULD		08h		#define I_MULQ	18h
#define I_NEGD		09h		#define I_NEGQ	19h
#define I_NOTD		0Ah		#define I_NOTQ	1Ah
#define I_TESTD		0Bh		#define I_TESTQ	1Bh
#define I_LEAD		0Ch		#define I_LEAQ	1Ch
#define I_DIVD		0Dh		#define I_DIVQ	1Dh
#define I_IDIVD		0Eh		#define I_IDIVQ	1Eh
#define I_INCD		0Fh		#define I_INCQ	1Fh

#define I_DECD		20h		#define I_DECQ		30h
#define I_SHLD		21h		#define I_SHLQ		31h
#define I_SARD		22h		#define I_SARQ		32h
#define I_SHRD		23h		#define I_SHRQ		33h
#define I_CDQ		24h		#define I_CQO		34h
#define I_SWITCHD	25h		#define I_SWITCHQ	35h
#define I_ADDSS		26h		#define I_ADDSD		36h
#define I_SUBSS		27h		#define I_SUBSD		37h
#define I_MULSS		28h		#define I_MULSD		38h
#define I_DIVSS		29h		#define I_DIVSD		39h
#define I_SQRTSS	2Ah		#define	I_SQRTSD	3Ah
#define I_MOVSS		2Bh		#define I_MOVSD		3Bh
#define I_CVTSS2SD	2Ch		#define I_CVTSD2SS	3Ch
#define I_PCMPEQD	2Dh		#define I_PCMPEQQ	3Dh
#define I_UCOMISS	2Fh		#define I_UCOMISD	3Fh

#define I_CVTSS2SID	40h		#define I_CVTSS2SIQ 50h
#define I_CVTSD2SID	41h		#define I_CVTSD2SIQ 51h
#define I_CVTSI2SSD	42h		#define I_CVTSI2SSQ 52h
#define I_CVTSI2SDD	43h		#define I_CVTSI2SDQ 53h
#define I_ROUNDSS	45h		#define I_ROUNDSD	55h
#define I_PSLLD		46h		#define I_PSLLQ		56h
#define I_PSRLD		47h		#define I_PSRLQ		57h

#define I_TRUNCS_U64 48h	#define I_TRUNCD_U64 58h
 
#define I_MOVB			60h
#define I_MOVBSX		61h
#define I_MOVBZX		62h
#define I_MOVW			63h
#define I_MOVWSX		64h
#define I_MOVWZX		65h
#define I_JMP			66h
#define I_JC			67h
#define I_SETC			68h
#define I_CALL			69h
#define I_CALLER_IP		6Ah
#define I_CALLER_SP		6Bh
#define I_TEST_ALLOC	6Ch
#define I_CMPB			6Fh
#define I_THROW			70h
#define I_THROWC		71h
#define I_CMPXCHG8		72h
#define I_CMPXCHG16		73h
#define I_CMPXCHG32		74h
#define I_CMPXCHG64		75h
#define I_MOVD			76h
#define I_MOVQ			77h
#define I_SYSCALL		78h

#define I_W_DIFF		10h		;-- I_ADDQ - I_ADDD

#define I_SAVE		1015
#define I_RESTORE	1016
#define I_RELOAD	1017
#define I_BLK_BEG	1018
#define I_BLK_END	1019
#define I_ENTRY		1020
#define I_PMOVE		1021		;-- phi parallel move
#define I_END		1022
#define I_RET		1023