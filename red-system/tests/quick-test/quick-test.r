REBOL [
  Title:   "Simple testing framework for Red/System programs"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.r
	Version: 0.3.2
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
  test-src-file: %runnable/qt-test-comp.reds

  ;; make runnable directory if needed
  make-dir join base-dir %tests/runnable/
  
  ;; windows ?
  windows-os?: system/version/4 = 3
  
  ;; use Cheyenne call with REBOL v2.7.8 on Windows (re: 'call bug on Windows 7)
  if all [
    windows-os?
    system/version/3 = 8              
  ][
		do %call.r					               
		set 'call :win-call
	]
  ;;;;;;;;;;; End Setup ;;;;;;;;;;;;;;
  
  comp-output: copy ""                 ;; output captured from compile
  output: copy ""                      ;; output captured from pgm exec
  exe: none                            ;; filepath to executable
  
  data: make object! [
    title: copy ""
    no-tests: 0
    no-asserts: 0
    passes: 0
    failures: 0
  ]
  
  file: make data []
  test-run: make data []
  
  ;; group data
  group-name: copy ""
  group?: false
  group-name-not-printed: true
  _init-group: does [
    group?: false
    group-name-not-printed: true
    group-name: copy ""
  ]
  
  ;; test data
  test-name: copy ""
  _init-test: does [
    test-name: copy ""
  ]
  
  compile: func [
    src [file!]
    /local
      comp                          ;; compilation script
      cmd                           ;; compilation cmd
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
    call/wait/output cmd make string! 1024	;; redirect output to anonymous buffer
    
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
  
  compile-and-run: func [src] [
    either exe: compile src [
      run exe
    ][
      compile-error src
      output: none
    ]
  ]
    
  compile-and-run-from-string: func [src] [
    either exe: compile-from-string src [
      run exe
    ][
      compile-error src
      output: "Compilation failed"
    ]
  ]
    
  compile-from-string: func [src][
    ;-- add a default header if not provided
    if none = find src "Red/System" [insert src "Red/System []^/"]
    
    write test-src-file src
    compile test-src-file                  ;; returns path to executable or none
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
  
  _start: func [
    data [object!]
    leader [string!]
    title [string!]
  ][
    print [leader title]
    data/title: title
    data/no-tests: 0
    data/no-asserts: 0
    data/passes: 0
    data/failures: 0
    _init-group
  ]

  start-test-run: func [
    title [string!]
  ][
    _start test-run "***Starting***" title
  ]
  
  start-file: func [
    title [string!]
  ][
    _start file "~~~started test~~~" title
  ]
  
  start-group: func[
    title [string!]
  ][
   group-name: title
   group?: true
  ]
  
  start-test: func[
    title [string!]
  ][
    _init-test
    test-name: title
    file/no-tests: file/no-tests + 1
  ]
    
  assert: func [
    assertion [logic!]
  ][
    file/no-asserts: file/no-asserts + 1
    either assertion [
      file/passes: file/passes + 1
    ][
      file/failures: file/failures + 1
      if group? [
        if group-name-not-printed [
          print ""
          print ["===group===" group-name]
        ]
      ]
      print ["---test---" test-name "FAILED**************"]
    ]
  ]
  
  assert-msg?: func [msg][
    assert found? find qt/comp-output msg
  ]
  
  clean-compile-from-string: does [
    if exists? test-src-file [delete test-src-file]
    if all [exe exists? exe][delete exe]
]
  
  end-group: does [
    _init-group
  ]
  
  _end: func [
    data [object!]
    leader [string!]
  ][
    print [leader data/title]
    print ["No of tests  " data/no-tests]
    print ["No of asserts" data/no-asserts]
    print ["Passed       " data/passes]
    print ["Failed       " data/failures]
    if data/failures > 0 [print "***TEST FAILURES***"]
    print ""
  ]
  
  end-file: func [] [
    _end file "~~~finished test~~~" 
    test-run/no-tests: test-run/no-tests + file/no-tests
    test-run/no-asserts: test-run/no-asserts + file/no-asserts
    test-run/passes: test-run/passes + file/passes
    test-run/failures: test-run/failures + file/failures
  ]
  
  end-test-run: func [] [
      print ""
    _end test-run "***Finished***"
  ]
  
  ;; create the test "dialect"
  
  set '***start-run***        :start-test-run
  set '~~~start-file~~~       :start-file
  set '===start-group===      :start-group
  set '--test--               :start-test
  set '--compile              :compile
  set '--compile-this         :compile-from-string
  set '--compile-and-run      :compile-and-run
  set '--compile-and-run-this :compile-and-run-from-string
  set '--run                  :run
  set '--run-script           :run-script
  set '--assert               :assert
  set '--assert-msg?          :assert-msg?
  set '--clean                :clean-compile-from-string
  set '===end-group===        :end-group
  set '~~~end-file~~~         :end-file
  set '***end-run***          :end-test-run
    
]
