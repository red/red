REBOL [
  Title:   "Simple testing framework for Red/System programs"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.r
	Version: 0.2.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

comment {
  This script makes some assumptions about the location of files. They are:
    this script will be run from the red-system/tests directory
    the test scripts will be in the red-system/tests/source directories
    this script resides in the red-system/tests/quick-test directory
    the compiler will reside in the red-system directory
    the source of the programmes being tested are in red-system/tests/source directories
    the exe of the program being tested will be created in red-system/builds
    (quick-test will move the executable to red-system/runnable.)
}

qt: make object! [
  
  ;;;;;;;;;;; Setup ;;;;;;;;;;;;;;
  ;; set the base-dir to ....red/red-system/tests
  base-dir: system/script/path  
  base-dir: copy/part base-dir find base-dir "tests/quick-test"
  
  ;; file names
  comp-echo: join base-dir %tests/runnable/comp-echo.txt
  comp-r: join base-dir %tests/runnable/comp.r

  ;; make runnable directory if needed
  make-dir join base-dir %tests/runnable/
  
  windows-os?: func [] [
    either system/version/4 = 3 [true] [false]
  ]
  
  ;; use Cheyenne call with REBOL v2.7.8 on Windows (re: 'call bug on Windows 7)
  if all [
    windows-os?
    system/version/3 = 8              
  ][
		do %call.r					               
		set 'call :win-call
	]
  ;;;;;;;;;;; End Setup ;;;;;;;;;;;;;;
  
  comp-output: ""                   ;; output captured from compile
  output: ""                        ;; output captured from pgm exec
  
  compile: func [
    src [file!]
    /local
      comp                          ;; compilation script
      cmd                           ;; compilation cmd
      exe                           ;; executable name
      built                         ;; full path of compiler output
  ][
    clear comp-output
    ;; workout executable name
    if not exe: copy find/last/tail src "/" [exe: copy src]
    exe: copy/part exe find exe "."
    if windows-os? [
      exe: join exe [".exe"]
    ]

    
    ;; compose and write compilation script
    save-dir: what-dir
    comp: mold compose [
      REBOL []
      halt: :quit
      change-dir (base-dir)
      echo (comp-echo)
      do/args %rsc.r "***src***"
      change-dir (what-dir)
    ]
    src: replace/all src "%" ""
    src: join "%" [base-dir "tests/" src]
    replace comp "***src***" src
    write comp-r comp

    ;; compose command line and call it
    cmd: join to-local-file system/options/boot [" -sc " comp-r]
    call/wait cmd
    
    ;; collect compiler output & tidy up
    if exists? comp-echo [
    	comp-output: read comp-echo
    	delete comp-echo
    ]
    if exists? comp-r [delete comp-r]
    
    ;; move the executable from /builds to /tests/runnable
    built: join base-dir [%builds/ exe]
    runner: join base-dir [%tests/runnable/ exe]
    
    if exists? built [
      write/binary runner read/binary built
      delete built
      if not windows-os? [
        r: open runner
        set-modes r [
          owner-execute: true
          group-execute: true
        ]
        close r
      ]
    ]
    
    either compile-ok? [
      exe
    ][
      none
    ]    
  ]
  
  compile-error: func [
    src [file!]
  ][
    assert join "" [src " - compiler error"] false
    print comp-output
  ]
  
  compile-ok?: func [] [
    either find comp-output "output file size:" [true] [false]
  ] 
  
  run: func [
    prog [file!]
    ;;/args                         ;; not yet needed
      ;;parms [string!]             ;; not yet needed  
    /local
    exec [string!]                   ;; command to be executed
  ][
    exec: to-local-file join base-dir [%tests/runnable/ prog]
    ;;exec: join "" compose/deep [(exec either args [join " " parms] [""])]
    clear output
    call/output/wait exec output
  ]
  
  run-script: func [
    src [file!]
    /local 
     filename                     ;; filename of script 
     script                       ;; %runnable/filename
  ][
    src: replace/all src "%" ""
    if not filename: copy find/last/tail src "/" [filename: copy src]
    script: join base-dir [%tests/runnable/ filename]
    write to file! script read to file! src
    do script
  ]
  
  data: make object! [
    title: copy ""
    no-tests: 0
    passes: 0
    failures: 0
  ]
  
  file: make data []
  test-run: make data []
  
  assert: func [
    name [string!]
    assertion [logic!]
  ][
    file/no-tests: file/no-tests + 1
    either assertion [
      file/passes: file/passes + 1
    ][
      file/failures: file/failures + 1
      print ["***TEST" name "FAILED***"]
    ]
  ]
  
  _start: func [
    data [object!]
    type [string!]
    title [string!]
  ][
    print ["^/Start" type title]
    data/title: title
    data/no-tests: 0
    data/passes: 0
    data/failures: 0
  ]

  start-file: func [
    title [string!]
  ][
    _start file "file" title
  ]
  
  start-test-run: func [
    title [string!]
  ][
    _start test-run "test run" title
  ]
  
  _end: func [
    data [object!]
    type [string!]
  ][
    print ["End" type data/title]
    print ["No of tests" data/no-tests]
    print ["Passed     " data/passes]
    print ["Failed     " data/failures]
    if data/failures > 0 [print "***TEST FAILURES***"]
    print ""
  ]
  
  end-file: func [] [
    _end file "file"
    test-run/no-tests: test-run/no-tests + file/no-tests
    test-run/passes: test-run/passes + file/passes
    test-run/failures: test-run/failures + file/failures
  ]
  
  end-test-run: func [] [
      print ""
    _end test-run "test run"
  ]
    
]
