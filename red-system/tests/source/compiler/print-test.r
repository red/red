REBOL [
  Title: "Test print function from Red/System programs"
  File:  %print-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
~~~start-file~~~ "print"

  --test-- "p1"
  --compile-and-run-this [
    a: as-byte 1
    b: as-byte 2
    print as byte-ptr! (as-integer b) << 16 or as-integer a
    print lf
  ]
  --assert none <> find qt/output "20001"
 
~~~end-file~~~
