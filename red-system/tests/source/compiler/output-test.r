REBOL [
  Title: "Test output from Red/System programs"
  File:  %output-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
~~~start-file~~~ "output"

  --test-- "hello"
    either exe: --compile src: %source/compiler/hello.reds [
      --run exe
      --assert none <> find qt/output "hello"
      --assert none <> find qt/output "world"
    ][
      qt/compile-error src
    ]

    --test-- "empty"
      either exe: --compile src: %source/compiler/empty.reds [
        --run exe
        --assert qt/output = ""
      ][
        qt/compile-error src
      ]

~~~end-file~~~
