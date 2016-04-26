REBOL [
	Title:   "Encapping wrapper script"
	Author:  "Nenad Rakocevic"
	File: 	 %precap.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Encap: [quiet secure none cgi no-window] 
]

#include %encap-paths.r
#include %../system/utils/encap-fs.r
do #include-string %bin/sources.r

build-date: #include %timestamp.r

do #include-string %../red.r