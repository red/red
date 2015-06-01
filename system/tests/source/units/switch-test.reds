Red/System [
	Title:   "Red/System switch function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %switch-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015, Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "switch"

===start-group=== "switch basics"

	--test-- "switch-basic-1"
	ci: 0
	cia: 1
	switch ci [0 [] default [0]]
	--assert cia = 1
	
	--test-- "switch-basic-2"
	ci: 1
	cia: 2
	switch ci [1 [cia: 2]]
	--assert cia = 2
	
	--test-- "switch-basic-3"
	ci: 1
	cia: 2
	switch ci [0 [] default [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-4"
	ci: 0
	cia: 2
	switch ci [1 [cia: 0] default [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-5"
	ci: 99
	cia: 2
	switch ci [1 [cia: 2] default [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-6"
	ci: 0
	cia: 1
	cia: switch ci [1 [0] default [2]]
	--assert cia = 2
	
	--test-- "switch-basic-7"
	ci: 1
	cia: 2
	cia: switch ci [1 [3]]
	--assert cia = 3
	
	--test-- "switch-basic-8"
	ci: 8
	cia: 2
	switch ci [8 [switch ci [8 [cia: 3] default [cia: 4]]]]
	--assert cia = 3
	
	--test-- "switch-basic-9"
	ci:  1
	cia: 2
	cia: switch ci [1 [switch ci [1 [3] default [4]]]]
	--assert cia = 3
	
	--test-- "switch-basic-10"
	ci:  8
	cia: 2
	cia: switch ci [8 [case [ci = 8 [3] true [4]]]]
	--assert cia = 3
	
	--test-- "switch-basic-11"
	ci:  1
	cia: 0
	switch ci [1 2 [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-12"
	ci:  2
	cia: 0
	switch ci [1 2 [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-13"
	ci:  8
	cia: 0
	switch ci [1 2 [cia: 0] default [cia: 3]]
	--assert cia = 3
	
	--test-- "switch-basic-14"
	ci:  1
	cia: 0
	cia: switch ci [1 2 [3]]
	--assert cia = 3

	--test-- "switch-basic-15"
	ci:  2
	cia: 0
	cia: switch ci [1 2 [3]]
	--assert cia = 3

	--test-- "switch-basic-16"
	ci:  8
	cia: 0
	cia: switch ci [1 2 [0] default [3]]
	--assert cia = 3

	--test-- "switch-basic-17"
	ci:  2
	cia: 0
	cia: switch ci [1 2 [3] 4 5 [0]]
	--assert cia = 3
	
	--test-- "switch-basic-18"
	ci:  4
	cia: 0
	cia: switch ci [1 2 [0] 4 5 [3]]
	--assert cia = 3
	
	--test-- "switch-basic-19"
	ci:  1
	cia: 0
	cia: switch ci [#"^(01)" 2 [3] 4 #"^(05)" [0]]
	--assert cia = 3

	--test-- "switch-basic-20"
	ci:  5
	cia: 0
	cia: switch ci [#"^(01)" 2 [0] 4 #"^(05)" [3]]
	--assert cia = 3
	
	--test-- "switch-basic-21"
	ci:  2
	cia: 0
	cia: switch ci [#"^(01)" 2 [3] 4 #"^(05)" [0]]
	--assert cia = 3

	--test-- "switch-basic-22"
	ci:  4
	cia: 0
	cia: switch ci [#"^(01)" 2 [0] 4 #"^(05)" [3]]
	--assert cia = 3
	
===end-group===

===start-group=== "switch basics local"

	switch-fun: func [/local ci cia][
		--test-- "switch-loc-1"
		ci: 0
		cia: 1
		switch ci [0 [] default [0]]
		--assert cia = 1

		--test-- "switch-loc-2"
		ci: 1
		cia: 2
		switch ci [1 [cia: 2]]
		--assert cia = 2

		--test-- "switch-loc-3"
		ci: 1
		cia: 2
		switch ci [0 [] default [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-4"
		ci: 0
		cia: 2
		switch ci [1 [cia: 0] default [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-5"
		ci: 99
		cia: 2
		switch ci [1 [cia: 2] default [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-6"
		ci: 0
		cia: 1
		cia: switch ci [1 [0] default [2]]
		--assert cia = 2

		--test-- "switch-loc-7"
		ci: 1
		cia: 2
		cia: switch ci [1 [3]]
		--assert cia = 3

		--test-- "switch-loc-8"
		ci: 8
		cia: 2
		switch ci [8 [switch ci [8 [cia: 3] default [cia: 4]]]]
		--assert cia = 3

		--test-- "switch-loc-9"
		ci:  1
		cia: 2
		cia: switch ci [1 [switch ci [1 [3] default [4]]]]
		--assert cia = 3

		--test-- "switch-loc-10"
		ci:  8
		cia: 2
		cia: switch ci [8 [case [ci = 8 [3] true [4]]]]
		--assert cia = 3

		--test-- "switch-loc-11"
		ci:  1
		cia: 0
		switch ci [1 2 [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-12"
		ci:  2
		cia: 0
		switch ci [1 2 [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-13"
		ci:  8
		cia: 0
		switch ci [1 2 [cia: 0] default [cia: 3]]
		--assert cia = 3

		--test-- "switch-loc-14"
		ci:  1
		cia: 0
		cia: switch ci [1 2 [3]]
		--assert cia = 3

		--test-- "switch-loc-15"
		ci:  2
		cia: 0
		cia: switch ci [1 2 [3]]
		--assert cia = 3

		--test-- "switch-loc-16"
		ci:  8
		cia: 0
		cia: switch ci [1 2 [0] default [3]]
		--assert cia = 3

		--test-- "switch-loc-17"
		ci:  2
		cia: 0
		cia: switch ci [1 2 [3] 4 5 [0]]
		--assert cia = 3

		--test-- "switch-loc-18"
		ci:  4
		cia: 0
		cia: switch ci [1 2 [0] 4 5 [3]]
		--assert cia = 3

		--test-- "switch-loc-19"
		ci:  1
		cia: 0
		cia: switch ci [#"^(01)" 2 [3] 4 #"^(05)" [0]]
		--assert cia = 3

		--test-- "switch-loc-20"
		ci:  5
		cia: 0
		cia: switch ci [#"^(01)" 2 [0] 4 #"^(05)" [3]]
		--assert cia = 3

		--test-- "switch-loc-21"
		ci:  2
		cia: 0
		cia: switch ci [#"^(01)" 2 [3] 4 #"^(05)" [0]]
		--assert cia = 3

		--test-- "switch-loc-22"
		ci:  4
		cia: 0
		cia: switch ci [#"^(01)" 2 [0] 4 #"^(05)" [3]]
		--assert cia = 3
	]
	switch-fun
	
===end-group===

===start-group=== "switch integer!"
	
#define switch-int-1 [switch ci [ 1 [cia: 1] 2 [cia: 2] default [cia: 3]]]

	--test-- "switch-int-1"
	  ci: 1
	  cia: 0
	  switch-int-1
	--assert 1 = cia
	
	--test-- "switch-int-2"
	  ci: 2
	  cia: 0
	  switch-int-1
	--assert 2 = cia
	
	--test-- "switch-int-3"
	  ci: 3
	  cia: 0
	  switch-int-1
	--assert 3 = cia
	
	--test-- "switch-int-4"
	  ci: 9
	  cia: 0
	  switch-int-1
	--assert 3 = cia
	
	#define switch-int-2 [switch ci [1 [1] 2 [2] default [3]]]

	--test-- "switch-int-5"
	  ci: 1
	--assert 1 = switch-int-2

	--test-- "switch-int-6"
	  ci: 1
	  cres: switch-int-2
	--assert 1 = cres
	
	--test-- "switch-int-7"
	  ci: 2
	--assert 2 = switch-int-2
		
	--test-- "switch-int-8"
	  ci: 2
	  cres: switch-int-2
	--assert 2 = cres

	--test-- "switch-int-9"
	  ci: 3
	--assert 3 = switch-int-2
	
	--test-- "switch-int-10"
	  ci: 3
	  cres: switch-int-2
	--assert 3 = cres
	
	--test-- "switch-int-11"
	  ci: 10
	--assert 3 = switch-int-2
	
	--test-- "switch-int-12"
	  ci: 10
	  cres: switch-int-2
	--assert 3 = cres

	#define switch-int-3 [switch ci [1 [cia: 1] 2 [cia: 2] default [cia: 3]] ]

	--test-- "switch-int-13"
	  ci: 1
	  cia: 0
	--assert 1 = switch-int-3
	
	--test-- "switch-int-14"
	  ci: 1
	  cia: 0
	  cres: switch-int-3
	--assert 1 = cres
	
	--test-- "switch-int-15"
	  ci: 2
	  cia: 0
	--assert 2 = switch-int-3
	
	--test-- "switch-int-16"
	  ci: 2
	  cia: 0
	  cres: switch-int-3
	--assert 2 = cres
	
	--test-- "switch-int-17"
	  ci: 3
	  cia: 0
	--assert 3 = switch-int-3
	
	--test-- "switch-int-18"
	  ci: 3
	  cia: 0
	  cres: switch-int-3
	--assert 3 = cres
	
	--test-- "switch-int-19"
	  ci: 9
	  cia: 0
	--assert 3 = switch-int-3
	
	--test-- "switch-int-20"
	  ci: 9
	  cia: 0
	  cres: switch-int-3
	--assert 3 = cres
	
===end-group===

===start-group=== "switch byte!"
	
#define switch-byte-1 [switch cb [#"1" [cba: #"1"] #"2" [cba: #"2"] default [cba: #"3"]]]

	--test-- "switch-byte-1"
	  cb: #"1"
	  cba: #"0"
	  switch-byte-1
	--assert #"1" = cba
	
	--test-- "switch-byte-2"
	  cb: #"2"
	  cba: #"0"
	  switch-byte-1
	--assert #"2" = cba
	
	--test-- "switch-byte-3"
	  cb: #"3"
	  cba: #"0"
	  switch-byte-1
	--assert #"3" = cba
	
	--test-- "switch-byte-4"
	  cb: #"9"
	  cba: #"0"
	  switch-byte-1
	--assert #"3" = cba
	
	#define switch-byte-2 [switch cb [#"1" [#"1"] #"2" [#"2"] default [#"3"]]]

	--test-- "switch-byte-5"
	  cb: #"1"
	--assert #"1" = switch-byte-2

	--test-- "switch-byte-6"
	  cb: #"1"
	  cbres: switch-byte-2
	--assert #"1" = cbres
	
	--test-- "switch-byte-7"
	  cb: #"2"
	--assert #"2" = switch-byte-2
		
	--test-- "switch-byte-8"
	  cb: #"2"
	  cbres: switch-byte-2
	--assert #"2" = cbres

	--test-- "switch-byte-9"
	  cb: #"3"
	--assert #"3" = switch-byte-2
	
	--test-- "switch-byte-10"
	  cb: #"3"
	  cbres: switch-byte-2
	--assert #"3" = cbres
	
	--test-- "switch-byte-11"
	  cb: #"9"
	--assert #"3" = switch-byte-2
	
	--test-- "switch-byte-12"
	  cb: #"9"
	  cbres: switch-byte-2
	--assert #"3" = cbres

	#define switch-byte-3 [switch cb [#"1" [cba: #"1"] #"2" [cba: #"2"] default [cba: #"3"]] ]

	--test-- "switch-byte-13"
	  cb: #"1"
	  cba: #"0"
	--assert #"1" = switch-byte-3
	
	--test-- "switch-byte-14"
	  cb: #"1"
	  cba: #"0"
	  cbres: switch-byte-3
	--assert #"1" = cbres
	
	--test-- "switch-byte-15"
	  cb: #"2"
	  cba: #"0"
	--assert #"2" = switch-byte-3
	
	--test-- "switch-byte-16"
	  cb: #"2"
	  cba: #"0"
	  cbres: switch-byte-3
	--assert #"2" = cbres
	
	--test-- "switch-byte-17"
	  cb: #"3"
	  cba: #"0"
	--assert #"3" = switch-byte-3
	
	--test-- "switch-byte-18"
	  cb: #"3"
	  cba: #"0"
	  cbres: switch-byte-3
	--assert #"3" = cbres
	
	--test-- "switch-byte-19"
	  cb: #"9"
	  cba: #"0"
	--assert #"3" = switch-byte-3
	
	--test-- "switch-byte-20"
	  cb: #"9"
	  cba: #"0"
	  cbres: switch-byte-3
	--assert #"3" = cbres
	
===end-group===

===start-group=== "switch-until"
  --test-- "switch-until-1"           ;; Issue #198
    sui: 1
    sur: 0
    su-end: true
    switch sui [
      0 [sur: 1] 
      2 [sur: 2]
      default [
        until [
          sur: 3
          su-end
        ]
      ]
    ]
  --assert sur = 3

===end-group===


~~~end-file~~~

