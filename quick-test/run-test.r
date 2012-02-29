REBOL [
  Title:   "Builds and Runs a single Red/System Tests"
	File: 	 %run-test.r
	Author:  "Peter W A Wood"
	Version: 0.7.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]


;; include quick-test.r
do %quick-test.r

;; set the base dir for the test source
qt/tests-dir: system/options/path

print rejoin ["Quick-Test v" system/script/header/version]
print rejoin ["Running under REBOL " system/version]

;; get the name of the test file
src: system/script/args

either any [
  (not find src ".r") and (not find src ".reds")
  not src: to-file src
][
  print "No valid test file supplied"
][
  print ["run-test src " src]
  either find src ".reds" [
    ;; compile & run reds pgm                     
    either exe: qt/compile src [
      qt/run exe
      print qt/output
    ][
      print "Compile Error!!!"
      print qt/comp-output
    ]
  ][
      ;; copy and run rebol script
      qt/run-script src
  ]
]

prin ""

