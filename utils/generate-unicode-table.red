Red [
	Title:	"generate unicode table"
	Author: "bitbegin"
	File: 	%generate-unicode-table.red
	Usage: comment {
		we use lower-to-upper and upper-to-lower table from 
		https://github.com/rust-lang/rust/blob/master/src/libcore/unicode/tables.rs
	}
	Tabs: 	4
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

tables: read https://raw.githubusercontent.com/rust-lang/rust/master/src/libcore/unicode/tables.rs
space: charset " ^-^/"

output: %../runtime/case-folding-table.reds

write output {Red/System [
	Title:	"case folding table file auto generated from rust"
	Author: "bitbegin"
	File: 	%case-folding-table.reds
	Usage: comment ^{
		run %utils/generate-unicode-table.red to produce this file
	^}
	Tabs: 	4
	License: ^{
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	^}
]

}

get-unicode-version: func [][
	version: none
	rule: [
		thru "major:" any space copy major to ","
		thru "minor:" any space copy minor to ","
		thru "micro:" any space copy micro to ","
		thru end
		(version: rejoin ["Unicode version: " to string! major "." to string! minor "." to string! micro])
	]
	parse tables rule
	version
]

write/append output rejoin [";-- " get-unicode-version "^/^/"]

pad: func [hex [string!] return: [string!] /local len][
	len: length? hex
	case [
		len < 2 [make error! "too large"]
		;len = 2 [hex]
		len <= 4 [insert/dup hex "0" 4 - len]
		len <= 8 [insert/dup hex "0" 8 - len]
		true [make error! "too large"]
	]
]

generate-lower-to-upper-table: func [] [
	to_uppercase_table-start: find/tail tables "const to_uppercase_table: &[(char, [char; 3])] = &["
	to_uppercase_table-end: find to_uppercase_table-start "];"

	to_uppercase_table: copy/part to_uppercase_table-start to_uppercase_table-end
	
	to-uppercase-table: copy ""

	rule: [
		thru "(" any space "'\u{" copy lower-char to "}'"
			thru "[" any space "'\u{" copy upper-char to "}'" thru ")" (
				pad lower-char
				pad upper-char
				append to-uppercase-table rejoin ["^-" uppercase lower-char "h " uppercase upper-char "h^/"]
			)
	]

	parse to_uppercase_table [some rule]
	write/append output "to-uppercase-table: [^/"
	write/append output to-uppercase-table
	write/append output "]^/"
]

generate-upper-to-lower-table: func [] [
	to_lowercase_table-start: find/tail tables "const to_lowercase_table: &[(char, [char; 3])] = &["
	to_lowercase_table-end: find to_lowercase_table-start "];"

	to_lowercase_table: copy/part to_lowercase_table-start to_lowercase_table-end
	
	to-lowercase-table: copy ""

	rule: [
		thru "(" any space "'\u{" copy upper-char to "}'"
			thru "[" any space "'\u{" copy lower-char to "}'" thru ")" (
				pad upper-char
				pad lower-char
				append to-lowercase-table rejoin ["^-" uppercase upper-char "h " uppercase lower-char "h^/"]
			)
	]

	parse to_lowercase_table [some rule]
	write/append output "to-lowercase-table: [^/"
	write/append output to-lowercase-table
	write/append output "]^/"
]

generate-lower-to-upper-table
generate-upper-to-lower-table


