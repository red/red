REBOL [
  Title: "Test successful compilations from Red/System programs"
  File:  %compiles-ok-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
~~~start-file~~~ "compiles-ok"

===start-group=== "reported issues"

  --test-- "issue #417"
  --assert --compiled? {
      Red/System[]
      {
        REBOL []
      }
    }
    
===end-group===

===start-group=== "pointer types"

  --test-- "protected string table uses pointer-width slots"
  --assert --compiled? {
      Red/System []
      names: protect ["first" "second"]
      #either target = 'X86-64 [
        table: declare pointer! [c-string!]
      ][
        table: declare pointer! [integer!]
      ]
      table: names
      value: table/2
    }

  --test-- "mixed pointer table uses pointer-width slots"
  --assert --compiled? {
      Red/System []
      table: protect ["first" 5 10]
      #either target = 'X86-64 [
        cursor: declare pointer! [uint64!]
      ][
        cursor: declare pointer! [integer!]
      ]
      cursor: table
      length: #either target = 'X86-64 [as integer! cursor/2][cursor/2]
    }

===end-group===
  
~~~end-file~~~
