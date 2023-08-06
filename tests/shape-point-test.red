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
            move (10,20)
            arc (180,20) 120 50 0
            move (10,70)
            arc (180,70) 120 50 0 sweep
            move (220,20)
            arc (400,20) 120 50 0 large
            move (480,100)
            arc (660,100) 120 50 0 sweep large
            move (0,0)
        ]
    ]

    "ARC"
    [
        pen yellow
        line-width 3
        shape [
            move (0,399)
            line (42,357)
            arc (84,315) 25 20 -45 sweep
            line (126,273)
            arc  (168,231) 25 40 -45 sweep
            line (210,189)
            arc  (252,147) 25 60 -45 sweep
            line (294,105)
            arc  (336,63) 25 80 -45 sweep
            line (399,0)
            move (0,0)
        ]
        pen red
        line-width 3
        translate (200,399)
        shape [
            move (0,0)
            'line (42,-42)
            'arc (42,-42) 25 20 -45 sweep
            'line (42,-42)
            'arc (42,-42) 25 40 -45 sweep
            'line (42,-42)
            'arc (42,-42) 25 60 -45 sweep
            'line (42,-42)
            'arc (42,-42) 25 80 -45 sweep
            'line (63,-63)
            move (0,0)
        ]
    ]

    "CURV"
    [
        line-width 3
        pen yellow
        shape [
            move (100,50)
            vline 150
            curv (300,150) (300,50)
            move (0,0)
        ]        
        line-width 3
        pen red
        translate (300,0)
        shape [
            'move (100,50)
            'vline 100
            'curv (200,0) (200,-100)
            move (0,0)
        ]        
    ]

    "CURVE"
    [
        line-width 3
        pen yellow
        shape [
            move (100,50)
            curve (100,150) (300,150) (300,50)
            move (0,0)
        ]        
        line-width 3
        pen red
        translate (300,0)
        shape [
            move (100,50) 'curve (0,100) (200,100) (200,0)
            move (0,0)
        ]
    ]

    "HLINE"
    [
        pen yellow
        line-width 4
        shape [
            move (100,100)
            hline 300
            move (100,150)
            hline 250
            move (100,200)
            hline 200
        ]
        pen red
        line-width 4
        translate (300,0)
        shape [
            move (100,100)
            'hline 200
            'move (-200,50)
            'hline 150
            'move (-150,50)
            'hline 100
        ]                
    ]

    "LINE"
    [
        pen yellow
        line-width 4
        shape [
            move (50,50)
            line (300,120) (50,120) (300,50)
            move (0,0)
        ]        
        pen red
        line-width 4
        translate (300,0)
        shape [
            move (50,50)
            move (50,50) 'line (250,70) (-250,0) (250,-70)
            move (0,0)
        ]
    ]

    "MOVE"
    [
        line-width 4
        pen yellow
        shape [
            move (100,100)
            line (20,20) (150,50)
            move (0,0)
        ]
        line-width 4
        pen yellow
        shape [
            move (100,100)
            line (20,20) (150,50)
            move (0,0)
        ]
        pen red
        shape [
            move (100,100)
            'move (0,100)
            'line (-80,-80) (130,30)
        ]
    ]

    "QCURV"
    [
        pen yellow
        line-width 4
        shape [
            move (0,150)
            qcurve (100,250) (200,150)
            qcurv (400,150)
            move (0,0)
        ]        
        pen red
        line-width 4
        translate (0,200)
        shape [
            move (0,150)
            'qcurve (100,100) (200,0)
            'qcurv (200,0)
            move (0,0)
        ]
    ]

    "QCURVE"
    [
        pen yellow
        line-width 4
        shape [
            move (100,50)
            qcurve (200,150) (300,50)
            move (0,0)
        ]
        pen red
        line-width 4
        translate (300,0)
        shape [
            move (100,50)
            'qcurve (100,100) (200,0)
            move (0,0)
        ]                
    ]

    "VLINE"
    [
        pen yellow
        line-width 4
        shape [
            move (100,100)  vline 300
            move (150,100)  vline 250
            move (200,100)  vline 200
        ]        
        pen red
        line-width 4
        translate (300,0)
        shape [
            move (100,100)   'vline 200
            'move (50,-200)  'vline 150
            'move (50,-150)  'vline 100
        ]        
    ]
]

index: 2
board: layout [
    below
    label: text "" 200 font [size: 16]
    canvas: base (700,400)
    below
    across
    btn-prev: button "previous" [ 
        unless btn-next/enabled? [ btn-next/enabled?: true ]
        either index > 2 [
            index: index - 2 
            label/text: drawings/(index - 1)
            canvas/draw: drawings/:index 
            show canvas
        ][ btn-prev/enabled?: false ]
    ]
    btn-next: button "next" [
        unless btn-prev/enabled? [ btn-prev/enabled?: true ]
        either index < length? drawings [
            index: index + 2 
            label/text: drawings/(index - 1)
            canvas/draw: drawings/:index 
            show canvas
        ][ btn-next/enabled?: false ]
    ]
    do [
        label/text: drawings/(index - 1)
        canvas/draw: drawings/:index
        btn-prev/enabled?: false
    ]
]
board/text: "Shape sub dialect demo"
view board 
