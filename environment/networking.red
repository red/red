Red [
	Title:   "Red network-related utility functions"
	Author:  "Nenad Rakocevic"
	File: 	 %networking.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

select-scheme: function ["Internal Use Only" p [port! object!]][
	s: p/scheme
	case [
		any-word? s [s: select system/schemes s]
		block? s 	[]
	]	
	unless object? s [cause-error 'access 'no-scheme [p/scheme]]
	p/scheme: s
]

register-scheme: func [
	"Registers a new scheme"
	name [word!]	"Scheme's name"
	spec [object!]	"Actors functions"
][
	unless find/skip system/schemes name 2 [
		reduce/into [name spec] system/schemes
	]
]

url-parser: object [
	; title:  "RFC3986 URL parser"
	; file:   https://gist.github.com/greggirwin/207149d46441cd48a1426e60926a7d25
	; author: "@greggirwin"
	; date:   03-Oct-2018
	; notes:  {
	;		Reference: https://tools.ietf.org/html/rfc3986#page-16
	;		
	;		Most rule names are taken from the RFC, with the goal of
	;		making it easy to compare to the reference. Some rules
	;		are simplified in this version (e.g. IP address literals).
	;		
	;		Where pct-encoded rules are listed in the RFC, they are
	;		omitted from parse rules here, as the input is dehexed
	;		before being parsed.
	;		
	;		Relative URI path references are not yet supported.
	;	}

	;-- Parse Variables
	=scheme: =user-info: =host: =port: =path: =query: =fragment: none
	vars: [=scheme =user-info =host =port =path =query =fragment]
	
	;-- General Character Sets
	alpha:       charset [#"a" - #"z" #"A" - #"Z"]
	digit:       charset "0123456789"
	alpha-num:   union alpha digit

	;-- URL Character Sets
	
	; The purpose of reserved characters is to provide a set of delimiting
	; characters that are distinguishable from other data within a URI.
	gen-delims:  charset ":/?#[]@"
	sub-delims:  charset "!$&'()*+,;="
	reserved:    [gen-delims | sub-delims]
	unreserved:  compose [alpha | digit | (charset "-._~")]

	; Helper func for extending alpha-num
	alpha-num+: func [more [string!]][union alpha-num charset more]

	scheme-char: alpha-num+ "+-."
	
	;-- URL Grammar
	url-rules:   [scheme-part hier-part opt query opt fragment]
	scheme-part: [copy =scheme [alpha some scheme-char] #":"]
	hier-part:   ["//" authority path-abempty | path-absolute | path-rootless | path-empty]

	;   The authority component is preceded by a double slash ("//") and is
	;   terminated by the next slash ("/"), question mark ("?"), or number
	;   sign ("#") character, or by the end of the URI.
	authority:   [opt user-info  host  opt [":" port]]

	; "user:password" format for user-info is deprecated.
	user-info:   [copy =user-info [any [unreserved | sub-delims | #":"] #"@"]]

	; Host is not detailed per the RFC yet. It covers IPv6 addresses, which go in
	; square brackets, making them a non-loadable URL in Red. They can also contain
	; colons, which makes finding the port marker more involved.
	IP-literal:  [copy =IP-literal ["[" thru "]"]] ; simplified from [IPv6address | IPvFuture]
	host:        [
					IP-literal (=host: =IP-literal) 
					| copy =host any [unreserved | sub-delims]
				 ]
	port:        [copy =port [1 5 digit]]

	; path-abempty    ; begins with "/" or is empty
	; path-absolute   ; begins with "/" but not "//"
	; path-noscheme   ; begins with a non-colon segment
	; path-rootless   ; begins with a segment
	; path-empty      ; zero characters
	path-abempty:  [copy =path any-segments | path-empty] 				; (print ["path:" mold =path])
	path-absolute: [copy =path [#"/" opt [segment-nz any-segments]]]	; (print ["path-abs:" mold =path])
	;!! path-noscheme is only used in relative URIs, which aren't supported here yet.
	;path-noscheme: [copy =path [segment-nz-nc any-segments]]			; (print ["path-no-scheme:" mold =path])
	path-rootless: [copy =path [segment-nz any-segments]] 				; (print ["path-rootless:" mold =path])
	path-empty:    [none]
				  
	any-segments:  [any [#"/" segment]]
	segment:       [any pchar]
	segment-nz:    [some pchar]
	segment-nz-nc: [some [unreserved | sub-delims | #"@"]]	; non-zero-length segment with no colon
	
	pchar:        [unreserved | sub-delims | #":" | #"@"]	; path characters

	query:        ["?" copy =query any [pchar | slash | #"?"]]
	fragment:     ["#" copy =fragment any [pchar | slash | #"?"]]


	;-- Parse Function
	parse-url: function [
		"Return object with URL components, or cause an error if not a valid URL"
		url  [url! string!]
		/throw-error "Throw an error, instead of returning NONE."
		/extern vars =path =host
	][  
		set vars none	; clear object level parse variables
		either parse dehex url url-rules [
			if empty? =host [=host: none]
			=path: either all [=path not empty? =path][
				split-path to file! =path
			][
				[#[none] #[none]]
			]
			make system/standard/url-parts [
				scheme:    to word! =scheme
				user-info: =user-info
				host:      =host
				port:      if =port [to integer! =port]
				path:      first =path
				target:    second =path
				query:     =query
				fragment:  =fragment
				ref: 	   url
			]
		][
			if throw-error [make error! rejoin ["URL error: " url]]
		]
	]

	; Exported function (Rebol compatible name)
	set 'decode-url function [
		"Decode a URL into an object containing its constituent parts"
		url [url! string!]
	][
		parse-url url
	]
]
