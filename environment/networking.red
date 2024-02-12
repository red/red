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

register-scheme: func [
	"Registers a new scheme"
	spec [object!]	"Scheme definition"
	/native
		dispatch [handle!]
][
	if native [spec/actor: dispatch]
	unless find/skip system/schemes spec/name 2 [
		reduce/into [spec/name spec] system/schemes
	]
]

comment {
	Reference: https://tools.ietf.org/html/rfc3986#page-16

	Most rule names are taken from the RFC, with the goal of
	making it easy to compare to the reference. Some rules
	are simplified in this version (e.g. IP address literals).

	Relative URI path references are not yet supported.
}
url-parser: object [
	;-- Parse Variables
	=scheme: =user-info: =host: =port: =path: =query: =fragment: none
	vars: [=scheme =user-info =host =port =path =query =fragment]
	
	;-- General Character Sets
	alpha:       charset [#"a" - #"z" #"A" - #"Z"]
	digit:       charset "0123456789"
	alpha-num:   union alpha digit
	hex-digit:   union digit charset [#"a" - #"f" #"A" - #"F"]

	;-- URL Character Sets
	
	; The purpose of reserved characters is to provide a set of delimiting
	; characters that are distinguishable from other data within a URI.
	gen-delims:  charset ":/?#[]@"
	sub-delims:  charset "!$&'()*+,;="
	reserved:    [gen-delims | sub-delims]
	unreserved:  compose [alpha | digit | (charset "-._~")]
	pct-encoded: [#"%" 2 hex-digit]

	; Helper func for extending alpha-num
	alpha-num+: func [more [string!]][union alpha-num charset more]

	scheme-char: alpha-num+ "+-."
	
	;-- URL Grammar
	url-rules:   [scheme-part hier-part opt query opt fragment]	; mark: (print mark) 
	scheme-part: [copy =scheme [alpha any scheme-char] #":"]
	hier-part:   ["//" authority path-abempty | path-absolute | path-rootless | path-empty]

	;   The authority component is preceded by a double slash ("//") and is
	;   terminated by the next slash ("/"), question mark ("?"), or number
	;   sign ("#") character, or by the end of the URI.
	authority:   [opt user-info  host  opt [":" port]]

	; "user:password" format for user-info is deprecated.
	user-info:	[
					;mark: (print mold mark)
					copy =user-info [any [unreserved | pct-encoded | sub-delims | #":"] #"@"]
					;(print ["user-info:" mold =user-info])
					(take/last =user-info)
				]

	; Host is not detailed per the RFC yet. It covers IPv6 addresses, which go in
	; square brackets, making them a non-loadable URL in Red. They can also contain
	; colons, which makes finding the port marker more involved. 
	; The percent encoded options for brackets here are a bit of a hack as well, 
	; because Red encodes them in URLs, even in the IP literal segment.
	IP-literal:  [copy =IP-literal [[#"[" | "%5B"] thru [#"]" | "%5D"]]] ; simplified from [IPv6address | IPvFuture]
	host:        [
					IP-literal (=host: =IP-literal) 
					| copy =host any [unreserved | pct-encoded | sub-delims]
					;(print ["host:" mold =host])
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
	segment-nz-nc: [some [unreserved | pct-encoded | sub-delims | #"@"]]	; non-zero-length segment with no colon
	
	pchar:        [unreserved | pct-encoded | sub-delims | #":" | #"@"]	; path characters

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
		; We can't dehex before parsing, or invalid chars will show up which
		; don't match the rules. Even forming the url messes it up. Only
		; MOLD preserves the percent encoding.
		;print ['input mold url]
		either parse mold url url-rules [
			;if empty? =host [=host: none]
			;if empty? =user-info [=user-info: none]
			=path: either all [=path not empty? =path][
				split-path to file! dehex =path
			][
				[#(none) #(none)]
			]
			;set 'dbg =path
			;print ['scheme mold =scheme type? =scheme]
			object [
				scheme:    to word! =scheme
				user-info: if =user-info [dehex =user-info]
				host:      if =host [dehex =host]
				port:      if =port [to integer! =port]
				path:      first =path
				target:    second =path
				query:     if =query [dehex =query]
				fragment:  if =fragment [dehex =fragment]
				ref: 	   url
			]
		][
			if throw-error [
				make error! rejoin ["URL error: " url]
			]
		]
	]

	; Exported function (Rebol compatible name)
	set 'decode-url function [
		"Decode a URL into an object containing its constituent parts"
		url [url! string!]
	][
		parse-url url
	]

	; Note that we are careful to preserve the distinction between a component
	; that is undefined, meaning that its separator was not present in the 
	; reference, and a component that is empty, meaning that the separator was
	; present and was immediately followed by the next component separator or
	; the end of the reference.
	set 'encode-url function [url-obj [object!] "What you'd get from decode-url"][
		result: make url! 60

		if url-obj/scheme [
			append result url-obj/scheme
			append result #":"
		]

		; authority: user-info, host opt port
		if url-obj/host [
			append result "//"
			if url-obj/user-info [
				append result url-obj/user-info
				append result #"@"
			]
			append result url-obj/host
			if url-obj/port [
				append result #":"
				append result url-obj/port
			]
		]

		if all [url-obj/path  url-obj/path <> %./] [
			append result url-obj/path
		]
		if url-obj/target [
			append result url-obj/target
		]

		if url-obj/query [
			append result #"?"
			append result url-obj/query
		]

		if url-obj/fragment [
			append result #"#"
			append result url-obj/fragment
		]

		result
	]
]
