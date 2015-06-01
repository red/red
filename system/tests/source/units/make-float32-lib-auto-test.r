REBOL [
  Title:   "Generates Red/System lib tests (float32 version)"
	Author:  "Peter W A Wood"
	File: 	 %make-float32-lib-auto-test.r
	Version: 0.2.0
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; initialisations 
make-dir %auto-tests/
file-out: %auto-tests/float32-lib-auto-test.reds
file-in: %float32-lib-test-source.reds

;; get base dir address 
base-dir: to-local-file system/script/path  

;; work out prefix and extension based on version
switch/default fourth system/version [
  2 [
    abs-path: join "" [base-dir "/libs/"]
    prefix: "lib"
    ext: ".dylib"
  ]
  3 [
    abs-path: join "" [base-dir "\libs\"]
    prefix: ""
    ext: ".dll"
  ]
][                                    ;; default to libxxx.so
    abs-path: join "" [base-dir "/libs/"]
    prefix: "lib"
    ext: ".so"
]

;; read the file, insert the absolute path and file prefix and extension
src: read file-in
replace/all src "***abs-path***" abs-path
replace/all src "###prefix###" prefix
replace/all src "@@@extension@@@" ext

write file-out src









