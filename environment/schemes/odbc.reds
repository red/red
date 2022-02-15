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


;---------------------------------------- SQL defines --
;

#define result-of [FFFFh and]




;  ██████  ██████  ██         ██   ██
; ██      ██    ██ ██         ██   ██
;  █████  ██    ██ ██         ███████
;      ██ ██ ▄▄ ██ ██         ██   ██
; ██████   ██████  ███████ ██ ██   ██
;             ▀▀

;-- special length/indicator values
#define SQL_NULL_DATA                                     FFFFh ;-1
;define SQL_DATA_AT_EXEC                                  FFFEh ;-2

;-- return values from functions
#define SQL_SUCCESS                                           0
#define SQL_SUCCESS_WITH_INFO                                 1
#define SQL_NO_DATA                                         100

comment { #if ODBCVER >= 0380h [ }
;define SQL_PARAM_DATA_AVAILABLE                            101
comment { ] ; ODBCVER >= 0380h }

#define SQL_ERROR                                         FFFFh ;-1
#define SQL_INVALID_HANDLE                                FFFEh ;-2

#define SQL_STILL_EXECUTING                                   2
#define SQL_NEED_DATA                                        99

;-- test for SQL_SUCCESS or SQL_SUCCESS_WITH_INFO
;define SQL_SUCCEEDED(rc)                                    [] ;-- FIXME

;-- flags for null-terminated string
#define SQL_NTS                                           FFFDh ;-3
;define SQL_NTSL                                             -3 ;-3L

;-- maximum message length
;define SQL_MAX_MESSAGE_LENGTH                              512

;-- date/time length constants
;define SQL_DATE_LEN                                         10
;define SQL_TIME_LEN                                          8 ;-- add P+1 if precision is nonzero
;define SQL_TIMESTAMP_LEN                                    19 ;-- add P+1 if precision is nonzero

;-- handle type identifiers
#define SQL_HANDLE_ENV                                        1
#define SQL_HANDLE_DBC                                        2
#define SQL_HANDLE_STMT                                       3
;define SQL_HANDLE_DESC                                       4

;-- environment attribute
#define SQL_ATTR_OUTPUT_NTS                               10001

;-- connection attributes
#define SQL_ATTR_AUTO_IPD                                 10001
#define SQL_ATTR_METADATA_ID                              10014

;-- statement attributes
#define SQL_ATTR_APP_ROW_DESC                             10010
#define SQL_ATTR_APP_PARAM_DESC                           10011
#define SQL_ATTR_IMP_ROW_DESC                             10012
#define SQL_ATTR_IMP_PARAM_DESC                           10013
#define SQL_ATTR_CURSOR_SCROLLABLE                        FFFFh ;-1
#define SQL_ATTR_CURSOR_SENSITIVITY                       FFFEh ;-2

;-- SQL_ATTR_CURSOR_SCROLLABLE values
;define SQL_NONSCROLLABLE                                     0
#define SQL_SCROLLABLE                                        1

;define SQL_DESC_COUNT                                     1001
;define SQL_DESC_TYPE                                      1002
;define SQL_DESC_LENGTH                                    1003
;define SQL_DESC_OCTET_LENGTH_PTR                          1004
;define SQL_DESC_PRECISION                                 1005
;define SQL_DESC_SCALE                                     1006
;define SQL_DESC_DATETIME_INTERVAL_CODE                    1007
;define SQL_DESC_NULLABLE                                  1008
;define SQL_DESC_INDICATOR_PTR                             1009
;define SQL_DESC_DATA_PTR                                  1010
;define SQL_DESC_NAME                                      1011
;define SQL_DESC_UNNAMED                                   1012
;define SQL_DESC_OCTET_LENGTH                              1013
;define SQL_DESC_ALLOC_TYPE                                1099

comment { #if ODBCVER >= 0400h [
;define SQL_DESC_CHARACTER_SET_CATALOG                     1018
;define SQL_DESC_CHARACTER_SET_SCHEMA                      1019
;define SQL_DESC_CHARACTER_SET_NAME                        1020
;define SQL_DESC_COLLATION_CATALOG                         1015
;define SQL_DESC_COLLATION_SCHEMA                          1016
;define SQL_DESC_COLLATION_NAME                            1017
;define SQL_DESC_USER_DEFINED_TYPE_CATALOG                 1026
;define SQL_DESC_USER_DEFINED_TYPE_SCHEMA                  1027
;define SQL_DESC_USER_DEFINED_TYPE_NAME                    1028
] ; ODBCVER >= 0400h }

;-- identifiers of fields in the diagnostics area
;define SQL_DIAG_RETURNCODE                                   1
;define SQL_DIAG_NUMBER                                       2
;define SQL_DIAG_ROW_COUNT                                    3
;define SQL_DIAG_SQLSTATE                                     4
;define SQL_DIAG_NATIVE                                       5
;define SQL_DIAG_MESSAGE_TEXT                                 6
;define SQL_DIAG_DYNAMIC_FUNCTION                             7
;define SQL_DIAG_CLASS_ORIGIN                                 8
;define SQL_DIAG_SUBCLASS_ORIGIN                              9
;define SQL_DIAG_CONNECTION_NAME                             10
;define SQL_DIAG_SERVER_NAME                                 11
;define SQL_DIAG_DYNAMIC_FUNCTION_CODE                       12

;-- dynamic function codes
;define SQL_DIAG_ALTER_DOMAIN                                 3
;define SQL_DIAG_ALTER_TABLE                                  4
;define SQL_DIAG_CALL                                         7
;define SQL_DIAG_CREATE_ASSERTION                             6
;define SQL_DIAG_CREATE_CHARACTER_SET                         8
;define SQL_DIAG_CREATE_COLLATION                            10
;define SQL_DIAG_CREATE_DOMAIN                               23
;define SQL_DIAG_CREATE_INDEX                             FFFFh ;-1
;define SQL_DIAG_CREATE_SCHEMA                               64
;define SQL_DIAG_CREATE_TABLE                                77
;define SQL_DIAG_CREATE_TRANSLATION                          79
;define SQL_DIAG_CREATE_VIEW                                 84
;define SQL_DIAG_DELETE_WHERE                                19
;define SQL_DIAG_DROP_ASSERTION                              24
;define SQL_DIAG_DROP_CHARACTER_SET                          25
;define SQL_DIAG_DROP_COLLATION                              26
;define SQL_DIAG_DROP_DOMAIN                                 27
;define SQL_DIAG_DROP_INDEX                               FFFEh ;-2
;define SQL_DIAG_DROP_SCHEMA                                 31
;define SQL_DIAG_DROP_TABLE                                  32
;define SQL_DIAG_DROP_TRANSLATION                            33
;define SQL_DIAG_DROP_VIEW                                   36
;define SQL_DIAG_DYNAMIC_DELETE_CURSOR                       38
;define SQL_DIAG_DYNAMIC_UPDATE_CURSOR                       81
;define SQL_DIAG_GRANT                                       48
;define SQL_DIAG_INSERT                                      50
;define SQL_DIAG_REVOKE                                      59
;define SQL_DIAG_SELECT_CURSOR                               85
;define SQL_DIAG_UNKNOWN_STATEMENT                            0
;define SQL_DIAG_UPDATE_WHERE                                82

;-- SQL data type codes
;define SQL_UNKNOWN_TYPE                                      0
#define SQL_CHAR                                              1
#define SQL_NUMERIC                                           2
#define SQL_DECIMAL                                           3
#define SQL_INTEGER                                           4
#define SQL_SMALLINT                                          5
#define SQL_FLOAT                                             6
#define SQL_REAL                                              7
#define SQL_DOUBLE                                            8
;define SQL_DATETIME                                          9
#define SQL_VARCHAR                                          12

comment { #if ODBCVER >= 0400h [
;define SQL_VARIANT_TYPE                                        SQL_UNKNOWN_TYPE
;define SQL_UDT                                              17
#define SQL_ROW                                              19
;define SQL_ARRAY                                            50
;define SQL_MULTISET                                         55
] ; ODBCVER >= 0400h }

;-- One-parameter shortcuts for date/time data types
#define SQL_TYPE_DATE                                        91
#define SQL_TYPE_TIME                                        92
#define SQL_TYPE_TIMESTAMP                                   93
comment { #if ODBCVER >= 0400h [
;define SQL_TYPE_TIME_WITH_TIMEZONE		                     94
;define SQL_TYPE_TIMESTAMP_WITH_TIMEZONE                     95
] ; ODBCVER >= 0400h }

;-- Statement attribute values for cursor sensitivity
;define SQL_UNSPECIFIED                                       0
;define SQL_INSENSITIVE                                       1
;define SQL_SENSITIVE                                         2

;-- GetTypeInfo() request for all data types
#define SQL_ALL_TYPES                                         0

;-- Default conversion code for SQLBindCol(), SQLBindParam() and SQLGetData()
;define SQL_DEFAULT                                          99

;-- SQLSQLLEN GetData() code indicating that the application row descriptor
;   specifies the data type
;
;define SQL_ARD_TYPE                                      FF9Dh ;-99

comment { #if ODBCVER >= 0380h [ }
;define SQL_APD_TYPE                                      FF9Ch ;-100
comment { ] ; ODBCVER >= 0380h }

;-- SQL date/time type subcodes
;define SQL_CODE_DATE                                         1
;define SQL_CODE_TIME                                         2
;define SQL_CODE_TIMESTAMP                                    3

comment { #if ODBCVER >= 0400h [
;define SQL_CODE_TIME_WITH_TIMEZONE                           4
;define SQL_CODE_TIMESTAMP_WITH_TIMEZONE                      5
] ; ODBCVER >= 0400h }

;-- CLI option values
#define SQL_FALSE                                             0
#define SQL_TRUE                                              1

;-- values of NULLABLE field in descriptor
#define SQL_NO_NULLS                                          0
#define SQL_NULLABLE                                          1

;-- Value returned by SQLGetTypeInfo() to denote that it is
;   not known whether or not a data type supports null values.
;
;define SQL_NULLABLE_UNKNOWN                                  2

;-- Values returned by SQLGetTypeInfo() to show WHERE clause
;   supported
;
;define SQL_PRED_NONE                                         0
;define SQL_PRED_CHAR                                         1
;define SQL_PRED_BASIC                                        2

;-- values of UNNAMED field in descriptor
;define SQL_NAMED                                             0
;define SQL_UNNAMED                                           1

;-- values of ALLOC_TYPE field in descriptor
;define SQL_DESC_ALLOC_AUTO                                   1
;define SQL_DESC_ALLOC_USER                                   2

;-- FreeStmt() options
#define SQL_CLOSE                                             0
;define SQL_DROP                                              1
#define SQL_UNBIND                                            2
#define SQL_RESET_PARAMS                                      3

;-- Codes used for FetchOrientation in SQLFetchScroll(),
;   and in SQLDataSources()
;
#define SQL_FETCH_NEXT                                        1
#define SQL_FETCH_FIRST                                       2

;-- Other codes used for FetchOrientation in SQLFetchScroll()
#define SQL_FETCH_LAST                                        3
#define SQL_FETCH_PRIOR                                       4
#define SQL_FETCH_ABSOLUTE                                    5
#define SQL_FETCH_RELATIVE                                    6

;-- SQLEndTran() options
#define SQL_COMMIT                                            0
;define SQL_ROLLBACK                                          1

;-- null handles returned by SQLAllocHandle()
;define SQL_NULL_HENV                                         0
;define SQL_NULL_HDBC                                         0
;define SQL_NULL_HSTMT                                        0
;define SQL_NULL_HDESC                                        0

;-- null handle used in place of parent handle when allocating HENV
;define SQL_NULL_HANDLE                                       0 ;0L

;-- Values that may appear in the result set of SQLSpecialColumns()
#define SQL_SCOPE_CURROW                                      0
#define SQL_SCOPE_TRANSACTION                                 1
#define SQL_SCOPE_SESSION                                     2

;define SQL_PC_UNKNOWN                                        0
;define SQL_PC_NON_PSEUDO                                     1
;define SQL_PC_PSEUDO                                         2

;-- Reserved value for the IdentifierType argument of SQLSpecialColumns()
;define SQL_ROW_IDENTIFIER                                    1

;-- Reserved values for UNIQUE argument of SQLStatistics()
#define SQL_INDEX_UNIQUE                                      0
#define SQL_INDEX_ALL                                         1

;-- Values that may appear in the result set of SQLStatistics()
;define SQL_INDEX_CLUSTERED                                   1
;define SQL_INDEX_HASHED                                      2
;define SQL_INDEX_OTHER                                       3

;-- SQLGetFunctions() values to identify ODBC APIs
;define SQL_API_SQLALLOCCONNECT                               1
;define SQL_API_SQLALLOCENV                                   2
;define SQL_API_SQLALLOCHANDLE                             1001
;define SQL_API_SQLALLOCSTMT                                  3
;define SQL_API_SQLBINDCOL                                    4
;define SQL_API_SQLBINDPARAM                               1002
;define SQL_API_SQLCANCEL                                     5
;define SQL_API_SQLCLOSECURSOR                             1003
;define SQL_API_SQLCOLATTRIBUTE                               6
;define SQL_API_SQLCOLUMNS                                   40
;define SQL_API_SQLCONNECT                                    7
;define SQL_API_SQLCOPYDESC                                1004
;define SQL_API_SQLDATASOURCES                               57
;define SQL_API_SQLDESCRIBECOL                                8
;define SQL_API_SQLDISCONNECT                                 9
;define SQL_API_SQLENDTRAN                                 1005
;define SQL_API_SQLERROR                                     10
;define SQL_API_SQLEXECDIRECT                                11
;define SQL_API_SQLEXECUTE                                   12
;define SQL_API_SQLFETCH                                     13
;define SQL_API_SQLFETCHSCROLL                             1021
;define SQL_API_SQLFREECONNECT                               14
;define SQL_API_SQLFREEENV                                   15
;define SQL_API_SQLFREEHANDLE                              1006
;define SQL_API_SQLFREESTMT                                  16
;define SQL_API_SQLGETCONNECTATTR                          1007
;define SQL_API_SQLGETCONNECTOPTION                          42
;define SQL_API_SQLGETCURSORNAME                             17
;define SQL_API_SQLGETDATA                                   43
;define SQL_API_SQLGETDESCFIELD                            1008
;define SQL_API_SQLGETDESCREC                              1009
;define SQL_API_SQLGETDIAGFIELD                            1010
;define SQL_API_SQLGETDIAGREC                              1011
;define SQL_API_SQLGETENVATTR                              1012
;define SQL_API_SQLGETFUNCTIONS                              44
;define SQL_API_SQLGETINFO                                   45
;define SQL_API_SQLGETSTMTATTR                             1014
;define SQL_API_SQLGETSTMTOPTION                             46
;define SQL_API_SQLGETTYPEINFO                               47
;define SQL_API_SQLNUMRESULTCOLS                             18
;define SQL_API_SQLPARAMDATA                                 48
;define SQL_API_SQLPREPARE                                   19
;define SQL_API_SQLPUTDATA                                   49
;define SQL_API_SQLROWCOUNT                                  20
;define SQL_API_SQLSETCONNECTATTR                          1016
;define SQL_API_SQLSETCONNECTOPTION                          50
;define SQL_API_SQLSETCURSORNAME                             21
;define SQL_API_SQLSETDESCFIELD                            1017
;define SQL_API_SQLSETDESCREC                              1018
;define SQL_API_SQLSETENVATTR                              1019
;define SQL_API_SQLSETPARAM                                  22
;define SQL_API_SQLSETSTMTATTR                             1020
;define SQL_API_SQLSETSTMTOPTION                             51
;define SQL_API_SQLSPECIALCOLUMNS                            52
;define SQL_API_SQLSTATISTICS                                53
;define SQL_API_SQLTABLES                                    54
;define SQL_API_SQLTRANSACT                                  23
comment { #if ODBCVER >= 0380h [ }
;define SQL_API_SQLCANCELHANDLE                            1550
;define SQL_API_SQLCOMPLETEASYNC                           1551
comment { ] ; ODBCVER >= 0380h }

;-- Information requested by SQLGetInfo()
;define SQL_MAX_DRIVER_CONNECTIONS                            0
;define SQL_MAXIMUM_DRIVER_CONNECTIONS                          SQL_MAX_DRIVER_CONNECTIONS
;define SQL_MAX_CONCURRENT_ACTIVITIES                         1
;define SQL_MAXIMUM_CONCURRENT_ACTIVITIES                       SQL_MAX_CONCURRENT_ACTIVITIES
#define SQL_DATA_SOURCE_NAME                                  2
;define SQL_FETCH_DIRECTION                                   8
#define SQL_SERVER_NAME                                      13
#define SQL_SEARCH_PATTERN_ESCAPE                            14
#define SQL_DBMS_NAME                                        17
#define SQL_DBMS_VER                                         18
#define SQL_ACCESSIBLE_TABLES                                19
#define SQL_ACCESSIBLE_PROCEDURES                            20
;define SQL_CURSOR_COMMIT_BEHAVIOR                           23
#define SQL_DATA_SOURCE_READ_ONLY                            25
;define SQL_DEFAULT_TXN_ISOLATION                            26
;define SQL_IDENTIFIER_CASE                                  28
;define SQL_IDENTIFIER_QUOTE_CHAR                            29
;define SQL_MAX_COLUMN_NAME_LEN                              30
;define SQL_MAXIMUM_COLUMN_NAME_LENGTH                         	SQL_MAX_COLUMN_NAME_LEN
;define SQL_MAX_CURSOR_NAME_LEN                              31
;define SQL_MAXIMUM_CURSOR_NAME_LENGTH                          SQL_MAX_CURSOR_NAME_LEN
;define SQL_MAX_SCHEMA_NAME_LEN                              32
;define SQL_MAXIMUM_SCHEMA_NAME_LENGTH                          SQL_MAX_SCHEMA_NAME_LEN
;define SQL_MAX_CATALOG_NAME_LEN                             34
;define SQL_MAXIMUM_CATALOG_NAME_LENGTH                         SQL_MAX_CATALOG_NAME_LEN
;define SQL_MAX_TABLE_NAME_LEN                               35
;define SQL_SCROLL_CONCURRENCY                               43
;define SQL_TXN_CAPABLE                                      46
;define SQL_TRANSACTION_CAPABLE                                 SQL_TXN_CAPABLE
#define SQL_USER_NAME                                        47
;define SQL_TXN_ISOLATION_OPTION                             72
;define SQL_TRANSACTION_ISOLATION_OPTION                        SQL_TXN_ISOLATION_OPTION
#define SQL_INTEGRITY                                        73
;define SQL_GETDATA_EXTENSIONS                               81
;define SQL_NULL_COLLATION                                   85
;define SQL_ALTER_TABLE                                      86
#define SQL_ORDER_BY_COLUMNS_IN_SELECT                       90
#define SQL_SPECIAL_CHARACTERS                               94
;define SQL_MAX_COLUMNS_IN_GROUP_BY                          97
;define SQL_MAXIMUM_COLUMNS_IN_GROUP_BY                         SQL_MAX_COLUMNS_IN_GROUP_BY
;define SQL_MAX_COLUMNS_IN_INDEX                             98
;define SQL_MAXIMUM_COLUMNS_IN_INDEX                            SQL_MAX_COLUMNS_IN_INDEX
;define SQL_MAX_COLUMNS_IN_ORDER_BY                          99
;define SQL_MAXIMUM_COLUMNS_IN_ORDER_BY                         SQL_MAX_COLUMNS_IN_ORDER_BY
;define SQL_MAX_COLUMNS_IN_SELECT                           100
;define SQL_MAXIMUM_COLUMNS_IN_SELECT                           SQL_MAX_COLUMNS_IN_SELECT
;define SQL_MAX_COLUMNS_IN_TABLE                            101
;define SQL_MAX_INDEX_SIZE                                  102
;define SQL_MAXIMUM_INDEX_SIZE                                  SQL_MAX_INDEX_SIZE
#define SQL_MAX_ROW_SIZE                                    104
;define SQL_MAXIMUM_ROW_SIZE                                    SQL_MAX_ROW_SIZE
;define SQL_MAX_STATEMENT_LEN                               105
;define SQL_MAXIMUM_STATEMENT_LENGTH                            SQL_MAX_STATEMENT_LEN
;define SQL_MAX_TABLES_IN_SELECT                            106
;define SQL_MAXIMUM_TABLES_IN_SELECT                            SQL_MAX_TABLES_IN_SELECT
;define SQL_MAX_USER_NAME_LEN                               107
;define SQL_MAXIMUM_USER_NAME_LENGTH                            SQL_MAX_USER_NAME_LEN
;define SQL_OJ_CAPABILITIES                                 115
;define SQL_OUTER_JOIN_CAPABILITIES                             SQL_OJ_CAPABILITIES

#define SQL_XOPEN_CLI_YEAR                                10000
;define SQL_CURSOR_SENSITIVITY                            10001
#define SQL_DESCRIBE_PARAMETER                            10002
#define SQL_CATALOG_NAME                                  10003
#define SQL_COLLATION_SEQ                                 10004
;define SQL_MAX_IDENTIFIER_LEN                            10005
;define SQL_MAXIMUM_IDENTIFIER_LENGTH                           SQL_MAX_IDENTIFIER_LEN

;-- SQL_ALTER_TABLE bitmasks
;define SQL_AT_ADD_COLUMN                             00000001h
;define SQL_AT_DROP_COLUMN                            00000002h

;define SQL_AT_ADD_CONSTRAINT                         00000008h

;-- The following bitmasks are ODBC extensions and defined in sqlext.h
;ignore SQL_AT_COLUMN_SINGLE                          00000020h
;ignore SQL_AT_ADD_COLUMN_DEFAULT                     00000040h
;ignore SQL_AT_ADD_COLUMN_COLLATION                   00000080h
;ignore SQL_AT_SET_COLUMN_DEFAULT                     00000100h
;ignore SQL_AT_DROP_COLUMN_DEFAULT                    00000200h
;ignore SQL_AT_DROP_COLUMN_CASCADE                    00000400h
;ignore SQL_AT_DROP_COLUMN_RESTRICT                   00000800h
;ignore SQL_AT_ADD_TABLE_CONSTRAINT                   00001000h
;ignore SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE          00002000h
;ignore SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT         00004000h
;ignore SQL_AT_CONSTRAINT_NAME_DEFINITION             00008000h
;ignore SQL_AT_CONSTRAINT_INITIALLY_DEFERRED          00010000h
;ignore SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE         00020000h
;ignore SQL_AT_CONSTRAINT_DEFERRABLE                  00040000h
;ignore SQL_AT_CONSTRAINT_NON_DEFERRABLE              00080000h

;-- SQL_ASYNC_MODE values
;define SQL_AM_NONE                                           0
;define SQL_AM_CONNECTION                                     1
;define SQL_AM_STATEMENT                                      2

;-- SQL_CURSOR_COMMIT_BEHAVIOR values
;define SQL_CB_DELETE                                         0
;define SQL_CB_CLOSE                                          1
;define SQL_CB_PRESERVE                                       2

;-- SQL_FETCH_DIRECTION bitmasks
;define SQL_FD_FETCH_NEXT                             00000001h
;define SQL_FD_FETCH_FIRST                            00000002h
;define SQL_FD_FETCH_LAST                             00000004h
;define SQL_FD_FETCH_PRIOR                            00000008h
;define SQL_FD_FETCH_ABSOLUTE                         00000010h
;define SQL_FD_FETCH_RELATIVE                         00000020h

;-- SQL_GETDATA_EXTENSIONS bitmasks
;define SQL_GD_ANY_COLUMN                             00000001h
;define SQL_GD_ANY_ORDER                              00000002h

;-- SQL_IDENTIFIER_CASE values
;define SQL_IC_UPPER                                          1
;define SQL_IC_LOWER                                          2
;define SQL_IC_SENSITIVE                                      3
;define SQL_IC_MIXED                                          4

;-- SQL_OJ_CAPABILITIES bitmasks
;   NB: this means 'outer join', not what you may be thinking

;define SQL_OJ_LEFT                                   00000001h
;define SQL_OJ_RIGHT                                  00000002h
;define SQL_OJ_FULL                                   00000004h
;define SQL_OJ_NESTED                                 00000008h
;define SQL_OJ_NOT_ORDERED                            00000010h
;define SQL_OJ_INNER                                  00000020h
;define SQL_OJ_ALL_COMPARISON_OPS                     00000040h

;-- SQL_SCROLL_CONCURRENCY bitmasks
;define SQL_SCCO_READ_ONLY                            00000001h
;define SQL_SCCO_LOCK                                 00000002h
;define SQL_SCCO_OPT_ROWVER                           00000004h
;define SQL_SCCO_OPT_VALUES                           00000008h

;-- SQL_TXN_CAPABLE values
;define SQL_TC_NONE                                           0
;define SQL_TC_DML                                            1
;define SQL_TC_ALL                                            2
;define SQL_TC_DDL_COMMIT                                     3
;define SQL_TC_DDL_IGNORE                                     4

;-- SQL_TXN_ISOLATION_OPTION bitmasks
;define SQL_TXN_READ_UNCOMMITTED                      00000001h
;define SQL_TRANSACTION_READ_UNCOMMITTED                        SQL_TXN_READ_UNCOMMITTED
;define SQL_TXN_READ_COMMITTED                        00000002h
;define SQL_TRANSACTION_READ_COMMITTED                          SQL_TXN_READ_COMMITTED
;define SQL_TXN_REPEATABLE_READ                       00000004h
;define SQL_TRANSACTION_REPEATABLE_READ                         SQL_TXN_REPEATABLE_READ
;define SQL_TXN_SERIALIZABLE                          00000008h
;define SQL_TRANSACTION_SERIALIZABLE                            SQL_TXN_SERIALIZABLE

;-- SQL_NULL_COLLATION values
;define SQL_NC_HIGH                                           0
;define SQL_NC_LOW                                            1




;  ██████  ██████  ██      ██    ██  ██████  ██████  ██████  ███████    ██   ██
; ██      ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
;  █████  ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ █████      ███████
;      ██ ██ ▄▄ ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
;  █████   ██████  ███████  ██████   ██████  ██████  ██████  ███████ ██ ██   ██
;             ▀▀

#define SQL_WCHAR                                         FFF8h ; -8
#define SQL_WVARCHAR                                      FFF7h ; -9
#define SQL_WLONGVARCHAR                                  FFF6h ;-10
#define SQL_C_WCHAR                                             SQL_WCHAR
;define SQL_C_TCHAR                                             SQL_C_WCHAR




;  ██████  ██████  ██      ███████ ██   ██ ████████    ██   ██
; ██      ██    ██ ██      ██       ██ ██     ██       ██   ██
;  █████  ██    ██ ██      █████     ███      ██       ███████
;      ██ ██ ▄▄ ██ ██      ██       ██ ██     ██       ██   ██
; ██████   ██████  ███████ ███████ ██   ██    ██    ██ ██   ██
;             ▀▀

;-- generally useful constants
;define SQL_SPEC_MAJOR                                        4 ;-- Major version of specification
;define SQL_SPEC_MINOR                                       00 ;-- Minor version of specification
;define SQL_SPEC_STRING                                 "04.00" ;-- String constant for version

;define SQL_SQLSTATE_SIZE                                     5 ;-- size of SQLSTATE

;typedef SQLTCHAR                                               SQLSTATE[SQL_SQLSTATE_SIZE+1];

;define SQL_MAX_DSN_LENGTH                                   32 ;-- maximum data source name size

;define SQL_MAX_OPTION_STRING_LENGTH                        256

;-- return code SQL_NO_DATA_FOUND is the same as SQL_NO_DATA
;define SQL_NO_DATA_FOUND                                       SQL_NO_DATA

;-- extended function return values
comment { #if ODBCVER >= 0400h [
;define SQL_DATA_AVAILABLE                                  102
;define SQL_METADATA_CHANGED                                103
;define SQL_MORE_DATA                                       104
] ; ODBCVER >= 0400h }

;-- an end handle type
;define SQL_HANDLE_SENV                                       5

;-- env attribute
#define SQL_ATTR_ODBC_VERSION                               200
#define SQL_ATTR_CONNECTION_POOLING                         201
#define SQL_ATTR_CP_MATCH                                   202
;-- For private driver manager
;define SQL_ATTR_APPLICATION_KEY                            203

;-- values for SQL_ATTR_CONNECTION_POOLING
;define SQL_CP_OFF                                            0 ;0UL
;define SQL_CP_ONE_PER_DRIVER                                 1 ;1UL
;define SQL_CP_ONE_PER_HENV                                   2 ;2UL
;define SQL_CP_DRIVER_AWARE                                   3 ;3UL
;define SQL_CP_DEFAULT                                          SQL_CP_OFF

;-- values for SQL_ATTR_CP_MATCH
;define SQL_CP_STRICT_MATCH                                   0 ;0UL
;define SQL_CP_RELAXED_MATCH                                  1 ;1UL
;define SQL_CP_MATCH_DEFAULT                                    SQL_CP_STRICT_MATCH

;-- values for SQL_ATTR_ODBC_VERSION
#define SQL_OV_ODBC2                                          2 ;2UL
#define SQL_OV_ODBC3                                          3 ;3UL

comment { #if ODBCVER >= 0380h [ }
;-- new values for SQL_ATTR_ODBC_VERSION
;   From ODBC 3.8 onwards, we should use <major version> * 100 + <minor version>
#define SQL_OV_ODBC3_80                                     380 ;380UL
comment { ] ; ODBCVER >= 0380h }

comment { #if ODBCVER >= 0400h [
#define SQL_OV_ODBC4                                        400 ;400UL
] ; ODBCVER >= 0400h }

;-- connection attributes
;define SQL_ACCESS_MODE                                     101
#define SQL_AUTOCOMMIT                                      102
;define SQL_LOGIN_TIMEOUT                                   103
;define SQL_OPT_TRACE                                       104
;define SQL_OPT_TRACEFILE                                   105
;define SQL_TRANSLATE_DLL                                   106
;define SQL_TRANSLATE_OPTION                                107
;define SQL_TXN_ISOLATION                                   108
;define SQL_CURRENT_QUALIFIER                               109
;define SQL_ODBC_CURSORS                                    110
;define SQL_QUIET_MODE                                      111
;define SQL_PACKET_SIZE                                     112

;-- connection attributes with new names
#define SQL_ATTR_ACCESS_MODE                                    SQL_ACCESS_MODE
#define SQL_ATTR_AUTOCOMMIT                                     SQL_AUTOCOMMIT
#define SQL_ATTR_CONNECTION_TIMEOUT                         113
#define SQL_ATTR_CURRENT_CATALOG                                SQL_CURRENT_QUALIFIER
#define SQL_ATTR_DISCONNECT_BEHAVIOR                        114
#define SQL_ATTR_ENLIST_IN_DTC                             1207
#define SQL_ATTR_ENLIST_IN_XA                              1208
#define SQL_ATTR_LOGIN_TIMEOUT                                  SQL_LOGIN_TIMEOUT
#define SQL_ATTR_ODBC_CURSORS                                   SQL_ODBC_CURSORS
#define SQL_ATTR_PACKET_SIZE                                    SQL_PACKET_SIZE
#define SQL_ATTR_QUIET_MODE                                     SQL_QUIET_MODE
#define SQL_ATTR_TRACE                                          SQL_OPT_TRACE
#define SQL_ATTR_TRACEFILE                                      SQL_OPT_TRACEFILE
#define SQL_ATTR_TRANSLATE_LIB                                  SQL_TRANSLATE_DLL
#define SQL_ATTR_TRANSLATE_OPTION                               SQL_TRANSLATE_OPTION
#define SQL_ATTR_TXN_ISOLATION                                  SQL_TXN_ISOLATION

#define SQL_ATTR_CONNECTION_DEAD                           1209 ;-- GetConnectAttr only

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
;
;define SQL_ATTR_ANSI_APP                                   115

comment { #if ODBCVER >= 0380h [ }
;define SQL_ATTR_RESET_CONNECTION                           116
#define SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE                 117
comment { ] ; ODBCVER >= 0380h }

;-- Connection attribute 118 is defined in sqlspi.h

comment { #if ODBCVER >= 0380h [ }
#define SQL_ATTR_ASYNC_DBC_EVENT                            119
comment { ] ; ODBCVER >= 0380h }

;-- Connection attribute 120 and 121 are defined in sqlspi.h

comment { #if ODBCVER >= 0400h [
;define SQL_ATTR_CREDENTIALS                                122
;define SQL_ATTR_REFRESH_CONNECTION                         123
] ; ODBCVER >= 0400h }

;-- SQL_ACCESS_MODE options
;define SQL_MODE_READ_WRITE                                   0 ;0UL
;define SQL_MODE_READ_ONLY                                    1 ;1UL
;define SQL_MODE_DEFAULT                                        SQL_MODE_READ_WRITE

;-- SQL_AUTOCOMMIT options
;define SQL_AUTOCOMMIT_OFF                                    0 ;0UL
#define SQL_AUTOCOMMIT_ON                                     1 ;1UL
;define SQL_AUTOCOMMIT_DEFAULT                                  SQL_AUTOCOMMIT_ON

;-- SQL_LOGIN_TIMEOUT options
;define SQL_LOGIN_TIMEOUT_DEFAULT                            15 ;15UL

;-- SQL_OPT_TRACE options
;define SQL_OPT_TRACE_OFF                                     0 ;0UL
;define SQL_OPT_TRACE_ON                                      1 ;1UL
;define SQL_OPT_TRACE_DEFAULT                                   SQL_OPT_TRACE_OFF
;define SQL_OPT_TRACE_FILE_DEFAULT                  "\\SQL.LOG"

;-- SQL_CUR_USE_IF_NEEDED and SQL_CUR_USE_ODBC are deprecated.
;   Please use SQL_CUR_USE_DRIVER for cursor functionalities provided by drivers
;define SQL_CUR_USE_IF_NEEDED                                 0 ;0UL
;define SQL_CUR_USE_ODBC                                      1 ;1UL
;define SQL_CUR_USE_DRIVER                                    2 ;2UL
;define SQL_CUR_DEFAULT                                         SQL_CUR_USE_DRIVER

;-- values for SQL_ATTR_DISCONNECT_BEHAVIOR
;define SQL_DB_RETURN_TO_POOL                                 0 ;0UL
;define SQL_DB_DISCONNECT                                     1 ;1UL
;define SQL_DB_DEFAULT                                          SQL_DB_RETURN_TO_POOL

;-- values for SQL_ATTR_ENLIST_IN_DTC
;define SQL_DTC_DONE                                          0 ;0L

;-- values for SQL_ATTR_CONNECTION_DEAD
;define SQL_CD_TRUE                                           1 ;1L ;-- Connection is closed/dead
;define SQL_CD_FALSE                                          0 ;0L ;-- Connection is open/available

;-- values for SQL_ATTR_ANSI_APP
;define SQL_AA_TRUE                                           1 ;1L ;-- the application is an ANSI app
;define SQL_AA_FALSE                                          0 ;0L ;-- the application is a Unicode app

;-- values for SQL_ATTR_RESET_CONNECTION
comment { #if ODBCVER >= 0380h [ }
;define SQL_RESET_CONNECTION_YES                              1 ;1UL
comment { ] ; ODBCVER >= 0380h }

;-- values for SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE
comment { #if ODBCVER >= 0380h [ }
;define SQL_ASYNC_DBC_ENABLE_ON                               1 ;1UL
;define SQL_ASYNC_DBC_ENABLE_OFF                              0 ;0UL
;define SQL_ASYNC_DBC_ENABLE_DEFAULT                            SQL_ASYNC_DBC_ENABLE_OFF
comment { ] ; ODBCVER >= 0380h }

;-- values for SQL_ATTR_REFRESH_CONNECTION
comment { #if ODBCVER >= 0400h [
;define SQL_REFRESH_NOW                                      -1
;define SQL_REFRESH_AUTO                                      0
;define SQL_REFRESH_MANUAL                                    1
] ; ODBCVER >= 0400h }

;-- statement attributes
;define SQL_QUERY_TIMEOUT                                     0
;define SQL_MAX_ROWS                                          1
;define SQL_NOSCAN                                            2
;define SQL_MAX_LENGTH                                        3
;define SQL_ASYNC_ENABLE                                      4
;define SQL_BIND_TYPE                                         5
#define SQL_CURSOR_TYPE                                       6
;define SQL_CONCURRENCY                                       7
;define SQL_KEYSET_SIZE                                       8
;define SQL_ROWSET_SIZE                                       9
;define SQL_SIMULATE_CURSOR                                  10
;define SQL_RETRIEVE_DATA                                    11
;define SQL_USE_BOOKMARKS                                    12
;define SQL_GET_BOOKMARK                                     13 ;-- GetStmtOption Only
#define SQL_ROW_NUMBER                                       14 ;-- GetStmtOption Only

;-- statement attributes for ODBC 3.0
#define SQL_ATTR_ASYNC_ENABLE                                   SQL_ASYNC_ENABLE
#define SQL_ATTR_CONCURRENCY                                    SQL_CONCURRENCY
#define SQL_ATTR_CURSOR_TYPE                                    SQL_CURSOR_TYPE
#define SQL_ATTR_ENABLE_AUTO_IPD                             15
#define SQL_ATTR_FETCH_BOOKMARK_PTR                          16
#define SQL_ATTR_KEYSET_SIZE                                    SQL_KEYSET_SIZE
#define SQL_ATTR_MAX_LENGTH                                     SQL_MAX_LENGTH
#define SQL_ATTR_MAX_ROWS                                       SQL_MAX_ROWS
#define SQL_ATTR_NOSCAN                                         SQL_NOSCAN
#define SQL_ATTR_PARAM_BIND_OFFSET_PTR                       17
#define SQL_ATTR_PARAM_BIND_TYPE                             18
#define SQL_ATTR_PARAM_OPERATION_PTR                         19
#define SQL_ATTR_PARAM_STATUS_PTR                            20
#define SQL_ATTR_PARAMS_PROCESSED_PTR                        21
#define SQL_ATTR_PARAMSET_SIZE                               22
#define SQL_ATTR_QUERY_TIMEOUT                                  SQL_QUERY_TIMEOUT
#define SQL_ATTR_RETRIEVE_DATA                                  SQL_RETRIEVE_DATA
#define SQL_ATTR_ROW_BIND_OFFSET_PTR                         23
#define SQL_ATTR_ROW_BIND_TYPE                                  SQL_BIND_TYPE
#define SQL_ATTR_ROW_NUMBER                                     SQL_ROW_NUMBER ;-- GetStmtAttr
#define SQL_ATTR_ROW_OPERATION_PTR                           24
#define SQL_ATTR_ROW_STATUS_PTR                              25
#define SQL_ATTR_ROWS_FETCHED_PTR                            26
#define SQL_ATTR_ROW_ARRAY_SIZE                              27
#define SQL_ATTR_SIMULATE_CURSOR                                SQL_SIMULATE_CURSOR
#define SQL_ATTR_USE_BOOKMARKS                                  SQL_USE_BOOKMARKS

comment { #if ODBCVER >= 0380h [ }
#define SQL_ATTR_ASYNC_STMT_EVENT                            29
comment { ] ; ODBCVER >= 0380h }

comment { #if ODBCVER >= 0400h [
;define SQL_ATTR_SAMPLE_SIZE                                 30
;define SQL_ATTR_DYNAMIC_COLUMNS                             31
;define SQL_ATTR_TYPE_EXCEPTION_BEHAVIOR                     32
;define SQL_ATTR_LENGTH_EXCEPTION_BEHAVIOR                   33
] ; ODBCVER >= 0400h }

;-- SQL_ATTR_TYPE_EXCEPTION_BEHAVIOR values
comment { #if ODBCVER >= 0400h [
;define SQL_TE_ERROR                                      0001h
;define SQL_TE_CONTINUE                                   0002h
;define SQL_TE_REPORT                                     0003h
] ; ODBCVER >= 0400h }

;-- SQL_ATTR_LENGTH_EXCEPTION_BEHAVIOR values
comment { #if ODBCVER >= 0400h [
;define SQL_LE_CONTINUE                                   0001h
;define SQL_LE_REPORT                                     0002h
] ; ODBCVER >= 0400h }

;-- New defines for SEARCHABLE column in SQLGetTypeInfo

;define SQL_COL_PRED_CHAR                                       SQL_LIKE_ONLY
;define SQL_COL_PRED_BASIC                                      SQL_ALL_EXCEPT_LIKE

;-- whether an attribute is a pointer or not
;define SQL_IS_POINTER                                    FFFCh ;-4
#define SQL_IS_UINTEGER                                   FFFBh ;-5
#define SQL_IS_INTEGER                                    FFFAh ;-6
;define SQL_IS_USMALLINT                                  FFF9h ;-7
;define SQL_IS_SMALLINT                                   FFF8h ;-8

;-- the value of SQL_ATTR_PARAM_BIND_TYPE
#define SQL_PARAM_BIND_BY_COLUMN                              0 ;0UL
;define SQL_PARAM_BIND_TYPE_DEFAULT                             SQL_PARAM_BIND_BY_COLUMN

;-- SQL_QUERY_TIMEOUT options
;define SQL_QUERY_TIMEOUT_DEFAULT                             0 ;0UL

;-- SQL_MAX_ROWS options
;define SQL_MAX_ROWS_DEFAULT                                  0 ;0UL

;-- SQL_NOSCAN options
;define SQL_NOSCAN_OFF                                        0 ;0UL ;-- 1.0 FALSE
;define SQL_NOSCAN_ON                                         1 ;1UL ;-- 1.0 TRUE
;define SQL_NOSCAN_DEFAULT                                      SQL_NOSCAN_OFF

;-- SQL_MAX_LENGTH options
;define SQL_MAX_LENGTH_DEFAULT                                0 ;0UL

;-- values for SQL_ATTR_ASYNC_ENABLE
;define SQL_ASYNC_ENABLE_OFF                                  0 ;0UL
;define SQL_ASYNC_ENABLE_ON                                   1 ;1UL
;define SQL_ASYNC_ENABLE_DEFAULT                                SQL_ASYNC_ENABLE_OFF

;-- SQL_BIND_TYPE options
#define SQL_BIND_BY_COLUMN                                    0 ;0UL
;define SQL_BIND_TYPE_DEFAULT                                   SQL_BIND_BY_COLUMN ;-- Default value

;-- SQL_CONCURRENCY options
;define SQL_CONCUR_READ_ONLY                                  1
;define SQL_CONCUR_LOCK                                       2
;define SQL_CONCUR_ROWVER                                     3
;define SQL_CONCUR_VALUES                                     4
;define SQL_CONCUR_DEFAULT                                      SQL_CONCUR_READ_ONLY ;-- Default value

;-- SQL_CURSOR_TYPE options
;define SQL_CURSOR_FORWARD_ONLY                               0 ;0UL
;define SQL_CURSOR_KEYSET_DRIVEN                              1 ;1UL
;define SQL_CURSOR_DYNAMIC                                    2 ;2UL
;define SQL_CURSOR_STATIC                                     3 ;3UL
;define SQL_CURSOR_TYPE_DEFAULT                                 SQL_CURSOR_FORWARD_ONLY ;-- Default value

;-- SQL_ROWSET_SIZE options
;define SQL_ROWSET_SIZE_DEFAULT                               1 ;1UL

;-- SQL_KEYSET_SIZE options
;define SQL_KEYSET_SIZE_DEFAULT                               0 ;0UL

;-- SQL_SIMULATE_CURSOR options
;define SQL_SC_NON_UNIQUE                                     0 ;0UL
;define SQL_SC_TRY_UNIQUE                                     1 ;1UL
;define SQL_SC_UNIQUE                                         2 ;2UL

;-- SQL_RETRIEVE_DATA options
;define SQL_RD_OFF                                            0 ;0UL
;define SQL_RD_ON                                             1 ;1UL
;define SQL_RD_DEFAULT                                          SQL_RD_ON

;-- SQL_USE_BOOKMARKS options
;define SQL_UB_OFF                                            0 ;0UL
;define SQL_UB_ON                                             1 ;1UL
;define SQL_UB_DEFAULT                                          SQL_UB_OFF

;-- New values for SQL_USE_BOOKMARKS attribute
;define SQL_UB_FIXED                                            SQL_UB_ON
;define SQL_UB_VARIABLE                                       2 ;2UL

;-- extended descriptor field
;define SQL_DESC_ARRAY_SIZE                                  20
;define SQL_DESC_ARRAY_STATUS_PTR                            21
;define SQL_DESC_AUTO_UNIQUE_VALUE                              SQL_COLUMN_AUTO_INCREMENT
;define SQL_DESC_BASE_COLUMN_NAME                            22
;define SQL_DESC_BASE_TABLE_NAME                             23
;define SQL_DESC_BIND_OFFSET_PTR                             24
;define SQL_DESC_BIND_TYPE                                   25
;define SQL_DESC_CASE_SENSITIVE                                 SQL_COLUMN_CASE_SENSITIVE
;define SQL_DESC_CATALOG_NAME                                   SQL_COLUMN_QUALIFIER_NAME
;define SQL_DESC_CONCISE_TYPE                                   SQL_COLUMN_TYPE
;define SQL_DESC_DATETIME_INTERVAL_PRECISION                 26
;define SQL_DESC_DISPLAY_SIZE                                   SQL_COLUMN_DISPLAY_SIZE
;define SQL_DESC_FIXED_PREC_SCALE                               SQL_COLUMN_MONEY
;define SQL_DESC_LABEL                                          SQL_COLUMN_LABEL
;define SQL_DESC_LITERAL_PREFIX                              27
;define SQL_DESC_LITERAL_SUFFIX                              28
;define SQL_DESC_LOCAL_TYPE_NAME                             29
;define SQL_DESC_MAXIMUM_SCALE                               30
;define SQL_DESC_MINIMUM_SCALE                               31
;define SQL_DESC_NUM_PREC_RADIX                              32
;define SQL_DESC_PARAMETER_TYPE                              33
;define SQL_DESC_ROWS_PROCESSED_PTR                          34
;define SQL_DESC_ROWVER                                      35
;define SQL_DESC_SCHEMA_NAME                                    SQL_COLUMN_OWNER_NAME
;define SQL_DESC_SEARCHABLE                                     SQL_COLUMN_SEARCHABLE
;define SQL_DESC_TYPE_NAME                                      SQL_COLUMN_TYPE_NAME
;define SQL_DESC_TABLE_NAME                                     SQL_COLUMN_TABLE_NAME
;define SQL_DESC_UNSIGNED                                       SQL_COLUMN_UNSIGNED
;define SQL_DESC_UPDATABLE                                      SQL_COLUMN_UPDATABLE

comment { #if ODBCVER >= 0400h [
;define SQL_DESC_MIME_TYPE		                             36
] ; ODBCVER >= 0400h }

;-- defines for diagnostics fields
;define SQL_DIAG_CURSOR_ROW_COUNT                         FB1Fh ;-1249
;define SQL_DIAG_ROW_NUMBER                               FB20h ;-1248
;define SQL_DIAG_COLUMN_NUMBER                            FB21h ;-1247

;-- SQL extended datatypes
#define SQL_DATE                                              9
#define SQL_INTERVAL                                         10
#define SQL_TIME                                             10
#define SQL_TIMESTAMP                                        11
#define SQL_LONGVARCHAR                                   FFFFh ;-1
#define SQL_BINARY                                        FFFEh ;-2
#define SQL_VARBINARY                                     FFFDh ;-3
#define SQL_LONGVARBINARY                                 FFFCh ;-4
#define SQL_BIGINT                                        FFFBh ;-5
#define SQL_TINYINT                                       FFFAh ;-6
#define SQL_BIT                                           FFF9h ;-7
#define SQL_GUID                                          FFF5h ;-11

;-- interval code
;define SQL_CODE_YEAR                                         1
;define SQL_CODE_MONTH                                        2
;define SQL_CODE_DAY                                          3
;define SQL_CODE_HOUR                                         4
;define SQL_CODE_MINUTE                                       5
;define SQL_CODE_SECOND                                       6
;define SQL_CODE_YEAR_TO_MONTH                                7
;define SQL_CODE_DAY_TO_HOUR                                  8
;define SQL_CODE_DAY_TO_MINUTE                                9
;define SQL_CODE_DAY_TO_SECOND                               10
;define SQL_CODE_HOUR_TO_MINUTE                              11
;define SQL_CODE_HOUR_TO_SECOND                              12
;define SQL_CODE_MINUTE_TO_SECOND                            13

#define SQL_INTERVAL_YEAR                                   101 ;-- 100 + SQL_CODE_YEAR
#define SQL_INTERVAL_MONTH                                  102 ;-- 100 + SQL_CODE_MONTH
#define SQL_INTERVAL_DAY                                    103 ;-- 100 + SQL_CODE_DAY
#define SQL_INTERVAL_HOUR                                   104 ;-- 100 + SQL_CODE_HOUR
#define SQL_INTERVAL_MINUTE                                 105 ;-- 100 + SQL_CODE_MINUTE
#define SQL_INTERVAL_SECOND                                 106 ;-- 100 + SQL_CODE_SECOND
#define SQL_INTERVAL_YEAR_TO_MONTH                          107 ;-- 100 + SQL_CODE_YEAR_TO_MONTH
#define SQL_INTERVAL_DAY_TO_HOUR                            108 ;-- 100 + SQL_CODE_DAY_TO_HOUR
#define SQL_INTERVAL_DAY_TO_MINUTE                          109 ;-- 100 + SQL_CODE_DAY_TO_MINUTE
#define SQL_INTERVAL_DAY_TO_SECOND                          110 ;-- 100 + SQL_CODE_DAY_TO_SECOND
#define SQL_INTERVAL_HOUR_TO_MINUTE                         111 ;-- 100 + SQL_CODE_HOUR_TO_MINUTE
#define SQL_INTERVAL_HOUR_TO_SECOND                         112 ;-- 100 + SQL_CODE_HOUR_TO_SECOND
#define SQL_INTERVAL_MINUTE_TO_SECOND                       113 ;-- 100 + SQL_CODE_MINUTE_TO_SECOND

;-- The previous definitions for SQL_UNICODE_ are historical and obsolete

;define SQL_UNICODE                                             SQL_WCHAR
;define SQL_UNICODE_VARCHAR                                     SQL_WVARCHAR
;define SQL_UNICODE_LONGVARCHAR                                 SQL_WLONGVARCHAR
;define SQL_UNICODE_CHAR                                        SQL_WCHAR

;-- C datatype to SQL datatype mapping                          SQL types
;                                                               -------------------
#define SQL_C_CHAR                                              SQL_CHAR
#define SQL_C_LONG                                              SQL_INTEGER
;define SQL_C_SHORT                                             SQL_SMALLINT
;define SQL_C_FLOAT                                             SQL_REAL
#define SQL_C_DOUBLE                                            SQL_DOUBLE
;define SQL_C_NUMERIC                                           SQL_NUMERIC
#define SQL_C_DEFAULT                                        99

;define SQL_SIGNED_OFFSET                                 FFECh ;-20
;define SQL_UNSIGNED_OFFSET                               FFEAh ;-22

;-- C datatype to SQL datatype mapping
;define SQL_C_DATE                                              SQL_DATE
#define SQL_C_TIME                                              SQL_TIME
;define SQL_C_TIMESTAMP                                         SQL_TIMESTAMP
#define SQL_C_TYPE_DATE                                         SQL_TYPE_DATE
#define SQL_C_TYPE_TIME                                         SQL_TYPE_TIME
#define SQL_C_TYPE_TIMESTAMP                                    SQL_TYPE_TIMESTAMP
comment { #if ODBCVER >= 0400h [
;define SQL_C_TYPE_TIME_WITH_TIMEZONE	     					SQL_TYPE_TIME_WITH_TIMEZONE
;define SQL_C_TYPE_TIMESTAMP_WITH_TIMEZONE   					SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
] ; ODBCVER >= 0400h }
;define SQL_C_INTERVAL_YEAR                                     SQL_INTERVAL_YEAR
;define SQL_C_INTERVAL_MONTH                                    SQL_INTERVAL_MONTH
;define SQL_C_INTERVAL_DAY                                      SQL_INTERVAL_DAY
;define SQL_C_INTERVAL_HOUR                                     SQL_INTERVAL_HOUR
;define SQL_C_INTERVAL_MINUTE                                   SQL_INTERVAL_MINUTE
;define SQL_C_INTERVAL_SECOND                                   SQL_INTERVAL_SECOND
;define SQL_C_INTERVAL_YEAR_TO_MONTH                            SQL_INTERVAL_YEAR_TO_MONTH
;define SQL_C_INTERVAL_DAY_TO_HOUR                              SQL_INTERVAL_DAY_TO_HOUR
;define SQL_C_INTERVAL_DAY_TO_MINUTE                            SQL_INTERVAL_DAY_TO_MINUTE
;define SQL_C_INTERVAL_DAY_TO_SECOND                            SQL_INTERVAL_DAY_TO_SECOND
;define SQL_C_INTERVAL_HOUR_TO_MINUTE                           SQL_INTERVAL_HOUR_TO_MINUTE
;define SQL_C_INTERVAL_HOUR_TO_SECOND                           SQL_INTERVAL_HOUR_TO_SECOND
;define SQL_C_INTERVAL_MINUTE_TO_SECOND                         SQL_INTERVAL_MINUTE_TO_SECOND
#define SQL_C_BINARY                                            SQL_BINARY
#define SQL_C_BIT                                               SQL_BIT
;define SQL_C_SBIGINT                                     FFFBh ;-5 -- SQL_BIGINT  + SQL_SIGNED_OFFSET    ;-- SIGNED BIGINT
;define SQL_C_UBIGINT                                     FFFBh ;-5 ;-- SQL_BIGINT  + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED BIGINT
;define SQL_C_TINYINT                                                SQL_TINYINT
;define SQL_C_SLONG                                       FFF0h ;-16 ;-- SQL_C_LONG  + SQL_SIGNED_OFFSET    ;-- SIGNED INTEGER
;define SQL_C_SSHORT                                      FFF1h ;-15 ;-- SQL_C_SHORT + SQL_SIGNED_OFFSET    ;-- SIGNED SMALLINT
;define SQL_C_STINYINT                                    FFF2h ;-14 ;-- SQL_TINYINT + SQL_SIGNED_OFFSET    ;-- SIGNED TINYINT
;define SQL_C_ULONG                                       FFEEh ;-18 ;-- SQL_C_LONG  + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED INTEGER
;define SQL_C_USHORT                                      FFEFh ;-17 ;-- SQL_C_SHORT + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED SMALLINT
;define SQL_C_UTINYINT                                    FFF0h ;-16 ;-- SQL_TINYINT + SQL_UNSIGNED_OFFSET  ;-- UNSIGNED TINYINT

;ifdef _WIN64 [
;define SQL_C_BOOKMARK                                          SQL_C_UBIGINT   ;-- BOOKMARK
;else
;define SQL_C_BOOKMARK                                          SQL_C_ULONG     ;-- BOOKMARK
;endif

;define SQL_C_GUID                                              SQL_GUID

;define SQL_TYPE_NULL                                         0

;-- base value of driver-specific C-Type (max is 0x7fff)
;   define driver-specific C-Type, named as SQL_DRIVER_C_TYPE_BASE,
;   SQL_DRIVER_C_TYPE_BASE+1, SQL_DRIVER_C_TYPE_BASE+2, etc.
comment { #if ODBCVER >= 0380h [ }
;define SQL_DRIVER_C_TYPE_BASE                             4000
comment { ] ; ODBCVER >= 0380h }

;-- base value of driver-specific fields/attributes (max are 0x7fff [16-bit] or 0x00007fff [32-bit])
;   define driver-specific SQL-Type, named as SQL_DRIVER_SQL_TYPE_BASE,
;   SQL_DRIVER_SQL_TYPE_BASE+1, SQL_DRIVER_SQL_TYPE_BASE+2, etc.
;
;   Please note that there is no runtime change in this version of DM.
;   However, we suggest that driver manufacturers adhere to this range
;   as future versions of the DM may enforce these constraints
comment { #if ODBCVER >= 0380h [ }
;define SQL_DRIVER_SQL_TYPE_BASE                          4000h
;define SQL_DRIVER_DESC_FIELD_BASE                        4000h
;define SQL_DRIVER_DIAG_FIELD_BASE                        4000h
;define SQL_DRIVER_INFO_TYPE_BASE                         4000h
;define SQL_DRIVER_CONN_ATTR_BASE                     00004000h ;-- 32-bit
;define SQL_DRIVER_STMT_ATTR_BASE                     00004000h ;-- 32-bit
comment { ] ; ODBCVER >= 0380h }

;define SQL_C_VARBOOKMARK                                       SQL_C_BINARY

;-- define for SQL_DIAG_ROW_NUMBER and SQL_DIAG_COLUMN_NUMBER
;define SQL_NO_ROW_NUMBER                                 FFFFh ;-1
;define SQL_NO_COLUMN_NUMBER                              FFFFh ;-1
;define SQL_ROW_NUMBER_UNKNOWN                            FFFEh ;-2
;define SQL_COLUMN_NUMBER_UNKNOWN                         FFFEh ;-2

;-- SQLBindParameter extensions
;define SQL_DEFAULT_PARAM                                 FFFBh ;-5
;define SQL_IGNORE                                        FFFAh ;-6
;define SQL_COLUMN_IGNORE                                       SQL_IGNORE
;define SQL_LEN_DATA_AT_EXEC_OFFSET                       FF9Ch ;-100
;define SQL_LEN_DATA_AT_EXEC(length)                            [(- (length) + SQL_LEN_DATA_AT_EXEC_OFFSET)]

;-- binary length for driver specific attributes
;define SQL_LEN_BINARY_ATTR_OFFSET                        FF9Ch ;-100
;define SQL_LEN_BINARY_ATTR(length)                             [(- (length) + SQL_LEN_BINARY_ATTR_OFFSET)]

;-- Defines used by Driver Manager when mapping SQLSetParam to SQLBindParameter
;
;define SQL_PARAM_TYPE_DEFAULT                                  SQL_PARAM_INPUT_OUTPUT
;define SQL_SETPARAM_VALUE_MAX                               -1 ;-1L

;-- Extended length/indicator values Values
comment { #if ODBCVER >= 0400h [
;define SQL_DATA_UNAVAILABLE                                    SQL_IGNORE
;define SQL_DATA_AT_FETCH                                       SQL_DATA_AT_EXEC
;define SQL_TYPE_EXCEPTION		                            -20
] ; ODBCVER >= 0400h }

;-- SQLColAttributes defines
;define SQL_COLUMN_COUNT                                      0
;define SQL_COLUMN_NAME                                       1
;define SQL_COLUMN_TYPE                                       2
;define SQL_COLUMN_LENGTH                                     3
;define SQL_COLUMN_PRECISION                                  4
;define SQL_COLUMN_SCALE                                      5
;define SQL_COLUMN_DISPLAY_SIZE                               6
;define SQL_COLUMN_NULLABLE                                   7
;define SQL_COLUMN_UNSIGNED                                   8
;define SQL_COLUMN_MONEY                                      9
;define SQL_COLUMN_UPDATABLE                                 10
;define SQL_COLUMN_AUTO_INCREMENT                            11
;define SQL_COLUMN_CASE_SENSITIVE                            12
;define SQL_COLUMN_SEARCHABLE                                13
;define SQL_COLUMN_TYPE_NAME                                 14
;define SQL_COLUMN_TABLE_NAME                                15
;define SQL_COLUMN_OWNER_NAME                                16
;define SQL_COLUMN_QUALIFIER_NAME                            17
;define SQL_COLUMN_LABEL                                     18
;define SQL_COLATT_OPT_MAX                                      SQL_COLUMN_LABEL
;define SQL_COLATT_OPT_MIN                                      SQL_COLUMN_COUNT

;-- SQLColAttributes subdefines for SQL_COLUMN_UPDATABLE
;define SQL_ATTR_READONLY                                     0
;define SQL_ATTR_WRITE                                        1
;define SQL_ATTR_READWRITE_UNKNOWN                            2

;-- SQLColAttributes subdefines for SQL_COLUMN_SEARCHABLE
;   These are also used by SQLGetInfo
;define SQL_UNSEARCHABLE                                      0
;define SQL_LIKE_ONLY                                         1
;define SQL_ALL_EXCEPT_LIKE                                   2
;define SQL_SEARCHABLE                                        3
;define SQL_PRED_SEARCHABLE                                     SQL_SEARCHABLE

;-- Special return values for SQLGetData
;define SQL_NO_TOTAL                                      FFFCh ;-4

;********************************************
;* SQLGetFunctions: additional values for   *
;* fFunction to represent functions that    *
;* are not in the X/Open spec.              *
;********************************************

;define SQL_API_SQLALLOCHANDLESTD                            73
;define SQL_API_SQLBULKOPERATIONS                            24
;define SQL_API_SQLBINDPARAMETER                             72
;define SQL_API_SQLBROWSECONNECT                             55
;define SQL_API_SQLCOLATTRIBUTES                              6
;define SQL_API_SQLCOLUMNPRIVILEGES                          56
;define SQL_API_SQLDESCRIBEPARAM                             58
;define SQL_API_SQLDRIVERCONNECT                             41
;define SQL_API_SQLDRIVERS                                   71
;define SQL_API_SQLEXTENDEDFETCH                             59
;define SQL_API_SQLFOREIGNKEYS                               60
;define SQL_API_SQLMORERESULTS                               61
;define SQL_API_SQLNATIVESQL                                 62
;define SQL_API_SQLNUMPARAMS                                 63
;define SQL_API_SQLPARAMOPTIONS                              64
;define SQL_API_SQLPRIMARYKEYS                               65
;define SQL_API_SQLPROCEDURECOLUMNS                          66
;define SQL_API_SQLPROCEDURES                                67
;define SQL_API_SQLSETPOS                                    68
;define SQL_API_SQLSETSCROLLOPTIONS                          69
;define SQL_API_SQLTABLEPRIVILEGES                           70

comment { #if ODBCVER >= 0400h [
;define SQL_API_SQLGETNESTEDHANDLE                           74
;define SQL_API_SQLSTRUCTUREDTYPES                           75
;define SQL_API_SQLSTRUCTUREDTYPECOLUMNS                     76
;define SQL_API_SQLNEXTCOLUMN                                77
] ; ODBCVER >= 0400h }

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

;define SQL_API_ALL_FUNCTIONS                                 0 ;-- See CAUTION above

;*----------------------------------------------*
;* 2.X drivers export a dummy function with     *
;* ordinal number SQL_API_LOADBYORDINAL to speed*
;* loading under the windows operating system.  *
;*                                              *
;* CAUTION: Loading by ordinal is not supported *
;* for 3.0 and above drivers.                   *
;*----------------------------------------------*

;define SQL_API_LOADBYORDINAL                               199 ;-- See CAUTION above

;*----------------------------------------------*
;* SQL_API_ODBC3_ALL_FUNCTIONS                  *
;* This returns a bitmap, which allows us to    *
;* handle the higher-valued function numbers.   *
;* Use  SQL_FUNC_EXISTS(bitmap,function_number) *
;* to determine if the function exists.         *
;*----------------------------------------------*

;define SQL_API_ODBC3_ALL_FUNCTIONS                         999
;define SQL_API_ODBC3_ALL_FUNCTIONS_SIZE                    250 ;-- array of 250 words --
;define SQL_FUNC_EXISTS(pfExists, uwAPI)                       [(
;            (* (((UWORD*) (pfExists)) + ((uwAPI) >> 4)) \
;                    & (1 << ((uwAPI) & 0x000F)) \
;                 ) ? SQL_TRUE : SQL_FALSE \
;)]

;************************************************
;* Extended definitions for SQLGetInfo          *
;************************************************

;*---------------------------------*
;* Values in ODBC 2.0 that are not *
;* in the X/Open spec              *
;*---------------------------------*

;define SQL_INFO_FIRST                                        0
;define SQL_ACTIVE_CONNECTIONS                                0 ;-- MAX_DRIVER_CONNECTIONS
;define SQL_ACTIVE_STATEMENTS                                 1 ;-- MAX_CONCURRENT_ACTIVITIES
;define SQL_DRIVER_HDBC                                       3
;define SQL_DRIVER_HENV                                       4
;define SQL_DRIVER_HSTMT                                      5
#define SQL_DRIVER_NAME                                       6
#define SQL_DRIVER_VER                                        7
;define SQL_ODBC_API_CONFORMANCE                              9
#define SQL_ODBC_VER                                         10
#define SQL_ROW_UPDATES                                      11
;define SQL_ODBC_SAG_CLI_CONFORMANCE                         12
;define SQL_ODBC_SQL_CONFORMANCE                             15
#define SQL_PROCEDURES                                       21
;define SQL_CONCAT_NULL_BEHAVIOR                             22
;define SQL_CURSOR_ROLLBACK_BEHAVIOR                         24
#define SQL_EXPRESSIONS_IN_ORDERBY                           27
;define SQL_MAX_OWNER_NAME_LEN                               32 ;-- MAX_SCHEMA_NAME_LEN
;define SQL_MAX_PROCEDURE_NAME_LEN                           33
;define SQL_MAX_QUALIFIER_NAME_LEN                           34 ;-- MAX_CATALOG_NAME_LEN
#define SQL_MULT_RESULT_SETS                                 36
#define SQL_MULTIPLE_ACTIVE_TXN                              37
;define SQL_OUTER_JOINS                                      38
;define SQL_OWNER_TERM                                       39
#define SQL_PROCEDURE_TERM                                   40
;define SQL_QUALIFIER_NAME_SEPARATOR                         41
;define SQL_QUALIFIER_TERM                                   42
;define SQL_SCROLL_OPTIONS                                   44
#define SQL_TABLE_TERM                                       45
;define SQL_CONVERT_FUNCTIONS                                48
;define SQL_NUMERIC_FUNCTIONS                                49
;define SQL_STRING_FUNCTIONS                                 50
;define SQL_SYSTEM_FUNCTIONS                                 51
;define SQL_TIMEDATE_FUNCTIONS                               52
;define SQL_CONVERT_BIGINT                                   53
;define SQL_CONVERT_BINARY                                   54
;define SQL_CONVERT_BIT                                      55
;define SQL_CONVERT_CHAR                                     56
;define SQL_CONVERT_DATE                                     57
;define SQL_CONVERT_DECIMAL                                  58
;define SQL_CONVERT_DOUBLE                                   59
;define SQL_CONVERT_FLOAT                                    60
;define SQL_CONVERT_INTEGER                                  61
;define SQL_CONVERT_LONGVARCHAR                              62
;define SQL_CONVERT_NUMERIC                                  63
;define SQL_CONVERT_REAL                                     64
;define SQL_CONVERT_SMALLINT                                 65
;define SQL_CONVERT_TIME                                     66
;define SQL_CONVERT_TIMESTAMP                                67
;define SQL_CONVERT_TINYINT                                  68
;define SQL_CONVERT_VARBINARY                                69
;define SQL_CONVERT_VARCHAR                                  70
;define SQL_CONVERT_LONGVARBINARY                            71
;define SQL_ODBC_SQL_OPT_IEF                                 73 ;-- SQL_INTEGRITY
;define SQL_CORRELATION_NAME                                 74
;define SQL_NON_NULLABLE_COLUMNS                             75
;define SQL_DRIVER_HLIB                                      76
#define SQL_DRIVER_ODBC_VER                                  77
;define SQL_LOCK_TYPES                                       78
;define SQL_POS_OPERATIONS                                   79
;define SQL_POSITIONED_STATEMENTS                            80
;define SQL_BOOKMARK_PERSISTENCE                             82
;define SQL_STATIC_SENSITIVITY                               83
;define SQL_FILE_USAGE                                       84
#define SQL_COLUMN_ALIAS                                     87
;define SQL_GROUP_BY                                         88
#define SQL_KEYWORDS                                         89
;define SQL_OWNER_USAGE                                      91
;define SQL_QUALIFIER_USAGE                                  92
;define SQL_QUOTED_IDENTIFIER_CASE                           93
;define SQL_SUBQUERIES                                       95
;define SQL_UNION                                            96
#define SQL_MAX_ROW_SIZE_INCLUDES_LONG                      103
;define SQL_MAX_CHAR_LITERAL_LEN                            108
;define SQL_TIMEDATE_ADD_INTERVALS                          109
;define SQL_TIMEDATE_DIFF_INTERVALS                         110
#define SQL_NEED_LONG_DATA_LEN                              111
;define SQL_MAX_BINARY_LITERAL_LEN                          112
#define SQL_LIKE_ESCAPE_CLAUSE                              113
;define SQL_QUALIFIER_LOCATION                              114

;*-----------------------------------------------*
;* ODBC 3.0 SQLGetInfo values that are not part  *
;* of the X/Open standard at this time.   X/Open *
;* standard values are in sql.h.                 *
;*-----------------------------------------------*

;define SQL_ACTIVE_ENVIRONMENTS                             116
;define SQL_ALTER_DOMAIN                                    117

;define SQL_SQL_CONFORMANCE                                 118
;define SQL_DATETIME_LITERALS                               119

;define SQL_ASYNC_MODE                                    10021 ;-- new X/Open spec
;define SQL_BATCH_ROW_COUNT                                 120
;define SQL_BATCH_SUPPORT                                   121
;define SQL_CATALOG_LOCATION                                    SQL_QUALIFIER_LOCATION
#define SQL_CATALOG_NAME_SEPARATOR                              SQL_QUALIFIER_NAME_SEPARATOR
#define SQL_CATALOG_TERM                                        SQL_QUALIFIER_TERM
;define SQL_CATALOG_USAGE                                       SQL_QUALIFIER_USAGE
;define SQL_CONVERT_WCHAR                                   122
;define SQL_CONVERT_INTERVAL_DAY_TIME                       123
;define SQL_CONVERT_INTERVAL_YEAR_MONTH                     124
;define SQL_CONVERT_WLONGVARCHAR                            125
;define SQL_CONVERT_WVARCHAR                                126
;define SQL_CREATE_ASSERTION                                127
;define SQL_CREATE_CHARACTER_SET                            128
;define SQL_CREATE_COLLATION                                129
;define SQL_CREATE_DOMAIN                                   130
;define SQL_CREATE_SCHEMA                                   131
;define SQL_CREATE_TABLE                                    132
;define SQL_CREATE_TRANSLATION                              133
;define SQL_CREATE_VIEW                                     134
;define SQL_DRIVER_HDESC                                    135
;define SQL_DROP_ASSERTION                                  136
;define SQL_DROP_CHARACTER_SET                              137
;define SQL_DROP_COLLATION                                  138
;define SQL_DROP_DOMAIN                                     139
;define SQL_DROP_SCHEMA                                     140
;define SQL_DROP_TABLE                                      141
;define SQL_DROP_TRANSLATION                                142
;define SQL_DROP_VIEW                                       143
;define SQL_DYNAMIC_CURSOR_ATTRIBUTES1                      144
;define SQL_DYNAMIC_CURSOR_ATTRIBUTES2                      145
;define SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1                 146
;define SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2                 147
;define SQL_INDEX_KEYWORDS                                  148
;define SQL_INFO_SCHEMA_VIEWS                               149
;define SQL_KEYSET_CURSOR_ATTRIBUTES1                       150
;define SQL_KEYSET_CURSOR_ATTRIBUTES2                       151
;define SQL_MAX_ASYNC_CONCURRENT_STATEMENTS               10022 ;-- new X/Open spec
;define SQL_ODBC_INTERFACE_CONFORMANCE                      152
;define SQL_PARAM_ARRAY_ROW_COUNTS                          153
;define SQL_PARAM_ARRAY_SELECTS                             154
#define SQL_SCHEMA_TERM                                         SQL_OWNER_TERM
;define SQL_SCHEMA_USAGE                                        SQL_OWNER_USAGE
;define SQL_SQL92_DATETIME_FUNCTIONS                        155
;define SQL_SQL92_FOREIGN_KEY_DELETE_RULE                   156
;define SQL_SQL92_FOREIGN_KEY_UPDATE_RULE                   157
;define SQL_SQL92_GRANT                                     158
;define SQL_SQL92_NUMERIC_VALUE_FUNCTIONS                   159
;define SQL_SQL92_PREDICATES                                160
;define SQL_SQL92_RELATIONAL_JOIN_OPERATORS                 161
;define SQL_SQL92_REVOKE                                    162
;define SQL_SQL92_ROW_VALUE_CONSTRUCTOR                     163
;define SQL_SQL92_STRING_FUNCTIONS                          164
;define SQL_SQL92_VALUE_EXPRESSIONS                         165
;define SQL_STANDARD_CLI_CONFORMANCE                        166
;define SQL_STATIC_CURSOR_ATTRIBUTES1                       167
;define SQL_STATIC_CURSOR_ATTRIBUTES2                       168

;define SQL_AGGREGATE_FUNCTIONS                             169
;define SQL_DDL_INDEX                                       170
#define SQL_DM_VER                                          171
;define SQL_INSERT_STATEMENT                                172
;define SQL_CONVERT_GUID                                    173
;define SQL_UNION_STATEMENT                                     SQL_UNION

comment { #if ODBCVER >= 0400h [
;define SQL_SCHEMA_INFERENCE                                174
;define SQL_BINARY_FUNCTIONS                                175
;define SQL_ISO_STRING_FUNCTIONS                            176
;define SQL_ISO_BINARY_FUNCTIONS                            177
;define SQL_LIMIT_ESCAPE_CLAUSE                             178
;define SQL_NATIVE_ESCAPE_CLAUSE                            179
;define SQL_RETURN_ESCAPE_CLAUSE                            180
;define SQL_FORMAT_ESCAPE_CLAUSE                            181
;define SQL_ISO_DATETIME_FUNCTIONS                              SQL_SQL92_DATETIME_FUNCTIONS
;define SQL_ISO_FOREIGN_KEY_DELETE_RULE                         SQL_SQL92_FOREIGN_KEY_DELETE_RULE
;define SQL_ISO_FOREIGN_KEY_UPDATE_RULE                         SQL_SQL92_FOREIGN_KEY_UPDATE_RULE
;define SQL_ISO_GRANT                                           SQL_SQL92_GRANT
;define SQL_ISO_NUMERIC_VALUE_FUNCTIONS                         SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
;define SQL_ISO_PREDICATES                                      SQL_SQL92_PREDICATES
;define SQL_ISO_RELATIONAL_JOIN_OPERATORS                       SQL_SQL92_RELATIONAL_JOIN_OPERATORS
;define SQL_ISO_REVOKE                                          SQL_SQL92_REVOKE
;define SQL_ISO_ROW_VALUE_CONSTRUCTOR                           SQL_SQL92_ROW_VALUE_CONSTRUCTOR
;define SQL_ISO_VALUE_EXPRESSIONS                               SQL_SQL92_VALUE_EXPRESSIONS
] ; ODBCVER >= 0400h }

comment { #if ODBCVER >= 0380h [ }
;-- Info Types
;define SQL_ASYNC_DBC_FUNCTIONS                           10023
comment { ] ; ODBCVER >= 0380h }

;define SQL_DRIVER_AWARE_POOLING_SUPPORTED                10024

comment { #if ODBCVER >= 0380h [ }
;define SQL_ASYNC_NOTIFICATION                            10025

;-- Possible values for SQL_ASYNC_NOTIFICATION
;define SQL_ASYNC_NOTIFICATION_NOT_CAPABLE            00000000h ;0x00000000L
;define SQL_ASYNC_NOTIFICATION_CAPABLE                00000001h ;0x00000001L
comment { ] ; ODBCVER >= 0380h }

;define SQL_DTC_TRANSITION_COST                            1750

;-- SQL_ALTER_TABLE bitmasks

;-- the following 5 bitmasks are defined in sql
;define SQL_AT_ADD_COLUMN                             00000001h ;0x00000001L
;define SQL_AT_DROP_COLUMN                            00000002h ;0x00000002L
;define SQL_AT_ADD_CONSTRAINT                         00000008h ;0x00000008L
;
;define SQL_AT_ADD_COLUMN_SINGLE                      00000020h ;0x00000020L
;define SQL_AT_ADD_COLUMN_DEFAULT                     00000040h ;0x00000040L
;define SQL_AT_ADD_COLUMN_COLLATION                   00000080h ;0x00000080L
;define SQL_AT_SET_COLUMN_DEFAULT                     00000100h ;0x00000100L
;define SQL_AT_DROP_COLUMN_DEFAULT                    00000200h ;0x00000200L
;define SQL_AT_DROP_COLUMN_CASCADE                    00000400h ;0x00000400L
;define SQL_AT_DROP_COLUMN_RESTRICT                   00000800h ;0x00000800L
;define SQL_AT_ADD_TABLE_CONSTRAINT                   00001000h ;0x00001000L
;define SQL_AT_DROP_TABLE_CONSTRAINT_CASCADE          00002000h ;0x00002000L
;define SQL_AT_DROP_TABLE_CONSTRAINT_RESTRICT         00004000h ;0x00004000L
;define SQL_AT_CONSTRAINT_NAME_DEFINITION             00008000h ;0x00008000L
;define SQL_AT_CONSTRAINT_INITIALLY_DEFERRED          00010000h ;0x00010000L
;define SQL_AT_CONSTRAINT_INITIALLY_IMMEDIATE         00020000h ;0x00020000L
;define SQL_AT_CONSTRAINT_DEFERRABLE                  00040000h ;0x00040000L
;define SQL_AT_CONSTRAINT_NON_DEFERRABLE              00080000h ;0x00080000L

;-- SQL_CONVERT_* return value bitmasks

;define SQL_CVT_CHAR                                  00000001h ;0x00000001L
;define SQL_CVT_NUMERIC                               00000002h ;0x00000002L
;define SQL_CVT_DECIMAL                               00000004h ;0x00000004L
;define SQL_CVT_INTEGER                               00000008h ;0x00000008L
;define SQL_CVT_SMALLINT                              00000010h ;0x00000010L
;define SQL_CVT_FLOAT                                 00000020h ;0x00000020L
;define SQL_CVT_REAL                                  00000040h ;0x00000040L
;define SQL_CVT_DOUBLE                                00000080h ;0x00000080L
;define SQL_CVT_VARCHAR                               00000100h ;0x00000100L
;define SQL_CVT_LONGVARCHAR                           00000200h ;0x00000200L
;define SQL_CVT_BINARY                                00000400h ;0x00000400L
;define SQL_CVT_VARBINARY                             00000800h ;0x00000800L
;define SQL_CVT_BIT                                   00001000h ;0x00001000L
;define SQL_CVT_TINYINT                               00002000h ;0x00002000L
;define SQL_CVT_BIGINT                                00004000h ;0x00004000L
;define SQL_CVT_DATE                                  00008000h ;0x00008000L
;define SQL_CVT_TIME                                  00010000h ;0x00010000L
;define SQL_CVT_TIMESTAMP                             00020000h ;0x00020000L
;define SQL_CVT_LONGVARBINARY                         00040000h ;0x00040000L
;define SQL_CVT_INTERVAL_YEAR_MONTH                   00080000h ;0x00080000L
;define SQL_CVT_INTERVAL_DAY_TIME                     00100000h ;0x00100000L
;define SQL_CVT_WCHAR                                 00200000h ;0x00200000L
;define SQL_CVT_WLONGVARCHAR                          00400000h ;0x00400000L
;define SQL_CVT_WVARCHAR                              00800000h ;0x00800000L
;define SQL_CVT_GUID                                  01000000h ;0x01000000L

;-- SQL_CONVERT_FUNCTIONS functions
;define SQL_FN_CVT_CONVERT                            00000001h ;0x00000001L
;define SQL_FN_CVT_CAST                               00000002h ;0x00000002L

;-- SQL_STRING_FUNCTIONS functions

;define SQL_FN_STR_CONCAT                             00000001h ;0x00000001L
;define SQL_FN_STR_INSERT                             00000002h ;0x00000002L
;define SQL_FN_STR_LEFT                               00000004h ;0x00000004L
;define SQL_FN_STR_LTRIM                              00000008h ;0x00000008L
;define SQL_FN_STR_LENGTH                             00000010h ;0x00000010L
;define SQL_FN_STR_LOCATE                             00000020h ;0x00000020L
;define SQL_FN_STR_LCASE                              00000040h ;0x00000040L
;define SQL_FN_STR_REPEAT                             00000080h ;0x00000080L
;define SQL_FN_STR_REPLACE                            00000100h ;0x00000100L
;define SQL_FN_STR_RIGHT                              00000200h ;0x00000200L
;define SQL_FN_STR_RTRIM                              00000400h ;0x00000400L
;define SQL_FN_STR_SUBSTRING                          00000800h ;0x00000800L
;define SQL_FN_STR_UCASE                              00001000h ;0x00001000L
;define SQL_FN_STR_ASCII                              00002000h ;0x00002000L
;define SQL_FN_STR_CHAR                               00004000h ;0x00004000L
;define SQL_FN_STR_DIFFERENCE                         00008000h ;0x00008000L
;define SQL_FN_STR_LOCATE_2                           00010000h ;0x00010000L
;define SQL_FN_STR_SOUNDEX                            00020000h ;0x00020000L
;define SQL_FN_STR_SPACE                              00040000h ;0x00040000L
;define SQL_FN_STR_BIT_LENGTH                         00080000h ;0x00080000L
;define SQL_FN_STR_CHAR_LENGTH                        00100000h ;0x00100000L
;define SQL_FN_STR_CHARACTER_LENGTH                   00200000h ;0x00200000L
;define SQL_FN_STR_OCTET_LENGTH                       00400000h ;0x00400000L
;define SQL_FN_STR_POSITION                           00800000h ;0x00800000L

;-- SQL_SQL92_STRING_FUNCTIONS
;define SQL_SSF_CONVERT                               00000001h ;0x00000001L
;define SQL_SSF_LOWER                                 00000002h ;0x00000002L
;define SQL_SSF_UPPER                                 00000004h ;0x00000004L
;define SQL_SSF_SUBSTRING                             00000008h ;0x00000008L
;define SQL_SSF_TRANSLATE                             00000010h ;0x00000010L
;define SQL_SSF_TRIM_BOTH                             00000020h ;0x00000020L
;define SQL_SSF_TRIM_LEADING                          00000040h ;0x00000040L
;define SQL_SSF_TRIM_TRAILING                         00000080h ;0x00000080L
comment { #if ODBCVER >= 0400h [
;define SQL_SSF_OVERLAY                               00000100h ;0x00000100L
;define SQL_SSF_LENGTH                                00000200h ;0x00000200L
;define SQL_SSF_POSITION                              00000400h ;0x00000400L
;define SQL_SSF_CONCAT                                00000800h ;0x00000800L
] ; ODBCVER >= 0400h }

;-- SQL_BINARY_FUNCTIONS functions
comment { #if ODBCVER >= 0400h [
;define SQL_FN_BIN_BIT_LENGTH                                   SQL_FN_STR_BIT_LENGTH
;define SQL_FN_BIN_CONCAT                                       SQL_FN_STR_CONCAT
;define SQL_FN_BIN_INSERT                                       SQL_FN_STR_INSERT
;define SQL_FN_BIN_LTRIM                                        SQL_FN_STR_LTRIM
;define SQL_FN_BIN_OCTET_LENGTH                                 SQL_FN_STR_OCTET_LENGTH
;define SQL_FN_BIN_POSITION                                     SQL_FN_STR_POSITION
;define SQL_FN_BIN_RTRIM                                        SQL_FN_STR_RTRIM
;define SQL_FN_BIN_SUBSTRING                                    SQL_FN_STR_SUBSTRING
] ; ODBCVER >= 0400h }

;-- SQL_SQLBINARY_FUNCTIONS
comment { #if ODBCVER >= 0400h [
;define SQL_SBF_CONVERT                                         SQL_SSF_CONVERT
;define SQL_SBF_SUBSTRING                                       SQL_SSF_SUBSTRING
;define SQL_SBF_TRIM_BOTH                                       SQL_SSF_TRIM_BOTH
;define SQL_SBF_TRIM_LEADING                                    SQL_SSF_TRIM_LEADING
;define SQL_SBF_TRIM_TRAILING                                   SQL_SSF_TRIM_TRAILING
;define SQL_SBF_OVERLAY                                         SQL_SSF_OVERLAY
;define SQL_SBF_LENGTH                                          SQL_SSF_LENGTH
;define SQL_SBF_POSITION                                        SQL_SSF_POSITION
;define SQL_SBF_CONCAT                                          SQL_SSF_CONCAT
] ; ODBCVER >= 0400h }

;-- SQL_NUMERIC_FUNCTIONS functions

;define SQL_FN_NUM_ABS                                00000001h ;0x00000001L
;define SQL_FN_NUM_ACOS                               00000002h ;0x00000002L
;define SQL_FN_NUM_ASIN                               00000004h ;0x00000004L
;define SQL_FN_NUM_ATAN                               00000008h ;0x00000008L
;define SQL_FN_NUM_ATAN2                              00000010h ;0x00000010L
;define SQL_FN_NUM_CEILING                            00000020h ;0x00000020L
;define SQL_FN_NUM_COS                                00000040h ;0x00000040L
;define SQL_FN_NUM_COT                                00000080h ;0x00000080L
;define SQL_FN_NUM_EXP                                00000100h ;0x00000100L
;define SQL_FN_NUM_FLOOR                              00000200h ;0x00000200L
;define SQL_FN_NUM_LOG                                00000400h ;0x00000400L
;define SQL_FN_NUM_MOD                                00000800h ;0x00000800L
;define SQL_FN_NUM_SIGN                               00001000h ;0x00001000L
;define SQL_FN_NUM_SIN                                00002000h ;0x00002000L
;define SQL_FN_NUM_SQRT                               00004000h ;0x00004000L
;define SQL_FN_NUM_TAN                                00008000h ;0x00008000L
;define SQL_FN_NUM_PI                                 00010000h ;0x00010000L
;define SQL_FN_NUM_RAND                               00020000h ;0x00020000L
;define SQL_FN_NUM_DEGREES                            00040000h ;0x00040000L
;define SQL_FN_NUM_LOG10                              00080000h ;0x00080000L
;define SQL_FN_NUM_POWER                              00100000h ;0x00100000L
;define SQL_FN_NUM_RADIANS                            00200000h ;0x00200000L
;define SQL_FN_NUM_ROUND                              00400000h ;0x00400000L
;define SQL_FN_NUM_TRUNCATE                           00800000h ;0x00800000L

;-- SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
;define SQL_SNVF_BIT_LENGTH                           00000001h ;0x00000001L
;define SQL_SNVF_CHAR_LENGTH                          00000002h ;0x00000002L
;define SQL_SNVF_CHARACTER_LENGTH                     00000004h ;0x00000004L
;define SQL_SNVF_EXTRACT                              00000008h ;0x00000008L
;define SQL_SNVF_OCTET_LENGTH                         00000010h ;0x00000010L
;define SQL_SNVF_POSITION                             00000020h ;0x00000020L

;-- SQL_TIMEDATE_FUNCTIONS functions
;define SQL_FN_TD_NOW                                 00000001h ;0x00000001L
;define SQL_FN_TD_CURDATE                             00000002h ;0x00000002L
;define SQL_FN_TD_DAYOFMONTH                          00000004h ;0x00000004L
;define SQL_FN_TD_DAYOFWEEK                           00000008h ;0x00000008L
;define SQL_FN_TD_DAYOFYEAR                           00000010h ;0x00000010L
;define SQL_FN_TD_MONTH                               00000020h ;0x00000020L
;define SQL_FN_TD_QUARTER                             00000040h ;0x00000040L
;define SQL_FN_TD_WEEK                                00000080h ;0x00000080L
;define SQL_FN_TD_YEAR                                00000100h ;0x00000100L
;define SQL_FN_TD_CURTIME                             00000200h ;0x00000200L
;define SQL_FN_TD_HOUR                                00000400h ;0x00000400L
;define SQL_FN_TD_MINUTE                              00000800h ;0x00000800L
;define SQL_FN_TD_SECOND                              00001000h ;0x00001000L
;define SQL_FN_TD_TIMESTAMPADD                        00002000h ;0x00002000L
;define SQL_FN_TD_TIMESTAMPDIFF                       00004000h ;0x00004000L
;define SQL_FN_TD_DAYNAME                             00008000h ;0x00008000L
;define SQL_FN_TD_MONTHNAME                           00010000h ;0x00010000L
;define SQL_FN_TD_CURRENT_DATE                        00020000h ;0x00020000L
;define SQL_FN_TD_CURRENT_TIME                        00040000h ;0x00040000L
;define SQL_FN_TD_CURRENT_TIMESTAMP                   00080000h ;0x00080000L
;define SQL_FN_TD_EXTRACT                             00100000h ;0x00100000L

;-- SQL_SQL92_DATETIME_FUNCTIONS
;define SQL_SDF_CURRENT_DATE                          00000001h ;0x00000001L
;define SQL_SDF_CURRENT_TIME                          00000002h ;0x00000002L
;define SQL_SDF_CURRENT_TIMESTAMP                     00000004h ;0x00000004L

;-- SQL_SYSTEM_FUNCTIONS functions
;define SQL_FN_SYS_USERNAME                           00000001h ;0x00000001L
;define SQL_FN_SYS_DBNAME                             00000002h ;0x00000002L
;define SQL_FN_SYS_IFNULL                             00000004h ;0x00000004L

;-- SQL_TIMEDATE_ADD_INTERVALS and SQL_TIMEDATE_DIFF_INTERVALS functions
;define SQL_FN_TSI_FRAC_SECOND                        00000001h ;0x00000001L
;define SQL_FN_TSI_SECOND                             00000002h ;0x00000002L
;define SQL_FN_TSI_MINUTE                             00000004h ;0x00000004L
;define SQL_FN_TSI_HOUR                               00000008h ;0x00000008L
;define SQL_FN_TSI_DAY                                00000010h ;0x00000010L
;define SQL_FN_TSI_WEEK                               00000020h ;0x00000020L
;define SQL_FN_TSI_MONTH                              00000040h ;0x00000040L
;define SQL_FN_TSI_QUARTER                            00000080h ;0x00000080L
;define SQL_FN_TSI_YEAR                               00000100h ;0x00000100L

;-- bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES
;   SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1,
;   SQL_KEYSET_CURSOR_ATTRIBUTES1, and SQL_STATIC_CURSOR_ATTRIBUTES1
;
;-- supported SQLFetchScroll FetchOrientation's
#define SQL_CA1_NEXT                                  00000001h ;0x00000001L
#define SQL_CA1_ABSOLUTE                              00000002h ;0x00000002L
#define SQL_CA1_RELATIVE                              00000004h ;0x00000004L
#define SQL_CA1_BOOKMARK                              00000008h ;0x00000008L

;-- supported SQLSetPos LockType's
#define SQL_CA1_LOCK_NO_CHANGE                        00000040h ;0x00000040L
#define SQL_CA1_LOCK_EXCLUSIVE                        00000080h ;0x00000080L
#define SQL_CA1_LOCK_UNLOCK                           00000100h ;0x00000100L

;-- supported SQLSetPos Operations
#define SQL_CA1_POS_POSITION                          00000200h ;0x00000200L
#define SQL_CA1_POS_UPDATE                            00000400h ;0x00000400L
#define SQL_CA1_POS_DELETE                            00000800h ;0x00000800L
#define SQL_CA1_POS_REFRESH                           00001000h ;0x00001000L

;-- positioned updates and deletes
#define SQL_CA1_POSITIONED_UPDATE                     00002000h ;0x00002000L
#define SQL_CA1_POSITIONED_DELETE                     00004000h ;0x00004000L
#define SQL_CA1_SELECT_FOR_UPDATE                     00008000h ;0x00008000L

;-- supported SQLBulkOperations operations
#define SQL_CA1_BULK_ADD                              00010000h ;0x00100000L
#define SQL_CA1_BULK_UPDATE_BY_BOOKMARK               00020000h ;0x00200000L
#define SQL_CA1_BULK_DELETE_BY_BOOKMARK               00040000h ;0x00400000L
#define SQL_CA1_BULK_FETCH_BY_BOOKMARK                00080000h ;0x00800000L

;-- bitmasks for SQL_DYNAMIC_CURSOR_ATTRIBUTES2,
;   SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2,
;   SQL_KEYSET_CURSOR_ATTRIBUTES2, and SQL_STATIC_CURSOR_ATTRIBUTES2
;
;-- supported values for SQL_ATTR_SCROLL_CONCURRENCY
#define SQL_CA2_READ_ONLY_CONCURRENCY                 00000001h ;0x00000001L
#define SQL_CA2_LOCK_CONCURRENCY                      00000002h ;0x00000002L
#define SQL_CA2_OPT_ROWVER_CONCURRENCY                00000004h ;0x00000004L
#define SQL_CA2_OPT_VALUES_CONCURRENCY                00000008h ;0x00000008L

;-- sensitivity of the cursor to its own inserts, deletes, and updates
#define SQL_CA2_SENSITIVITY_ADDITIONS                 00000010h ;0x00000010L
#define SQL_CA2_SENSITIVITY_DELETIONS                 00000020h ;0x00000020L
#define SQL_CA2_SENSITIVITY_UPDATES                   00000040h ;0x00000040L

;-- semantics of SQL_ATTR_MAX_ROWS
#define SQL_CA2_MAX_ROWS_SELECT                       00000080h ;0x00000080L
#define SQL_CA2_MAX_ROWS_INSERT                       00000100h ;0x00000100L
#define SQL_CA2_MAX_ROWS_DELETE                       00000200h ;0x00000200L
#define SQL_CA2_MAX_ROWS_UPDATE                       00000400h ;0x00000400L
#define SQL_CA2_MAX_ROWS_CATALOG                      00000800h ;0x00000800L
#define SQL_CA2_MAX_ROWS_AFFECTS_ALL                  00000F80h ;SQL_CA2_MAX_ROWS_SELECT |
															    ;SQL_CA2_MAX_ROWS_INSERT | SQL_CA2_MAX_ROWS_DELETE |
															    ;SQL_CA2_MAX_ROWS_UPDATE | SQL_CA2_MAX_ROWS_CATALOG

;-- semantics of SQL_DIAG_CURSOR_ROW_COUNT
#define SQL_CA2_CRC_EXACT                             00001000h ;0x00001000L
#define SQL_CA2_CRC_APPROXIMATE                       00002000h ;0x00002000L

;-- the kinds of positioned statements that can be simulated
#define SQL_CA2_SIMULATE_NON_UNIQUE                   00004000h ;0x00004000L
#define SQL_CA2_SIMULATE_TRY_UNIQUE                   00008000h ;0x00008000L
#define SQL_CA2_SIMULATE_UNIQUE                       00010000h ;0x00010000L

;-- SQL_ODBC_API_CONFORMANCE values
;define SQL_OAC_NONE                                      0000h ;0x0000
;define SQL_OAC_LEVEL1                                    0001h ;0x0001
;define SQL_OAC_LEVEL2                                    0002h ;0x0002

;-- SQL_ODBC_SAG_CLI_CONFORMANCE values
;define SQL_OSCC_NOT_COMPLIANT                            0000h ;0x0000
;define SQL_OSCC_COMPLIANT                                0001h ;0x0001

;-- SQL_ODBC_SQL_CONFORMANCE values
;define SQL_OSC_MINIMUM                                   0000h ;0x0000
;define SQL_OSC_CORE                                      0001h ;0x0001
;define SQL_OSC_EXTENDED                                  0002h ;0x0002

;-- SQL_CONCAT_NULL_BEHAVIOR values
;define SQL_CB_NULL                                       0000h ;0x0000
;define SQL_CB_NON_NULL                                   0001h ;0x0001

;-- SQL_SCROLL_OPTIONS masks
;define SQL_SO_FORWARD_ONLY                           00000001h ;0x00000001L
;define SQL_SO_KEYSET_DRIVEN                          00000002h ;0x00000002L
;define SQL_SO_DYNAMIC                                00000004h ;0x00000004L
;define SQL_SO_MIXED                                  00000008h ;0x00000008L
;define SQL_SO_STATIC                                 00000010h ;0x00000010L

;-- SQL_FETCH_DIRECTION masks
;-- SQL_FETCH_RESUME is no longer supported
;define SQL_FD_FETCH_RESUME                           00000040h ;0x00000040L
;define SQL_FD_FETCH_BOOKMARK                         00000080h ;0x00000080L

;-- SQL_TXN_ISOLATION_OPTION masks
;   SQL_TXN_VERSIONING is no longer supported
;define SQL_TXN_VERSIONING                            00000010h ;0x00000010L
;

;-- SQL_CORRELATION_NAME values
;define SQL_CN_NONE                                       0000h ;0x0000
;define SQL_CN_DIFFERENT                                  0001h ;0x0001
;define SQL_CN_ANY                                        0002h ;0x0002

;-- SQL_NON_NULLABLE_COLUMNS values
;define SQL_NNC_NULL                                      0000h ;0x0000
;define SQL_NNC_NON_NULL                                  0001h ;0x0001

;-- SQL_NULL_COLLATION values
;define SQL_NC_START                                      0002h ;0x0002
;define SQL_NC_END                                        0004h ;0x0004

;-- SQL_FILE_USAGE values
;define SQL_FILE_NOT_SUPPORTED                            0000h ;0x0000
;define SQL_FILE_TABLE                                    0001h ;0x0001
;define SQL_FILE_QUALIFIER                                0002h ;0x0002
;define SQL_FILE_CATALOG                                        SQL_FILE_QUALIFIER ;-- ODBC 3.0

;-- SQL_GETDATA_EXTENSIONS values
;define SQL_GD_BLOCK                                  00000004h ;0x00000004L
;define SQL_GD_BOUND                                  00000008h ;0x00000008L
comment { #if ODBCVER >= 0380h [ }
;define SQL_GD_OUTPUT_PARAMS                          00000010h ;0x00000010L
comment { ] ; ODBCVER >= 0380h }
comment { #if ODBCVER >= 0400h [
;define SQL_GD_CONCURRENT                             00000020h ;0x00000020L
] ; ODBCVER >= 0400h }

;-- SQL_POSITIONED_STATEMENTS masks
;define SQL_PS_POSITIONED_DELETE                      00000001h ;0x00000001L
;define SQL_PS_POSITIONED_UPDATE                      00000002h ;0x00000002L
;define SQL_PS_SELECT_FOR_UPDATE                      00000004h ;0x00000004L

;-- SQL_GROUP_BY values
;define SQL_GB_NOT_SUPPORTED                              0000h ;0x0000
;define SQL_GB_GROUP_BY_EQUALS_SELECT                     0001h ;0x0001
;define SQL_GB_GROUP_BY_CONTAINS_SELECT                   0002h ;0x0002
;define SQL_GB_NO_RELATION                                0003h ;0x0003
;define SQL_GB_COLLATE                                    0004h ;0x0004

;-- SQL_OWNER_USAGE masks
;define SQL_OU_DML_STATEMENTS                         00000001h ;0x00000001L
;define SQL_OU_PROCEDURE_INVOCATION                   00000002h ;0x00000002L
;define SQL_OU_TABLE_DEFINITION                       00000004h ;0x00000004L
;define SQL_OU_INDEX_DEFINITION                       00000008h ;0x00000008L
;define SQL_OU_PRIVILEGE_DEFINITION                   00000010h ;0x00000010L

;-- SQL_SCHEMA_USAGE masks
;define SQL_SU_DML_STATEMENTS                                   SQL_OU_DML_STATEMENTS
;define SQL_SU_PROCEDURE_INVOCATION                             SQL_OU_PROCEDURE_INVOCATION
;define SQL_SU_TABLE_DEFINITION                                 SQL_OU_TABLE_DEFINITION
;define SQL_SU_INDEX_DEFINITION                                 SQL_OU_INDEX_DEFINITION
;define SQL_SU_PRIVILEGE_DEFINITION                             SQL_OU_PRIVILEGE_DEFINITION

;-- SQL_QUALIFIER_USAGE masks
;define SQL_QU_DML_STATEMENTS                         00000001h ;0x00000001L
;define SQL_QU_PROCEDURE_INVOCATION                   00000002h ;0x00000002L
;define SQL_QU_TABLE_DEFINITION                       00000004h ;0x00000004L
;define SQL_QU_INDEX_DEFINITION                       00000008h ;0x00000008L
;define SQL_QU_PRIVILEGE_DEFINITION                   00000010h ;0x00000010L

;-- SQL_CATALOG_USAGE masks
;define SQL_CU_DML_STATEMENTS                                   SQL_QU_DML_STATEMENTS
;define SQL_CU_PROCEDURE_INVOCATION                             SQL_QU_PROCEDURE_INVOCATION
;define SQL_CU_TABLE_DEFINITION                                 SQL_QU_TABLE_DEFINITION
;define SQL_CU_INDEX_DEFINITION                                 SQL_QU_INDEX_DEFINITION
;define SQL_CU_PRIVILEGE_DEFINITION                             SQL_QU_PRIVILEGE_DEFINITION

;-- SQL_SUBQUERIES masks
;define SQL_SQ_COMPARISON                             00000001h ;0x00000001L
;define SQL_SQ_EXISTS                                 00000002h ;0x00000002L
;define SQL_SQ_IN                                     00000004h ;0x00000004L
;define SQL_SQ_QUANTIFIED                             00000008h ;0x00000008L
;define SQL_SQ_CORRELATED_SUBQUERIES                  00000010h ;0x00000010L

;-- SQL_UNION masks
;define SQL_U_UNION                                   00000001h ;0x00000001L
;define SQL_U_UNION_ALL                               00000002h ;0x00000002L

;-- SQL_BOOKMARK_PERSISTENCE values
;define SQL_BP_CLOSE                                  00000001h ;0x00000001L
;define SQL_BP_DELETE                                 00000002h ;0x00000002L
;define SQL_BP_DROP                                   00000004h ;0x00000004L
;define SQL_BP_TRANSACTION                            00000008h ;0x00000008L
;define SQL_BP_UPDATE                                 00000010h ;0x00000010L
;define SQL_BP_OTHER_HSTMT                            00000020h ;0x00000020L
;define SQL_BP_SCROLL                                 00000040h ;0x00000040L

;-- SQL_STATIC_SENSITIVITY values
;define SQL_SS_ADDITIONS                              00000001h ;0x00000001L
;define SQL_SS_DELETIONS                              00000002h ;0x00000002L
;define SQL_SS_UPDATES                                00000004h ;0x00000004L

;-- SQL_VIEW values
;define SQL_CV_CREATE_VIEW                            00000001h ;0x00000001L
;define SQL_CV_CHECK_OPTION                           00000002h ;0x00000002L
;define SQL_CV_CASCADED                               00000004h ;0x00000004L
;define SQL_CV_LOCAL                                  00000008h ;0x00000008L

;-- SQL_LOCK_TYPES masks
;define SQL_LCK_NO_CHANGE                             00000000h ;0x00000001L
;define SQL_LCK_EXCLUSIVE                             00000000h ;0x00000002L
;define SQL_LCK_UNLOCK                                00000000h ;0x00000004L

;-- SQL_POS_OPERATIONS masks
;define SQL_POS_POSITION                              00000000h ;0x00000001L
;define SQL_POS_REFRESH                               00000000h ;0x00000002L
;define SQL_POS_UPDATE                                00000000h ;0x00000004L
;define SQL_POS_DELETE                                00000000h ;0x00000008L
;define SQL_POS_ADD                                   00000000h ;0x00000010L

;-- SQL_QUALIFIER_LOCATION values
;define SQL_QL_START                                      0001h ;0x0001
;define SQL_QL_END                                        0002h ;0x0002

;-- Here start return values for ODBC 3.0 SQLGetInfo
;-- SQL_AGGREGATE_FUNCTIONS bitmasks
;define SQL_AF_AVG                                    00000001h ;0x00000001L
;define SQL_AF_COUNT                                  00000002h ;0x00000002L
;define SQL_AF_MAX                                    00000004h ;0x00000004L
;define SQL_AF_MIN                                    00000008h ;0x00000008L
;define SQL_AF_SUM                                    00000010h ;0x00000010L
;define SQL_AF_DISTINCT                               00000020h ;0x00000020L
;define SQL_AF_ALL                                    00000040h ;0x00000040L
comment { #if ODBCVER >= 0400h [
;define SQL_AF_EVERY                                  00000080h ;0x00000080L
;define SQL_AF_ANY                                    00000100h ;0x00000100L
;define SQL_AF_STDEV_OP                               00000200h ;0x00000200L
;define SQL_AF_STDEV_SAMP                             00000400h ;0x00000400L
;define SQL_AF_VAR_SAMP                               00000800h ;0x00000800L
;define SQL_AF_VAR_POP                                00001000h ;0x00001000L
;define SQL_AF_ARRAY_AGG                              00002000h ;0x00002000L
;define SQL_AF_COLLECT                                00004000h ;0x00004000L
;define SQL_AF_FUSION                                 00008000h ;0x00008000L
;define SQL_AF_INTERSECTION	                          00010000h ;0x00010000L
] ; ODBCVER >= 0400h }

;-- SQL_SQL_CONFORMANCE bit masks
;define SQL_SC_SQL92_ENTRY                            00000001h ;0x00000001L
;define SQL_SC_FIPS127_2_TRANSITIONAL                 00000002h ;0x00000002L
;define SQL_SC_SQL92_INTERMEDIATE                     00000004h ;0x00000004L
;define SQL_SC_SQL92_FULL                             00000008h ;0x00000008L

;-- SQL_DATETIME_LITERALS masks
;define SQL_DL_SQL92_DATE                             00000001h ;0x00000001L
;define SQL_DL_SQL92_TIME                             00000002h ;0x00000002L
;define SQL_DL_SQL92_TIMESTAMP                        00000004h ;0x00000004L
;define SQL_DL_SQL92_INTERVAL_YEAR                    00000008h ;0x00000008L
;define SQL_DL_SQL92_INTERVAL_MONTH                   00000010h ;0x00000010L
;define SQL_DL_SQL92_INTERVAL_DAY                     00000020h ;0x00000020L
;define SQL_DL_SQL92_INTERVAL_HOUR                    00000040h ;0x00000040L
;define SQL_DL_SQL92_INTERVAL_MINUTE                  00000080h ;0x00000080L
;define SQL_DL_SQL92_INTERVAL_SECOND                  00000100h ;0x00000100L
;define SQL_DL_SQL92_INTERVAL_YEAR_TO_MONTH           00000200h ;0x00000200L
;define SQL_DL_SQL92_INTERVAL_DAY_TO_HOUR             00000400h ;0x00000400L
;define SQL_DL_SQL92_INTERVAL_DAY_TO_MINUTE           00000800h ;0x00000800L
;define SQL_DL_SQL92_INTERVAL_DAY_TO_SECOND           00001000h ;0x00001000L
;define SQL_DL_SQL92_INTERVAL_HOUR_TO_MINUTE          00002000h ;0x00002000L
;define SQL_DL_SQL92_INTERVAL_HOUR_TO_SECOND          00004000h ;0x00004000L
;define SQL_DL_SQL92_INTERVAL_MINUTE_TO_SECOND        00008000h ;0x00008000L

;-- SQL_CATALOG_LOCATION values
;define SQL_CL_START                                            SQL_QL_START
;define SQL_CL_END                                              SQL_QL_END

;-- values for SQL_BATCH_ROW_COUNT
;define SQL_BRC_PROCEDURES                            00000001h ;0x0000001
;define SQL_BRC_EXPLICIT                              00000002h ;0x0000002
;define SQL_BRC_ROLLED_UP                             00000004h ;0x0000004

;-- bitmasks for SQL_BATCH_SUPPORT
;define SQL_BS_SELECT_EXPLICIT                        00000001h ;0x00000001L
;define SQL_BS_ROW_COUNT_EXPLICIT                     00000002h ;0x00000002L
;define SQL_BS_SELECT_PROC                            00000004h ;0x00000004L
;define SQL_BS_ROW_COUNT_PROC                         00000008h ;0x00000008L

;-- Values for SQL_PARAM_ARRAY_ROW_COUNTS getinfo
;define SQL_PARC_BATCH                                        1
;define SQL_PARC_NO_BATCH                                     2

;-- values for SQL_PARAM_ARRAY_SELECTS
;define SQL_PAS_BATCH                                         1
;define SQL_PAS_NO_BATCH                                      2
;define SQL_PAS_NO_SELECT                                     3

;-- Bitmasks for SQL_INDEX_KEYWORDS
;define SQL_IK_NONE                                   00000000h ;0x00000000L
;define SQL_IK_ASC                                    00000001h ;0x00000001L
;define SQL_IK_DESC                                   00000002h ;0x00000002L
;define SQL_IK_ALL                                              [( SQL_IK_ASC or SQL_IK_DESC )]

;-- Bitmasks for SQL_INFO_SCHEMA_VIEWS
;define SQL_ISV_ASSERTIONS                            00000001h ;0x00000001L
;define SQL_ISV_CHARACTER_SETS                        00000002h ;0x00000002L
;define SQL_ISV_CHECK_CONSTRAINTS                     00000004h ;0x00000004L
;define SQL_ISV_COLLATIONS                            00000008h ;0x00000008L
;define SQL_ISV_COLUMN_DOMAIN_USAGE                   00000010h ;0x00000010L
;define SQL_ISV_COLUMN_PRIVILEGES                     00000020h ;0x00000020L
;define SQL_ISV_COLUMNS                               00000040h ;0x00000040L
;define SQL_ISV_CONSTRAINT_COLUMN_USAGE               00000080h ;0x00000080L
;define SQL_ISV_CONSTRAINT_TABLE_USAGE                00000100h ;0x00000100L
;define SQL_ISV_DOMAIN_CONSTRAINTS                    00000200h ;0x00000200L
;define SQL_ISV_DOMAINS                               00000400h ;0x00000400L
;define SQL_ISV_KEY_COLUMN_USAGE                      00000800h ;0x00000800L
;define SQL_ISV_REFERENTIAL_CONSTRAINTS               00001000h ;0x00001000L
;define SQL_ISV_SCHEMATA                              00002000h ;0x00002000L
;define SQL_ISV_SQL_LANGUAGES                         00004000h ;0x00004000L
;define SQL_ISV_TABLE_CONSTRAINTS                     00008000h ;0x00008000L
;define SQL_ISV_TABLE_PRIVILEGES                      00010000h ;0x00010000L
;define SQL_ISV_TABLES                                00020000h ;0x00020000L
;define SQL_ISV_TRANSLATIONS                          00040000h ;0x00040000L
;define SQL_ISV_USAGE_PRIVILEGES                      00080000h ;0x00080000L
;define SQL_ISV_VIEW_COLUMN_USAGE                     00100000h ;0x00100000L
;define SQL_ISV_VIEW_TABLE_USAGE                      00200000h ;0x00200000L
;define SQL_ISV_VIEWS                                 00400000h ;0x00400000L

;-- Bitmasks for SQL_ALTER_DOMAIN
;define SQL_AD_CONSTRAINT_NAME_DEFINITION             00000001h ;0x00000001L
;define SQL_AD_ADD_DOMAIN_CONSTRAINT                  00000002h ;0x00000002L
;define SQL_AD_DROP_DOMAIN_CONSTRAINT                 00000004h ;0x00000004L
;define SQL_AD_ADD_DOMAIN_DEFAULT                     00000008h ;0x00000008L
;define SQL_AD_DROP_DOMAIN_DEFAULT                    00000010h ;0x00000010L
;define SQL_AD_ADD_CONSTRAINT_INITIALLY_DEFERRED      00000020h ;0x00000020L
;define SQL_AD_ADD_CONSTRAINT_INITIALLY_IMMEDIATE     00000040h ;0x00000040L
;define SQL_AD_ADD_CONSTRAINT_DEFERRABLE              00000080h ;0x00000080L
;define SQL_AD_ADD_CONSTRAINT_NON_DEFERRABLE          00000100h ;0x00000100L

;-- SQL_CREATE_SCHEMA bitmasks
;define SQL_CS_CREATE_SCHEMA                          00000001h ;0x00000001L
;define SQL_CS_AUTHORIZATION                          00000002h ;0x00000002L
;define SQL_CS_DEFAULT_CHARACTER_SET                  00000004h ;0x00000004L

;-- SQL_CREATE_TRANSLATION bitmasks
;define SQL_CTR_CREATE_TRANSLATION                    00000001h ;0x00000001L

;-- SQL_CREATE_ASSERTION bitmasks
;define SQL_CA_CREATE_ASSERTION                       00000001h ;0x00000001L
;define SQL_CA_CONSTRAINT_INITIALLY_DEFERRED          00000010h ;0x00000010L
;define SQL_CA_CONSTRAINT_INITIALLY_IMMEDIATE         00000020h ;0x00000020L
;define SQL_CA_CONSTRAINT_DEFERRABLE                  00000040h ;0x00000040L
;define SQL_CA_CONSTRAINT_NON_DEFERRABLE              00000080h ;0x00000080L

;-- SQL_CREATE_CHARACTER_SET bitmasks
;define SQL_CCS_CREATE_CHARACTER_SET                  00000001h ;0x00000001L
;define SQL_CCS_COLLATE_CLAUSE                        00000002h ;0x00000002L
;define SQL_CCS_LIMITED_COLLATION                     00000004h ;0x00000004L

;-- SQL_CREATE_COLLATION bitmasks
;define SQL_CCOL_CREATE_COLLATION                     00000001h ;0x00000001L

;-- SQL_CREATE_DOMAIN bitmasks
;define SQL_CDO_CREATE_DOMAIN                         00000001h ;0x00000001L
;define SQL_CDO_DEFAULT                               00000002h ;0x00000002L
;define SQL_CDO_CONSTRAINT                            00000004h ;0x00000004L
;define SQL_CDO_COLLATION                             00000008h ;0x00000008L
;define SQL_CDO_CONSTRAINT_NAME_DEFINITION            00000010h ;0x00000010L
;define SQL_CDO_CONSTRAINT_INITIALLY_DEFERRED         00000020h ;0x00000020L
;define SQL_CDO_CONSTRAINT_INITIALLY_IMMEDIATE        00000040h ;0x00000040L
;define SQL_CDO_CONSTRAINT_DEFERRABLE                 00000080h ;0x00000080L
;define SQL_CDO_CONSTRAINT_NON_DEFERRABLE             00000100h ;0x00000100L

;-- SQL_CREATE_TABLE bitmasks
;define SQL_CT_CREATE_TABLE                           00000001h ;0x00000001L
;define SQL_CT_COMMIT_PRESERVE                        00000002h ;0x00000002L
;define SQL_CT_COMMIT_DELETE                          00000004h ;0x00000004L
;define SQL_CT_GLOBAL_TEMPORARY                       00000008h ;0x00000008L
;define SQL_CT_LOCAL_TEMPORARY                        00000010h ;0x00000010L
;define SQL_CT_CONSTRAINT_INITIALLY_DEFERRED          00000020h ;0x00000020L
;define SQL_CT_CONSTRAINT_INITIALLY_IMMEDIATE         00000040h ;0x00000040L
;define SQL_CT_CONSTRAINT_DEFERRABLE                  00000080h ;0x00000080L
;define SQL_CT_CONSTRAINT_NON_DEFERRABLE              00000100h ;0x00000100L
;define SQL_CT_COLUMN_CONSTRAINT                      00000200h ;0x00000200L
;define SQL_CT_COLUMN_DEFAULT                         00000400h ;0x00000400L
;define SQL_CT_COLUMN_COLLATION                       00000800h ;0x00000800L
;define SQL_CT_TABLE_CONSTRAINT                       00001000h ;0x00001000L
;define SQL_CT_CONSTRAINT_NAME_DEFINITION             00002000h ;0x00002000L

;-- SQL_DDL_INDEX bitmasks
;define SQL_DI_CREATE_INDEX                           00000001h ;0x00000001L
;define SQL_DI_DROP_INDEX                             00000002h ;0x00000002L

;-- SQL_DROP_COLLATION bitmasks
;define SQL_DC_DROP_COLLATION                         00000001h ;0x00000001L

;-- SQL_DROP_DOMAIN bitmasks
;define SQL_DD_DROP_DOMAIN                            00000001h ;0x00000001L
;define SQL_DD_RESTRICT                               00000002h ;0x00000002L
;define SQL_DD_CASCADE                                00000004h ;0x00000004L

;-- SQL_DROP_SCHEMA bitmasks
;define SQL_DS_DROP_SCHEMA                            00000001h ;0x00000001L
;define SQL_DS_RESTRICT                               00000002h ;0x00000002L
;define SQL_DS_CASCADE                                00000004h ;0x00000004L

;-- SQL_DROP_CHARACTER_SET bitmasks
;define SQL_DCS_DROP_CHARACTER_SET                    00000001h ;0x00000001L

;-- SQL_DROP_ASSERTION bitmasks
;define SQL_DA_DROP_ASSERTION                         00000001h ;0x00000001L

;-- SQL_DROP_TABLE bitmasks
;define SQL_DT_DROP_TABLE                             00000001h ;0x00000001L
;define SQL_DT_RESTRICT                               00000002h ;0x00000002L
;define SQL_DT_CASCADE                                00000004h ;0x00000004L

;-- SQL_DROP_TRANSLATION bitmasks
;define SQL_DTR_DROP_TRANSLATION                      00000001h ;0x00000001L

;-- SQL_DROP_VIEW bitmasks
;define SQL_DV_DROP_VIEW                              00000001h ;0x00000001L
;define SQL_DV_RESTRICT                               00000002h ;0x00000002L
;define SQL_DV_CASCADE                                00000004h ;0x00000004L

;-- SQL_INSERT_STATEMENT bitmasks
;define SQL_IS_INSERT_LITERALS                        00000001h ;0x00000001L
;define SQL_IS_INSERT_SEARCHED                        00000002h ;0x00000002L
;define SQL_IS_SELECT_INTO                            00000004h ;0x00000004L

;-- SQL_ODBC_INTERFACE_CONFORMANCE values
;define SQL_OIC_CORE                                          1 ;1UL
;define SQL_OIC_LEVEL1                                        2 ;2UL
;define SQL_OIC_LEVEL2                                        3 ;3UL

;-- SQL_SQL92_FOREIGN_KEY_DELETE_RULE bitmasks
;define SQL_SFKD_CASCADE                              00000001h ;0x00000001L
;define SQL_SFKD_NO_ACTION                            00000002h ;0x00000002L
;define SQL_SFKD_SET_DEFAULT                          00000004h ;0x00000004L
;define SQL_SFKD_SET_NULL                             00000008h ;0x00000008L

;-- SQL_SQL92_FOREIGN_KEY_UPDATE_RULE bitmasks
;define SQL_SFKU_CASCADE                              00000001h ;0x00000001L
;define SQL_SFKU_NO_ACTION                            00000002h ;0x00000002L
;define SQL_SFKU_SET_DEFAULT                          00000004h ;0x00000004L
;define SQL_SFKU_SET_NULL                             00000008h ;0x00000008L

;-- SQL_SQL92_GRANT bitmasks
;define SQL_SG_USAGE_ON_DOMAIN                        00000001h ;0x00000001L
;define SQL_SG_USAGE_ON_CHARACTER_SET                 00000002h ;0x00000002L
;define SQL_SG_USAGE_ON_COLLATION                     00000004h ;0x00000004L
;define SQL_SG_USAGE_ON_TRANSLATION                   00000008h ;0x00000008L
;define SQL_SG_WITH_GRANT_OPTION                      00000010h ;0x00000010L
;define SQL_SG_DELETE_TABLE                           00000020h ;0x00000020L
;define SQL_SG_INSERT_TABLE                           00000040h ;0x00000040L
;define SQL_SG_INSERT_COLUMN                          00000080h ;0x00000080L
;define SQL_SG_REFERENCES_TABLE                       00000100h ;0x00000100L
;define SQL_SG_REFERENCES_COLUMN                      00000200h ;0x00000200L
;define SQL_SG_SELECT_TABLE                           00000400h ;0x00000400L
;define SQL_SG_UPDATE_TABLE                           00000800h ;0x00000800L
;define SQL_SG_UPDATE_COLUMN                          00001000h ;0x00001000L

;-- SQL_SQL92_PREDICATES bitmasks
;define SQL_SP_EXISTS                                 00000001h ;0x00000001L
;define SQL_SP_ISNOTNULL                              00000002h ;0x00000002L
;define SQL_SP_ISNULL                                 00000004h ;0x00000004L
;define SQL_SP_MATCH_FULL                             00000008h ;0x00000008L
;define SQL_SP_MATCH_PARTIAL                          00000010h ;0x00000010L
;define SQL_SP_MATCH_UNIQUE_FULL                      00000020h ;0x00000020L
;define SQL_SP_MATCH_UNIQUE_PARTIAL                   00000040h ;0x00000040L
;define SQL_SP_OVERLAPS                               00000080h ;0x00000080L
;define SQL_SP_UNIQUE                                 00000100h ;0x00000100L
;define SQL_SP_LIKE                                   00000200h ;0x00000200L
;define SQL_SP_IN                                     00000400h ;0x00000400L
;define SQL_SP_BETWEEN                                00000800h ;0x00000800L
;define SQL_SP_COMPARISON                             00001000h ;0x00001000L
;define SQL_SP_QUANTIFIED_COMPARISON                  00002000h ;0x00002000L

;-- SQL_SQL92_RELATIONAL_JOIN_OPERATORS bitmasks
;define SQL_SRJO_CORRESPONDING_CLAUSE                 00000001h ;0x00000001L
;define SQL_SRJO_CROSS_JOIN                           00000002h ;0x00000002L
;define SQL_SRJO_EXCEPT_JOIN                          00000004h ;0x00000004L
;define SQL_SRJO_FULL_OUTER_JOIN                      00000008h ;0x00000008L
;define SQL_SRJO_INNER_JOIN                           00000010h ;0x00000010L
;define SQL_SRJO_INTERSECT_JOIN                       00000020h ;0x00000020L
;define SQL_SRJO_LEFT_OUTER_JOIN                      00000040h ;0x00000040L
;define SQL_SRJO_NATURAL_JOIN                         00000080h ;0x00000080L
;define SQL_SRJO_RIGHT_OUTER_JOIN                     00000100h ;0x00000100L
;define SQL_SRJO_UNION_JOIN                           00000200h ;0x00000200L

;-- SQL_SQL92_REVOKE bitmasks
;define SQL_SR_USAGE_ON_DOMAIN                        00000001h ;0x00000001L
;define SQL_SR_USAGE_ON_CHARACTER_SET                 00000002h ;0x00000002L
;define SQL_SR_USAGE_ON_COLLATION                     00000004h ;0x00000004L
;define SQL_SR_USAGE_ON_TRANSLATION                   00000008h ;0x00000008L
;define SQL_SR_GRANT_OPTION_FOR                       00000010h ;0x00000010L
;define SQL_SR_CASCADE                                00000020h ;0x00000020L
;define SQL_SR_RESTRICT                               00000040h ;0x00000040L
;define SQL_SR_DELETE_TABLE                           00000080h ;0x00000080L
;define SQL_SR_INSERT_TABLE                           00000100h ;0x00000100L
;define SQL_SR_INSERT_COLUMN                          00000200h ;0x00000200L
;define SQL_SR_REFERENCES_TABLE                       00000400h ;0x00000400L
;define SQL_SR_REFERENCES_COLUMN                      00000800h ;0x00000800L
;define SQL_SR_SELECT_TABLE                           00001000h ;0x00001000L
;define SQL_SR_UPDATE_TABLE                           00002000h ;0x00002000L
;define SQL_SR_UPDATE_COLUMN                          00004000h ;0x00004000L

;-- SQL_SQL92_ROW_VALUE_CONSTRUCTOR bitmasks
;define SQL_SRVC_VALUE_EXPRESSION                     00000001h ;0x00000001L
;define SQL_SRVC_NULL                                 00000002h ;0x00000002L
;define SQL_SRVC_DEFAULT                              00000004h ;0x00000004L
;define SQL_SRVC_ROW_SUBQUERY                         00000008h ;0x00000008L

;-- SQL_SQL92_VALUE_EXPRESSIONS bitmasks
;define SQL_SVE_CASE                                  00000001h ;0x00000001L
;define SQL_SVE_CAST                                  00000002h ;0x00000002L
;define SQL_SVE_COALESCE                              00000004h ;0x00000004L
;define SQL_SVE_NULLIF                                00000008h ;0x00000008L

;-- SQL_STANDARD_CLI_CONFORMANCE bitmasks
;define SQL_SCC_XOPEN_CLI_VERSION1                    00000001h ;0x00000001L
;define SQL_SCC_ISO92_CLI                             00000002h ;0x00000002L

;-- SQL_UNION_STATEMENT bitmasks
;define SQL_US_UNION                                            SQL_U_UNION
;define SQL_US_UNION_ALL                                        SQL_U_UNION_ALL

;-- values for SQL_DRIVER_AWARE_POOLING_SUPPORTED
;define SQL_DRIVER_AWARE_POOLING_NOT_CAPABLE          00000000h ;0x00000000L
;define SQL_DRIVER_AWARE_POOLING_CAPABLE              00000001h ;0x00000001L

;-- SQL_DTC_TRANSITION_COST bitmasks
;define SQL_DTC_ENLIST_EXPENSIVE                      00000001h ;0x00000001L
;define SQL_DTC_UNENLIST_EXPENSIVE                    00000002h ;0x00000002L

comment { #if ODBCVER >= 0380h [ }
;-- possible values for SQL_ASYNC_DBC_FUNCTION
;define SQL_ASYNC_DBC_NOT_CAPABLE                     00000000h ;0x00000000L
;define SQL_ASYNC_DBC_CAPABLE                         00000001h ;0x00000001L
comment { ] ; ODBCVER >= 0380h }

;-- Bitmask values for SQL_LIMIT_ESCAPE_CLAUSE
comment { #if ODBCVER >= 0400h [
;define SQL_LC_NONE                                   00000000h ;0x00000000L
;define SQL_LC_TAKE                                   00000001h ;0x00000001L
;define SQL_LC_SKIP                                   00000003h ;0x00000003L
] ; ODBCVER >= 0400h }

;-- Bitmask values for SQL_RETURN_ESCAPE_CLAUSE
comment { #if ODBCVER >= 0400h [
;define SQL_RC_NONE                                   00000000h ;0x00000000L
;define SQL_RC_INSERT_SINGLE_ROWID                    00000001h ;0x00000001L
;define SQL_RC_INSERT_SINGLE_ANY                   [( 00000002h or SQL_RC_INSERT_SINGLE_ROWID )]
;define SQL_RC_INSERT_MULTIPLE_ROWID               [( 00000004h or SQL_RC_INSERT_SINGLE_ROWID )]
;define SQL_RC_INSERT_MULTIPLE_ANY                 [( 00000008h or SQL_RC_INSERT_MULTIPLE_ROWID or SQL_RC_INSERT_SINGLE_ANY )]
;define SQL_RC_INSERT_SELECT_ROWID                    00000010h ;0x00000010L
;define SQL_RC_INSERT_SELECT_ANY                   [( 00000020h or SQL_RC_INSERT_SELECT_ROWID )]
;define SQL_RC_UPDATE_ROWID                           00000040h ;0x00000040L
;define SQL_RC_UPDATE_ANY                          [( 00000080h or SQL_RC_UPDATE_ROWID )]
;define SQL_RC_DELETE_ROWID                           00000100h ;0x00000100L
;define SQL_RC_DELETE_ANY                          [( 00000200h or SQL_RC_DELETE_ROWID )]
;define SQL_RC_SELECT_INTO_ROWID                      00000400h ;0x00000400L
;define SQL_RC_SELECT_INTO_ANY                     [( 00000800h or SQL_RC_SELECT_INTO_ROWID )]
] ; ODBCVER >= 0400h }

;-- Bitmask values for SQL_FORMAT_ESCAPE_CLAUSE
comment { #if ODBCVER >= 0400h [
;define SQL_FC_NONE                                   00000000h ;0x00000000L
;define SQL_FC_JSON                                   00000001h ;0x00000001L
;define SQL_FC_JSON_BINARY                            00000002h ;0x00000002L
] ; ODBCVER >= 0400h }

;-- additional SQLDataSources fetch directions
#define SQL_FETCH_FIRST_USER                                 31
#define SQL_FETCH_FIRST_SYSTEM                               32

;-- Defines for SQLSetPos
;define SQL_ENTIRE_ROWSET                                     0

;-- Operations in SQLSetPos
#define SQL_POSITION                                          0 ;-- 1.0 FALSE
;define SQL_REFRESH                                           1 ;-- 1.0 TRUE
;define SQL_UPDATE                                            2
;define SQL_DELETE                                            3

;-- Operations in SQLBulkOperations
;define SQL_ADD                                               4
;define SQL_SETPOS_MAX_OPTION_VALUE                             SQL_ADD
;define SQL_UPDATE_BY_BOOKMARK                                5
;define SQL_DELETE_BY_BOOKMARK                                6
;define SQL_FETCH_BY_BOOKMARK                                 7

;-- Lock options in SQLSetPos
#define SQL_LOCK_NO_CHANGE                                    0 ;-- 1.0 FALSE
;define SQL_LOCK_EXCLUSIVE                                    1 ;-- 1.0 TRUE
;define SQL_LOCK_UNLOCK                                       2

;define SQL_SETPOS_MAX_LOCK_VALUE                               SQL_LOCK_UNLOCK

;-- Macros for SQLSetPos
;define SQL_POSITION_TO    (hstmt irow)                         [SQLSetPos hstmt irow SQL_POSITION SQL_LOCK_NO_CHANGE]
;define SQL_LOCK_RECORD    (hstmt irow fLock)                   [SQLSetPos hstmt irow SQL_POSITION fLock]
;define SQL_REFRESH_RECORD (hstmt irow fLock)                   [SQLSetPos hstmt irow SQL_REFRESH  fLock]
;define SQL_UPDATE_RECORD  (hstmt irow)                         [SQLSetPos hstmt irow SQL_UPDATE   SQL_LOCK_NO_CHANGE]
;define SQL_DELETE_RECORD  (hstmt irow)                         [SQLSetPos hstmt irow SQL_DELETE   SQL_LOCK_NO_CHANGE]
;define SQL_ADD_RECORD     (hstmt irow)                         [SQLSetPos hstmt irow SQL_ADD      SQL_LOCK_NO_CHANGE]

;-- Column types and scopes in SQLSpecialColumns
#define SQL_BEST_ROWID                                        1
#define SQL_ROWVER                                            2

;-- Defines for SQLSpecialColumns (returned in the result set)
;   SQL_PC_UNKNOWN and SQL_PC_PSEUDO are defined in sql.h
;define SQL_PC_NOT_PSEUDO                                     1

;-- Defines for SQLStatistics
#define SQL_QUICK                                             0
#define SQL_ENSURE                                            1

;-- Defines for SQLStatistics (returned in the result set)
;   SQL_INDEX_CLUSTERED, SQL_INDEX_HASHED, and SQL_INDEX_OTHER are
;   defined in sql.h
;define SQL_TABLE_STAT                                        0

;-- Defines for SQLTables
;define SQL_ALL_CATALOGS                                    "%"
;define SQL_ALL_SCHEMAS                                     "%"
;define SQL_ALL_TABLE_TYPES                                 "%"

;-- Options for SQLDriverConnect
#define SQL_DRIVER_NOPROMPT                                   0
;define SQL_DRIVER_COMPLETE                                   1
;define SQL_DRIVER_PROMPT                                     2
;define SQL_DRIVER_COMPLETE_REQUIRED                          3

;-- Level 2 Functions

;-- SQLExtendedFetch "fFetchType" values
;define SQL_FETCH_BOOKMARK                                    8

;-- SQLExtendedFetch "rgfRowStatus" element values
;define SQL_ROW_SUCCESS                                       0
;define SQL_ROW_DELETED                                       1
;define SQL_ROW_UPDATED                                       2
;define SQL_ROW_NOROW                                         3
;define SQL_ROW_ADDED                                         4
;define SQL_ROW_ERROR                                         5
;define SQL_ROW_SUCCESS_WITH_INFO                             6
;define SQL_ROW_PROCEED                                       0
;define SQL_ROW_IGNORE                                        1

;-- value for SQL_DESC_ARRAY_STATUS_PTR
;define SQL_PARAM_SUCCESS                                     0
;define SQL_PARAM_SUCCESS_WITH_INFO                           6
;define SQL_PARAM_ERROR                                       5
;define SQL_PARAM_UNUSED                                      7
;define SQL_PARAM_DIAG_UNAVAILABLE                            1
;define SQL_PARAM_PROCEED                                     0
;define SQL_PARAM_IGNORE                                      1

;-- Defines for SQLForeignKeys (UPDATE_RULE and DELETE_RULE)
;define SQL_CASCADE                                           0
;define SQL_RESTRICT                                          1
;define SQL_SET_NULL                                          2
;define SQL_NO_ACTION                                         3
;define SQL_SET_DEFAULT                                       4

;-- Note that the following are in a different column of SQLForeignKeys than
;   the previous #defines.   These are for DEFERRABILITY.
;define SQL_INITIALLY_DEFERRED                                5
;define SQL_INITIALLY_IMMEDIATE                               6
;define SQL_NOT_DEFERRABLE                                    7

;-- Defines for SQLBindParameter and
;   SQLProcedureColumns (returned in the result set)
;define SQL_PARAM_TYPE_UNKNOWN                                0
#define SQL_PARAM_INPUT                                       1
;define SQL_PARAM_INPUT_OUTPUT                                2
;define SQL_RESULT_COL                                        3
;define SQL_PARAM_OUTPUT                                      4
;define SQL_RETURN_VALUE                                      5
comment { #if ODBCVER >= 0380h [ }
;define SQL_PARAM_INPUT_OUTPUT_STREAM                         8
;define SQL_PARAM_OUTPUT_STREAM                              16
comment { ] ; ODBCVER >= 0380h }

;-- Defines for SQLProcedures (returned in the result set)
;define SQL_PT_UNKNOWN                                        0
;define SQL_PT_PROCEDURE                                      1
;define SQL_PT_FUNCTION                                       2




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
