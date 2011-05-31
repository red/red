Red/System [
  Title:   "Overwrite the contents of a c-string"
	Author:  "Peter W A Wood"
	File: 	 %overwrite.reds
	Rights:  copyright (c) 2011 Peter W A Wood
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

overwrite: func [
  target [c-string!]
  src [c-string!]
  max-len [integer!]
  /local
  c [integer!]
][
  c: 0
  until [
    c: c + 1
    target/c: src/c
    if target/c = null-char [exit]
    c = max-len 
  ]
]
  






