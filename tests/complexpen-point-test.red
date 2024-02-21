Red [
	Title:  "Red complex pen test"
	Author: "Iosif Haidu"
    Tabs:   4
	File: 	%complexpen-test.red
	Needs:	View
]

start-x: 30
start-y: 30
width:  150
height: 100
step-x: 10
step-y: 30

box-start: (0,0)
box-stop: (0,0)

bitmap-1: make image! 30x30
draw bitmap-1 [line (0,0) (30,30)]
bitmap-2: make image! 30x30
draw bitmap-2 [fill-pen red pen off box (0,0) (30,30) pen black circle (15,15) 10]
bitmap-3: make image! 30x30
draw bitmap-3 [fill-pen blue pen off box (0,0) (30,30) pen black triangle (10,0) (0,30) (30,30)]
bitmap-4: make image! 60x90
draw bitmap-4 [
    line-width 1 
    pen off 
    fill-pen black push [clip (0,0) (60,90) intersect push [fill-pen black line-width 1 pen off scale 1.0 1.5 push [fill-pen 109.105.92 line-width 1 pen off box (0,0) (98,98)] push [fill-pen 98.95.83 line-width 1 pen off translate (30,0) rotate 45.0 box (0,0) (41,41)] push [fill-pen 113.111.100 line-width 1 pen off rotate 45.0 box (0,0) (98,0)] push [fill-pen 113.111.100 line-width 1 pen off translate (0,60) rotate -45.0 box (0,0) (98,0)]]]
]
bitmap-5: make image! 8x8
draw bitmap-5 [
    line-width 1 
    pen off 
    fill-pen black push [clip (0,0) (8,8) intersect push [fill-pen 64.60.63 line-width 1 pen off box (0,0) (8,8)] push [fill-pen black line-width 1 pen 30.41.45.0 line-width 1 shape [move (0,0) line (8,8) move (8,0) line (0,8)]]]
]
bitmap-6: make image! 50x90
draw bitmap-6 [
    line-width 1 
    pen off 
    fill-pen black push [clip (0,0) (50,90) intersect push [fill-pen 128.128.128 line-width 1 pen off box (0,0) (50,90)] push [fill-pen 192.192.192 line-width 1 pen off box (25,0) (50,90)]]
]

;pattern-1-size: as-point2D start-x + (4 * (width + step-x)) start-y + height + step-y
pattern-1-size: as-point2D 4 * (width + step-x) height
pattern-1: compose/deep [
    pen off 
    ;fill-pen linear 240.16.144 0.0 0.192.240 1.0 (as-point2D start-x start-y) (pattern-1-size) 
    fill-pen linear 240.16.144 0.0 0.192.240 1.0 (0,0) (pattern-1-size) 
    pen off 
    ;box (as-point2D start-x start-y) (pattern-1-size)
    box (0,0) (pattern-1-size)
    fill-pen pattern (8,8) [
        fill-pen off push [
            clip (0,0) (8,8) intersect push [
                fill-pen black pen 32.32.32.0 line-width 4
                shape [
                    move (-2,10) 
                    line (10,-2) 
                    move (10,6) 
                    line (6,10) 
                    move (-2,2) 
                    line (2,-2)
                ]
            ]
        ]
    ] 
    ;box (as-point2D start-x start-y) (pattern-1-size) 
    box (0,0) (pattern-1-size) 
]
pattern-2: [
    line-width 1 
    pen off 
    fill-pen black push [
        clip (0,0) (15,15) intersect push [
            fill-pen 79.99.141 line-width 1 pen off box (0,0) (15,15)
        ] 
        push [
            fill-pen 48.51.85 line-width 1 pen off 
            shape [
                move (0,15) line (7,0) line (15,15)
            ]
        ]
    ]
] 
pattern-3: [
    line-width 1 
    pen off 
    fill-pen black push [
        clip (0,0) (20,20) intersect push [
            fill-pen 128.160.48 line-width 1 pen off box (0,0) (40,40)
        ] 
        push [
            fill-pen off line-width 1 pen 96.16.48.0 line-width 1
            circle (0,0) 9.2
        ] 
        push [
            fill-pen off line-width 1 pen 96.16.48.0 line-width 1
            circle (0,18) 9.2
        ] 
        push [
            fill-pen off line-width 1 pen 96.16.48.0 line-width 1 
            circle (18,18) 9.2
        ]
    ]
]


drawings: [
    "FILL LINEAR GRADIENT"
    [
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0"
        fill-pen linear red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,0)"
        fill-pen linear red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (1 * (width + step-x)) start-y 
                box-stop: as-point2D start-x + width + (1 * (width + step-x)) start-y + height
                box-start + (0,0)
            )
            (box-start + (50,0))
	    repeat
        box (box-start) (box-stop)

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,50)"
        fill-pen linear red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (2 * (width + step-x)) start-y 
                box-stop: as-point2D start-x + width + (2 * (width + step-x)) start-y + height
                box-start + (0,0)
            )
            (box-start + (50,50))
	    repeat
        box (box-start) (box-stop)

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,0) reflect"
        fill-pen linear red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (3 * (width + step-x)) start-y 
                box-stop: as-point2D start-x + width + (3 * (width + step-x)) start-y + height
                box-start + (0,0)
            )
            (box-start + (50,0))
            reflect
        box (box-start) (box-stop)


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops"
        fill-pen linear red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,0)"
        fill-pen linear red green blue
            (
                box-start: as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (1 * (width + step-x)) start-y + height + (1 * (height + step-y))
                box-start + (0,0)
            )
            (box-start + (50,0))
	    repeat
        box (box-start) (box-stop)

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,50)"
        fill-pen linear red green blue
            (
                box-start: as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (2 * (width + step-x)) start-y + height + (1 * (height + step-y))
                box-start + (0,0)
            )
            (box-start + (50,50))
	    repeat
        box (box-start) (box-stop)

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,0) reflect"
        fill-pen linear red green blue
            (
                box-start: as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (3 * (width + step-x)) start-y + height + (1 * (height + step-y))
                box-start + (0,0)
            )
            (box-start + (50,0))
            reflect
        box (box-start) (box-stop)

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        fill-pen linear red green blue scale 'fill-pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 45"
        fill-pen linear red green blue repeat rotate 'fill-pen 45 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        fill-pen linear red green blue repeat translate 'fill-pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (50,50)"
        fill-pen linear red green blue repeat skew 'fill-pen 50 50
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "FILL RADIAL GRADIENT"
    [
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0;c=f;r=max"
        fill-pen radial red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;r=50"
        fill-pen radial red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (1 * (width + step-x)) start-y
                box-stop: as-point2D start-x + width + (1 * (width + step-x)) start-y + height
                box-start + (100,100)
            )
            50
        box (box-start) (box-stop)

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;r=50"
        fill-pen radial red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (2 * (width + step-x)) start-y
                box-stop: as-point2D start-x + width + (2 * (width + step-x)) start-y + height
                box-start + (100,100)
            )
            50
            ((80,80) - (100,100))
        box (box-start) (box-stop)

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;reflect"
        fill-pen radial red 0.1 green 0.8 blue 1.0
            (
                box-start: as-point2D start-x + (3 * (width + step-x)) start-y
                box-stop: as-point2D start-x + width + (3 * (width + step-x)) start-y + height
                box-start + (70,100)
            )
            50
            ((50,80) - (70,100))
            reflect
        box (box-start) (box-stop)


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;r=max"
        fill-pen radial red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;r=50"
        fill-pen radial red green blue
            (
                box-start: as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(1 * (height + step-y))
                box-start + (100,100)
            )
            50
        box (box-start) (box-stop)

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;r=50"
        fill-pen radial red green blue
            (
                box-start: as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(1 * (height + step-y))
                box-start + (100,100)
            )
            50
            ((80,80) - (100,100))
        box (box-start) (box-stop)

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;reflect"
        fill-pen radial red green blue
            (
                box-start: as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y))
                box-stop: as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(1 * (height + step-y))
                box-start + (70,100)
            )
            50
            ((50,80) - (70,100))
            reflect
        box (box-start) (box-stop)

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        fill-pen radial red green blue scale 'fill-pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 15"
        fill-pen radial red green blue rotate 'fill-pen 15 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        fill-pen radial red green blue translate 'fill-pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (15,15)"
        fill-pen radial red green blue skew 'fill-pen 15 15
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "FILL DIAMOND GRADIENT"
    [
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0;c=f;max"
        fill-pen diamond red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;small"
        fill-pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50)
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;small"
        fill-pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50) (5,5)  
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;reflect"
        fill-pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50) (5,5) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;max"
        fill-pen diamond red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;small"
        fill-pen diamond red green blue  (0,0) (50,50)
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;small"
        fill-pen diamond red green blue (0,0) (50,50) (5,5)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;reflect"
        fill-pen diamond red green blue (0,0) (50,50) (5,5) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        fill-pen diamond red green blue scale 'fill-pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 15"
        fill-pen diamond red green blue rotate 'fill-pen 15 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        fill-pen diamond red green blue translate 'fill-pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        6
        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (15,15)"
        fill-pen diamond red green blue skew 'fill-pen 15 15
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "PEN LINEAR GRADIENT"
    [
        line-width 9
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0"
        pen linear red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,0)"
        pen linear red 0.1 green 0.8 blue 1.0 (0,0) (50,0) repeat
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,50)"
        pen linear red 0.1 green 0.8 blue 1.0 (0,0) (50,50) repeat
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0; (50,0) reflect"
        pen linear red 0.1 green 0.8 blue 1.0 (0,0) (50,0) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops"
        pen linear red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,0)"
        pen linear red green blue (0,0) (50,0) repeat
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,50)"
        pen linear red green blue (0,0) (50,50) repeat
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops; (50,0) reflect"
        pen linear red green blue (0,0) (50,0) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        pen linear red green blue scale 'pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 45"
        pen linear red green blue repeat rotate 'pen 45 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        pen linear red green blue repeat translate 'pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (50,50)"
        pen linear red green blue repeat skew 'pen 50 50
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "PEN RADIAL GRADIENT"
    [
        line-width 9
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0;c=f;r=max"
        pen radial red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;r=50"
        pen radial red 0.1 green 0.8 blue 1.0  (100,100) 50
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;r=50"
        pen radial red 0.1 green 0.8 blue 1.0 (100,100) 50 (80,80)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;reflect"
        pen radial red 0.1 green 0.8 blue 1.0 (70,100) 50 (50,80) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;r=max"
        pen radial red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;r=50"
        pen radial red green blue (100,100) 50 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;r=50"
        pen radial red green blue (100,100) 50 (80,80)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;reflect"
        pen radial red green blue  (70,100) 50 (50,80) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        pen radial red green blue scale 'pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 15"
        pen radial red green blue rotate 'pen 15 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        pen radial red green blue translate 'pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (15,15)"
        pen radial red green blue skew 'pen 15 15
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "PEN DIAMOND GRADIENT"
    [
        line-width 9
        text ( as-point2D start-x start-y - 20 ) "0.1, 0.8, 1.0;c=f;max"
        pen diamond red 0.1 green 0.8 blue 1.0
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c=f;small"
        pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50)
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;small"
        pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50) (5,5)  
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "0.1, 0.8, 1.0;c<>f;reflect"
        pen diamond red 0.1 green 0.8 blue 1.0 (0,0) (50,50) (5,5) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;max"
        pen diamond red green blue
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c=f;small"
        pen diamond red green blue  (0,0) (50,50)
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;small"
        pen diamond red green blue (0,0) (50,50) (5,5)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "no stops;c<>f;reflect"
        pen diamond red green blue (0,0) (50,50) (5,5) reflect
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(1 * (height + step-y)) )

        
        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "no stops; scale 2 1"
        pen diamond red green blue scale 'pen 2 1 
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; rotate 15"
        pen diamond red green blue rotate 'pen 15 
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
        
        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; translate (50,0)"
        pen diamond red green blue translate 'pen (50,0)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "no stops; skew (15,15)"
        pen diamond red green blue skew 'pen 15 15
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )
    ]

    "BITMAP FILL"
    [
        text ( as-point2D start-x start-y - 20 ) "lines"
        fill-pen bitmap bitmap-1 (1,1) (30,20)
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + width start-y + height )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y - 20 ) "circles"
        fill-pen bitmap bitmap-2 (1,1) (30,30)
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y - 20 ) "triangles"
        fill-pen bitmap bitmap-3  (1,1) (30,30)
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y - 20 ) "argile"
        fill-pen bitmap bitmap-4 (1,1) (60,90)
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "cross stripes"
        fill-pen bitmap bitmap-5 (1,1) (8,8)
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + (4 * (width + step-x)) start-y + height + (1 * (height + step-y)) )


        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "vertical stripes"
        fill-pen bitmap bitmap-6 (1,1) (50,90)
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + (4 * (width + step-x)) start-y + height + (2 * (height + step-y)) )
    ]

    "PATTERN FILL"
    [
        text ( as-point2D start-x start-y - 20 ) "dance"
        fill-pen pattern (pattern-1-size) [ (pattern-1) ]
        box 
            ( as-point2D start-x start-y ) 
            ( as-point2D start-x + (4 * (width + step-x)) start-y + height )


        text ( as-point2D start-x start-y + (1 * (height + step-y)) - 20 ) "halfrombs upper"
        fill-pen pattern (15,15) (1,1) (15,15) [ (pattern-2) ]  
        box 
            ( as-point2D start-x start-y + (1 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height +(1 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "circle centered"
        fill-pen pattern (15,15) (1,1) [ (pattern-2) ]
        circle
            ( as-point2D start-x + (1 * (width + step-x)) + (width / 2) start-y + (1 * (height + step-y) + (height / 2)) )
            (height / 2)

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "triangle centered"
        fill-pen pattern (15,15) (1,1) [ (pattern-2) ]
        triangle
            ( as-point2D start-x + (2 * (width + step-x)) + (width / 2) start-y + (1 * (height + step-y)) )
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (1 * (height + step-y) + height))
            ( as-point2D start-x + (2 * (width + step-x)) + width start-y + (1 * (height + step-y) + height))

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) - 20 ) "shape centered"
        fill-pen pattern (15,15) (1,1) [ (pattern-2) ]
        shape [
            move ( as-point2D start-x + (3 * (width + step-x)) start-y + (1 * (height + step-y)) )
            'line (as-point2D width 0)
            'line (as-point2D 0 height)
            'line (as-point2D 0 - width 0)
            'line (as-point2D 0 0 - height)
        ]


        text ( as-point2D start-x start-y + (2 * (height + step-y)) - 20 ) "microbial normal"
        fill-pen pattern (20,20) (1,1) (20,20) [ (pattern-3) ]
        box 
            ( as-point2D start-x start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width start-y + height + (2 * (height + step-y)) )

        text ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "microbial flip-x"
        fill-pen pattern (20,20) (1,1) flip-x [ (pattern-3) ]
        box 
            ( as-point2D start-x + (1 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (1 * (width + step-x)) start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "microbial flip-y"
        fill-pen pattern (20,20) (1,1) flip-y [ (pattern-3) ]
        box 
            ( as-point2D start-x + (2 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (2 * (width + step-x)) start-y + height +(2 * (height + step-y)) )

        text ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) - 20 ) "microbial flip-xy"
        fill-pen pattern (20,20) (1,1) flip-xy [ (pattern-3) ]
        box 
            ( as-point2D start-x + (3 * (width + step-x)) start-y + (2 * (height + step-y)) ) 
            ( as-point2D start-x + width + (3 * (width + step-x)) start-y + height +(2 * (height + step-y)) )

    ]
]

index: 2
board: layout [
    below
    label: text "" 400 font [size: 16]
    canvas: base (700,400)
    below
    across
    btn-prev: button "previous" [ 
        unless btn-next/enabled? [ btn-next/enabled?: true ]
        either index > 2 [
            index: index - 2 
            label/text: drawings/(index - 1)
            canvas/draw: compose/deep drawings/:index 
            show canvas
        ][ btn-prev/enabled?: false ]
    ]
    btn-next: button "next" [
        unless btn-prev/enabled? [ btn-prev/enabled?: true ]
        either index < length? drawings [
            index: index + 2 
            label/text: drawings/(index - 1)
            canvas/draw: compose/deep drawings/:index
            show canvas
        ][ btn-next/enabled?: false ]
    ]
    do [
        label/text: drawings/(index - 1)
        canvas/draw: compose/deep drawings/:index
        btn-prev/enabled?: false
    ]
]
board/text: "Complex pen demo"
view board 
