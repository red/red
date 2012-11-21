REBOL [
  Title:   "Builds and Runs a single Red/System Tests"
	File: 	 %run-test.r
	Author:  "Peter W A Wood"
	Version: 0.9.3
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; include quick-test.r
do %quick-test.r

;; set the base dir for the test source
qt/tests-dir: system/script/path
remove/part find/last qt/tests-dir "quick-test/" 11
qt/r-tests-dir: qt/tests-dir

print rejoin ["Quick-Test v" qt/version]
print rejoin ["Running under REBOL " system/version]

;; get the name of the test file
src: system/script/args

either any [
  not src: to-file src
  all [
    %.r <> suffix? src
    %.red <> suffix? src
    %.reds <> suffix? src
  ]
][
  print "No valid test file supplied"
][
  either %.reds = suffix? src [
    ;; compile & run reds pgm                     
    either exe: qt/compile src [
      qt/run exe
      print qt/output
    ][
      print "Compile Error!!!"
      print qt/comp-output
    ]
  ][
    either %.red = suffix? src [
      ;; compile and run red pgm
      --compile-and-run-red src
      print qt/output
      
    ][
      either find read qt/tests-dir/:src "quick-unit-test.r" [
        --run-unit-test src
      ][
        ;; copy and run rebol script
        qt/run-script src
      ]
    ]
  ]
]

prin ""

