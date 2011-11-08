REBOL [
  Title:   "Builds and Runs a single Red/System Tests"
	File: 	 %run-test.r
	Author:  "Peter W A Wood"
	Version: 0.6.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]
;; make runnable/ directory if needed 
make-dir %runnable/
;; include quick-test.r
if not value? 'qt [do %../../quick-test/quick-test.r]

print rejoin ["Quick-Test v" system/script/header/version]
print rejoin ["Running under REBOL " system/version]

;; get the src path
src: system/script/args
either any [
  not "%" <> first src 
  (not find src ".r") and (not find src ".reds")
  not src: to-file src
][
  print "No valid test file supplied"
][
  either find src ".reds" [
    ;; compile & run reds pgm
    remove src                      
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

