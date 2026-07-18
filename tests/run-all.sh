#!/bin/sh
# Runs every compiled Red test binary in this directory and prints a
# distinguishable verdict for each, so CI can tell a genuine test failure apart
# from a crash, a hang, or missing output. Exits non-zero if any binary did not
# cleanly pass (this exit code is the CI step's pass/fail signal).
echo "\nstarting Red tests\n"
echo "Red test log\n" > quick-test.log
failures=0;
platform=`uname -s`;
architecture=`uname -m`;

# per-binary wall-clock cap: a hung binary is reported, not left to stall CI
if command -v timeout >/dev/null 2>&1; then TIMEOUT="timeout 600"; else TIMEOUT=""; fi
for exe in *;
 do
  if [ -f "$exe" ] && [ "$exe" != "run-all.sh" ] && [ "$exe" != "quick-test.log" ]
   then
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
     report=`$TIMEOUT ./"$exe" 2>&1`;
     status=$?;
     echo "$report" >> quick-test.log
     nfail=$(printf '%s\n' "$report" | awk -F'Number of Assertions Failed:' 'NF>1{s+=$2+0} END{print s+0}')
     ntot=$(printf '%s\n' "$report" | grep -c 'Number of Assertions Failed:')
     if [ "$status" -ge 128 ]; then
       echo "****** $exe CRASHED (killed by signal $((status - 128))) *****";failures=1;
     elif [ -n "$TIMEOUT" ] && [ "$status" -eq 124 ]; then
       echo "****** $exe TIMED OUT (hung) *****";failures=1;
     elif [ "$status" -ne 0 ]; then
       echo "****** $exe exited with error code $status *****";failures=1;
     elif [ "$ntot" -eq 0 ]; then
       echo "****** $exe produced NO test output (died before finishing?) *****";failures=1;
     elif [ "$nfail" -ne 0 ]; then
       echo "****** $exe FAILED ($nfail assertions) *****";failures=1;
     else
       echo "$exe passed             ";
     fi
  fi   
 done
echo "\nfinished Red tests\n"
echo ""
exit $failures
