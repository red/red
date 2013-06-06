#!/bin/sh
echo "\nstarting Red/System tests\n"
echo "Red/System test log\n" > quick-test.log
for exe in *;
 	do
 		filename=$(basename "$exe")
		extension="${filename##*.}"
		filename="${filename%.*}"
 		if [ "$extension" == "$filename" ]
 		then
 			chmod +x $exe;
 			printf "$exe is running \r";
 			report=`./$exe`;
 			echo "$report" >> quick-test.log
 			case "$report" in 
 	 	 		*'Number of Assertions Failed:    0'* ) echo "$exe passed             ";;
 	 	 		* ) echo "****** $exe failed *****";;
 	 	 	esac
 	 	fi   
 	done
echo "\nfinished Red/System tests\n"
echo ""
