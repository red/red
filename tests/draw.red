Red [
	Title:	"Tests for draw dialect"
	Author: "Fyodor Shchukin"
	File:	%draw.red
	Needs:	View
	Tabs:	4
]

l: layout [
	title "Draw test"

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		line 10x10 40x30 10x30
		line 10x40 40x40

		font font-label
		text 5x45 "line"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		triangle 10x10 40x10 25x40

		font font-label
		text 5x45 "triangle"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 40x20
		box 20x30 30x40

		font font-label	
		text 5x45 "box"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		polygon 10x10 40x10 40x40 20x30

		font font-label
		text 5x45 "polygon"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		circle 25x25 15
		circle 25x25 10 5

		font font-label
		text 5x45 "circle"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		ellipse 10x10 5x10
		ellipse 35x10 5x10
		ellipse 20x20 10x20

		font font-label	
		text 5x45 "ellipse"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		;arc <center> <radius> <begin> <sweep> closed
		arc 25x25 15x15 0 180 closed
		arc 25x25 5x10 90 270 

		font font-label
		text 5x45 "arc"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		curve 10x5  45x5        45x40
		curve 10x10 40x10 10x40 40x40

		font font-label
		text 5x45 "curve"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		spline 10x10 40x10 40x40 10x40 10x20 30x20 30x30 20x30

		font font-label	
		text 5x45 "spline"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		image fstk-logo 10x10 40x40

		font font-label	
		text 5x45 "image"
	]

	base 50x60 100.70.70 draw [
		font font-label
		text 5x45 "text"

		text 10x10 "Red"
		pen red						; test if pen color
		font font-A 
		text 10x20 "Red"
	]

	base 50x60 100.70.70 draw [
		font font-label
		text 5x45 "pen flat"

		line 10x10 10x40
		box 15x10 20x40

		pen off
		fill-pen 20.20.170.128
		box 25x10 30x40

		pen 255.255.255.100 
		line-width 1 
		triangle 35x10 40x40 35x40

		fill-pen off
		triangle 35x10 40x10 40x40
	]

	return

	base 50x60 100.70.70 draw [
		font font-label
		text 5x45 "pen gradient"

		pen linear red green blue
		line-width 5
		fill-pen off 
		box 10x10 40x40
	]

	base 50x60 100.70.70 draw [
		font font-label	
		text 5x45 "linear gradient"
		fill-pen linear 4x4 0 40 0 1.0 1.0 red green blue
		box 10x10 40x40
	]

	base 50x60 100.70.70 draw [
		font font-label	
		text 5x45 "radial gradient"
		fill-pen radial 25x25 0 15  0 1.0 1.0 red green blue 
    	box 10x10 40x40
	]

	base 50x60 100.70.70 draw [
		font font-label	
		text 5x45 "line join"
		
		line-width 5

		line-join miter
		line 10x40 15x20 20x40
		line-join round
		line 20x40 25x20 30x40
		line-join bevel
		line 30x40 35x20 40x40
	]

	return

	base 230x2 0.0.0 return
	; . . .

	base 50x60 100.70.70 draw [
		font font-label	
		text 5x45 "line cap"
		
		line-width 7

		line-cap flat
		line 15x15 15x35
		line-cap square
		line 25x15 25x35
		line-cap round
		line 35x15 35x35
	]

	base 50x60 70.70.100 draw [
		font font-label
		text 5x45 "rotate"

		line-width 2
		fill-pen 170.20.20.128 

		box 15x15 35x35
		rotate 45 25x25
		box 15x15 35x35
	]

	base 50x60 70.70.100 draw [
		font font-label	
		text 5x45 "scale"

		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 40x40
		scale 0.5 0.5
		box 10x10 40x40
	]

	base 50x60 70.70.100 draw [
		font font-label
		text 5x45 "translate"

		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 30x30
		translate 10x10
		box 10x10 30x30
	]

]

font-label: make font! [
	name: "Arial"
	size: 11
	color: white
	anti-alias?: no 
]

font-A: make font! [
	name: "Times New Roman"
	size: 15
	color: red
	style: [bold italic underline]
	anti-alias?: yes
]

fstk-logo: load/as 64#{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
		 wAAAABJRU5ErkJggg==
	} 'png

view l

