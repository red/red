REBOL [
  Title: "Test output from Red/System programs"
  File:  %output-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
~~~start-file~~~ "output"

  --test-- "hello"
  --compile-and-run/pgm %source/compiler/hello.reds 
  --assert none <> find qt/output "hello"
  --assert none <> find qt/output "world"
  
  --test-- "empty"
  --compile-and-run/pgm %source/compiler/empty.reds
  --assert qt/output = ""
  
~~~end-file~~~
