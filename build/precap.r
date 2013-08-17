REBOL [
	Title:   "Encapping wrapper script"
	Author:  "Nenad Rakocevic"
	File: 	 %precap.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Encap: [quiet secure none cgi no-window] 
]

#include %encap-paths.r
#include %../red-system/utils/encap-fs.r
do #include-string %bin/sources.r

do #include-string %../red.r