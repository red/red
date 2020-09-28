REBOL [
  Title:        "Generate Red/System api docs"
	Author:       "Peter W A Wood"
	File: 	      %generate-reds-api.r
	Version:      0.1.0
	Rights:       "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License:      "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Description:  {Extracts the doc-strings from a Red/System file or files and
	               calls a supplied emitter to generate a document.}
	Arguments:     {title - the title of the API
	                src   - A red/system file or directory to be documented
	                %emit - The filepath to a REBOL script containing a function
	                        named emit which takes the extracted block as input
	                        and returns its output in a string
	                %doc  - The filepath of the file to contain the document
	                        (If this is not supplied the output will be printed)
	                }
]

;; declarations
print?: false

;; object definitions
xtract: make object! [

  ;; object variables
  docstrings: copy []
  file-blk: copy []
  func-blk: copy []
  ret-blk: copy []
  private: false
  
  ;; parse rules
  
  ;; string parse
  whitespace: charset " ^(tab)^/]"
	file-char: complement whitespace
  a-file: ["%" some file-char]
	an-include: [
	  "#include" some whitespace [copy filename a-file (
	    append inc-blk filename
	  )
	  ]
	]
  
  ;; block parse
  a-func: [
    (
      docstr: copy ""
      private: false
    )
    set func-name set-word! 'func opt [set docstr string!] 
    set arguments [block!] (
      parse arguments [
        opt [set docstr string!] (
          either docstr = "private" [
            private: true
          ][
            private: false
            new-func mold to word! func-name docstr
            docstr: copy  ""
          ]
        )
        some [
          set arg-name word! set arg-type block! opt [set docstr string!] (
            if not private [
              add-arg-blk mold arg-name mold arg-type docstr 
              docstr: copy ""
             ]
           )
        ]
        opt [set-word! set return-type [block!] opt [set docstr string!] (
          if not private [
            ret-blk: compose [(return-type) (docstr)] 
          ]
        )
        ]
        to end
      ]
    )
    block!
  ]
  
  a-header: [
    'Red/System set header block! (
      insert/only find/tail file-blk 'header header
    )
  ]
  
  an-import: [
    issue! [block!]
  ]
  
  rules: [
    any [ a-header | an-import | a-func | skip ] 
    to end (new-func "" "") 
  ]
  
  ;; functions
  
  add-arg-blk: func [
    arg       [string!]
    type      [string!]
    docstr    [string!]
    /local blk
  ][
    if not local? [
      blk: compose [(arg) (type) (docstr)]
      append/only func-blk blk
    ]
  ]
  
  new-func: func [
    name    [string!]
    docstr  [string!]
  ][
    if func-blk <> [] [
      if ret-blk <> [] [
        append func-blk 'return
        append/only func-blk ret-blk
    ]
      append/only file-blk/functions func-blk
    ]
    if name <> "" [
      func-blk: compose copy [func (name) (docstr)]
    ]
    local?: false
    ret-blk: copy []
  ]
  
  extract-docstrings: func [
    src [file!]
    /local
      code-string
      code
      dirs
  ][
    if not suffix? src [src: dirize src]
    either block! = type? code-string: read src [
      ;; recurse through the files in the directory
      if %Tests/ <> last split-path src [
        dirs: read src
        foreach file dirs [
          extract-docstrings src/:file
        ]
      ]
    ][
      if %.reds = suffix? src [
        
        ;; build a file block
        file-blk: compose copy [file (to string! second split-path src)]
        inc-blk: copy []
        append file-blk 'header 
        append file-blk 'functions
        append/only file-blk copy []
      
        ;; populate with the a block for each function
        code: code-string
        replace/all code " % " " ***rem*** "      ;; REBOL treats % operator as
                                                  ;; an invalid file name   
        parse/all load code rules
        
        ;; parse the source again to find the includes and add
        inc-blk: copy []
        parse/all code-string [some [an-include | skip] end]
        append file-blk 'includes 
        append/only file-blk inc-blk
        
        append/only docstrings file-blk
        #[unset!]
      ]
    ]
  ]
  
  extract-reds-docstrings: func [
    {Extracts docstrings from a Red/System source file or a directory of them}
    title [string!] 
    src [file!]  "A Red/System source file or a directory"
  ][
    docstrings: compose [title (title)]
    extract-docstrings src
    docstrings   
  ]
  
]

;; processing

args: parse system/script/args none 
either all [
  5 > length? args
  2 < length? args
  title: args/1
  attempt [src: to file! args/2]
  attempt [
    do to file! args/3
    function! = type? :emit
  ]
][
  doc: emit xtract/extract-reds-docstrings title src
  either 4 = length? args [
    write to file! args/4 doc
  ][
    probe doc
    print ""
  ]
][
  print "incorrect arguments supplied"
]
