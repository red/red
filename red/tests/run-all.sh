#!/bin/sh
echo "\nstarting Red tests\n"
echo "Red test log\n" > quick-test.log
failures=0;
for exe in *;
 do
  if [ "$exe" != "run-all.sh" ] && [ "$exe" != "quick-test.log" ]
   then
     chmod +x $exe;
     printf "$exe is running \r";
     report=`./$exe`;
     failures=0;
     echo "$report" >> quick-test.log
     case "$report" in 
     *'Number of Assertions Failed:    0'* ) echo "$exe passed             ";;
     * ) echo "****** $exe failed *****";;
     esac
  fi   
 done
echo "\nfinished Red tests\n"
echo ""
