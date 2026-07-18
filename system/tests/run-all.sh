#!/bin/sh
# Runs every compiled Red/System test binary in this directory and prints a
# distinguishable verdict for each, so CI can tell a genuine test failure apart
# from a crash, a hang, or missing output. Exits non-zero if any binary did not
# cleanly pass (this exit code is the CI step's pass/fail signal).
echo "\nstarting Red/System tests\n"
echo "Red/System test log\n" > quick-test.log
failures=0;
passed=0;
total=0;
platform=`uname -s`;
architecture=`uname -m`;
if command -v timeout >/dev/null 2>&1; then TIMEOUT="timeout 600"; else TIMEOUT=""; fi
if [ -f structlib.c ]; then
  if [ "$platform" = "Darwin" ]; then
    structlib=libstructlib.dylib;
    struct_flags="-arch arm64 -dynamiclib";
  else
    structlib=libstructlib.so;
    struct_flags="-shared -fPIC";
  fi
  if ! "${CC:-cc}" $struct_flags -O2 -o "$structlib" structlib.c; then
    echo "****** failed to build $structlib *****";
    exit 1;
  fi
fi
if [ -f darwin-arm64-abi-helper.c ]; then
  if ! "${CC:-cc}" -arch arm64 -dynamiclib -O2 \
    -o libdarwin-arm64-abi-helper.dylib darwin-arm64-abi-helper.c; then
    echo "****** failed to build libdarwin-arm64-abi-helper.dylib *****";
    exit 1;
  fi
fi
if [ "$platform" = "Darwin" ]; then
  export DYLD_LIBRARY_PATH="$PWD${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}";
  for library in *.dylib; do
    if [ -f "$library" ]; then
      if [ "$architecture" = "arm64" ]; then
        if ! codesign --verify --strict --verbose=4 "$library"; then
          echo "****** invalid code signature on $library *****";
          exit 1;
        fi
      elif ! codesign --force --sign - "$library"; then
        echo "****** failed to sign $library *****";
        exit 1;
      fi
    fi
  done
fi
for exe in *;
 do
  case "$exe" in
    run-all.sh|validate-arm64-elf.sh|quick-test.log|*.so|*.dylib|*.dll|*.c)
      continue;;
  esac
     total=$((total + 1));
     chmod +x "$exe";
     if [ "$platform" = "Darwin" ]; then
       if [ "$architecture" = "arm64" ]; then
         if ! codesign --verify --strict --verbose=4 "$exe"; then
           echo "****** invalid code signature on $exe *****";
           exit 1;
         fi
       elif ! codesign --force --sign - "$exe"; then
         echo "****** failed to sign $exe *****";
         exit 1;
       fi
     fi
     printf "$exe is running \r";
     assertions=0;
     case "$exe" in
       darwin-arm64-runtime-smoke)
         report=`$TIMEOUT ./"$exe" alpha 2>&1`; status=$?;;
       arm64-*|darwin-arm64-*)
         report=`$TIMEOUT ./"$exe" alpha beta 2>&1`; status=$?;;
       *)
         report=`$TIMEOUT ./"$exe" 2>&1`; status=$?; assertions=1;;
     esac
     echo "$report" >> quick-test.log;
     if [ "$status" -ge 128 ]; then
       echo "****** $exe CRASHED (killed by signal $((status - 128))) *****"; failures=1;
     elif [ -n "$TIMEOUT" ] && [ "$status" -eq 124 ]; then
       echo "****** $exe TIMED OUT (hung) *****"; failures=1;
     elif [ "$status" -ne 0 ]; then
       echo "****** $exe exited with error code $status *****"; failures=1;
     elif [ "$assertions" -eq 0 ]; then
       echo "$exe passed             "; passed=$((passed + 1));
     else
       nfail=$(printf '%s\n' "$report" | awk -F'Number of Assertions Failed:' 'NF>1{s+=$2+0} END{print s+0}');
       ntot=$(printf '%s\n' "$report" | grep -c 'Number of Assertions Failed:');
       if [ "$ntot" -eq 0 ]; then
         echo "****** $exe produced NO test output (died before finishing?) *****"; failures=1;
       elif [ "$nfail" -ne 0 ]; then
         echo "****** $exe FAILED ($nfail assertions) *****"; failures=1;
       else
         echo "$exe passed             "; passed=$((passed + 1));
       fi
     fi
 done
echo "\nfinished Red/System tests\n"
echo "Summary: $passed/$total tests passed"
echo ""
exit $failures
