REBOL [
  Title:        "Emit Red/System api to makedoc2"
	Author:       "Peter W A Wood"
	File: 	      %emit-reds-api-md2.r
	Version:      0.1.0
	Rights:       "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License:      "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Description:  {This is a plug for generate-reds-api.r which emits Makedoc 2}  
	Argument:     {A block output by xtract/extract-reds-docstrings}
]

emit: func [
  docstrings  [block!]
  /local
    doc
    des
][
  new-line: func [] [append doc "^/"]
  new-para: func [] [append doc "^/^/"]
  doc: copy ""
  append doc docstrings/title
  new-para
  docstrings: skip docstrings 2
  
  foreach file docstrings [
    append doc join {===} [file/file]
    new-line
    header: make object! file/header
    if in header 'title [
      append doc join "Title:" header/title
      new-line
    ]
    if in header 'purpose [
      append doc join "Purpose: " header/purpose
      new-line
    ]
    new-para
    append doc {---Functions}
    new-line
    foreach funct file/functions [
      append doc rejoin [{+++Function: } funct/func]
      new-line
      if funct/3 <> "" [                   ;; add any description
       des: replace/all funct/3 "^/" "" 
       append doc des
      ]
      new-para
      append doc {...Returns}
      new-line
      either ret-blk: select funct 'return [
        append doc rejoin [" " first ret-blk " " second ret-blk]
      ][
        append doc {No return value}    
      ]
      new-para
      append doc {...Arguments}
      new-line
      funct: skip funct 3
      foreach arg-blk funct [
        if arg-blk = 'return [break]
        append doc rejoin [
          {  } arg-blk/1 " " arg-blk/2 " " arg-blk/3
        ]
        new-para
      ]
    ]
    
    if 0 < length? file/includes [
      append doc {---Includes}
      new-line
      foreach inc file/includes [
        append doc join "  " inc 
        new-line
      ]
    ]
  ] 
  append doc reduce ["Created at  " now]
  new-para
  append doc "###"
  new-para
  append doc {
    REBOL []

    do/args %makedoc2.r 'load-only
    doc: scan-doc read file: system/options/script
    set [title out] gen-html/options doc [(options)]
    
    file: last split-path file
    replace file ".txt" ".html"
    file2: copy file
    insert find file2 "." "-light"
    replace out "$DARK$"  file
    replace out "$LIGHT$" file2
    
    write file out
    replace out "dark.css" "light.css"
    write file2 out
  }
  doc
]
