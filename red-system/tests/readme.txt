QUICK-TEST - A testing framework for Red/System

INTRO
Quick-Test is a small testing framework for Red/System. It is called quick-test as it was put together quickly to support the development of the "boot-strapped" version of Red/System. Hopefully, it also runs the test quite quickly and, perhaps more importantly, is a quick way to write meaningful tests.

As a result, quick-test is very fussy about where files are and it is not particularly fault tolerant. These were traded-off for an earlier implementation.

There are many improvements that could be made to quick-test. It is expected that quick-test will be replaced at the time when Red/System is re-written so they probably won't get made.

TYPES OF TESTS
Quick-Test supports three types of tests - tests of Red/System code, tests of Red/System programs and tests of the Red/System compiler behaviour.

The first type of tests are written in Red/System, the other two in REBOL.

QUICK TEST COMPONENTS
Quick-Test consists of the following:
  quick-test.r - a REBOL script that supports testing compiler and executable output.
  quick-test.reds - a set of Red/System functions that supports writing tests in Red/System.
  quick-test-all.reds a set of Red/System functions for totalling no of tests, passes and failures.
  prin-int.reds - a temporary Red/System function whichs prints an integer.
  
  (The above are stored in the red-system/tests/quick-test/ directory.)
  
  rs-test-suite.r - a consolidated script of all the individual tests written using quick-test.r
  rs-test-suite.reds - a consolidated script of all the individual tests written using quick-test.reds
  
  (Both the above are stored in the red-system/tests/source/ directory.)
  
  run-all.r - a script which runs the complete set of Red/System tests.
  run-test.r - a script which will run an individual test.
  
  (Both the above are stored in the red-system/tests/ directory.)
  
DIRECTORY STRUCTURE
Quick-Test uses the following directory structure:

  red-system/
    tests/                          ;; the main test directory
    quick-test/                     ;; quick-test components
    source/                         ;; all test sources
      builtin/                      ;; tests for builtin functions (eg print)
      compiler/                     ;; tests of the compiler
      run-time/                     ;; tests of the run time library
      units/                        ;; base language tests (eg datatype tests)
    runnable/                       ;; the test executables
                                    ;; automatically created by Quick-Test
                                    ;; listed in .gitignore

RUNNING TESTS
The Red/System tests are designed to be run from a REBOL/VIEW console session. The tests must be run from the red-system/tests/ directory.

To run all tests:
  do %run-all.r
  
To run an individual test file:
  do/args %run-test.r "%<file>"
  
  where <file> is the path to the file to be tested (from the red-system/tests/ directory).
  
  e.g.
    The command to run the logic-test.reds test file which is in the units directory:
    do/args %run-test.r "%source/units/logic-test.reds"
    
(Note: %run-test.r can run both .r and .reds tests).

WRITING TESTS
In terms of writing tests, Quick-Test is quite minimal by design. It provides only a simple assert function and a minimal set of test organisation functions.

Example 1: A Test of inc.reds - an imaginary function which adds 1 to an integer

Red/System [
  Title:   "Tests of inc.reds"
	File: 	 %source/run-time/inc-test.reds
]
  #include %../../quick-test/quick-test.reds 
  #include %relativepathto/inc.reds
  
  qt-start-file "inc"                 ;; start test - initialises the totals
  
  qt-assert "inc-test-1" 2 = inc 1                 ;; a test
                                                   ;;   test name [string!]
                                                   ;;   expression [logic!]
                                                   
  qt-end-file                         ;; finish test - print totals
  
  
Example 2: A test to check the compiler correctly identifies aan unidentified variable:

REBOL [
  Title: "Red/System compilation error test"
  File:  %source/complier/comp-err-test.r
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
                                  ;; .r test scripts are copied to runnable 
                                  ;; before execution
                                  
                                  ;; There is no need to include quick-test.r
                                  ;; as it will have been included by either 
                                  ;; %run-all.r or %run-test.r
  
qt/start-file "comp-err"          ;; start test
                                  
write %runnable/comp-err.reds {
  Red/System []
  i := 1;
}

qt/compile %runnable/comp-err.reds      ;; compiles programs
                                        ;; compiler output is collected in
                                        ;;  qt/comp-output
                                        
if exists? %runnable/comp-err.reds [delete %runnable/comp-err.reds]      
qt/assert "ce1-l1" none <> find qt/comp-output "*** undefined symbol"
qt/assert "ce1-l2" none <> find qt/comp-output "at:  ["
qt/assert "ce1-l3" none <> find qt/comp-output "i := 1"
qt/assert "ce1-l4" none <> find qt/comp-output "]"

;; qt/assert
;;   test name [string!]
;;   expression [logic!]   

qt/end-file                             ;; ends test and print totals

Example 3: Test the output of a Red/System programs

REBOL [
  Title: "Test output from Red/System programs"
  File:  %source/compiler/output-test.r
  
]

change-dir %../                     ;; revert to tests/ directory from runnable/
  
qt/start-file "output"              ;; as example 2

                                    ;; qt/compile compiles a Red/System
                                    ;; it returns the relative path to the
                                    ;; executable file or none in the case of
                                    ;; a compilation error

either exe: qt/compile src: %source/compiler/hello.reds [

  qt/run exe                        ;; runs the program
                                    ;; the output is collected in qt/output 
  
  qt/assert "hello 1" none <> find qt/output "hello"    ;; same as example 2
  qt/assert "hello 2" none <> find qt/output "world"
][
  qt/compile-error src                              ;; generates a test failure
                                                    ;;  so that the problem is
                                                    ;;  highlighted
]

qt/end-file                                         ;; same as example 2



  
  
  
  
      