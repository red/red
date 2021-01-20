Red []

#include %../environment/console/CLI/input.red


debugger: context [
    code-stk: make block! 10

    mold-mapped: function [code [block!]][
        out: clear ""
        pos: 1
        idx: index? code
?? idx  
        code: head last code-stk
        append out #"["
        forall code [
            append out value: code/1
            unless tail? next code [append out space]
            if 60 < length? out [
                append clear at out 57 "..."
                break
            ]
            if idx >= index? code [
                len: length? value
                pos: pos + 1 + any [all [len < 60 len] 56]
                ;len: length? code/2
            ]
        ]
        append out #"]"
        reduce [out pos any [len 1]]
    ]

    tracer: function [
        event [word!]
        code  [block! none!]
        value [any-type!]
        frame [pair!]               ;-- current frame start, top
        /local out pos len
    ][
       ?? event
        switch/default event [
            begin [append/only code-stk split mold/only code space]
            end   [take/last code-stk]
        ][
        ;if find [open close push exec] event [
            print ["Input:" either code [set [out pos len] mold-mapped code out]["..."]]            
            ;prin "       "
            loop pos + 7 [prin space]
            loop len [prin #"^^"]
            prin lf
            repeat i frame/2 - frame/1 [
                print ["Stack:" mold/part/flat pick-stack i + frame/1 50]
            ]
            until [
                entry: trim ask "^/debug>"
                if cmd: attempt [to-word entry][
                    if cmd = 'q [halt]
                ]
                empty? entry
            ]
        ;]
        ]
    ]
]

do/trace [print 1 + length? mold 'hello] :debugger/tracer

