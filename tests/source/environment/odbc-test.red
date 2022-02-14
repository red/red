Red [
	Title:   "Red ODBC tests"
	Author:  "Christian Ensel"
	File: 	 %tests/odbc-test.red
	Tabs:    4
	Rights:  "Copyright 2022 Christian Ensel"
	License: 'Unlicensed
]

#include  %../../../quick-test/quick-test.red
#include  %odbc-test-integration.red					;-- NOTE: deliberatly .gitignore'd

~~~start-file~~~ "odbc"

===start-group=== "prerequisites tests"

	;-- If the following testing requirements aren't met, most consecutive
	;   tests will fail, too. However, these env-vars aren't required for
	;   anything other than running these tests.

	--test-- {can get-env "TESTDSN"}  --assert not none? get-env "TESTDSN"
	--test-- {can get-env "TESTDRVR"} --assert not none? get-env "TESTDRVR"
	--test-- {can get-env "TESTSRVR"} --assert not none? get-env "TESTSRVR"
	--test-- {can get-env "TESTPORT"} --assert not none? get-env "TESTPORT"
	--test-- {can get-env "TESTDB"}   --assert not none? get-env "TESTDB"
	--test-- {can get-env "TESTUID"}  --assert not none? get-env "TESTUID"
	--test-- {can get-env "TESTPWD"}  --assert not none? get-env "TESTPWD"
	--test-- {can get-env "TESTCSV"}  --assert not none? get-env "TESTCSV"

===end-group===

===start-group=== "environment tests"

	--test-- "can lists drivers" --assert block? system/schemes/odbc/info/drivers
	--test-- "can lists sources" --assert block? system/schemes/odbc/info/sources

===end-group===

===start-group=== "connection tests"

	--test-- "can connect by ODBC datasource name"
		--assert not error? try [
			url: rejoin [odbc:// get-env "TESTDSN"]		;-- required to be set for
			close open open url							;	the test to succeed
		]

	--test-- "can connect by ODBC connection string"
		--assert not error? try [
			set/any 'outcome try [
				conn: open make port! [scheme: 'odbc target: rejoin [
					"Driver="       get-env "TESTDRVR"	;-- required to be set for
					";Server="		get-env "TESTSRVR"	;   the test to succeed
					";Port=" 		get-env "TESTPORT"
					";Database="	get-env "TESTDB"
					";Uid="			get-env "TESTUID"
					";Pwd="			get-env "TESTPWD"
				]
			]]
			all [conn  close conn]
			outcome
		]

	--test-- "can set state/auto-commit?"
		--assert not error? try [
			conn: open rejoin [odbc:// get-env "TESTCSV"]
			conn/state/auto-commit?: not conn/state/auto-commit?
			close conn
		]

	--test-- "can manually commit a transaction"
		--assert not error? try [
			test: open conn: open rejoin [odbc:// get-env "TESTCSV"]
			conn/state/auto-commit?: no
			insert test "INSERT INTO test.csv (Name, Zahl, Datum) VALUES ('Manuell', 4711, '01-01-2020')"
			insert conn 'commit
			close conn
		]

	--test-- "can translate to native sql on connection"
		--assert not error? try [
			change conn: open rejoin [odbc:// get-env "TESTCSV"] "SELECT {fn CONVERT(4711, SQL_SMALLINT)}"
			close conn
		]

	--test-- "can translate to native sql on statement"
		--assert not error? try [
			change open conn: open rejoin [odbc:// get-env "TESTDSN"] "SELECT caption FROM depot2019.schools"
			close conn
		]

===end-group===

===start-group=== "parameter tests"

	--test-- "can detect prmsets not being blocks"
		--assert equal? 'expect-val try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			set/any 'error try [
				insert test ["SELECT caption FROM depot2019.schools WHERE id = ?" [] 1]
			]
			close conn
			error/id
		]

	--test-- "can detect prmsets of different lengths"
		--assert equal? 'invalid-arg try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			set/any 'error try [
				insert test ["SELECT caption FROM depot2019.schools WHERE id = ?" [1] [1 2]]
			]
			close conn
			error/id
		]

	--test-- "can detect prmsets with unmatched types"
		--assert equal? 'not-same-type try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			set/any 'error try [
				insert test ["SELECT caption FROM depot2019.schools WHERE id = ?" [1 "test"] [1 2]]
			]
			close conn
			error/id
		]

	--test-- "can detect prmsets with unmatched types, but allows NONE"
		--assert not error? comment [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test ["SELECT caption FROM depot2019.schools WHERE school_id = ? AND caption = ?" [1 "Test"] [1 #[none]]]
			close conn
		]

	--test-- "can use string params"
		--assert equal? 3 length? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test ["SELECT caption FROM depot2019.schools WHERE school_id = ?" ["13891"] ["59013"] ["40324"]]
			also collect [until [keep copy test none? update test]] close conn
		]

	--test-- "can round trip strings"
		--assert equal? {[["13891"] ["59013"] ["40324"]]} try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test ["SELECT ?::char(5)" ["13891"] ["59013"] ["40324"]]
			also mold/all new-line/all collect [until [keep copy test none? update test]] off close conn
		]

	--test-- "can exchange the various string types"
		--assert equal? rejoin [
			{[}
			{["string" "file" "http://url" "tag" "e@mail" "ref"] }
			{["ref" "string" "file" "http://url" "tag" "e@mail"] }
			{["e@mail" "ref" "string" "file" "http://url" "tag"] }
			{["tag" "e@mail" "ref" "string" "file" "http://url"] }
			{["http://url" "tag" "e@mail" "ref" "string" "file"] }
			{["file" "http://url" "tag" "e@mail" "ref" "string"]}
			{]}
		] try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test [
				"select ?, ?, ?, ?, ?, ?"
				["string" %file http://url <tag> e@mail @ref]
				[@ref "string" %file http://url <tag> e@mail]
				[e@mail @ref "string" %file http://url <tag>]
				[<tag> e@mail @ref "string" %file http://url]
				[http://url <tag> e@mail @ref "string" %file]
				[%file http://url <tag> e@mail @ref "string"]
			]
			also mold/all new-line/all collect [until [keep copy test none? update test]] off close conn
		]

	--test-- "can use time params"
		--assert equal? {[["0"] ["1"] ["0"]]} try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test ["SELECT '14:15:16'::time = ?" [11:12:13] [14:15:16] [17:18:19]]
			also mold/all new-line/all collect [until [keep copy test none? update test]] off close conn
		]

	--test-- "can round trip times"
		--assert equal? {[[11:12:13] [14:15:16] [17:18:19]]} try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			insert test ["SELECT ?::time" [11:12:13] [14:15:16] [17:18:19]]
			also mold/all new-line/all collect [until [keep copy test none? update test]] off close conn
		]

===end-group===

===start-group=== "datatypes tests"

	--test-- "can fetch integers"
		--assert equal? "[[-2147483648 -1 0 1 2147483647]]" try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT -2147483648, -1, 0, 1, 2147483647}
			also mold/all new-line/all copy test off close conn
		]

	--test-- "can fetch strings"
		--assert equal? {[["" "test"]]} try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT '', 'test' }
			also mold/all new-line/all copy test off close conn
		]

	--test-- "can fetch times"
		--assert equal? {[[8:00:00 11:12:13 24:00:00]]} try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT '08:00'::time, '11:12:13'::time, '24:00:00'::time }
			also mold/all new-line/all copy test off close conn
		]

	--test-- "can fetch times with fractions of seconds"
		--assert equal? 3.123456789 try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT '01:02:03.123456789'::time }
			time: first first copy test
			close conn
			time/seconds
		]

	--test-- "can fetch dates anno Domini (AD) up to year 9999"
		--assert equal? {[[31-Dec-4713 31-Dec-9999]]} try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT '4713-12-31'::date, '9999-12-31'::date }
			also mold/all new-line/all copy test off close conn
		]

	--test-- "can fetch date/time anno Domini (AD) up to year 9999"
		--assert equal? {[[31-Dec-4713/11:12:13 31-Dec-9999/14:15:16]]} try [
			insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT '4713-12-31 11:12:13'::timestamp, '9999-12-31 14:15:16'::timestamp }
			also mold/all new-line/all copy test off close conn
		]

===end-group===

===start-group=== "table tests"

    --test-- "can read all depot2019.articles"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.articles }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.articles_multi"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.articles_multi }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.authorities"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.authorities }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.depots"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.depots }
		--assert not error? try [copy test close conn]

	--test-- "can read all depot2019.messages"			;-- FIXME: *** Internal Error: stack overflow
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.messages }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.orders"			;-- FIXME: *** Internal Error: stack overflow
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.orders }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.packings"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.packings }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.placings"			;-- FIXME: *** Internal Error: stack overflow
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.placings }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.publishers"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.publishers }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.pupils"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.pupils }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.receipts"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.receipts }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.receivings"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.receivings }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.reorders"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.reorders }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.roles"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.roles }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.schools"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.schools }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.sources"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.sources }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.sourcings"			;-- FIXME: *** crashes! ***
    	insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.sourcings }
    	--assert not error? try [close conn cause-error 'user 'message "would crash with access violation"]

    --test-- "can read all depot2019.stockings"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.stockings }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.stocks"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.stocks }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.suppliers"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.suppliers }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.updates"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.updates }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.users"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.users }
		--assert not error? try [copy test close conn]

    --test-- "can read all depot2019.warnings"
		insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] { SELECT * FROM depot2019.warnings }
		--assert not error? try [copy test close conn]

===end-group===

===start-group=== "paging tests"

	--test-- "can set state/window"
		--assert equal? 2 length? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a ORDER BY a }
			also next test close conn
		]

	--test-- "can not use INDEX? before paging"
		--assert error? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a ORDER BY a }
			also try [index? test] close conn
		]

	--test-- "can use INDEX? after paging"
		--assert not error? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a ORDER BY a }
			index? next test
			close conn
		]

	--test-- "can not page back with forward-only cursor"
		--assert error? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a ORDER BY a }
			next test
			also try [back test] close conn
		]

	--test-- "can set static cursor"
		--assert not error? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			test/state/cursor: 'static
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a ORDER BY a }
			back next test
			close conn
		]

	--test-- "may overlap when back paging"
		--assert equal? 2 length? try [
			test: open conn: open rejoin [odbc:// get-env "TESTDSN"]
			test/state/window: 2
			test/state/cursor: 'static
			insert test { SELECT 1 AS a UNION SELECT 2 AS a UNION SELECT 3 AS a UNION SELECT 4 AS a UNION SELECT 5 AS a ORDER BY a }
			loop 3 [rows: next test] 					;-- rows = []
			loop 2 [rows: back test]
			close conn
			rows
		]

===end-group===

===start-group=== "catalog tests"

	--test-- "can catalog column privileges" 	--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [column privileges "lmf" "depot2019" "schools" "school_id"] close conn]
	--test-- "can catalog columns" 				--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] 'columns close conn]
	--test-- "can catalog foreign keys" 		--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [foreign keys "lmf" "depot2019" "schools"] close conn]
	--test-- "can catalog primary keys" 		--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [primary keys "lmf" "depot2019" "schools"] close conn]
	--test-- "can catalog procedure columns" 	--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [procedure columns] close conn]
	--test-- "can catalog procedures" 			--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] 'procedures close conn]
	--test-- "can catalog special columns" 		--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [special columns unique "lmf" "depot2019" "orders"] close conn]
	--test-- "can catalog statistics" 			--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [statistics "lmf" "depot2019" "schools"] close conn]
	--test-- "can catalog table privileges" 	--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] [table privileges] close conn]
	--test-- "can catalog tables" 				--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] 'tables close conn]
	--test-- "can catalog types" 				--assert not error? try [insert test: open conn: open rejoin [odbc:// get-env "TESTDSN"] 'types close conn]

===end-group===

~~~end-file~~~
