REBOL [
	Title: "secure-clean-path"
	File: %secure-clean-path.r
	Date: 19-Sep-2002
	Version: 1.0.1
	Author: ["Brian Hawley" "Anton Rolls"]
	Rights: {
		Copyright (C) Brian Hawley and Anton Rolls 2002. License for
		redistribution, use and modification is granted only if this
		copyright notice is included, and does not in any way confer
		ownership. It is requested, but not required, that the authors
		be notified of any use or modification, for quality-control
		purposes.
	}
	Purpose: {Cleans up parent markers in a path, whilst restricting the output to a sandbox directory}
]

;-- (Nenad Rakocevic)
;-- script trimmed down to the function only
;-- most of comments and unit tests removed
;-- minor changes in the function body ("/" factorized, index? replaced by offset?)
;--
;-- Full script can be found here: http://www.rebol.org/view-script.r?script=secure-clean-path.r


secure-clean-path: func [
    target [any-string!] {The path to be cleaned}
    /limit               {Limit paths relative to this root}
    root   [any-string!] {The root path (Default "", not applied if "")}
    /nocopy              {Modify target instead of copy}
    /local root-rule a b c slash dot
] [
	dot: "."
	slash: "/"
    unless nocopy [target: at copy head target index? target]
    
    root-rule: either all [root not empty? root] [
        either #"/" = pick root length? root [root] [[root slash]]
    ] [
        [slash | none]
    ]
    
    if parse/all target [
        root-rule limit:
        any [
            a: dot [slash | end] (remove/part a 2) :a |
            a: some slash b: (remove/part a b) :a |
            a: some dot b: [slash | end] c: (
                loop (offset? a b) - 1 [
                    either all [
                        b: find/reverse back a slash
                        -1 <= offset? limit b
                    ] [a: next b] [a: limit  break]
                ]
            ) :a (
                remove/part a c
            ) |
            thru slash
        ] to end
    ] [target]
]
