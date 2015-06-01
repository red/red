REBOL [
  Title:        "Emit Red/System api to html"
	Author:       "Peter W A Wood"
	File: 	      %emit-block.r
	Version:      0.1.0
	Rights:       "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License:      "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Description:  {This is a plug for generate-reds-api.r which emits the input block }  
	Argument:     {A block output by xtract/extract-reds-docstrings}
]

emit: func [
  docstrings  [block!]
][
  docstrings
]
