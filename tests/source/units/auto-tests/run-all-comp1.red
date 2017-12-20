
Red [
	Title:   "Red auto-generated test"
	Author:  "Peter W A Wood"
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

comment {
	This file is generated by make-run-all-red.r
	Do not edit this file directly.
}

#include %../../../../quick-test/quick-test.red

~~~start-file~~~ "run-all-comp1"
#include %run-all/preprocessor-test.red
#include %run-all/conditional-test.red
#include %run-all/path-test.red
#include %run-all/function-test.red
#include %run-all/type-test.red
#include %run-all/select-test.red
#include %run-all/evaluation-test.red
#include %run-all/switch-test.red
#include %run-all/char-test.red
#include %run-all/routine-test.red
#include %run-all/insert-test.red
#include %run-all/make-test.red
#include %run-all/parse-test.red
#include %run-all/strict-equal-test.red
#include %run-all/integer-test.red
#include %run-all/same-test.red
#include %run-all/case-folding-test.red
#include %run-all/vector-test.red
#include %run-all/pair-test.red
#include %run-all/checksum-test.red
#include %run-all/auto-tests/lexer-auto-test.red
~~~end-file~~~
