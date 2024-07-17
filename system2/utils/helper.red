Red [
	Title:   "helper functions"
	File: 	 %helper.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

reform: func [v][form reduce v]
join: func [
    "Concatenates values."
    value "Base value"
    rest "Value or block of values"
][
    value: either series? value [copy value] [form value]
    append value rest
]

for: func [
    "Repeats a block over a range of values."
    'word [word!] "Variable to hold current value"
    start [number! series! money! time! date! char!] "Starting value"
    end [number! series! money! time! date! char!] "Ending value"
    bump [number! money! time! char!] "Amount to skip each time"
    body [block!] "Block to evaluate"
    /local result do-body op
][
    if (type? start) <> (type? end) [
        throw make error! reduce ['script 'expect-arg 'for 'end type? start]
    ]
    do-body: func reduce [word] body
    op: :greater-or-equal?
    either series? start [
        if not same? head start head end [
            throw make error! reduce ['script 'invalid-arg end]
        ]
        if (negative? bump) [op: :lesser?]
        while [op index? end index? start] [
            set/any 'result do-body start
            start: skip start bump
        ]
        if (negative? bump) [set/any 'result do-body start]
    ] [
        if (negative? bump) [op: :lesser-or-equal?]
        while [op end start] [
            set/any 'result do-body start
            start: start + bump
        ]
    ]
    get/any 'result
]

forskip: func [
    "Evaluates a block for periodic values in a series."
    'word [word!] {Word set to each position in series and changed as a result}
    skip-num [integer!] "Number of values to skip each time"
    body [block!] "Block to evaluate each time"
    /local orig result
][
    orig: get word
    while [any [not tail? get word (set word orig false)]] [
        set/any 'result do body
        set word skip get word skip-num
        get/any 'result
    ]
]

found?: func [
    "Returns TRUE if value is not NONE."
    value
][
    not none? :value
]

map-each: func [
	"Evaluates a block for each value(s) in a series and returns them as a block."
	'word [word! block!] "Word or block of words to set each time (local)"
	data [block!] "The series to traverse"
	body [block!] "Block to evaluate each time"
	/into "Collect into a given series, rather than a new block"
	output [any-block! any-string!] "The series to output to" ; Not image!
	/local init len x
][
	; Shortcut return for empty data
	either empty? data [any [output make block! 0]] [
		; BIND/copy word and body
		word: either block? word [
			if empty? word [throw make error! [script invalid-arg []]]
			copy/deep word  ; /deep because word is rebound before errors checked
		] [reduce [word]]

		; Build init code
		init: none
		parse word [any [word! | x: set-word! (
			unless init [init: make block! 4]
			; Add [x: at data index] to init, and remove from word
			insert insert insert tail init first x [at data] index? x
			remove x
		) :x | x: skip (
			throw make error! reduce ['script 'expect-set [word! set-word!] type? first x]
		)]]
		len: length? word ; Can be zero now (for advanced code tricks)
		; Create the output series if not specified
		unless into [output: make block! divide length? data max 1 len]
		; Process the data (which is not empty at this point)
		until [ ; Note: output: insert/only output needed for list! output
			set word data  do init
			unless unset? set/any 'x do body [output: insert/only output :x]
			tail? data: skip data len
		]
		; Return the output and clean up memory references
		also either into [output] [head output] (
			set [word data body output init x] none
		)
	]
]

array: func [
    "Makes and initializes a series of a given size."
    size [integer! block!] "Size or block of sizes for each dimension"
    /initial "Specify an initial value for all elements"
    value "Initial value"
    /local block rest
][
    if block? size [
        rest: next size
        if tail? rest [rest: none]
        size: first size
        if not integer? size [make error! "Integer size required"]
    ]
    block: make block! size
    case [
        block? rest [
            loop size [block: insert/only block array/initial rest :value]
        ]
        series? :value [
            loop size [block: insert/only block copy/deep value]
        ]
        any-function? :value [
            loop size [block: insert/only block value]
        ]
        true [insert/dup block value size]
    ]
    head block
]