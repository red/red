Red/System [
	File: 	 %opcode.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum opcode! [
	INS_VAR				;-- 0
	INS_UPDATE_VAR		;-- 1
	INS_PARAM           ;-- 2
	INS_PHI             ;-- 3
	INS_CONST           ;-- 4
	INS_IF              ;-- 5
	INS_SWITCH          ;-- 6
	INS_GOTO            ;-- 7
	INS_RETURN          ;-- 8
	INS_THROW           ;-- 9
                        
	OP_BOOL_EQ          ;-- 10
	OP_BOOL_AND         ;-- 11
	OP_BOOL_OR          ;-- 12
	OP_BOOL_NOT         ;-- 13

	OP_INT_ADD          ;-- 14
	OP_INT_SUB          ;-- 15
	OP_INT_MUL          ;-- 16
	OP_INT_DIV          ;-- 17
	OP_INT_MOD          ;-- 18
	OP_INT_REM          ;-- 19
	OP_INT_AND          ;-- 20
	OP_INT_OR           ;-- 21
	OP_INT_XOR          ;-- 22
	OP_INT_SHL          ;-- 23
	OP_INT_SAR          ;-- 24
	OP_INT_SHR          ;-- 25
	OP_INT_EQ           ;-- 26
	OP_INT_NE           ;-- 27
	OP_INT_LT           ;-- 28
	OP_INT_LTEQ         ;-- 29
                        
	OP_FLT_ADD          ;-- 30
	OP_FLT_SUB          ;-- 31
	OP_FLT_MUL          ;-- 32
	OP_FLT_DIV          ;-- 33
	OP_FLT_MOD          ;-- 34
	OP_FLT_REM          ;-- 35
	OP_FLT_ABS          ;-- 36
	OP_FLT_CEIL         ;-- 37
	OP_FLT_FLOOR        ;-- 38
	OP_FLT_SQRT         ;-- 39
	OP_FLT_UNUSED       ;-- 40
	OP_FLT_BITEQ        ;-- 41
	OP_FLT_EQ           ;-- 42
	OP_FLT_NE           ;-- 43
	OP_FLT_LT           ;-- 44
	OP_FLT_LTEQ         ;-- 45

	OP_INT_CAST         ;-- 46
	OP_FLOAT_CAST       ;-- 47
	OP_INT_TO_F         ;-- 48
	OP_FLT_TO_I			;-- 49

	OP_PTR_ADD			;-- 50
	OP_PTR_SUB			;-- 51
	OP_PTR_EQ			;-- 52
	OP_PTR_NE			;-- 53
	OP_PTR_LT			;-- 54
	OP_PTR_LTEQ			;-- 55
	OP_PTR_CAS			;-- 56 compare and swap
	OP_PTR_LOAD			;-- 57
	OP_PTR_STORE		;-- 58
	OP_PTR_AT			;-- 59
	OP_GET_PTR			;-- 60
	
	OP_DEFAULT_VALUE	;-- 61
	
	OP_CALL_FUNC		;-- 62

	OP_SET_FIELD		;-- 63
	OP_GET_FIELD		;-- 64
	OP_GET_GLOBAL		;-- 65
	OP_SET_GLOBAL		;-- 66
	OP_SET_LOCAL		;-- 67

	OP_CPU_IP			;-- 68 get instruction pointer
	OP_CPU_SP			;-- 69 get stack pointer

	OP_ARRAY_GET		;-- 70
	OP_ARRAY_SET		;-- 71

	OP_CATCH_BEG		;-- 72
	OP_CATCH_END		;-- 73
	OP_THROW			;-- 74
	OP_TYPED_VALUE		;-- 75
	OP_CALL_NATIVE		;-- 76

	OP_MIXED_EQ			;-- e.g. compare int with uint
	OP_MIXED_NE
	OP_MIXED_LT
	OP_MIXED_LTEQ
]

#enum instr-flag! [
	F_INS_PURE:		1		;-- no side-effects
	F_INS_KILLED:	2		;-- instruction is dead
	F_INS_END:		4
	F_INS_LIVE:		8
	F_NOT_VOID:		10h		;-- has a value
	F_FOLDABLE:		20h		;-- constant fold
	F_COMMUTATIVE:	40h		;-- (x, y) = (y, x)
	F_ASSOCIATIVE:	80h		;-- ((x, y), z) = (x, (y, z))
	F_NO_INT_TRUNC: 0100h
	F_ZERO:			0200h	;-- zero value
]

#define F_PF		21h		;-- F_INS_PURE or F_FOLDABLE
#define F_PFC		61h		;-- F_PF or F_COMMUTATIVE
#define F_PFCA		E1h		;-- F_PFC or F_ASSOCIATIVE

instr-flags: [
	0	;--INS_VAR
	0	;--INS_UPDATE_VAR
	0	;--INS_PARAM
	0	;--INS_PHI
	0	;--INS_CONST
	0	;--INS_IF
	0	;--INS_SWITCH
	0	;--INS_GOTO
	0	;--INS_RETURN
	0	;--INS_THROW

	F_PFC			;--OP_BOOL_EQ
	F_PFCA			;--OP_BOOL_AND
	F_PFCA			;--OP_BOOL_OR
	F_PF			;--OP_BOOL_NOT

	F_PFCA			;--OP_INT_ADD
	F_PF			;--OP_INT_SUB
	F_PFCA			;--OP_INT_MUL
	F_FOLDABLE		;--OP_INT_DIV
	F_FOLDABLE		;--OP_INT_MOD
	F_FOLDABLE		;--OP_INT_REM
	F_PFCA			;--OP_INT_AND
	F_PFCA			;--OP_INT_OR
	F_PFCA			;--OP_INT_XOR
	F_PF			;--OP_INT_SHL
	F_PF			;--OP_INT_SAR
	F_PF			;--OP_INT_SHR
	F_PFC			;--OP_INT_EQ
	F_PF			;--OP_INT_NE
	F_PF			;--OP_INT_LT
	F_PF			;--OP_INT_LTEQ

	F_PFCA			;--OP_FLT_ADD
	F_PF			;--OP_FLT_SUB
	F_PFCA			;--OP_FLT_MUL
	F_PF			;--OP_FLT_DIV
	F_FOLDABLE		;--OP_FLT_MOD
	F_FOLDABLE		;--OP_FLT_REM
	F_PF			;--OP_FLT_ABS
	F_PF			;--OP_FLT_CEIL
	F_PF			;--OP_FLT_FLOOR
	F_PF			;--OP_FLT_SQRT
	0	;--OP_FLT_UNUSED
	F_PFC			;--OP_FLT_BITEQ
	F_PFC			;--OP_FLT_EQ
	F_PF			;--OP_FLT_NE
	F_PF			;--OP_FLT_LT
	F_PF			;--OP_FLT_LTEQ

	0	;--OP_INT_CAST
	0	;--OP_FLOAT_CAST
	0	;--OP_INT_TO_F
	0	;--OP_FLT_TO_I

	F_PF			;--OP_PTR_ADD
	F_PF			;--OP_PTR_SUB
	F_PFC			;--OP_PTR_EQ
	F_PF			;--OP_PTR_NE
	F_PF			;--OP_PTR_LT
	F_PF			;--OP_PTR_LTEQ
	0	;--OP_PTR_CAS
	0	;--OP_PTR_LOAD
	0	;--OP_PTR_STORE
	0	;--OP_PTR_AT
	0	;--OP_GET_PTR
	
	0	;--OP_DEFAULT_VALUE
	0	;--OP_CALL_FUNC

	0	;--OP_SET_FIELD
	0	;--OP_GET_FIELD
	0	;--OP_GET_GLOBAL
	0	;--OP_SET_GLOBAL
	0	;--OP_SET_LOCAL

	0	;-- OP_CPU_IP
	0	;-- OP_CPU_SP

	0	;-- OP_ARRAY_GET
	0	;-- OP_ARRAY_SET

	0	;-- OP_CATCH_BEG
	0	;-- OP_CATCH_END
	0	;-- OP_THROW
	0	;-- OP_TYPED_VALUE
	0	;-- OP_CALL_NATIVE

	0	;-- OP_MIXED_EQ			;-- e.g. compare int with uint
	0	;-- OP_MIXED_NE
	0	;-- OP_MIXED_LT
	0	;-- OP_MIXED_LTEQ
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
#define I_IMODD		 49h	#define I_IMODQ		59h
 
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
#define I_GET_PC		6Ah
#define I_GET_SP		6Bh
#define I_SET_SP		6Ch
#define I_CMPB			6Fh
#define I_CATCH			70h
#define I_THROW			71h
#define I_CMPXCHG8		72h
#define I_CMPXCHG16		73h
#define I_CMPXCHG32		74h
#define I_CMPXCHG64		75h
#define I_MOVD			76h
#define I_MOVQ			77h
#define I_SYSCALL		78h
#define I_PUSH			79h
#define I_POP			80h
#define I_CALL_NATIVE	81h

#define I_W_DIFF		10h		;-- I_ADDQ - I_ADDD

#define I_NOP		1000
#define I_SAVE		1015
#define I_RESTORE	1016
#define I_RELOAD	1017
#define I_BLK_BEG	1018
#define I_BLK_END	1019
#define I_ENTRY		1020
#define I_PMOVE		1021		;-- phi parallel move
#define I_END		1022
#define I_RET		1023