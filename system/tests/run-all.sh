#!/bin/sh
echo "\nstarting Red/System tests\n"
echo "Red/System test log\n" > quick-test.log
failures=0;
passed=0;
total=0;
platform=`uname -s`;
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
    if [ -f "$library" ] && ! codesign --force --sign - "$library"; then
      echo "****** failed to sign $library *****";
      exit 1;
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
       if ! codesign --force --sign - "$exe"; then
         echo "****** failed to sign $exe *****";
         exit 1;
       fi
     fi
     printf "$exe is running \r";
     case "$exe" in
       darwin-arm64-runtime-smoke)
         report=`./"$exe" alpha 2>&1`;
         status=$?;
         echo "$report" >> quick-test.log;
         if [ "$status" -eq 0 ]; then
           echo "$exe passed             ";
           passed=$((passed + 1));
         else
           echo "****** $exe failed (exit $status) *****";
           failures=1;
         fi;;
       arm64-*|darwin-arm64-*)
         report=`./"$exe" alpha beta 2>&1`;
         status=$?;
         echo "$report" >> quick-test.log;
         if [ "$status" -eq 0 ]; then
           echo "$exe passed             ";
           passed=$((passed + 1));
         else
           echo "****** $exe failed (exit $status) *****";
           failures=1;
         fi;;
       *)
         report=`./"$exe" 2>&1`;
         status=$?;
         echo "$report" >> quick-test.log;
         if [ "$status" -eq 0 ]; then
           case "$report" in
             *'Number of Assertions Failed:    0'*)
               echo "$exe passed             ";
               passed=$((passed + 1));;
             *) echo "****** $exe failed *****";failures=1;;
           esac
         else
           echo "****** $exe failed (exit $status) *****";
           failures=1;
         fi;;
     esac
 done
echo "\nfinished Red/System tests\n"
echo "Summary: $passed/$total tests passed"
echo ""
exit $failures
