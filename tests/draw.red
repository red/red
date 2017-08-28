Red [
	Title:	"Tests for draw dialect"
	Author: "Fyodor Shchukin"
	File:	%draw.red
	Tabs:	4
]

l: layout [
	title "Draw test"

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		line 10x10 40x30 10x30
		line 10x40 40x40

		text 5x55 "line"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		triangle 10x10 40x10 25x40

		text 5x55 "triangle"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 40x20
		box 20x30 30x40

		text 5x55 "box"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		polygon 10x10 40x10 40x40 20x30

		text 5x55 "polygon"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		circle 25x25 15
		circle 25x25 10 5

		text 5x55 "circle"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		ellipse 10x10 5x10
		ellipse 35x10 5x10
		ellipse 20x20 10x20

		text 5x55 "ellipse"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		;arc <center> <radius> <begin> <sweep> closed
		arc 25x25 15x15 0 180 closed
		arc 25x25 5x10 90 270 

		text 5x55 "arc"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		curve 10x5  45x5        45x40
		curve 10x10 40x10 10x40 40x40

		text 5x55 "curve"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		spline 10x10 40x10 40x40 10x40

		text 5x55 "spline"
	]

	base 50x60 100.70.70 draw [
		line-width 2
		fill-pen 170.20.20.128 

		;image

		text 5x55 "image"
	]

	base 50x60 100.70.70 draw [
		text 5x55 "text"

		text 10x20 "Red"
		pen red						; test if pen color
		font font-A 
		text 10x30 "Red"
	]

	base 50x60 100.70.70 draw [
		text 5x55 "pen flat"

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
		text 5x55 "pen gradient"

		pen linear red green blue
		line-width 5
		fill-pen off 
		box 10x10 40x40
	]

	base 50x60 100.70.70 draw [
		text 5x55 "fill gradient"

		fill-pen linear red green blue
		box 10x10 40x40
	]

	base 50x60 100.70.70 draw [
		text 5x55 "line join"
		
		line-width 5

		line-join miter
		line 10x40 15x20 20x40
		line-join round
		line 20x40 25x20 30x40
		line-join bevel
		line 30x40 35x20 40x40
	]

	base 50x60 100.70.70 draw [
		text 5x55 "line cap"
		
		line-width 7

		line-cap flat
		line 15x15 15x35
		line-cap square
		line 25x15 25x35
		line-cap round
		line 35x15 35x35
	]

	return

	; . . .

	base 230x2 0.0.0

	return

	base 50x60 70.70.100 draw [
		text 5x55 "rotate"

		line-width 2
		fill-pen 170.20.20.128 

		box 15x15 35x35
		rotate 45 25x25
		box 15x15 35x35
	]

	base 50x60 70.70.100 draw [
		text 5x55 "scale"

		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 40x40
		scale 0.5 0.5
		box 10x10 40x40
	]

	base 50x60 70.70.100 draw [
		text 5x55 "translate"

		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 30x30
		translate 10x10
		box 10x10 30x30
	]

	base 50x60 70.70.100 draw [
		text 5x55 "translate"

		line-width 2
		fill-pen 170.20.20.128 

		box 10x10 30x30
		translate 10x10
		box 10x10 30x30
	]
]

font-A: make font! [
	name: "Comic Sans MS"
	size: 10
	color: blue
	style: [bold italic underline]
	anti-alias?: yes
]

view l

