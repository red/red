Red [
	Title:   "Red ODBC Scheme"
	Author:  "Christian Ensel"
	File:    %odbc.red
	Tabs:    4
	Rights:  "Copyright 2022 Christian Ensel. All rights reserved."
	License: 'Unlicensed
]

;-------------------------------------------- odbc:// --
;

odbc: context [

	#system [
		#include %odbc.reds
	]

	;---------------------------------------- objects --
	;

	environment: context [                              ;-- FIXME: singleton, ODBC allows for multiple
		type:          'environment
		handle:         none
		errors:         []
		flat?:          no
		count:          0
		connections:    []
		login-timeout:  none

		drivers:        does [do reduce [get-drivers]]
		sources:        does [do reduce [get-sources]]

		on-change*:     func [word old new] [switch word [
			login-timeout [any [
				none? new
				all [integer? new positive? new]
				login-timeout: old
			]]
			flat? [flat?: either logic? new [new] [old]]
		]]
	]

	connection-proto: context [
		type:          'connection
		handle:         none
		errors:         []
		flat?:          none
		environment:    none
		statements:     []
		info:           none
		port:           none
		auto-commit?:   yes

		on-change*:     func [word old new] [switch word [
			auto-commit? [set-commit-mode self old new]
			flat? [flat?: either any [logic? new none? new] [new] [old]]
		]]
	]

	statement-proto: context [
		type:          'statement
		handle:         none
		errors:         []
		flat?:          none
		connection:     none
		sql:            none
		params:         []
		prms-status:    none
		window:         10                              ;-- default window size
		columns:        []
		scroll?:        off
		rows-status:    none
		rows-fetched:   none
		port:           none
		cursor:        'forward

		on-change*:     func [word old new] [switch word [
			scroll? [set-cursor-scrolling self old new]
			cursor  [set-cursor-type      self old new]
			flat?   [flat?: either any [logic? new none? new] [new] [old]]
		]]
	]


	;======================================= routines ==
	;

	;------------------------------- open-environment --
	;

	open-environment: routine [
		environment     [object!]
		return:         [none!]
		/local
			sqlhenv     [integer!]
			rc          [integer!]
	][
		#if debug? = yes [print ["OPEN-ENVIRONMENT [" lf]]

		sqlhenv: 0

		ODBC_RESULT sql/SQLAllocHandle sql/handle-env
									   null
									  :sqlhenv

		#if debug? = yes [print ["^-SQLAllocHandle " rc lf]]

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) environment
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(internal no-memory) environment
		]]

		copy-cell as red-value! handle/box sqlhenv
				(object/get-values environment) + odbc/common-field-handle

		ODBC_RESULT sql/SQLSetEnvAttr sqlhenv
									  sql/attr-odbc-version
									  sql/ov-odbc3
									  0

		#if debug? = yes [print ["^-SQLSetEnvAttr " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-env sqlhenv environment)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) environment
		]]
		if ODBC_ERROR   [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values environment) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]

		as red-none! SET_RETURN(none-value)
	]


	;----------------------------------- list-drivers --
	;

	list-drivers: routine [
		environment     [object!]
		/local
			henv        [red-handle!]
			drivers     [red-block!]
			rc          [integer!]
			direction   [integer!]
			desc-buf    [byte-ptr!]
			desc-len    [integer!]
			desc-out    [integer!]
			attr-buf    [byte-ptr!]
			attr-len    [integer!]
			attr-out    [integer!]
	][
		#if debug? = yes [print ["LIST-DRIVERS [" lf]]

		direction:  sql/fetch-first
		desc-buf:   null
		desc-len:   1000
		desc-out:   0
		attr-buf:   null
		attr-len:   4000
		attr-out:   0

		henv: as red-handle! (object/get-values environment) + odbc/common-field-handle

		drivers: block/push-only* 32

		until [
			if desc-buf = null [
				desc-buf: allocate desc-len + 1 << 1

				#if debug? = yes [print ["^-allocate desc-buf, " desc-len + 1 << 1 " bytes @ " desc-buf lf]]
			]
			if attr-buf = null [
				attr-buf: allocate attr-len + 1 << 1

				#if debug? = yes [print ["^-allocate attr-buf, " attr-len + 1 << 1 " bytes @ " attr-buf lf]]
			]

			ODBC_RESULT sql/SQLDrivers henv/value
									   direction
									   desc-buf
									   desc-len
									  :desc-out
									   attr-buf
									   attr-len
									  :attr-out

			#if debug? = yes [print ["^-SQLDrivers " rc lf]]

			either all [ODBC_INFO any [
				desc-len < desc-out
				attr-len < attr-out
			]] [
				#if debug? = yes [print ["^-free desc-buf @ " desc-buf lf]]

				free desc-buf
				desc-buf: null
				desc-len: desc-out

				#if debug? = yes [print ["^-free attr-buf @ " attr-buf lf]]

				free attr-buf
				attr-buf: null
				attr-len: attr-out

				block/rs-clear drivers                  ;-- try again with larger buffers
				direction: sql/fetch-first              ;

				continue
			][
				direction: sql/fetch-next
			]

			ODBC_DIAGNOSIS(sql/handle-env henv/value environment)

			if ODBC_SUCCEEDED [
				string/load-in as c-string! desc-buf desc-out drivers UTF-16LE
				string/load-in as c-string! attr-buf attr-out drivers UTF-16LE
			]

			any [ODBC_INVALID ODBC_NO_DATA ODBC_ERROR]
		]

		#if debug? = yes [print ["^-free desc-buf @ " desc-buf lf]]

		free desc-buf

		#if debug? = yes [print ["^-free attr-buf @ " attr-buf lf]]

		free attr-buf

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) environment
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values environment) + odbc/common-field-errors
		]]

		SET_RETURN(drivers)

		#if debug? = yes [print ["]" lf]]
	]


	;----------------------------------- list-sources --
	;

	list-sources: routine [
		environment     [object!]
		scope           [word!]
		return:         [value!]
		/local
			desc-buf    [byte-ptr!]
			desc-len    [integer!]
			desc-out    [integer!]
			direction   [integer!]
			henv        [red-handle!]
			init-dir    [subroutine!]
			rc          [integer!]
			sources     [red-block!]
			srvr-buf    [byte-ptr!]
			srvr-len    [integer!]
			srvr-out    [integer!]
			sym         [integer!]
	][
		#if debug? = yes [print ["LIST-SOURCES [" lf]]

		init-dir: [
			direction: case [
				sym = odbc/_user   [sql/fetch-first-user]
				sym = odbc/_system [sql/fetch-first-system]
				sym = odbc/_all    [sql/fetch-first]
			]
		]

		sym: symbol/resolve scope/symbol

		init-dir

		srvr-buf:       null
		srvr-len:       1000
		srvr-out:       0
		desc-buf:       null
		desc-len:       4000
		desc-out:       0

		henv: as red-handle! (object/get-values environment) + odbc/common-field-handle

		sources: block/push-only* 32

		until [
			if srvr-buf = null [
				srvr-buf: allocate srvr-len + 1 << 1

				#if debug? = yes [print ["^-allocate srvr-buf, " srvr-len + 1 << 1 " bytes @ " srvr-buf lf]]
			]
			if desc-buf = null [
				desc-buf: allocate desc-len + 1 << 1

				#if debug? = yes [print ["^-allocate desc-buf, " desc-len + 1 << 1 " bytes @ " desc-buf lf]]
			]

			ODBC_RESULT sql/SQLDataSources henv/value
										   direction
										   srvr-buf
										   srvr-len
										  :srvr-out
										   desc-buf
										   desc-len
										  :desc-out

			#if debug? = yes [print ["^-SQLDataSources " rc lf]]

			either all [ODBC_INFO any [
				srvr-len < srvr-out
				desc-len < desc-out
			]] [
				#if debug? = yes [print ["^-free srvr-buf @ " srvr-buf lf]]

				free srvr-buf
				srvr-buf: null
				srvr-len: srvr-out

				#if debug? = yes [print ["^-free desc-buf @ " desc-buf lf]]

				free desc-buf
				desc-buf: null
				desc-len: desc-out

				block/rs-clear sources                  ;-- try again with larger buffers
				init-dir                                ;

				continue
			][
				direction: sql/fetch-next
			]

			ODBC_DIAGNOSIS(sql/handle-env henv/value environment)

			if ODBC_SUCCEEDED [
				string/load-in as c-string! srvr-buf srvr-out sources UTF-16LE
				string/load-in as c-string! desc-buf desc-out sources UTF-16LE
			]

			any [ODBC_INVALID ODBC_NO_DATA ODBC_ERROR]
		]

		#if debug? = yes [print ["^-free srvr-buf @ " srvr-buf lf]]

		free srvr-buf

		#if debug? = yes [print ["^-free desc-buf @ " desc-buf lf]]

		free desc-buf

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) environment
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values environment) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]

		SET_RETURN(sources)
	]


	;-------------------------------- open-connection --
	;

	open-connection: routine [
		environment     [object!]
		connection      [object!]
		dsn             [string!]
		/local
			henv        [red-handle!]
			sqlhdbc     [integer!]
			rc          [integer!]
			seconds     [red-integer!]
			str         [c-string!]
			str-len     [integer!]
			timeout     [red-value!]
	][
		#if debug? = yes [print ["OPEN-CONNECTION [" lf]]

		henv:       as red-handle! (object/get-values environment) + odbc/common-field-handle
		timeout:                   (object/get-values environment) + odbc/env-field-login-timeout
		sqlhdbc:    0

		ODBC_RESULT sql/SQLAllocHandle sql/handle-dbc
									   henv/value
									  :sqlhdbc

		#if debug? = yes [print ["^-SQLAllocHandle " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-env henv/value environment)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) environment
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values environment) + odbc/common-field-errors
		]]

		copy-cell as red-value! handle/box sqlhdbc
				(object/get-values connection) + odbc/common-field-handle

		if TYPE_OF(timeout) = TYPE_INTEGER [
			seconds: as red-integer! timeout

			set-connection connection sql/attr-login-timeout
									  seconds/value
									  sql/is-integer
		]

		str:     unicode/to-utf16 dsn                   ;-- connect to driver
		str-len: odbc/wlength? str

		ODBC_RESULT sql/SQLDriverConnect sqlhdbc
										 null
										 as byte-ptr! str
										 str-len
										 null
										 0
										 null
										 sql/driver-noprompt

		#if debug? = yes [print ["^-SQLDriverConnect " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc sqlhdbc connection)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) connection
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values connection) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]

	;---------------------------------- pick-metadata --
	;   with common interfaces

	pick-attribute: routine [
		entity          [object!]
		info            [integer!]
	][
		pick-metadata entity info true
	]

	pick-information: routine [
		connection      [object!]
		info            [integer!]
	][
		pick-metadata connection info false
	]

	pick-metadata: routine [
		entity          [object!]
		info            [integer!]
		attribute?      [logic!]                        ;-- true = attr, false info (dbc only)
		/local
			buffer      [byte-ptr!]
			buflen      [integer!]
			htype       [integer!]
			hndl        [red-handle!]
			intptr      [int-ptr!]
			outlen      [integer!]
			rc          [integer!]
			sym         [integer!]
			type        [red-word!]
			value       [red-value!]
	][
	;#if debug? = yes [print ["PICK-METADATA [" lf]]

		intptr: declare int-ptr!

		hndl:   as red-handle! (object/get-values entity) + odbc/common-field-handle

		type:   as red-word!   (object/get-values entity) + odbc/common-field-type
		sym:    symbol/resolve type/symbol

		buflen: 2000
		outlen:    0

		loop 2 [
			buffer: allocate buflen + 1

			case [
				sym = odbc/_environment [
					ODBC_RESULT sql/SQLGetEnvAttr hndl/value
												  info
												  buffer
												  buflen
												 :outlen

				;#if debug? = yes [print ["^-SQLGetEnvAttr(" info ") " rc lf]]
				]
				all [
					sym = odbc/_connection
					attribute?
				][
					ODBC_RESULT sql/SQLGetConnectAttr hndl/value
													  info
													  buffer
													  buflen
													 :outlen

				;#if debug? = yes [print ["^-SQLGetConnectAttr(" info ") " rc lf]]
				]
				all [
					sym = odbc/_connection
					not attribute?
				][
					ODBC_RESULT sql/SQLGetInfo hndl/value
											   info
											   buffer
											   buflen
											  :outlen

				;#if debug? = yes [print ["^-SQLGetInfo(" info ") " rc lf]]
				]
				sym = odbc/_statement [
					ODBC_RESULT sql/SQLGetStmtAttr hndl/value
												   info
												   buffer
												   buflen
												  :outlen

				;#if debug? = yes [print ["^-SQLGetStmtAttr(" info ") " rc lf]]
				]
			]

			either any [
				rc <> sql/success-with-info
				outlen <= buflen
			][
				break                                   ;-- buffer was large enough
			][
				free buffer                             ;-- try again with bigger buffer
				buflen: outlen
			]
		]

		htype: case [
			sym = odbc/_environment [sql/handle-env ]
			sym = odbc/_connection  [sql/handle-dbc ]
			sym = odbc/_statement   [sql/handle-stmt]
		]

		ODBC_DIAGNOSIS(htype hndl/value entity)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) entity
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values entity) + odbc/common-field-errors
		]]

		either attribute? [
			intptr: as int-ptr! buffer
			SET_RETURN((integer/box intptr/value))
		][
			either any [
				;-- connections
				;
				info = sql/accessible-procedures        ;-- all these return strings
				info = sql/accessible-tables            ;
				info = sql/catalog-name
				info = sql/catalog-name-separator
				info = sql/catalog-term
				info = sql/collation-seq
				info = sql/column-alias
				info = sql/data-source-name
				info = sql/data-source-read-only
			;   info = sql/database-name                ;-- fixme: = sql-catalog-name ?!
				info = sql/dbms-name
				info = sql/dbms-ver
				info = sql/describe-parameter
				info = sql/dm-ver
				info = sql/driver-name
				info = sql/driver-odbc-ver
				info = sql/driver-ver
				info = sql/expressions-in-orderby
				info = sql/integrity
				info = sql/keywords
				info = sql/like-escape-clause
				info = sql/max-row-size-includes-long
				info = sql/mult-result-sets
				info = sql/multiple-active-txn
				info = sql/need-long-data-len
				info = sql/odbc-ver
				info = sql/order-by-columns-in-select
				info = sql/procedure-term
				info = sql/procedures
				info = sql/row-updates
				info = sql/schema-term
				info = sql/search-pattern-escape
				info = sql/server-name
				info = sql/special-characters
				info = sql/table-term
				info = sql/user-name
				info = sql/xopen-cli-year
			][
				SET_RETURN((string/load as c-string! buffer outlen UTF-8))
			][
				intptr: as int-ptr! buffer
				SET_RETURN((integer/box intptr/value))
			]
		]

		free buffer

	;#if debug? = yes [print ["]" lf]]
	]


	;-------------------------------- end-transaction --
	;

	end-transaction: routine [
		connection      [object!]
		commit?         [logic!]
		/local
			hdbc        [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["END-TRANSACTION [" lf]]

		hdbc: as red-handle! (object/get-values connection) + odbc/common-field-handle

		ODBC_RESULT sql/SQLEndTran sql/handle-dbc
								   hdbc/value
								   either commit? [0] [1] ;SQL_COMMIT/ROLLBACK

		#if debug? = yes [print ["^-SQLEndTran " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) connection
		]]
		if any [ODBC_ERROR ODBC_EXECUTING] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values connection) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;--------------------------------- open-statement --
	;

	open-statement: routine [
		connection      [object!]
		statement       [object!]
		/local
			fetched     [byte-ptr!]
			hdbc        [red-handle!]
			rc          [integer!]
			sqlhstmt    [integer!]
	][
		#if debug? = yes [print ["OPEN-STATEMENT [" lf]]

		hdbc:       as red-handle! (object/get-values connection) + odbc/common-field-handle
		sqlhstmt:   0

		ODBC_RESULT sql/SQLAllocHandle sql/handle-stmt
									   hdbc/value
									  :sqlhstmt

		#if debug? = yes [print ["^-SQLAllocHandle " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) connection
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values connection) + odbc/common-field-errors
		]]

		copy-cell as red-value! handle/box
				  sqlhstmt
				  (object/get-values statement) + odbc/common-field-handle

		fetched: allocate size? integer!

		#if debug? = yes [print ["^-allocate fetched, " size? integer! " bytes @ " fetched lf]]

		copy-cell as red-value! handle/box as integer! fetched
				(object/get-values statement) + odbc/stmt-field-rows-fetched

		#if debug? = yes [print ["]" lf]]
	]


	;---------------------------- translate-statement --
	;

	translate-statement: routine [
		connection      [object!]
		sqlstr          [string!]
		/local
			buffer      [byte-ptr!]
			buflen      [integer!]
			hdbc        [red-handle!]
			outlen      [integer!]
			rc          [integer!]
			cstr        [c-string!]
	][
		#if debug? = yes [print ["TRANSLATE-STATEMENT [" lf]]

		buffer:     null
		buflen:     2047
		hdbc:       as red-handle! (object/get-values connection) + odbc/common-field-handle
		outlen:     0
		cstr:       unicode/to-utf16 sqlstr             ;-- null terminated utf16

		loop 2 [
			buffer: allocate buflen + 1 << 1

			#if debug? = yes [print ["^-allocate buffer, " buflen + 1 << 1 " bytes @ " buffer lf]]

			ODBC_RESULT sql/SQLNativeSql hdbc/value
										 cstr
										 sql/nts
										 buffer
										 buflen
										:outlen

			#if debug? = yes [print ["^-SQLNativeSql " rc lf]]

			either any [
				rc <> sql/success-with-info
				outlen <= buflen
			][
				break                                   ;-- buffer was large enough
			][
				#if debug? = yes [print ["^-free buffer @ " buffer lf]]

				free buffer                             ;-- try again with bigger buffer
				buflen: outlen
			]
		]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		if ODBC_SUCCEEDED [
			SET_RETURN((string/load as c-string! buffer odbc/wlength? as c-string! buffer UTF-16LE))
		]

		#if debug? = yes [print ["^-free buffer @ " buffer lf]]

		free buffer

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) connection
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values connection) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;--------------------------------- set-connection --
	;

	set-connection: routine [
		connection      [object!]
		attribute       [integer!]
		value           [integer!]
		type            [integer!]
		/local
			hdbc        [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["SET-CONNECTION [" lf]]

		hdbc: as red-handle! (object/get-values connection) + odbc/common-field-handle

		ODBC_RESULT sql/SQLSetConnectAttr hdbc/value
										  attribute
										  value
										  type

		#if debug? = yes [print ["^-SQLSetConnectAttr " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) connection
		]]
		if any [ODBC_ERROR ODBC_EXECUTING] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values connection) + odbc/common-field-errors
		]]

		SET_RETURN(none-value)

		#if debug? = yes [print ["]" lf]]
	]


	;---------------------------------- set-statement --
	;

	set-statement: routine [
		statement       [object!]
		attribute       [integer!]
		value           [integer!]
		type            [integer!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["SET-STATEMENT [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		ODBC_RESULT sql/SQLSetStmtAttr hstmt/value
									   attribute
									   value
									   type

		#if debug? = yes [print ["^-SQLSetStmtAttr " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) statement
		]]
		if any [ODBC_ERROR ODBC_NEED_DATA ODBC_EXECUTING] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;------------------------------------- set-cursor --
	;

	set-cursor: routine [
		statement       [object!]
		index           [integer!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["SET-CURSOR [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		ODBC_RESULT sql/SQLSetPos hstmt/value
								  index
								  sql/position
								  sql/lock-no-change

		#if debug? = yes [print ["^-SQLSetPos " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) statement]
		]
		if any [ODBC_ERROR ODBC_NEED_DATA ODBC_EXECUTING] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;------------------------------ prepare-statement --
	;

	prepare-statement: routine [
		statement       [object!]
		params          [block!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
			sqlstr      [c-string!]
	][
		#if debug? = yes [print ["PREPARE-STATEMENT [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		sqlstr: unicode/to-utf16 as red-string! block/rs-head params

		ODBC_RESULT sql/SQLPrepare hstmt/value
								   sqlstr
								   odbc/wlength? sqlstr

		#if debug? = yes [print ["^-SQLPrepare " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) statement
		]]
		if any [ODBC_ERROR ODBC_EXECUTING] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;-------------------------------- free-parameters --
	;

	free-parameters: routine [
		statement       [object!]
		/local
			buffer      [red-handle!]
			prm         [integer!]
			prms        [integer!]
			params      [red-block!]
	][
		#if debug? = yes [print ["FREE-PARAMETERS [" lf]]

		params: as red-block! (object/get-values statement) + odbc/stmt-field-params
		prms:   block/rs-length? params

		prm: 0
		loop prms [
			buffer: as red-handle! block/rs-abs-at params prm
														;-- NOTE: buffers come in param'n'strlen buffer pairs here
			free as byte-ptr! buffer/value
			prm: prm + 1
		]

		block/rs-clear params

		#if debug? = yes [print ["]" lf]]
	]


	;-------------------------------- bind-parameters --
	;

	bind-parameters: routine [
		statement       [object!]
		params          [block!]
		/local
			buffer      [byte-ptr!]
			bufslot     [byte-ptr!]
			buffers     [red-block!]
			buflen      [integer!]
			hstmt       [red-handle!]
			c-string    [c-string!]
			c-type      [integer!]
			column-size [integer!]
			digits      [integer!]
			lenbuf      [int-ptr!]
			lenslot     [int-ptr!]
			maxlen      [integer!]
			param       [red-value!]
			prm         [integer!]
			prms        [integer!]
			rc          [integer!]
			red-binary  [red-binary!]
			red-date    [red-date!]
			red-float   [red-float!]
			red-integer [red-integer!]
			red-logic   [red-logic!]
			red-string  [red-string!]
			red-time    [red-time!]
			row         [integer!]
			rows        [integer!]
			size        [integer!]
			series      [series!]
			sql-type    [integer!]
			status      [red-handle!]
			strlen      [integer!]
			total       [integer!]
			dt          [sql-date!]
			tm          [sql-time!]
			ts          [sql-timestamp!]
			val-float   [float!]
			val-integer [integer!]
			value       [red-value!]
			values      [red-value!]
	][
		#if debug? = yes [print ["BIND-PARAMETERS [" lf]]

		values:     object/get-values statement

		hstmt:      as red-handle! values + odbc/common-field-handle

		rows: block/rs-length? params
		prms: block/rs-length? as red-block! block/rs-head params

		#if debug? = yes [print ["^-" rows " rows of " prms " params" lf]]

		status:    handle/box as integer! allocate rows * size? integer!

		#if debug? = yes [print ["^-allocate status/value, " rows * size? integer! " bytes @ " as byte-ptr! status/value lf]]

		copy-cell as red-value! status values + odbc/stmt-field-prms-status     ;-- store pointer in statement

		set-statement statement sql/attr-paramset-size    rows         0
		set-statement statement sql/attr-param-status-ptr status/value 0

		buffers: as red-block! values + odbc/stmt-field-params

		prm: 1
		loop prms [
			#if debug? = yes [print ["^-prm " prm lf]]

			;-- determine buflen
			;

			maxlen: 0
			row: 1
			loop rows [
				#if debug? = yes [print ["^-^-buflen? row " row "/" rows lf]]

				value: block/rs-abs-at params row       ;-- NOTE: correct, because rows - 1 is the SQL string itself
				param: block/rs-abs-at as red-block! value prm - 1

				#if debug? = yes [print ["^-^-TYPE_OF(" TYPE_OF(param) ")" lf]]

				case [
					any [
						TYPE_OF(param) = TYPE_STRING
						TYPE_OF(param) = TYPE_FILE
						TYPE_OF(param) = TYPE_URL
						TYPE_OF(param) = TYPE_TAG
						TYPE_OF(param) = TYPE_EMAIL
						TYPE_OF(param) = TYPE_REF
					][
						buflen: (odbc/wlength? unicode/to-utf16 as red-string! param) + 1 << 1
						#if debug? = yes [print ["^-^-^-buflen = " buflen lf]]
						if maxlen < buflen [maxlen: buflen]
					]
					TYPE_OF(param) = TYPE_BINARY [
						buflen: binary/rs-length? as red-binary! param
						if maxlen < buflen [maxlen: buflen]
					]
					TYPE_OF(param) = TYPE_INTEGER [
						maxlen: 4
						break
					]
					TYPE_OF(param) = TYPE_FLOAT [
						maxlen: 4
						break
					]
					TYPE_OF(param) = TYPE_LOGIC [
						maxlen: 1
						break
					]
					TYPE_OF(param) = TYPE_TIME [
						maxlen: 6                       ;-- FIXME: size? sql-time!
						break
					]
					TYPE_OF(param) = TYPE_DATE [
						red-date: as red-date! param
						maxlen: either as-logic red-date/date >> 16 and 01h [16] [6] ;-- NOTE: This is safe, because calling INSERT actor asserts values of same type
						break
					]
					true [
						maxlen: maxlen or 1
					]
				]

				row: row + 1
			]
			buflen: maxlen

			#if debug? = yes [print ["^-^-^-buflen = " buflen lf]]

			;-- create buffer
			;

			total:   rows * buflen
			buffer:  allocate total
			bufslot: buffer
			handle/make-in buffers as integer! buffer

			#if debug? = yes [print ["^-allocate buffer, " rows * buflen " bytes @ " buffer lf]]

			lenbuf:  as int-ptr! allocate rows * size? integer!
			lenslot: lenbuf
			handle/make-in buffers as integer! lenbuf

			#if debug? = yes [print ["^-allocate lenbuf, " rows * size? integer! " bytes @ " lenbuf lf]]

			;-- populate buffer array
			;

			sql-type:   sql/bit                         ;-- default in case all rows are #[none]
			c-type:     sql/c-bit                       ;
			digits:     0

			row: 1
			loop rows [
				#if debug? = yes [print ["^-^-populate row " row "/" rows lf]]

				value: block/rs-abs-at params row       ;-- NOTE: correct, because rows - 1 is the SQL string itself
				param: block/rs-abs-at as red-block! value prm - 1

				#if debug? = yes [print ["^-^-TYPE_OF(" TYPE_OF(param) ")" lf]]

				lenslot/value: 0

				switch TYPE_OF(param) [
					TYPE_INTEGER [
						#if debug? = yes [print ["^-^-^-TYPE_INTEGER buflen = " buflen lf]]

						column-size:        4
						sql-type:           sql/integer
						c-type:             sql/c-long
						red-integer:        as red-integer! param
						val-integer:        red-integer/value

						copy-memory bufslot as byte-ptr! :val-integer column-size

						#if debug? = yes [odbc/print-buffer bufslot column-size]

						bufslot:            bufslot + column-size
						lenslot/value:      column-size
					]
					TYPE_FLOAT [
						column-size:        8
						sql-type:           sql/double
						c-type:             sql/c-double
						red-float:          as red-float! param
						val-float:          red-float/value

						copy-memory bufslot as byte-ptr! :val-float column-size

						#if debug? = yes [odbc/print-buffer bufslot column-size]

						bufslot:            bufslot + column-size
						lenslot/value:      column-size
					]
					TYPE_ANY_STRING [
						#if debug? = yes [print ["^-^-^-TYPE_STRING buflen = " buflen lf]]

						column-size:        buflen
						sql-type:           sql/wvarchar
						c-type:             sql/c-wchar
						red-string:         as red-string! param
						c-string:           unicode/to-utf16 red-string
						strlen:             odbc/wlength? c-string
						lenslot/value:      strlen << 1 ;-- actual octet length w/o null-terminator

						copy-memory bufslot as byte-ptr! c-string strlen + 1 << 1

						bufslot:            bufslot + column-size

						#if debug? = yes [odbc/print-buffer buffer total]
					]
					TYPE_BINARY [
						#if debug? = yes [print ["^-^-^-TYPE_BINARY buflen = " buflen lf]]

						column-size:        buflen
						sql-type:           sql/varbinary
						c-type:             sql/c-binary
						red-binary:         as red-binary! param
						lenslot/value:      binary/rs-length? red-binary
						series:             GET_BUFFER(red-binary)

						copy-memory bufslot as byte-ptr! series/offset buflen

						bufslot:            bufslot + buflen

						#if debug? = yes [odbc/print-buffer buffer total]
					]
					TYPE_LOGIC [
						#if debug? = yes [print ["^-^-^-TYPE_LOGIC buflen = " buflen lf]]

						column-size:        1
						digits:             1
						sql-type:           sql/bit
						c-type:             sql/c-bit
						red-logic:          as red-logic! param
						bufslot/value:      as byte! red-logic/value
						bufslot:            bufslot + buflen
						lenslot/value:      1

						#if debug? = yes [odbc/print-buffer buffer total]
					]
					TYPE_DATE [
						#if debug? = yes [print ["^-^-^-TYPE_DATE buflen = " buflen lf]]

						red-date: as red-date! param
						either as-logic red-date/date >> 16 and 01h [           ;-- NOTE: This is safe, INSERT actor asserts values of same type
							column-size:    27                                  ;-- yyyy-mm-dd hh:mm:ss.fffffff
							digits:         7
							sql-type:       sql/type-timestamp
							c-type:         sql/c-type-timestamp
							lenslot/value:  0
							ts:             as sql-timestamp! bufslot
							ts/year|month:  red-date/date >> 17 or              ;-- year
										   (red-date/date >> 12 and 0Fh << 16)  ;-- month
							ts/day|hour:    red-date/date >>  7 and 1Fh         ;-- day
									   or ((as integer! floor       red-date/time         / 3600.0) << 16)
							ts/minute|second:
										   (as integer! floor (fmod red-date/time 3600.0) /   60.0)
									   or ((as integer!        fmod red-date/time   60.0)           << 16)
						][
							column-size:   10                                   ;-- yyyy-mm-dd
							digits:         0
							sql-type:       sql/type-date
							c-type:         sql/c-type-date
							dt:             as sql-date! bufslot
							dt/year|month:  red-date/date >> 17 or              ;-- year
										   (red-date/date >> 12 and 0Fh << 16)  ;-- month
						;   dt/day|pad:     red-date/date >>  7 and 1Fh
							val-integer:    red-date/date >>  7 and 1Fh
							dt/daylo:       as byte! val-integer
							dt/dayhi:       as byte! 0
						]
						bufslot:            bufslot + buflen
					]
					TYPE_TIME [
						#if debug? = yes [print ["^-^-^-TYPE_TIME = " buflen lf]]

						column-size:        8                                   ;-- hh:mm:ss
						sql-type:           sql/type-time
						c-type:             sql/c-type-time
						red-time:           as red-time! param

						tm:                 as sql-time! bufslot
						tm/hour|minute:    (as integer! floor       red-time/time         / 3600.0)
									   or ((as integer! floor (fmod red-time/time 3600.0) /   60.0) << 16)
					;   tm/second|pad:      as integer!        fmod red-time/time   60.0
						val-integer:        as integer!        fmod red-time/time   60.0
						tm/seclo:           as byte! val-integer
						tm/sechi:           as byte! 0

						bufslot:            bufslot + buflen
					]
					TYPE_NONE [
						#if debug? = yes [print ["^-^-^-TYPE_NONE buflen = " buflen lf]]

						bufslot:            bufslot + buflen
						lenslot/value:      sql/null-data
					]
					default [
						#if debug? = yes [print ["^-^-^-default buflen = " buflen lf]]
						bufslot:            bufslot  + buflen
						c-type:             sql/c-default

						lenslot/value:      sql/null-data
					]
				]
				lenslot: lenslot + 1
				row:     row     + 1
			]

			;-- bind param
			;

			#if debug? = yes [print ["^-prm    "   prm      lf]]
			#if debug? = yes [print ["^-C-type "   c-type   lf]]
			#if debug? = yes [print ["^-SQL-type " sql-type lf]]
			#if debug? = yes [print ["^-col-size " column-size lf]]
			#if debug? = yes [print ["^-digits "   digits   lf]]
			#if debug? = yes [print ["^-buffer "   buffer   lf]]
			#if debug? = yes [print ["^-buflen "   buflen   lf]]
			#if debug? = yes [print ["^-lenbuf "   lenbuf   lf]]

			if zero? buflen [buffer: null]

			ODBC_RESULT sql/SQLBindParameter hstmt/value
											 prm        ;-- 1-indexed
											 sql/param-input
											 c-type
											 sql-type
											 column-size
											 digits
											 buffer
											 buflen
											 lenbuf

			#if debug? = yes [print ["^-SQLBindParameter " rc lf]]

			ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

			if ODBC_INVALID [fire [
				TO_ERROR(script invalid-arg) statement
			]]
			if ODBC_ERROR [fire [
				TO_ERROR(script bad-bad) odbc/odbc
				as red-block! (object/get-values statement) + odbc/common-field-errors
			]]

			prm: prm + 1
		]

		#if debug? = yes [print ["]" lf]]
	]


	;------------------------------ catalog-statement --
	;

	catalog-statement: routine [
		statement       [object!]
		dialect         [block!]
		strict          [logic!]
		/local
			bol         [integer!]
			hstmt       [red-handle!]
			nullable    [integer!]
			nulls       [red-logic!]
			rc          [integer!]
			reserved    [integer!]
			s1 s2 s3
			s4 s5 s6 s7 [c-string!]
			scope       [integer!]
			sctype      [integer!]
			sym         [integer!]
			uniq        [integer!]
			v1 v2 v3
			v4 v5 v6 v7 [red-value!]
			value       [red-value!]
			word        [red-word!]

	][
		#if debug? = yes [print ["CATALOG-STATEMENT [" lf]]

		s1: null s2: null s3: null s4: null s5: null s6: null s7: null

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		if strict [                                         ;-- NOTE: for data sources that don't
			set-statement statement sql/attr-metadata-id    ;   treated as identifier
									sql/true
									sql/is-integer
		]

		word: as red-word! block/rs-abs-at dialect 0
		sym:  symbol/resolve word/symbol

		value: block/rs-abs-at dialect 1
		if TYPE_OF(value) = TYPE_WORD [
			word: as red-word! value
			bol:  symbol/resolve word/symbol
		]

		v1: block/rs-abs-at dialect 1
		v2: block/rs-abs-at dialect 2
		v3: block/rs-abs-at dialect 3
		v4: block/rs-abs-at dialect 4
		v5: block/rs-abs-at dialect 5
		v6: block/rs-abs-at dialect 6
		v7: block/rs-abs-at dialect 7

		if TYPE_OF(v1) = TYPE_STRING [s1: unicode/to-utf16 as red-string! v1]
		if TYPE_OF(v2) = TYPE_STRING [s2: unicode/to-utf16 as red-string! v2]
		if TYPE_OF(v3) = TYPE_STRING [s3: unicode/to-utf16 as red-string! v3]
		if TYPE_OF(v4) = TYPE_STRING [s4: unicode/to-utf16 as red-string! v4]
		if TYPE_OF(v5) = TYPE_STRING [s5: unicode/to-utf16 as red-string! v5]
		if TYPE_OF(v6) = TYPE_STRING [s6: unicode/to-utf16 as red-string! v6]
		if TYPE_OF(v7) = TYPE_STRING [s7: unicode/to-utf16 as red-string! v7]

		case [
			all [
				sym = odbc/_column
				bol = odbc/_privileges
			][
				ODBC_RESULT sql/SQLColumnPrivileges hstmt/value s2 sql/nts s3 sql/nts s4 sql/nts s5 sql/nts

				#if debug? = yes [print ["^-SQLColumnPrivileges " rc lf]]
			]
			all [
				sym = odbc/_columns
			][
				ODBC_RESULT sql/SQLColumns hstmt/value s1 sql/nts s2 sql/nts s3 sql/nts s4 sql/nts

				#if debug? = yes [print ["^-SQLColumns " rc lf]]
			]
			all [
				sym = odbc/_foreign
				bol = odbc/_keys
			][
				ODBC_RESULT sql/SQLForeignKeys hstmt/value s2 sql/nts s3 sql/nts s4 sql/nts s5 sql/nts s6 sql/nts s7 sql/nts

				#if debug? = yes [print ["^-SQLForeignKeys " rc lf]]
			]
			all [
				sym = odbc/_primary
				bol = odbc/_keys
			][
				ODBC_RESULT sql/SQLPrimaryKeys hstmt/value s2 sql/nts s3 sql/nts s4 sql/nts

				#if debug? = yes [print ["^-SQLPrimaryKeys " rc lf]]
			]
			all [
				sym = odbc/_procedure
				bol = odbc/_columns
			][
				ODBC_RESULT sql/SQLProcedureColumns hstmt/value s2 sql/nts s3 sql/nts s4 sql/nts s5 sql/nts

				#if debug? = yes [print ["^-SQLProcedureColumns " rc lf]]
			]
			all [
				sym = odbc/_procedures
			][
				ODBC_RESULT sql/SQLProcedures hstmt/value s1 sql/nts s2 sql/nts s3 sql/nts

				#if debug? = yes [print ["^-SQLProcedures " rc lf]]
			]
			all [
				sym = odbc/_special
				bol = odbc/_columns
			][
				sctype: sql/best-rowid                  ;-- default

				if TYPE_OF(v2) = TYPE_WORD [
					word: as red-word! v2
					sym:  symbol/resolve word/symbol

					sctype: case [
						sym = odbc/_unique      [sql/best-rowid]
						sym = odbc/_update      [sql/rowver]
				]   ]

				scope: sql/scope-currow                 ;-- default

				if TYPE_OF(v6) = TYPE_WORD [
					word: as red-word! v6
					sym:  symbol/resolve word/symbol

					scope: case [
						sym = odbc/_row         [sql/scope-currow]
						sym = odbc/_transaction [sql/scope-transaction]
						sym = odbc/_session     [sql/scope-session]
				]   ]

				nullable: sql/no-nulls                  ;-- default

				if TYPE_OF(v7) = TYPE_LOGIC [
					nulls: as red-logic! v7
					nullable: case [
						nulls/value             [sql/nullable]
				]   ]

				ODBC_RESULT sql/SQLSpecialColumns hstmt/value sctype s3 sql/nts s4 sql/nts s5 sql/nts scope nullable

				#if debug? = yes [print ["^-SQLSpecialColumns " rc lf]]
			]
			all [
				sym = odbc/_statistics
			][
				uniq:     sql/index-all                 ;-- default
				reserved: 0

				if TYPE_OF(v4) = TYPE_WORD [
					word: as red-word! v4
					sym:  symbol/resolve word/symbol
					uniq: case [
						sym = odbc/_all         [sql/index-all]
						sym = odbc/_unique      [sql/index-unique]
				]   ]

				ODBC_RESULT sql/SQLStatistics hstmt/value s1 sql/nts s2 sql/nts s3 sql/nts uniq reserved
														;-- FIXME: SQL_QUICK vs. SQL_ENSURE not supported!
				#if debug? = yes [print ["^-SQLStatistics " rc lf]]
			]
			all [
				sym = odbc/_table
				bol = odbc/_privileges
			][
				ODBC_RESULT sql/SQLTablePrivileges hstmt/value s2 sql/nts s3 sql/nts s4 sql/nts

				#if debug? = yes [print ["^-SQLTablePrivileges " rc lf]]
			]
			all [
				sym = odbc/_tables
			][
				ODBC_RESULT sql/SQLTables hstmt/value s1 sql/nts s2 sql/nts s3 sql/nts s4 sql/nts

				#if debug? = yes [print ["^-SQLTables " rc lf]]
			]
			all [
				sym = odbc/_types
			][
				ODBC_RESULT sql/SQLGetTypeInfo hstmt/value sql/all-types

				#if debug? = yes [print ["^-SQLGetTypeInfo " rc lf]]
			]
		]

		if strict [
			set-statement statement sql/attr-metadata-id
									sql/false
									sql/is-integer
		]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		if ODBC_INVALID [fire [
			TO_ERROR(script invalid-arg) statement
		]]
		if ODBC_ERROR [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" rc lf]]
	]


	;------------------------------ execute-statement --
	;

	execute-statement: routine [
		statement       [object!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["EXECUTE-STATEMENT [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		ODBC_RESULT sql/SQLExecute hstmt/value

		#if debug? = yes [print ["^-SQLExecute " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		unless ODBC_SUCCEEDED [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]
	]


	;---------------------------------- affected-rows --
	;

	affected-rows: routine [
		statement       [object!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
			rows        [red-integer!]
	][
		#if debug? = yes [print ["AFFECTED-ROWS [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle
		rows:  integer/box 0

		ODBC_RESULT sql/SQLRowCount hstmt/value
								   :rows/value

		#if debug? = yes [print ["^-SQLRowCount " rows/value ": " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		unless ODBC_SUCCEEDED [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		#if debug? = yes [print ["]" lf]]

		SET_RETURN(rows)
	]


	;---------------------------------- more-results? --
	;

	more-results?: routine [
		statement       [object!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["MORE-RESULTS? [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		ODBC_RESULT sql/SQLMoreResults hstmt/value

		#if debug? = yes [print ["^-SQLMoreResults " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		unless any [ODBC_NO_DATA ODBC_SUCCESS ODBC_INFO] [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		SET_RETURN((either ODBC_SUCCEEDED [true-value] [none-value]))

		#if debug? = yes [print ["]" lf]]
	]


	;---------------------------------- count-columns --
	;

	count-columns: routine [
		statement       [object!]
		/local
			cols        [integer!]
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["COUNT-COLUMNS [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle
		cols:  0

		ODBC_RESULT sql/SQLNumResultCols hstmt/value :cols

		#if debug? = yes [print ["^-SQLNumResultCols " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		unless ODBC_SUCCEEDED [fire [
			TO_ERROR(script bad-bad) odbc/odbc
			as red-block! (object/get-values statement) + odbc/common-field-errors
		]]

		SET_RETURN((integer/box cols))

		#if debug? = yes [print ["]" lf]]
	]


	;----------------------------------- free-columns --
	;

	free-columns: routine [
		statement       [object!]
		/local
			buffer      [red-handle!]
			cols        [integer!]
			columns     [red-block!]
			num         [integer!]
			offset      [integer!]
			strlen      [red-handle!]
	][
		#if debug? = yes [print ["FREE-COLUMNS [" lf]]

		columns: as red-block! (object/get-values statement) + odbc/stmt-field-columns
		cols:    (block/rs-length? columns) / odbc/col-field-fields

		num: 0
		while [num < cols] [
			offset: num * odbc/col-field-fields

			buffer: as red-handle! block/rs-abs-at columns offset + odbc/col-field-buffer
			strlen: as red-handle! block/rs-abs-at columns offset + odbc/col-field-strlen-ind

			free as byte-ptr! buffer/value
			free as byte-ptr! strlen/value

			buffer/value: 0
			strlen/value: 0

			num: num + 1
		]

		block/rs-clear columns

		#if debug? = yes [print ["]" lf]]
	]


	;----------------------------------- bind-columns --
	;

	bind-columns: routine [                             ;-- FIXME: needs code cleaning
		statement       [object!]
		cols            [integer!]
		/local
			buffer      [byte-ptr!]
			buflen      [integer!]
			c-type      [integer!]
			col         [integer!]
			col-size    [integer!]
			columns     [red-block!]
			digits      [integer!]
			fetched     [red-handle!]
			hstmt       [red-handle!]
			name        [c-string!]
			name-buflen [integer!]
			name-len    [integer!]
			nullable    [integer!]
			rc          [integer!]
			sql-type    [integer!]
			status      [red-handle!]
			strlen      [int-ptr!]
			title       [red-string!]
			value       [red-value!]
			values      [red-value!]
			window      [integer!]
	][
		#if debug? = yes [print ["BIND-COLUMNS [" lf]]

		name-len:       0
		digits:         0
		nullable:       0
		sql-type:       0

		;-- determining statement attributes --
		;

		values: object/get-values statement

		hstmt:    as red-handle! values + odbc/common-field-handle

		fetched:  as red-handle! values + odbc/stmt-field-rows-fetched          ;-- number of rows fetched
		window:     integer/get (values + odbc/stmt-field-window)               ;-- window size (num of rows to recieve)
		value:                   values + odbc/stmt-field-rows-status

		if TYPE_OF(value) = TYPE_HANDLE [
			status: as red-handle! value

			#if debug? = yes [print ["^-free status/value @ " as byte-ptr! status/value lf]]

			free as byte-ptr! status/value
		]

		status: handle/box as integer! allocate window * size? integer!

		#if debug? = yes [print ["^-allocate status/value, " window * size? integer! " bytes @ " as byte-ptr! status/value lf]]

		copy-cell as red-value! status values + odbc/stmt-field-rows-status     ;-- store pointer in statement

		;-- setting statement attributes --
		;

		set-statement statement sql/attr-row-bind-type    sql/bind-by-column    0
		set-statement statement sql/attr-row-array-size   window                0
		set-statement statement sql/attr-rows-fetched-ptr fetched/value         0

		;-- describe & bind columns --
		;

		name-buflen: 256                                ;-- FIXME: why 256 ?!
		name:        make-c-string name-buflen          ;

		#if debug? = yes [print ["^-allocate name, " name-buflen " bytes @ " as byte-ptr! name lf]]

		columns:        block/push-only* cols * odbc/col-field-fields
		col-size:       0
		col:            1
		buffer:         null

		while [col <= cols] [

			;-- describe --
			;

			ODBC_RESULT sql/SQLDescribeCol hstmt/value
										   col
										   name
										   name-buflen
										  :name-len
										  :sql-type
										  :col-size
										  :digits
										  :nullable

			#if debug? = yes [print ["^-SQLDescribeCol " rc lf]]

			ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

			unless ODBC_SUCCEEDED [fire [
				TO_ERROR(script bad-bad) odbc/odbc
				as red-block! (object/get-values statement) + odbc/common-field-errors
			]]

			#if debug? = yes [print ["^-sql-type = " sql-type ", col-size = " col-size lf]]

			case [
				any [
					sql-type = sql/wchar
					sql-type = sql/wvarchar
					sql-type = sql/wlongvarchar
				][
					c-type: sql/c-wchar
					buflen: col-size + 1 << 1
				]
				any [
					sql-type = sql/char
					sql-type = sql/varchar
					sql-type = sql/longvarchar
				][
					c-type: sql/c-char
					buflen: col-size + 1
				]
				any [
					sql-type = sql/decimal
					sql-type = sql/numeric
				][
					c-type: sql/c-char
					buflen: col-size + 1
				]
				any [
					sql-type = sql/smallint
					sql-type = sql/integer
				][
					c-type: sql/c-long
					buflen: size? integer!
				]
				any [
					sql-type = sql/real
					sql-type = sql/float
					sql-type = sql/double
				][
					c-type: sql/c-double
					buflen: size? float!
				]
				sql-type = sql/bit [
					c-type: sql/c-bit
					buflen: 1
				]
				sql-type = sql/tinyint [
					c-type: sql/c-long
					buflen: size? integer!
				]
				sql-type = sql/type-date [
					c-type: sql/c-type-date
					buflen: 6                           ;-- FIXME: size? sql-date!
				]
				sql-type = sql/type-time [
					c-type: sql/c-type-time
					buflen: 6                           ;-- FIXME: size? sql-time!
				]
				sql-type = sql/type-timestamp [
					c-type: sql/c-type-timestamp
					buflen: size? sql-timestamp!
				]
				sql-type = sql/guid [
					c-type: sql/c-char
					buflen: col-size + 1
				]
				any [
					sql-type = sql/interval-year
					sql-type = sql/interval-year-to-month
					sql-type = sql/interval-month
					sql-type = sql/interval-day
					sql-type = sql/interval-hour
					sql-type = sql/interval-minute
					sql-type = sql/interval-second
					sql-type = sql/interval-day-to-hour
					sql-type = sql/interval-day-to-minute
					sql-type = sql/interval-day-to-second
					sql-type = sql/interval-hour-to-minute
					sql-type = sql/interval-hour-to-second
					sql-type = sql/interval-minute-to-second
				][
					sql/c-char
				]
				sql-type = sql/bigint [
					c-type: sql/c-char
					buflen: col-size + 1
				]
				any [
					sql-type = sql/longvarbinary
					sql-type = sql/varbinary
					sql-type = sql/binary
				][
					c-type: sql/c-char
					buflen: col-size
				]
				true [
					c-type: sql/c-wchar
					buflen: col-size + 1
				]
			]

			buffer: allocate window * buflen

			#if debug? = yes [print ["^-allocate buffer, " window * buflen " bytes @ " buffer "..." buffer + (window * buflen) - 1 lf]]

			strlen: as int-ptr! allocate window * size? integer!

			#if debug? = yes [print ["^-allocate strlen, " window * size? integer! " bytes @ " strlen lf]]

			title: string/load-in name name-len columns UTF-16LE
			title/header: title/header or flag-new-line

			integer/make-in columns             sql-type
			integer/make-in columns             col-size
			integer/make-in columns             digits
			integer/make-in columns             nullable
			 handle/make-in columns as integer! buffer
			integer/make-in columns             buflen
			 handle/make-in columns as integer! strlen

			;-- bind --
			;

			ODBC_RESULT sql/SQLBindCol hstmt/value
									   col
									   c-type
									   buffer
									   buflen
									   strlen

			#if debug? = yes [print ["^-SQLBindCol " rc lf]]

			ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

			unless ODBC_SUCCEEDED [fire [
				TO_ERROR(script bad-bad) odbc/odbc
				as red-block! (object/get-values statement) + odbc/common-field-errors
			]]

			#if debug? = yes [print ["^-c-type = " c-type lf]]

			col: col + 1
		]

		#if debug? = yes [print ["^-free name @ " as byte-ptr! name lf]]

		free as byte-ptr! name
		SET_RETURN(columns)

		#if debug? = yes [print ["]" lf]]
	]


	;---------------------------------- fetch-columns --
	;

	fetch-columns: routine [                            ;-- FIXME: status column isn't used at all
		statement       [object!]
		orientation     [word!]
		offset          [integer!]
		/local
			buffer      [red-handle!]
			buflen      [integer!]
			bufrow      [byte-ptr!]
			c           [integer!]
			d           [integer!]
			col-size    [integer!]
			cols        [integer!]
			columns     [red-block!]
			dt          [sql-date!]
			digits      [integer!]
			fetched     [red-handle!]
			flat?       [red-value!]
			flatten     [red-logic!]
			float-ptr   [struct! [int1 [integer!] int2 [integer!]]]
			hstmt       [red-handle!]
			int-ptr     [int-ptr!]
			length      [int-ptr!]
			nullable    [integer!]
			orient      [integer!]
			r           [integer!]
			rc          [integer!]
			row         [red-block!]
			rows        [int-ptr!]
			rowset      [red-block!]
			s           [float!]
			sql-type    [integer!]
			status      [red-handle!]
			strlen      [red-handle!]
			sym         [integer!]
			t           [float!]
			tm          [sql-time!]
			tim         [struct! [lo [integer!] hi [integer!]]]
			ts          [sql-timestamp!]
			values      [red-value!]
			window      [integer!]
	][
		#if debug? = yes [print ["FETCH-COLUMNS [" lf]]

		values:          object/get-values statement
		hstmt:       as red-handle! values + odbc/common-field-handle

		columns:      as red-block! values + odbc/stmt-field-columns
		window:         integer/get values + odbc/stmt-field-window
		fetched:     as red-handle! values + odbc/stmt-field-rows-fetched
		status:      as red-handle! values + odbc/stmt-field-rows-status

		flat?:                      values + odbc/common-field-flat?
		if TYPE_OF(flat?) = TYPE_NONE [
			values:      object/get-values (as red-object! values + odbc/stmt-field-connection)
			flat?:                  values + odbc/common-field-flat?
			if TYPE_OF(flat?) = TYPE_NONE [
				values:  object/get-values (as red-object! values + odbc/dbc-field-environment)
				flat?:              values + odbc/common-field-flat?
			]
		]
		flatten: as red-logic! flat?

		#if debug? = yes [print ["^-window:  "              window        lf]]
		#if debug? = yes [print ["^-status:  " as byte-ptr! status/value  lf]]

		rowset:    block/push-only* window
		cols:     (block/rs-length? columns) / odbc/col-field-fields
		sym:       symbol/resolve orientation/symbol

		orient:    case [
			sym = odbc/_all  [sql/fetch-next]
			sym = odbc/_skip [sql/fetch-relative]
			sym = odbc/_at   [sql/fetch-absolute]
			sym = odbc/_head [sql/fetch-first]
			sym = odbc/_back [sql/fetch-prior]
			sym = odbc/_next [sql/fetch-next]
			sym = odbc/_tail [sql/fetch-last]
		]

		while [true] [
			ODBC_RESULT sql/SQLFetchScroll hstmt/value orient offset

			#if debug? = yes [print ["^-SQLFetchScroll " rc lf]]

			ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

			if ODBC_NO_DATA [
				break
			]
			if ODBC_INVALID [fire [
				TO_ERROR(script invalid-arg) statement
			]]
			if any [ODBC_ERROR ODBC_EXECUTING] [fire [
				TO_ERROR(script bad-bad) odbc/odbc
				as red-block! (object/get-values statement) + odbc/common-field-errors
			]]

			rows: as int-ptr! fetched/value

			#if debug? = yes [print ["^-fetched: " as byte-ptr! fetched/value " (" rows/value " rows) " lf]]

		;#if debug? = yes [
		;    c: 0
		;    loop cols [
		;        offset: c * odbc/col-field-fields
		;        c: c + 1
		;        buffer:  as red-handle! block/rs-abs-at columns offset + odbc/col-field-buffer
		;        buflen:     integer/get block/rs-abs-at columns offset + odbc/col-field-buffer-len
		;        odbc/print-buffer as byte-ptr! buffer/value buflen * rows/value
		;    ]
		;]

			r: 0
			loop rows/value [
				row: either flatten/value [
					rowset
				][
					block/make-in rowset cols
				]

				c: 0
				loop cols [
					offset: c * odbc/col-field-fields
					c: c + 1

					sql-type:   integer/get block/rs-abs-at columns offset + odbc/col-field-sql-type
					col-size:   integer/get block/rs-abs-at columns offset + odbc/col-field-col-size
					nullable:   integer/get block/rs-abs-at columns offset + odbc/col-field-nullable
					digits:     integer/get block/rs-abs-at columns offset + odbc/col-field-digits

					buffer:  as red-handle! block/rs-abs-at columns offset + odbc/col-field-buffer
					buflen:     integer/get block/rs-abs-at columns offset + odbc/col-field-buffer-len
					strlen:  as red-handle! block/rs-abs-at columns offset + odbc/col-field-strlen-ind

					bufrow:  as byte-ptr! buffer/value
					bufrow:  bufrow + (r * buflen)

					length:   as int-ptr! strlen/value
					length: length + r

					if sql/null-data = (FFFFh and length/value) [
						none/make-in row                ;-- continue early with NONE value
						continue
					]

					case [
						any [
							sql-type = sql/wlongvarchar
							sql-type = sql/wvarchar
							sql-type = sql/wchar
						][
							string/load-in as c-string! bufrow length/value >> 1 row UTF-16LE
						]
						any [
							sql-type = sql/longvarchar
							sql-type = sql/varchar
							sql-type = sql/char
						][
							string/load-in as c-string! bufrow length/value row UTF-8
						]
						any [
							sql-type = sql/decimal
							sql-type = sql/numeric
						][
							set-type as cell! string/load-in as c-string! bufrow length/value row UTF-8 TYPE_REF
						]
						any [
							sql-type = sql/smallint
							sql-type = sql/integer
						][
							int-ptr: as int-ptr! bufrow
							integer/make-in row int-ptr/value
						]
						any [
							sql-type = sql/double
							sql-type = sql/float
							sql-type = sql/real
						][
							float-ptr: as struct! [int1 [integer!] int2 [integer!]] bufrow
							float/make-in row float-ptr/int2 float-ptr/int1
						]
						sql-type = sql/bit [
							logic/make-in row bufrow/value = #"^(01)"
						]
						sql-type = sql/tinyint [
							int-ptr: as int-ptr! bufrow
							integer/make-in row int-ptr/value
						]
						sql-type = sql/bigint [
							string/load-in as c-string! bufrow length/value row UTF-8
						]
						any [
							sql-type = sql/longvarbinary
							sql-type = sql/varbinary
							sql-type = sql/binary
						][
							binary/load-in bufrow length/value row
						]
						sql-type = sql/type-date [
							dt: as sql-date! bufrow

							d: 0 and 0001FFFFh or ((dt/year|month and 0000FFFFh      )         << 17)
							d: d and FFFF0FFFh or ((dt/year|month and FFFF0000h >> 16) and 0Fh << 12)
						;   d: d and FFFFF07Fh or ((dt/day|pad    and 0000FFFFh      ) and 1Fh <<  7)
							d: d and FFFFF07Fh or ((as integer! dt/daylo)              and 1Fh <<  7)

							date/make-in row d 0 0
						]
						sql-type = sql/type-time [
							tm: as sql-time! bufrow

							t: (3600.0 * as float! tm/hour|minute and 0000FFFFh      )
							 + (  60.0 * as float! tm/hour|minute and FFFF0000h >> 16)
						;    + (         as float! tm/second|pad  and 0000FFFFh      )
							d: as integer! tm/seclo
							t: t + (     as float! d                                 )

							tim: as struct! [lo [integer!] hi [integer!]] as byte-ptr! :t

							time/make-in row tim/hi tim/lo
						]
						sql-type = sql/type-timestamp [
							ts: as sql-timestamp! bufrow

							d: 0 and 0001FFFFh or ((ts/year|month and 0000FFFFh      )         << 17)
							d: d and FFFF0FFFh or ((ts/year|month and FFFF0000h >> 16) and 0Fh << 12)
							d: d and FFFFF07Fh or ((ts/day|hour   and 0000FFFFh      ) and 1Fh <<  7)
							d: d or 00010000h

							t: (3600.0 * as float! ts/day|hour      and FFFF0000h >> 16)
							 + (  60.0 * as float! ts/minute|second and 0000FFFFh      )
							 + (         as float! ts/minute|second and FFFF0000h >> 16)
							 + (  1e-9 * as float! ts/fraction)

							tim: as struct! [lo [integer!] hi [integer!]] as byte-ptr! :t

							date/make-in row d tim/hi tim/lo
						]
						any [
							sql-type = sql/interval-year
							sql-type = sql/interval-year-to-month
							sql-type = sql/interval-month
							sql-type = sql/interval-day
							sql-type = sql/interval-hour
							sql-type = sql/interval-minute
							sql-type = sql/interval-second
							sql-type = sql/interval-day-to-hour
							sql-type = sql/interval-day-to-minute
							sql-type = sql/interval-day-to-second
							sql-type = sql/interval-hour-to-minute
							sql-type = sql/interval-hour-to-second
							sql-type = sql/interval-minute-to-second
						][
							string/load-in as c-string! bufrow length/value row UTF-8
						]
						sql-type = sql/guid [
							string/load-in as c-string! bufrow length/value row UTF-8
						]
						true [
							#if debug? = yes [print ["^-DEFAULT sql-type handler" lf]]

							string/load-in as c-string! bufrow length/value row UTF-16LE
						]
					]

				] ; loop cols

				r: r + 1
			] ; loop rows/value

			unless sym = odbc/_all [break]
		]

		SET_RETURN(rowset)

		#if debug? = yes [print ["]" lf]]
	]


	;--------------------------------- free-statement --
	;

	free-statement: routine [
		statement       [object!]
		/local
			hstmt       [red-handle!]
			option      [integer!]
			rc          [integer!]
			step        [integer!]
	][
		#if debug? = yes [print ["FREE-STATEMENT [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		step: 0
		loop 3 [
			step:   step + 1
			option: switch step [
				1 [sql/close]
				2 [sql/unbind]
				3 [sql/reset-params]
			]

			ODBC_RESULT sql/SQLFreeStmt hstmt/value option

			#if debug? = yes [print ["^-SQLFreeStmt " rc lf]]

			ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

			unless ODBC_SUCCEEDED [fire [
				TO_ERROR(script bad-bad) odbc/odbc
				as red-block! (object/get-values statement) + odbc/common-field-errors
			]]
		]

		#if debug? = yes [print ["]" lf]]
	]


	;-------------------------------- close-statement --
	;

	close-statement: routine [
		statement       [object!]
		/local
			hstmt       [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["CLOSE-STATEMENT [" lf]]

		hstmt: as red-handle! (object/get-values statement) + odbc/common-field-handle

		ODBC_RESULT sql/SQLFreeHandle sql/handle-stmt hstmt/value

		#if debug? = yes [print ["^-SQLFreeHandle " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-stmt hstmt/value statement)

		unless ODBC_SUCCEEDED [fire [TO_ERROR(access cannot-close) statement]]

		#if debug? = yes [print ["]" lf]]
	]


	;------------------------------- close-connection --
	;

	close-connection: routine [
		connection      [object!]
		/local
			hdbc        [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["CLOSE-CONNECTION [" lf]]

		hdbc: as red-handle! (object/get-values connection) + odbc/common-field-handle

		ODBC_RESULT sql/SQLDisconnect hdbc/value

		#if debug? = yes [print ["^-SQLDisconnect " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		unless ODBC_SUCCEEDED [fire [TO_ERROR(access cannot-close) connection]]

		ODBC_RESULT sql/SQLFreeHandle sql/handle-dbc hdbc/value

		#if debug? = yes [print ["^-SQLFreeHandle " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-dbc hdbc/value connection)

		unless ODBC_SUCCEEDED [fire [TO_ERROR(access cannot-close) connection]]

		#if debug? = yes [print ["]" lf]]
	]


	;------------------------------ close-environment --
	;

	close-environment: routine [
		environment     [object!]
		return:         [none!]
		/local
			henv        [red-handle!]
			rc          [integer!]
	][
		#if debug? = yes [print ["CLOSE-ENVIRONMENT [" lf]]

		henv: as red-handle! (object/get-values environment) + odbc/common-field-handle

		ODBC_RESULT sql/SQLFreeHandle sql/handle-env henv/value

		#if debug? = yes [print ["^-SQLFreeHandle " rc lf]]

		ODBC_DIAGNOSIS(sql/handle-env henv/value environment)

		unless ODBC_SUCCEEDED [fire [TO_ERROR(access cannot-close) environment]]

		#if debug? = yes [print ["]" lf]]

		as red-none! SET_RETURN(none-value)
	]


	;------------------------------------ debug-odbc? --
	;

	debug-odbc?: routine [return: [logic!]] [
	#either debug? = yes [true] [false]
	]


	;============================== private functions ==
	;
	;
	;  ██████  ██████  ██ ██    ██  █████  ████████ ███████
	;  ██   ██ ██   ██ ██ ██    ██ ██   ██    ██    ██
	;  ██████  ██████  ██ ██    ██ ███████    ██    █████
	;  ██      ██   ██ ██  ██  ██  ██   ██    ██    ██
	;  ██      ██   ██ ██   ████   ██   ██    ██    ███████
	;

	;-------------------------------------- init-odbc --
	;

	init-odbc: func [
		"Init ODBC environment."
	][
		if debug-odbc? [print "init-odbc"]

		if zero? environment/count [
			open-environment environment
		]

		environment/count: environment/count + 1

		exit
	]


	;-------------------------------------- free-odbc --
	;

	free-odbc: func [
		"Free environment."
	][
		if debug-odbc? [print "free-odbc"]

		all [
			zero? environment/count: environment/count - 1
			close-environment environment
		]
	]


	;------------------------------- describe-columns --
	;

	describe-columns: function [
		statement [object!]
	][
		if debug-odbc? [print "describe-columns"]

		if zero? cols: count-columns statement [
			return affected-rows statement
		]

		statement/columns: bind-columns statement cols

		new-line/all extract statement/columns 8 off    ;-- 8 = odbc/col-field-fields
	]


	;------------------------------------- as-column --
	;

	as-column: function [column [string!]] [
		upper: charset [#"A" - #"Z" #"À" - #"Ö" #"Ø" - #"Þ"]
		lower: charset [#"a" - #"z" #"ß" - #"ö" #"ø" - #"ÿ"]
		parse/case column: system/words/copy column [
			any [
				change ["_" | "." | " "] "-"
			|   here: upper upper lower (here: system/words/change/part here rejoin [here/1 here/2 "-" here/3] 3) :here
			|   here: lower upper       (here: system/words/change/part here rejoin [here/1 "-" here/2] 2) :here
			|   skip
			]
		]
		lowercase column
	]


	;--------------------------------- return-columns --
	;
	;   FIXME:  This whole RETURN-COLUMNS thing is nothing
	;           but a costly hack to late convert datatypes
	;           on Red level instead of doing the right ting
	;           on Red/System level
	;
	;   Returns DECIMAL or NUMERIC if the a LOAD-able
	;   or string otherwise.

	return-columns: function [statement rows] [
		if debug-odbc? [print "return-columns"]

		either first find reduce [
			statement/flat?
			statement/connection/flat?
			environment/flat?
		] logic! [
			forall rows [all [
				ref? value: first rows
				system/words/change rows any [attempt [load value: to string! value] value]
			]]

			columns: divide system/words/length? statement/columns 8
														; 8 = rs-odbc/col-field-fields
			new-line/skip/all system/words/head rows on columns
		][
			foreach row rows [forall row [all [
				ref? value: first row
				system/words/change row any [attempt [load value: to string! value] value]
			]]]

			new-line/all system/words/head rows on
		]
	]


	;------------------------------ about-environment --
	;

	environment-attrs: [
		00200 "SQL_ATTR_ODBC_VERSION"        integer!
		00201 "SQL_ATTR_CONNECTION_POOLING"  ;SQLUINTEGER
		00202 "SQL_ATTR_CP_MATCH"            ;SQLUINTEGER
		10001 "SQL_ATTR_OUTPUT_NTS"          logic!
	]


	;------------------------------- connection-infos --
	;

	cursor-attributes:
	supported-conversions: none

	connection-infos: compose/only [
		00000 "max-driver-connections"
		00001 "max-concurrent-activities"
		00002 "data-source-name"
	;   00003 "driver-hdbc"                             ;-- FIXME: support this?
	;   00004 "driver-henv"                             ;-- FIXME: support this?
	;   00005 "driver-hstmt"                            ;-- FIXME: support this?
		00006 "driver-name"
		00007 "driver-ver"
	;   00008 "fetch-direction"                         ;-- deprecated in 3.x
	;   00009 "odbc-api-conformance"                    ;-- deprecated in 3.x
		00010 "odbc-ver"
		00011 "row-updates" ?
	;   00012 "odbc-sag-cli-conformance"                ;-- FIXME: support this?
		00013 "server-name"
		00014 "search-pattern-escape"
	;   00015 "odbc-sql-conformance"                    ;-- deprecated in 3.x
	;   00016                                           ;-- FIXME: undefined?!
		00017 "dbms-name"
		00018 "dbms-ver"
		00019 "accessible-tables" ?
		00020 "accessible-procedures" ?
		00021 "procedures" ?
		00022 "concat-null-behavior" opt [
			00000000h null
			00000001h non-null
		]
		00023 "cursor-commit-behavior" opt [
			00000000h delete
			00000001h close
			00000002h preserve
		]
		00024 "cursor-rollback-behavior" opt [
			00000000h delete
			00000001h close
			00000002h preserve
		]
		00025 "data-source-read-only" ?
		00026 "default-txn-isolation" any [
			00000001h read-uncommitted
			00000002h read-committed
			00000004h repeatable-read
			00000008h serializable
		]
		00027 "expressions-in-orderby" ?
		00028 "identifier-case" opt [
			00000001h upper
			00000002h lower
			00000003h sensitive
			00000004h mixed
		]
		00029 "identifier-quote-char"
		00030 "max-column-name-len"
		00031 "max-cursor-name-len"
		00032 "max-schema-name-len"
		00033 "max-procedure-name-len"
		00034 "max-catalog-name-len"
		00035 "max-table-name-len"
		00036 "mult-result-sets" ?
		00037 "multiple-active-txn" ?
		00038 "outer-joins" ?
		00039 "schema-term"
		00040 "procedure-term"
		00041 "catalog-name-separator"
		00042 "catalog-term"
	;   00043 "scroll-concurrency"                      ;-- deprecated in 3.x
		00044 "scroll-options" any [
			00000001h forward-only
			00000002h keyset-driven
			00000004h dynamic
			00000008h mixed
			00000010h static
		]
		00045 "table-term"
		00046 "txn-capable" opt [
			00000001h dml
			00000002h all
			00000003h ddl-commit
			00000004h ddl-ignore
		]
		00047 "user-name"
		00048 "convert-functions" any [
			00000001h convert
			00000002h cast
		]
		00049 "numeric-functions" any [
			00000001h abs
			00000002h acos
			00000004h asin
			00000008h atan
			00000010h atan2
			00000020h ceiling
			00000040h cos
			00000080h cot
			00000100h exp
			00000200h floor
			00000400h log
			00000800h mod
			00001000h sign
			00002000h sin
			00004000h sqrt
			00008000h tan
			00010000h pi
			00020000h rand
			00040000h degrees
			00080000h log10
			00100000h power
			00200000h radians
			00400000h round
			00800000h truncate
		]
		00050 "string-functions" any [
			00000001h convert
			00000002h lower
			00000004h upper
			00000008h substring
			00000010h translate
			00000020h trim-both
			00000040h trim-leading
			00000080h trim-trailing
			00000100h overlay
			00000200h length
			00000400h position
			00000800h concat
		]
		00051 "system-functions" any [
			00000001h username
			00000002h dbname
			00000004h ifnull
		]
		00052 "timedate-functions" any [
			00000001h now
			00000002h curdate
			00000004h dayofmonth
			00000008h dayofweek
			00000010h dayofyear
			00000020h month
			00000040h quarter
			00000080h week
			00000100h year
			00000200h curtime
			00000400h hour
			00000800h minute
			00001000h second
			00002000h timestampadd
			00004000h timestampdiff
			00008000h dayname
			00010000h monthname
			00020000h current-date
			00040000h current-time
			00080000h current-timestamp
			00100000h extract
		]
		00053 "convert-bigint" any (supported-conversions: [
			00000001h char
			00000002h numeric
			00000004h decimal
			00000008h integer
			00000010h smallint
			00000020h float
			00000040h real
			00000080h double
			00000100h varchar
			00000200h longvarchar
			00000400h binary
			00000800h varbinary
			00001000h bit
			00002000h tinyint
			00004000h bigint
			00008000h date
			00010000h time
			00020000h timestamp
			00040000h longvarbinary
			00080000h interval-year-month
			00100000h interval-day-time
			00200000h wchar
			00400000h wlongvarchar
			00800000h wvarchar
			01000000h guid
		])
		00054 "convert-binary" any (
			supported-conversions
		)
		00055 "convert-bit" any (
			supported-conversions
		)
		00056 "convert-char" any (
			supported-conversions
		)
		00057 "convert-date" any (
			supported-conversions
		)
		00058 "convert-decimal" any (
			supported-conversions
		)
		00059 "convert-double" any (
			supported-conversions
		)
		00060 "convert-float" any (
			supported-conversions
		)
		00061 "convert-integer" any (
			supported-conversions
		)
		00062 "convert-longvarchar" any (
			supported-conversions
		)
		00063 "convert-numeric" any (
			supported-conversions
		)
		00064 "convert-real" any (
			supported-conversions
		)
		00065 "convert-smallint" any (
			supported-conversions
		)
		00066 "convert-time" any (
			supported-conversions
		)
		00067 "convert-timestamp" any (
			supported-conversions
		)
		00068 "convert-tinyint" any (
			supported-conversions
		)
		00069 "convert-varbinary" any (
			supported-conversions
		)
		00070 "convert-varchar" any (
			supported-conversions
		)
		00071 "convert-longvarbinary" any (
			supported-conversions
		)
		00072 "txn-isolation-option" any [
			00000001h read-uncommitted
			00000002h read-committed
			00000004h repeatable-read
			00000008h serializable
		]
		00073 "integrity" ?
		00074 "correlation-name" opt [
			00000001h different
			00000002h any
		]
		00075 "non-nullable-columns" opt [
			00000000h null
			00000001h non-null
		]
	;   00076 "driver-hlib"                             ;-- FIXME: support this?
		00077 "driver-odbc-ver"
	;   00078 "lock-types"                              ;-- deprecated in 3.x
	;   00079 "pos-operations"                          ;-- deprecated in 3.x
	;   00080 "positioned-statements"                   ;-- deprecated in 3.x
		00081 "getdata-extensions" any [
			00000001h any-column
			00000002h any-order
		]
		00082 "bookmark-persistence" any [
			00000001h close
			00000002h delete
			00000004h drop
			00000008h transaction
			00000010h update
			00000020h other-hstmt
			00000040h scroll
		]
	;   00083 "static-sensitivity"                      ;-- deprecated in 3.x
		00084 "file-usage" any [
			00000001h table
			00000002h catalog
		]
		00085 "null-collation" opt [
			00000000h high
			00000001h low
			00000002h start
			00000004h end
		]
		00086 "alter-table" any [
			00000001h add-column
			00000002h drop-column
			00000004h add-constraint
			00000020h add-column-single
			00000040h add-column-default
			00000080h add-column-collation
			00000100h set-column-default
			00000200h drop-column-default
			00000400h drop-column-cascade
			00000800h drop-column-restrict
			00001000h add-table-constraint
			00002000h drop-table-constraint-cascade
			00004000h drop-table-constraint-restrict
			00008000h constraint-name-definition
			00010000h constraint-initially-deferred
			00020000h constraint-initially-immediate
			00040000h constraint-deferrable
			00080000h constraint-non-deferrable
		]
		00087 "column-alias" ?
		00088 "group-by" opt [
			00000000h not-supported
			00000001h group-by-equals-select
			00000002h group-by-contains-select
			00000003h no-relation
			00000004h collate
		]
		00089 "keywords"
		00090 "order-by-columns-in-select" ?
		00091 "schema-usage" any [
			00000001h dml-statements
			00000002h procedure-invocation
			00000004h table-definition
			00000008h index-definition
			00000010h privilege-definition
		]
		00092 "catalog-usage" any [
			00000001h dml-statements
			00000002h procedure-invocation
			00000004h table-definition
			00000008h index-definition
			00000010h privilege-definition
		]
		00093 "quoted-identifier-case" opt [
			00000001h upper
			00000002h lower
			00000003h sensitive
			00000004h mixed
		]
		00094 "special-characters"
		00095 "subqueries" any [
			00000001h comparison
			00000002h exists
			00000004h in
			00000008h quantified
			00000010h correlated-subqueries
		]
		00096 "union" any [
			00000001h union
			00000002h union-all
		]
		00097 "max-columns-in-group-by"
		00098 "max-columns-in-index"
		00099 "max-columns-in-order-by"
		00100 "max-columns-in-select"
		00101 "max-columns-in-table"
		00102 "max-index-size"
		00103 "max-row-size-includes-long" ?
		00104 "max-row-size"
		00105 "max-statement-len"
		00106 "max-tables-in-select"
		00107 "max-user-name-len"
		00108 "max-char-literal-len"
		00109 "timedate-add-intervals" any [
			00000001h frac-second
			00000002h second
			00000004h minute
			00000008h hour
			00000010h day
			00000020h week
			00000040h month
			00000080h quarter
			00000100h year
		]
		00110 "timedate-diff-intervals" any [
			00000001h frac-second
			00000002h second
			00000004h minute
			00000008h hour
			00000010h day
			00000020h week
			00000040h month
			00000080h quarter
			00000100h year
		]
		00111 "need-long-data-len" ?
		00112 "max-binary-literal-len"
		00113 "like-escape-clause" ?
		00114 "catalog-location" opt [
			00000001h start
			00000002h end
		]
		00115 "oj-capabilities" any [
			00000001h left
			00000002h right
			00000004h full
			00000008h nested
			00000010h not-ordered
			00000020h inner
			00000030h all-comparison-ops
		]
		00116 "active-environments"
		00117 "alter-domain" any [
			00000001h constraint-name-definition
			00000002h add-domain-constraint
			00000004h drop-domain-constraint
			00000008h add-domain-default
			00000010h drop-domain-default
			00000020h add-constraint-initially-deferred
			00000040h add-constraint-initially-immediate
			00000080h add-constraint-deferrable
			00000100h add-constraint-non-deferrable
		]
		00118 "sql-conformance" any [
			00000001h sql92-entry
			00000002h fips127-2-transitional
			00000004h sql92-intermediate
			00000008h sql92-full
		]
	;   00119 "ansi-sql-datetime-literals" any [
	;       00000001h date
	;       00000002h time
	;       00000004h timestamp
	;       00000008h interval-year
	;       00000010h interval-month
	;       00000020h interval-day
	;       00000040h interval-hour
	;       00000080h interval-minute
	;       00000100h interval-second
	;       00000200h interval-year-to-month
	;       00000400h interval-day-to-hour
	;       00000800h interval-day-to-minute
	;       00001000h interval-day-to-second
	;       00002000h interval-hour-to-minute
	;       00004000h interval-hour-to-second
	;       00008000h interval-minute-to-second
	;   ]
		00120 "batch-row-count" any [
			00000001h procedures
			00000002h explicit
			00000004h rolled-up
		]
		00121 "batch-support" any [
			00000001h select-explicit
			00000002h row-count-explicit
			00000004h select-proc
			00000008h row-count-proc
		]
	;   00122 "convert-wchar"                                               ;-- FIXME: support this?
	;   00123 "convert-interval-day-time"   any (supported-conversions)     ;-- FIXME: support this?
	;   00124 "convert-interval-year-month" any (supported-conversions)     ;-- FIXME: support this?
	;   00125 "convert-wlongvarchar"                                        ;-- FIXME: support this?
	;   00126 "convert-wvarchar"                                            ;-- FIXME: support this?
		00127 "create-assertion" any [
			00000001h create-assertion
			00000010h constraint-initially-deferred
			00000020h constraint-initially-immediate
			00000040h constraint-deferrable
			00000080h constraint-non-deferrable
		]
		00128 "create-character-set" any [
			00000001h create-character-set
			00000002h collate-clause
			00000004h limited-collation
		]
		00129 "create-collation" any [
			00000001h create-collation
		]
		00130 "create-domain" any [
			00000001h create-domain
			00000002h default
			00000004h constraint
			00000008h collation
			00000010h constraint-name-definition
			00000020h constraint-initially-deferred
			00000040h constraint-initially-immediate
			00000080h constraint-deferrable
			00000100h constraint-non-deferrable
		]
		00131 "create-schema" any [
			00000001h create-schema
			00000002h authorization
			00000004h default-character-set
		]
		00132 "create-table" any [
			00000001h create-table
			00000002h commit-preserve
			00000004h commit-delete
			00000008h global-temporary
			00000010h local-temporary
			00000020h constraint-initially-deferred
			00000040h constraint-initially-immediate
			00000080h constraint-deferrable
			00000100h constraint-non-deferrable
			00000200h column-constraint
			00000400h column-default
			00000800h column-collation
			00001000h table-constraint
			00002000h constraint-name-definition
		]
		00133 "create-translation" any [
			00000001h create-translation
		]
		00134 "create-view" any [
			00000001h create-view
			00000002h check-option
			00000004h cascaded
			00000008h local
		]
	;   00135 "driver-hdesc"                            ;-- FIXME: support this?
		00136 "drop-assertion" any [
			00000001h drop-assertion
		]
		00137 "drop-character-set" any [
			00000001h drop-character-set
		]
		00138 "drop-collation" any [
			00000001h drop-collation
		]
		00139 "drop-domain" any [
			00000001h drop-domain
			00000002h restrict
			00000004h cascade
		]
		00140 "drop-schema" any [
			00000001h drop-schema
			00000002h restrict
			00000004h cascade
		]
		00141 "drop-table" any [
			00000001h drop-table
			00000002h restrict
			00000004h cascade
		]
		00142 "drop-translation" any [
			00000001h drop-translation
		]
		00143 "drop-view" any [
			00000001h drop-view
			00000002h restrict
			00000004h cascade
		]
		00144 "dynamic-cursor-attributes1" any (cursor-attributes: [
			00000001h next
			00000002h absolute
			00000004h relative
			00000008h bookmark
			00000040h lock-no-change
			00000080h lock-exclusive
			00000100h lock-unlock
			00000200h pos-position
			00000400h pos-update
			00000800h pos-delete
			00001000h pos-refresh
			00002000h positioned-update
			00004000h positioned-delete
			00008000h select-for-update
			00010000h bulk-add
			00020000h bulk-update-by-bookmark
			00040000h bulk-delete-by-bookmark
			00080000h bulk-fetch-by-bookmark
		])
		00145 "dynamic-cursor-attributes2" any (
			cursor-attributes
		)
		00146 "forward-only-cursor-attributes1" any (
			cursor-attributes
		)
		00147 "forward-only-cursor-attributes2" any (
			cursor-attributes
		)
		00148 "index-keywords" any [
			00000000h #[none]
			00000001h asc
			00000002h desc
			00000003h all
		]
		00149 "info-schema-views" any [
			00000001h assertions
			00000002h character-sets
			00000004h check-constraints
			00000008h collations
			00000010h column-domain-usage
			00000020h column-privileges
			00000040h columns
			00000080h constraint-column-usage
			00000100h constraint-table-usage
			00000200h domain-constraints
			00000400h domains
			00000800h key-column-usage
			00001000h referential-constraints
			00002000h schemata
			00004000h sql-languages
			00008000h table-constraints
			00010000h table-privileges
			00020000h tables
			00040000h translations
			00080000h usage-privileges
			00100000h view-column-usage
			00200000h view-table-usage
			00400000h views
		]
		00150 "keyset-cursor-attributes1"       any (cursor-attributes)
		00151 "keyset-cursor-attributes2"       any (cursor-attributes)
		00152 "odbc-interface-conformance" opt [
			00000001h core
			00000002h level-1
			00000003h level-2
		]
		00153 "param-array-row-counts" opt [
			00000001h batch
			00000002h no-batch
		]
		00154 "param-array-selects" opt [
			00000001h batch
			00000002h no-batch
			00000003h no-select
		]
		00155 "sql92-datetime-functions" any [
			00000001h current-date
			00000002h current-time
			00000004h current-timestamp
		]
		00156 "sql92-foreign-key-delete-rule" any [
			00000001h cascade
			00000002h no-action
			00000004h set-default
			00000008h set-null
		]
		00157 "sql92-foreign-key-update-rule" any [
			00000001h cascade
			00000002h no-action
			00000004h set-default
			00000008h set-null
		]
		00158 "sql92-grant" any [
			00000001h usage-on-domain
			00000002h usage-on-character-set
			00000004h usage-on-collation
			00000008h usage-on-translation
			00000010h with-grant-option
			00000020h delete-table
			00000040h insert-table
			00000080h insert-column
			00000100h references-table
			00000200h references-column
			00000400h select-table
			00000800h update-table
			00001000h update-column
		]
		00159 "sql92-numeric-value-functions" any [
			00000001h bit-length
			00000002h char-length
			00000004h character-length
			00000008h extract
			00000010h octet-length
			00000020h position
		]
		00160 "sql92-predicates" any [
			00000001h exists
			00000002h isnotnull
			00000004h isnull
			00000008h match-full
			00000010h match-partial
			00000020h match-unique-full
			00000040h match-unique-partial
			00000080h overlaps
			00000100h unique
			00000200h like
			00000400h in
			00000800h between
			00001000h comparison
			00002000h quantified-comparison
		]
		00161 "sql92-relational-join-operators" any [
			00000001h corresponding-clause
			00000002h cross-join
			00000004h except-join
			00000008h full-outer-join
			00000010h inner-join
			00000020h intersect-join
			00000040h left-outer-join
			00000080h natural-join
			00000100h right-outer-join
			00000200h union-join
		]
		00162 "sql92-revoke" any [
			00000001h usage-on-domain
			00000002h usage-on-character-set
			00000004h usage-on-collation
			00000008h usage-on-translation
			00000010h grant-option-for
			00000020h cascade
			00000040h restrict
			00000080h delete-table
			00000100h insert-table
			00000200h insert-column
			00000400h references-table
			00000800h references-column
			00001000h select-table
			00002000h update-table
			00004000h update-column
		]
		00163 "sql92-row-value-constructor" any [
			00000001h value-expression
			00000002h null
			00000004h default
			00000008h row-subquery
		]
		00164 "sql92-string-functions" any [
			00000001h convert
			00000002h lower
			00000004h upper
			00000008h substring
			00000010h translate
			00000020h trim-both
			00000040h trim-leading
			00000080h trim-trailing
			00000100h overlay
			00000200h length
			00000400h position
			00000800h concat
		]
		00165 "sql92-value-expressions" any [
			00000001h case
			00000002h cast
			00000004h coalesce
			00000008h nullif
		]
	;   00166 "standard-cli-conformance" any [          ;-- FIXME: support this?
	;       00000001h xopen-cli-version1
	;       00000002h iso92-cli
	;   ]
		00167 "static-cursor-attributes1" any (
			cursor-attributes
		)
		00168 "static-cursor-attributes2" any (
			cursor-attributes
		)
		00169 "aggregate-functions" any [
			00000001h avg
			00000002h count
			00000004h max
			00000008h min
			00000010h sum
			00000020h distinct
			00000040h all
			00000080h every
			00000100h any
			00000200h stdev-op
			00000400h stdev-samp
			00000800h var-samp
			00001000h var-pop
			00002000h array-agg
			00004000h collect
			00008000h fusion
			00010000h intersection
		]
		00170 "ddl-index" any [
			00000001h create-index
			00000002h drop-index
		]
		00171 "dm-ver"
		00172 "insert-statement" any [
			00000001h insert-literals
			00000002h insert-searched
			00000004h select-into
		]
	;   00173 "convert-guid" any (                      ;-- FIXME: support this?
	;       supported-conversions
	;   )
	;   00174 "schema-inference"                        ;-- TODO: odbc 4.0
	;   00175 "binary-functions"                        ;-- TODO: odbc 4.0
	;   00176 "iso-string-functions"                    ;-- TODO: odbc 4.0
	;   00177 "iso-binary-functions"                    ;-- TODO: odbc 4.0
	;   00178 "limit-escape-clause"                     ;-- TODO: odbc 4.0
	;   00179 "native-escape-clause"                    ;-- TODO: odbc 4.0
	;   00180 "return-escape-clause"                    ;-- TODO: odbc 4.0
	;   00181 "format-escape-clause"                    ;-- TODO: odbc 4.0
	;   10000 "xopen-cli-year"
	;   10001 "cursor-sensitivity" opt [
	;       00000000h unspecified
	;       00000001h insensitive
	;       00000002h sensitive
	;   ]
		10002 "describe-parameter" ?
		10003 "catalog-name" ?
		10004 "collation-seq"
		10005 "max-identifier-len"
		10021 "async-mode" any [
			00000001h connection
			00000002h statement
		]
	;   10022 "max-async-concurrent-statements"
	;   10023 "async-dbc-functions"
		10024 "driver-aware-pooling-supported" opt [
			00000000h #[false]
			00000001h #[true]
		]
		10025 "async-notification" opt [
			00000000h #[false]
			00000001h #[true]
		]
	]

	about-connection: function [
		"Collects connection information."
		connection [object!]
		/local value name
	][
		if debug-odbc? [print "about-connection"]

		make map! sort/skip parse connection-infos [
			collect some [
				set info integer!
				set name string! (
				;if debug-odbc? [print ["info:" info name]]

					info: pick-information connection info
				)
				keep (name)
				opt [
					'? keep (
						equal? info "Y"
					)
				|   'any set values [word! | block!] keep (
						if word? values [values: get values]
						collect [foreach [value name] values [
							unless zero? info and value [keep name]
						]]
					)
				|   'opt set values [block! | block!] keep (
						if word? values [values: get values]
						foreach [value name] values [
							if equal? info value [break/return name]
						]
					)
				|   keep (info)
				]
			]
		] 2
	]


	;------------------------------- connection-attrs --
	;

	connection-attrs: [
		00004 "SQL_ATTR_ASYNC_ENABLE"
		00101 "SQL_ATTR_ACCESS_MODE"
		00102 "SQL_ATTR_AUTOCOMMIT"
		00103 "attr-login-timeout"
		00104 "SQL_ATTR_TRACE"
		00105 "SQL_ATTR_TRACEFILE"
		00106 "SQL_ATTR_TRANSLATE_LIB"
		00107 "SQL_ATTR_TRANSLATE_OPTION"
		00108 "SQL_ATTR_TXN_ISOLATION"
		00109 "SQL_ATTR_CURRENT_CATALOG"
		00110 "SQL_ATTR_ODBC_CURSORS"
		00111 "SQL_ATTR_QUIET_MODE"
		00112 "SQL_ATTR_PACKET_SIZE"
		00113 "SQL_ATTR_CONNECTION_TIMEOUT"
		00114 "SQL_ATTR_DISCONNECT_BEHAVIOR"
		00117 "SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE"
		00119 "SQL_ATTR_ASYNC_DBC_EVENT"
		01207 "SQL_ATTR_ENLIST_IN_DTC"
		01208 "SQL_ATTR_ENLIST_IN_XA"
		01209 "SQL_ATTR_CONNECTION_DEAD"
		10001 "SQL_ATTR_AUTO_IPD"
		10014 "SQL_ATTR_METADATA_ID"
	]


	;-------------------------------- statement-attrs --
	;

	statement-attrs: [
		00000 "SQL_ATTR_QUERY_TIMEOUT"                  ;SQLULEN
		00001 "SQL_ATTR_MAX_ROWS"                       ;integer! "window size"
		00002 "SQL_ATTR_NOSCAN"                         ;logic! "scan SQL strings for escape sequences (default OFF)"
		00003 "SQL_ATTR_MAX_LENGTH"                     ;integer! "maximum amount of data that the driver returns from a character or binary column"
		00004 "SQL_ATTR_ASYNC_ENABLE"                   ;logic! "whether a function called with the specified statement is executed asynchronously"
		00005 "SQL_ATTR_ROW_BIND_TYPE"                  ;[0 bind-by-column]
		00006 "SQL_ATTR_CURSOR_TYPE"                    ;before-preparation [0 forward-only 1 keyset-driven 2 dynamic 3 static] "specifies the cursor type"
		00007 "SQL_ATTR_CONCURRENCY"                    ;[1 read-only "(default)" 2 lock 3 rowver 4 values] "specifies the cursor concurrency"
		00008 "SQL_ATTR_KEYSET_SIZE"                    ;SQLULEN "pecifies the number of rows in the keyset for a keyset-driven cursor"
		00011 "SQL_ATTR_RETRIEVE_DATA"                  ;logic!
		00010 "SQL_ATTR_SIMULATE_CURSOR"                ;[0 non-unique 1 try-unique 2 unique] "whether drivers that simulate positioned update and delete statements guarantee that such statements affect only one single row"
		00012 "SQL_ATTR_USE_BOOKMARKS"                  ;[0 off 1 on 2 variable] "whether an application will use bookmarks with a cursor"
		00014 "SQL_ATTR_ROW_NUMBER"                     ;read-only SQLULEN "number of the current row in the entire result set (or zero, if unretrievable)"
		00015 "SQL_ATTR_ENABLE_AUTO_IPD"                ;logic! "whether automatic population of the IPD is performed"
		00016 "SQL_ATTR_FETCH_BOOKMARK_PTR"             ;handle!
		00017 "SQL_ATTR_PARAM_BIND_OFFSET_PTR"          ;handle!
		00018 "SQL_ATTR_PARAM_BIND_TYPE"                ;[0 param-bind-by-column]
		00019 "SQL_ATTR_PARAM_OPERATION_PTR"            ;handle!
		00020 "SQL_ATTR_PARAM_STATUS_PTR"               ;handle!
		00021 "SQL_ATTR_PARAMS_PROCESSED_PTR"           ;handle!
		00022 "SQL_ATTR_PARAMSET_SIZE"                  ;SQLULEN "specifies the number of values for each parameter"
		00023 "SQL_ATTR_ROW_BIND_OFFSET_PTR"            ;handle!
		00024 "SQL_ATTR_ROW_OPERATION_PTR"              ;handle!
		00025 "SQL_ATTR_ROW_STATUS_PTR"                 ;handle!
		00026 "SQL_ATTR_ROWS_FETCHED_PTR"               ;handle!
		00027 "SQL_ATTR_ROW_ARRAY_SIZE"                 ;SQLULEN "specifies the number of rows returned by each call to SQLFetch or SQLFetchScroll"
		00029 "SQL_ATTR_ASYNC_STMT_EVENT"               ;
	;   ????? "SQL_ATTR_ASYNC_STMT_PCALLBACK"           ;driver-only
	;   ????? "SQL_ATTR_ASYNC_STMT_PCONTEXT"            ;driver-only
		10010 "SQL_ATTR_APP_ROW_DESC"                   ;handle! "to the ARD for subsequent fetches on the statement handle"
		10011 "SQL_ATTR_APP_PARAM_DESC"                 ;handle! "to the APD for subsequent calls to SQLExecute and SQLExecDirect on the statement handle"
		10012 "SQL_ATTR_IMP_ROW_DESC"                   ;read-only handle! "to the IRD"
		10013 "SQL_ATTR_IMP_PARAM_DESC"                 ;read-only handle! "handle to the IPD"
		10014 "SQL_ATTR_METADATA_ID"                    ;SQLULEN "determines how the string arguments of catalog functions are treated"
		FFFFh "SQL_ATTR_CURSOR_SCROLLABLE"              ;[0 non-scrollable 1 scrollable] "specifies the level of scrolling support that the application requires"
		FFFEh "SQL_ATTR_CURSOR_SENSITIVITY"             ;SQLULEN "specifies whether cursors on the statement handle make visible the changes made to a result set by another cursor"
	]


	;=============================== scheme functions ==
	;

	;------------------------------------ get-drivers --
	;

	get-drivers: function [
		"Returns info on ODBC drivers."
		/local
			desc
			attrs
			attr
	][
		if debug-odbc? [print "scheme/drivers"]

		init-odbc
		drivers: collect [foreach [desc attrs] list-drivers environment [
			attrs: split system/words/head remove system/words/back system/words/tail attrs #"^@"
			attrs: to map! collect [foreach attr attrs [keep split attr #"="]]
			keep reduce [desc attrs]
		]]
		free-odbc

		new-line/skip/all drivers on 2
	]


	;------------------------------------ get-sources --
	;

	get-sources: function [
		"Returns info on ODBC data sources."
		/user       "user data sources only"
		/system     "system data sources only"
	][
		if debug-odbc? [print "scheme/sources"]

		all [user system cause-error 'script 'bad-refines []]

		init-odbc
		sources: list-sources environment any [
			pick [user] user
			pick [system] system
			'all
		]
		free-odbc

		new-line/skip/all sources on 2
	]


	;-------------------------------- set-commit-mode --
	;

	set-commit-mode: func [
		connection      [object!]
		auto?           [logic!]
	][
		set-connection connection 0066h                 ;-- SQL_ATTR_AUTOCOMMIT
								  either auto? [1] [0]  ;-- SQL_ATTR_AUTOCOMMIT on/off
								  FFFBh                 ;-- SQL_IS_UINTEGER
	]


	;-------------------------------- set-cursor-type --
	;

	set-cursor-type: func [
		statement       [object!]
		old
		new
	][
		case/all [
			not find [default forward keyset static dynamic] new [
				set-quiet in statement 'cursor old
				cause-error 'script 'bad-bad ["ODBC" "invalid cursor type"]
			]
			find [keyset] new [
				set-quiet in statement 'cursor old
				cause-error 'internal 'bad-bad ["ODBC" "keyset driven cursors not implemented"]
			]
		]

		new: select [forward 0 keyset 1 dynamic 2 static 3 default 0] new

		set-statement statement 6 new FFFBh             ;-- SQL_ATTR_CURSOR_TYPE, SQL_IS_UINTEGER
	]


	;------------------------------- set-cursor-scrolling --
	;

	set-cursor-scrolling: func [
		statement       [object!]
		old
		new
	][
		unless logic? new [
			cause-error 'script 'bad-bad ["ODBC" "invalid cursor scrolling"]
		]

		set-statement statement FFFFh                   ;-- SQL_ATTR_CURSOR_SCROLLABLE
								pick [1 0] new          ;-- SQL_(NON)SCROLLABLE
								FFFBh                   ;-- SQL_IS_UINTEGER
	]


	;================================ actor functions ==
	;
	;
	;   █████   ██████ ████████  ██████  ██████   ██████
	;  ██   ██ ██         ██    ██    ██ ██   ██ ██
	;  ███████ ██         ██    ██    ██ ██████   █████
	;  ██   ██ ██         ██    ██    ██ ██   ██      ██
	;  ██   ██  ██████    ██     ██████  ██   ██ ██████
	;

	;------------------------------------------- open --
	;

	open: function [
		"Connect to a datasource or open a statement."
		entity          [port!] "connection string to open connection port, connection port to return statement port"
	][
		case [
			none? entity/state [
				if debug-odbc? [print "actor/open: connection"]

				init-odbc
				connection: make connection-proto []

				open-connection environment connection any [
					entity/spec/target
					rejoin ["DSN=" entity/spec/host]
				]

				connection/environment: environment     ;-- linkage only after success
				append environment/connections connection

				entity/state: connection
				entity/state/info: about-connection connection

				connection/port: entity
			]
			all [entity/state entity/state/type = 'connection] [
				if debug-odbc? [print "actor/open: statement"]

				connection: entity/state
				statement:  make statement-proto []
				port:       make entity [scheme: 'odbc]

				open-statement connection statement

				statement/connection: connection        ;-- linkage only after success
				append connection/statements statement

				port/state: statement
				statement/port: port
			]
			/else [
				cause-error 'script 'invalig-arg [entity]
			]
		]
	]


	;----------------------------------------- insert --
	;

	insert: function [{
		Prepares and executes (batches of) SQL statement(s), returning (first)
		result set's column names or row count.
		Commits or rolls back all active operations on all statements associated
		with a connection.
		Performs catalog queries.}
		entity          [port!]
		sql             [string! word! block!]  "statement w/o parameter(s) (block gets reduced) or catalog dialect"
		/part
			length      [integer!]
	][
		if debug-odbc? [print "actor/insert"]

		set [connection: statement:] reduce switch entity/state/type [
			connection [[entity none]]
			statement  [[none entity]]
		]

		case [
			all [statement any [
				string? sql
				all [
					block? sql
					string? first sql
				]
			]][
				sql: reduce compose [(sql)]

				free-parameters statement/state
				free-columns    statement/state
				free-statement  statement/state

				unless same? statement/state/sql first sql [                    ;-- prepare only new statement
					prepare-statement statement/state sql
					statement/state/sql: first sql
				]

				unless system/words/tail? params: system/words/next sql [
					unless block? first params [
						system/words/insert/only params take/part params system/words/length? params
																				;-- treat ["..." p1 p2] as ["..." [p1 p2]] prm array with only 1 elem
					]
					foreach prmset params [unless block? prmset [               ;-- assert all prmsets are blocks
						cause-error 'script 'expect-val ['block! type? prmset]
					]]
					unless single? unique collect [foreach prmset params [      ;-- assert all prmsets have the same length
						keep system/words/length? prmset
					]][
						cause-error 'script 'invalid-arg [prmset]
					]
					repeat pos system/words/length? first params [
						types: unique collect [foreach prmset params [
							unless none? param: prmset/:pos [keep case [
								date? param [either param/time ['datetime!] ['date!!]]
								any-string? param ['any-string!]
								/else [type?/word param]
							]]
						]]
						unless any [
							empty?  types               ;-- all rows in param col are #[none]
							single? types
						][
							cause-error 'script 'not-same-type []
						]
					]
					bind-parameters statement/state params
				]

				execute-statement statement/state
				result: describe-columns statement/state

				either number? result [result] [collect [forall result [        ;-- column titles
					column: as-column first result
					keep any [attempt [to word! column] column]
				]]]
			]
			all [statement any [
				word? sql
				any [
					block? sql
					word? first sql
				]
			]][
				string!?: [string! | none! | change 'none (none)]
				strict?:  no

				unless parse command: compose [(sql) (none) (none) (none) (none) (none) (none) (none)] [
					opt [remove 'strict (strict?: yes)]
					[   'column 'privileges 4 string!?
					|   'columns            4 string!?
					|   'foreign 'keys      6 string!?
					|   'special 'columns   ['unique | 'update | none! | change 'none (none)]
											3 string!?
											['row | 'transaction | 'session | none! | change 'none (none)]
											[   logic!
											|   change ['yes | 'true  | 'on ] (on)
											|   change ['no  | 'false | 'off] (off)
											|   none!
											|   change 'none (none)
											]
					|   'primary 'keys      3 string!?
					|   'procedure 'columns 4 string!?
					|   'procedures         3 string!?
					|   'statistics         3 string!?
											['all | 'unique | none! | change 'none (none)]
														;-- TODO: SQL_QUICK vs. SQL_ENSURE not supported!
					|   'table 'privileges  3 string!?
					|   'tables             4 string!?
					|   'types                          ;-- TODO: datatype arg not supported yet
					]
					to end
				][
					cause-error 'script 'invalid-arg reduce [mold sql]
				]

				free-parameters   statement/state       ;-- all this freeing here is architecturally required,
				free-columns      statement/state       ;   in case of a statement already being prepared an bound
				free-statement    statement/state
				statement/state/sql: none

				catalog-statement statement/state command strict?
				describe-columns  statement/state
			]
			all [connection find [commit rollback] sql] [
				end-transaction connection/state sql = 'commit
			]
			/else [
				cause-error 'script 'invalid-arg [sql]
			]
		] ;case

	]


	;----------------------------------------- change --
	;

	change: function [
		"Translates SQL statement into native SQL."
		entity          [port!]
		sql             [series! port!] "sql string"
	][
		if debug-odbc? [print "actor/change"]

		sql: reduce compose [(sql)]

		unless string? first sql [
			cause-error 'script 'invalid-arg [sql]
		]

		connection: switch entity/state/type [
			connection [entity]
			statement  [entity/state/connection/port]
		]

		translate-statement connection/state first sql
	]


	;---------------------------------------- length? --
	;

	length?: function [
		"Returns number of rows of the current result set."
		statement       [port!]
	][
		if debug-odbc? [print "actor/length?"]

		affected-rows statement/state
	]


	;----------------------------------------- index? --
	;

	index?: function [
		"Returns number of current rows of the current result set."
		statement       [port!]
	][
		if debug-odbc? [print "actor/index?"]

		pick-attribute statement/state 14 ;SQL_ATTR_ROW_NUMBER
	]


	;----------------------------------------- update --
	;

	update: function [
		"Updates statement with next result set and returns its column names or row count."
		statement       [port!]
	][
		if debug-odbc? [print "actor/update"]

		all [
			more-results?    statement/state
			describe-columns statement/state
		]
	]


	;------------------------------------------- copy --
	;

	copy: function [
		"Copy rowset from executed SQL statement."
		statement       [port!]
	][
		if debug-odbc? [print "actor/copy"]

		rows: fetch-columns statement/state 'all 0
		return-columns statement/state rows
	]


	;------------------------------------------- skip --
	;

	skip: function [
		"Copy rowset from executed SQL statement at relative offset."
		statement       [port!]
		rows            [integer!]
	][
		if debug-odbc? [print "actor/skip"]

		rows: fetch-columns statement/state pick [at skip] zero? rows rows
		return-columns statement/state rows
	]


	;--------------------------------------------- at --
	;

	at: function [
		"Copy rowset from executed SQL statement at absolute position."
		statement       [port!]
		row             [integer!]
	][
		if debug-odbc? [print "actor/at"]

		rows: fetch-columns statement/state 'at min statement/state/length max 0 row
		return-columns statement/state rows
	]


	;------------------------------------------- head --
	;

	head: function [
		"Retrieve first rowset from executed SQL statement."
		statement       [port!]
	][
		rows: fetch-columns statement/state 'head 0 ;ignored
		return-columns statement/state rows
	]


	;------------------------------------------ head? --
	;

	head?: function [
		"Returns true if current rowset includes first row in rowset."
		statement       [port!]
	][
		1 = index? statement
	]


	;------------------------------------------- back --
	;

	back: function [
		"Retrieve previous rowset from executed SQL statement."
		statement       [port!]
	][
		rows: fetch-columns statement/state 'back statement/state/window
		return-columns statement/state rows
	]


	;------------------------------------------- next --
	;

	next: function [
		"Retrieve next rowset from executed SQL statement."
		statement       [port!]
	][
		rows: fetch-columns statement/state 'next statement/state/window
		return-columns statement/state rows
	]


	;------------------------------------------- tail --
	;

	tail: function [
		"Retrieve last rowset from executed SQL statement."
		statement       [port!]
	][
		rows: fetch-columns statement/state 'tail 0 ;ignored
		return-columns statement/state rows
	]


	;------------------------------------------ tail? --
	;

	tail?: function [
		"Returns true if current rowset includes last row in rowset."
		statement       [port!]
	][
		statement/state/length <= (statement/state/window - 1 + index? statement)
	]


	;------------------------------------------ close --
	;

	close: function [
		"Close connection or statement."
		entity          [port!] "connection or statement"
	][
		switch entity/state/type [
			connection [
				if debug-odbc? [print "actor/close: connection"]

				connection: entity
				statements: connection/state/statements

				while [not empty? statements] [
					statement: take statements
					close statement/port
				]
				close-connection connection/state
				remove find environment/connections connection/state

				free-odbc
			]
			statement [
				if debug-odbc? [print "actor/close: statement"]

				statement: entity

				free-columns    statement/state
				close-statement statement/state

				remove find statement/state/connection/statements statement/state
				statement/state/connection: none
			]
		]

		exit
	]

] ;odbc


;=========================================== register ==
;

register-scheme make system/standard/scheme [
	name:   'ODBC
	title:  "ODBC"
	actor:  odbc
	state:  odbc/environment
]

unset 'odbc                                             ;-- do not pollute global context

