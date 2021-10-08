Red []

;#include %../environment/console/CLI/input.red


debugger: context [
    code-stk: make block! 10
    call-stk: make block! 10
    base: none

    mold-mapped: function [code [block!]][
        out: clear ""
        pos: 1
        len: 0
        idx: index? code

        code: head last code-stk
        append out #"["
        forall code [
            append out value: code/1
            unless tail? next code [append out space]
            if 60 < length? out [
                append clear at out 57 "..."
                break
            ]
            if idx = index? code [len: length? value]
            if idx > index? code [pos: pos + 1 + length? value]
        ]
        append out #"]"
        reduce [out pos len]
    ]

    tracer: function [
        event [word!]
        code  [block! none!]
        value [any-type!]
        frame [pair!]               ;-- current frame start, top
        name  [word! none!]
        /local out pos len
    ][
    	unless base [base: frame/1]
;       ?? event
        switch event [
            begin	[append/only code-stk split mold/only code space]
            end		[take/last code-stk]
            call	[append/only call-stk reduce [:value]]
            push	[append/only last call-stk :value]            
            return	[
            	take/last call-stk
            	unless empty? call-stk [append/only last call-stk :value]
            ]
        ]        
			unless find [begin end] event [
				?? event
				;?? value
				?? call-stk
				print ["Input:" either code [set [out pos len] mold-mapped code out]["..."]]            
				loop 7 + pos [prin space]
				loop len [prin #"^^"]
				prin lf
				repeat i frame/2 - base + 1 [
					print ["Stack:" mold/part/flat pick-stack i + base - 1 50]
				]
				until [
					entry: trim ask "^/debug>"
					if cmd: attempt [to-word entry][
						if cmd = 'q [halt]
					]
					empty? entry
				]
			]
        ;]
    ]
    
	logger: function [
		event [word!]
		code  [block! none!]
		value [any-type!]
		frame [pair!]               ;-- current frame start, top
	][
		switch event [
			begin [append/only code-stk split mold/only code space]
			end   [take/last code-stk]
			open  [append/only call-stk idx: index? code]
			close [idx: take/last call-stk]
        ]
        unless idx [idx: all [code index? code]]
		print [event idx mold/part/flat :value 20 frame]
	]
]

do/trace [print 1 + length? mold 'hello] :debugger/tracer
;do/trace [print 1 + length? mold 'hello] :debugger/logger

