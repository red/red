Red [
    Title:  "Random function for Red"
    Author: "Arnold van Hofwegen"
    File:   %random.red
    Tabs:   4
]

#system-global [
    #include %random-taocp.reds
]

random-seed: routine [
    seed [integer!]
][
    random-taocp/ran_start seed
]

random-next: routine [
    return: [integer!]
][
    random-taocp/ran_arr_next 
]

random-integer: routine [
	n       [integer!]	       ; Red context
	return: [integer!]	       ; Red context
][
    random-taocp/ran_integer n
]

random-free: routine [][
    random-taocp/ran_arr_free
]

random: function [
    ran-input [integer! float! string! logic! block!] 
    /seed
    /only  ; return one element of a series!, in Red a value from a block 
    return: [string! integer! logic! none!] 
    /local in-type i-val r-val l-val s-val idx idx2 swap
][
    in-type: type? ran-input

    if  seed [ 
        if  in-type = "integer" [random-seed ran-input]
        exit
    ]
    
    if  only [ 
        if  block! = type? ran-input [ 
            i-val: random-integer length? ran-input
            return pick ran-input i-val
        ]
    ]
    
    ; integer input, return a random value between 1 and this integer value 
    if  integer! = type? ran-input [ 
		i-val: random-integer ran-input
	    return i-val
    ]
    
    ; logic input, return a random logic value (true or false)
    if  logic! = type? ran-input   [
        l-val: random-integer 2
        return either l-val = 1 [false][true]
    ]
    
    ; string input, return the string randomized
    if  string! = type? ran-input   [
        s-val: length? ran-input
        idx: 1
        while [idx <= s-val][
            idx2: random-integer s-val
            swap: pick ran-input idx2
            poke ran-input idx2 pick ran-input idx
            poke ran-input idx swap
            idx: idx + 1
        ]
        return ran-input
    ]
    
    ;    "float"    [exit] ;; not supported atm
    
    ;default    [exit] ;; return none!] ; return "not supported yet"]
]

