Red [Needs: View]

view [
    size 390x220
    across space 0x0
    base 367x200 with [
        flags: 'scrollable
        pane: layout/only [
            origin 0x0 space 0x0
            p: panel 350x800 [
                origin 0x0 space 0x0
                below
                area "A" 350x200
                area "B" 350x200
                area "C" 350x200
                area "D" 350x200
            ]
        ]
    ]
    on-created [
        put get-scroller face 'horizontal 'visible? no
        sc: get-scroller face 'vertical
        sc/position: 0
        sc/page-size: 200
        sc/max-size: 800
    ]
    on-scroll [
        sc/position: max 0 min 600 switch event/key [
            down [sc/position + 20]
            up [sc/position - 20]
            page-down [sc/position + sc/page-size]
            page-up [sc/position - sc/page-size]
            track [event/picked - 1]
            end [sc/position]
        ]
        p/offset: as-pair 0 negate sc/position
    ] 
]