Red/System [
	Title:   "Red/System ODBC Bindings"
	Author:  "Christian Ensel"
	File:    %odbc.reds
	Tabs:    4
	Rights:  "Copyright 2022 Christian Ensel. All rights reserved."
	License: 'Unlicensed
]

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


sql-date!: alias struct! [
	year|month    [integer!]
	daylo         [byte!]
	dayhi         [byte!]
]

sql-time!: alias struct! [
	hour|minute   [integer!]
	seclo         [byte!]
	sechi         [byte!]
]

sql-timestamp!: alias struct! [
	year|month    [integer!]
	day|hour      [integer!]
	minute|second [integer!]
	fraction      [integer!]
]


sql: context [

	#enum odbcdef! [

		;################################# sqlucode.h ##
		;
		;  ██████  ██████  ██         ██   ██
		; ██      ██    ██ ██         ██   ██
		;  █████  ██    ██ ██         ███████
		;      ██ ██ ▄▄ ██ ██         ██   ██
		; ██████   ██████  ███████ ██ ██   ██
		;             ▀▀

		;-- special length/indicator values
		null-data:                                FFFFh ;-1
	;   data-at-exec:                             FFFEh ;-2

		;-- return values from functions
		success:                                      0
		success-with-info:                            1
		no-data:                                    100

		;#if ODBCVER >= 0380h [
	;   param-data-available:                       101
		;] ; ODBCVER >= 0380h

		error:                                    FFFFh ;-1
		invalid-handle:                           FFFEh ;-2

		still-executing:                              2
		need-data:                                   99

		;-- test for 'success' or 'success-with-info'
	;   succeeded(rc)                            [] ;-- FIXME

		;-- flags for null-terminated string
		nts:                                      FFFDh ;-3
	;   ntsl:                                        -3 ;-3L

		;-- maximum message length
	;   max-message-length:                         512

		;-- date/time length constants
	;   date-len:                                    10
	;   time-len:                                     8 ;-- add P+1 if precision is nonzero
	;   timestamp-len:                               19 ;-- add P+1 if precision is nonzero

		;-- handle type identifiers
		handle-env:                                   1
		handle-dbc:                                   2
		handle-stmt:                                  3
	;   handle-desc:                                  4

		;-- environment attribute
		attr-output-nts:                          10001

		;-- connection attributes
		attr-auto-ipd:                            10001
		attr-metadata-id:                         10014

		;-- statement attributes
		attr-app-row-desc:                        10010
		attr-app-param-desc:                      10011
		attr-imp-row-desc:                        10012
		attr-imp-param-desc:                      10013
		attr-cursor-scrollable:                   FFFFh ;-1
		attr-cursor-sensitivity:                  FFFEh ;-2

		;-- 'attr-cursor-scrollable' values
	;   nonscrollable:                                0
		scrollable:                                   1

	;   desc-count:                                1001
	;   desc-type:                                 1002
	;   desc-length:                               1003
	;   desc-octet-length-ptr:                     1004
	;   desc-precision:                            1005
	;   desc-scale:                                1006
	;   desc-datetime-interval-code:               1007
	;   desc-nullable:                             1008
	;   desc-indicator-ptr:                        1009
	;   desc-data-ptr:                             1010
	;   desc-name:                                 1011
	;   desc-unnamed:                              1012
	;   desc-octet-length:                         1013
	;   desc-alloc-type:                           1099

	;   #if ODBCVER >= 0400h [
	;   desc-character-set-catalog:                1018
	;   desc-character-set-schema:                 1019
	;   desc-character-set-name:                   1020
	;   desc-collation-catalog:                    1015
	;   desc-collation-schema:                     1016
	;   desc-collation-name:                       1017
	;   desc-user-defined-type-catalog:            1026
	;   desc-user-defined-type-schema:             1027
	;   desc-user-defined-type-name:               1028
	;   ] ; ODBCVER >= 0400h

		;-- identifiers of fields in the diagnostics area
	;   diag-returncode:                              1
	;   diag-number:                                  2
	;   diag-row-count:                               3
	;   diag-sqlstate:                                4
	;   diag-native:                                  5
	;   diag-message-text:                            6
	;   diag-dynamic-function:                        7
	;   diag-class-origin:                            8
	;   diag-subclass-origin:                         9
	;   diag-connection-name:                        10
	;   diag-server-name:                            11
	;   diag-dynamic-function-code:                  12

		;-- dynamic function codes
	;   diag-alter-domain:                            3
	;   diag-alter-table:                             4
	;   diag-call:                                    7
	;   diag-create-assertion:                        6
	;   diag-create-character-set:                    8
	;   diag-create-collation:                       10
	;   diag-create-domain:                          23
	;   diag-create-index:                        FFFFh ;-1
	;   diag-create-schema:                          64
	;   diag-create-table:                           77
	;   diag-create-translation:                     79
	;   diag-create-view:                            84
	;   diag-delete-where:                           19
	;   diag-drop-assertion:                         24
	;   diag-drop-character-set:                     25
	;   diag-drop-collation:                         26
	;   diag-drop-domain:                            27
	;   diag-drop-index:                          FFFEh ;-2
	;   diag-drop-schema:                            31
	;   diag-drop-table:                             32
	;   diag-drop-translation:                       33
	;   diag-drop-view:                              36
	;   diag-dynamic-delete-cursor:                  38
	;   diag-dynamic-update-cursor:                  81
	;   diag-grant:                                  48
	;   diag-insert:                                 50
	;   diag-revoke:                                 59
	;   diag-select-cursor:                          85
	;   diag-unknown-statement:                       0
	;   diag-update-where:                           82

		;-- SQL data type codes
	;   unknown-type:                                 0
		char:                                         1
		numeric:                                      2
		decimal:                                      3
		integer:                                      4
		smallint:                                     5
		float:                                        6
		real:                                         7
		double:                                       8
	;   datetime:                                     9
		varchar:                                     12

	;   #if ODBCVER >= 0400h [
	;   variant-type:                                 0 ;=sql-unknown-type
	;   udt:                                         17
		row:                                         19
	;   array:                                       50
	;   multiset:                                    55
	;   ] ; ODBCVER >= 0400h

		;-- One-parameter shortcuts for date/time data types
		type-date:                                   91
		type-time:                                   92
		type-timestamp:                              93
	;   #if ODBCVER >= 0400h [
	;   type-time-with-timezone:                     94
	;   type-timestamp-with-timezone:                95
	;   ] ; ODBCVER >= 0400h

		;-- Statement attribute values for cursor sensitivity
	;   unspecified:                                  0
	;   insensitive:                                  1
	;   sensitive:                                    2

		;-- GetTypeInfo() request for all data types
		all-types:                                    0

		;-- Default conversion code for SQLBindCol(), SQLBindParam() and SQLGetData()
	;   default:                                     99

		;-- SQLLEN GetData() code indicating that the application row descriptor
		;   specifies the data type
		;
	;   ard-type:                                 FF9Dh ;-99

	;   #if ODBCVER >= 0380h [
	;   apd-type:                                 FF9Ch ;-100
	;   ] ; ODBCVER >= 0380h

		;-- SQL date/time type subcodes
	;   code-date:                                    1
	;   code-time:                                    2
	;   code-timestamp:                               3

	;   #if ODBCVER >= 0400h [
	;   code-time-with-timezone:                      4
	;   code-timestamp-with-timezone:                 5
	;   ] ; ODBCVER >= 0400h

		;-- CLI option values
		false:                                        0
		true:                                         1

		;-- values of NULLABLE field in descriptor
		no-nulls:                                     0
		nullable:                                     1

		;-- Value returned by SQLGetTypeInfo() to denote that it is
		;   not known whether or not a data type supports null values.
	;   nullable-unknown:                             2

		;-- Values returned by SQLGetTypeInfo() to show WHERE clause
		;   supported
	;   pred-none:                                    0
	;   pred-char:                                    1
	;   pred-basic:                                   2

		;-- values of UNNAMED field in descriptor
	;   named:                                        0
	;   unnamed:                                      1

		;-- values of ALLOC-TYPE field in descriptor
	;   desc-alloc-auto:                              1
	;   desc-alloc-user:                              2

		;-- FreeStmt() options
		close:                                        0
	;   drop:                                         1
		unbind:                                       2
		reset-params:                                 3

		;-- Codes used for FetchOrientation in SQLFetchScroll(),
		;   and in SQLDataSources()
		fetch-next:                                   1
		fetch-first:                                  2

		;-- Other codes used for FetchOrientation in SQLFetchScroll()
		fetch-last:                                   3
		fetch-prior:                                  4
		fetch-absolute:                               5
		fetch-relative:                               6

		;-- SQLEndTran() options
		commit:                                       0
	;   rollback:                                     1

		;-- null handles returned by SQLAllocHandle()
	;   null-henv:                                    0
	;   null-hdbc:                                    0
	;   null-hstmt:                                   0
	;   null-hdesc:                                   0

		;-- null handle used in place of parent handle when allocating HENV
	;   null-handle:                                  0 ;0l

		;-- Values that may appear in the result set of SQLSpecialColumns()
		scope-currow:                                 0
		scope-transaction:                            1
		scope-session:                                2

	;   pc-unknown:                                   0
	;   pc-non-pseudo:                                1
	;   pc-pseudo:                                    2

		;-- Reserved value for the IdentifierType argument of SQLSpecialColumns()
	;   row-identifier:                               1

		;-- Reserved values for UNIQUE argument of SQLStatistics()
		index-unique:                                 0
		index-all:                                    1

		;-- Values that may appear in the result set of SQLStatistics()
	;   index-clustered:                              1
	;   index-hashed:                                 2
	;   index-other:                                  3

		;-- SQLGetFunctions() values to identify ODBC APIs
	;   api-sqlallocconnect:                          1
	;   api-sqlallocenv:                              2
	;   api-sqlallochandle:                        1001
	;   api-sqlallocstmt:                             3
	;   api-sqlbindcol:                               4
	;   api-sqlbindparam:                          1002
	;   api-sqlcancel:                                5
	;   api-sqlclosecursor:                        1003
	;   api-sqlcolattribute:                          6
	;   api-sqlcolumns:                              40
	;   api-sqlconnect:                               7
	;   api-sqlcopydesc:                           1004
	;   api-sqldatasources:                          57
	;   api-sqldescribecol:                           8
	;   api-sqldisconnect:                            9
	;   api-sqlendtran:                        i   1005
	;   api-sqlerror:                                10
	;   api-sqlexecdirect:                           11
	;   api-sqlexecute:                              12
	;   api-sqlfetch:                                13
	;   api-sqlfetchscroll:                        1021
	;   api-sqlfreeconnect:                          14
	;   api-sqlfreeenv:                              15
	;   api-sqlfreehandle:                         1006
	;   api-sqlfreestmt:                             16
	;   api-sqlgetconnectattr:                     1007
	;   api-sqlgetconnectoption:                     42
	;   api-sqlgetcursorname:                        17
	;   api-sqlgetdata:                              43
	;   api-sqlgetdescfield:                       1008
	;   api-sqlgetdescrec:                         1009
	;   api-sqlgetdiagfield:                       1010
	;   api-sqlgetdiagrec:                         1011
	;   api-sqlgetenvattr:                         1012
	;   api-sqlgetfunctions:                         44
	;   api-sqlgetinfo:                              45
	;   api-sqlgetstmtattr:                        1014
	;   api-sqlgetstmtoption:                        46
	;   api-sqlgettypeinfo:                          47
	;   api-sqlnumresultcols:                        18
	;   api-sqlparamdata:                            48
	;   api-sqlprepare:                              19
	;   api-sqlputdata:                              49
	;   api-sqlrowcount:                             20
	;   api-sqlsetconnectattr:                     1016
	;   api-sqlsetconnectoption:                     50
	;   api-sqlsetcursorname:                        21
	;   api-sqlsetdescfield:                       1017
	;   api-sqlsetdescrec:                         1018
	;   api-sqlsetenvattr:                         1019
	;   api-sqlsetparam:                             22
	;   api-sqlsetstmtattr:                        1020
	;   api-sqlsetstmtoption:                        51
	;   api-sqlspecialcolumns:                       52
	;   api-sqlstatistics:                           53
	;   api-sqltables:                               54
	;   api-sqltransact:                             23
	;   #if ODBCVER >= 0380h [
	;   api-sqlcancelhandle:                       1550
	;   api-sqlcompleteasync:                      1551
	;   ] ; ODBCVER >= 0380h

		;-- Information requested by SQLGetInfo()
	;   maximum-driver-connections:                   0
	;   maximum-concurrent-activities:                1
		data-source-name:                             2
	;   fetch-direction:                              8
		server-name:                                 13
		search-pattern-escape:                       14
		dbms-name:                                   17
		dbms-ver:                                    18
		accessible-tables:                           19
		accessible-procedures:                       20
	;   cursor-commit-behavior:                      23
		data-source-read-only:                       25
	;   default-txn-isolation:                       26
	;   identifier-case:                             28
	;   identifier-quote-char:                       29
	;   maximum-column-name-length:                  30
	;   maximum-cursor-name-length:                  31
	;   maximum-schema-name-length:                  32
	;   maximum-catalog-name-length:                 34
	;   scroll-concurrency:                          43
	;   transaction-capable:                         46
		user-name:                                   47
	;   transaction-isolation-option:                72
		integrity:                                   73
	;   getdata-extensions:                          81
	;   null-collation:                              85
	;   alter-table:                                 86
		order-by-columns-in-select:                  90
		special-characters:                          94
	;   maximum-columns-in-group-by:                 97
	;   maximum-columns-in-index:                    98
	;   maximum-columns-in-order-by:                 99
	;   maximum-columns-in-select:                  100
	;   maximum-index-size:                         102
		maximum-row-size:                           104
	;   maximum-statement-length:                   105
	;   maximum-tables-in-select:                   106
	;   maximum-user-name-length:                   107
	;   outer-join-capabilities:                    115
		xopen-cli-year:                           10000
	;   cursor-sensitivity:                       10001
		describe-parameter:                       10002
		catalog-name:                             10003
		collation-seq:                            10004
	;   maximum-identifier-length:                10005

		;-- ALTER-TABLE bitmasks
	;   at-add-column:                        00000001h
	;   at-drop-column:                       00000002h
	;   at-add-constraint:                    00000008h

		;-- The following bitmasks are ODBC extensions and defined in sqlext.h
	;   at-column-single:                     00000020h
	;   at-add-column-default:                00000040h
	;   at-add-column-collation:              00000080h
	;   at-set-column-default:                00000100h
	;   at-drop-column-default:               00000200h
	;   at-drop-column-cascade:               00000400h
	;   at-drop-column-restrict:              00000800h
	;   at-add-table-constraint:              00001000h
	;   at-drop-table-constraint-cascade:     00002000h
	;   at-drop-table-constraint-restrict:
	;                                         00004000h
	;   at-constraint-name-definition:        00008000h
	;   at-constraint-initially-deferred:     00010000h
	;   at-constraint-initially-immediate:
	;                                         00020000h
	;   at-constraint-deferrable:             00040000h
	;   at-constraint-non-deferrable:         00080000h

		;-- ASYNC-MODE values
	;   am-none:                                      0
	;   am-connection:                                1
	;   am-statement:                                 2

		;-- CURSOR-COMMIT-BEHAVIOR values
	;   cb-delete:                                    0
	;   cb-close:                                     1
	;   cb-preserve:                                  2

		;-- FETCH-DIRECTION bitmasks
	;   fd-fetch-next:                        00000001h
	;   fd-fetch-first:                       00000002h
	;   fd-fetch-last:                        00000004h
	;   fd-fetch-prior:                       00000008h
	;   fd-fetch-absolute:                    00000010h
	;   fd-fetch-relative:                    00000020h

		;-- GETDATA-EXTENSIONS bitmasks
	;   gd-any-column:                        00000001h
	;   gd-any-order:                         00000002h

		;-- IDENTIFIER-CASE values
	;   ic-upper:                                     1
	;   ic-lower:                                     2
	;   ic-sensitive:                                 3
	;   ic-mixed:                                     4

		;-- OJ-CAPABILITIES bitmasks
		;   NB: this means 'outer join', not what you may be thinking
	;   oj-left:                              00000001h
	;   oj-right:                             00000002h
	;   oj-full:                              00000004h
	;   oj-nested:                            00000008h
	;   oj-not-ordered:                       00000010h
	;   oj-inner:                             00000020h
	;   oj-all-comparison-ops:                00000040h

		;-- SCROLL-CONCURRENCY bitmasks
	;   scco-read-only:                       00000001h
	;   scco-lock:                            00000002h
	;   scco-opt-rowver:                      00000004h
	;   scco-opt-values:                      00000008h

		;-- TXN-CAPABLE values
	;   tc-none:                                      0
	;   tc-dml:                                       1
	;   tc-all:                                       2
	;   tc-ddl-commit:                                3
	;   tc-ddl-ignore:                                4

		;-- TXN-ISOLATION-OPTION bitmasks
	;   transaction-read-uncommitted:         00000001h
	;   transaction-read-committed:           00000002h
	;   transaction-repeatable-read:          00000004h
	;   transaction-serializable:             00000008h

		;-- NULL-COLLATION values
	;   nc-high:                                      0
	;   nc-low:                                       1


		;################################# sqlucode.h ##
		;
		;  ██████  ██████  ██      ██    ██  ██████  ██████  ██████  ███████    ██   ██
		; ██      ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
		;  █████  ██    ██ ██      ██    ██ ██      ██    ██ ██   ██ █████      ███████
		;      ██ ██ ▄▄ ██ ██      ██    ██ ██      ██    ██ ██   ██ ██         ██   ██
		;  █████   ██████  ███████  ██████   ██████  ██████  ██████  ███████ ██ ██   ██
		;             ▀▀

		wchar:                                    FFF8h ; -8
		wvarchar:                                 FFF7h ; -9
		wlongvarchar:                             FFF6h ;-10
		c-wchar:                                  FFF8h ;=wchar
	;   c-tchar:                                  FFF8h ;=c-wchar


		;################################### sqlext.h ##
		;

		;  ██████  ██████  ██      ███████ ██   ██ ████████    ██   ██
		; ██      ██    ██ ██      ██       ██ ██     ██       ██   ██
		;  █████  ██    ██ ██      █████     ███      ██       ███████
		;      ██ ██ ▄▄ ██ ██      ██       ██ ██     ██       ██   ██
		; ██████   ██████  ███████ ███████ ██   ██    ██    ██ ██   ██
		;             ▀▀

		;-- generally useful constants
	;   spec-major:                                   4 ;-- Major version of specification
	;   spec-minor:                                  00 ;-- Minor version of specification
	;   spec-string:                            "04.00" ;-- String constant for version

	;   sqlstate-size:                                5 ;-- size of SQLSTATE

	;   typedef SQLTCHAR                                SQLSTATE[SQL-SQLSTATE-SIZE + 1];

	;   max-dsn-length:                              32 ;-- maximum data source name size

	;   max-option-string-length:                   256

		;-- return code NO-DATA-FOUND is the same as NO-DATA
	;   no-data-found:                              100 ;=NO-DATA

		;-- extended function return values
	;   #if ODBCVER >= 0400h [
	;   data-available:                             102
	;   metadata-changed:                           103
	;   more-data:                                  104
	;   ] ; ODBCVER >= 0400h

		;-- an end handle type
	;   handle-senv:                                  5

		;-- env attribute
		attr-odbc-version:                          200
		attr-connection-pooling:                    201
		attr-cp-match:                              202
		;-- For private driver manager
	;   attr-application-key:                       203

		;-- values for ATTR-CONNECTION-POOLING
	;   cp-off:                                       0 ;0UL
	;   cp-one-per-driver:                            1 ;1UL
	;   cp-one-per-henv:                              2 ;2UL
	;   cp-driver-aware:                              3 ;3UL
	;   cp-default:                                   0 ;=CP-OFF

		;-- values for ATTR-CP-MATCH
	;   cp-strict-match:                              0 ;0UL
	;   cp-relaxed-match:                             1 ;1UL
	;   cp-match-default:                             0 ;=CP-STRICT-MATCH

		;-- values for ATTR-ODBC-VERSION
		ov-odbc2:                                     2 ;2UL
		ov-odbc3:                                     3 ;3UL

	;   #if ODBCVER >= 0380h [
		;-- new values for ATTR-ODBC-VERSION
		;   From ODBC 3.8 onwards, we should use <major version> * 100 + <minor version>
		ov-odbc3-80:                                380 ;380UL
	;   ] ; ODBCVER >= 0380h

	;   #if ODBCVER >= 0400h [
	;   ov-odbc4:                                   400 ;400UL
	;   ] ; ODBCVER >= 0400h

		;-- connection attributes with new names
		attr-access-mode:                           101
		attr-autocommit:                            102
		attr-login-timeout:                         103
		attr-trace:                                 104
		attr-tracefile:                             105
		attr-translate-lib:                         106
		attr-translate-option:                      107
		attr-txn-isolation:                         108
		attr-current-catalog:                       109
		attr-odbc-cursors:                          110
		attr-quiet-mode:                            111
		attr-packet-size:                           112
		attr-connection-timeout:                    113
		attr-disconnect-behavior:                   114
		attr-enlist-in-dtc:                        1207
		attr-enlist-in-xa:                         1208
		attr-connection-dead:                      1209 ;-- GetConnectAttr only

		;-- ODBC Driver Manager sets this connection attribute to a unicode driver
		;   (which supports SQLConnectW) when the application is an ANSI application
		;   (which calls SQLConnect, SQLDriverConnect, or SQLBrowseConnect).
		;   This is SetConnectAttr only and application does not set this attribute
		;   This attribute was introduced because some unicode driver's some APIs may
		;   need to behave differently on ANSI or Unicode applications. A unicode
		;   driver, which  has same behavior for both ANSI or Unicode applications,
		;   should return ERROR when the driver manager sets this connection
		;   attribute. When a unicode driver returns SUCCESS on this attribute,
		;   the driver manager treates ANSI and Unicode connections differently in
		;   connection pooling.
	;   attr-ansi-app:                              115

	;   #if ODBCVER >= 0380h [
	;   attr-reset-connection:                      116
		attr-async-dbc-functions-enable:            117
	;   ] ; ODBCVER >= 0380h

		;-- Connection attribute 118 is defined in sqlspi.h

	;   #if ODBCVER >= 0380h [
		attr-async-dbc-event:                       119
	;   ] ; ODBCVER >= 0380h

		;-- Connection attribute 120 and 121 are defined in sqlspi.h

	;   #if ODBCVER >= 0400h [
	;   attr-credentials:                           122
	;   attr-refresh-connection:                    123
	;   ] ; ODBCVER >= 0400h

		;-- ACCESS-MODE options
	;   mode-read-write:                              0 ;0UL
	;   mode-read-only:                               1 ;1UL
	;   mode-default:                                 0 ;=MODE-READ-WRITE

		;-- AUTOCOMMIT options
	;   autocommit-off:                               0 ;0UL
		autocommit-on:                                1 ;1UL
	;   autocommit-default:                           1 ;=AUTOCOMMIT-ON

		;-- LOGIN-TIMEOUT options
	;   login-timeout-default:                       15 ;15UL

		;-- OPT-TRACE options
	;   opt-trace-off:                                0 ;0UL
	;   opt-trace-on:                                 1 ;1UL
	;   opt-trace-default:                            0 ;=OPT-TRACE-OFF
	;   opt-trace-file-default:             "\\SQL.LOG"

		;-- CUR-USE-IF-NEEDED and CUR-USE-ODBC are deprecated.
		;   Please use CUR-USE-DRIVER for cursor functionalities provided by drivers
	;   cur-use-if-needed:                            0 ;0UL
	;   cur-use-odbc:                                 1 ;1UL
	;   cur-use-driver:                               2 ;2UL
	;   cur-default:                                  2 ;CUR-USE-DRIVER

		;-- values for ATTR-DISCONNECT-BEHAVIOR
	;   db-return-to-pool:                            0 ;0UL
	;   db-disconnect:                                1 ;1UL
	;   db-default:                                   0 ;DB-RETURN-TO-POOL

		;-- values for ATTR-ENLIST-IN-DTC
	;   dtc-done:                                     0 ;0L

		;-- values for ATTR-CONNECTION-DEAD
	;   cd-true:                                      1 ;1L ;-- Connection is closed/dead
	;   cd-false:                                     0 ;0L ;-- Connection is open/available

		;-- values for ATTR-ANSI-APP
	;   aa-true:                                      1 ;1L ;-- the application is an ANSI app
	;   aa-false:                                     0 ;0L ;-- the application is a Unicode app

		;-- values for ATTR-RESET-CONNECTION
	;   #if ODBCVER >= 0380h [
	;   reset-connection-yes:                         1 ;1UL
	;   ] ; ODBCVER >= 0380h

		;-- values for ATTR-ASYNC-DBC-FUNCTIONS-ENABLE
	;   #if ODBCVER >= 0380h [
	;   async-dbc-enable-on:                          1 ;1UL
	;   async-dbc-enable-off:                         0 ;0UL
	;   async-dbc-enable-default:                     0 ;ASYNC-DBC-ENABLE-OFF
	;   ] ; ODBCVER >= 0380h

		;-- values for ATTR-REFRESH-CONNECTION
	;   #if ODBCVER >= 0400h [
	;   refresh-now:                                 -1
	;   refresh-auto:                                 0
	;   refresh-manual:                               1
	;   ] ; ODBCVER >= 0400h

	;-- statement attributes
	;   rowset-size:                                  9
	;   get-bookmark:                                13 ;-- GetStmtOption Only

		;-- statement attributes for ODBC 3.0
		attr-query-timeout:                           0
		attr-max-rows:                                1
		attr-noscan:                                  2
		attr-max-length:                              3
		attr-async-enable:                            4
		attr-row-bind-type:                           5
		attr-cursor-type:                             6
		attr-concurrency:                             7
		attr-keyset-size:                             8
		attr-simulate-cursor:                        10
		attr-retrieve-data:                          11
		attr-use-bookmarks:                          12
		attr-row-number:                             14 ;-- GetStmtAttr
		attr-enable-auto-ipd:                        15
		attr-fetch-bookmark-ptr:                     16
		attr-param-bind-offset-ptr:                  17
		attr-param-bind-type:                        18
		attr-param-operation-ptr:                    19
		attr-param-status-ptr:                       20
		attr-params-processed-ptr:                   21
		attr-paramset-size:                          22
		attr-row-bind-offset-ptr:                    23
		attr-row-operation-ptr:                      24
		attr-row-status-ptr:                         25
		attr-rows-fetched-ptr:                       26
		attr-row-array-size:                         27

	;   #if ODBCVER >= 0380h [
		attr-async-stmt-event:                       29
	;   ] ; ODBCVER >= 0380h

	;   #if ODBCVER >= 0400h [
	;   attr-sample-size:                            30
	;   attr-dynamic-columns:                        31
	;   attr-type-exception-behavior:                32
	;   attr-length-exception-behavior:              33
	;   ] ; ODBCVER >= 0400h

		;-- ATTR-TYPE-EXCEPTION-BEHAVIOR values
	;   #if ODBCVER >= 0400h [
	;   te-error:                                 0001h
	;   te-continue:                              0002h
	;   te-report:                                0003h
	;   ] ; ODBCVER >= 0400h

		;-- ATTR-LENGTH-EXCEPTION-BEHAVIOR values
	;   #if ODBCVER >= 0400h [
	;   le-continue:                              0001h
	;   le-report:                                0002h
	;   ] ; ODBCVER >= 0400h

		;-- New defines for SEARCHABLE column in SQLGetTypeInfo
	;   col-pred-char:                                1 ;=LIKE-ONLY
	;   col-pred-basic:                               2 ;=ALL-EXCEPT-LIKE

		;-- whether an attribute is a pointer or not
	;   is-pointer:                               FFFCh ;-4
		is-uinteger:                              FFFBh ;-5
		is-integer:                               FFFAh ;-6
	;   is-usmallint:                             FFF9h ;-7
	;   is-smallint:                              FFF8h ;-8

		;-- the value of ATTR-PARAM-BIND-TYPE
		param-bind-by-column:                         0 ;0UL
	;   param-bind-type-default:                      0 ;=PARAM-BIND-BY-COLUMN

		;-- QUERY-TIMEOUT options
	;   query-timeout-default:                        0 ;0UL

		;-- MAX-ROWS options
	;   max-rows-default:                             0 ;0UL

		;-- NOSCAN options
	;   noscan-off:                                   0 ;0UL ;-- 1.0 FALSE
	;   noscan-on:                                    1 ;1UL ;-- 1.0 TRUE
	;   noscan-default:                               0 ;=NOSCAN-OFF

		;-- MAX-LENGTH options
	;   max-length-default:                           0 ;0UL

		;-- values for ATTR-ASYNC-ENABLE
	;   async-enable-off:                             0 ;0UL
	;   async-enable-on:                              1 ;1UL
	;   async-enable-default:                         0 ;=ASYNC-ENABLE-OFF

		;-- BIND-TYPE options
		bind-by-column:                               0 ;0UL
	;   bind-type-default:                            0 ;=BIND-BY-COLUMN

		;-- CONCURRENCY options
	;   concur-read-only:                             1
	;   concur-lock:                                  2
	;   concur-rowver:                                3
	;   concur-values:                                4
	;   concur-default:                               1 ;=CONCUR-READ-ONLY

		;-- CURSOR-TYPE options
	;   cursor-forward-only:                          0 ;0UL
	;   cursor-keyset-driven:                         1 ;1UL
	;   cursor-dynamic:                               2 ;2UL
	;   cursor-static:                                3 ;3UL
	;   cursor-type-default:                          0 ;=CURSOR-FORWARD-ONLY

		;-- ROWSET-SIZE options
	;   rowset-size-default:                          1 ;1UL

		;-- KEYSET-SIZE options
	;   keyset-size-default:                          0 ;0UL

		;-- SIMULATE-CURSOR options
	;   sc-non-unique:                                0 ;0UL
	;   sc-try-unique:                                1 ;1UL
	;   sc-unique:                                    2 ;2UL

		;-- RETRIEVE-DATA options
	;   rd-off:                                       0 ;0UL
	;   rd-on:                                        1 ;1UL
	;   rd-default:                                   1 ;=RD-ON

		;-- USE-BOOKMARKS options
	;   ub-off:                                       0 ;0UL
	;   ub-on:                                        1 ;1UL
	;   ub-default:                                   0 ;=UB-OFF

		;-- New values for USE-BOOKMARKS attribute
	;   ub-fixed:                                     1 ;=UB-ON
	;   ub-variable:                                  2 ;2UL

		;-- extended descriptor field
	;   desc-array-size:                             20
	;   desc-array-status-ptr:                       21
	;   desc-auto-unique-value:                      11 ;=COLUMN-AUTO-INCREMENT
	;   desc-base-column-name:                       22
	;   desc-base-table-name:                        23
	;   desc-bind-offset-ptr:                        24
	;   desc-bind-type:                              25
	;   desc-case-sensitive:                         12 ;=COLUMN-CASE-SENSITIVE
	;   desc-catalog-name:                           17 ;=COLUMN-QUALIFIER-NAME
	;   desc-concise-type:                            2 ;=COLUMN-TYPE
	;   desc-datetime-interval-precision:            26
	;   desc-display-size:                            6 ;=COLUMN-DISPLAY-SIZE
	;   desc-fixed-prec-scale:                        9 ;=COLUMN-MONEY
	;   desc-label:                                  18 ;=COLUMN-LABEL
	;   desc-literal-prefix:                         27
	;   desc-literal-suffix:                         28
	;   desc-local-type-name:                        29
	;   desc-maximum-scale:                          30
	;   desc-minimum-scale:                          31
	;   desc-num-prec-radix:                         32
	;   desc-parameter-type:                         33
	;   desc-rows-processed-ptr:                     34
	;   desc-rowver:                                 35
	;   desc-schema-name:                            16 ;=COLUMN-OWNER-NAME
	;   desc-searchable:                             13 ;=COLUMN-SEARCHABLE
	;   desc-type-name:                              14 ;=COLUMN-TYPE-NAME
	;   desc-table-name:                             15 ;=COLUMN-TABLE-NAME
	;   desc-unsigned:                                8 ;=COLUMN-UNSIGNED
	;   desc-updatable:                              10 ;=COLUMN-UPDATABLE

	;   #if ODBCVER >= 0400h [
	;   desc-mime-type:                              36
	;   ] ; ODBCVER >= 0400h

		;-- defines for diagnostics fields
	;   diag-cursor-row-count:                    FB1Fh ;-1249
	;   diag-row-number:                          FB20h ;-1248
	;   diag-column-number:                       FB21h ;-1247

		;-- SQL extended datatypes
		date:                                         9
		interval:                                    10
		time:                                        10
		timestamp:                                   11
		longvarchar:                              FFFFh ;-1
		binary:                                   FFFEh ;-2
		varbinary:                                FFFDh ;-3
		longvarbinary:                            FFFCh ;-4
		bigint:                                   FFFBh ;-5
		tinyint:                                  FFFAh ;-6
		bit:                                      FFF9h ;-7
		guid:                                     FFF5h ;-11

		;-- interval code
	;   code-year:                                    1
	;   code-month:                                   2
	;   code-day:                                     3
	;   code-hour:                                    4
	;   code-minute:                                  5
	;   code-second:                                  6
	;   code-year-to-month:                           7
	;   code-day-to-hour:                             8
	;   code-day-to-minute:                           9
	;   code-day-to-second:                          10
	;   code-hour-to-minute:                         11
	;   code-hour-to-second:                         12
	;   code-minute-to-second:                       13

		interval-year:                              101 ;-- 100 + CODE-YEAR
		interval-month:                             102 ;-- 100 + CODE-MONTH
		interval-day:                               103 ;-- 100 + CODE-DAY
		interval-hour:                              104 ;-- 100 + CODE-HOUR
		interval-minute:                            105 ;-- 100 + CODE-MINUTE
		interval-second:                            106 ;-- 100 + CODE-SECOND
		interval-year-to-month:                     107 ;-- 100 + CODE-YEAR-TO-MONTH
		interval-day-to-hour:                       108 ;-- 100 + CODE-DAY-TO-HOUR
		interval-day-to-minute:                     109 ;-- 100 + CODE-DAY-TO-MINUTE
		interval-day-to-second:                     110 ;-- 100 + CODE-DAY-TO-SECOND
		interval-hour-to-minute:                    111 ;-- 100 + CODE-HOUR-TO-MINUTE
		interval-hour-to-second:                    112 ;-- 100 + CODE-HOUR-TO-SECOND
		interval-minute-to-second:                  113 ;-- 100 + CODE-MINUTE-TO-SECOND

		;-- The previous definitions for UNICODE- are historical and obsolete

	;   unicode:                                  FFF8h ;=WCHAR
	;   unicode-varchar:                          FFF7h ;=WVARCHAR
	;   unicode-longvarchar:                      FFF6h ;=WLONGVARCHAR
	;   unicode-char:                             FFF8h ;=WCHAR

		;-- C datatype to SQL datatype mapping SQL types
		;                                       -------------------
		c-char:                                       1 ;=CHAR
		c-long:                                       4 ;=INTEGER
	;   c-short:                                      5 ;=SMALLINT
	;   c-float:                                      7 ;=REAL
		c-double:                                     8 ;=DOUBLE
	;   c-numeric:                                    2 ;=NUMERIC
		c-default:                                   99

	;   signed-offset:                            FFECh ;-20
	;   unsigned-offset:                          FFEAh ;-22

		;-- C datatype to SQL datatype mapping
	;   c-date:                                       9 ;=DATE
	;   c-time:                                      10 ;=TIME
	;   c-timestamp:                                 11 ;=TIMESTAMP
		c-type-date:                                 91 ;=TYPE-DATE
		c-type-time:                                 92 ;=TYPE-TIME
		c-type-timestamp:                            93 ;=TYPE-TIMESTAMP
	;   #if ODBCVER >= 0400h [
	;   c-type-time-with-timezone:                   94 ;=TYPE-TIME-WITH-TIMEZONE
	;   c-type-timestamp-with-timezone:              95 ;=TYPE-TIMESTAMP-WITH-TIMEZONE
	;   ] ; ODBCVER >= 0400h
	;   c-interval-year:                            101 ;=INTERVAL-YEAR
	;   c-interval-month:                           102 ;=INTERVAL-MONTH
	;   c-interval-day:                             103 ;=INTERVAL-DAY
	;   c-interval-hour:                            104 ;=INTERVAL-HOUR
	;   c-interval-minute:                          105 ;=INTERVAL-MINUTE
	;   c-interval-second:                          106 ;=INTERVAL-SECOND
	;   c-interval-year-to-month:                   107 ;=INTERVAL-YEAR-TO-MONTH
	;   c-interval-day-to-hour:                     108 ;=INTERVAL-DAY-TO-HOUR
	;   c-interval-day-to-minute:                   109 ;=INTERVAL-DAY-TO-MINUTE
	;   c-interval-day-to-second:                   110 ;=INTERVAL-DAY-TO-SECOND
	;   c-interval-hour-to-minute:                  111 ;=INTERVAL-HOUR-TO-MINUTE
	;   c-interval-hour-to-second:                  112 ;=INTERVAL-HOUR-TO-SECOND
	;   c-interval-minute-to-second:                113 ;=INTERVAL-MINUTE-TO-SECOND
		c-binary:                                 FFFEh ;=BINARY
		c-bit:                                    FFF9h ;=BIT
	;   c-sbigint:                                FFFBh ; -5 =BIGINT  + SIGNED-OFFSET    ;-- SIGNED BIGINT
	;   c-ubigint:                                FFFBh ; -5 =BIGINT  + UNSIGNED-OFFSET  ;-- UNSIGNED BIGINT
	;   c-tinyint:                                FFFAh ; -6 =TINYINT
	;   c-slong:                                  FFF0h ;-16 =C-LONG  + SIGNED-OFFSET    ;-- SIGNED INTEGER
	;   c-sshort:                                 FFF1h ;-15 =C-SHORT + SIGNED-OFFSET    ;-- SIGNED SMALLINT
	;   c-stinyint:                               FFF2h ;-14 =TINYINT + SIGNED-OFFSET    ;-- SIGNED TINYINT
	;   c-ulong:                                  FFEEh ;-18 =C-LONG  + UNSIGNED-OFFSET  ;-- UNSIGNED INTEGER
	;   c-ushort:                                 FFEFh ;-17 =C-SHORT + UNSIGNED-OFFSET  ;-- UNSIGNED SMALLINT
	;   c-utinyint:                               FFF0h ;-16 =TINYINT + UNSIGNED-OFFSET  ;-- UNSIGNED TINYINT

	;   ifdef -WIN64
	;   c-bookmark:                               FFFBh ;=C-UBIGINT
	;   else
	;   c-bookmark:                               FFEEh ;=C-ULONG
	;   endif

	;   c-guid:                                   FFF5h ;=GUID
	;   type-null:                                    0

		;-- base value of driver-specific C-Type (max is 0x7fff)
		;   define driver-specific C-Type, named as DRIVER-C-TYPE-BASE,
		;   DRIVER-C-TYPE-BASE+1, DRIVER-C-TYPE-BASE+2, etc.
	;   #if ODBCVER >= 0380h [
	;   driver-c-type-base:                        4000
	;   ] ; ODBCVER >= 0380h

		;-- base value of driver-specific fields/attributes (max are 0x7fff [16-bit] or 0x00007fff [32-bit])
		;   define driver-specific Type, named as DRIVER-SQL-TYPE-BASE,
		;   DRIVER-SQL-TYPE-BASE+1, DRIVER-SQL-TYPE-BASE+2, etc.
		;
		;   Please note that there is no runtime change in this version of DM.
		;   However, we suggest that driver manufacturers adhere to this range
		;   as future versions of the DM may enforce these constraints
	;   #if ODBCVER >= 0380h [
	;   driver-sql-type-base:                     4000h
	;   driver-desc-field-base:                   4000h
	;   driver-diag-field-base:                   4000h
	;   driver-info-type-base:                    4000h
	;   driver-conn-attr-base:                00004000h ;-- 32-bit
	;   driver-stmt-attr-base:                00004000h ;-- 32-bit
	;   ] ; ODBCVER >= 0380h

	;   c-varbookmark                             FFFEh ;=C-BINARY

		;-- define for DIAG-ROW-NUMBER and DIAG-COLUMN-NUMBER
	;   no-row-number:                            FFFFh ;-1
	;   no-column-number:                         FFFFh ;-1
	;   row-number-unknown:                       FFFEh ;-2
	;   column-number-unknown:                    FFFEh ;-2

		;-- INDpARAMETER extensions
	;   default-param:                            FFFBh ;-5
	;   ignore:                                   FFFAh ;-6
	;   column-ignore:                            FFFAh ;-6=IGNORE
	;   len-data-at-exec-offset:                  FF9Ch ;-100
	;   #define len-data-at-exec(length)                [(- (length) + LEN-DATA-AT-EXEC-OFFSET)]

		;-- binary length for driver specific attributes
	;   len-binary-attr-offset:                   FF9Ch ;-100
	;   len-binary-attr(length)                         [(- (length) + LEN-BINARY-ATTR-OFFSET)]

		;-- Defines used by Driver Manager when mapping SQLSetParam to SQLBindParameter
	;   param-type-default:                           2 ;=PARAM-INPUT-OUTPUT
	;   setparam-value-max:                          -1 ;-1L

		;-- Extended length/indicator values Values
	;   #if ODBCVER >= 0400h [
	;   data-unavailable:                         FFFAh ;=IGNORE
	;   data-at-fetch:                            FFFEh ;=DATA-AT-EXEC
	;   type-exception:                             -20
	;   ] ; ODBCVER >= 0400h

		;-- SQLColAttributes defines
	;   column-count:                                 0
	;   column-name:                                  1
	;   column-type:                                  2
	;   column-length:                                3
	;   column-precision:                             4
	;   column-scale:                                 5
	;   column-display-size:                          6
	;   column-nullable:                              7
	;   column-unsigned:                              8
	;   column-money:                                 9
	;   column-updatable:                            10
	;   column-auto-increment:                       11
	;   column-case-sensitive:                       12
	;   column-searchable:                           13
	;   column-type-name:                            14
	;   column-table-name:                           15
	;   column-owner-name:                           16
	;   column-qualifier-name:                       17
	;   column-label:                                18
	;   colatt-opt-max:                              18 ;=COLUMN-LABEL
	;   colatt-opt-min:                               0 ;=COLUMN-COUNT

		;-- SQLColAttributes subdefines for SQL-COLUMN-UPDATABLE
	;   attr-readonly:                                0
	;   attr-write:                                   1
	;   attr-readwrite-unknown:                       2

		;-- SQLColAttributes subdefines for COLUMN-SEARCHABLE
		;   These are also used by SQLGetInfo
	;   unsearchable:                                 0
	;   like-only:                                    1
	;   all-except-like:                              2
	;   searchable:                                   3
	;   pred-searchable:                             13 ;=SEARCHABLE

		;-- Special return values for SQLGetData
	;   no-total:                                 FFFCh ;-4

		;********************************************
		;* SQLGetFunctions: additional values for   *
		;* fFunction to represent functions that    *
		;* are not in the X/Open spec.              *
		;********************************************

	;   api-sqlallochandlestd:                       73
	;   api-sqlbulkoperations:                       24
	;   api-sqlbindparameter:                        72
	;   api-sqlbrowseconnect:                        55
	;   api-sqlcolattributes:                         6
	;   api-sqlcolumnprivileges:                     56
	;   api-sqldescribeparam:                        58
	;   api-sqldriverconnect:                        41
	;   api-sqldrivers:                              71
	;   api-sqlextendedfetch:                        59
	;   api-sqlforeignkeys:                          60
	;   api-sqlmoreresults:                          61
	;   api-sqlnativesql:                            62
	;   api-sqlnumparams:                            63
	;   api-sqlparamoptions:                         64
	;   api-sqlprimarykeys:                          65
	;   api-sqlprocedurecolumns:                     66
	;   api-sqlprocedures:                           67
	;   api-sqlsetpos:                               68
	;   api-sqlsetscrolloptions:                     69
	;   api-sqltableprivileges:                      70

	;   #if ODBCVER >= 0400h [
	;   api-sqlgetnestedhandle:                      74
	;   api-sqlstructuredtypes:                      75
	;   api-sqlstructuredtypecolumns:                76
	;   api-sqlnextcolumn:                           77
	;   ] ; ODBCVER >= 0400h

		;*--------------------------------------------*
		;* API-ALL-FUNCTIONS returns an array         *
		;* of 'booleans' representing whether a       *
		;* function is implemented by the driver.     *
		;*                                            *
		;* CAUTION: Only functions defined in ODBC    *
		;* version 2.0 and earlier are returned, the  *
		;* new high-range function numbers defined by *
		;* X/Open break this scheme.   See the new    *
		;* method -- API-ODBC3-ALL-FUNCTIONS          *
		;*--------------------------------------------*

	;   api-all-functions:                            0 ;-- See CAUTION above

		;*----------------------------------------------*
		;* 2.X drivers export a dummy function with     *
		;* ordinal number API-LOADBYORDINAL to speed    *
		;* loading under the windows operating system.  *
		;*                                              *
		;* CAUTION: Loading by ordinal is not supported *
		;* for 3.0 and above drivers.                   *
		;*----------------------------------------------*

	;   api-loadbyordinal:                          199 ;-- See CAUTION above

		;*----------------------------------------------*
		;* API-ODBC3-ALL-FUNCTIONS                      *
		;* This returns a bitmap, which allows us to    *
		;* handle the higher-valued function numbers.   *
		;* Use  FUNC-EXISTS(bitmap,function-number)     *
		;* to determine if the function exists.         *
		;*----------------------------------------------*

	;   api-odbc3-all-functions:                    999
	;   api-odbc3-all-functions-size:               250 ;-- array of 250 words --
	;   #define FUNC-EXISTS(pfExists, uwAPI)                 [(
	;               (* (((UWORD*) (pfExists)) + ((uwAPI) >> 4)) \
	;                       & (1 << ((uwAPI) & 0x000F)) \
	;                    ) ? TRUE : FALSE \
	;   )]

	;   ************************************************
	;   * Extended definitions for SQLGetInfo          *
	;   ************************************************

	;   *---------------------------------*
	;   * Values in ODBC 2.0 that are not *
	;   * in the X/Open spec              *
	;   *---------------------------------*

	;   info-first:                                   0
	;   active-connections:                           0 ;=MAX-DRIVER-CONNECTIONS
	;   active-statements:                            1 ;=MAX-CONCURRENT-ACTIVITIES
	;   driver-hdbc:                                  3
	;   driver-henv:                                  4
	;   driver-hstmt:                                 5
		driver-name:                                  6
		driver-ver:                                   7
	;   odbc-api-conformance:                         9
		odbc-ver:                                    10
		row-updates:                                 11
	;   odbc-sag-cli-conformance:                    12
	;   odbc-sql-conformance:                        15
		procedures:                                  21
	;   concat-null-behavior:                        22
	;   cursor-rollback-behavior:                    24
		expressions-in-orderby:                      27
	;   max-owner-name-len:                          32 ;=MAX-SCHEMA-NAME-LEN
	;   max-procedure-name-len:                      33
	;   max-qualifier-name-len:                      34 ;=MAX-CATALOG-NAME-LEN
		mult-result-sets:                            36
		multiple-active-txn:                         37
	;   outer-joins:                                 38
	;   owner-term:                                  39
		procedure-term:                              40
	;   qualifier-name-separator:                    41
	;   qualifier-term:                              42
	;   scroll-options:                              44
		table-term:                                  45
	;   convert-functions:                           48
	;   numeric-functions:                           49
	;   string-functions:                            50
	;   system-functions:                            51
	;   timedate-functions:                          52
	;   convert-bigint:                              53
	;   convert-binary:                              54
	;   convert-bit:                                 55
	;   convert-char:                                56
	;   convert-date:                                57
	;   convert-decimal:                             58
	;   convert-double:                              59
	;   convert-float:                               60
	;   convert-integer:                             61
	;   convert-longvarchar:                         62
	;   convert-numeric:                             63
	;   convert-real:                                64
	;   convert-smallint:                            65
	;   convert-time:                                66
	;   convert-timestamp:                           67
	;   convert-tinyint:                             68
	;   convert-varbinary:                           69
	;   convert-varchar:                             70
	;   convert-longvarbinary:                       71
	;   odbc-sql-opt-ief:                            73 ;=INTEGRITY
	;   correlation-name:                            74
	;   non-nullable-columns:                        75
	;   driver-hlib:                                 76
		driver-odbc-ver:                             77
	;   lock-types:                                  78
	;   pos-operations:                              79
	;   positioned-statements:                       80
	;   bookmark-persistence:                        82
	;   static-sensitivity:                          83
	;   file-usage:                                  84
		column-alias:                                87
	;   group-by:                                    88
		keywords:                                    89
	;   owner-usa/E:                                 91
	;   qualifier-usage:                             92
	;   quoted-identifier-case:                      93
	;   subqueries:                                  95
	;   union:                                       96
		max-row-size-includes-long:                 103
	;   max-char-literal-len:                       108
	;   timedate-add-intervals:                     109
	;   timedate-diff-intervals:                    110
		need-long-data-len:                         111
	;   max-binary-literal-len:                     112
		like-escape-clause:                         113
	;   qualifier-location:                         114

		;*-----------------------------------------------*
		;* ODBC 3.0 SQLGetInfo values that are not part  *
		;* of the X/Open standard at this time.   X/Open *
		;* standard values are in sql.h.                 *
		;*-----------------------------------------------*

	;   active-environments:                        116
	;   alter-domain:                               117
	;   sql-conformance:                            118
	;   datetime-literals:                          119
	;   async-mode:                               10021 ;-- new X/Open spec
	;   batch-row-count:                            120
	;   batch-support:                              121
	;   catalog-location:                           114 ;=QUALIFIER-LOCATION
		catalog-name-separator:                      41 ;=QUALIFIER-NAME-SEPARATOR
		catalog-term:                                42 ;=QUALIFIER-TERM
	;   catalog-usage:                               92 ;=QUALIFIER-USAGE
	;   convert-wchar:                              122
	;   convert-interval-day-time:                  123
	;   convert-interval-year-month:                124
	;   convert-wlongvarchar:                       125
	;   convert-wvarchar:                           126
	;   create-assertion:                           127
	;   create-character-set:                       128
	;   create-collation:                           129
	;   create-domain:                              130
	;   create-schema:                              131
	;   create-table:                               132
	;   create-translation:                         133
	;   create-view:                                134
	;   driver-hdesc:                               135
	;   drop-assertion:                             136
	;   drop-character-set:                         137
	;   drop-collation:                             138
	;   drop-domain:                                139
	;   drop-schema:                                140
	;   drop-table:                                 141
	;   drop-translation:                           142
	;   drop-view:                                  143
	;   dynamic-cursor-attributes1:                 144
	;   dynamic-cursor-attributes2:                 145
	;   forward-only-cursor-attributes1:            146
	;   forward-only-cursor-attributes2:            147
	;   index-keywords:                             148
	;   info-schema-views:                          149
	;   keyset-cursor-attributes1:                  150
	;   keyset-cursor-attributes2:                  151
	;   max-async-concurrent-statements:          10022 ;-- new X/Open spec
	;   odbc-interface-conformance:                 152
	;   param-array-row-counts:                     153
	;   param-array-selects:                        154
		schema-term:                                 39 ;=OWNER-TERM
	;   schema-usage:                                91 ;=OWNER-USAGE
	;   sql92-datetime-functions:                   155
	;   sql92-foreign-key-delete-rule:              156
	;   sql92-foreign-key-update-rule:              157
	;   sql92-grant:                                158
	;   sql92-numeric-value-functions:              159
	;   sql92-predicates:                           160
	;   sql92-relational-join-operators:            161
	;   sql92-revoke:                               162
	;   sql92-row-value-constructor:                163
	;   sql92-string-functions:                     164
	;   sql92-value-expressions:                    165
	;   standard-cli-conformance:                   166
	;   static-cursor-attributes1:                  167
	;   static-cursor-attributes2:                  168
	;   aggregate-functions:                        169
	;   ddl-index:                                  170
		dm-ver:                                     171
	;   insert-statement:                           172
	;   convert-guid:                               173
	;   union-statement:                             95 ;=UNION

	;   #if ODBCVER >= 0400h [
	;   schema-inference:                           174
	;   binary-functions:                           175
	;   iso-string-functions:                       176
	;   iso-binary-functions:                       177
	;   limit-escape-clause:                        178
	;   native-escape-clause:                       179
	;   return-escape-clause:                       180
	;   format-escape-clause:                       181
	;   iso-datetime-functions:                     155 ;=SQL92-DATETIME-FUNCTIONS
	;   iso-foreign-key-delete-rule:                156 ;=SQL92-FOREIGN-KEY-DELETE-RULE
	;   iso-foreign-key-update-rule:                157 ;=SQL92-FOREIGN-KEY-UPDATE-RULE
	;   iso-grant:                                  158 ;=SQL92-GRANT
	;   iso-numeric-value-functions:                159 ;=SQL92-NUMERIC-VALUE-FUNCTIONS
	;   iso-predicates:                             160 ;=SQL92-PREDICATES
	;   iso-relational-join-operators:              161 ;=SQL92-RELATIONAL-JOIN-OPERATORS
	;   iso-revoke:                                 162 ;=SQL92-REVOKE
	;   iso-row-value-constructor:                  163 ;=SQL92-ROW-VALUE-CONSTRUCTOR
	;   iso-value-expressions:                      165 ;=SQL92-VALUE-EXPRESSIONS
	;   ] ; ODBCVER >= 0400h

	;   #if ODBCVER >= 0380h [
		;-- Info Types
	;   async-dbc-functions:                      10023
	;   ] ; ODBCVER >= 0380h

	;   driver-aware-pooling-supported:           10024

	;   #if ODBCVER >= 0380h [
	;   async-notification:                       10025

		;-- Possible values for ASYNC-NOTIFICATION
	;   async-notification-not-capable:       00000000h
	;   async-notification-capable:           00000001h
	;   ] ; ODBCVER >= 0380h

	;   dtc-transition-cost:                       1750

		;-- ALTER-TABLE bitmasks

		;-- the following 5 bitmasks are defined in sql
	;   at-add-column:                        00000001h
	;   at-drop-column:                       00000002h
	;   at-add-constraint:                    00000008h
	;   at-add-column-single:                 00000020h
	;   at-add-column-default:                00000040h
	;   at-add-column-collation:              00000080h
	;   at-set-column-default:                00000100h
	;   at-drop-column-default:               00000200h
	;   at-drop-column-cascade:               00000400h
	;   at-drop-column-restrict:              00000800h
	;   at-add-table-constraint:              00001000h
	;   at-drop-table-constraint-cascade:     00002000h
	;   at-drop-table-constraint-restrict:
	;                                         00004000h
	;   at-constraint-name-definition:        00008000h
	;   at-constraint-initially-deferred:     00010000h
	;   at-constraint-initially-immediate:
	;                                         00020000h
	;   at-constraint-deferrable:             00040000h
	;   at-constraint-non-deferrable:         00080000h

		;-- convert-* return value bitmasks
	;   cvt-char:                             00000001h
	;   cvt-numeric:                          00000002h
	;   cvt-decimal:                          00000004h
	;   cvt-integer:                          00000008h
	;   cvt-smallint:                         00000010h
	;   cvt-float:                            00000020h
	;   cvt-real:                             00000040h
	;   cvt-double:                           00000080h
	;   cvt-varchar:                          00000100h
	;   cvt-longvarchar:                      00000200h
	;   cvt-binary:                           00000400h
	;   cvt-varbinary:                        00000800h
	;   cvt-bit:                              00001000h
	;   cvt-tinyint:                          00002000h
	;   cvt-bigint:                           00004000h
	;   cvt-date:                             00008000h
	;   cvt-time:                             00010000h
	;   cvt-timestamp:                        00020000h
	;   cvt-longvarbinary:                    00040000h
	;   cvt-interval-year-month:              00080000h
	;   cvt-interval-day-time:                00100000h
	;   cvt-wchar:                            00200000h
	;   cvt-wlongvarchar:                     00400000h
	;   cvt-wvarchar:                         00800000h
	;   cvt-guid:                             01000000h

		;-- CONVERT-FUNCTIONS functions
	;   fn-cvt-convert:                       00000001h
	;   fn-cvt-cast:                          00000002h

		;-- STRING-FUNCTIONS functions

	;   fn-str-concat:                        00000001h
	;   fn-str-insert:                        00000002h
	;   fn-str-left:                          00000004h
	;   fn-str-ltrim:                         00000008h
	;   fn-str-length:                        00000010h
	;   fn-str-locate:                        00000020h
	;   fn-str-lcase:                         00000040h
	;   fn-str-repeat:                        00000080h
	;   fn-str-replace:                       00000100h
	;   fn-str-right:                         00000200h
	;   fn-str-rtrim:                         00000400h
	;   fn-str-substring:                     00000800h
	;   fn-str-ucase:                         00001000h
	;   fn-str-ascii:                         00002000h
	;   fn-str-char:                          00004000h
	;   fn-str-difference:                    00008000h
	;   fn-str-locate-2:                      00010000h
	;   fn-str-soundex:                       00020000h
	;   fn-str-space:                         00040000h
	;   fn-str-bit-length:                    00080000h
	;   fn-str-char-length:                   00100000h
	;   fn-str-character-length:              00200000h
	;   fn-str-octet-length:                  00400000h
	;   fn-str-position:                      00800000h

		;-- SQL92-STRING-FUNCTIONS
	;   ssf-convert:                          00000001h
	;   ssf-lower:                            00000002h
	;   ssf-upper:                            00000004h
	;   ssf-substring:                        00000008h
	;   ssf-translate:                        00000010h
	;   ssf-trim-both:                        00000020h
	;   ssf-trim-leading:                     00000040h
	;   ssf-trim-trailing:                    00000080h
	;   #if ODBCVER >= 0400h [
	;   ssf-overlay:                          00000100h
	;   ssf-length:                           00000200h
	;   ssf-position:                         00000400h
	;   ssf-concat:                           00000800h
	;   ] ; ODBCVER >= 0400h

		;-- BINARY-FUNCTIONS functions
	;   #if ODBCVER >= 0400h [
	;   fn-bin-bit-length:                    00080000h ;=FN-STR-BIT-LENGTH
	;   fn-bin-concat:                        00000001h ;=FN-STR-CONCAT
	;   fn-bin-insert:                        00000002h ;=FN-STR-INSERT
	;   fn-bin-ltrim:                         00000008h ;=FN-STR-LTRIM
	;   fn-bin-octet-length:                  00400000h ;=FN-STR-OCTET-LENGTH
	;   fn-bin-position:                      00800000h ;=FN-STR-POSITION
	;   fn-bin-rtrim:                         00000400h ;=FN-STR-RTRIM
	;   fn-bin-substring:                     00000800h ;=FN-STR-SUBSTRING
	;   ] ; ODBCVER >= 0400h

		;-- SQLBINARY-FUNCTIONS
	;   #if ODBCVER >= 0400h [
	;   sbf-convert:                          00000001h ;=SSF-CONVERT
	;   sbf-substring:                        00000008h ;=SSF-SUBSTRING
	;   sbf-trim-both:                        00000020h ;=SSF-TRIM-BOTH
	;   sbf-trim-leading:                     00000040h ;=SSF-TRIM-LEADING
	;   sbf-trim-trailing:                    00000080h ;=SSF-TRIM-TRAILING
	;   sbf-overlay:                          00000100h ;=SSF-OVERLAY
	;   sbf-length:                           00000200h ;=SSF-LENGTH
	;   sbf-position:                         00000400h ;=SSF-POSITION
	;   sbf-concat:                           00000800h ;=SSF-CONCAT
	;   ] ; ODBCVER >= 0400h

		;-- NUMERIC-FUNCTIONS functions
	;   fn-num-abs:                           00000001h
	;   fn-num-acos:                          00000002h
	;   fn-num-asin:                          00000004h
	;   fn-num-atan:                          00000008h
	;   fn-num-atan2:                         00000010h
	;   fn-num-ceiling:                       00000020h
	;   fn-num-cos:                           00000040h
	;   fn-num-cot:                           00000080h
	;   fn-num-exp:                           00000100h
	;   fn-num-floor:                         00000200h
	;   fn-num-log:                           00000400h
	;   fn-num-mod:                           00000800h
	;   fn-num-sign:                          00001000h
	;   fn-num-sin:                           00002000h
	;   fn-num-sqrt:                          00004000h
	;   fn-num-tan:                           00008000h
	;   fn-num-pi:                            00010000h
	;   fn-num-rand:                          00020000h
	;   fn-num-degrees:                       00040000h
	;   fn-num-log10:                         00080000h
	;   fn-num-power:                         00100000h
	;   fn-num-radians:                       00200000h
	;   fn-num-round:                         00400000h
	;   fn-num-truncate:                      00800000h

		;-- SQL92-NUMERIC-VALUE-FUNCTIONS
	;   snvf-bit-length:                      00000001h
	;   snvf-char-length:                     00000002h
	;   snvf-character-length:                00000004h
	;   snvf-extract:                         00000008h
	;   snvf-octet-length:                    00000010h
	;   snvf-position:                        00000020h

		;-- TIMEDATE-FUNCTIONS functions
	;   fn-td-now:                            00000001h
	;   fn-td-curdate:                        00000002h
	;   fn-td-dayofmonth:                     00000004h
	;   fn-td-dayofweek:                      00000008h
	;   fn-td-dayofyear:                      00000010h
	;   fn-td-month:                          00000020h
	;   fn-td-quarter:                        00000040h
	;   fn-td-week:                           00000080h
	;   fn-td-year:                           00000100h
	;   fn-td-curtime:                        00000200h
	;   fn-td-hour:                           00000400h
	;   fn-td-minute:                         00000800h
	;   fn-td-second:                         00001000h
	;   fn-td-timestampadd:                   00002000h
	;   fn-td-timestampdiff:                  00004000h
	;   fn-td-dayname:                        00008000h
	;   fn-td-monthname:                      00010000h
	;   fn-td-current-date:                   00020000h
	;   fn-td-current-time:                   00040000h
	;   fn-td-current-timestamp:              00080000h
	;   fn-td-extract:                        00100000h

		;-- SQL92-DATETIME-FUNCTIONS
	;   sdf-current-date:                     00000001h
	;   sdf-current-time:                     00000002h
	;   sdf-current-timestamp:                00000004h

		;-- SYSTEM-FUNCTIONS functions
	;   fn-sys-username:                      00000001h
	;   fn-sys-dbname:                        00000002h
	;   fn-sys-ifnull:                        00000004h

		;-- TIMEDATE-ADD-INTERVALS and TIMEDATE-DIFF-INTERVALS functions
	;   fn-tsi-frac-second:                   00000001h
	;   fn-tsi-second:                        00000002h
	;   fn-tsi-minute:                        00000004h
	;   fn-tsi-hour:                          00000008h
	;   fn-tsi-day:                           00000010h
	;   fn-tsi-week:                          00000020h
	;   fn-tsi-month:                         00000040h
	;   fn-tsi-quarter:                       00000080h
	;   fn-tsi-year:                          00000100h

		;-- bitmasks for DYNAMIC-CURSOR-ATTRIBUTES
		;   FORWARD-ONLY-CURSOR-ATTRIBUTES1,
		;   KEYSET-CURSOR-ATTRIBUTES1, and STATIC-CURSOR-ATTRIBUTES1
		;
		;-- supported SQLFetchScroll FetchOrientation's
		ca1-next:                             00000001h
		ca1-absolute:                         00000002h
		ca1-relative:                         00000004h
		ca1-bookmark:                         00000008h

		;-- supported SQLSetPos LockType's
		ca1-lock-no-change:                   00000040h
		ca1-lock-exclusive:                   00000080h
		ca1-lock-unlock:                      00000100h

		;-- supported SQLSetPos Operations
		ca1-pos-position:                     00000200h
		ca1-pos-update:                       00000400h
		ca1-pos-delete:                       00000800h
		ca1-pos-refresh:                      00001000h

		;-- positioned updates and deletes
		ca1-positioned-update:                00002000h
		ca1-positioned-delete:                00004000h
		ca1-select-for-update:                00008000h

		;-- supported SQLBulkOperations operations
		ca1-bulk-add:                         00010000h
		ca1-bulk-update-by-bookmark:          00020000h
		ca1-bulk-delete-by-bookmark:          00040000h
		ca1-bulk-fetch-by-bookmark:           00080000h

		;-- bitmasks for DYNAMIC-CURSOR-ATTRIBUTES2,
		;   FORWARD-ONLY-CURSOR-ATTRIBUTES2,
		;   KEYSET-CURSOR-ATTRIBUTES2, and STATIC-CURSOR-ATTRIBUTES2
		;
		;-- supported values for ATTR-SCROLL-CONCURRENCY
		ca2-read-only-concurrency:            00000001h
		ca2-lock-concurrency:                 00000002h
		ca2-opt-rowver-concurrency:           00000004h
		ca2-opt-values-concurrency:           00000008h

		;-- sensitivity of the cursor to its own inserts, deletes, and updates
		ca2-sensitivity-additions:            00000010h
		ca2-sensitivity-deletions:            00000020h
		ca2-sensitivity-updates:              00000040h

		;-- semantics of ATTR-MAX-ROWS
		ca2-max-rows-select:                  00000080h
		ca2-max-rows-insert:                  00000100h
		ca2-max-rows-delete:                  00000200h
		ca2-max-rows-update:                  00000400h
		ca2-max-rows-catalog:                 00000800h
		ca2-max-rows-affects-all:             00000F80h ;CA2-MAX-ROWS-SELECT |
														;CA2-MAX-ROWS-INSERT | CA2-MAX-ROWS-DELETE |
														;CA2-MAX-ROWS-UPDATE | CA2-MAX-ROWS-CATALOG

		;-- semantics of DIAG-CURSOR-ROW-COUNT
		ca2-crc-exact:                        00001000h
		ca2-crc-approximate:                  00002000h

		;-- the kinds of positioned statements that can be simulated
		ca2-simulate-non-unique:              00004000h
		ca2-simulate-try-unique:              00008000h
		ca2-simulate-unique:                  00010000h

		;-- ODBC-API-CONFORMANCE values
	;   oac-none:                                 0000h
	;   oac-level1:                               0001h
	;   oac-level2:                               0002h

		;-- ODBC-SAG-CLI-CONFORMANCE values
	;   oscc-not-compliant:                       0000h
	;   oscc-compliant:                           0001h

		;-- ODBC-SQL-CONFORMANCE values
	;   osc-minimum:                              0000h
	;   osc-core:                                 0001h
	;   osc-extended:                             0002h

		;-- CONCAT-NULL-BEHAVIOR values
	;   cb-null:                                  0000h
	;   cb-non-null:                              0001h

		;-- SCROLL-OPTIONS masks
	;   so-forward-only:                      00000001h
	;   so-keyset-driven:                     00000002h
	;   so-dynamic:                           00000004h
	;   so-mixed:                             00000008h
	;   so-static:                            00000010h

		;-- FETCH-DIRECTION masks
		;
		;-- FETCH-RESUME is no longer supported
	;   fd-fetch-resume:                      00000040h
	;   fd-fetch-bookmark:                    00000080h

		;-- TXN-ISOLATION-OPTION masks
		;   TXN-VERSIONING is no longer supported
	;   txn-versioning:                       00000010h

		;-- CORRELATION-NAME values
	;   cn-none:                                  0000h
	;   cn-different:                             0001h
	;   cn-any:                                   0002h

		;-- NON-NULLABLE-COLUMNS values
	;   nnc-null:                                 0000h
	;   nnc-non-null:                             0001h

		;-- NULL-COLLATION values
	;   nc-start:                                 0002h
	;   nc-end:                                   0004h

		;-- FILE-USAGE values
	;   file-not-supported:                       0000h
	;   file-table:                               0001h
	;   file-qualifier:                           0002h
	;   file-catalog:                             0002h ;=FILE-QUALIFIER ;-- ODBC 3.0

		;-- GETDATA-EXTENSIONS values
	;   gd-block:                             00000004h
	;   gd-bound:                             00000008h
	;   #if ODBCVER >= 0380h [
	;   gd-output-params:                     00000010h
	;   ] ; ODBCVER >= 0380h
	;   #if ODBCVER >= 0400h [
	;   gd-concurrent:                        00000020h
	;   ] ; ODBCVER >= 0400h

		;-- POSITIONED-STATEMENTS masks
	;   ps-positioned-delete:                 00000001h
	;   ps-positioned-update:                 00000002h
	;   ps-select-for-update:                 00000004h

		;-- GROUP-BY values
	;   gb-not-supported:                         0000h
	;   gb-group-by-equals-select:                0001h
	;   gb-group-by-contains-select:              0002h
	;   gb-no-relation:                           0003h
	;   gb-collate:                               0004h

		;-- OWNER-USAGE masks
	;   ou-dml-statements:                    00000001h
	;   ou-procedure-invocation:              00000002h
	;   ou-table-definition:                  00000004h
	;   ou-index-definition:                  00000008h
	;   ou-privilege-definition:              00000010h

		;-- SCHEMA-USAGE masks
	;   su-dml-statements:                    00000001h ;=OU-DML-STATEMENTS
	;   su-procedure-invocation:              00000002h ;=OU-PROCEDURE-INVOCATION
	;   su-table-definition:                  00000004h ;=OU-TABLE-DEFINITION
	;   su-index-definition:                  00000008h ;=OU-INDEX-DEFINITION
	;   su-privilege-definition:              00000010h ;=OU-PRIVILEGE-DEFINITION

		;-- QUALIFIER-USAGE masks
	;   qu-dml-statements:                    00000001h
	;   qu-procedure-invocation:              00000002h
	;   qu-table-definition:                  00000004h
	;   qu-index-definition:                  00000008h
	;   qu-privilege-definition:              00000010h

		;-- CATALOG-USAGE masks
	;   cu-dml-statements:                    00000001h ;=QU-DML-STATEMENTS
	;   cu-procedure-invocation:              00000002h ;=QU-PROCEDURE-INVOCATION
	;   cu-table-definition:                  00000004h ;=QU-TABLE-DEFINITION
	;   cu-index-definition:                  00000008h ;=QU-INDEX-DEFINITION
	;   cu-privilege-definition:              00000010h ;=QU-PRIVILEGE-DEFINITION

		;-- SUBQUERIES masks
	;   sq-comparison:                        00000001h
	;   sq-exists:                            00000002h
	;   sq-in:                                00000004h
	;   sq-quantified:                        00000008h
	;   sq-correlated-subqueries:             00000010h

		;-- UNION masks
	;   u-union:                              00000001h
	;   u-union-all:                          00000002h

		;-- BOOKMARK-PERSISTENCE values
	;   bp-close:                             00000001h
	;   bp-delete:                            00000002h
	;   bp-drop:                              00000004h
	;   bp-transaction:                       00000008h
	;   bp-update:                            00000010h
	;   bp-other-hstmt:                       00000020h
	;   bp-scroll:                            00000040h

		;-- STATIC-SENSITIVITY values
	;   ss-additions:                         00000001h
	;   ss-deletions:                         00000002h
	;   ss-updates:                           00000004h

		;-- VIEW values
	;   cv-create-view:                       00000001h
	;   cv-check-option:                      00000002h
	;   cv-cascaded:                          00000004h
	;   cv-local:                             00000008h

		;-- LOCK-TYPES masks
	;   lck-no-change:                        00000001h
	;   lck-exclusive:                        00000002h
	;   lck-unlock:                           00000004h

		;-- POS-OPERATIONS masks
	;   pos-position:                         00000001h
	;   pos-refresh:                          00000002h
	;   pos-update:                           00000004h
	;   pos-delete:                           00000008h
	;   pos-add:                              00000010h

		;-- QUALIFIER-LOCATION values
	;   ql-start:                                 0001h
	;   ql-end:                                   0002h

		;-- Here start return values for ODBC 3.0 SQLGetInfo
		;-- AGGREGATE-FUNCTIONS bitmasks
	;   af-avg:                               00000001h
	;   af-count:                             00000002h
	;   af-max:                               00000004h
	;   af-min:                               00000008h
	;   af-sum:                               00000010h
	;   af-distinct:                          00000020h
	;   af-all:                               00000040h
	;   #if ODBCVER >= 0400h [
	;   af-every:                             00000080h
	;   af-any:                               00000100h
	;   af-stdev-op:                          00000200h
	;   af-stdev-samp:                        00000400h
	;   af-var-samp:                          00000800h
	;   af-var-pop:                           00001000h
	;   af-array-agg:                         00002000h
	;   af-collect:                           00004000h
	;   af-fusion:                            00008000h
	;   af-intersection:                      00010000h
	;   ] ; ODBCVER >= 0400h

		;-- SQL-CONFORMANCE bit masks
	;   sc-sql92-entry:                       00000001h
	;   sc-fips127-2-transitional:            00000002h
	;   sc-sql92-intermediate:                00000004h
	;   sc-sql92-full:                        00000008h

		;-- DATETIME-LITERALS masks
	;   dl-sql92-date:                        00000001h
	;   dl-sql92-time:                        00000002h
	;   dl-sql92-timestamp:                   00000004h
	;   dl-sql92-interval-year:               00000008h
	;   dl-sql92-interval-month:              00000010h
	;   dl-sql92-interval-day:                00000020h
	;   dl-sql92-interval-hour:               00000040h
	;   dl-sql92-interval-minute:             00000080h
	;   dl-sql92-interval-second:             00000100h
	;   dl-sql92-interval-year-to-month:      00000200h
	;   dl-sql92-interval-day-to-hour:        00000400h
	;   dl-sql92-interval-day-to-minute:      00000800h
	;   dl-sql92-interval-day-to-second:      00001000h
	;   dl-sql92-interval-hour-to-minute:     00002000h
	;   dl-sql92-interval-hour-to-second:     00004000h
	;   dl-sql92-interval-minute-to-second:   00008000h

		;-- CATALOG-LOCATION values
	;   cl-start:                                 0001h ;=QL-START
	;   cl-end:                                   0002h ;=QL-END

		;-- values for BATCH-ROW-COUNT
	;   brc-procedures:                       00000001h
	;   brc-explicit:                         00000002h
	;   brc-rolled-up:                        00000004h

		;-- bitmasks for BATCH-SUPPORT
	;   bs-select-explicit:                   00000001h
	;   bs-row-count-explicit:                00000002h
	;   bs-select-proc:                       00000004h
	;   bs-row-count-proc:                    00000008h

		;-- Values for PARAM-ARRAY-ROW-COUNTS getinfo
	;   parc-batch:                                   1
	;   parc-no-batch:                                2

		;-- values for PARAM-ARRAY-SELECTS
	;   pas-batch:                                    1
	;   pas-no-batch:                                 2
	;   pas-no-select:                                3

		;-- Bitmasks for INDEX-KEYWORDS
	;   ik-none:                              00000000h
	;   ik-asc:                               00000001h
	;   ik-desc:                              00000002h
	;   ik-all:                               00000003h ;=IK-ASC or IK-DESC

		;-- Bitmasks for INFO-SCHEMA-VIEWS
	;   isv-assertions:                       00000001h
	;   isv-character-sets:                   00000002h
	;   isv-check-constraints:                00000004h
	;   isv-collations:                       00000008h
	;   isv-column-domain-usage:              00000010h
	;   isv-column-privileges:                00000020h
	;   isv-columns:                          00000040h
	;   isv-constraint-column-usage:          00000080h
	;   isv-constraint-table-usage:           00000100h
	;   isv-domain-constraints:               00000200h
	;   isv-domains:                          00000400h
	;   isv-key-column-usage:                 00000800h
	;   isv-referential-constraints:          00001000h
	;   isv-schemata:                         00002000h
	;   isv-sql-languages:                    00004000h
	;   isv-table-constraints:                00008000h
	;   isv-table-privileges:                 00010000h
	;   isv-tables:                           00020000h
	;   isv-translations:                     00040000h
	;   isv-usage-privileges:                 00080000h
	;   isv-view-column-usage:                00100000h
	;   isv-view-table-usage:                 00200000h
	;   isv-views:                            00400000h

		;-- Bitmasks for ALTER-DOMAIN
	;   ad-constraint-name-definition:        00000001h
	;   ad-add-domain-constraint:             00000002h
	;   ad-drop-domain-constraint:            00000004h
	;   ad-add-domain-default:                00000008h
	;   ad-drop-domain-default:               00000010h
	;   ad-add-constraint-initially-deferred: 00000020h
	;   ad-add-constraint-initially-immediate:
	;                                         00000040h
	;   ad-add-constraint-deferrable:         00000080h
	;   ad-add-constraint-non-deferrable:     00000100h

		;-- CREATE-SCHEMA bitmasks
	;   cs-create-schema:                     00000001h
	;   cs-authorization:                     00000002h
	;   cs-default-character-set:             00000004h

		;-- CREATE-TRANSLATION bitmasks
	;   ctr-create-translation:               00000001h

		;-- CREATE-ASSERTION bitmasks
	;   ca-create-assertion:                  00000001h
	;   ca-constraint-initially-deferred:     00000010h
	;   ca-constraint-initially-immediate:    00000020h
	;   ca-constraint-deferrable:             00000040h
	;   ca-constraint-non-deferrable:         00000080h

		;-- CREATE-CHARACTER-SET bitmasks
	;   ccs-create-character-set:             00000001h
	;   ccs-collate-clause:                   00000002h
	;   ccs-limited-collation:                00000004h

		;-- CREATE-COLLATION bitmasks
	;   ccol-create-collation:                00000001h

		;-- CREATE-DOMAIN bitmasks
	;   cdo-create-domain:                    00000001h
	;   cdo-default:                          00000002h
	;   cdo-constraint:                       00000004h
	;   cdo-collation:                        00000008h
	;   cdo-constraint-name-definition:       00000010h
	;   cdo-constraint-initially-deferred:    00000020h
	;   cdo-constraint-initially-immediate:   00000040h
	;   cdo-constraint-deferrable:            00000080h
	;   cdo-constraint-non-deferrable:        00000100h

		;-- CREATE-TABLE bitmasks
	;   ct-create-table:                      00000001h
	;   ct-commit-preserve:                   00000002h
	;   ct-commit-delete:                     00000004h
	;   ct-global-temporary:                  00000008h
	;   ct-local-temporary:                   00000010h
	;   ct-constraint-initially-deferred:     00000020h
	;   ct-constraint-initially-immediate:    00000040
	;   ct-constraint-deferrable:             00000080h
	;   ct-constraint-non-deferrable:         00000100h
	;   ct-column-constraint:                 00000200h
	;   ct-column-default:                    00000400h
	;   ct-column-collation:                  00000800h
	;   ct-table-constraint:                  00001000h
	;   ct-constraint-name-definition:        00002000h

		;-- DDL-INDEX bitmasks
	;   di-create-index:                      00000001h
	;   di-drop-index:                        00000002h

		;-- DROP-COLLATION bitmasks
	;   dc-drop-collation:                    00000001h

		;-- DROP-DOMAIN bitmasks
	;   dd-drop-domain:                       00000001h
	;   dd-restrict:                          00000002h
	;   dd-cascade:                           00000004h

		;-- DROP-SCHEMA bitmasks
	;   ds-drop-schema:                       00000001h
	;   ds-restrict:                          00000002h
	;   ds-cascade:                           00000004h

		;-- DROP-CHARACTER-SET bitmasks
	;   dcs-drop-character-set:               00000001h

		;-- drop-assertion bitmasks
	;   da-drop-assertion:                    00000001h

		;-- DROP-TABLE bitmasks
	;   dt-drop-table:                        00000001h
	;   dt-restrict:                          00000002h
	;   dt-cascade:                           00000004h

		;-- DROP-TRANSLATION bitmasks
	;   dtr-drop-translation:                 00000001h

		;-- DROP-VIEW bitmasks
	;   dv-drop-view:                         00000001h
	;   dv-restrict:                          00000002h
	;   dv-cascade:                           00000004h

		;-- INSERT-STATEMENT bitmasks
	;   is-insert-literals:                   00000001h
	;   is-insert-searched:                   00000002h
	;   is-select-into:                       00000004h

		;-- ODBC-INTERFACE-CONFORMANCE values
	;   oic-core:                                     1 ;1UL
	;   oic-level1:                                   2 ;2UL
	;   oic-level2:                                   3 ;3UL

		;-- SQL92-FOREIGN-KEY-DELETE-RULE bitmasks
	;   sfkd-cascade:                         00000001h
	;   sfkd-no-action:                       00000002h
	;   sfkd-set-default:                     00000004h
	;   sfkd-set-null:                        00000008h

		;-- SQL92-FOREIGN-KEY-UPDATE-RULE bitmasks
	;   sfku-cascade:                         00000001h
	;   sfku-no-action:                       00000002h
	;   sfku-set-default:                     00000004h
	;   sfku-set-null:                        00000008h

		;-- SQL92-GRANT bitmasks
	;   sg-usage-on-domain:                   00000001h
	;   sg-usage-on-character-set:            00000002h
	;   sg-usage-on-collation:                00000004h
	;   sg-usage-on-translation:              00000008h
	;   sg-with-grant-option:                 00000010h
	;   sg-delete-table:                      00000020h
	;   sg-insert-table:                      00000040h
	;   sg-insert-column:                     00000080h
	;   sg-references-table:                  00000100h
	;   sg-references-column:                 00000200h
	;   sg-select-table:                      00000400h
	;   sg-update-table:                      00000800h
	;   sg-update-column:                     00001000h

		;-- SQL92-PREDICATES bitmasks
	;   sp-exists:                            00000001h
	;   sp-isnotnull:                         00000002h
	;   sp-isnull:                            00000004h
	;   sp-match-full:                        00000008h
	;   sp-match-partial:                     00000010h
	;   sp-match-unique-full:                 00000020h
	;   sp-match-unique-partial:              00000040h
	;   sp-overlaps:                          00000080h
	;   sp-unique:                            00000100h
	;   sp-like:                              00000200h
	;   sp-in:                                00000400h
	;   sp-between:                           00000800h
	;   sp-comparison:                        00001000h
	;   sp-quantified-comparison:             00002000h

		;-- SQL92-RELATIONAL-JOIN-OPERATORS bitmasks
	;   srjo-corresponding-clause:            00000001h
	;   srjo-cross-join:                      00000002h
	;   srjo-except-join:                     00000004h
	;   srjo-full-outer-join:                 00000008h
	;   srjo-inner-join:                      00000010h
	;   srjo-intersect-join:                  00000020h
	;   srjo-left-outer-join:                 00000040h
	;   srjo-natural-join:                    00000080h
	;   srjo-right-outer-join:                00000100h
	;   srjo-union-join:                      00000200h

		;-- SQL92-REVOKE bitmasks
	;   sr-usage-on-domain:                   00000001h
	;   sr-usage-on-character-set:            00000002h
	;   sr-usage-on-collation:                00000004h
	;   sr-usage-on-translation:              00000008h
	;   sr-grant-option-for:                  00000010h
	;   sr-cascade:                           00000020h
	;   sr-restrict:                          00000040h
	;   sr-delete-table:                      00000080h
	;   sr-insert-table:                      00000100h
	;   sr-insert-column:                     00000200h
	;   sr-references-table:                  00000400h
	;   sr-references-column:                 00000800h
	;   sr-select-table:                      00001000h
	;   sr-update-table:                      00002000h
	;   sr-update-column:                     00004000h

		;-- SQL92-ROW-VALUE-CONSTRUCTOR bitmasks
	;   srvc-value-expression:                00000001h
	;   srvc-null:                            00000002h
	;   srvc-default:                         00000004h
	;   srvc-row-subquery:                    00000008h

		;-- SQL92-VALUE-EXPRESSIONS bitmasks
	;   sve-case:                             00000001h
	;   sve-cast:                             00000002h
	;   sve-coalesce:                         00000004h
	;   sve-nullif:                           00000008h

		;-- STANDARD-CLI-CONFORMANCE bitmasks
	;   scc-xopen-cli-version1:               00000001h
	;   scc-iso92-cli:                        00000002h

		;-- UNION-STATEMENT bitmasks
	;   us-union:                                       U-UNION
	;   us-union-all:                                   U-UNION-ALL

		;-- values for DRIVER-AWARE-POOLING-SUPPORTED
	;   driver-aware-pooling-not-capable:     00000000h
	;   driver-aware-pooling-capable:         00000001h

		;-- DTC-TRANSITION-COST bitmasks
	;   dtc-enlist-expensive:                 00000001h
	;   dtc-unenlist-expensive:               00000002h

	;   #if ODBCVER >= 0380h [
		;-- possible values for ASYNC-DBC-FUNCTION
	;   async-dbc-not-capable:                00000000h
	;   async-dbc-capable:                    00000001h
	;   ] ; ODBCVER >= 0380h

		;-- Bitmask values for LIMIT-ESCAPE-CLAUSE
	;   #if ODBCVER >= 0400h [
	;   lc-none:                              00000000h
	;   lc-take:                              00000001h
	;   lc-skip:                              00000003h
	;   ] ; ODBCVER >= 0400h

		;-- Bitmask values for RETURN-ESCAPE-CLAUSE
	;   #if ODBCVER >= 0400h [
	;   rc-none:                              00000000h
	;   rc-insert-single-rowid:               00000001h
	;   rc-insert-single-any:              [( 00000002h or RC-INSERT-SINGLE-ROWID )]
	;   rc-insert-multiple-rowid:          [( 00000004h or RC-INSERT-SINGLE-ROWID )]
	;   rc-insert-multiple-any:            [( 00000008h or RC-INSERT-MULTIPLE-ROWID or RC-INSERT-SINGLE-ANY )]
	;   rc-insert-select-rowid:               00000010h
	;   rc-insert-select-any:              [( 00000020h or RC-INSERT-SELECT-ROWID )]
	;   rc-update-rowid:                      00000040h
	;   rc-update-any:                     [( 00000080h or RC-UPDATE-ROWID )]
	;   rc-delete-rowid:                      00000100h
	;   rc-delete-any:                     [( 00000200h or RC-DELETE-ROWID )]
	;   rc-select-into-rowid:                 00000400h
	;   rc-select-into-any:                [( 00000800h or RC-SELECT-INTO-ROWID )]
	;   ] ; ODBCVER >= 0400h

		;-- Bitmask values for FORMAT-ESCAPE-CLAUSE
	;   #if ODBCVER >= 0400h [
	;   fc-none:                              00000000h
	;   fc-json:                              00000001h
	;   fc-json-binary:                       00000002h
	;   ] ; ODBCVER >= 0400h

		;-- additional SQLDataSources fetch directions
		fetch-first-user:                            31
		fetch-first-system:                          32

		;-- Defines for SQLSetPos
	;   entire-rowset:                                0

		;-- Operations in SQLSetPos
		position:                                     0 ;-- 1.0 FALSE
	;   refresh:                                      1 ;-- 1.0 TRUE
	;   update:                                       2
	;   delete:                                       3

		;-- Operations in SQLBulkOperations
	;   add:                                          4
	;   setpos-max-option-value:                      4 ;=ADD
	;   update-by-bookmark:                           5
	;   delete-by-bookmark:                           6
	;   fetch-by-bookmark:                            7

		;-- Lock options in SQLSetPos
		lock-no-change:                               0 ;-- 1.0 FALSE
	;   lock-exclusive:                               1 ;-- 1.0 TRUE
	;   lock-unlock:                                  2

	;   SETPOS-MAX-LOCK-VALUE:                        2 ;=LOCK-UNLOCK

		;-- Macros for SQLSetPos
	;   #define POSITION-TO    (hstmt irow)         [SQLSetPos hstmt irow POSITION LOCK-NO-CHANGE]
	;   #define LOCK-RECORD    (hstmt irow fLock)   [SQLSetPos hstmt irow POSITION fLock]
	;   #define REFRESH-RECORD (hstmt irow fLock)   [SQLSetPos hstmt irow REFRESH  fLock]
	;   #define UPDATE-RECORD  (hstmt irow)         [SQLSetPos hstmt irow UPDATE   LOCK-NO-CHANGE]
	;   #define DELETE-RECORD  (hstmt irow)         [SQLSetPos hstmt irow DELETE   LOCK-NO-CHANGE]
	;   #define ADD-RECORD     (hstmt irow)         [SQLSetPos hstmt irow ADD      LOCK-NO-CHANGE]

		;-- Column types and scopes in SQLSpecialColumns
		best-rowid:                                   1
		rowver:                                       2

		;-- Defines for SQLSpecialColumns (returned in the result set)
		;   PC-UNKNOWN and PC-PSEUDO are defined in sql.h
	;   pc-not-pseudo:                                1

		;-- Defines for SQLStatistics
		quick:                                        0
		ensure:                                       1

		;-- Defines for SQLStatistics (returned in the result set)
		;   INDEX-CLUSTERED, INDEX-HASHED, and INDEX-OTHER are
		;   defined in sql.h
	;   table-stat:                                   0

		;-- Defines for SQLTables
	;   all-catalogs:                               "%"
	;   all-schemas:                                "%"
	;   all-table-types:                            "%"

		;-- Options for SQLDriverConnect
		driver-noprompt:                              0
	;   driver-complete:                              1
	;   driver-prompt:                                2
	;   driver-complete-required:                     3

		;-- Level 2 Functions

		;-- SQLExtendedFetch "fFetchType" values
	;   fetch-bookmark:                               8

		;-- SQLExtendedFetch "rgfRowStatus" element values
	;   row-success:                                  0
	;   row-deleted:                                  1
	;   row-updated:                                  2
	;   row-norow:                                    3
	;   row-added:                                    4
	;   row-error:                                    5
	;   row-success-with-info:                        6
	;   row-proceed:                                  0
	;   row-ignore:                                   1

		;-- value for DESC-ARRAY-STATUS-PTR
	;   param-success:                                0
	;   param-success-with-info:                      6
	;   param-error:                                  5
	;   param-unused:                                 7
	;   param-diag-unavailable:                       1
	;   param-proceed:                                0
	;   param-ignore:                                 1

		;-- Defines for SQLForeignKeys (UPDATE-RULE and DELETE-RULE)
	;   cascade:                                      0
	;   restrict:                                     1
	;   set-null:                                     2
	;   no-action:                                    3
	;   set-default:                                  4

		;-- Note that the following are in a different column of SQLForeignKeys than
		;   the previous #defines.   These are for DEFERRABILITY.
	;   initially-deferred:                           5
	;   initially-immediate:                          6
	;   not-deferrable:                               7

		;-- Defines for SQLBindParameter and
		;   SQLProcedureColumns (returned in the result set)
	;   param-type-unknown                            0
		param-input:                                  1
	;   param-input-output:                           2
	;   result-col:                                   3
	;   param-output:                                 4
	;   return-value:                                 5
	;   #if ODBCVER >= 0380h [
	;   param-input-output-stream:                    8
	;   param-output-stream:                         16
	;   ] ; ODBCVER >= 0380h

		;-- Defines for SQLProcedures (returned in the result set)
	;   pt-unknown:                                   0
	;   pt-procedure:                                 1
	;   pt-function:                                  2

	] ;-- enum


	;##########################000000####### sqlfuncs ##
	;
	;  ██████  ██████  ██      ███████ ██    ██ ███    ██  ██████  ██████
	; ██      ██    ██ ██      ██      ██    ██ ████   ██ ██      ██
	;  █████  ██    ██ ██      █████   ██    ██ ██ ██  ██ ██       █████
	;      ██ ██ ▄▄ ██ ██      ██      ██    ██ ██  ██ ██ ██           ██
	; ██████   ██████  ███████ ██       ██████  ██   ████  ██████ ██████
	;             ▀▀

	;----------------------------------- ODBC_LIBRARY --
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

	]] ;#import

]


;---------------------------------------- ODBC macros --
;

#define ODBC_RESULT     [rc: FFFFh and]

#define ODBC_SUCCESS    [rc = sql/success]
#define ODBC_INFO       [rc = sql/success-with-info]
#define ODBC_NO_DATA    [rc = sql/no-data]
#define ODBC_NEED_DATA  [rc = sql/need-data]
#define ODBC_ERROR      [rc = sql/error]
#define ODBC_INVALID    [rc = sql/invalid-handle]
#define ODBC_EXECUTING  [rc = sql/still-executing]

#define ODBC_SUCCEEDED  [any [rc = sql/success rc = sql/success-with-info]]
#define ODBC_FAILED     [any [rc = sql/error   rc = sql/success-with-info]]

#define ODBC_DIAGNOSIS(type handle entity) [
		if any [rc = sql/error rc = sql/success-with-info] [odbc/diagnose-error type handle entity]
]


odbc: context [

	;--------------------------- state objects layout --
	;

	#enum odbc-field! [
		common-field-type:          0
		common-field-handle
		common-field-errors
		common-field-flat?

		env-field-count:            4
		env-field-connections
		env-field-login-timeout

		dbc-field-environment:      4
		dbc-field-statements
		dbc-field-info
		dbc-field-port
		dbc-field-auto-commit

		stmt-field-connection:      4
		stmt-field-sql
		stmt-field-params
		stmt-field-prms-status
		stmt-field-window
		stmt-field-columns
		stmt-field-scroll
		stmt-field-rows-status
		stmt-field-rows-fetched
		stmt-field-port
		stmt-field-cursor

		col-field-name:             0
		col-field-sql-type
		col-field-col-size
		col-field-digits
		col-field-nullable
		col-field-buffer
		col-field-buffer-len
		col-field-strlen-ind
		col-field-fields:           8
	]

	;---------------------------------------- symbols --
	;

	_all:           symbol/resolve symbol/make "all"
	_at:            symbol/resolve symbol/make "at"
	_back:          symbol/resolve symbol/make "back"
	_column:        symbol/resolve symbol/make "column"
	_columns:       symbol/resolve symbol/make "columns"
	_connection:    symbol/resolve symbol/make "connection"
	_environment:   symbol/resolve symbol/make "environment"
	_foreign:       symbol/resolve symbol/make "foreign"
	_head:          symbol/resolve symbol/make "head"
	_info:          symbol/resolve symbol/make "info"
	_keys:          symbol/resolve symbol/make "keys"
	_next:          symbol/resolve symbol/make "next"
	_primary:       symbol/resolve symbol/make "primary"
	_privileges:    symbol/resolve symbol/make "privileges"
	_procedure:     symbol/resolve symbol/make "procedure"
	_procedures:    symbol/resolve symbol/make "procedures"
	_row:           symbol/resolve symbol/make "row"
	_session:       symbol/resolve symbol/make "session"
	_skip:          symbol/resolve symbol/make "skip"
	_special:       symbol/resolve symbol/make "special"
	_statement:     symbol/resolve symbol/make "statement"
	_statistics:    symbol/resolve symbol/make "statistics"
	_system:        symbol/resolve symbol/make "system"
	_table:         symbol/resolve symbol/make "table"
	_tables:        symbol/resolve symbol/make "tables"
	_tail:          symbol/resolve symbol/make "tail"
	_transaction:   symbol/resolve symbol/make "transaction"
	_types:         symbol/resolve symbol/make "types"
	_unique:        symbol/resolve symbol/make "unique"
	_update:        symbol/resolve symbol/make "update"
	_user:          symbol/resolve symbol/make "user"

	odbc:           word/load "ODBC"


	;---------------------------------- print-wstring --
	;   debugging only

	print-wstring: func [
		str [c-string!]
	][
		loop (wlength? str) << 1 [
			prin str str: str + 1
		]
	]


	;----------------------------------- print-buffer --
	;   debugging only

	print-buffer: func [
		bytes   [byte-ptr!]
		cnt     [integer!]
		/local
			--- i c byte hi lo hex x
	][
		---: "----------------"
		hex: "0123456789abcdef"
		print [lf --- --- --- --- --- --- --- --- "---" lf]
		i: 0
		while [true] [
			print [bytes ":  "]
			c: 0
			until [
				either i + c >= cnt [print "  "] [
					x: c + 1
					byte: bytes/x
					hi: (F0h and as integer! byte) >>> 4 + 1
					lo: (0Fh and as integer! byte)       + 1
					print [hex/hi hex/lo]
				]
				c: c + 1
				if c % 2 = 0 [print " "]
				if c % 8 = 0 [print " "]
				c = 32
			]
			prin "    "
			c: 0
			until [
				either i + c >= cnt [print " "] [
					x: c + 1
					byte: bytes/x
					case [
						byte <= #"^(1f)" [print  "."]
						byte <= #"^(7f)" [print byte]
						byte <= #"^(9f)" [print  "."]
						byte <= #"^(ff)" [print byte]
					]
				]
				c: c + 1
				c = 32
			]
			print lf
			either i + 32 >= cnt [break] [
				i: i + 32
				bytes: bytes + 32
			]
		]
		print [--- --- --- --- --- --- --- --- "---" lf]
	]


	;--------------------------------------- wlength? --
	;   There must be sth. better

	wlength?: func [
		"Returns length in wide chars, terminating null char included."
		wide        [c-string!]
		return:     [integer!]
		/local
			i       [integer!]
	][
		i: 0
		while [any [wide/1 <> #"^@" wide/2 <> #"^@"]] [i: i + 1 wide: wide + 2]
		i
	]


	;--------------------------------- diagnose-error --
	;

	diagnose-error: func [
		handle-type     [integer!]
		handle          [integer!]
		entity          [red-object!]
		/local
			buffer-len  [integer!]
			errors      [red-block!]
			message     [byte-ptr!]
			message-len [integer!]
			native      [integer!]
			rc          [integer!]
			record-num  [integer!]
			state       [byte-ptr!]
			values      [red-value!]
	][
		#if debug? = yes [print ["DIAGNOSE-ERROR [" lf]]

		values:         object/get-values entity
		errors:         as red-block! values + common-field-errors

		state:          allocate 5 + 1 << 1

		#if debug? = yes [print ["^-allocate state, " 5 + 1 << 1 " bytes @ " state lf]]

		native:         0
		message:        null
		message-len:    0
		buffer-len:     2047
		record-num:     0

		until [
			record-num: record-num + 1

			loop 2 [
				if message = null [
					message: allocate buffer-len + 1 << 1

					#if debug? = yes [print ["^-allocate message, " buffer-len + 1 << 1 " bytes @ " message lf]]
				]

				ODBC_RESULT sql/SQLGetDiagRec handle-type
											  handle
											  record-num
											  state
											 :native
											  message
											  buffer-len
											 :message-len

				#if debug? = yes [print ["^-SQLGetDiagRec " rc lf]]

				either any [
					rc <> sql/success-with-info
					message-len <= buffer-len
				][
					break                               ;-- buffer was large enough
				][
					#if debug? = yes [print ["^-free message @ " message lf]]

					free message                        ;-- try again with bigger buffer
					message: null
					buffer-len: message-len
				]
			]

			if ODBC_SUCCEEDED [
				string/load-in as c-string! state 5             errors UTF-16LE
				integer/make-in                                 errors native
				string/load-in as c-string! message message-len errors UTF-16LE

				#if debug? = yes [print [state/1 state/3 state/5 state/7 state/9 lf]]

				print-wstring as c-string! state prin " "
				print [native " "]
				print-wstring as c-string! message print ["" lf]
			]

			any [ODBC_INVALID ODBC_ERROR ODBC_NO_DATA]
		]

		#if debug? = yes [print ["^-free state @ "   state   lf]]
		#if debug? = yes [print ["^-free message @ " message lf]]

		free state
		free message

		#if debug? = yes [print ["]" lf]]
	]

] ;context: odbc
