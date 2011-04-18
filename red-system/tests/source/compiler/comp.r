
      REBOL []
      halt: :quit
      change-dir %../
      echo %tests/comp-echo.txt
      do/args %rsc.r "%tests/compiler/comp-err.reds"
      change-dir %tests/
    