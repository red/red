REBOL [
  Title:        "Emit Red/System api to html"
	Author:       "Peter W A Wood"
	File: 	      %emit-reds-api-html.r
	Version:      0.1.0
	Rights:       "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License:      "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Description:  {This is a plug for generate-reds-api.r which emits HTML }  
	Argument:     {A block output by xtract/extract-reds-docstrings}
]

emit: func [
  docstrings  [block!]
  /local
    doc
][
  doc: copy ""
  append doc join {<h1>} [docstrings/title {</h1>}]
  docstrings: skip docstrings 2
  foreach file docstrings [
    append doc join {<h2 class="file" id ="} [file/file {">} file/file "</h2>"]
    header: make object! file/header
    if in header 'title [
      append doc rejoin [{<p class="header">Title } header/title {</p>}]
    ]
    if in header 'purpose [
      append doc rejoin [{<p class="header">Purpose } header/purpose {</p>}]
    ] 
    append doc {<h3>Functions</h3>}
    foreach funct file/functions [
      append doc rejoin [
        {<h4 class="func" id="} funct/func {">Function: } funct/func 
        {</h4><h5>Description</h5><p class="description">} funct/3 {</p>} 
      ]
      append doc {<h5>Returns</h5>}
      either ret-blk: select funct 'return [
        append doc rejoin [{<p class="return">} first ret-blk " " second ret-blk {</p>}]
      ][
        append doc {<p>No return value</p>}    
      ]
      append doc {<h5>Arguments</h5>}
      funct: skip funct 3
      foreach arg-blk funct [
        if arg-blk = 'return [break]
        append doc rejoin [
          {<p class="argument">} arg-blk/1 " " arg-blk/2 " " arg-blk/3 {</p>}
        ]
      ]
    ]
    append doc {<h3>Includes</h3>}
      
      foreach inc file/includes [
        append doc rejoin [{<p class="include">} inc {</p>}]
      ]
  ] 
  append doc rejoin [{<p>Created at } now {</p>}]
  doc
]
