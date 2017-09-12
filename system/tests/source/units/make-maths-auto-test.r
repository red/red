REBOL [
  Title:   "Generates Red/System maths tests"
	Author:  "Peter W A Wood"
	File: 	 %make-maths-auto-test.r
	Version: 0.1.3
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

make-test: func [
  test-string [string!]
  /setup
    test-setup [string!]
  /local
    rule
    char
    mold-char
    new-test-string
    cs
][
  cs: complement charset [#"#"]
  mold-char: func [
    char [char!]
  ][
    join {#"^^(} [copy/part tail to-hex to integer! to char! char -2 {)"}]
  ]
  rule: [
    (new-test-string: copy "")
    any [
      copy char [{#"} thru {"}] (append new-test-string mold-char load char) 
      |
      copy string [some cs] (append new-test-string string)
      |
      skip
    ]
  ]
  test-number: test-number + 1
  append tests join {  --test-- "maths-auto-} [test-number {"^(0A)}]
  if setup [append tests test-setup]
  append tests "  --assert "
  
  ;; convert all char! literals to hex format
  parse/all test-string rule
  
  ;; check if the first value is a byte!
  either byte-first? [
    append tests reform [expected "= (as integer! (" new-test-string "))^(0A)"]
  ][
    append tests reform [expected "= (" new-test-string ")^(0A)"]
  ]
   
]

preprocess: func [
  s [string!]
  /local
    calc
    rules
    sb
    ns
    nothing-changed
    division-sign
][

  calc: func [
    a   [char!]
    op  [word!]
    b   [char!]
    /local 
      res
  ][
    ;; Ensure all typecasts are to integer! not char!
    a: to integer! a   
    
    switch op [
      + [res: a + b]
      - [res: a - b]
      * [res: a * b]
      div-sign [res: to integer! (a / b)]
    ]
    
    ;; adjust the return value to emulate 8-bit arithmetic with overflow
    either res >= 0 [
      res: res // 256
    ][
      until [
        res: res + 256
        res > 0
      ]
     ]
    to char! res
  ]
  
  rules: [
    any [
      [set a char! set op word! set b char! (
        acc: calc a op b
        replace ns join "(" [mold a " " op " " mold b ")"] mold acc
        replace ns join "" [mold a " " op " " mold b ] mold acc
        nothing-changed: false
      )] |
      [set a integer! 'div-sign set b integer! (
        replace ns join "" [mold a " " op " " mold b ]
                   join "(to integer! divide "[mold a " " mold b ")"]
      )] |
      [set p paren! (parse to block! p rules)] |
      skip
    ]
    end
  ]

  ns: copy s
  replace/all ns " / " " div-sign "  
  until [
    nothing-changed: true
    sb: to block! load ns
    parse sb rules
    nothing-changed
  ]
  
  ns
]

;; initialisations 
tests: copy ""                          ;; string to hold generated tests
test-number: 0                          ;; number of the generated test
make-dir %auto-tests/
file-out: %auto-tests/maths-auto-test.reds


;; tests & data - test formulae, test data, test formulae, test data, etc.
tests-and-data: [
  [
    "(v * v) * v"
    "(v - v) - v"
    "(v * v) - v"
    "(v - v) * v"
    "v * v * v"
    "v - v - v"
    "v - v * v"
    "(v / v) + v"
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
    [#"^(02)" #"^(02)" #"^(02)"]
    [#"^(07)" #"^(08)" #"^(03)"]
    [1 #"^(0A)" 100]
    [2 #"^(10)" 256]
    [#"^(FD)" #"^(FE)" #"^(FF)"]
    [#"^(AA)" 34 #"^(99)"]
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
    [#"^(FF)" 256 257 258]
    [#"^(FC)" #"^(FD)" #"^(FE)" #"^(FF)"]
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
    [#"^(01)" #"^(02)" #"^(03)" #"^(01)" #"^(02)" #"^(03)" #"^(01)" #"^(02)"]
    [1 2 #"^(03)" 4 5 6 7 8]
    [#"^(F8)" #"^(F9)" #"^(FA)" #"^(FB)" #"^(FC)" #"^(FD)" #"^(FE)" #"^(FF)"]
  ]
]

;;;;;;;;;;;;;;;; start of template ;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;; end of template ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;make-length:$LENGTH$

#include %../../../../../quick-test/quick-test.reds

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

write/binary file-out header

tests: copy ""

foreach [formulae data] tests-and-data [
  foreach test-formula formulae [
    foreach test-data data [
      test-string: copy test-formula
      foreach test-value test-data [
        replace test-string "v" mold test-value
      ]
      
      byte-first?: either char! = type? first test-data [true] [false]
      
      rebol-test-string: preprocess test-string
      
      ;; parse the expression and perform the calculation as Red/System would
      ;; only write a test if REBOL produces a valid result 
      if attempt [expected: do load rebol-test-string][
        
          expected: to integer! expected
              
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
write/append/binary file-out tests
tests: copy ""

;; write file epilog
append tests "^(0A)===end-group===^(0A)^(0A)"
append tests {~~~end-file~~~^(0A)^(0A)}

write/append/binary file-out tests
      
print ["Number of assertions generated" test-number]






