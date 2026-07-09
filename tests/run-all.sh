#!/bin/sh
# Runs every compiled Red test binary in this directory and prints a
# distinguishable verdict for each, so CI can tell a genuine test failure apart
# from a crash, a hang, or missing output. Exits non-zero if any binary did not
# cleanly pass (this exit code is the CI step's pass/fail signal).
echo "\nstarting Red tests\n"
echo "Red test log\n" > quick-test.log

# per-binary wall-clock cap: a hung binary is reported, not left to stall CI
if command -v timeout >/dev/null 2>&1; then TIMEOUT="timeout 600"; else TIMEOUT=""; fi

failures=0
for exe in *;
 do
  if [ -f "$exe" ] && [ "$exe" != "run-all.sh" ] && [ "$exe" != "quick-test.log" ]
   then
     chmod +x "$exe"
     printf "%s is running \r" "$exe"
     report=$($TIMEOUT ./"$exe"); rc=$?
     echo "$report" >> quick-test.log

     # A binary may run several ~~~start-file~~~ scopes, so sum EVERY
     # "Number of Assertions Failed: N" line (not just match one) and count
     # how many totals blocks were printed at all.
     nfail=$(printf '%s\n' "$report" | awk -F'Number of Assertions Failed:' 'NF>1{s+=$2+0} END{print s+0}')
     ntot=$(printf '%s\n' "$report" | grep -c 'Number of Assertions Failed:')

     if [ "$rc" -ge 128 ]; then
       echo "****** $exe CRASHED (killed by signal $((rc - 128))) *****"; failures=1
     elif [ -n "$TIMEOUT" ] && [ "$rc" -eq 124 ]; then
       echo "****** $exe TIMED OUT (hung) *****"; failures=1
     elif [ "$rc" -ne 0 ]; then
       echo "****** $exe exited with error code $rc *****"; failures=1
     elif [ "$ntot" -eq 0 ]; then
       echo "****** $exe produced NO test output (died before finishing?) *****"; failures=1
     elif [ "$nfail" -ne 0 ]; then
       echo "****** $exe FAILED ($nfail assertions) *****"; failures=1
     else
       echo "$exe passed             "
     fi
  fi
 done
echo "\nfinished Red tests\n"
echo ""
exit $failures
