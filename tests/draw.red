Red [
	Title:	"Tests for draw dialect"
	Author: "Fyodor Shchukin"
	File:	%draw.red
	Tabs:	4
]

view [
	title "Draw test"

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 200.50.20 

		line 10x10 40x30
		line 10x40 40x40

		text 5x55 "line"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		triangle 10x10 40x10 25x40

		text 5x55 "triangle"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		box 10x10 40x20
		box 20x30 30x40

		text 5x55 "box"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		polygon 10x10 40x10 40x40 20x30

		text 5x55 "polygon"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		circle 25x25 15
		circle 25x25 10 5

		text 5x55 "circle"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		ellipse 10x10 5x10
		ellipse 35x10 5x10
		ellipse 20x20 10x20

		text 5x55 "ellipse"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		;arc <center> <radius> <begin> <sweep> closed
		arc 25x25 15x15 0 180 closed
		arc 25x25 5x10 90 270 

		text 5x55 "arc"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		curve 10x10 40x10 10x40 40x40
		curve 10x10 20x40       10x40

		text 5x55 "curve"
	]

	return

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		spline 10x10 40x40 40x40 10x40

		text 5x55 "spline"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		;image

		text 5x55 "image"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		text 10x20 "Red"
		;font font-A 
		text 10x30 "Red"

		text 5x55 "text"
	]

	base 50x60 100.70.70 draw [
		line-width 3
		fill-pen 120.20.20 

		text 5x55 "..."
	]

	return

	; . . .

	base 230x2 0.0.0

	return

	base 50x60 70.70.100 draw [
		text 5x55 "rotate"

		line-width 3
		fill-pen 120.20.20 

		box 15x15 35x35
		rotate 45 25x25
		box 15x15 35x35
	]

	base 50x60 70.70.100 draw [
		text 5x55 "scale"

		line-width 3
		fill-pen 120.20.20 

		box 10x10 40x40
		scale 0.5 0.5
		box 10x10 40x40
	]

	base 50x60 70.70.100 draw [
		text 5x55 "translate"

		line-width 3
		fill-pen 120.20.20 

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

