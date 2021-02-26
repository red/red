Red [
	Title:   "JSON codec test script"
	Author:  "Gabriele Santilli"
	File: 	 %json-test.red
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "JSON"

===start-group=== "to-json"

    --test-- "to-json-1"
        --assert "null" = to-json none

    --test-- "to-json-2"
        --assert "true" = to-json true

    --test-- "to-json-3"
        --assert "false" = to-json false

    --test-- "to-json-4"
        --assert "1" = to-json 1

    --test-- "to-json-5"
        --assert "-1200.0" = to-json -1200.0

    --test-- "to-json-6"
        --assert {"abc"} = to-json "abc"

    --test-- "to-json-7"
        --assert {"\u0000\u001F"} = to-json "^@^_"

    --test-- "to-json-8"
        --assert {"^(4EC1)^(4EBA)"} = to-json "仁人"

    --test-- "to-json-9"
        --assert "[]" = to-json []

    --test-- "to-json-10"
        --assert {[^/    "A",^/    1^/]} = to-json/pretty ["A" 1] "    "

    --test-- "to-json-11"
        --assert "{}" = to-json #()

    --test-- "to-json-12"
        str: {{^/    "a": {^/        "b": {^/            "c": 3^/        }^/    }^/}}
        src: #(
            "a" #(
                "b" #(
                    "c" 3
                )
            )
        )
        --assert str = to-json/pretty src "    "

    --test-- "to-json-13"
        str: {{^/    "a": {^/        "b": {^/            "c": 3,^/            "d": 4^/        }^/    }^/}}
        src: #(
            "a" #(
                "b" #(
                    "c" 3
                    "d" 4
                )
            )
        )
        --assert str = to-json/pretty src "    "

    --test-- "to-json-14"
        str: {{^/    "A": 1,^/    "a": {^/        "b": {^/            "c": 3,^/            "d": [^/                "x",^/                "y",^/                [^/                    3,^/                    4^/                ],^/                "z"^/            ]^/        }^/    },^/    "B": 2^/}}
        src: #(
            "A" 1
            "a" #(
                "b" #(
                    "c" 3
                    "d" ["x" "y" [3 4] "z"]
                )
            )
            "B" 2
        )
        --assert str = to-json/pretty src "    "

    --test-- "to-json-15"
        --assert {["A",1]} = to-json ["A" 1]

    --test-- "to-json-16"
        --assert {{"a":{"b":{"c":3}}}} = to-json #("a" #("b" #("c" 3)))

    --test-- "to-json-17"
        --assert {{"a":{"b":{"c":3,"d":4}}}} = to-json #("a" #("b" #("c" 3 "d" 4)))

    --test-- "to-json-18"
        str: {{"A":1,"a":{"b":{"c":3,"d":["x","y",[3,4],"z"]}},"B":2}}
        src: #(
            "A" 1
            "a" #(
                "b" #(
                    "c" 3
                    "d" ["x" "y" [3 4] "z"]
                )
            )
            "B" 2
        )
        --assert str = to-json src

===end-group===

===start-group=== "load-json"

    --test-- "load-json-1"
        --assert #[none] = load-json "null"

    --test-- "load-json-4"
        --assert 1 = load-json "1"

    --test-- "load-json-5"
        --assert -1200.0 = load-json "-1.2e3"

    --test-- "load-json-6"
        --assert "abc" = load-json {"abc"}

    --test-- "load-json-7"
        --assert "^-^/\" = load-json {"\t\n\\"}

    --test-- "load-json-8"
        --assert "^@^_" = load-json {"\u0000\u001f"}

    --test-- "load-json-9"
        --assert "^(4EC1)^(4EBA)" = load-json {"\u4EC1\u4EBA"}

    --test-- "load-json-10"
        --assert [] = load-json "[]"

    --test-- "load-json-11"
        --assert [] = load-json "[ ]"

    --test-- "load-json-12"
        --assert ["A" 1] = load-json {["A", 1]}

    --test-- "load-json-13"
        --assert #() = load-json "{}"

    --test-- "load-json-14"
        --assert #(array: []) = load-json {{"array":[ ]}}

    --test-- "load-json-15"
        --assert #(a: #(b: #(c: 3))) = load-json {{"a": {"b": {"c": 3}}}}

    --test-- "load-json-16"
        --assert #(a: #(b: #(c: 3 d: 4))) = load-json {{"a": { "b": {"c": 3, "d": 4}}}}

    --test-- "load-json-17"
        res: #(
            A: 1
            a: #(
                b: #(
                    c: 3
                    d: ["x" "y" [3 4] "z"]
                )
            )
            B: 2
        )
        str: {{"A": 1, "a": {"b": { "c": 3, "d": [ "x", "y", [3, 4 ], "z"] }}, "B": 2}}
        --assert res = load-json str

    --test-- "load-json-18"
        --assert error? try [load-json "TRUE"]

    --test-- "load-json-19"
        --assert error? try [load-json "NULL"]

    --test-- "load-json-20"
        --assert error? try [load-json {"Not a tab \T"}]

    --test-- "load-json-21"
        --assert #("<tag>" "value") = load-json {{"<tag>": "value"}}

    --test-- "load-json-22"
        res: #(
            tag: "value"
            "<tag" "value"
            ">tag" "value"
            "tag<" "value"
            "<tag<" "value"
            ">tag<" "value"
            "tag>" "value"
            "<tag>" "value"
            ">tag>" "value"
            "a<tag>b" "value"
        )
        str: {{"tag":"value","<tag":"value",">tag":"value","tag<":"value","<tag<":"value",">tag<":"value","tag>":"value","<tag>":"value",">tag>":"value","a<tag>b":"value"}}
        --assert res = load-json str

    --test-- "load-json-23"         ;-- crash test for strings divisable by 16
        s: "1234567812345678"
        --assert s = load/as mold s 'json

    --test-- "load-json-24"         ;-- crash test
        o: load/as {{"location": "関西    ↓詳しいプロ↓"}} 'json
        --assert o/location = "関西    ↓詳しいプロ↓"

===end-group===

===start-group=== "json-codec"

    --test-- "json-codec-2"
        res: #(
            A: 1
            a: #(
                b: #(
                    c: 3
                    d: ["x" "y" [3 4] "z"]
                )
            )
            B: 2
        )
        str: {{"A": 1, "a": {"b": { "c": 3, "d": [ "x", "y", [3, 4 ], "z"] }}, "B": 2}}
        --assert res = load/as str 'json

    --test-- "json-codec-3"
        --assert {{"a":{"b":{"c":3,"d":4}}}} = save/as none #("a" #("b" #("c" 3 "d" 4))) 'json

    --test-- "json-codec-4"
        str: copy ""
        random/seed 1337
        loop 1'000'000 [append str random #"^(110)"]
        save/as bin: #{} str 'json
        str2: load/as bin 'json
        --assert str == str2
        unset [str str2 bin]

===end-group===

~~~end-file~~~
