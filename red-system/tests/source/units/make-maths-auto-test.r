REBOL [
  Title:   "Generates Red/System maths tests"
	Author:  "Peter W A Wood"
	File: 	 %make-maths-auto-test.r
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

rand: func [
  "returns a random number between -2147483647 and 2147483647"
  /local i
][
  i: random 2147483647
  if 2 = random 2 [i: - i]
  i
]

make-test: func [
  test-string [string!]
  /setup
    test-setup [string!]
][
  test-number: test-number + 1
  append tests join {  --test-- "maths-auto-} [test-number {"^(0A)}]
  if setup [append tests test-setup]
  append tests "  --assert "
  either find test-string "#" [
    append tests reform [expected "= (as integer! (" test-string "))^(0A)"]
  ][
    append tests reform [expected "= (" test-string ")^(0A)"]
  ]
]

;; initialisations 
tests: copy ""                          ;; string to hold generated tests
test-number: 0                          ;; number of the generated test
make-dir %auto-tests/
file-out: %auto-tests/maths-auto-test.reds


;; tests & data - test formulae, test data, test formulae, test data, etc.
;;  byte! values must be enclosed in () so that the correct expected value will 
;;  be calculated in REBOL
tests-and-data: [
  [
    "(v * v) * v"
    "(v - v) - v"
    "(v * v) - v)"
    "(v - v) * v)"
    "v * v * v"
    "v - v - v"
    "v - v * v"
  ]  
  [
    [1 1 1]
    [2 2 2]
    [256 256 256]
    [257 257 257]
    [255 256 257]
    [-256 256 256]
    [257 -257 257]
    [255 256 -257]
    [-256 -256 -256]
    [-257 -257 -257]
    [-255 -256 -257]
    [(#"^(02)") (#"^(02)") (#"^(02)")]
    [(#"^(09)") (#"^(08)") (#"^(07)")]
    [1 (#"^(0A)") 100]
    [2 (#"^(10)") 256]

  ]
  [
    "(v * v) * (v * v)"
    "(v - v) - (v - v)"
    "(v * v) - (v - v)"
    "(v - v) * (v - v)"
    "(v - v) - (v * v)"
    "(v * v) * (v - v)"
    "(v - v) * (v * v)"
    "(v * v) - (v * v)"
    "v + v + v + v"
    "v / v * v / v"
  ]
  [
    [1 1 1 1]
    [2 2 2 2]
    [256 256 256 256]
    [257 257 257 257]
    [(#"^(FF)") 256 257 258]
  ]
  [
    "((v * v) * (v * v)) * ((v * v) * (v * v))"
    "((v - v) * (v * v)) * ((v * v) * (v * v))"
    "((v * v) - (v * v)) * ((v * v) * (v * v))"
    "((v * v) * (v - v)) * ((v * v) * (v * v))"
    "((v * v) * (v * v)) - ((v * v) * (v * v))"
    "((v * v) * (v * v)) * ((v - v) * (v * v))"
    "((v * v) * (v * v)) * ((v * v) - (v * v))"
    "((v * v) * (v * v)) * ((v * v) * (v - v))"
    "((v - v) * (v * v)) * ((v * v) * (v * v))"
    "((v - v) * (v * v)) * ((v * v) * (v * v))"
    "((v - v) - (v * v)) * ((v * v) * (v * v))"
    "((v - v) * (v - v)) * ((v * v) * (v * v))"
    "((v - v) * (v * v)) - ((v * v) * (v * v))"
    "((v - v) * (v * v)) * ((v - v) * (v * v))"
    "((v - v) * (v * v)) * ((v * v) - (v * v))"
    "((v - v) * (v * v)) * ((v * v) * (v - v))"
    "((v * v) - (v * v)) * ((v * v) * (v * v))"
    "((v - v) - (v * v)) * ((v * v) * (v * v))"
    "((v * v) - (v * v)) * ((v * v) * (v * v))"
    "((v * v) - (v - v)) * ((v * v) * (v * v))"
    "((v * v) - (v * v)) - ((v * v) * (v * v))"
    "((v * v) - (v * v)) * ((v - v) * (v * v))"
    "((v * v) - (v * v)) * ((v * v) - (v * v))"
    "((v * v) - (v * v)) * ((v * v) * (v - v))"
    "((v * v) * (v - v)) - ((v * v) * (v * v))"
    "((v - v) * (v - v)) * ((v - v) * (v * v))"
    "((v * v) * (v - v)) * ((v * v) - (v * v))"
    "((v * v) * (v - v)) * ((v * v) * (v - v))"
    "((v * v) * (v - v)) - ((v * v) * (v * v))"
    "((v * v) * (v - v)) * ((v - v) * (v * v))"
    "((v * v) * (v - v)) * ((v * v) - (v * v))"
    "((v * v) * (v - v)) * ((v * v) * (v - v))"
    "((v - v) - (v - v)) * ((v * v) * (v * v))"
    "((v - v) - (v * v)) - ((v * v) * (v * v))"
    "((v - v) - (v * v)) * ((v - v) * (v * v))"
    "((v - v) - (v - v)) * ((v * v) - (v * v))"
    "((v - v) * (v - v)) - ((v * v) * (v - v))"
    "((v - v) * (v * v)) - ((v - v) * (v * v))"
    "((v - v) * (v * v)) - ((v * v) - (v * v))"
    "((v - v) * (v * v)) - ((v * v) * (v - v))"
    "((v - v) * (v * v)) * ((v - v) - (v * v))"
    "((v - v) * (v * v)) * ((v - v) * (v - v))"
    "((v - v) * (v * v)) * ((v * v) - (v - v))"
    "((v * v) - (v - v)) - ((v * v) * (v * v))"
    "((v * v) - (v - v)) * ((v - v) * (v * v))"
    "((v * v) - (v - v)) * ((v * v) - (v * v))"
    "((v * v) - (v - v)) * ((v * v) * (v - v))"
    "((v * v) * (v - v)) - ((v - v) * (v * v))"
    "((v * v) * (v - v)) - ((v * v) - (v * v))"
    "((v * v) * (v - v)) - ((v * v) * (v - v))"
    "((v * v) * (v - v)) * ((v - v) - (v * v))"
    "((v * v) * (v - v)) * ((v - v) * (v - v))"
    "((v * v) * (v * v)) - ((v - v) - (v * v))"
    "((v * v) * (v * v)) - ((v - v) * (v - v))"
    "((v * v) * (v * v)) - ((v * v) - (v - v))"
    "((v * v) * (v * v)) * ((v - v) - (v - v))"
    "((v - v) * (v - v)) - ((v - v) * (v * v))"
    "((v - v) * (v - v)) - ((v * v) - (v * v))"
    "((v - v) * (v - v)) - ((v * v) * (v - v))"
    "((v - v) - (v - v)) - ((v * v) * (v * v))"
    "((v - v) - (v - v)) * ((v - v) * (v * v))"
    "((v - v) - (v - v)) * ((v * v) - (v * v))"
    "((v - v) - (v - v)) * ((v * v) * (v - v))"
    "((v - v) - (v * v)) * ((v - v) - (v * v))"
    "((v - v) - (v * v)) * ((v - v) * (v - v))"
    "((v * v) - (v - v)) - ((v - v) * (v * v))"
    "((v * v) * (v - v)) - ((v * v) - (v - v))"
    "((v * v) * (v - v)) - ((v - v) - (v - v))"
    "((v * v) * (v * v)) - ((v - v) - (v - v))"
    "((v - v) * (v - v)) - ((v - v) * (v - v))"
    "((v - v) - (v - v)) - ((v - v) - (v - v))"
  ]
  [
    [1 1 1 1 1 1 1 1]
    [256 256 256 256 256 256 256 256]
    [257 257 257 257 257 257 257 257]
    [-256 -256 -256 -256 -256 -256 -256 -256]
    [-257 -257 -257 -257 -257 -257 -257 -257]
    [(#"^(01)") (#"^(02)") (#"^(03)") (#"^(04)") (#"^(05)") (#"^(06)") (#"^(07)") (#"^(08)")]
    [1 2 (#"^(03)") 4 5 6 7 8]
  ]
]

;;;;;;;;;;;;;;;; start of template;;;;;;;;;;;;;;;;;;;;;;;;;;
template: {
Red/System [
  Title:   "Red/System auto-generated maths tests"
  Author:  "Peter W A Wood"
  File:    %maths-auto-test.reds
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

comment {
  This file is generated by make-maths-auto-test.r
  Do not edit this file directly.
}
;make-length:$LENGTH$

#include %../../../quick-test/quick-test.reds

s: declare struct! [
  a [integer!]
  b [integer!]
  c [integer!]
  d [integer!]
  e [integer!]
  f [integer!]
  g [integer!]
  h [integer!]
]

ident: func [i [integer!] return: [integer!]][i]

~~~start-file~~~ "Auto-generated tests for maths"

===start-group=== "Auto-generated tests for maths"

}
;;;;;;;;;;;;;;;; end of template;;;;;;;;;;;;;;;;;;;;;;;;;;

;; start of executable code
header: copy template
replace header "$LENGTH$" length? read %make-maths-auto-test.r 
write file-out header

tests: copy ""

foreach [formulae data] tests-and-data [
  foreach test-formula formulae [
    foreach test-data data [
      test-string: copy test-formula
      foreach test-value test-data [
        replace test-string "v" mold test-value
      ]
    
      ;; only write a test if REBOL produces a result
      rebol-test-string: replace/all copy test-string "#" "to integer! #"
      if attempt [expected: do rebol-test-string][
          
          expected: to-integer expected
              
          ;; test with literal values
          make-test test-string
          
          ;; if the data contains byte! values don't create the other tests
          if not find test-string "#" [
          
          ;; test using integer variables
          test-setup: copy ""
          test-string: copy test-formula
          variable-names: copy ["a" "b" "c" "d" "e" "f" "g" "h"]
          foreach test-value test-data [
            append test-setup join "    " [
              first variable-names ": " mold test-value "^(0A)"
            ]
            replace test-string "v" first variable-names
            variable-names: next variable-names
          ]
          make-test/setup test-string test-setup
          
          ;; test using integer/path 
          test-setup: copy ""
          test-string: copy test-formula
          variable-names: copy ["a" "b" "c" "d" "e" "f" "g" "h"]
          foreach test-value test-data [
            append test-setup join "    s/" [
              first variable-names ": " mold test-value "^(0A)"
            ]
            replace test-string "v" join "s/" [first variable-names]
            variable-names: next variable-names
          ]
          make-test/setup test-string test-setup
          
          ;; test using function call
          test-string: copy test-formula
          foreach test-value test-data [
            replace test-string "v" join "(ident " [mold test-value ")"]
          ]
          make-test test-string
        ]
      ]
    ]
  ]
  recycle
]  
write/append file-out tests
tests: copy ""

;; write file epilog
append tests "^(0A)===end-group===^(0A)^(0A)"
append tests {~~~end-file~~~^(0A)^(0A)}

write/append file-out tests
      
print ["Number of assertions generated" test-number]






