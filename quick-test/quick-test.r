REBOL [
  Title:   "Simple testing framework for Red and Red/System programs"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.r
	Version: 0.12.0
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

comment {
	This script makes some assumptions about the directory structure in which 
	files are stored. They are:
    	this script is stored in Red/quick-test/
    	the Red & Red/System compiler is stored in Red/
    	the default dir for tests is Red/system/tests/
    	
    	The default test dirs can be overriden by setting qt/tests-dir before
    	tests are processed
    	The default script header for code supplied as string is Red [], this 
    	can be overriden by setting qt/script-header
    	The default location of the compiler binary is Red/build/bin, this can
    	be overriden by setting qt/bin-compiler
}

qt: make object! [
  
  ;;;;;;;;;;; Setup ;;;;;;;;;;;;;;
  ;; set the base-dir to ....Red/
  base-dir: system/script/path
  base-dir: copy/part base-dir find base-dir "quick-test"
  ;; set the red/system runnable dir
  runnable-dir: dirize base-dir/quick-test/runnable
  ;; set the default base dir for tests
  tests-dir: dirize base-dir/system/tests
  
  ;; set the version number
  version: system/script/header/version
  
  ;; switch for binary compiler usage
  binary-compiler?: false

  ;; check if call-show? is enabled for call
  either any [
  		not value? 'call-show?
  		equal? call-show? 'wait
  	] [call-show?: 'wait] [call-show?: 'show]
  call*: to path! 'call
  append call* :call-show?
  append call* 'output
  
  ;; default binary compiler path
  bin-compiler: base-dir/build/bin/red
  
  ;; default script header to be inserted into code supplied in string form
  script-header: "Red []"
  
  ;; set temporary files names
  ;;  use Red/quick-test/runnable for temp files
  comp-echo: runnable-dir/comp-echo.txt
  comp-r: runnable-dir/comp.r
  test-src-file: runnable-dir/qt-test-comp.red
  
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
		do %../utils/call.r
		set 'call :win-call
	]
	
	;; script header parse rules - assumes parsing without /all
	red?: false
	red-header: ["red" any " " "[" to end (red?: true)]
	red-system-header: ["red/system" any " " "[" to end (red?: false)]
	red?-rule: [(red?: false) any [red-system-header | red-header | skip]]
	script-header-rule: [
		(no-script-header?: true) 
		any [ 
				[["red/system" | "red"] any " " "[" (no-script-header?: false)]
			|
				skip
		]
	]

	;;;;;;;;; End Setup ;;;;;;;;;;;;;;
  
  comp-output: copy ""                 ;; output captured from compile
  output: copy ""                      ;; output captured from pgm exec
  exe: none                            ;; filepath to executable
  source-file?: true                   ;; true = running  test file
                                       ;; false = runnning test script
				  

  summary-template: ".. - .................................................. / "
  
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
  		/bin
  		/lib
  	  		target [string!]	
  	  	/local
  	  		comp                          	;; compilation script
  	  		cmd                           	;; compilation cmd
  	  		exe								;; executable name
  ][
    clear comp-output
    
    ;; workout executable name
    either find/last/tail src "/" [
      exe: copy find/last/tail src "/"
    ][
      exe: copy src
    ]
    exe: copy/part exe find exe "."
    either lib [
      switch/default target [
        "Windows"	[exe: join exe [".dll"]]
        "Darwin"   	[exe: join exe [".dylib"]]
      ][
      	  exe: join exe [".so"]
      ]
      exe
    ][     
      if windows-os? [
        exe: join exe [".exe"]
      ]
    ]
    
    ;; find the path to the src
    if #"/" <> first src [src: tests-dir/:src]     ;; relative path supplied
    
    ;; red/system or red
    red?: false
    parse read src red?-rule
 
    ;; compose and write compilation script
    either binary-compiler? [
    	if #"/" <> first src [src: tests-dir/:src]     ;; relative path supplied
    	either lib [
    		cmd: join "" [to-local-file bin-compiler " -o " 
    					  to-local-file runnable-dir/:exe
    					  " -dlib -t " target " "
    					  to-local-file src
    		]
    	][
    		cmd: join "" [to-local-file bin-compiler " -o " 
    					  to-local-file runnable-dir/:exe " "
    					  to-local-file src	
    		]  		
    	]
    	comp-output: make string! 1024
    	do call* cmd comp-output
    ][
    	comp: mold compose/deep [
    	  REBOL []
    	  halt: :quit
    	  echo (comp-echo)
    	  do/args (reduce base-dir/red.r) (join " -o " [
    	  	  	  reduce runnable-dir/:exe " ###lib###***src***" 
    	  ])
    	  echo none
    	]
    	either lib [
    		replace comp "###lib###" join "-dlib -t " [target " "]
    	][
    		replace comp "###lib###" ""
    	]
    
    	replace comp "***src***"  clean-path src
    	write comp-r comp

    	;; compose command line and call it
    	cmd: join to-local-file system/options/boot [" -sc " comp-r]
    	do call* cmd make string! 1024	;; redirect output to anonymous
    											;; buffer
    ]
    
    ;; collect compiler output & tidy up
    if exists? comp-echo [
    	comp-output: read comp-echo
    	delete comp-echo
    ]
    if exists? comp-r [delete comp-r]
    recycle
    either compile-ok? [
      exe
    ][
      none
    ]    
  ]
  
  compile-and-run: func [src /error /pgm] [
    source-file?: true
    either exe: compile src [
      either error [
        run/error  exe
      ][
      	  either pgm [
      	  	  run/pgm exe
      	  ][
      	  	  run exe
      	  ]
      ]
    ][
      compile-error src
      output: "Compilation failed"
    ]
  ]
    
  compile-and-run-from-string: func [src /error] [
    source-file?: false
    either exe: compile-from-string src [
      either error [
        run/error  exe
      ][
        run exe
      ]
    ][
      
      compile-error "Supplied source"
      output: "Compilation failed"
    ]
  ]
  
  compile-dll: func [
    lib-src [file!]
    target	[string!]
    /local
    	dll
  ][
    ;; compile the lib into the runnable dir
    if not dll: compile/lib lib-src target [
      compile-error lib-src
      output: "Lib compilation failed"  
    ]
    dll
  ]
  
  compile-from-string: func [src][
    ;-- add a default header if not provided
    parse src script-header-rule
    if no-script-header? [
    	insert src join script-header "^/"
    ]
    write test-src-file src
    compile test-src-file                  ;; returns path to executable or none
  ]
  
  compile-error: func [
    src [file! string!]
  ][
    print join "^/" [src " - compiler error^/"]
    print comp-output
    print newline
    clear output                           ;; clear the output from previous test
    _signify-failure
  ]
  
  compile-ok?: func [] [
    either find comp-output "output file size :" [true] [false]
  ] 
  
  compile-run-print: func [src [file!] /error][
  	  either error [
  	  	  compile-and-run/error src
  	  ][
  	  	  compile-and-run src
    ]
    if output <> "Compilation failed" [print output]
  ]
  
  compiled?: func [
    src [string!]
  ][
    exe: compile-from-string src
    clean-compile-from-string
    qt/compile-ok?
  ]
  
  run: func [
    prog [file!]
    ;;/args                         ;; not yet needed
      ;;parms [string!]             ;; not yet needed
    /error                          ;; run time error expected
    /pgm							;; a program not a test
    /local
    exec [string!]                  ;; command to be executed
  ][
    exec: to-local-file runnable-dir/:prog
    ;;exec: join "" compose/deep [(exec either args [join " " parms] [""])]
    clear output
    do call* exec output
    ;;if all [red? windows-os?] [output: qt/utf-16le-to-utf-8 output]
    recycle
    if all [
      source-file?
      not pgm
      any [
      	  all [
      	   none <> find output "Runtime Error"
      	   not error
      	  ]
      	  none = find output "Passed"
      ]
    ][	
    print "signify failure"
      _signify-failure
    ]
  ]
  
  run-unit-test: func [
    src [file!]
    /local               
      cmd                             ;; command to run
      output
      test-name                     
  ][
    source-file?: false
    do join tests-dir src
  ]
  
  run-unit-test-quiet: func [
    src [file!]
    /local               
      cmd                             ;; command to run
      test-name                     
  ][
    file/reset
    source-file?: false
    test-name: find/last/tail src "/"
    test-name: copy/part test-name find test-name "."
    prin [ "running " test-name #"^(0D)"]
    clear output
    cmd: join to-local-file system/options/boot [" -sc " tests-dir src]
    do call* cmd output
    if find output "Error:" [_signify-failure]
    add-to-run-totals
    write/append log-file output
    file/title: test-name
    replace file/title "-test" ""
    _print-summary file
  ]
  
  run-script: func [
    src [file!]
    /local
     filename                     ;; filename of script 
     script                       ;; %runnable/filename
  ][
    if not filename: copy find/last/tail src "/" [filename: copy src]
    script: runnable-dir/:filename
    write to file! script read join tests-dir [src]
    if error? try [do script] [_signify-failure]
  ]
  
  run-script-quiet: func [
  	src [file!]
  ][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-script src
    add-to-run-totals
    print: :_save-print
    write/append log-file print-output
    _print-summary file
  ]
  
  run-test-file: func [
  	src [file!]
  ][
    file/reset
    unless file/title: find/last/tail to string! src "/" [file/title: src]
    replace file/title "-test.reds" ""
    replace file/title "-test.red" ""
    compile-run-print src
    add-to-run-totals
  ]
  
  run-test-file-quiet: func [
  	src [file!]
  	][
    prin [ "running " find/last/tail src "/" #"^(0D)"]
    print: :_quiet-print
    print-output: copy ""
    run-test-file src
    print: :_save-print
    write/append log-file print-output
    _print-summary file
    output: copy ""
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
    write log-file rejoin ["***Starting*** " title newline]
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
  
  assert-printed?: func [msg] [
    assert found? find qt/output msg
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
  
  make-if-needed?: func [
    {This function is used by the Red run-all scripts to build the auto files
     when necessary.} 
    auto-test-file [file!]
    make-file [file!]
    /lib-test
    /local
      stored-length   ; the length of the make... .r file used to build auto tests
      stored-file-length
      digit
      number
      rule
  ][
    auto-test-file: join tests-dir auto-test-file
    make-file: join tests-dir make-file
    
    stored-file-length: does [
      parse/all read auto-test-file rule
      stored-length
    ]
    digit: charset [#"0" - #"9"]
    number: [some digit]
    rule: [
      thru ";make-length:" 
      copy stored-length number (stored-length: to integer! stored-length)
      to end
    ]
    
    if not exists? make-file [return]
   
    if any [
      not exists? auto-test-file
      stored-file-length <> length? read make-file
      0:00 < difference modified? make-file modified? auto-test-file
    ][
      print ["Making" auto-test-file " - it will take a while"]
      do make-file
    ]
  ]
  
  setup-temp-files: func [
  	  /local
  	  	f
  ][
  	foreach file read runnable-dir [attempt [delete runnable-dir/:file]]
  	
  	f: to string! now/time/precise
  	f: replace/all f ":" ""
  	f: replace/all f "." ""
    comp-echo: join runnable-dir ["comp-echo" f ".txt"]
  	comp-r: join runnable-dir ["comp" f ".r"]
  	test-src-file: join runnable-dir ["qt-test-comp" f ".red"]
  ]
  
  delete-temp-files: does [
  	  if exists? comp-echo [delete comp-echo]
  	  if exists? comp-r [delete comp-r]
  	  if exists? test-src-file [delete test-src-file]  
  ]
  
  seperate-log-file: func [
  	  /local
  	  	f
  ][
  	f: to string! now/time/precise
  	f: replace/all f ":" ""
  	f: replace/all f "." ""
    log-file: join base-dir ["quick-test/quick-test" f ".log"]
  ]
  
  utf-16le-to-utf-8: func [
    {Translates a utf-16LE encoded string to an utf-8 encoded one
     the algorithm is copied from lexer.r                         }
    in-str [string!]
    /local
      out-str
      code
  ][
   out-str: copy ""
   foreach [low high] to binary! in-str [
     code: high * 256 + low
     case [
       code <= 127  [
         append out-str to char! code					            ;-- c <= 7Fh
       ]
       code <= 2047 [							                        ;-- c <= 07FFh
         append out-str join "" [ 
           to char! ((shift code 6) and #"^(1F)" or #"^(C0)")
					 to char! ((code and #"^(3F)") or #"^(80)")
				 ]
			 ]
			 code <= 65535 [					                         		;-- c <= FFFFh
			   append out-str join "" [
			     to char! ((shift code 12) and #"^(0F)" or #"^(E0)")
			     to char! ((shift code 6) and #"^(3F)" or #"^(80)")
			     to char! (code and #"^(3F)" or #"^(80)")
			   ]
			 ]
			 code <= 1114111 [						                        ;-- c <= 10FFFFh
			   append out-str join "" [
			     to char! ((shift code 18) & ^"(07)" or #"^(F0)")
					 to char! ((shift code 12) and #"^(3F)" or #"^(80)")
					 to char! ((shift code 6)  and #"^(3F)" or #"^(80)")
					 to char! (code and #"^(3F)" or #"^(80)")
				 ]
			 ]                         ;-- Codepoints above U+10FFFF are ignored"
		 ]
	 ]
   out-str 
  ]
  
  ;; create the test "dialect"
  
  set '***start-run***              :start-test-run
  set '***start-run-quiet***        :start-test-run-quiet
  set '~~~start-file~~~             :start-file
  set '===start-group===            :start-group
  set '--test--                     :start-test
  set '--compile                    :compile
  set '--compile-red                :compile
  set '--compile-dll          		:compile-dll
  set '--compile-this               :compile-from-string
  set '--compile-this-red           :compile-from-string
  set '--compile-and-run            :compile-and-run
  set '--compile-and-run-red        :compile-and-run 
  set '--compile-and-run-this       :compile-and-run-from-string
  set '--compile-and-run-this-red   :compile-and-run-from-string
  set '--compile-run-print          :compile-run-print
  set '--compile-run-print-red      :compile-run-print
  set '--compiled?                  :compiled?
  set '--run                        :run
  set '--add-to-run-totals          :add-to-run-totals
  set '--run-unit-test              :run-unit-test
  set '--run-unit-test-quiet        :run-unit-test-quiet
  set '--run-script                 :run-script
  set '--run-script-quiet           :run-script-quiet
  set '--run-test-file              :run-test-file
  set '--run-test-file-red          :run-test-file
  set '--run-test-file-quiet        :run-test-file-quiet
  set '--run-test-file-quiet-red    :run-test-file-quiet
  set '--assert                     :assert
  set '--assert-msg?                :assert-msg?
  set '--assert-printed?            :assert-printed?
  set '--assert-red-printed?        :assert-printed?
  set '--clean                      :clean-compile-from-string
  set '===end-group===              :end-group
  set '~~~end-file~~~               :end-file
  set '***end-run***                :end-test-run
  set '***end-run-quiet***          :end-test-run-quiet
  set '--setup-temp-files			:setup-temp-files
  set '--delete-temp-files			:delete-temp-files
  set '--seperate-log-file			:seperate-log-file	
]
