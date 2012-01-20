REBOL [
  Title:   "Simple testing framework for Red/System programs"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.r
	Version: 0.7.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

comment {
  This script makes some assumptions about the directory structure in which 
  files are stored. They are:
    this script is stored in Red/quick-test
    the Red/System compiler is stored in Red/red-system
    the compiler must be run from Red/red-system
    the compiler writes the executable to Red/red-system/builds
    the default "base" dir for tests is Red/red-system/tests
    
 The default "base" test dir can be overriden by setting qt/tests-dir before
 any tests are processed
}

qt: make object! [
  
  ;;;;;;;;;;; Setup ;;;;;;;;;;;;;;
  ;; set the base-dir to ....Red
  base-dir: system/script/path 
  base-dir: copy/part base-dir find base-dir "quick-test"
  ;; set the red/system compiler directory
  comp-dir: join base-dir "red-system/"
  ;; set the red/system runnable dir
  runnable-dir: join comp-dir "tests/runnable/"
  ;; set the builds dir
  builds-dir: join comp-dir "builds/"
  ;; set the default base dir for tests
  tests-dir: join comp-dir "tests/"
  
  ;; set the version number
  version: system/script/header/version
  
  ;; set temporary files names
  ;;  use Red/red-system/runnable for temp files
  comp-echo: join runnable-dir %comp-echo.txt
  comp-r: join runnable-dir %comp.r
  test-src-file: join %runnable/ "qt-test-comp.reds"
  
  ;; set log file 
  log-file: join system/script/path "quick-test.log"

  ;; make runnable directory if needed
  make-dir runnable-dir
  
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
  
  summary-template: ".. - .................................... / "
  
  data: make object! [
    title: copy ""
    no-tests: 0
    no-asserts: 0
    passes: 0
    failures: 0
    reset: does [
      title: copy ""
      no-tests: 0
      no-asserts: 0
      passes: 0
      failures: 0
    ]
  ]
  
  file: make data []
  test-run: make data []
  _add-file-to-run-totals: does [
    test-run/no-tests: test-run/no-tests + file/no-tests
    test-run/no-asserts: test-run/no-asserts + file/no-asserts
    test-run/passes: test-run/passes + file/passes
    test-run/failures: test-run/failures + file/failures
  ]
  _signify-failure: does [
    ;; called when a compiler or runtime error occurs
    file/failures: file/failures + 1           
    file/no-tests: file/no-tests + 1
    file/no-asserts: file/no-asserts + 1
    test-run/failures: test-run/failures + 1           
    test-run/no-tests: test-run/no-tests + 1
    test-run/no-asserts: test-run/no-asserts + 1
  ]
  
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
  
  ;; print diversion function
  _save-print: :print
  print-output: copy ""
  _quiet-print: func [val] [
    append print-output join "" [reduce val "^/"]
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
    comp: mold compose [
      REBOL []
      halt: :quit
      change-dir (comp-dir)
      echo (comp-echo)
      do/args %rsc.r "***src***"
    ]
    replace comp "***src***" join tests-dir src
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
    built: join builds-dir [exe]
    runner: join runnable-dir [exe]
    
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
      output: "Compilation failed"
    ]
  ]
    
  compile-and-run-from-string: func [src] [
    either exe: compile-from-string src [
      run exe
    ][
      compile-error "Supplied source"
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
    src [file! string!]
  ][
    print join "" [src " - compiler error"]
    print comp-output
    _signify-failure
  ]
  
  compile-ok?: func [] [
    either find comp-output "output file size:" [true] [false]
  ] 
  
  compile-run-print: func [src [file!]][
    compile-and-run src
    if output <> "Compilation failed" [print output]
  ]
  
  run: func [
    prog [file!]
    ;;/args                         ;; not yet needed
      ;;parms [string!]             ;; not yet needed  
    /local
    exec [string!]                   ;; command to be executed
  ][
    exec: to-local-file join runnable-dir [prog]
    ;;exec: join "" compose/deep [(exec either args [join " " parms] [""])]
    clear output
    call/output/wait exec output
    if none <> find output "Runtime Error" [
      _signify-failure
    ]
  ]
  
  run-red-test-quiet: func [
    src [file!]
    /local               
      cmd                             ;; command to run
      test-name                     
  ][
    test-name: find/last/tail src "/"
    test-name: copy/part test-name find test-name "."
    print [ "running " test-name #"^(0D)"]
    clear output
    cmd: join to-local-file system/options/boot [" -sc " tests-dir src]
    call/output/wait cmd output
    add-to-run-totals
    write/append log-file output
    file/title: test-name
    _print-summary file
  ]
  
  run-script: func [
    src [file!]
    /local 
     filename                     ;; filename of script 
     script                       ;; %runnable/filename
  ][
    src: replace/all src "%" ""
    if not filename: copy find/last/tail src "/" [filename: copy src]
    script: join runnable-dir [filename]
    print "tests-dir"
    write to file! script read join tests-dir [src]
    do script
  ]
  
  ;; This is for the temporary version of quick-test.red (in REBOL)
  run-script-quiet: func [src [file!]][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-script src
    add-to-run-totals
    print: :_save-print
    write/append log-file print-output
    _print-summary file
  ]
  
  run-test-file: func [src [file!]][
    file/reset
    file/title: find/last/tail to string! src "/"
    replace file/title "-test.reds" ""
    compile-run-print src
    add-to-run-totals
  ]
  
  run-test-file-quiet: func [src [file!]][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-test-file src
    print: :_save-print
    write/append log-file print-output
    _print-summary file
  ]
  
  add-to-run-totals: func [
    /local
      tests
      asserts
      passes
      failures
      rule
      digit
      number
  ][
    digit: charset [#"0" - #"9"]
    number: [some digit]
    ws: charset [#"^-" #"^/" #" "]
    whitespace: [some ws]
    rule: [
      thru "Number of Tests Performed:" whitespace copy tests number
      thru "Number of Assertions Performed:" whitespace copy asserts number
      thru "Number of Assertions Passed:" whitespace copy passed number
      thru "Number of Assertions Failed:" whitespace copy failures number
      to end
    ]
    if parse/all output rule [
      file/no-tests: file/no-tests + to integer! tests
      file/no-asserts: file/no-asserts + to integer! asserts
      file/passes: file/passes + to integer! passed
      file/failures: file/failures + to integer! failures
      _add-file-to-run-totals
    ]
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
    prin newline
  ]
  
  start-test-run-quiet: func [
    title [string!]
      ][
    _start test-run "" title
    prin newline
    write log-file rejoin ["***Starting***" title newline]
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
    _add-file-to-run-totals
  ]
  
  end-test-run: func [] [
      print ""
    _end test-run "***Finished***"
  ]
  
  end-test-run-quiet: func [] [
    print: :_quiet-print
    print-output: copy ""
    end-test-run
    print: :_save-print
    write/append log-file print-output
    prin newline
    _print-summary test-run
  ]
  
  _print-summary: func [
    data [object!]
    /local
      print-line
  ][
    print-line: copy summary-template
    print-line: skip print-line 5
    remove/part print-line length? data/title
    insert print-line data/title
    print-line: skip tail print-line negate (3 + length? mold data/passes)
    remove/part print-line length? mold data/passes
    insert print-line data/passes
    append print-line data/no-asserts
    print-line: head print-line
    either data/no-asserts = data/passes [
      replace print-line ".." "ok"
    ][
      replace/all print-line "." "*"
      append print-line " **"
    ]
    print print-line
]
  
  ;; create the test "dialect"
  
  set '***start-run***        :start-test-run
  set '***start-run-quiet***  :start-test-run-quiet
  set '~~~start-file~~~       :start-file
  set '===start-group===      :start-group
  set '--test--               :start-test
  set '--compile              :compile
  set '--compile-this         :compile-from-string
  set '--compile-and-run      :compile-and-run
  set '--compile-and-run-this :compile-and-run-from-string
  set '--compile-run-print    :compile-run-print
  set '--run                  :run
  set '--add-to-run-totals    :add-to-run-totals
  set '--run-red-test-quiet   :run-red-test-quiet
  set '--run-script           :run-script
  set '--run-script-quiet     :run-script-quiet
  set '--run-test-file        :run-test-file
  set '--run-test-file-quiet  :run-test-file-quiet
  set '--assert               :assert
  set '--assert-msg?          :assert-msg?
  set '--clean                :clean-compile-from-string
  set '===end-group===        :end-group
  set '~~~end-file~~~         :end-file
  set '***end-run***          :end-test-run
  set '***end-run-quiet***    :end-test-run-quiet
]
