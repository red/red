Red [
	Title:  "Red shape dialect test"
	Author: "Iosif Haidu"
    Tabs:   4
	File: 	%shape-test.red
	Needs:	View
]

drawings: [
    "ARC"
    [
        pen yellow
        line-width 3
        shape [
            move 10x20
            arc 180x20 120 50 0
            move 10x70
            arc 180x70 120 50 0 sweep
            move 220x20
            arc 400x20 120 50 0 large
            move 480x100
            arc 660x100 120 50 0 sweep large
            move 0x0
        ]
    ]

    "ARC"
    [
        pen yellow
        line-width 3
        shape [
            move 0x399
            line 42x357
            arc 84x315 25 20 -45 sweep
            line 126x273
            arc  168x231 25 40 -45 sweep
            line 210x189
            arc  252x147 25 60 -45 sweep
            line 294x105
            arc  336x63 25 80 -45 sweep
            line 399x0
            move 0x0
        ]
        pen red
        line-width 3
        translate 200x399
        shape [
            move 0x0
            'line 42x-42
            'arc 42x-42 25 20 -45 sweep
            'line 42x-42
            'arc 42x-42 25 40 -45 sweep
            'line 42x-42
            'arc 42x-42 25 60 -45 sweep
            'line 42x-42
            'arc 42x-42 25 80 -45 sweep
            'line 63x-63
            move 0x0
        ]
    ]

    "CURV"
    [
        line-width 3
        pen yellow
        shape [
            move 100x50
            vline 150
            curv 300x150 300x50
            move 0x0
        ]        
        line-width 3
        pen red
        translate 300x0
        shape [
            'move 100x50
            'vline 100
            'curv 200x0 200x-100
            move 0x0
        ]        
    ]

    "CURVE"
    [
        line-width 3
        pen yellow
        shape [
            move 100x50
            curve 100x150 300x150 300x50
            move 0x0
        ]        
        line-width 3
        pen red
        translate 300x0
        shape [
            move 100x50 'curve 0x100 200x100 200x0
            move 0x0
        ]
    ]

    "HLINE"
    [
        pen yellow
        line-width 4
        shape [
            move 100x100
            hline 300
            move 100x150
            hline 250
            move 100x200
            hline 200
        ]
        pen red
        line-width 4
        translate 300x0
        shape [
            move 100x100
            'hline 200
            'move -200x50
            'hline 150
            'move -150x50
            'hline 100
        ]                
    ]

    "LINE"
    [
        pen yellow
        line-width 4
        shape [
            move 50x50
            line 300x120 50x120 300x50
            move 0x0
        ]        
        pen red
        line-width 4
        translate 300x0
        shape [
            move 50x50
            move 50x50 'line 250x70 -250x0 250x-70
            move 0x0
        ]
    ]

    "MOVE"
    [
        line-width 4
        pen yellow
        shape [
            move 100x100
            line 20x20 150x50
            move 0x0
        ]
        line-width 4
        pen yellow
        shape [
            move 100x100
            line 20x20 150x50
            move 0x0
        ]
        pen red
        shape [
            move 100x100
            'move 0x100
            'line -80x-80 130x30
        ]
    ]

    "QCURV"
    [
        pen yellow
        line-width 4
        shape [
            move 0x150
            qcurve 100x250 200x150
            qcurv 400x150
            move 0x0
        ]        
        pen red
        line-width 4
        translate 0x200
        shape [
            move 0x150
            'qcurve 100x100 200x0
            'qcurv 200x0
            move 0x0
        ]
    ]

    "QCURVE"
    [
        pen yellow
        line-width 4
        shape [
            move 100x50
            qcurve 200x150 300x50
            move 0x0
        ]
        pen red
        line-width 4
        translate 300x0
        shape [
            move 100x50
            'qcurve 100x100 200x0
            move 0x0
        ]                
    ]

    "VLINE"
    [
        pen yellow
        line-width 4
        shape [
            move 100x100  vline 300
            move 150x100  vline 250
            move 200x100  vline 200
        ]        
        pen red
        line-width 4
        translate 300x0
        shape [
            move 100x100   'vline 200
            'move 50x-200  'vline 150
            'move 50x-150  'vline 100
        ]        
    ]
]

index: 2
board: layout [
    below
    label: text "" 200 font [size: 16]
    canvas: base 700x400
    below
    across
    btn-prev: button "previous" [ 
        unless btn-next/enable? [ btn-next/enable?: true ]
        either index > 2 [
            index: index - 2 
            label/text: drawings/(index - 1)
            canvas/draw: drawings/:index 
            show canvas
        ][ btn-prev/enable?: false ]
    ]
    btn-next: button "next" [
        unless btn-prev/enable? [ btn-prev/enable?: true ]
        either index < length? drawings [
            index: index + 2 
            label/text: drawings/(index - 1)
            canvas/draw: drawings/:index 
            show canvas
        ][ btn-next/enable?: false ]
    ]
    do [
        label/text: drawings/(index - 1)
        canvas/draw: drawings/:index
        btn-prev/enable?: false
    ]
]
board/text: "Shape sub dialect demo"
view board 
