REBOL [
	Title:			"Make To-Matrix HTML"
	Author:       	"Peter W A Wood"
	Version:		0.1.0
	Rights:       	"Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License:      	"BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Description:  	{Builds the to-matirx html page from the html template
					 and the matrix stored in Red blocks}
]

template: read %to-matrix-template.html
json: copy ""
matrix: third load/all %to-matrix.red

foreach [type vector]  matrix [
	append json join { "} [type {": } "{"]
	foreach [datatype entry] vector [
		if string! = type? entry [
			entry: replace/all entry "^/" " "
			entry: replace/all entry "^-" " "
		]
		append json join {"} [datatype {": "} entry {",}	]
	]
	remove tail back json
	append json "},"
]

html: replace template "***JSON***" head json

write %to-matrix.html html



