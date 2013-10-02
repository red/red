REBOL [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Encap: [quiet secure none cgi no-window] 
]

#include %encap-paths.r
#include %red-system/utils/encap-fs.r
do #include-string %.cache.efs

do #include-string %red-encap.r