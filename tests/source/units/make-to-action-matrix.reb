REBOL [
	Author:  "Oldes"
	Purpose: {Script for creating conversion matrix for TO action}
]

types-src: [
	#"a"
	"foo"
	123
	256       ;integer bigger than 255
	1.5
	-1
	-1.5
	1x2
	word
	/refinement
	path/foo
	http://red-lang.org
	%/file/
	#FF00
	#{}
	#{616263}
	[]        ;empty block
	[1 2]     ;block with 2 integers
	[1 2 3]   ;block with 3 integers
	["a" "b"] ;block with strings
	1.1.1    ;tuple! not yet supported in Red
	()
	(1 2)
	<a>
	10:00
	16-Jun-2014/14:34:59+2:00
	foo@boo
]
append types-src make bitset! #{00}

types-trg: []
not-implemented: [tuple! tag! time! date! email! pair! url!]

foreach src types-src [
	type: type?/word src
	unless find types-trg type [
		append types-trg type
	]
]

mold2: func[data /local result][
	result: mold/flat data
	if any [block? data paren? data] [
		replace/all result "^/   " ""
		replace/all result "^/" ""
	]
	result
]

invalid: ""
tests:   ""
foreach trg types-trg [
	append tests rejoin [{===start-group=== "to-} trg {"^/}]
	foreach src types-src [
		prin ["to" mold trg mold src " == "]
		either error? set/any 'result try [
			to to datatype! trg src
		][
			print "error!"
			append invalid rejoin [
				"to" mold trg mold src lf
			]
		][
			print mold result
			com: either any [
				find not-implemented trg
				find not-implemented type?/word src
			][";"][""]
			switch/default trg [
				url! [
					append tests rejoin [
						com {	--test-- "to-} trg "-" type? src {"^/}
						com {		--assert url? to } trg " " mold src lf
						com {		--assert } mold2 form result { = form to } trg " " mold src lf  
					]
				]
				path! [
					append tests rejoin [
						com {	--test-- "to-} trg "-" type? src {"^/}
						com {		--assert path? to } trg " " mold src lf
						com {		--assert } mold2 form result { = form to } trg " " mold src lf  
					]
				]
				refinement! [
					append tests rejoin [
						com {	--test-- "to-} trg "-" type? src {"^/}
						com {		--assert refinement? to } trg " " mold src lf
						com {		--assert } mold2 form result { = form to } trg " " mold src lf  
					]
				]
			][
				append tests rejoin [
					com {	--test-- "to-} trg "-" type? src {"^/}
					com {		--assert } mold2 result { = to } trg " " mold src lf
				]
			]

		]
	]
	append tests {===end-group===^/}
]

print "^/^/;=============== copy this into the unit test file =================^/"
print tests