#!/bin/sh
echo "\nstarting Red/System tests\n"
echo "Red/System test log\n" > quick-test.log
failures=0;
passed=0;
total=0;
if [ -f structlib.c ]; then
  if ! "${CC:-cc}" -shared -fPIC -O2 -Dlong=int -o libstructlib.so structlib.c; then
    echo "****** failed to build libstructlib.so *****";
    exit 1;
  fi
fi
for exe in *;
 do
  if [ "$exe" != "run-all.sh" ] && [ "$exe" != "quick-test.log" ] && [ "$exe" != "libtest-dll1.so" ] && [ "$exe" != "libtest-dll2.so" ] && [ "$exe" != "libstructlib.so" ] && [ "$exe" != "structlib.c" ]
   then
     total=$((total + 1));
     chmod +x "$exe";
     printf "$exe is running \r";
     case "$exe" in
       arm64-*)
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
  fi   
 done
echo "\nfinished Red/System tests\n"
echo "Summary: $passed/$total tests passed"
echo ""
exit $failures
