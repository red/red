Red/System [
	Title:	"2d vector"
	Author: "bitbegin"
	File: 	%vector2d.reds
	Note:	"2d vector lib for image"
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

VECTOR2D!: alias struct! [
	x	[float!]
	y	[float!]
]

vector2d: context [

	magnitude: func [vect [VECTOR2D!] return: [float!]][
		sqrt vect/x * vect/x + (vect/y * vect/y)
	]

	unit: func [vect [VECTOR2D!] /local mag [float!]][
		mag: magnitude vect
		vect/x: vect/x / mag
		vect/y: vect/y / mag
	]

	from-point: func [
		vect	[VECTOR2D!]
		px		[float32!]
		py		[float32!]
	][
		vect/x: as float! px
		vect/y: as float! py
	]

	from-points: func [
		vect	[VECTOR2D!]
		p1x		[float32!]
		p1y		[float32!]
		p2x		[float32!]
		p2y		[float32!]
	][
		vect/x: as float! p2x - p1x
		vect/y: as float! p2y - p1y
	]

	;-- A * B =|A|.|B|.sin(angle AOB)
	cross-product: func [v1 [VECTOR2D!] v2 [VECTOR2D!] return: [float!]][
		v1/x * v2/y - (v1/y * v2/x)
	]

	;-- A. B=|A|.|B|.cos(angle AOB)
	dot-product: func [v1 [VECTOR2D!] v2 [VECTOR2D!] return: [float!]][
		v1/x * v2/x + (v1/y * v2/y)
	]

	clockwise?: func [
		p1x		[float32!]
		p1y		[float32!]
		p2x		[float32!]
		p2y		[float32!]
		p3x		[float32!]
		p3y		[float32!]
		return:	[logic!]
		/local
			v21	[VECTOR2D! value]
			v23	[VECTOR2D! value]
	][
		from-points v21 p2x p2y p1x p1y
		from-points v23 p2x p2y p3x p3y
		0.0 > cross-product v21 v23		;-- sin(angle pt1 pt2 pt3) > 0, 0<angle pt1 pt2 pt3 <180
	]

	ccw?: func [
		p1x		[float32!]
		p1y		[float32!]
		p2x		[float32!]
		p2y		[float32!]
		p3x		[float32!]
		p3y		[float32!]
		return:	[logic!]
		/local
			v21	[VECTOR2D! value]
			v23	[VECTOR2D! value]
	][
		from-points v21 p2x p2y p1x p1y
		from-points v23 p2x p2y p3x p3y
		0.0 < cross-product v21 v23		;-- sin(angle pt2 pt1 pt3) < 0, 180<angle pt2 pt1 pt3 <360
	]

	distance: func [
		px		[float32!]
		py		[float32!]
		p1x		[float32!]
		p1y		[float32!]
		p2x		[float32!]
		p2y		[float32!]
		return:	[float!]
		/local
			v1	[VECTOR2D! value]
			v2	[VECTOR2D! value]
			ret	[float!]
	][
		from-points v1 p1x p1y p2x p2y
		from-points v2 p1x p1y px py
		unit v1
		ret: cross-product v2 v1
		if ret < 0.0 [ret: 0.0 - ret]
		ret
	]

	rotate: func [
		vect	[VECTOR2D!]
		degree	[integer!]
		/local
			rad	[float!]
			si	[float!]
			co	[float!]
			nx	[float!]
			ny	[float!]
	][
		rad: (as float! degree) * 3.14159265359 / 180.0
		si: sin rad
		co: cos rad
		nx: vect/x * co - (vect/y * si)
		ny: vect/x * si - (vect/y * co)
		vect/x: nx
		vect/y: ny
	]

]