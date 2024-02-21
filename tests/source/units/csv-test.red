Red [
	Title:   "CSV codec test script"
	Author:  "Boleslav Březovský"
	File: 	 %csv-test.red
	Needs:	 CSV
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "CSV"

===start-group=== "to-csv"
	--test-- "to-csv-1-single-line"
		--assert "none^/" = to-csv [none]
		--assert "1,2,3^/" = to-csv [1 2 3]
		--assert "1,2,3^/" = to-csv [[1 2 3]]
		--assert "hello,world^/" = to-csv [hello world]
		--assert {"hello world",from,Red^/} = to-csv ["hello world" from Red]
		--assert {"hello,world",hello,world^/} = to-csv ["hello,world" hello world]
		--assert {1,"^/",3^/} = to-csv [1 "^/" 3]
	--test-- "to-csv-2-multi-line"
		--assert "1,2,3^/4,5,6^/" = to-csv [[1 2 3][4 5 6]]
		--assert "1,2,3^/4,5,6^/7,8,9^/" = to-csv [[1 2 3][4 5 6][7 8 9]]
	--test-- "to-csv-3-skip"
		--assert "1,2,3^/4,5,6^/" = to-csv/skip [1 2 3 4 5 6] 3
	--test-- "to-csv-4-with"
		--assert "1;2;3^/" = to-csv/with [1 2 3] #";"
		--assert "1;2;3^/4;5;6^/" = to-csv/with [[1 2 3][4 5 6]] #";"
		--assert "1;2;3^/4;5;6^/" = to-csv/with/skip [1 2 3 4 5 6] #";" 3
	--test-- "to-csv-5-quote"
		--assert equal? {"hel""lo"^/} to-csv [{hel"lo}]
		--assert equal? {"hel""""lo"^/} to-csv [{hel""lo}]
		--assert equal?
			"'hello world',',',''''^/" 
			to-csv/quote ["hello world" "," "'"] #"'"
	--test-- "to-csv-6-unaligned"
		--assert error? to-csv [[1 2 3][1 2 3 4]]
	--test-- "to-csv-7-fix-4424"
		--assert {"x x"^/} = to-csv l: ["x x"]
		--assert l = ["x x"] ; we need to make sure original was not modified
		unset 'l
	--test-- "to-csv-block-of-keyval"
		--assert {a,b^/1,2^/3,4^/} = to-csv reduce [object [a: 1 b: 2] object [a: 3 b: 4]]
		--assert {a,b^/1,2^/3,4^/} = to-csv reduce [make map! [a: 1 b: 2] make map! [a: 3 b: 4]]
===end-group===

===start-group=== "load-csv"
	--test-- "load-csv-1-single-line"
		--assert [["1" "2" "3"]] = load-csv {1,2,3^/}
		--assert [["1" "2" "3"]] = load-csv {1,2,3}
	--test-- "load-csv-2-multi-line"
		--assert [["1" "2" "3"]["4" "5" "6"]] = load-csv {1,2,3^/4,5,6^/}
		--assert [["1" "2" "3"]["4" "5" "6"]] = load-csv {1,2,3^/4,5,6}
	--test-- "load-csv-3-spaces"
		--assert [["1" "2 " " 3"]] = load-csv {1,2 , 3^/}
		--assert [["1" "2 " " 3"]] = load-csv {1,2 , 3}
	--test-- "load-csv-4-quotes"
		--assert [["aaa" {b"bb} { "ccc"}]] = load-csv {"aaa","b""bb", "ccc"}
	--test-- "load-csv-5-comma"
		--assert [["a" "b,b" "c"]] = load-csv {a,"b,b",c}
	--test-- "load-csv-6-newline"
		--assert [["a" "b^/b" "c"]] = load-csv {a,"b^/b",c}
===end-group===

===start-group=== "load-csv-with"
	--test-- "load-csv-with-1-single-line"
		--assert [["1" "2" "3"]] = load-csv/with {1;2;3^/} #";"
		--assert [["1" "2" "3"]] = load-csv/with {1;2;3} #";"
	--test-- "load-csv-with-2-multi-line"
		--assert [["1" "2" "3"]["4" "5" "6"]] = load-csv/with {1;2;3^/4;5;6^/} #";"
		--assert [["1" "2" "3"]["4" "5" "6"]] = load-csv/with {1;2;3^/4;5;6} #";"
===end-group===

===start-group=== "load-csv-header"
	--test-- "load-csv-header-1"
		--assert #["a" ["1"] "b" ["2"] "c" ["3"]] = load-csv/header {a,b,c^/1,2,3}
		--assert #["a" ["1" "4"] "b" ["2" "5"] "c" ["3" "6"]] 
			= load-csv/header {a,b,c^/1,2,3^/4,5,6}
	--test-- "load-csv-header-2-error"
		--assert error? try [load-csv/header {a,b,c}]
===end-group===

===start-group=== "load-csv-as-columns"
	--test-- "load-csv-as-columns-1"
		--assert #["A" ["1"] "B" ["2"] "C" ["3"]] = load-csv/as-columns {1,2,3}
		--assert #["A" ["1" "4"] "B" ["2" "5"] "C" ["3" "6"]]
			= load-csv/as-columns {1,2,3^/4,5,6}
	--test-- "load-csv-as-columns"
		--assert #["a" ["1"] "b" ["2"] "c" ["3"]]
			= load-csv/as-columns/header {a,b,c^/1,2,3}
===end-group===

===start-group=== "load-csv-as-records"
	--test-- "load-csv-as-records-1"
		--assert [#["A" "1" "B" "2" "C" "3"]] = load-csv/as-records {1,2,3}
		--assert [
			#["A" "1" "B" "2" "C" "3"]
			#["A" "4" "B" "5" "C" "6"]
		] = load-csv/as-records {1,2,3^/4,5,6}
	--test-- "load-csv-as-records-2-header"
		--assert [
			#["A" "1" "B" "2" "C" "3"]
			#["A" "4" "B" "5" "C" "6"]
		] = load-csv/as-records/header {A,B,C^/1,2,3^/4,5,6}
	--test-- "load-csv-as-records-2-header-error"
		--assert error? try [load-csv/as-records/header {a,b,c}]
===end-group===

===start-group=== "load-csv-flat"
	--test-- "load-csv-flat-1"
		--assert ["1" "2" "3"] = load-csv/flat {1,2,3}
		--assert ["1" "2" "3" "4" "5" "6"] = load-csv/flat {1,2,3^/4,5,6}
===end-group===

;===start-group=== "load-csv-align"
;===end-group===

===start-group=== "load-csv-trim"
	--test-- "load-csv-trim-1"
		--assert [["1" "2" "3" "4"]] = load-csv/trim {1, 2, 3 , 4}
===end-group===

===start-group=== "load-csv-quote"
	--test-- "load-csv-quote-1"
		--assert equal?
			load-csv/quote "'hello world',',',''''^/" #"'"
			[["hello world" "," "'"]]
===end-group===

===start-group=== "load-csv-wrong-refinements"
	--test-- "load-csv-as-columns-as-records"
		--assert error? try [load-csv/as-columns/as-records "1,2,3"]
;	--test-- "load-csv-flat-align"
;		--assert error? try [load-csv/flat/align "1,2,3"]
	--test-- "load-csv-flat-as-records"
		--assert error? try [load-csv/flat/as-records "1,2,3"]
	--test-- "load-csv-flat-as-columns"
		--assert error? try [load-csv/flat/as-columns "1,2,3"]
===end-group===

===start-group=== "csv-codec"
	--test-- "csv-codec-1"
		res: [["1" "2" "3"]]
		str: {1,2,3^/}
		--assert res = load/as str 'csv
	--test-- "csv-codec-2"
		--assert {1,2,3^/} = save/as none [1 2 3] 'csv
		--assert {1,2,3^/} = save/as none [[1 2 3]] 'csv
		--assert {1,2,3^/} = save/as none ["1" "2" "3"] 'csv
		--assert {1,2,3^/} = save/as none [["1" "2" "3"]] 'csv
===end-group===

~~~end-file~~~
