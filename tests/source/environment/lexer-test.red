Red [
	Title:		"Red lexer test"
	Author:		"Peter W A Wood"
	File:		%print-test.red
	Tabs:		4
	Rights:		"Copyright (C) 2014 Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red
#include %../../../environment/lexer.red

~~~start-file~~~ "lexer"


===start-group=== "system/lexer/transcode with none"

	--test-- "trans1"
		--assert [Red[] 1] = system/lexer/transcode {Red[] 1} none
		
	--test-- "trans2"
		--assert [Red[] a: 1] = system/lexer/transcode {Red[] a: 1} none
		
===end-group===

===start-group=== "literal values - integer"

	--test-- "litval-integer1" --assert [1] = system/lexer/transcode {1} none
	--test-- "litval-integer2" --assert [+1] = system/lexer/transcode {+1} none
	--test-- "litval-integer3" --assert [-1] = system/lexer/transcode {-1} none
	--test-- "litval-integer4" --assert [0] = system/lexer/transcode {0} none
	--test-- "litval-integer5" --assert [+0] = system/lexer/transcode {+0} none
	--test-- "litval-integer6" --assert [0] = system/lexer/transcode {-0} none
	--test-- "litval-integer7" --assert 0 = -0
	--test-- "litval-integer8" 
		--assert [2147483647] = system/lexer/transcode {2147483647} none
	--test-- "litval-integer9" 
		--assert [-2147483648] = system/lexer/transcode {-2147483648} none
	--test-- "litval-integer10" --assert [01h] = system/lexer/transcode {01h} none
	--test-- "litval-integer11" --assert [00h] = system/lexer/transcode {00h} none
	--test-- "litval-integer12" --assert [-1] = system/lexer/transcode {FFFFFFFFh} none
	--test-- "litval-integer13" 
		--assert [2147483647] = system/lexer/transcode {7FFFFFFFh} none
	--test-- "litval-integer14" 
		--assert [-2147483648] = system/lexer/transcode {80000000h} none
		
===end-group===

===start-group=== "literal values - char"

    --test-- "lvc1"     --assert [#" "] = system/lexer/transcode {#" "} none
    --test-- "lvc2"     --assert [#"^(00)"] = system/lexer/transcode {#"^^(00)"} none
    --test-- "lvc3"
        --assert [#"^(10FFFF)"] = system/lexer/transcode {#"^^(10FFFF)"} none
    --test-- "lvc4"     --assert [#"^(00E9)"] = system/lexer/transcode {#"é"} none
    --test-- "lvc5"     --assert [#"^(2020)"] = system/lexer/transcode {#"†"} none
    --test-- "lvc6"     --assert [#"^(01F64F)"] = system/lexer/transcode {#"🙏"} none
    --test-- "lvc7"     --assert [#"^/"] = system/lexer/transcode {#"^^/"} none
    --test-- "lvc8"     --assert [#"^(0D)"] = system/lexer/transcode {#"^^M"} none
    --test-- "lvc9"     --assert [#"^(1B)"] = system/lexer/transcode {#"^^["} none
    --test-- "lvc10"    --assert [#"^(09)"] = system/lexer/transcode {#"^^-"} none
    --test-- "lvc11"    --assert [#"^(00)"] = system/lexer/transcode {#"^^@"} none
    --test-- "lvc12"    --assert [#"^@"] = system/lexer/transcode {#"^^@"} none
    --test-- "lvc13"    --assert [#"^M"] = system/lexer/transcode {#"^^M"} none
    --test-- "lvc14"    --assert [#"^["] = system/lexer/transcode {#"^^["} none
    --test-- "lvc15"    --assert [#"^(0D)"] = system/lexer/transcode {#"^^(0D)"} none
    --test-- "lvc16"    --assert [#"^(1B)"] = system/lexer/transcode {#"^^(1B)"} none
    --test-- "lvc17"    --assert [#"^(09)"] = system/lexer/transcode {#"^^(09)"} none
    --test-- "lvc18"    --assert [#"^(0A)"] = system/lexer/transcode {#"^^(0A)"} none
    --test-- "lvc19"    --assert [#"^/"] = system/lexer/transcode {#"^^(0A)"} none
    
===end-group===


~~~end-file~~~
