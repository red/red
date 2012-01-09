REBOL [
  Title:   "Generates Red/System lib tests (float version)"
	Author:  "Peter W A Wood"
	File: 	 %make-float-lib-auto-test.r
	Version: 0.1.1
	Rights:  "Copyright (C) 2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; initialisations 
make-dir %auto-tests/
file-out: %auto-tests/float-lib-auto-test.reds
file-in: %float-lib-test-source.reds

;; get base dir address 
base-dir: to-local-file system/script/path  

;; set the absolute path to the libs
switch/default fourth system/version [
  3 [
    abs-path: join "" [base-dir "\libs\"]
  ]
][                                    
    abs-path: join "" [base-dir "/libs/"]
]

;; read the file, insert the absolute path to the library
src: read file-in
replace/all src "***abs-path***" abs-path
write file-out src









