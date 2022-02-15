Red/System [
	Title:   "Red/System ODBC Bindings"
	Author:  "Christian Ensel"
	File:    %odbc.reds
	Tabs:    4
	Rights:  "Copyright 2022 Christian Ensel. All rights reserved."
	License: 'Unlicensed
]


;------------------------------------------------- OS --
;

#switch OS [

	Windows [
		#define ODBC_LIBRARY "odbc32.dll"
	]
	macOS [
		#define ODBC_LIBRARY "odbc.dylib"
	]
	#default [
		#define ODBC_LIBRARY "libodbc.so.2"
	]

]


;------------------------------------ own ODBC macros --
;

#define result-of [FFFFh and]

#define ODBC_SUCCESS	[rc = SQL_SUCCESS]
#define ODBC_INFO		[rc = SQL_SUCCESS_WITH_INFO]
#define ODBC_NO_DATA    [rc = SQL_NO_DATA]
#define ODBC_NEED_DATA  [rc = SQL_NEED_DATA]
#define ODBC_ERROR      [rc = SQL_ERROR]
#define ODBC_INVALID	[rc = SQL_INVALID_HANDLE]
#define ODBC_EXECUTING  [rc = SQL_STILL_EXECUTING]

#define ODBC_SUCCEEDED	[any [rc = SQL_SUCCESS rc = SQL_SUCCESS_WITH_INFO]]
#define ODBC_FAILED 	[any [rc = SQL_ERROR   rc = SQL_SUCCESS_WITH_INFO]]

#define ODBC_DIAGNOSIS (type handle entity) [
	if any [rc = SQL_ERROR rc = SQL_SUCCESS_WITH_INFO] [diagnose-error type handle entity]
]




	;  ██████  ██████  ██         ██   ██
	; ██      ██    ██ ██         ██   ██
	;  █████  ██    ██ ██         ███████
	;      ██ ██ ▄▄ ██ ██         ██   ██
	; ██████   ██████  ███████ ██ ██   ██
	;             ▀▀

#enum odbcdef! [

	;-- special length/indicator values
	SQL_NULL_DATA:									   FFFFh ;-1
;	SQL_DATA_AT_EXEC:								   FFFEh ;-2

	;-- return values from functions
	SQL_SUCCESS:										   0
	SQL_SUCCESS_WITH_INFO:								   1
	SQL_NO_DATA:										 100

;	#if ODBCVER >= 0380h [
;	SQL_PARAM_DATA_AVAILABLE:							 101
;	] ; ODBCVER >= 0380h

	SQL_ERROR:										   FFFFh ;-1
	SQL_INVALID_HANDLE:								   FFFEh ;-2

	SQL_STILL_EXECUTING:                                   2
	SQL_NEED_DATA:                                        99

	;-- test for SQL_SUCCESS or SQL_SUCCESS_WITH_INFO
;	SQL_SUCCEEDED(rc)									  [] ;-- FIXME

	;-- flags for null-terminated string
	SQL_NTS:										   FFFDh ;-3
;	SQL_NTSL:											  -3 ;-3L

	;-- maximum message length
;	SQL_MAX_MESSAGE_LENGTH:                              512

	;-- date/time length constants
;	SQL_DATE_LEN:                                         10
;	SQL_TIME_LEN:                                          8 ;-- add P+1 if precision is nonzero
;	SQL_TIMESTAMP_LEN:                                    19 ;-- add P+1 if precision is nonzero

	;-- handle type identifiers
	SQL_HANDLE_ENV:                                        1
	SQL_HANDLE_DBC:                                        2
	SQL_HANDLE_STMT:                                       3
;	SQL_HANDLE_DESC:                                       4

	;-- environment attribute
	SQL_ATTR_OUTPUT_NTS:                               10001

	;-- connection attributes
	SQL_ATTR_AUTO_IPD:                                 10001
	SQL_ATTR_METADATA_ID:                              10014

	;-- statement attributes
	SQL_ATTR_APP_ROW_DESC:                             10010
	SQL_ATTR_APP_PARAM_DESC:                           10011
	SQL_ATTR_IMP_ROW_DESC:                             10012
	SQL_ATTR_IMP_PARAM_DESC:                           10013
	SQL_ATTR_CURSOR_SCROLLABLE:                        FFFFh ;-1
	SQL_ATTR_CURSOR_SENSITIVITY:                       FFFEh ;-2

	;-- SQL_ATTR_CURSOR_SCROLLABLE values
;	SQL_NONSCROLLABLE:                                     0
	SQL_SCROLLABLE:                                        1

;	SQL_DESC_COUNT:                                     1001
;   SQL_DESC_TYPE:                                      1002
;   SQL_DESC_LENGTH:                                    1003
;   SQL_DESC_OCTET_LENGTH_PTR:                          1004
;   SQL_DESC_PRECISION:                                 1005
;   SQL_DESC_SCALE:                                     1006
;   SQL_DESC_DATETIME_INTERVAL_CODE:                    1007
;   SQL_DESC_NULLABLE:                                  1008
;   SQL_DESC_INDICATOR_PTR:                             1009
;   SQL_DESC_DATA_PTR:                                  1010
;   SQL_DESC_NAME:                                      1011
;   SQL_DESC_UNNAMED:                                   1012
;   SQL_DESC_OCTET_LENGTH:                              1013
;   SQL_DESC_ALLOC_TYPE:                                1099

;   #if ODBCVER >= 0400h [
;	SQL_DESC_CHARACTER_SET_CATALOG:                     1018
;	SQL_DESC_CHARACTER_SET_SCHEMA:                      1019
;	SQL_DESC_CHARACTER_SET_NAME:                        1020
;	SQL_DESC_COLLATION_CATALOG:                         1015
;	SQL_DESC_COLLATION_SCHEMA:                          1016
;	SQL_DESC_COLLATION_NAME:                            1017
;	SQL_DESC_USER_DEFINED_TYPE_CATALOG:                 1026
;	SQL_DESC_USER_DEFINED_TYPE_SCHEMA:                  1027
;	SQL_DESC_USER_DEFINED_TYPE_NAME:                    1028
;	] ; ODBCVER >= 0400h

	;-- identifiers of fields in the diagnostics area
;	SQL_DIAG_RETURNCODE:                                   1
;	SQL_DIAG_NUMBER:                                       2
;	SQL_DIAG_ROW_COUNT:                                    3
;	SQL_DIAG_SQLSTATE:                                     4
;	SQL_DIAG_NATIVE:                                       5
;	SQL_DIAG_MESSAGE_TEXT:                                 6
;	SQL_DIAG_DYNAMIC_FUNCTION:                             7
;	SQL_DIAG_CLASS_ORIGIN:                                 8
;	SQL_DIAG_SUBCLASS_ORIGIN:                              9
;	SQL_DIAG_CONNECTION_NAME:                             10
;	SQL_DIAG_SERVER_NAME:                                 11
;	SQL_DIAG_DYNAMIC_FUNCTION_CODE:                       12

	;-- dynamic function codes
;	SQL_DIAG_ALTER_DOMAIN:                                 3
;	SQL_DIAG_ALTER_TABLE:                                  4
;	SQL_DIAG_CALL:                                         7
;	SQL_DIAG_CREATE_ASSERTION:                             6
;	SQL_DIAG_CREATE_CHARACTER_SET:                         8
;	SQL_DIAG_CREATE_COLLATION:                            10
;	SQL_DIAG_CREATE_DOMAIN:                               23
;	SQL_DIAG_CREATE_INDEX:                             FFFFh ;-1
;	SQL_DIAG_CREATE_SCHEMA:                               64
;	SQL_DIAG_CREATE_TABLE:                                77
;	SQL_DIAG_CREATE_TRANSLATION:                          79
;	SQL_DIAG_CREATE_VIEW:                                 84
;	SQL_DIAG_DELETE_WHERE:                                19
;	SQL_DIAG_DROP_ASSERTION:                              24
;	SQL_DIAG_DROP_CHARACTER_SET:                          25
;	SQL_DIAG_DROP_COLLATION:                              26
;	SQL_DIAG_DROP_DOMAIN:                                 27
;	SQL_DIAG_DROP_INDEX:                               FFFEh ;-2
;	SQL_DIAG_DROP_SCHEMA:                                 31
;	SQL_DIAG_DROP_TABLE:                                  32
;	SQL_DIAG_DROP_TRANSLATION:                            33
;	SQL_DIAG_DROP_VIEW:                                   36
;	SQL_DIAG_DYNAMIC_DELETE_CURSOR:                       38
;	SQL_DIAG_DYNAMIC_UPDATE_CURSOR:                       81
;	SQL_DIAG_GRANT:                                       48
;	SQL_DIAG_INSERT:                                      50
;	SQL_DIAG_REVOKE:                                      59
;	SQL_DIAG_SELECT_CURSOR:                               85
;	SQL_DIAG_UNKNOWN_STATEMENT:                            0
;	SQL_DIAG_UPDATE_WHERE:                                82

	;-- SQL data type codes
;	SQL_UNKNOWN_TYPE:                                      0
	SQL_CHAR:                                              1
	SQL_NUMERIC:                                           2
	SQL_DECIMAL:                                           3
	SQL_INTEGER:                                           4
	SQL_SMALLINT:                                          5
	SQL_FLOAT:                                             6
	SQL_REAL:                                              7
	SQL_DOUBLE:                                            8
;	SQL_DATETIME:                                          9
	SQL_VARCHAR:                                          12

;	#if ODBCVER >= 0400h [
;	SQL_VARIANT_TYPE:                                      0 ;=SQL_UNKNOWN_TYPE
;	SQL_UDT:                                              17
	SQL_ROW:                                              19
;	SQL_ARRAY:                                            50
;	SQL_MULTISET:                                         55
;	] ; ODBCVER >= 0400h

	;-- One-parameter shortcuts for date/time data types
	SQL_TYPE_DATE:                                        91
	SQL_TYPE_TIME:                                        92
	SQL_TYPE_TIMESTAMP:                                   93
;	#if ODBCVER >= 0400h [
;	SQL_TYPE_TIME_WITH_TIMEZONE:		                  94
;	SQL_TYPE_TIMESTAMP_WITH_TIMEZONE:                     95
;	] ; ODBCVER >= 0400h

	;-- Statement attribute values for cursor sensitivity
;	SQL_UNSPECIFIED:                                       0
;	SQL_INSENSITIVE:                                       1
;	SQL_SENSITIVE:                                         2

	;-- GetTypeInfo() request for all data types
	SQL_ALL_TYPES:                                         0

	;-- Default conversion code for SQLBindCol(), SQLBindParam() and SQLGetData()
;	SQL_DEFAULT:                                          99

	;-- SQLSQLLEN GetData() code indicating that the application row descriptor
	;   specifies the data type
	;
;	SQL_ARD_TYPE:                                      FF9Dh ;-99

;	#if ODBCVER >= 0380h [
;	SQL_APD_TYPE:                                      FF9Ch ;-100
; 	] ; ODBCVER >= 0380h

	;-- SQL date/time type subcodes
;	SQL_CODE_DATE:                                         1
;	SQL_CODE_TIME:                                         2
;	SQL_CODE_TIMESTAMP:                                    3

;	#if ODBCVER >= 0400h [
;	SQL_CODE_TIME_WITH_TIMEZONE:                           4
;	SQL_CODE_TIMESTAMP_WITH_TIMEZONE:                      5
;	] ; ODBCVER >= 0400h

	;-- CLI option values
	SQL_FALSE:                                             0
	SQL_TRUE:                                              1

	;-- values of NULLABLE field in descriptor
	SQL_NO_NULLS:                                          0
	SQL_NULLABLE:                                          1

	;-- Value returned by SQLGetTypeInfo() to denote that it is
	;   not known whether or not a data type supports null values.
;	SQL_NULLABLE_UNKNOWN:                                  2

	;-- Values returned by SQLGetTypeInfo() to show WHERE clause
	;   supported
;	SQL_PRED_NONE:                                         0
;	SQL_PRED_CHAR:                                         1
;	SQL_PRED_BASIC:                                        2

	;-- values of UNNAMED field in descriptor
;	SQL_NAMED:                                             0
;	SQL_UNNAMED:                                           1

	;-- values of ALLOC_TYPE field in descriptor
;	SQL_DESC_ALLOC_AUTO:                                   1
;	SQL_DESC_ALLOC_USER:                                   2

	;-- FreeStmt() options
	SQL_CLOSE:                                             0
;	SQL_DROP:                                              1
	SQL_UNBIND:                                            2
	SQL_RESET_PARAMS:                                      3

	;-- Codes used for FetchOrientation in SQLFetchScroll(),
	;   and in SQLDataSources()
	SQL_FETCH_NEXT:                                        1
	SQL_FETCH_FIRST:                                       2

	;-- Other codes used for FetchOrientation in SQLFetchScroll()
	SQL_FETCH_LAST:                                        3
	SQL_FETCH_PRIOR:                                       4
	SQL_FETCH_ABSOLUTE:                                    5
	SQL_FETCH_RELATIVE:                                    6

	;-- SQLEndTran() options
	SQL_COMMIT:                                            0
;	SQL_ROLLBACK:                                          1

	;-- null handles returned by SQLAllocHandle()
;	SQL_NULL_HENV:                                         0
;	SQL_NULL_HDBC:                                         0
;	SQL_NULL_HSTMT:                                        0
;	SQL_NULL_HDESC:                                        0

	;-- null handle used in place of parent handle when allocating HENV
;	SQL_NULL_HANDLE:                                       0 ;0L

	;-- Values that may appear in the result set of SQLSpecialColumns()
	SQL_SCOPE_CURROW:                                      0
	SQL_SCOPE_TRANSACTION:                                 1
	SQL_SCOPE_SESSION:                                     2

;	SQL_PC_UNKNOWN:                                        0
;	SQL_PC_NON_PSEUDO:                                     1
;	SQL_PC_PSEUDO:                                         2

	;-- Reserved value for the IdentifierType argument of SQLSpecialColumns()
;	SQL_ROW_IDENTIFIER:                                    1

	;-- Reserved values for UNIQUE argument of SQLStatistics()
	SQL_INDEX_UNIQUE:                                      0
	SQL_INDEX_ALL:                                         1

	;-- Values that may appear in the result set of SQLStatistics()
;	SQL_INDEX_CLUSTERED:                                   1
;	SQL_INDEX_HASHED:                                      2
;	SQL_INDEX_OTHER:                                       3

	;-- SQLGetFunctions() values to identify ODBC APIs
;	SQL_API_SQLALLOCCONNECT:                               1
;	SQL_API_SQLALLOCENV:                                   2
;	SQL_API_SQLALLOCHANDLE:                             1001
;	SQL_API_SQLALLOCSTMT:                                  3
;	SQL_API_SQLBINDCOL:                                    4
;	SQL_API_SQLBINDPARAM:                               1002
;	SQL_API_SQLCANCEL:                                     5
;	SQL_API_SQLCLOSECURSOR:                             1003
;	SQL_API_SQLCOLATTRIBUTE:                               6
;	SQL_API_SQLCOLUMNS:                                   40
;	SQL_API_SQLCONNECT:                                    7
;	SQL_API_SQLCOPYDESC:                                1004
;	SQL_API_SQLDATASOURCES:                               57
;	SQL_API_SQLDESCRIBECOL:                                8
;	SQL_API_SQLDISCONNECT:                                 9
;	SQL_API_SQLENDTRAN:                                 1005
;	SQL_API_SQLERROR:                                     10
;	SQL_API_SQLEXECDIRECT:                                11
;	SQL_API_SQLEXECUTE:                                   12
;	SQL_API_SQLFETCH:                                     13
;	SQL_API_SQLFETCHSCROLL:                             1021
;	SQL_API_SQLFREECONNECT:                               14
;	SQL_API_SQLFREEENV:                                   15
;	SQL_API_SQLFREEHANDLE:                              1006
;	SQL_API_SQLFREESTMT:                                  16
;	SQL_API_SQLGETCONNECTATTR:                          1007
;	SQL_API_SQLGETCONNECTOPTION:                          42
;	SQL_API_SQLGETCURSORNAME:                             17
;	SQL_API_SQLGETDATA:                                   43
;	SQL_API_SQLGETDESCFIELD:                            1008
;	SQL_API_SQLGETDESCREC:                              1009
;	SQL_API_SQLGETDIAGFIELD:                            1010
;	SQL_API_SQLGETDIAGREC:                              1011
;	SQL_API_SQLGETENVATTR:                              1012
;	SQL_API_SQLGETFUNCTIONS:                              44
;	SQL_API_SQLGETINFO:                                   45
;	SQL_API_SQLGETSTMTATTR:                             1014
;	SQL_API_SQLGETSTMTOPTION:                             46
;	SQL_API_SQLGETTYPEINFO:                               47
;	SQL_API_SQLNUMRESULTCOLS:                             18
;	SQL_API_SQLPARAMDATA:                                 48
;	SQL_API_SQLPREPARE:                                   19
;	SQL_API_SQLPUTDATA:                                   49
;	SQL_API_SQLROWCOUNT:                                  20
;	SQL_API_SQLSETCONNECTATTR:                          1016
;	SQL_API_SQLSETCONNECTOPTION:                          50
;	SQL_API_SQLSETCURSORNAME:                             21
;	SQL_API_SQLSETDESCFIELD:                            1017
;	SQL_API_SQLSETDESCREC:                              1018
;	SQL_API_SQLSETENVATTR:                              1019
;	SQL_API_SQLSETPARAM:                                  22
;	SQL_API_SQLSETSTMTATTR:                             1020
;	SQL_API_SQLSETSTMTOPTION:                             51
;	SQL_API_SQLSPECIALCOLUMNS:                            52
;	SQL_API_SQLSTATISTICS:                                53
;	SQL_API_SQLTABLES:                                    54
;	SQL_API_SQLTRANSACT:                                  23
;	#if ODBCVER >= 0380h [
;	SQL_API_SQLCANCELHANDLE:                            1550
;	SQL_API_SQLCOMPLETEASYNC:                           1551
;	] ; ODBCVER >= 0380h

	;-- Information requested by SQLGetInfo()
;	SQL_MAXIMUM_DRIVER_CONNECTIONS:                        0
;	SQL_MAXIMUM_CONCURRENT_ACTIVITIES:                     1
	SQL_DATA_SOURCE_NAME:                                  2
;	SQL_FETCH_DIRECTION:                                   8
	SQL_SERVER_NAME:                                      13
	SQL_SEARCH_PATTERN_ESCAPE:                            14
	SQL_DBMS_NAME:                                        17
	SQL_DBMS_VER:                                         18
	SQL_ACCESSIBLE_TABLES:                                19
	SQL_ACCESSIBLE_PROCEDURES:                            20
;	SQL_CURSOR_COMMIT_BEHAVIOR:                           23
	SQL_DATA_SOURCE_READ_ONLY:                            25
;	SQL_DEFAULT_TXN_ISOLATION:                            26
;	SQL_IDENTIFIER_CASE:                                  28
;	SQL_IDENTIFIER_QUOTE_CHAR:                            29
;	SQL_MAXIMUM_COLUMN_NAME_LENGTH:                       30
;	SQL_MAXIMUM_CURSOR_NAME_LENGTH:                       31
;	SQL_MAXIMUM_SCHEMA_NAME_LENGTH:                       32
;	SQL_MAXIMUM_CATALOG_NAME_LENGTH:                      34
;	SQL_SCROLL_CONCURRENCY:                               43
;	SQL_TRANSACTION_CAPABLE:                              46
	SQL_USER_NAME:                                        47
;	SQL_TRANSACTION_ISOLATION_OPTION:                     72
	SQL_INTEGRITY:                                        73
;	SQL_GETDATA_EXTENSIONS:                               81
;	SQL_NULL_COLLATION:                                   85
;	SQL_ALTER_TABLE:                                      86
	SQL_ORDER_BY_COLUMNS_IN_SELECT:                       90
	SQL_SPECIAL_CHARACTERS:                               94
;	SQL_MAXIMUM_COLUMNS_IN_GROUP_BY:                      97
;	SQL_MAXIMUM_COLUMNS_IN_INDEX:                         98
;	SQL_MAXIMUM_COLUMNS_IN_ORDER_BY:                      99
;	SQL_MAXIMUM_COLUMNS_IN_SELECT:                       100
;	SQL_MAXIMUM_INDEX_SIZE:                              102
	SQL_MAXIMUM_ROW_SIZE:                                104
;	SQL_MAXIMUM_STATEMENT_LENGTH:                        105
;	SQL_MAXIMUM_TABLES_IN_SELECT:                        106
;	SQL_MAXIMUM_USER_NAME_LENGTH:                        107
;	SQL_OUTER_JOIN_CAPABILITIES:                         115
	SQL_XOPEN_CLI_YEAR:                                10000
;	SQL_CURSOR_SENSITIVITY:                            10001
	SQL_DESCRIBE_PARAMETER:                            10002
	SQL_CATALOG_NAME:                                  10003
	SQL_COLLATION_SEQ:                                 10004
;	SQL_MAXIMUM_IDENTIFIER_LENGTH:                     10005

	;-- SQL_ALTER_TABLE bitmasks
;	SQL_AT_ADD_COLUMN:                             00000001h
;	SQL_AT_DROP_COLUMN:                            00000002h
;	SQL_AT_ADD_CONSTRAINT:                         00000008h

	;-- The following bitmasks are ODBC extensions and defined in sqlext.h
;	SQL_AT_COLUMN_SINGLE:                          00000020h
;	SQL_AT_ADD_COLUMN_DEFAULT:                     00000040h
;	SQL_AT_ADD_COLUMN_COLLATION:                   00000080h
;	SQL_AT_SET_COLUMN_DEFAULT:                     00000100h
;	SQL_AT_DROP_COLUMN_DEFAULT:                    00000200h
;	SQL_AT_DROP_COLUMN_CASCADE:                    00000400h
;	SQL_AT_DROP_COLUMN_RESTRICT:                   00000800h
;	SQL_AT_ADD_TABLE_CONSTRAINT:                   00001000h
;	SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE:          00002000h
;	SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT:         00004000h
;	SQL_AT_CONSTRAINT_NAME_DEFINITION:             00008000h
;	SQL_AT_CONSTRAINT_INITIALLY_DEFERRED:          00010000h
;	SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE:         00020000h
;	SQL_AT_CONSTRAINT_DEFERRABLE:                  00040000h
;	SQL_AT_CONSTRAINT_NON_DEFERRABLE:              00080000h

	;-- SQL_ASYNC_MODE values
;	SQL_AM_NONE:                                           0
;	SQL_AM_CONNECTION:                                     1
;	SQL_AM_STATEMENT:                                      2

	;-- SQL_CURSOR_COMMIT_BEHAVIOR values
;	SQL_CB_DELETE:                                         0
;	SQL_CB_CLOSE:                                          1
;	SQL_CB_PRESERVE:                                       2

	;-- SQL_FETCH_DIRECTION bitmasks
;	SQL_FD_FETCH_NEXT:                             00000001h
;	SQL_FD_FETCH_FIRST:                            00000002h
;	SQL_FD_FETCH_LAST:                             00000004h
;	SQL_FD_FETCH_PRIOR:                            00000008h
;	SQL_FD_FETCH_ABSOLUTE:                         00000010h
;	SQL_FD_FETCH_RELATIVE:                         00000020h

	;-- SQL_GETDATA_EXTENSIONS bitmasks
;	SQL_GD_ANY_COLUMN:                             00000001h
;	SQL_GD_ANY_ORDER:                              00000002h

	;-- SQL_IDENTIFIER_CASE values
;	SQL_IC_UPPER:                                          1
;	SQL_IC_LOWER:                                          2
;	SQL_IC_SENSITIVE:                                      3
;	SQL_IC_MIXED:                                          4

	;-- SQL_OJ_CAPABILITIES bitmasks
	;   NB: this means 'outer join', not what you may be thinking
;	SQL_OJ_LEFT:                                   00000001h
;	SQL_OJ_RIGHT:                                  00000002h
;	SQL_OJ_FULL:                                   00000004h
;	SQL_OJ_NESTED:                                 00000008h
;	SQL_OJ_NOT_ORDERED:                            00000010h
;	SQL_OJ_INNER:                                  00000020h
;	SQL_OJ_ALL_COMPARISON_OPS:                     00000040h

	;-- SQL_SCROLL_CONCURRENCY bitmasks
;	SQL_SCCO_READ_ONLY:                            00000001h
;	SQL_SCCO_LOCK:                                 00000002h
;	SQL_SCCO_OPT_ROWVER:                           00000004h
;	SQL_SCCO_OPT_VALUES:                           00000008h

	;-- SQL_TXN_CAPABLE values
;	SQL_TC_NONE:                                           0
;	SQL_TC_DML:                                            1
;	SQL_TC_ALL:                                            2
;	SQL_TC_DDL_COMMIT:                                     3
;	SQL_TC_DDL_IGNORE:                                     4

	;-- SQL_TXN_ISOLATION_OPTION bitmasks
;	SQL_TRANSACTION_READ_UNCOMMITTED:              00000001h
;	SQL_TRANSACTION_READ_COMMITTED:                00000002h
;	SQL_TRANSACTION_REPEATABLE_READ:               00000004h
;	SQL_TRANSACTION_SERIALIZABLE:                  00000008h

	;-- SQL_NULL_COLLATION values
;	SQL_NC_HIGH:                                           0
;	SQL_NC_LOW:                                            1




	;  ██████  ██████  ██      ██    ██  ██████  ██████  ██████  ███████    ██   ██
	; ██      ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
	;  █████  ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ █████      ███████
	;      ██ ██ ▄▄ ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
	;  █████   ██████  ███████  ██████   ██████  ██████  ██████  ███████ ██ ██   ██
	;             ▀▀

	SQL_WCHAR:                                         FFF8h ; -8
	SQL_WVARCHAR:                                      FFF7h ; -9
	SQL_WLONGVARCHAR:                                  FFF6h ;-10
	SQL_C_WCHAR:                                       FFF8h ;=SQL_WCHAR
;	SQL_C_TCHAR:                                       FFF8h ;=SQL_C_WCHAR




	;  ██████  ██████  ██      ███████ ██   ██ ████████    ██   ██
	; ██      ██    ██ ██      ██       ██ ██     ██       ██   ██
	;  █████  ██    ██ ██      █████     ███      ██       ███████
	;      ██ ██ ▄▄ ██ ██      ██       ██ ██     ██       ██   ██
	; ██████   ██████  ███████ ███████ ██   ██    ██    ██ ██   ██
	;             ▀▀

	;-- generally useful constants
;	SQL_SPEC_MAJOR:                                        4 ;-- Major version of specification
;	SQL_SPEC_MINOR:                                       00 ;-- Minor version of specification
;	SQL_SPEC_STRING:                                 "04.00" ;-- String constant for version

;	SQL_SQLSTATE_SIZE:                                     5 ;-- size of SQLSTATE

;	typedef SQLTCHAR                                         SQLSTATE[SQL_SQLSTATE_SIZE+1];

;	SQL_MAX_DSN_LENGTH:                                   32 ;-- maximum data source name size

;	SQL_MAX_OPTION_STRING_LENGTH:                        256

	;-- return code SQL_NO_DATA_FOUND is the same as SQL_NO_DATA
;	SQL_NO_DATA_FOUND:                                   100 ;=SQL_NO_DATA

	;-- extended function return values
;	#if ODBCVER >= 0400h [
;	SQL_DATA_AVAILABLE:                                  102
;	SQL_METADATA_CHANGED:                                103
;	SQL_MORE_DATA:                                       104
;	] ; ODBCVER >= 0400h

	;-- an end handle type
;	SQL_HANDLE_SENV:                                       5

	;-- env attribute
	SQL_ATTR_ODBC_VERSION:                               200
	SQL_ATTR_CONNECTION_POOLING:                         201
	SQL_ATTR_CP_MATCH:                                   202
	;-- For private driver manager
;	SQL_ATTR_APPLICATION_KEY:                            203

	;-- values for SQL_ATTR_CONNECTION_POOLING
;	SQL_CP_OFF:                                            0 ;0UL
;	SQL_CP_ONE_PER_DRIVER:                                 1 ;1UL
;	SQL_CP_ONE_PER_HENV:                                   2 ;2UL
;	SQL_CP_DRIVER_AWARE:                                   3 ;3UL
;	SQL_CP_DEFAULT:                                        0 ;=SQL_CP_OFF

	;-- values for SQL_ATTR_CP_MATCH
;	SQL_CP_STRICT_MATCH:                                   0 ;0UL
;	SQL_CP_RELAXED_MATCH:                                  1 ;1UL
;	SQL_CP_MATCH_DEFAULT:                                  0 ;=SQL_CP_STRICT_MATCH

	;-- values for SQL_ATTR_ODBC_VERSION
	SQL_OV_ODBC2:                                          2 ;2UL
	SQL_OV_ODBC3:                                          3 ;3UL

;	#if ODBCVER >= 0380h [
	;-- new values for SQL_ATTR_ODBC_VERSION
	;   From ODBC 3.8 onwards, we should use <major version> * 100 + <minor version>
	SQL_OV_ODBC3_80:                                     380 ;380UL
;	] ; ODBCVER >= 0380h

;	#if ODBCVER >= 0400h [
;	SQL_OV_ODBC4:                                        400 ;400UL
;	] ; ODBCVER >= 0400h

	;-- connection attributes with new names
	SQL_ATTR_ACCESS_MODE:                                101
	SQL_ATTR_AUTOCOMMIT:                                 102
	SQL_ATTR_LOGIN_TIMEOUT:                              103
	SQL_ATTR_TRACE:                                      104
	SQL_ATTR_TRACEFILE:                                  105
	SQL_ATTR_TRANSLATE_LIB:                              106
	SQL_ATTR_TRANSLATE_OPTION:                           107
	SQL_ATTR_TXN_ISOLATION:                              108
	SQL_ATTR_CURRENT_CATALOG:                            109
	SQL_ATTR_ODBC_CURSORS:                               110
	SQL_ATTR_QUIET_MODE:                                 111
	SQL_ATTR_PACKET_SIZE:                                112
	SQL_ATTR_CONNECTION_TIMEOUT:                         113
	SQL_ATTR_DISCONNECT_BEHAVIOR:                        114
	SQL_ATTR_ENLIST_IN_DTC:                             1207
	SQL_ATTR_ENLIST_IN_XA:                              1208
	SQL_ATTR_CONNECTION_DEAD:                           1209 ;-- GetConnectAttr only

	;-- ODBC Driver Manager sets this connection attribute to a unicode driver
	;   (which supports SQLConnectW) when the application is an ANSI application
	;   (which calls SQLConnect, SQLDriverConnect, or SQLBrowseConnect).
	;   This is SetConnectAttr only and application does not set this attribute
	;   This attribute was introduced because some unicode driver's some APIs may
	;   need to behave differently on ANSI or Unicode applications. A unicode
	;   driver, which  has same behavior for both ANSI or Unicode applications,
	;   should return SQL_ERROR when the driver manager sets this connection
	;   attribute. When a unicode driver returns SQL_SUCCESS on this attribute,
	;   the driver manager treates ANSI and Unicode connections differently in
	;   connection pooling.
;	SQL_ATTR_ANSI_APP:                                   115

;	#if ODBCVER >= 0380h [
;	SQL_ATTR_RESET_CONNECTION:                           116
	SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE:                 117
;	] ; ODBCVER >= 0380h

	;-- Connection attribute 118 is defined in sqlspi.h

;	#if ODBCVER >= 0380h [
	SQL_ATTR_ASYNC_DBC_EVENT:                            119
;	] ; ODBCVER >= 0380h

	;-- Connection attribute 120 and 121 are defined in sqlspi.h

;	#if ODBCVER >= 0400h [
;	SQL_ATTR_CREDENTIALS:                                122
;	SQL_ATTR_REFRESH_CONNECTION:                         123
;	] ; ODBCVER >= 0400h

	;-- SQL_ACCESS_MODE options
;	SQL_MODE_READ_WRITE:                                   0 ;0UL
;	SQL_MODE_READ_ONLY:                                    1 ;1UL
;	SQL_MODE_DEFAULT:                                      0 ;=SQL_MODE_READ_WRITE

	;-- SQL_AUTOCOMMIT options
;	SQL_AUTOCOMMIT_OFF:                                    0 ;0UL
	SQL_AUTOCOMMIT_ON:                                     1 ;1UL
;	SQL_AUTOCOMMIT_DEFAULT:                                1 ;=SQL_AUTOCOMMIT_ON

	;-- SQL_LOGIN_TIMEOUT options
;	SQL_LOGIN_TIMEOUT_DEFAULT:                            15 ;15UL

	;-- SQL_OPT_TRACE options
;	SQL_OPT_TRACE_OFF:                                     0 ;0UL
;	SQL_OPT_TRACE_ON:                                      1 ;1UL
;	SQL_OPT_TRACE_DEFAULT:                                 0 ;=SQL_OPT_TRACE_OFF
;	SQL_OPT_TRACE_FILE_DEFAULT:                  "\\SQL.LOG"

	;-- SQL_CUR_USE_IF_NEEDED and SQL_CUR_USE_ODBC are deprecated.
	;   Please use SQL_CUR_USE_DRIVER for cursor functionalities provided by drivers
;	SQL_CUR_USE_IF_NEEDED:                                 0 ;0UL
;	SQL_CUR_USE_ODBC:                                      1 ;1UL
;	SQL_CUR_USE_DRIVER:                                    2 ;2UL
;	SQL_CUR_DEFAULT:                                       2 ;SQL_CUR_USE_DRIVER

	;-- values for SQL_ATTR_DISCONNECT_BEHAVIOR
;	SQL_DB_RETURN_TO_POOL:                                 0 ;0UL
;	SQL_DB_DISCONNECT:                                     1 ;1UL
;	SQL_DB_DEFAULT:                                        0 ;SQL_DB_RETURN_TO_POOL

	;-- values for SQL_ATTR_ENLIST_IN_DTC
;	SQL_DTC_DONE:                                          0 ;0L

	;-- values for SQL_ATTR_CONNECTION_DEAD
;	SQL_CD_TRUE:                                           1 ;1L ;-- Connection is closed/dead
;	SQL_CD_FALSE:                                          0 ;0L ;-- Connection is open/available

	;-- values for SQL_ATTR_ANSI_APP
;	SQL_AA_TRUE:                                           1 ;1L ;-- the application is an ANSI app
;	SQL_AA_FALSE:                                          0 ;0L ;-- the application is a Unicode app

	;-- values for SQL_ATTR_RESET_CONNECTION
;	#if ODBCVER >= 0380h [
;	SQL_RESET_CONNECTION_YES:                              1 ;1UL
;	] ; ODBCVER >= 0380h

	;-- values for SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE
;	#if ODBCVER >= 0380h [
;	SQL_ASYNC_DBC_ENABLE_ON:                               1 ;1UL
;	SQL_ASYNC_DBC_ENABLE_OFF:                              0 ;0UL
;	SQL_ASYNC_DBC_ENABLE_DEFAULT:                          0 ;SQL_ASYNC_DBC_ENABLE_OFF
;	] ; ODBCVER >= 0380h

	;-- values for SQL_ATTR_REFRESH_CONNECTION
;	#if ODBCVER >= 0400h [
;	SQL_REFRESH_NOW:                                      -1
;	SQL_REFRESH_AUTO:                                      0
;	SQL_REFRESH_MANUAL:                                    1
;	] ; ODBCVER >= 0400h

;-- statement attributes
;	SQL_ROWSET_SIZE:                                       9
;	SQL_GET_BOOKMARK:                                     13 ;-- GetStmtOption Only

	;-- statement attributes for ODBC 3.0
	SQL_ATTR_QUERY_TIMEOUT:                                0
	SQL_ATTR_MAX_ROWS:                                     1
	SQL_ATTR_NOSCAN:                                       2
	SQL_ATTR_MAX_LENGTH:                                   3
	SQL_ATTR_ASYNC_ENABLE:                                 4
	SQL_ATTR_ROW_BIND_TYPE:                                5
	SQL_ATTR_CURSOR_TYPE:                                  6
	SQL_ATTR_CONCURRENCY:                                  7
	SQL_ATTR_KEYSET_SIZE:                                  8
	SQL_ATTR_SIMULATE_CURSOR:                             10
	SQL_ATTR_RETRIEVE_DATA:                               11
	SQL_ATTR_USE_BOOKMARKS:                               12
	SQL_ATTR_ROW_NUMBER:                                  14 ;-- GetStmtAttr
	SQL_ATTR_ENABLE_AUTO_IPD:                             15
	SQL_ATTR_FETCH_BOOKMARK_PTR:                          16
	SQL_ATTR_PARAM_BIND_OFFSET_PTR:                       17
	SQL_ATTR_PARAM_BIND_TYPE:                             18
	SQL_ATTR_PARAM_OPERATION_PTR:                         19
	SQL_ATTR_PARAM_STATUS_PTR:                            20
	SQL_ATTR_PARAMS_PROCESSED_PTR:                        21
	SQL_ATTR_PARAMSET_SIZE:                               22
	SQL_ATTR_ROW_BIND_OFFSET_PTR:                         23
	SQL_ATTR_ROW_OPERATION_PTR:                           24
	SQL_ATTR_ROW_STATUS_PTR:                              25
	SQL_ATTR_ROWS_FETCHED_PTR:                            26
	SQL_ATTR_ROW_ARRAY_SIZE:                              27

;	#if ODBCVER >= 0380h [
	SQL_ATTR_ASYNC_STMT_EVENT:                            29
;	] ; ODBCVER >= 0380h

;	#if ODBCVER >= 0400h [
;	SQL_ATTR_SAMPLE_SIZE:                                 30
;	SQL_ATTR_DYNAMIC_COLUMNS:                             31
;	SQL_ATTR_TYPE_EXCEPTION_BEHAVIOR:                     32
;	SQL_ATTR_LENGTH_EXCEPTION_BEHAVIOR:                   33
;	] ; ODBCVER >= 0400h

	;-- SQL_ATTR_TYPE_EXCEPTION_BEHAVIOR values
;	#if ODBCVER >= 0400h [
;	SQL_TE_ERROR:                                      0001h
;	SQL_TE_CONTINUE:                                   0002h
;	SQL_TE_REPORT:                                     0003h
;	] ; ODBCVER >= 0400h

	;-- SQL_ATTR_LENGTH_EXCEPTION_BEHAVIOR values
;	#if ODBCVER >= 0400h [
;	SQL_LE_CONTINUE:                                   0001h
;	SQL_LE_REPORT:                                     0002h
;	] ; ODBCVER >= 0400h

	;-- New defines for SEARCHABLE column in SQLGetTypeInfo
;	SQL_COL_PRED_CHAR:                                     1 ;=SQL_LIKE_ONLY
;	SQL_COL_PRED_BASIC:                                    2 ;=SQL_ALL_EXCEPT_LIKE

	;-- whether an attribute is a pointer or not
;	SQL_IS_POINTER:                                    FFFCh ;-4
	SQL_IS_UINTEGER:                                   FFFBh ;-5
	SQL_IS_INTEGER:                                    FFFAh ;-6
;	SQL_IS_USMALLINT:                                  FFF9h ;-7
;	SQL_IS_SMALLINT:                                   FFF8h ;-8

	;-- the value of SQL_ATTR_PARAM_BIND_TYPE
	SQL_PARAM_BIND_BY_COLUMN:                              0 ;0UL
;	SQL_PARAM_BIND_TYPE_DEFAULT:                           0 ;=SQL_PARAM_BIND_BY_COLUMN

	;-- SQL_QUERY_TIMEOUT options
;	SQL_QUERY_TIMEOUT_DEFAULT:                             0 ;0UL

	;-- SQL_MAX_ROWS options
;	SQL_MAX_ROWS_DEFAULT:                                  0 ;0UL

	;-- SQL_NOSCAN options
;	SQL_NOSCAN_OFF:                                        0 ;0UL ;-- 1.0 FALSE
;	SQL_NOSCAN_ON:                                         1 ;1UL ;-- 1.0 TRUE
;	SQL_NOSCAN_DEFAULT:                                    0 ;=SQL_NOSCAN_OFF

	;-- SQL_MAX_LENGTH options
;	SQL_MAX_LENGTH_DEFAULT:                                0 ;0UL

	;-- values for SQL_ATTR_ASYNC_ENABLE
;	SQL_ASYNC_ENABLE_OFF:                                  0 ;0UL
;	SQL_ASYNC_ENABLE_ON:                                   1 ;1UL
;	SQL_ASYNC_ENABLE_DEFAULT:                              0 ;=SQL_ASYNC_ENABLE_OFF

	;-- SQL_BIND_TYPE options
	SQL_BIND_BY_COLUMN:                                    0 ;0UL
;	SQL_BIND_TYPE_DEFAULT:                                 0 ;=SQL_BIND_BY_COLUMN

	;-- SQL_CONCURRENCY options
;	SQL_CONCUR_READ_ONLY:                                  1
;	SQL_CONCUR_LOCK:                                       2
;	SQL_CONCUR_ROWVER:                                     3
;	SQL_CONCUR_VALUES:                                     4
;	SQL_CONCUR_DEFAULT:                                    1 ;=SQL_CONCUR_READ_ONLY

	;-- SQL_CURSOR_TYPE options
;	SQL_CURSOR_FORWARD_ONLY:                               0 ;0UL
;	SQL_CURSOR_KEYSET_DRIVEN:                              1 ;1UL
;	SQL_CURSOR_DYNAMIC:                                    2 ;2UL
;	SQL_CURSOR_STATIC:                                     3 ;3UL
;	SQL_CURSOR_TYPE_DEFAULT:                               0 ;=SQL_CURSOR_FORWARD_ONLY

	;-- SQL_ROWSET_SIZE options
;	SQL_ROWSET_SIZE_DEFAULT:                               1 ;1UL

	;-- SQL_KEYSET_SIZE options
;	SQL_KEYSET_SIZE_DEFAULT:                               0 ;0UL

	;-- SQL_SIMULATE_CURSOR options
;	SQL_SC_NON_UNIQUE:                                     0 ;0UL
;	SQL_SC_TRY_UNIQUE:                                     1 ;1UL
;	SQL_SC_UNIQUE:                                         2 ;2UL

	;-- SQL_RETRIEVE_DATA options
;	SQL_RD_OFF:                                            0 ;0UL
;	SQL_RD_ON:                                             1 ;1UL
;	SQL_RD_DEFAULT:                                        1 ;=SQL_RD_ON

	;-- SQL_USE_BOOKMARKS options
;	SQL_UB_OFF:                                            0 ;0UL
;	SQL_UB_ON:                                             1 ;1UL
;	SQL_UB_DEFAULT:                                        0 ;=SQL_UB_OFF

	;-- New values for SQL_USE_BOOKMARKS attribute
;	SQL_UB_FIXED:                                          1 ;=SQL_UB_ON
;	SQL_UB_VARIABLE:                                       2 ;2UL

	;-- extended descriptor field
;	SQL_DESC_ARRAY_SIZE:                                  20
;	SQL_DESC_ARRAY_STATUS_PTR:                            21
;	SQL_DESC_AUTO_UNIQUE_VALUE:                           11 ;=SQL_COLUMN_AUTO_INCREMENT
;	SQL_DESC_BASE_COLUMN_NAME:                            22
;	SQL_DESC_BASE_TABLE_NAME:                             23
;	SQL_DESC_BIND_OFFSET_PTR:                             24
;	SQL_DESC_BIND_TYPE:                                   25
;	SQL_DESC_CASE_SENSITIVE:                              12 ;=SQL_COLUMN_CASE_SENSITIVE
;	SQL_DESC_CATALOG_NAME:                                17 ;=SQL_COLUMN_QUALIFIER_NAME
;	SQL_DESC_CONCISE_TYPE:                                 2 ;=SQL_COLUMN_TYPE
;	SQL_DESC_DATETIME_INTERVAL_PRECISION:                 26
;	SQL_DESC_DISPLAY_SIZE:                                 6 ;=SQL_COLUMN_DISPLAY_SIZE
;	SQL_DESC_FIXED_PREC_SCALE:                             9 ;=SQL_COLUMN_MONEY
;	SQL_DESC_LABEL:                                       18 ;=SQL_COLUMN_LABEL
;	SQL_DESC_LITERAL_PREFIX:                              27
;	SQL_DESC_LITERAL_SUFFIX:                              28
;	SQL_DESC_LOCAL_TYPE_NAME:                             29
;	SQL_DESC_MAXIMUM_SCALE:                               30
;	SQL_DESC_MINIMUM_SCALE:                               31
;	SQL_DESC_NUM_PREC_RADIX:                              32
;	SQL_DESC_PARAMETER_TYPE:                              33
;	SQL_DESC_ROWS_PROCESSED_PTR:                          34
;	SQL_DESC_ROWVER:                                      35
;	SQL_DESC_SCHEMA_NAME:                                 16 ;=SQL_COLUMN_OWNER_NAME
;	SQL_DESC_SEARCHABLE:                                  13 ;=SQL_COLUMN_SEARCHABLE
;	SQL_DESC_TYPE_NAME:                                   14 ;=SQL_COLUMN_TYPE_NAME
;	SQL_DESC_TABLE_NAME:                                  15 ;=SQL_COLUMN_TABLE_NAME
;	SQL_DESC_UNSIGNED:                                     8 ;=SQL_COLUMN_UNSIGNED
;	SQL_DESC_UPDATABLE:                                   10 ;=SQL_COLUMN_UPDATABLE

;	#if ODBCVER >= 0400h [
;	SQL_DESC_MIME_TYPE:		                             36
;	] ; ODBCVER >= 0400h

	;-- defines for diagnostics fields
;	SQL_DIAG_CURSOR_ROW_COUNT:                         FB1Fh ;-1249
;	SQL_DIAG_ROW_NUMBER:                               FB20h ;-1248
;	SQL_DIAG_COLUMN_NUMBER:                            FB21h ;-1247

	;-- SQL extended datatypes
	SQL_DATE:                                              9
	SQL_INTERVAL:                                         10
	SQL_TIME:                                             10
	SQL_TIMESTAMP:                                        11
	SQL_LONGVARCHAR:                                   FFFFh ;-1
	SQL_BINARY:                                        FFFEh ;-2
	SQL_VARBINARY:                                     FFFDh ;-3
	SQL_LONGVARBINARY:                                 FFFCh ;-4
	SQL_BIGINT:                                        FFFBh ;-5
	SQL_TINYINT:                                       FFFAh ;-6
	SQL_BIT:                                           FFF9h ;-7
	SQL_GUID:                                          FFF5h ;-11

	;-- interval code
;	SQL_CODE_YEAR:                                         1
;	SQL_CODE_MONTH:                                        2
;	SQL_CODE_DAY:                                          3
;	SQL_CODE_HOUR:                                         4
;	SQL_CODE_MINUTE:                                       5
;	SQL_CODE_SECOND:                                       6
;	SQL_CODE_YEAR_TO_MONTH:                                7
;	SQL_CODE_DAY_TO_HOUR:                                  8
;	SQL_CODE_DAY_TO_MINUTE:                                9
;	SQL_CODE_DAY_TO_SECOND:                               10
;	SQL_CODE_HOUR_TO_MINUTE:                              11
;	SQL_CODE_HOUR_TO_SECOND:                              12
;	SQL_CODE_MINUTE_TO_SECOND:                            13

	SQL_INTERVAL_YEAR:                                   101 ;-- 100 + SQL_CODE_YEAR
	SQL_INTERVAL_MONTH:                                  102 ;-- 100 + SQL_CODE_MONTH
	SQL_INTERVAL_DAY:                                    103 ;-- 100 + SQL_CODE_DAY
	SQL_INTERVAL_HOUR:                                   104 ;-- 100 + SQL_CODE_HOUR
	SQL_INTERVAL_MINUTE:                                 105 ;-- 100 + SQL_CODE_MINUTE
	SQL_INTERVAL_SECOND:                                 106 ;-- 100 + SQL_CODE_SECOND
	SQL_INTERVAL_YEAR_TO_MONTH:                          107 ;-- 100 + SQL_CODE_YEAR_TO_MONTH
	SQL_INTERVAL_DAY_TO_HOUR:                            108 ;-- 100 + SQL_CODE_DAY_TO_HOUR
	SQL_INTERVAL_DAY_TO_MINUTE:                          109 ;-- 100 + SQL_CODE_DAY_TO_MINUTE
	SQL_INTERVAL_DAY_TO_SECOND:                          110 ;-- 100 + SQL_CODE_DAY_TO_SECOND
	SQL_INTERVAL_HOUR_TO_MINUTE:                         111 ;-- 100 + SQL_CODE_HOUR_TO_MINUTE
	SQL_INTERVAL_HOUR_TO_SECOND:                         112 ;-- 100 + SQL_CODE_HOUR_TO_SECOND
	SQL_INTERVAL_MINUTE_TO_SECOND:                       113 ;-- 100 + SQL_CODE_MINUTE_TO_SECOND

	;-- The previous definitions for SQL_UNICODE_ are historical and obsolete

;	SQL_UNICODE:                                       FFF8h ;=SQL_WCHAR
;	SQL_UNICODE_VARCHAR:                               FFF7h ;=SQL_WVARCHAR
;	SQL_UNICODE_LONGVARCHAR:                           FFF6h ;=SQL_WLONGVARCHAR
;	SQL_UNICODE_CHAR:                                  FFF8h ;=SQL_WCHAR

	;-- C datatype to SQL datatype mapping                          SQL types
	;                                                               -------------------
	SQL_C_CHAR:                                            1 ;=SQL_CHAR
	SQL_C_LONG:                                            4 ;=SQL_INTEGER
;	SQL_C_SHORT:                                           5 ;=SQL_SMALLINT
;	SQL_C_FLOAT:                                           7 ;=SQL_REAL
	SQL_C_DOUBLE:                                          8 ;=SQL_DOUBLE
;	SQL_C_NUMERIC:                                         2 ;=SQL_NUMERIC
	SQL_C_DEFAULT:                                        99

;	SQL_SIGNED_OFFSET:                                 FFECh ;-20
;	SQL_UNSIGNED_OFFSET:                               FFEAh ;-22

	;-- C datatype to SQL datatype mapping
;	SQL_C_DATE:                                            9 ;=SQL_DATE
	SQL_C_TIME:                                           10 ;=SQL_TIME
;	SQL_C_TIMESTAMP:                                      11 ;=SQL_TIMESTAMP
	SQL_C_TYPE_DATE:                                      91 ;=SQL_TYPE_DATE
	SQL_C_TYPE_TIME:                                      92 ;=SQL_TYPE_TIME
	SQL_C_TYPE_TIMESTAMP:                                 93 ;=SQL_TYPE_TIMESTAMP
;	#if ODBCVER >= 0400h [
;	SQL_C_TYPE_TIME_WITH_TIMEZONE:	     				  94 ;=SQL_TYPE_TIME_WITH_TIMEZONE
;	SQL_C_TYPE_TIMESTAMP_WITH_TIMEZONE:   				  95 ;=SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
;	] ; ODBCVER >= 0400h
;	SQL_C_INTERVAL_YEAR:                                 101 ;=SQL_INTERVAL_YEAR
;	SQL_C_INTERVAL_MONTH:                                102 ;=SQL_INTERVAL_MONTH
;	SQL_C_INTERVAL_DAY:                                  103 ;=SQL_INTERVAL_DAY
;	SQL_C_INTERVAL_HOUR:                                 104 ;=SQL_INTERVAL_HOUR
;	SQL_C_INTERVAL_MINUTE:                               105 ;=SQL_INTERVAL_MINUTE
;	SQL_C_INTERVAL_SECOND:                               106 ;=SQL_INTERVAL_SECOND
;	SQL_C_INTERVAL_YEAR_TO_MONTH:                        107 ;=SQL_INTERVAL_YEAR_TO_MONTH
;	SQL_C_INTERVAL_DAY_TO_HOUR:                          108 ;=SQL_INTERVAL_DAY_TO_HOUR
;	SQL_C_INTERVAL_DAY_TO_MINUTE:                        109 ;=SQL_INTERVAL_DAY_TO_MINUTE
;	SQL_C_INTERVAL_DAY_TO_SECOND:                        110 ;=SQL_INTERVAL_DAY_TO_SECOND
;	SQL_C_INTERVAL_HOUR_TO_MINUTE:                       111 ;=SQL_INTERVAL_HOUR_TO_MINUTE
;	SQL_C_INTERVAL_HOUR_TO_SECOND:                       112 ;=SQL_INTERVAL_HOUR_TO_SECOND
;	SQL_C_INTERVAL_MINUTE_TO_SECOND:                     113 ;=SQL_INTERVAL_MINUTE_TO_SECOND
	SQL_C_BINARY:                                      FFFEh ;=SQL_BINARY
	SQL_C_BIT:                                         FFF9h ;=SQL_BIT
;	SQL_C_SBIGINT:                                     FFFBh ; -5 =SQL_BIGINT  + SQL_SIGNED_OFFSET    ;-- SIGNED BIGINT
;	SQL_C_UBIGINT:                                     FFFBh ; -5 =SQL_BIGINT  + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED BIGINT
;	SQL_C_TINYINT:                                     FFFAh ; -6 =SQL_TINYINT
;	SQL_C_SLONG:                                       FFF0h ;-16 =SQL_C_LONG  + SQL_SIGNED_OFFSET    ;-- SIGNED INTEGER
;	SQL_C_SSHORT:                                      FFF1h ;-15 =SQL_C_SHORT + SQL_SIGNED_OFFSET    ;-- SIGNED SMALLINT
;	SQL_C_STINYINT:                                    FFF2h ;-14 =SQL_TINYINT + SQL_SIGNED_OFFSET    ;-- SIGNED TINYINT
;	SQL_C_ULONG:                                       FFEEh ;-18 =SQL_C_LONG  + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED INTEGER
;	SQL_C_USHORT:                                      FFEFh ;-17 =SQL_C_SHORT + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED SMALLINT
;	SQL_C_UTINYINT:                                    FFF0h ;-16 =SQL_TINYINT + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED TINYINT

;	ifdef _WIN64
;	SQL_C_BOOKMARK:                                    FFFBh ;=SQL_C_UBIGINT
;	else
;	SQL_C_BOOKMARK:                                    FFEEh ;=SQL_C_ULONG
;	endif

;	SQL_C_GUID:                                        FFF5h ;=SQL_GUID
;	SQL_TYPE_NULL:                                         0

	;-- base value of driver-specific C-Type (max is 0x7fff)
	;   define driver-specific C-Type, named as SQL_DRIVER_C_TYPE_BASE,
	;   SQL_DRIVER_C_TYPE_BASE+1, SQL_DRIVER_C_TYPE_BASE+2, etc.
;	#if ODBCVER >= 0380h [
;	SQL_DRIVER_C_TYPE_BASE:                             4000
;	] ; ODBCVER >= 0380h

	;-- base value of driver-specific fields/attributes (max are 0x7fff [16-bit] or 0x00007fff [32-bit])
	;   define driver-specific SQL-Type, named as SQL_DRIVER_SQL_TYPE_BASE,
	;   SQL_DRIVER_SQL_TYPE_BASE+1, SQL_DRIVER_SQL_TYPE_BASE+2, etc.
	;
	;   Please note that there is no runtime change in this version of DM.
	;   However, we suggest that driver manufacturers adhere to this range
	;   as future versions of the DM may enforce these constraints
;	#if ODBCVER >= 0380h [
;	SQL_DRIVER_SQL_TYPE_BASE:                          4000h
;	SQL_DRIVER_DESC_FIELD_BASE:                        4000h
;	SQL_DRIVER_DIAG_FIELD_BASE:                        4000h
;	SQL_DRIVER_INFO_TYPE_BASE:                         4000h
;	SQL_DRIVER_CONN_ATTR_BASE:                     00004000h ;-- 32-bit
;	SQL_DRIVER_STMT_ATTR_BASE:                     00004000h ;-- 32-bit
;	] ; ODBCVER >= 0380h

;	SQL_C_VARBOOKMARK                                  FFFEh ;=SQL_C_BINARY

	;-- define for SQL_DIAG_ROW_NUMBER and SQL_DIAG_COLUMN_NUMBER
;	SQL_NO_ROW_NUMBER:                                 FFFFh ;-1
;	SQL_NO_COLUMN_NUMBER:                              FFFFh ;-1
;	SQL_ROW_NUMBER_UNKNOWN:                            FFFEh ;-2
;	SQL_COLUMN_NUMBER_UNKNOWN:                         FFFEh ;-2

	;-- SQLBindParameter extensions
;	SQL_DEFAULT_PARAM:                                 FFFBh ;-5
;	SQL_IGNORE:                                        FFFAh ;-6
;	SQL_COLUMN_IGNORE:                                 FFFAh ;-6=SQL_IGNORE
;	SQL_LEN_DATA_AT_EXEC_OFFSET:                       FF9Ch ;-100
;	#define SQL_LEN_DATA_AT_EXEC(length)                      [(- (length) + SQL_LEN_DATA_AT_EXEC_OFFSET)]

	;-- binary length for driver specific attributes
;	SQL_LEN_BINARY_ATTR_OFFSET:                        FF9Ch ;-100
;	SQL_LEN_BINARY_ATTR(length)                               [(- (length) + SQL_LEN_BINARY_ATTR_OFFSET)]

	;-- Defines used by Driver Manager when mapping SQLSetParam to SQLBindParameter
;	SQL_PARAM_TYPE_DEFAULT:                                2 ;=SQL_PARAM_INPUT_OUTPUT
;	SQL_SETPARAM_VALUE_MAX:                               -1 ;-1L

	;-- Extended length/indicator values Values
;	#if ODBCVER >= 0400h [
;	SQL_DATA_UNAVAILABLE:                              FFFAh ;=SQL_IGNORE
;	SQL_DATA_AT_FETCH:                                 FFFEh ;=SQL_DATA_AT_EXEC
;	SQL_TYPE_EXCEPTION:		                             -20
;	] ; ODBCVER >= 0400h

	;-- SQLColAttributes defines
;	SQL_COLUMN_COUNT:                                      0
;	SQL_COLUMN_NAME:                                       1
;	SQL_COLUMN_TYPE:                                       2
;	SQL_COLUMN_LENGTH:                                     3
;	SQL_COLUMN_PRECISION:                                  4
;	SQL_COLUMN_SCALE:                                      5
;	SQL_COLUMN_DISPLAY_SIZE:                               6
;	SQL_COLUMN_NULLABLE:                                   7
;	SQL_COLUMN_UNSIGNED:                                   8
;	SQL_COLUMN_MONEY:                                      9
;	SQL_COLUMN_UPDATABLE:                                 10
;	SQL_COLUMN_AUTO_INCREMENT:                            11
;	SQL_COLUMN_CASE_SENSITIVE:                            12
;	SQL_COLUMN_SEARCHABLE:                                13
;	SQL_COLUMN_TYPE_NAME:                                 14
;	SQL_COLUMN_TABLE_NAME:                                15
;	SQL_COLUMN_OWNER_NAME:                                16
;	SQL_COLUMN_QUALIFIER_NAME:                            17
;	SQL_COLUMN_LABEL:                                     18
;	SQL_COLATT_OPT_MAX:                                   18 ;=SQL_COLUMN_LABEL
;	SQL_COLATT_OPT_MIN:                                    0 ;=SQL_COLUMN_COUNT

	;-- SQLColAttributes subdefines for SQL_COLUMN_UPDATABLE
;	SQL_ATTR_READONLY:                                     0
;	SQL_ATTR_WRITE:                                        1
;	SQL_ATTR_READWRITE_UNKNOWN:                            2

	;-- SQLColAttributes subdefines for SQL_COLUMN_SEARCHABLE
	;   These are also used by SQLGetInfo
;	SQL_UNSEARCHABLE:                                      0
;	SQL_LIKE_ONLY:                                         1
;	SQL_ALL_EXCEPT_LIKE:                                   2
;	SQL_SEARCHABLE:                                        3
;	SQL_PRED_SEARCHABLE:                                  13 ;=SQL_SEARCHABLE

	;-- Special return values for SQLGetData
;	SQL_NO_TOTAL:                                      FFFCh ;-4

	;********************************************
	;* SQLGetFunctions: additional values for   *
	;* fFunction to represent functions that    *
	;* are not in the X/Open spec.              *
	;********************************************

;	SQL_API_SQLALLOCHANDLESTD:                            73
;	SQL_API_SQLBULKOPERATIONS:                            24
;	SQL_API_SQLBINDPARAMETER:                             72
;	SQL_API_SQLBROWSECONNECT:                             55
;	SQL_API_SQLCOLATTRIBUTES:                              6
;	SQL_API_SQLCOLUMNPRIVILEGES:                          56
;	SQL_API_SQLDESCRIBEPARAM:                             58
;	SQL_API_SQLDRIVERCONNECT:                             41
;	SQL_API_SQLDRIVERS:                                   71
;	SQL_API_SQLEXTENDEDFETCH:                             59
;	SQL_API_SQLFOREIGNKEYS:                               60
;	SQL_API_SQLMORERESULTS:                               61
;	SQL_API_SQLNATIVESQL:                                 62
;	SQL_API_SQLNUMPARAMS:                                 63
;	SQL_API_SQLPARAMOPTIONS:                              64
;	SQL_API_SQLPRIMARYKEYS:                               65
;	SQL_API_SQLPROCEDURECOLUMNS:                          66
;	SQL_API_SQLPROCEDURES:                                67
;	SQL_API_SQLSETPOS:                                    68
;	SQL_API_SQLSETSCROLLOPTIONS:                          69
;	SQL_API_SQLTABLEPRIVILEGES:                           70

;	#if ODBCVER >= 0400h [
;	SQL_API_SQLGETNESTEDHANDLE:                           74
;	SQL_API_SQLSTRUCTUREDTYPES:                           75
;	SQL_API_SQLSTRUCTUREDTYPECOLUMNS:                     76
;	SQL_API_SQLNEXTCOLUMN:                                77
;	] ; ODBCVER >= 0400h

	;*--------------------------------------------*
	;* SQL_API_ALL_FUNCTIONS returns an array     *
	;* of 'booleans' representing whether a       *
	;* function is implemented by the driver.     *
	;*                                            *
	;* CAUTION: Only functions defined in ODBC    *
	;* version 2.0 and earlier are returned, the  *
	;* new high-range function numbers defined by *
	;* X/Open break this scheme.   See the new    *
	;* method -- SQL_API_ODBC3_ALL_FUNCTIONS      *
	;*--------------------------------------------*

;	SQL_API_ALL_FUNCTIONS:                                 0 ;-- See CAUTION above

	;*----------------------------------------------*
	;* 2.X drivers export a dummy function with     *
	;* ordinal number SQL_API_LOADBYORDINAL to speed*
	;* loading under the windows operating system.  *
	;*                                              *
	;* CAUTION: Loading by ordinal is not supported *
	;* for 3.0 and above drivers.                   *
	;*----------------------------------------------*

;	SQL_API_LOADBYORDINAL:                               199 ;-- See CAUTION above

	;*----------------------------------------------*
	;* SQL_API_ODBC3_ALL_FUNCTIONS                  *
	;* This returns a bitmap, which allows us to    *
	;* handle the higher-valued function numbers.   *
	;* Use  SQL_FUNC_EXISTS(bitmap,function_number) *
	;* to determine if the function exists.         *
	;*----------------------------------------------*

;	SQL_API_ODBC3_ALL_FUNCTIONS:                         999
;	SQL_API_ODBC3_ALL_FUNCTIONS_SIZE:                    250 ;-- array of 250 words --
;	#define SQL_FUNC_EXISTS(pfExists, uwAPI)                 [(
;               (* (((UWORD*) (pfExists)) + ((uwAPI) >> 4)) \
;                       & (1 << ((uwAPI) & 0x000F)) \
;                    ) ? SQL_TRUE : SQL_FALSE \
;	)]

;	************************************************
;	* Extended definitions for SQLGetInfo          *
;	************************************************

;	*---------------------------------*
;	* Values in ODBC 2.0 that are not *
;	* in the X/Open spec              *
;	*---------------------------------*

;	SQL_INFO_FIRST:                                        0
;	SQL_ACTIVE_CONNECTIONS:                                0 ;=MAX_DRIVER_CONNECTIONS
;	SQL_ACTIVE_STATEMENTS:                                 1 ;=MAX_CONCURRENT_ACTIVITIES
;	SQL_DRIVER_HDBC:                                       3
;	SQL_DRIVER_HENV:                                       4
;	SQL_DRIVER_HSTMT:                                      5
	SQL_DRIVER_NAME:                                       6
	SQL_DRIVER_VER:                                        7
;	SQL_ODBC_API_CONFORMANCE:                              9
	SQL_ODBC_VER:                                         10
	SQL_ROW_UPDATES:                                      11
;	SQL_ODBC_SAG_CLI_CONFORMANCE:                         12
;	SQL_ODBC_SQL_CONFORMANCE:                             15
	SQL_PROCEDURES:                                       21
;	SQL_CONCAT_NULL_BEHAVIOR:                             22
;	SQL_CURSOR_ROLLBACK_BEHAVIOR:                         24
	SQL_EXPRESSIONS_IN_ORDERBY:                           27
;	SQL_MAX_OWNER_NAME_LEN:                               32 ;=MAX_SCHEMA_NAME_LEN
;	SQL_MAX_PROCEDURE_NAME_LEN:                           33
;	SQL_MAX_QUALIFIER_NAME_LEN:                           34 ;=MAX_CATALOG_NAME_LEN
	SQL_MULT_RESULT_SETS:                                 36
	SQL_MULTIPLE_ACTIVE_TXN:                              37
;	SQL_OUTER_JOINS:                                      38
;	SQL_OWNER_TERM:                                       39
	SQL_PROCEDURE_TERM:                                   40
;	SQL_QUALIFIER_NAME_SEPARATOR:                         41
;	SQL_QUALIFIER_TERM:                                   42
;	SQL_SCROLL_OPTIONS:                                   44
	SQL_TABLE_TERM:                                       45
;	SQL_CONVERT_FUNCTIONS:                                48
;	SQL_NUMERIC_FUNCTIONS:                                49
;	SQL_STRING_FUNCTIONS:                                 50
;	SQL_SYSTEM_FUNCTIONS:                                 51
;	SQL_TIMEDATE_FUNCTIONS:                               52
;	SQL_CONVERT_BIGINT:                                   53
;	SQL_CONVERT_BINARY:                                   54
;	SQL_CONVERT_BIT:                                      55
;	SQL_CONVERT_CHAR:                                     56
;	SQL_CONVERT_DATE:                                     57
;	SQL_CONVERT_DECIMAL:                                  58
;	SQL_CONVERT_DOUBLE:                                   59
;	SQL_CONVERT_FLOAT:                                    60
;	SQL_CONVERT_INTEGER:                                  61
;	SQL_CONVERT_LONGVARCHAR:                              62
;	SQL_CONVERT_NUMERIC:                                  63
;	SQL_CONVERT_REAL:                                     64
;	SQL_CONVERT_SMALLINT:                                 65
;	SQL_CONVERT_TIME:                                     66
;	SQL_CONVERT_TIMESTAMP:                                67
;	SQL_CONVERT_TINYINT:                                  68
;	SQL_CONVERT_VARBINARY:                                69
;	SQL_CONVERT_VARCHAR:                                  70
;	SQL_CONVERT_LONGVARBINARY:                            71
;	SQL_ODBC_SQL_OPT_IEF:                                 73 ;=SQL_INTEGRITY
;	SQL_CORRELATION_NAME:                                 74
;	SQL_NON_NULLABLE_COLUMNS:                             75
;	SQL_DRIVER_HLIB:                                      76
	SQL_DRIVER_ODBC_VER:                                  77
;	SQL_LOCK_TYPES:                                       78
;	SQL_POS_OPERATIONS:                                   79
;	SQL_POSITIONED_STATEMENTS:                            80
;	SQL_BOOKMARK_PERSISTENCE:                             82
;	SQL_STATIC_SENSITIVITY:                               83
;	SQL_FILE_USAGE:                                       84
	SQL_COLUMN_ALIAS:                                     87
;	SQL_GROUP_BY:                                         88
	SQL_KEYWORDS:                                         89
;	SQL_OWNER_USA/E:                                      91
;	SQL_QUALIFIER_USAGE:                                  92
;	SQL_QUOTED_IDENTIFIER_CASE:                           93
;	SQL_SUBQUERIES:                                       95
;	SQL_UNION:                                            96
	SQL_MAX_ROW_SIZE_INCLUDES_LONG:                      103
;	SQL_MAX_CHAR_LITERAL_LEN:                            108
;	SQL_TIMEDATE_ADD_INTERVALS:                          109
;	SQL_TIMEDATE_DIFF_INTERVALS:                         110
	SQL_NEED_LONG_DATA_LEN:                              111
;	SQL_MAX_BINARY_LITERAL_LEN:                          112
	SQL_LIKE_ESCAPE_CLAUSE:                              113
;	SQL_QUALIFIER_LOCATION:                              114

	;*-----------------------------------------------*
	;* ODBC 3.0 SQLGetInfo values that are not part  *
	;* of the X/Open standard at this time.   X/Open *
	;* standard values are in sql.h.                 *
	;*-----------------------------------------------*

;	SQL_ACTIVE_ENVIRONMENTS:                             116
;	SQL_ALTER_DOMAIN:                                    117
;	SQL_SQL_CONFORMANCE:                                 118
;	SQL_DATETIME_LITERALS:                               119
;	SQL_ASYNC_MODE:                                    10021 ;-- new X/Open spec
;	SQL_BATCH_ROW_COUNT:                                 120
;	SQL_BATCH_SUPPORT:                                   121
;	SQL_CATALOG_LOCATION:                                114 ;=SQL_QUALIFIER_LOCATION
	SQL_CATALOG_NAME_SEPARATOR:                           41 ;=SQL_QUALIFIER_NAME_SEPARATOR
	SQL_CATALOG_TERM:                                     42 ;=SQL_QUALIFIER_TERM
;	SQL_CATALOG_USAGE:                                    92 ;=SQL_QUALIFIER_USAGE
;	SQL_CONVERT_WCHAR:                                   122
;	SQL_CONVERT_INTERVAL_DAY_TIME:                       123
;	SQL_CONVERT_INTERVAL_YEAR_MONTH:                     124
;	SQL_CONVERT_WLONGVARCHAR:                            125
;	SQL_CONVERT_WVARCHAR:                                126
;	SQL_CREATE_ASSERTION:                                127
;	SQL_CREATE_CHARACTER_SET:                            128
;	SQL_CREATE_COLLATION:                                129
;	SQL_CREATE_DOMAIN:                                   130
;	SQL_CREATE_SCHEMA:                                   131
;	SQL_CREATE_TABLE:                                    132
;	SQL_CREATE_TRANSLATION:                              133
;	SQL_CREATE_VIEW:                                     134
;	SQL_DRIVER_HDESC:                                    135
;	SQL_DROP_ASSERTION:                                  136
;	SQL_DROP_CHARACTER_SET:                              137
;	SQL_DROP_COLLATION:                                  138
;	SQL_DROP_DOMAIN:                                     139
;	SQL_DROP_SCHEMA:                                     140
;	SQL_DROP_TABLE:                                      141
;	SQL_DROP_TRANSLATION:                                142
;	SQL_DROP_VIEW:                                       143
;	SQL_DYNAMIC_CURSOR_ATTRIBUTES1:                      144
;	SQL_DYNAMIC_CURSOR_ATTRIBUTES2:                      145
;	SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1:                 146
;	SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2:                 147
;	SQL_INDEX_KEYWORDS:                                  148
;	SQL_INFO_SCHEMA_VIEWS:                               149
;	SQL_KEYSET_CURSOR_ATTRIBUTES1:                       150
;	SQL_KEYSET_CURSOR_ATTRIBUTES2:                       151
;	SQL_MAX_ASYNC_CONCURRENT_STATEMENTS:               10022 ;-- new X/Open spec
;	SQL_ODBC_INTERFACE_CONFORMANCE:                      152
;	SQL_PARAM_ARRAY_ROW_COUNTS:                          153
;	SQL_PARAM_ARRAY_SELECTS:                             154
	SQL_SCHEMA_TERM:                                      39 ;=SQL_OWNER_TERM
;	SQL_SCHEMA_USAGE:                                     91 ;=SQL_OWNER_USAGE
;	SQL_SQL92_DATETIME_FUNCTIONS:                        155
;	SQL_SQL92_FOREIGN_KEY_DELETE_RULE:                   156
;	SQL_SQL92_FOREIGN_KEY_UPDATE_RULE:                   157
;	SQL_SQL92_GRANT:                                     158
;	SQL_SQL92_NUMERIC_VALUE_FUNCTIONS:                   159
;	SQL_SQL92_PREDICATES:                                160
;	SQL_SQL92_RELATIONAL_JOIN_OPERATORS:                 161
;	SQL_SQL92_REVOKE:                                    162
;	SQL_SQL92_ROW_VALUE_CONSTRUCTOR:                     163
;	SQL_SQL92_STRING_FUNCTIONS:                          164
;	SQL_SQL92_VALUE_EXPRESSIONS:                         165
;	SQL_STANDARD_CLI_CONFORMANCE:                        166
;	SQL_STATIC_CURSOR_ATTRIBUTES1:                       167
;	SQL_STATIC_CURSOR_ATTRIBUTES2:                       168
;	SQL_AGGREGATE_FUNCTIONS:                             169
;	SQL_DDL_INDEX:                                       170
	SQL_DM_VER:                                          171
;	SQL_INSERT_STATEMENT:                                172
;	SQL_CONVERT_GUID:                                    173
;	SQL_UNION_STATEMENT:                                  95 ;=SQL_UNION

;	#if ODBCVER >= 0400h [
;	SQL_SCHEMA_INFERENCE:                                174
;	SQL_BINARY_FUNCTIONS:                                175
;	SQL_ISO_STRING_FUNCTIONS:                            176
;	SQL_ISO_BINARY_FUNCTIONS:                            177
;	SQL_LIMIT_ESCAPE_CLAUSE:                             178
;	SQL_NATIVE_ESCAPE_CLAUSE:                            179
;	SQL_RETURN_ESCAPE_CLAUSE:                            180
;	SQL_FORMAT_ESCAPE_CLAUSE:                            181
;	SQL_ISO_DATETIME_FUNCTIONS:                          155 ;=SQL_SQL92_DATETIME_FUNCTIONS
;	SQL_ISO_FOREIGN_KEY_DELETE_RULE:                     156 ;=SQL_SQL92_FOREIGN_KEY_DELETE_RULE
;	SQL_ISO_FOREIGN_KEY_UPDATE_RULE:                     157 ;=SQL_SQL92_FOREIGN_KEY_UPDATE_RULE
;	SQL_ISO_GRANT:                                       158 ;=SQL_SQL92_GRANT
;	SQL_ISO_NUMERIC_VALUE_FUNCTIONS:                     159 ;=SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
;	SQL_ISO_PREDICATES:                                  160 ;=SQL_SQL92_PREDICATES
;	SQL_ISO_RELATIONAL_JOIN_OPERATORS:                   161 ;=SQL_SQL92_RELATIONAL_JOIN_OPERATORS
;	SQL_ISO_REVOKE:                                      162 ;=SQL_SQL92_REVOKE
;	SQL_ISO_ROW_VALUE_CONSTRUCTOR:                       163 ;=SQL_SQL92_ROW_VALUE_CONSTRUCTOR
;	SQL_ISO_VALUE_EXPRESSIONS:                           165 ;=SQL_SQL92_VALUE_EXPRESSIONS
;	] ; ODBCVER >= 0400h

; 	#if ODBCVER >= 0380h [
	;-- Info Types
;	SQL_ASYNC_DBC_FUNCTIONS:                           10023
;	] ; ODBCVER >= 0380h

;	SQL_DRIVER_AWARE_POOLING_SUPPORTED:                10024

;	#if ODBCVER >= 0380h [
;	SQL_ASYNC_NOTIFICATION:                            10025

	;-- Possible values for SQL_ASYNC_NOTIFICATION
;	SQL_ASYNC_NOTIFICATION_NOT_CAPABLE:            00000000h ;0x00000000L
;	SQL_ASYNC_NOTIFICATION_CAPABLE:                00000001h ;0x00000001L
;	] ; ODBCVER >= 0380h

;	SQL_DTC_TRANSITION_COST:                            1750

	;-- SQL_ALTER_TABLE bitmasks

	;-- the following 5 bitmasks are defined in sql
;	SQL_AT_ADD_COLUMN:                             00000001h ;0x00000001L
;	SQL_AT_DROP_COLUMN:                            00000002h ;0x00000002L
;	SQL_AT_ADD_CONSTRAINT:                         00000008h ;0x00000008L
;	SQL_AT_ADD_COLUMN_SINGLE:                      00000020h ;0x00000020L
;	SQL_AT_ADD_COLUMN_DEFAULT:                     00000040h ;0x00000040L
;	SQL_AT_ADD_COLUMN_COLLATION:                   00000080h ;0x00000080L
;	SQL_AT_SET_COLUMN_DEFAULT:                     00000100h ;0x00000100L
;	SQL_AT_DROP_COLUMN_DEFAULT:                    00000200h ;0x00000200L
;	SQL_AT_DROP_COLUMN_CASCADE:                    00000400h ;0x00000400L
;	SQL_AT_DROP_COLUMN_RESTRICT:                   00000800h ;0x00000800L
;	SQL_AT_ADD_TABLE_CONSTRAINT:                   00001000h ;0x00001000L
;	SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE:          00002000h ;0x00002000L
;	SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT:         00004000h ;0x00004000L
;	SQL_AT_CONSTRAINT_NAME_DEFINITION:             00008000h ;0x00008000L
;	SQL_AT_CONSTRAINT_INITIALLY_DEFERRED:          00010000h ;0x00010000L
;	SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE:         00020000h ;0x00020000L
;	SQL_AT_CONSTRAINT_DEFERRABLE:                  00040000h ;0x00040000L
;	SQL_AT_CONSTRAINT_NON_DEFERRABLE:              00080000h ;0x00080000L

	;-- SQL_CONVERT_* return value bitmasks

;	SQL_CVT_CHAR:                                  00000001h ;0x00000001L
;	SQL_CVT_NUMERIC:                               00000002h ;0x00000002L
;	SQL_CVT_DECIMAL:                               00000004h ;0x00000004L
;	SQL_CVT_INTEGER:                               00000008h ;0x00000008L
;	SQL_CVT_SMALLINT:                              00000010h ;0x00000010L
;	SQL_CVT_FLOAT:                                 00000020h ;0x00000020L
;	SQL_CVT_REAL:                                  00000040h ;0x00000040L
;	SQL_CVT_DOUBLE:                                00000080h ;0x00000080L
;	SQL_CVT_VARCHAR:                               00000100h ;0x00000100L
;	SQL_CVT_LONGVARCHAR:                           00000200h ;0x00000200L
;	SQL_CVT_BINARY:                                00000400h ;0x00000400L
;	SQL_CVT_VARBINARY:                             00000800h ;0x00000800L
;	SQL_CVT_BIT:                                   00001000h ;0x00001000L
;	SQL_CVT_TINYINT:                               00002000h ;0x00002000L
;	SQL_CVT_BIGINT:                                00004000h ;0x00004000L
;	SQL_CVT_DATE:                                  00008000h ;0x00008000L
;	SQL_CVT_TIME:                                  00010000h ;0x00010000L
;	SQL_CVT_TIMESTAMP:                             00020000h ;0x00020000L
;	SQL_CVT_LONGVARBINARY:                         00040000h ;0x00040000L
;	SQL_CVT_INTERVAL_YEAR_MONTH:                   00080000h ;0x00080000L
;	SQL_CVT_INTERVAL_DAY_TIME:                     00100000h ;0x00100000L
;	SQL_CVT_WCHAR:                                 00200000h ;0x00200000L
;	SQL_CVT_WLONGVARCHAR:                          00400000h ;0x00400000L
;	SQL_CVT_WVARCHAR:                              00800000h ;0x00800000L
;	SQL_CVT_GUID:                                  01000000h ;0x01000000L

	;-- SQL_CONVERT_FUNCTIONS functions
;	SQL_FN_CVT_CONVERT:                            00000001h ;0x00000001L
;	SQL_FN_CVT_CAST:                               00000002h ;0x00000002L

	;-- SQL_STRING_FUNCTIONS functions

;	SQL_FN_STR_CONCAT:                             00000001h ;0x00000001L
;	SQL_FN_STR_INSERT:                             00000002h ;0x00000002L
;	SQL_FN_STR_LEFT:                               00000004h ;0x00000004L
;	SQL_FN_STR_LTRIM:                              00000008h ;0x00000008L
;	SQL_FN_STR_LENGTH:                             00000010h ;0x00000010L
;	SQL_FN_STR_LOCATE:                             00000020h ;0x00000020L
;	SQL_FN_STR_LCASE:                              00000040h ;0x00000040L
;	SQL_FN_STR_REPEAT:                             00000080h ;0x00000080L
;	SQL_FN_STR_REPLACE:                            00000100h ;0x00000100L
;	SQL_FN_STR_RIGHT:                              00000200h ;0x00000200L
;	SQL_FN_STR_RTRIM:                              00000400h ;0x00000400L
;	SQL_FN_STR_SUBSTRING:                          00000800h ;0x00000800L
;	SQL_FN_STR_UCASE:                              00001000h ;0x00001000L
;	SQL_FN_STR_ASCII:                              00002000h ;0x00002000L
;	SQL_FN_STR_CHAR:                               00004000h ;0x00004000L
;	SQL_FN_STR_DIFFERENCE:                         00008000h ;0x00008000L
;	SQL_FN_STR_LOCATE_2:                           00010000h ;0x00010000L
;	SQL_FN_STR_SOUNDEX:                            00020000h ;0x00020000L
;	SQL_FN_STR_SPACE:                              00040000h ;0x00040000L
;	SQL_FN_STR_BIT_LENGTH:                         00080000h ;0x00080000L
;	SQL_FN_STR_CHAR_LENGTH:                        00100000h ;0x00100000L
;	SQL_FN_STR_CHARACTER_LENGTH:                   00200000h ;0x00200000L
;	SQL_FN_STR_OCTET_LENGTH:                       00400000h ;0x00400000L
;	SQL_FN_STR_POSITION:                           00800000h ;0x00800000L

	;-- SQL_SQL92_STRING_FUNCTIONS
;	SQL_SSF_CONVERT:                               00000001h ;0x00000001L
;	SQL_SSF_LOWER:                                 00000002h ;0x00000002L
;	SQL_SSF_UPPER:                                 00000004h ;0x00000004L
;	SQL_SSF_SUBSTRING:                             00000008h ;0x00000008L
;	SQL_SSF_TRANSLATE:                             00000010h ;0x00000010L
;	SQL_SSF_TRIM_BOTH:                             00000020h ;0x00000020L
;	SQL_SSF_TRIM_LEADING:                          00000040h ;0x00000040L
;	SQL_SSF_TRIM_TRAILING:                         00000080h ;0x00000080L
;	#if ODBCVER >= 0400h [
;	SQL_SSF_OVERLAY:                               00000100h ;0x00000100L
;	SQL_SSF_LENGTH:                                00000200h ;0x00000200L
;	SQL_SSF_POSITION:                              00000400h ;0x00000400L
;	SQL_SSF_CONCAT:                                00000800h ;0x00000800L
;	] ; ODBCVER >= 0400h

	;-- SQL_BINARY_FUNCTIONS functions
;	#if ODBCVER >= 0400h [
;	SQL_FN_BIN_BIT_LENGTH:                         00080000h ;=SQL_FN_STR_BIT_LENGTH
;	SQL_FN_BIN_CONCAT:                             00000001h ;=SQL_FN_STR_CONCAT
;	SQL_FN_BIN_INSERT:                             00000002h ;=SQL_FN_STR_INSERT
;	SQL_FN_BIN_LTRIM:                              00000008h ;=SQL_FN_STR_LTRIM
;	SQL_FN_BIN_OCTET_LENGTH:                       00400000h ;=SQL_FN_STR_OCTET_LENGTH
;	SQL_FN_BIN_POSITION:                           00800000h ;=SQL_FN_STR_POSITION
;	SQL_FN_BIN_RTRIM:                              00000400h ;=SQL_FN_STR_RTRIM
;	SQL_FN_BIN_SUBSTRING:                          00000800h ;=SQL_FN_STR_SUBSTRING
;	] ; ODBCVER >= 0400h

	;-- SQL_SQLBINARY_FUNCTIONS
;	#if ODBCVER >= 0400h [
;	SQL_SBF_CONVERT:                               00000001h ;=SQL_SSF_CONVERT
;	SQL_SBF_SUBSTRING:                             00000008h ;=SQL_SSF_SUBSTRING
;	SQL_SBF_TRIM_BOTH:                             00000020h ;=SQL_SSF_TRIM_BOTH
;	SQL_SBF_TRIM_LEADING:                          00000040h ;=SQL_SSF_TRIM_LEADING
;	SQL_SBF_TRIM_TRAILING:                         00000080h ;=SQL_SSF_TRIM_TRAILING
;	SQL_SBF_OVERLAY:                               00000100h ;=SQL_SSF_OVERLAY
;	SQL_SBF_LENGTH:                                00000200h ;=SQL_SSF_LENGTH
;	SQL_SBF_POSITION:                              00000400h ;=SQL_SSF_POSITION
;	SQL_SBF_CONCAT:                                00000800h ;=SQL_SSF_CONCAT
;	] ; ODBCVER >= 0400h

	;-- SQL_NUMERIC_FUNCTIONS functions

;	SQL_FN_NUM_ABS:                                00000001h ;0x00000001L
;	SQL_FN_NUM_ACOS:                               00000002h ;0x00000002L
;	SQL_FN_NUM_ASIN:                               00000004h ;0x00000004L
;	SQL_FN_NUM_ATAN:                               00000008h ;0x00000008L
;	SQL_FN_NUM_ATAN2:                              00000010h ;0x00000010L
;	SQL_FN_NUM_CEILING:                            00000020h ;0x00000020L
;	SQL_FN_NUM_COS:                                00000040h ;0x00000040L
;	SQL_FN_NUM_COT:                                00000080h ;0x00000080L
;	SQL_FN_NUM_EXP:                                00000100h ;0x00000100L
;	SQL_FN_NUM_FLOOR:                              00000200h ;0x00000200L
;	SQL_FN_NUM_LOG:                                00000400h ;0x00000400L
;	SQL_FN_NUM_MOD:                                00000800h ;0x00000800L
;	SQL_FN_NUM_SIGN:                               00001000h ;0x00001000L
;	SQL_FN_NUM_SIN:                                00002000h ;0x00002000L
;	SQL_FN_NUM_SQRT:                               00004000h ;0x00004000L
;	SQL_FN_NUM_TAN:                                00008000h ;0x00008000L
;	SQL_FN_NUM_PI:                                 00010000h ;0x00010000L
;	SQL_FN_NUM_RAND:                               00020000h ;0x00020000L
;	SQL_FN_NUM_DEGREES:                            00040000h ;0x00040000L
;	SQL_FN_NUM_LOG10:                              00080000h ;0x00080000L
;	SQL_FN_NUM_POWER:                              00100000h ;0x00100000L
;	SQL_FN_NUM_RADIANS:                            00200000h ;0x00200000L
;	SQL_FN_NUM_ROUND:                              00400000h ;0x00400000L
;	SQL_FN_NUM_TRUNCATE:                           00800000h ;0x00800000L

	;-- SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
;	SQL_SNVF_BIT_LENGTH:                           00000001h ;0x00000001L
;	SQL_SNVF_CHAR_LENGTH:                          00000002h ;0x00000002L
;	SQL_SNVF_CHARACTER_LENGTH:                     00000004h ;0x00000004L
;	SQL_SNVF_EXTRACT:                              00000008h ;0x00000008L
;	SQL_SNVF_OCTET_LENGTH:                         00000010h ;0x00000010L
;	SQL_SNVF_POSITION:                             00000020h ;0x00000020L

	;-- SQL_TIMEDATE_FUNCTIONS functions
;	SQL_FN_TD_NOW:                                 00000001h ;0x00000001L
;	SQL_FN_TD_CURDATE:                             00000002h ;0x00000002L
;	SQL_FN_TD_DAYOFMONTH:                          00000004h ;0x00000004L
;	SQL_FN_TD_DAYOFWEEK:                           00000008h ;0x00000008L
;	SQL_FN_TD_DAYOFYEAR:                           00000010h ;0x00000010L
;	SQL_FN_TD_MONTH:                               00000020h ;0x00000020L
;	SQL_FN_TD_QUARTER:                             00000040h ;0x00000040L
;	SQL_FN_TD_WEEK:                                00000080h ;0x00000080L
;	SQL_FN_TD_YEAR:                                00000100h ;0x00000100L
;	SQL_FN_TD_CURTIME:                             00000200h ;0x00000200L
;	SQL_FN_TD_HOUR:                                00000400h ;0x00000400L
;	SQL_FN_TD_MINUTE:                              00000800h ;0x00000800L
;	SQL_FN_TD_SECOND:                              00001000h ;0x00001000L
;	SQL_FN_TD_TIMESTAMPADD:                        00002000h ;0x00002000L
;	SQL_FN_TD_TIMESTAMPDIFF:                       00004000h ;0x00004000L
;	SQL_FN_TD_DAYNAME:                             00008000h ;0x00008000L
;	SQL_FN_TD_MONTHNAME:                           00010000h ;0x00010000L
;	SQL_FN_TD_CURRENT_DATE:                        00020000h ;0x00020000L
;	SQL_FN_TD_CURRENT_TIME:                        00040000h ;0x00040000L
;	SQL_FN_TD_CURRENT_TIMESTAMP:                   00080000h ;0x00080000L
;	SQL_FN_TD_EXTRACT:                             00100000h ;0x00100000L

	;-- SQL_SQL92_DATETIME_FUNCTIONS
;	SQL_SDF_CURRENT_DATE:                          00000001h ;0x00000001L
;	SQL_SDF_CURRENT_TIME:                          00000002h ;0x00000002L
;	SQL_SDF_CURRENT_TIMESTAMP:                     00000004h ;0x00000004L

	;-- SQL_SYSTEM_FUNCTIONS functions
;	SQL_FN_SYS_USERNAME:                           00000001h ;0x00000001L
;	SQL_FN_SYS_DBNAME:                             00000002h ;0x00000002L
;	SQL_FN_SYS_IFNULL:                             00000004h ;0x00000004L

	;-- SQL_TIMEDATE_ADD_INTERVALS and SQL_TIMEDATE_DIFF_INTERVALS functions
;	SQL_FN_TSI_FRAC_SECOND:                        00000001h ;0x00000001L
;	SQL_FN_TSI_SECOND:                             00000002h ;0x00000002L
;	SQL_FN_TSI_MINUTE:                             00000004h ;0x00000004L
;	SQL_FN_TSI_HOUR:                               00000008h ;0x00000008L
;	SQL_FN_TSI_DAY:                                00000010h ;0x00000010L
;	SQL_FN_TSI_WEEK:                               00000020h ;0x00000020L
;	SQL_FN_TSI_MONTH:                              00000040h ;0x00000040L
;	SQL_FN_TSI_QUARTER:                            00000080h ;0x00000080L
;	SQL_FN_TSI_YEAR:                               00000100h ;0x00000100L

	;-- bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES
	;   SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1,
	;   SQL_KEYSET_CURSOR_ATTRIBUTES1, and SQL_STATIC_CURSOR_ATTRIBUTES1
	;
	;-- supported SQLFetchScroll FetchOrientation's
	SQL_CA1_NEXT:                                  00000001h ;0x00000001L
	SQL_CA1_ABSOLUTE:                              00000002h ;0x00000002L
	SQL_CA1_RELATIVE:                              00000004h ;0x00000004L
	SQL_CA1_BOOKMARK:                              00000008h ;0x00000008L

	;-- supported SQLSetPos LockType's
	SQL_CA1_LOCK_NO_CHANGE:                        00000040h ;0x00000040L
	SQL_CA1_LOCK_EXCLUSIVE:                        00000080h ;0x00000080L
	SQL_CA1_LOCK_UNLOCK:                           00000100h ;0x00000100L

	;-- supported SQLSetPos Operations
	SQL_CA1_POS_POSITION:                          00000200h ;0x00000200L
	SQL_CA1_POS_UPDATE:                            00000400h ;0x00000400L
	SQL_CA1_POS_DELETE:                            00000800h ;0x00000800L
	SQL_CA1_POS_REFRESH:                           00001000h ;0x00001000L

	;-- positioned updates and deletes
	SQL_CA1_POSITIONED_UPDATE:                     00002000h ;0x00002000L
	SQL_CA1_POSITIONED_DELETE:                     00004000h ;0x00004000L
	SQL_CA1_SELECT_FOR_UPDATE:                     00008000h ;0x00008000L

	;-- supported SQLBulkOperations operations
	SQL_CA1_BULK_ADD:                              00010000h ;0x00100000L
	SQL_CA1_BULK_UPDATE_BY_BOOKMARK:               00020000h ;0x00200000L
	SQL_CA1_BULK_DELETE_BY_BOOKMARK:               00040000h ;0x00400000L
	SQL_CA1_BULK_FETCH_BY_BOOKMARK:                00080000h ;0x00800000L

	;-- bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES2,
	;   SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2,
	;   SQL_KEYSET_CURSOR_ATTRIBUTES2, and SQL_STATIC_CURSOR_ATTRIBUTES2
	;
	;-- supported values for SQL_ATTR_SCROLL_CONCURRENCY
	SQL_CA2_READ_ONLY_CONCURRENCY:                 00000001h ;0x00000001L
	SQL_CA2_LOCK_CONCURRENCY:                      00000002h ;0x00000002L
	SQL_CA2_OPT_ROWVER_CONCURRENCY:                00000004h ;0x00000004L
	SQL_CA2_OPT_VALUES_CONCURRENCY:                00000008h ;0x00000008L

	;-- sensitivity of the cursor to its own inserts, deletes, and updates
	SQL_CA2_SENSITIVITY_ADDITIONS:                 00000010h ;0x00000010L
	SQL_CA2_SENSITIVITY_DELETIONS:                 00000020h ;0x00000020L
	SQL_CA2_SENSITIVITY_UPDATES:                   00000040h ;0x00000040L

	;-- semantics of SQL_ATTR_MAX_ROWS
	SQL_CA2_MAX_ROWS_SELECT:                       00000080h ;0x00000080L
	SQL_CA2_MAX_ROWS_INSERT:                       00000100h ;0x00000100L
	SQL_CA2_MAX_ROWS_DELETE:                       00000200h ;0x00000200L
	SQL_CA2_MAX_ROWS_UPDATE:                       00000400h ;0x00000400L
	SQL_CA2_MAX_ROWS_CATALOG:                      00000800h ;0x00000800L
	SQL_CA2_MAX_ROWS_AFFECTS_ALL:                  00000F80h ;SQL_CA2_MAX_ROWS_SELECT |
																;SQL_CA2_MAX_ROWS_INSERT | SQL_CA2_MAX_ROWS_DELETE |
																;SQL_CA2_MAX_ROWS_UPDATE | SQL_CA2_MAX_ROWS_CATALOG

	;-- semantics of SQL_DIAG_CURSOR_ROW_COUNT
	SQL_CA2_CRC_EXACT:                             00001000h ;0x00001000L
	SQL_CA2_CRC_APPROXIMATE:                       00002000h ;0x00002000L

	;-- the kinds of positioned statements that can be simulated
	SQL_CA2_SIMULATE_NON_UNIQUE:                   00004000h ;0x00004000L
	SQL_CA2_SIMULATE_TRY_UNIQUE:                   00008000h ;0x00008000L
	SQL_CA2_SIMULATE_UNIQUE:                       00010000h ;0x00010000L

	;-- SQL_ODBC_API_CONFORMANCE values
;	SQL_OAC_NONE:                                      0000h ;0x0000
;	SQL_OAC_LEVEL1:                                    0001h ;0x0001
;	SQL_OAC_LEVEL2:                                    0002h ;0x0002

	;-- SQL_ODBC_SAG_CLI_CONFORMANCE values
;	SQL_OSCC_NOT_COMPLIANT:                            0000h ;0x0000
;	SQL_OSCC_COMPLIANT:                                0001h ;0x0001

	;-- SQL_ODBC_SQL_CONFORMANCE values
;	SQL_OSC_MINIMUM:                                   0000h ;0x0000
;	SQL_OSC_CORE:                                      0001h ;0x0001
;	SQL_OSC_EXTENDED:                                  0002h ;0x0002

	;-- SQL_CONCAT_NULL_BEHAVIOR values
;	SQL_CB_NULL:                                       0000h ;0x0000
;	SQL_CB_NON_NULL:                                   0001h ;0x0001

	;-- SQL_SCROLL_OPTIONS masks
;	SQL_SO_FORWARD_ONLY:                           00000001h ;0x00000001L
;	SQL_SO_KEYSET_DRIVEN:                          00000002h ;0x00000002L
;	SQL_SO_DYNAMIC:                                00000004h ;0x00000004L
;	SQL_SO_MIXED:                                  00000008h ;0x00000008L
;	SQL_SO_STATIC:                                 00000010h ;0x00000010L

	;-- SQL_FETCH_DIRECTION masks
	;
	;-- SQL_FETCH_RESUME is no longer supported
;	SQL_FD_FETCH_RESUME:                           00000040h ;0x00000040L
;	SQL_FD_FETCH_BOOKMARK:                         00000080h ;0x00000080L

	;-- SQL_TXN_ISOLATION_OPTION masks
	;   SQL_TXN_VERSIONING is no longer supported
;	SQL_TXN_VERSIONING:                            00000010h ;0x00000010L

	;-- SQL_CORRELATION_NAME values
;	SQL_CN_NONE:                                       0000h ;0x0000
;	SQL_CN_DIFFERENT:                                  0001h ;0x0001
;	SQL_CN_ANY:                                        0002h ;0x0002

	;-- SQL_NON_NULLABLE_COLUMNS values
;	SQL_NNC_NULL:                                      0000h ;0x0000
;	SQL_NNC_NON_NULL:                                  0001h ;0x0001

	;-- SQL_NULL_COLLATION values
;	SQL_NC_START:                                      0002h ;0x0002
;	SQL_NC_END:                                        0004h ;0x0004

	;-- SQL_FILE_USAGE values
;	SQL_FILE_NOT_SUPPORTED:                            0000h ;0x0000
;	SQL_FILE_TABLE:                                    0001h ;0x0001
;	SQL_FILE_QUALIFIER:                                0002h ;0x0002
;	SQL_FILE_CATALOG:                                  0002h ;=SQL_FILE_QUALIFIER ;-- ODBC 3.0

	;-- SQL_GETDATA_EXTENSIONS values
;	SQL_GD_BLOCK:                                  00000004h ;0x00000004L
;	SQL_GD_BOUND:                                  00000008h ;0x00000008L
;	#if ODBCVER >= 0380h [
;	SQL_GD_OUTPUT_PARAMS:                          00000010h ;0x00000010L
;	] ; ODBCVER >= 0380h
;	#if ODBCVER >= 0400h [
;	SQL_GD_CONCURRENT:                             00000020h ;0x00000020L
;	] ; ODBCVER >= 0400h

	;-- SQL_POSITIONED_STATEMENTS masks
;	SQL_PS_POSITIONED_DELETE:                      00000001h ;0x00000001L
;	SQL_PS_POSITIONED_UPDATE:                      00000002h ;0x00000002L
;	SQL_PS_SELECT_FOR_UPDATE:                      00000004h ;0x00000004L

	;-- SQL_GROUP_BY values
;	SQL_GB_NOT_SUPPORTED:                              0000h ;0x0000
;	SQL_GB_GROUP_BY_EQUALS_SELECT:                     0001h ;0x0001
;	SQL_GB_GROUP_BY_CONTAINS_SELECT:                   0002h ;0x0002
;	SQL_GB_NO_RELATION:                                0003h ;0x0003
;	SQL_GB_COLLATE:                                    0004h ;0x0004

	;-- SQL_OWNER_USAGE masks
;	SQL_OU_DML_STATEMENTS:                         00000001h ;0x00000001L
;	SQL_OU_PROCEDURE_INVOCATION:                   00000002h ;0x00000002L
;	SQL_OU_TABLE_DEFINITION:                       00000004h ;0x00000004L
;	SQL_OU_INDEX_DEFINITION:                       00000008h ;0x00000008L
;	SQL_OU_PRIVILEGE_DEFINITION:                   00000010h ;0x00000010L

	;-- SQL_SCHEMA_USAGE masks
;	SQL_SU_DML_STATEMENTS:                         00000001h ;=SQL_OU_DML_STATEMENTS
;	SQL_SU_PROCEDURE_INVOCATION:                   00000002h ;=SQL_OU_PROCEDURE_INVOCATION
;	SQL_SU_TABLE_DEFINITION:                       00000004h ;=SQL_OU_TABLE_DEFINITION
;	SQL_SU_INDEX_DEFINITION:                       00000008h ;=SQL_OU_INDEX_DEFINITION
;	SQL_SU_PRIVILEGE_DEFINITION:                   00000010h ;=SQL_OU_PRIVILEGE_DEFINITION

	;-- SQL_QUALIFIER_USAGE masks
;	SQL_QU_DML_STATEMENTS:                         00000001h ;0x00000001L
;	SQL_QU_PROCEDURE_INVOCATION:                   00000002h ;0x00000002L
;	SQL_QU_TABLE_DEFINITION:                       00000004h ;0x00000004L
;	SQL_QU_INDEX_DEFINITION:                       00000008h ;0x00000008L
;	SQL_QU_PRIVILEGE_DEFINITION:                   00000010h ;0x00000010L

	;-- SQL_CATALOG_USAGE masks
;	SQL_CU_DML_STATEMENTS:                         00000001h ;=SQL_QU_DML_STATEMENTS
;	SQL_CU_PROCEDURE_INVOCATION:                   00000002h ;=SQL_QU_PROCEDURE_INVOCATION
;	SQL_CU_TABLE_DEFINITION:                       00000004h ;=SQL_QU_TABLE_DEFINITION
;	SQL_CU_INDEX_DEFINITION:                       00000008h ;=SQL_QU_INDEX_DEFINITION
;	SQL_CU_PRIVILEGE_DEFINITION:                   00000010h ;=SQL_QU_PRIVILEGE_DEFINITION

	;-- SQL_SUBQUERIES masks
;	SQL_SQ_COMPARISON:                             00000001h ;0x00000001L
;	SQL_SQ_EXISTS:                                 00000002h ;0x00000002L
;	SQL_SQ_IN:                                     00000004h ;0x00000004L
;	SQL_SQ_QUANTIFIED:                             00000008h ;0x00000008L
;	SQL_SQ_CORRELATED_SUBQUERIES:                  00000010h ;0x00000010L

	;-- SQL_UNION masks
;	SQL_U_UNION:                                   00000001h ;0x00000001L
;	SQL_U_UNION_ALL:                               00000002h ;0x00000002L

	;-- SQL_BOOKMARK_PERSISTENCE values
;	SQL_BP_CLOSE:                                  00000001h ;0x00000001L
;	SQL_BP_DELETE:                                 00000002h ;0x00000002L
;	SQL_BP_DROP:                                   00000004h ;0x00000004L
;	SQL_BP_TRANSACTION:                            00000008h ;0x00000008L
;	SQL_BP_UPDATE:                                 00000010h ;0x00000010L
;	SQL_BP_OTHER_HSTMT:                            00000020h ;0x00000020L
;	SQL_BP_SCROLL:                                 00000040h ;0x00000040L

	;-- SQL_STATIC_SENSITIVITY values
;	SQL_SS_ADDITIONS:                              00000001h ;0x00000001L
;	SQL_SS_DELETIONS:                              00000002h ;0x00000002L
;	SQL_SS_UPDATES:                                00000004h ;0x00000004L

	;-- SQL_VIEW values
;	SQL_CV_CREATE_VIEW:                            00000001h ;0x00000001L
;	SQL_CV_CHECK_OPTION:                           00000002h ;0x00000002L
;	SQL_CV_CASCADED:                               00000004h ;0x00000004L
;	SQL_CV_LOCAL:                                  00000008h ;0x00000008L

	;-- SQL_LOCK_TYPES masks
;	SQL_LCK_NO_CHANGE:                             00000000h ;0x00000001L
;	SQL_LCK_EXCLUSIVE:                             00000000h ;0x00000002L
;	SQL_LCK_UNLOCK:                                00000000h ;0x00000004L

	;-- SQL_POS_OPERATIONS masks
;	SQL_POS_POSITION:                              00000000h ;0x00000001L
;	SQL_POS_REFRESH:                               00000000h ;0x00000002L
;	SQL_POS_UPDATE:                                00000000h ;0x00000004L
;	SQL_POS_DELETE:                                00000000h ;0x00000008L
;	SQL_POS_ADD:                                   00000000h ;0x00000010L

	;-- SQL_QUALIFIER_LOCATION values
;	SQL_QL_START:                                      0001h ;0x0001
;	SQL_QL_END:                                        0002h ;0x0002

	;-- Here start return values for ODBC 3.0 SQLGetInfo
	;-- SQL_AGGREGATE_FUNCTIONS bitmasks
;	SQL_AF_AVG:                                    00000001h ;0x00000001L
;	SQL_AF_COUNT:                                  00000002h ;0x00000002L
;	SQL_AF_MAX:                                    00000004h ;0x00000004L
;	SQL_AF_MIN:                                    00000008h ;0x00000008L
;	SQL_AF_SUM:                                    00000010h ;0x00000010L
;	SQL_AF_DISTINCT:                               00000020h ;0x00000020L
;	SQL_AF_ALL:                                    00000040h ;0x00000040L
;	#if ODBCVER >= 0400h [
;	SQL_AF_EVERY:                                  00000080h ;0x00000080L
;	SQL_AF_ANY:                                    00000100h ;0x00000100L
;	SQL_AF_STDEV_OP:                               00000200h ;0x00000200L
;	SQL_AF_STDEV_SAMP:                             00000400h ;0x00000400L
;	SQL_AF_VAR_SAMP:                               00000800h ;0x00000800L
;	SQL_AF_VAR_POP:                                00001000h ;0x00001000L
;	SQL_AF_ARRAY_AGG:                              00002000h ;0x00002000L
;	SQL_AF_COLLECT:                                00004000h ;0x00004000L
;	SQL_AF_FUSION:                                 00008000h ;0x00008000L
;	SQL_AF_INTERSECTION:	                       00010000h ;0x00010000L
;	] ; ODBCVER >= 0400h

	;-- SQL_SQL_CONFORMANCE bit masks
;	SQL_SC_SQL92_ENTRY:                            00000001h ;0x00000001L
;	SQL_SC_FIPS127_2_TRANSITIONAL:                 00000002h ;0x00000002L
;	SQL_SC_SQL92_INTERMEDIATE:                     00000004h ;0x00000004L
;	SQL_SC_SQL92_FULL:                             00000008h ;0x00000008L

	;-- SQL_DATETIME_LITERALS masks
;	SQL_DL_SQL92_DATE:                             00000001h ;0x00000001L
;	SQL_DL_SQL92_TIME:                             00000002h ;0x00000002L
;	SQL_DL_SQL92_TIMESTAMP:                        00000004h ;0x00000004L
;	SQL_DL_SQL92_INTERVAL_YEAR:                    00000008h ;0x00000008L
;	SQL_DL_SQL92_INTERVAL_MONTH:                   00000010h ;0x00000010L
;	SQL_DL_SQL92_INTERVAL_DAY:                     00000020h ;0x00000020L
;	SQL_DL_SQL92_INTERVAL_HOUR:                    00000040h ;0x00000040L
;	SQL_DL_SQL92_INTERVAL_MINUTE:                  00000080h ;0x00000080L
;	SQL_DL_SQL92_INTERVAL_SECOND:                  00000100h ;0x00000100L
;	SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH:           00000200h ;0x00000200L
;	SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR:             00000400h ;0x00000400L
;	SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE:           00000800h ;0x00000800L
;	SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND:           00001000h ;0x00001000L
;	SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE:          00002000h ;0x00002000L
;	SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND:          00004000h ;0x00004000L
;	SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND:        00008000h ;0x00008000L

	;-- SQL_CATALOG_LOCATION values
;	SQL_CL_START:                                      0001h ;=SQL_QL_START
;	SQL_CL_END:                                        0002h ;=SQL_QL_END

	;-- values for SQL_BATCH_ROW_COUNT
;	SQL_BRC_PROCEDURES:                            00000001h ;0x0000001
;	SQL_BRC_EXPLICIT:                              00000002h ;0x0000002
;	SQL_BRC_ROLLED_UP:                             00000004h ;0x0000004

	;-- bitmasks for SQL_BATCH_SUPPORT
;	SQL_BS_SELECT_EXPLICIT:                        00000001h ;0x00000001L
;	SQL_BS_ROW_COUNT_EXPLICIT:                     00000002h ;0x00000002L
;	SQL_BS_SELECT_PROC:                            00000004h ;0x00000004L
;	SQL_BS_ROW_COUNT_PROC:                         00000008h ;0x00000008L

	;-- Values for SQL_PARAM_ARRAY_ROW_COUNTS getinfo
;	SQL_PARC_BATCH:                                        1
;	SQL_PARC_NO_BATCH:                                     2

	;-- values for SQL_PARAM_ARRAY_SELECTS
;	SQL_PAS_BATCH:                                         1
;	SQL_PAS_NO_BATCH:                                      2
;	SQL_PAS_NO_SELECT:                                     3

	;-- Bitmasks for SQL_INDEX_KEYWORDS
;	SQL_IK_NONE:                                   00000000h ;0x00000000L
;	SQL_IK_ASC:                                    00000001h ;0x00000001L
;	SQL_IK_DESC:                                   00000002h ;0x00000002L
;	SQL_IK_ALL:                                    00000003h ;=SQL_IK_ASC or SQL_IK_DESC

	;-- Bitmasks for SQL_INFO_SCHEMA_VIEWS
;	SQL_ISV_ASSERTIONS:                            00000001h ;0x00000001L
;	SQL_ISV_CHARACTER_SETS:                        00000002h ;0x00000002L
;	SQL_ISV_CHECK_CONSTRAINTS:                     00000004h ;0x00000004L
;	SQL_ISV_COLLATIONS:                            00000008h ;0x00000008L
;	SQL_ISV_COLUMN_DOMAIN_USAGE:                   00000010h ;0x00000010L
;	SQL_ISV_COLUMN_PRIVILEGES:                     00000020h ;0x00000020L
;	SQL_ISV_COLUMNS:                               00000040h ;0x00000040L
;	SQL_ISV_CONSTRAINT_COLUMN_USAGE:               00000080h ;0x00000080L
;	SQL_ISV_CONSTRAINT_TABLE_USAGE:                00000100h ;0x00000100L
;	SQL_ISV_DOMAIN_CONSTRAINTS:                    00000200h ;0x00000200L
;	SQL_ISV_DOMAINS:                               00000400h ;0x00000400L
;	SQL_ISV_KEY_COLUMN_USAGE:                      00000800h ;0x00000800L
;	SQL_ISV_REFERENTIAL_CONSTRAINTS:               00001000h ;0x00001000L
;	SQL_ISV_SCHEMATA:                              00002000h ;0x00002000L
;	SQL_ISV_SQL_LANGUAGES:                         00004000h ;0x00004000L
;	SQL_ISV_TABLE_CONSTRAINTS:                     00008000h ;0x00008000L
;	SQL_ISV_TABLE_PRIVILEGES:                      00010000h ;0x00010000L
;	SQL_ISV_TABLES:                                00020000h ;0x00020000L
;	SQL_ISV_TRANSLATIONS:                          00040000h ;0x00040000L
;	SQL_ISV_USAGE_PRIVILEGES:                      00080000h ;0x00080000L
;	SQL_ISV_VIEW_COLUMN_USAGE:                     00100000h ;0x00100000L
;	SQL_ISV_VIEW_TABLE_USAGE:                      00200000h ;0x00200000L
;	SQL_ISV_VIEWS:                                 00400000h ;0x00400000L

	;-- Bitmasks for SQL_ALTER_DOMAIN
;	SQL_AD_CONSTRAINT_NAME_DEFINITION:             00000001h ;0x00000001L
;	SQL_AD_ADD_DOMAIN_CONSTRAINT:                  00000002h ;0x00000002L
;	SQL_AD_DROP_DOMAIN_CONSTRAINT:                 00000004h ;0x00000004L
;	SQL_AD_ADD_DOMAIN_DEFAULT:                     00000008h ;0x00000008L
;	SQL_AD_DROP_DOMAIN_DEFAULT:                    00000010h ;0x00000010L
;	SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED:      00000020h ;0x00000020L
;	SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE:     00000040h ;0x00000040L
;	SQL_AD_ADD_CONSTRAINT_DEFERRABLE:              00000080h ;0x00000080L
;	SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE:          00000100h ;0x00000100L

	;-- SQL_CREATE_SCHEMA bitmasks
;	SQL_CS_CREATE_SCHEMA:                          00000001h ;0x00000001L
;	SQL_CS_AUTHORIZATION:                          00000002h ;0x00000002L
;	SQL_CS_DEFAULT_CHARACTER_SET:                  00000004h ;0x00000004L

	;-- SQL_CREATE_TRANSLATION bitmasks
;	SQL_CTR_CREATE_TRANSLATION:                    00000001h ;0x00000001L

	;-- SQL_CREATE_ASSERTION bitmasks
;	SQL_CA_CREATE_ASSERTION:                       00000001h ;0x00000001L
;	SQL_CA_CONSTRAINT_INITIALLY_DEFERRED:          00000010h ;0x00000010L
;	SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE:         00000020h ;0x00000020L
;	SQL_CA_CONSTRAINT_DEFERRABLE:                  00000040h ;0x00000040L
;	SQL_CA_CONSTRAINT_NON_DEFERRABLE:              00000080h ;0x00000080L

	;-- SQL_CREATE_CHARACTER_SET bitmasks
;	SQL_CCS_CREATE_CHARACTER_SET:                  00000001h ;0x00000001L
;	SQL_CCS_COLLATE_CLAUSE:                        00000002h ;0x00000002L
;	SQL_CCS_LIMITED_COLLATION:                     00000004h ;0x00000004L

	;-- SQL_CREATE_COLLATION bitmasks
;	SQL_CCOL_CREATE_COLLATION:                     00000001h ;0x00000001L

	;-- SQL_CREATE_DOMAIN bitmasks
;	SQL_CDO_CREATE_DOMAIN:                         00000001h ;0x00000001L
;	SQL_CDO_DEFAULT:                               00000002h ;0x00000002L
;	SQL_CDO_CONSTRAINT:                            00000004h ;0x00000004L
;	SQL_CDO_COLLATION:                             00000008h ;0x00000008L
;	SQL_CDO_CONSTRAINT_NAME_DEFINITION:            00000010h ;0x00000010L
;	SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED:         00000020h ;0x00000020L
;	SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE:        00000040h ;0x00000040L
;	SQL_CDO_CONSTRAINT_DEFERRABLE:                 00000080h ;0x00000080L
;	SQL_CDO_CONSTRAINT_NON_DEFERRABLE:             00000100h ;0x00000100L

	;-- SQL_CREATE_TABLE bitmasks
;	SQL_CT_CREATE_TABLE:                           00000001h ;0x00000001L
;	SQL_CT_COMMIT_PRESERVE:                        00000002h ;0x00000002L
;	SQL_CT_COMMIT_DELETE:                          00000004h ;0x00000004L
;	SQL_CT_GLOBAL_TEMPORARY:                       00000008h ;0x00000008L
;	SQL_CT_LOCAL_TEMPORARY:                        00000010h ;0x00000010L
;	SQL_CT_CONSTRAINT_INITIALLY_DEFERRED:          00000020h ;0x00000020L
;	SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE:         00000040h ;0x00000040L
;	SQL_CT_CONSTRAINT_DEFERRABLE:                  00000080h ;0x00000080L
;	SQL_CT_CONSTRAINT_NON_DEFERRABLE:              00000100h ;0x00000100L
;	SQL_CT_COLUMN_CONSTRAINT:                      00000200h ;0x00000200L
;	SQL_CT_COLUMN_DEFAULT:                         00000400h ;0x00000400L
;	SQL_CT_COLUMN_COLLATION:                       00000800h ;0x00000800L
;	SQL_CT_TABLE_CONSTRAINT:                       00001000h ;0x00001000L
;	SQL_CT_CONSTRAINT_NAME_DEFINITION:             00002000h ;0x00002000L

	;-- SQL_DDL_INDEX bitmasks
;	SQL_DI_CREATE_INDEX:                           00000001h ;0x00000001L
;	SQL_DI_DROP_INDEX:                             00000002h ;0x00000002L

	;-- SQL_DROP_COLLATION bitmasks
;	SQL_DC_DROP_COLLATION:                         00000001h ;0x00000001L

	;-- SQL_DROP_DOMAIN bitmasks
;	SQL_DD_DROP_DOMAIN:                            00000001h ;0x00000001L
;	SQL_DD_RESTRICT:                               00000002h ;0x00000002L
;	SQL_DD_CASCADE:                                00000004h ;0x00000004L

	;-- SQL_DROP_SCHEMA bitmasks
;	SQL_DS_DROP_SCHEMA:                            00000001h ;0x00000001L
;	SQL_DS_RESTRICT:                               00000002h ;0x00000002L
;	SQL_DS_CASCADE:                                00000004h ;0x00000004L

	;-- SQL_DROP_CHARACTER_SET bitmasks
;	SQL_DCS_DROP_CHARACTER_SET:                    00000001h ;0x00000001L

	;-- SQL_DROP_ASSERTION bitmasks
;	SQL_DA_DROP_ASSERTION:                         00000001h ;0x00000001L

	;-- SQL_DROP_TABLE bitmasks
;	SQL_DT_DROP_TABLE:                             00000001h ;0x00000001L
;	SQL_DT_RESTRICT:                               00000002h ;0x00000002L
;	SQL_DT_CASCADE:                                00000004h ;0x00000004L

	;-- SQL_DROP_TRANSLATION bitmasks
;	SQL_DTR_DROP_TRANSLATION:                      00000001h ;0x00000001L

	;-- SQL_DROP_VIEW bitmasks
;	SQL_DV_DROP_VIEW:                              00000001h ;0x00000001L
;	SQL_DV_RESTRICT:                               00000002h ;0x00000002L
;	SQL_DV_CASCADE:                                00000004h ;0x00000004L

	;-- SQL_INSERT_STATEMENT bitmasks
;	SQL_IS_INSERT_LITERALS:                        00000001h ;0x00000001L
;	SQL_IS_INSERT_SEARCHED:                        00000002h ;0x00000002L
;	SQL_IS_SELECT_INTO:                            00000004h ;0x00000004L

	;-- SQL_ODBC_INTERFACE_CONFORMANCE values
;	SQL_OIC_CORE:                                          1 ;1UL
;	SQL_OIC_LEVEL1:                                        2 ;2UL
;	SQL_OIC_LEVEL2:                                        3 ;3UL

	;-- SQL_SQL92_FOREIGN_KEY_DELETE_RULE bitmasks
;	SQL_SFKD_CASCADE:                              00000001h ;0x00000001L
;	SQL_SFKD_NO_ACTION:                            00000002h ;0x00000002L
;	SQL_SFKD_SET_DEFAULT:                          00000004h ;0x00000004L
;	SQL_SFKD_SET_NULL:                             00000008h ;0x00000008L

	;-- SQL_SQL92_FOREIGN_KEY_UPDATE_RULE bitmasks
;	SQL_SFKU_CASCADE:                              00000001h ;0x00000001L
;	SQL_SFKU_NO_ACTION:                            00000002h ;0x00000002L
;	SQL_SFKU_SET_DEFAULT:                          00000004h ;0x00000004L
;	SQL_SFKU_SET_NULL:                             00000008h ;0x00000008L

	;-- SQL_SQL92_GRANT bitmasks
;	SQL_SG_USAGE_ON_DOMAIN:                        00000001h ;0x00000001L
;	SQL_SG_USAGE_ON_CHARACTER_SET:                 00000002h ;0x00000002L
;	SQL_SG_USAGE_ON_COLLATION:                     00000004h ;0x00000004L
;	SQL_SG_USAGE_ON_TRANSLATION:                   00000008h ;0x00000008L
;	SQL_SG_WITH_GRANT_OPTION:                      00000010h ;0x00000010L
;	SQL_SG_DELETE_TABLE:                           00000020h ;0x00000020L
;	SQL_SG_INSERT_TABLE:                           00000040h ;0x00000040L
;	SQL_SG_INSERT_COLUMN:                          00000080h ;0x00000080L
;	SQL_SG_REFERENCES_TABLE:                       00000100h ;0x00000100L
;	SQL_SG_REFERENCES_COLUMN:                      00000200h ;0x00000200L
;	SQL_SG_SELECT_TABLE:                           00000400h ;0x00000400L
;	SQL_SG_UPDATE_TABLE:                           00000800h ;0x00000800L
;	SQL_SG_UPDATE_COLUMN:                          00001000h ;0x00001000L

	;-- SQL_SQL92_PREDICATES bitmasks
;	SQL_SP_EXISTS:                                 00000001h ;0x00000001L
;	SQL_SP_ISNOTNULL:                              00000002h ;0x00000002L
;	SQL_SP_ISNULL:                                 00000004h ;0x00000004L
;	SQL_SP_MATCH_FULL:                             00000008h ;0x00000008L
;	SQL_SP_MATCH_PARTIAL:                          00000010h ;0x00000010L
;	SQL_SP_MATCH_UNIQUE_FULL:                      00000020h ;0x00000020L
;	SQL_SP_MATCH_UNIQUE_PARTIAL:                   00000040h ;0x00000040L
;	SQL_SP_OVERLAPS:                               00000080h ;0x00000080L
;	SQL_SP_UNIQUE:                                 00000100h ;0x00000100L
;	SQL_SP_LIKE:                                   00000200h ;0x00000200L
;	SQL_SP_IN:                                     00000400h ;0x00000400L
;	SQL_SP_BETWEEN:                                00000800h ;0x00000800L
;	SQL_SP_COMPARISON:                             00001000h ;0x00001000L
;	SQL_SP_QUANTIFIED_COMPARISON:                  00002000h ;0x00002000L

	;-- SQL_SQL92_RELATIONAL_JOIN_OPERATORS bitmasks
;	SQL_SRJO_CORRESPONDING_CLAUSE:                 00000001h ;0x00000001L
;	SQL_SRJO_CROSS_JOIN:                           00000002h ;0x00000002L
;	SQL_SRJO_EXCEPT_JOIN:                          00000004h ;0x00000004L
;	SQL_SRJO_FULL_OUTER_JOIN:                      00000008h ;0x00000008L
;	SQL_SRJO_INNER_JOIN:                           00000010h ;0x00000010L
;	SQL_SRJO_INTERSECT_JOIN:                       00000020h ;0x00000020L
;	SQL_SRJO_LEFT_OUTER_JOIN:                      00000040h ;0x00000040L
;	SQL_SRJO_NATURAL_JOIN:                         00000080h ;0x00000080L
;	SQL_SRJO_RIGHT_OUTER_JOIN:                     00000100h ;0x00000100L
;	SQL_SRJO_UNION_JOIN:                           00000200h ;0x00000200L

	;-- SQL_SQL92_REVOKE bitmasks
;	SQL_SR_USAGE_ON_DOMAIN:                        00000001h ;0x00000001L
;	SQL_SR_USAGE_ON_CHARACTER_SET:                 00000002h ;0x00000002L
;	SQL_SR_USAGE_ON_COLLATION:                     00000004h ;0x00000004L
;	SQL_SR_USAGE_ON_TRANSLATION:                   00000008h ;0x00000008L
;	SQL_SR_GRANT_OPTION_FOR:                       00000010h ;0x00000010L
;	SQL_SR_CASCADE:                                00000020h ;0x00000020L
;	SQL_SR_RESTRICT:                               00000040h ;0x00000040L
;	SQL_SR_DELETE_TABLE:                           00000080h ;0x00000080L
;	SQL_SR_INSERT_TABLE:                           00000100h ;0x00000100L
;	SQL_SR_INSERT_COLUMN:                          00000200h ;0x00000200L
;	SQL_SR_REFERENCES_TABLE:                       00000400h ;0x00000400L
;	SQL_SR_REFERENCES_COLUMN:                      00000800h ;0x00000800L
;	SQL_SR_SELECT_TABLE:                           00001000h ;0x00001000L
;	SQL_SR_UPDATE_TABLE:                           00002000h ;0x00002000L
;	SQL_SR_UPDATE_COLUMN:                          00004000h ;0x00004000L

	;-- SQL_SQL92_ROW_VALUE_CONSTRUCTOR bitmasks
;	SQL_SRVC_VALUE_EXPRESSION:                     00000001h ;0x00000001L
;	SQL_SRVC_NULL:                                 00000002h ;0x00000002L
;	SQL_SRVC_DEFAULT:                              00000004h ;0x00000004L
;	SQL_SRVC_ROW_SUBQUERY:                         00000008h ;0x00000008L

	;-- SQL_SQL92_VALUE_EXPRESSIONS bitmasks
;	SQL_SVE_CASE:                                  00000001h ;0x00000001L
;	SQL_SVE_CAST:                                  00000002h ;0x00000002L
;	SQL_SVE_COALESCE:                              00000004h ;0x00000004L
;	SQL_SVE_NULLIF:                                00000008h ;0x00000008L

	;-- SQL_STANDARD_CLI_CONFORMANCE bitmasks
;	SQL_SCC_XOPEN_CLI_VERSION1:                    00000001h ;0x00000001L
;	SQL_SCC_ISO92_CLI:                             00000002h ;0x00000002L

	;-- SQL_UNION_STATEMENT bitmasks
;	SQL_US_UNION:                                            SQL_U_UNION
;	SQL_US_UNION_ALL:                                        SQL_U_UNION_ALL

	;-- values for SQL_DRIVER_AWARE_POOLING_SUPPORTED
;	SQL_DRIVER_AWARE_POOLING_NOT_CAPABLE:          00000000h ;0x00000000L
;	SQL_DRIVER_AWARE_POOLING_CAPABLE:              00000001h ;0x00000001L

	;-- SQL_DTC_TRANSITION_COST bitmasks
;	SQL_DTC_ENLIST_EXPENSIVE:                      00000001h ;0x00000001L
;	SQL_DTC_UNENLIST_EXPENSIVE:                    00000002h ;0x00000002L

;	#if ODBCVER >= 0380h [
	;-- possible values for SQL_ASYNC_DBC_FUNCTION
;	SQL_ASYNC_DBC_NOT_CAPABLE:                     00000000h ;0x00000000L
;	SQL_ASYNC_DBC_CAPABLE:                         00000001h ;0x00000001L
;	] ; ODBCVER >= 0380h

	;-- Bitmask values for SQL_LIMIT_ESCAPE_CLAUSE
;	#if ODBCVER >= 0400h [
;	SQL_LC_NONE:                                   00000000h ;0x00000000L
;	SQL_LC_TAKE:                                   00000001h ;0x00000001L
;	SQL_LC_SKIP:                                   00000003h ;0x00000003L
;	] ; ODBCVER >= 0400h

	;-- Bitmask values for SQL_RETURN_ESCAPE_CLAUSE
;	#if ODBCVER >= 0400h [
;	SQL_RC_NONE:                                   00000000h ;0x00000000L
;	SQL_RC_INSERT_SINGLE_ROWID:                    00000001h ;0x00000001L
;	SQL_RC_INSERT_SINGLE_ANY:                   [( 00000002h or SQL_RC_INSERT_SINGLE_ROWID )]
;	SQL_RC_INSERT_MULTIPLE_ROWID:               [( 00000004h or SQL_RC_INSERT_SINGLE_ROWID )]
;	SQL_RC_INSERT_MULTIPLE_ANY:                 [( 00000008h or SQL_RC_INSERT_MULTIPLE_ROWID or SQL_RC_INSERT_SINGLE_ANY )]
;	SQL_RC_INSERT_SELECT_ROWID:                    00000010h ;0x00000010L
;	SQL_RC_INSERT_SELECT_ANY:                   [( 00000020h or SQL_RC_INSERT_SELECT_ROWID )]
;	SQL_RC_UPDATE_ROWID:                           00000040h ;0x00000040L
;	SQL_RC_UPDATE_ANY:                          [( 00000080h or SQL_RC_UPDATE_ROWID )]
;	SQL_RC_DELETE_ROWID:                           00000100h ;0x00000100L
;	SQL_RC_DELETE_ANY:                          [( 00000200h or SQL_RC_DELETE_ROWID )]
;	SQL_RC_SELECT_INTO_ROWID:                      00000400h ;0x00000400L
;	SQL_RC_SELECT_INTO_ANY:                     [( 00000800h or SQL_RC_SELECT_INTO_ROWID )]
;	] ; ODBCVER >= 0400h

	;-- Bitmask values for SQL_FORMAT_ESCAPE_CLAUSE
;	#if ODBCVER >= 0400h [
;	SQL_FC_NONE:                                   00000000h ;0x00000000L
;	SQL_FC_JSON:                                   00000001h ;0x00000001L
;	SQL_FC_JSON_BINARY:                            00000002h ;0x00000002L
;	] ; ODBCVER >= 0400h

	;-- additional SQLDataSources fetch directions
	SQL_FETCH_FIRST_USER:                                 31
	SQL_FETCH_FIRST_SYSTEM:                               32

	;-- Defines for SQLSetPos
;	SQL_ENTIRE_ROWSET:                                     0

	;-- Operations in SQLSetPos
	SQL_POSITION:                                          0 ;-- 1.0 FALSE
;	SQL_REFRESH:                                           1 ;-- 1.0 TRUE
;	SQL_UPDATE:                                            2
;	SQL_DELETE:                                            3

	;-- Operations in SQLBulkOperations
;	SQL_ADD:                                               4
;	SQL_SETPOS_MAX_OPTION_VALUE:                           4 ;=SQL_ADD
;	SQL_UPDATE_BY_BOOKMARK:                                5
;	SQL_DELETE_BY_BOOKMARK:                                6
;	SQL_FETCH_BY_BOOKMARK:                                 7

	;-- Lock options in SQLSetPos
	SQL_LOCK_NO_CHANGE:                                    0 ;-- 1.0 FALSE
;	SQL_LOCK_EXCLUSIVE:                                    1 ;-- 1.0 TRUE
;	SQL_LOCK_UNLOCK:                                       2

;	SQL_SETPOS_MAX_LOCK_VALUE:                             2 ;=SQL_LOCK_UNLOCK

	;-- Macros for SQLSetPos
;	#define SQL_POSITION_TO    (hstmt irow)                         [SQLSetPos hstmt irow SQL_POSITION SQL_LOCK_NO_CHANGE]
;	#define SQL_LOCK_RECORD    (hstmt irow fLock)                   [SQLSetPos hstmt irow SQL_POSITION fLock]
;	#define SQL_REFRESH_RECORD (hstmt irow fLock)                   [SQLSetPos hstmt irow SQL_REFRESH  fLock]
;	#define SQL_UPDATE_RECORD  (hstmt irow)                         [SQLSetPos hstmt irow SQL_UPDATE   SQL_LOCK_NO_CHANGE]
;	#define SQL_DELETE_RECORD  (hstmt irow)                         [SQLSetPos hstmt irow SQL_DELETE   SQL_LOCK_NO_CHANGE]
;	#define SQL_ADD_RECORD     (hstmt irow)                         [SQLSetPos hstmt irow SQL_ADD      SQL_LOCK_NO_CHANGE]

	;-- Column types and scopes in SQLSpecialColumns
	SQL_BEST_ROWID:                                        1
	SQL_ROWVER:                                            2

	;-- Defines for SQLSpecialColumns (returned in the result set)
	;   SQL_PC_UNKNOWN and SQL_PC_PSEUDO are defined in sql.h
;	SQL_PC_NOT_PSEUDO:                                     1

	;-- Defines for SQLStatistics
	SQL_QUICK:                                             0
	SQL_ENSURE:                                            1

	;-- Defines for SQLStatistics (returned in the result set)
	;   SQL_INDEX_CLUSTERED, SQL_INDEX_HASHED, and SQL_INDEX_OTHER are
	;   defined in sql.h
;	SQL_TABLE_STAT:                                        0

	;-- Defines for SQLTables
;	SQL_ALL_CATALOGS:                                    "%"
;	SQL_ALL_SCHEMAS:                                     "%"
;	SQL_ALL_TABLE_TYPES:                                 "%"

	;-- Options for SQLDriverConnect
	SQL_DRIVER_NOPROMPT:                                   0
;	SQL_DRIVER_COMPLETE:                                   1
;	SQL_DRIVER_PROMPT:                                     2
;	SQL_DRIVER_COMPLETE_REQUIRED:                          3

	;-- Level 2 Functions

	;-- SQLExtendedFetch "fFetchType" values
;	SQL_FETCH_BOOKMARK:                                    8

	;-- SQLExtendedFetch "rgfRowStatus" element values
;	SQL_ROW_SUCCESS:                                       0
;	SQL_ROW_DELETED:                                       1
;	SQL_ROW_UPDATED:                                       2
;	SQL_ROW_NOROW:                                         3
;	SQL_ROW_ADDED:                                         4
;	SQL_ROW_ERROR:                                         5
;	SQL_ROW_SUCCESS_WITH_INFO:                             6
;	SQL_ROW_PROCEED:                                       0
;	SQL_ROW_IGNORE:                                        1

	;-- value for SQL_DESC_ARRAY_STATUS_PTR
;	SQL_PARAM_SUCCESS:                                     0
;	SQL_PARAM_SUCCESS_WITH_INFO:                           6
;	SQL_PARAM_ERROR:                                       5
;	SQL_PARAM_UNUSED:                                      7
;	SQL_PARAM_DIAG_UNAVAILABLE:                            1
;	SQL_PARAM_PROCEED:                                     0
;	SQL_PARAM_IGNORE:                                      1

	;-- Defines for SQLForeignKeys (UPDATE_RULE and DELETE_RULE)
;	SQL_CASCADE:                                           0
;	SQL_RESTRICT:                                          1
;	SQL_SET_NULL:                                          2
;	SQL_NO_ACTION:                                         3
;	SQL_SET_DEFAULT:                                       4

	;-- Note that the following are in a different column of SQLForeignKeys than
	;   the previous #defines.   These are for DEFERRABILITY.
;	SQL_INITIALLY_DEFERRED:                                5
;	SQL_INITIALLY_IMMEDIATE:                               6
;	SQL_NOT_DEFERRABLE:                                    7

	;-- Defines for SQLBindParameter and
	;   SQLProcedureColumns (returned in the result set)
;	SQL_PARAM_TYPE_UNKNOWN                                0:
	SQL_PARAM_INPUT:                                       1
;	SQL_PARAM_INPUT_OUTPUT:                                2
;	SQL_RESULT_COL:                                        3
;	SQL_PARAM_OUTPUT:                                      4
;	SQL_RETURN_VALUE:                                      5
;	#if ODBCVER >= 0380h [
;	SQL_PARAM_INPUT_OUTPUT_STREAM:                         8
;	SQL_PARAM_OUTPUT_STREAM:                              16
;	] ; ODBCVER >= 0380h

	;-- Defines for SQLProcedures (returned in the result set)
;	SQL_PT_UNKNOWN:                                        0
;	SQL_PT_PROCEDURE:                                      1
;	SQL_PT_FUNCTION:                                       2

] ;-- enum



;  ██████  ██████  ██      ███████ ██    ██ ███    ██  ██████  ██████
; ██      ██    ██ ██      ██      ██    ██ ████   ██ ██      ██
;  █████  ██    ██ ██      █████   ██    ██ ██ ██  ██ ██       █████
;      ██ ██ ▄▄ ██ ██      ██      ██    ██ ██  ██ ██ ██           ██
; ██████   ██████  ███████ ██       ██████  ██   ████  ██████ ██████
;             ▀▀

SQL_DATE_STRUCT!: alias struct! [
	year|month    [integer!]
	day|pad       [integer!]
]

SQL_TIME_STRUCT!: alias struct! [
	hour|minute   [integer!]
	second|pad    [integer!]
]

SQL_TIMESTAMP_STRUCT!: alias struct! [
	year|month    [integer!]
	day|hour      [integer!]
	minute|second [integer!]
	fraction      [integer!]
]


;--------------------------------------- ODBC_LIBRARY --
;
;   Compare https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/unicode-function-arguments?view=sql-server-2017
;   for functions having both ANSI (A) and Unicode (W) versions

#import [ODBC_LIBRARY stdcall [

SQLAllocHandle: "SQLAllocHandle" [
	type                    [integer!]
	input                   [integer!]
	output*                 [int-ptr!]
	return:                 [integer!]
]

SQLBindCol: "SQLBindCol" [
	statement               [integer!]
	column-number           [integer!]
	target-type             [integer!]
	target-value            [byte-ptr!]
	buffer-length           [integer!]
	strlen-or-ind           [int-ptr!]
	return:                 [integer!]
]

SQLBindParameter: "SQLBindParameter" [
	statement               [integer!]
	param-number            [integer!]
	input-output-type       [integer!]
	value-type              [integer!]
	parameter-type          [integer!]
	column-size             [integer!]
	decimal-digits          [integer!]
	param-value-ptr         [byte-ptr!]
	buffer-length           [integer!]
	strlen-or-ind-ptr       [int-ptr!]
	return:                 [integer!]
]

SQLCloseCursor: "SQLCloseCursor" [
	statement               [integer!]
	return:                 [integer!]
]

SQLColumnPrivileges: "SQLColumnPrivilegesW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	column-name             [c-string!]
	name-length-4           [integer!]
	return:                 [integer!]
]

SQLColumns: "SQLColumnsW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	column-name             [c-string!]
	name-length-4           [integer!]
	return:                 [integer!]
]

SQLConnect: "SQLConnectW" [
	connection              [integer!]
	server-name             [c-string!]
	length-1                [integer!]
	user-name               [c-string!]
	length-2                [integer!]
	authentication          [c-string!]
	length-3                [integer!]
	return:                 [integer!]
]

SQLDataSources: "SQLDataSourcesW" [
	enviromment             [integer!]
	direction               [integer!]
	server-name             [byte-ptr!]
	buffer1-length          [integer!]
	server-name-length      [int-ptr!]
	description-name        [byte-ptr!]
	buffer2-length          [integer!]
	description-length      [int-ptr!]
	return:                 [integer!]
]

SQLDescribeCol: "SQLDescribeColW" [
	statement               [integer!]
	column-number           [integer!]
	column-name             [c-string!]
	buffer-length           [integer!]
	name-length             [int-ptr!]
	sql-type                [int-ptr!]
	column-size             [int-ptr!]
	decimal-digits          [int-ptr!]
	nullable                [int-ptr!]
	return:                 [integer!]
]

SQLDisconnect: "SQLDisconnect" [
	connection              [integer!]
	return:                 [integer!]
]

SQLDriverConnect: "SQLDriverConnectW" [
	connection              [integer!]
	window-handle           [byte-ptr!]
	in-connection-string    [byte-ptr!]
	string-length-1         [integer!]
	out-connection-string   [byte-ptr!]
	buffer-length           [integer!]
	string-length-2-ptr     [int-ptr!]
	driver-completion       [integer!]
	return:                 [integer!]
]

SQLDrivers: "SQLDriversW" [
	enviromment             [integer!]
	direction               [integer!]
	description             [byte-ptr!]
	buffer1-length          [integer!]
	description-length      [int-ptr!]
	attributes              [byte-ptr!]
	buffer2-length          [integer!]
	attributes-length       [int-ptr!]
	return:                 [integer!]
]

SQLEndTran: "SQLEndTran" [
	type                    [integer!]
	connection              [integer!]
	completion-type         [integer!]
	return:                 [integer!]
]

SQLExecute: "SQLExecute" [
	statement               [integer!]
	return:                 [integer!]
]

SQLFetch: "SQLFetch" [
	statement               [integer!]
	return:                 [integer!]
]

SQLFetchScroll: "SQLFetchScroll" [
	statement               [integer!]
	direction               [integer!]
	offset                  [integer!]
	return:                 [integer!]
]

SQLForeignKeys: "SQLForeignKeysW" [
	statement               [integer!]
	pk-catalog-name         [c-string!]
	name-length-1           [integer!]
	pk-schema-name          [c-string!]
	name-length-2           [integer!]
	pk-table-name           [c-string!]
	name-length-3           [integer!]
	fk-catalog-name         [c-string!]
	name-length-4           [integer!]
	fk-schema-name          [c-string!]
	name-length-5           [integer!]
	fk-table-name           [c-string!]
	name-length-6           [integer!]
	return:                 [integer!]
]

SQLFreeHandle: "SQLFreeHandle" [
	type                    [integer!]
	statement               [integer!]
	return:                 [integer!]
]

SQLFreeStmt: "SQLFreeStmt" [
	statement               [integer!]
	option                  [integer!]
	return:                 [integer!]
]

SQLGetConnectAttr: "SQLGetConnectAttrW" [
	connection              [integer!]
	attribute               [integer!]
	value                   [byte-ptr!]
	buffer-len              [integer!]
	length-ptr              [int-ptr!]
	return:                 [integer!]
]

SQLGetDiagRec: "SQLGetDiagRecW" [
	type                    [integer!]
	handle                  [integer!]
	record                  [integer!]
	state                   [byte-ptr!]
	error-ptr               [int-ptr!]
	message                 [byte-ptr!]
	length                  [integer!]
	length-ptr              [int-ptr!]
	return:                 [integer!]
]

SQLGetEnvAttr: "SQLGetEnvAttr" [
	environment             [integer!]
	attribute               [integer!]
	value                   [byte-ptr!]
	buffer-len              [integer!]
	length-ptr              [int-ptr!]
	return:                 [integer!]
]

SQLGetInfo: "SQLGetInfo" [
	connection              [integer!]
	infotype                [integer!]
	infovalue               [byte-ptr!]
	buffer-len              [integer!]
	length-ptr              [int-ptr!]
	return:                 [integer!]
]

SQLGetStmtAttr: "SQLGetStmtAttrW" [
	statement               [integer!]
	attribute               [integer!]
	value                   [byte-ptr!]
	buffer-len              [integer!]
	length-ptr              [int-ptr!]
	return:                 [integer!]
]

SQLGetTypeInfo: "SQLGetTypeInfo" [
	statement               [integer!]
	datatype                [integer!]
	return:                 [integer!]
]

SQLMoreResults: "SQLMoreResults" [
	statement               [integer!]
	return:                 [integer!]
]

SQLNativeSql: "SQLNativeSqlW" [
	connection              [integer!]
	in-statement-string     [c-string!]
	string-length-1         [integer!]
	out-statement-string    [byte-ptr!]
	buffer-length           [integer!]
	string-length-2-ptr     [int-ptr!]
	return:                 [integer!]
]

SQLNumResultCols: "SQLNumResultCols" [
	statement               [integer!]
	column-count            [int-ptr!]
	return:                 [integer!]
]

SQLPrepare: "SQLPrepareW" [
	statement               [integer!]
	statement-text          [c-string!]
	text-length             [integer!]
	return:                 [integer!]
]

SQLPrimaryKeys: "SQLPrimaryKeysW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	return:                 [integer!]
]

SQLProcedureColumns: "SQLProcedureColumnsW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	procedure-name          [c-string!]
	name-length-3           [integer!]
	column-name             [c-string!]
	name-length-4           [integer!]
	return:                 [integer!]
]

SQLProcedures: "SQLProceduresW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	procedure-name          [c-string!]
	name-length-3           [integer!]
	return:                 [integer!]
]

SQLRowCount: "SQLRowCount" [
	statement               [integer!]
	row-count-ptr           [int-ptr!]
	return:                 [integer!]
]

SQLSetConnectAttr: "SQLSetConnectAttrW" [
	connection              [integer!]
	attribute               [integer!]
	value                   [integer!]
	length                  [integer!]
	return:                 [integer!]
]

SQLSetEnvAttr: "SQLSetEnvAttr" [
	environment             [integer!]
	attribute               [integer!]
	value                   [integer!]
	length                  [integer!]
	return:                 [integer!]
]

SQLSetPos: "SQLSetPos" [
	statement               [integer!]
	row-number              [integer!]
	operation               [integer!]
	lock-type               [integer!]
	return:                 [integer!]
]

SQLSetStmtAttr: "SQLSetStmtAttrW" [
	statement               [integer!]
	attribute               [integer!]
	value                   [integer!]
	length                  [integer!]
	return:                 [integer!]
]

SQLSpecialColumns: "SQLSpecialColumnsW" [
	statement               [integer!]
	identifier-type         [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	scope                   [integer!]
	nullable                [integer!]
	return:                 [integer!]
]

SQLStatistics: "SQLStatisticsW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	unique                  [integer!]
	reserved                [integer!]
	return:                 [integer!]
]

SQLTablePrivileges: "SQLTablePrivilegesW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	return:                 [integer!]
]

SQLTables: "SQLTablesW" [
	statement               [integer!]
	catalog-name            [c-string!]
	name-length-1           [integer!]
	schema-name             [c-string!]
	name-length-2           [integer!]
	table-name              [c-string!]
	name-length-3           [integer!]
	table-type              [c-string!]
	name-length-4           [integer!]
	return:                 [integer!]
]

]]
