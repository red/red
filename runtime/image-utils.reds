Red/System [
	Title:	"image utils"
	Author: "bitbegin"
	File: 	%image-utils.reds
	Note:	"useful functions for image!"
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %vector2d.reds

TRANS-VERTEX!: alias struct! [
	v1x		[float32!]
	v1y		[float32!]
	v2x		[float32!]
	v2y		[float32!]
	v3x		[float32!]
	v3y		[float32!]
	v4x		[float32!]
	v4y		[float32!]
]

float32-max: as float32!  3.40282347E+38
float32-min: as float32! -3.40282347E+38

image-utils: context [

	flip-x: func [
		vertex	[TRANS-VERTEX!]
		x0		[float32!]
		/local
			p	[pointer! [float32!]]
			t	[float32!]
	][
		p: as pointer! [float32!] vertex
		loop 4 [
			t: x0 * as float32! 2.0
			p/1: t - p/1
			p: p + 2
		]
	]

	flip-y: func [
		vertex	[TRANS-VERTEX!]
		y0		[float32!]
		/local
			p	[pointer! [float32!]]
			t	[float32!]
	][
		p: as pointer! [float32!] vertex
		p: p + 1
		loop 4 [
			t: y0 * as float32! 2.0
			p/1: t - p/1
			p: p + 2
		]
	]

	on-plane?: func [
		vertex	[TRANS-VERTEX!]
		x		[float32!]
		y		[float32!]
		return:	[logic!]
	][
		if any [
			vector2d/ccw? x y vertex/v1x vertex/v1y vertex/v2x vertex/v2y
			vector2d/ccw? x y vertex/v2x vertex/v2y vertex/v3x vertex/v3y
			vector2d/ccw? x y vertex/v3x vertex/v3y vertex/v4x vertex/v4y
			vector2d/ccw? x y vertex/v4x vertex/v4y vertex/v1x vertex/v1y
		][return false]
		true
	]

	crop: func [
		src			[byte-ptr!]
		sw			[integer!]		;-- src width
		sh			[integer!]		;-- src height
		x			[integer!]		;-- start.x
		y			[integer!]		;-- start.y
		dw			[integer!]		;-- dst width
		dh			[integer!]		;-- dst height
		dst			[byte-ptr!]
		return:		[logic!]
		/local
			ss		[integer!]		;-- src stride
			ds		[integer!]		;-- dst stride
			offset	[integer!]
			from	[byte-ptr!]
			to		[byte-ptr!]
	][
		ss: sw * 4
		ds: dw * 4
		if any [
			x < 0
			y < 0
			x >= sw
			y >= sh
		][
			return false
		]
		if x + dw > sw [
			ds: sw - x * 4
		]
		if y + dh > sh [
			dh: sh - y
		]
		offset: y * ss + (x * 4)
		from: src + offset
		to: dst
		loop dh [
			copy-memory to from ds
			to: to + ds
			from: from + ss
		]
		true
	]

	transform: func [
		src			[int-ptr!]
		sw			[integer!]		;-- src width
		sh			[integer!]		;-- src height
		vertex		[TRANS-VERTEX!]
		dx			[int-ptr!]
		dy			[int-ptr!]
		dw			[int-ptr!]		;-- dst width
		dh			[int-ptr!]		;-- dst height
		return:		[int-ptr!]
		/local
			ps		[byte-ptr!]
			pd		[byte-ptr!]
			p		[pointer! [float32!]]
			AB		[VECTOR2D! value]
			BC		[VECTOR2D! value]
			CD		[VECTOR2D! value]
			DA		[VECTOR2D! value]
			v		[VECTOR2D! value]
			rgba	[int-ptr!]
			xmin	[float32!]
			ymin	[float32!]
			xmax	[float32!]
			ymax	[float32!]
			rect.x	[integer!]
			rect.y	[integer!]
			rect.w	[integer!]
			rect.h	[integer!]
			size	[integer!]
			src.w	[float!]
			src.h	[float!]
			i		[integer!]
			j		[integer!]
			fi		[float32!]
			fj		[float32!]
			dab		[float!]
			dbc		[float!]
			dcd		[float!]
			dda		[float!]
			fx		[float32!]
			fy		[float32!]
			x1		[integer!]
			y1		[integer!]
			si		[integer!]
			di		[integer!]
			x2		[integer!]
			y2		[integer!]
			dx1		[float32!]
			dx2		[float32!]
			dy1		[float32!]
			dy2		[float32!]
			dx1y1	[float32!]
			dx1y2	[float32!]
			dx2y1	[float32!]
			dx2y2	[float32!]
			ti		[integer!]
			c1		[float32!]
			c2		[float32!]
			c3		[float32!]
			c4		[float32!]
	][
		if any [
			sw <= 0
			sh <= 0
		][return null]
		xmin: float32-max
		ymin: float32-max
		xmax: float32-min
		ymax: float32-min
		p: as pointer! [float32!] vertex
		loop 4 [
			xmax: either xmax > p/1 [xmax][p/1]
			ymax: either ymax > p/2 [ymax][p/2]
			xmin: either xmin < p/1 [xmin][p/1]
			ymin: either ymin < p/2 [ymin][p/2]
			p: p + 2
		]
		rect.x: as integer! xmin
		rect.y: as integer! ymin
		rect.w: as integer! xmax - xmin
		rect.h: as integer! ymax - ymin

		dx/1: rect.x
		dy/1: rect.y
		dw/1: rect.w
		dh/1: rect.h

		vector2d/from-points AB vertex/v1x vertex/v1y vertex/v2x vertex/v2y
		vector2d/from-points BC vertex/v2x vertex/v2y vertex/v3x vertex/v3y
		vector2d/from-points CD vertex/v3x vertex/v3y vertex/v4x vertex/v4y
		vector2d/from-points DA vertex/v4x vertex/v4y vertex/v1x vertex/v1y
		vector2d/unit AB
		vector2d/unit BC
		vector2d/unit CD
		vector2d/unit DA

		src.w: as float! sw
		src.h: as float! sh
		size: rect.w * rect.h * 4
		rgba: as int-ptr! allocate size
		set-memory as byte-ptr! rgba #"^(00)" size
		i: 0 j: 0
		loop rect.h [
			i: 0
			loop rect.w [
				fi: as float32! i + rect.x
				fj: as float32! j + rect.y
				if on-plane? vertex fi fj [
					vector2d/from-points v vertex/v1x vertex/v1y fi fj
					dab: vector2d/cross-product v AB
					if dab < 0.0 [dab: 0.0 - dab]
					vector2d/from-points v vertex/v2x vertex/v2y fi fj
					dbc: vector2d/cross-product v BC
					if dbc < 0.0 [dbc: 0.0 - dbc]
					vector2d/from-points v vertex/v3x vertex/v3y fi fj
					dcd: vector2d/cross-product v CD
					if dcd < 0.0 [dcd: 0.0 - dcd]
					vector2d/from-points v vertex/v4x vertex/v4y fi fj
					dda: vector2d/cross-product v DA
					if dda < 0.0 [dda: 0.0 - dda]
					fx: as float32! src.w * (dda / (dda + dbc))
					fy: as float32! src.h * (dab / (dab + dcd))
					x1: as integer! fx
					y1: as integer! fy
					if all [
						x1 >= 0
						x1 < sw
						y1 >= 0
						y1 < sh
					][
						either true [
							x2: either x1 = (sw - 1) [x1][x1 + 1]
							y2: either y1 = (sh - 1) [y1][y1 + 1]
							dx1: fx - as float32! x1
							if dx1 < as float32! 0.0 [dx1: as float32! 0.0]
							dx2: dx1
							dx1: (as float32! 1.0) - dx1
							dy1: fy - as float32! y1
							if dy1 < as float32! 0.0 [dy1: as float32! 0.0]
							dy2: dy1
							dy1: (as float32! 1.0) - dy1
							dx1y1: dx1 * dy1
							dx1y2: dx1 * dy2
							dx2y1: dx2 * dy1
							dx2y2: dx2 * dy2
							di: j * rect.w + i
							pd: as byte-ptr! (rgba + di)

							si: y1 * sw + x1
							ps: as byte-ptr! (src + si)
							ti: as integer! ps/1
							c1: dx1y1 * as float32! ti
							ti: as integer! ps/2
							c2: dx1y1 * as float32! ti
							ti: as integer! ps/3
							c3: dx1y1 * as float32! ti
							ti: as integer! ps/4
							c4: dx1y1 * as float32! ti
							si: y1 * sw + x2
							ps: as byte-ptr! (src + si)
							ti: as integer! ps/1
							c1: c1 + (dx2y1 * as float32! ti)
							ti: as integer! ps/2
							c2: c2 + (dx2y1 * as float32! ti)
							ti: as integer! ps/3
							c3: c3 + (dx2y1 * as float32! ti)
							ti: as integer! ps/4
							c4: c4 + (dx2y1 * as float32! ti)
							si: y2 * sw + x1
							ps: as byte-ptr! (src + si)
							ti: as integer! ps/1
							c1: c1 + (dx1y2 * as float32! ti)
							ti: as integer! ps/2
							c2: c2 + (dx1y2 * as float32! ti)
							ti: as integer! ps/3
							c3: c3 + (dx1y2 * as float32! ti)
							ti: as integer! ps/4
							c4: c4 + (dx1y2 * as float32! ti)
							si: y2 * sw + x2
							ps: as byte-ptr! (src + si)
							ti: as integer! ps/1
							c1: c1 + (dx2y2 * as float32! ti)
							ti: as integer! ps/2
							c2: c2 + (dx2y2 * as float32! ti)
							ti: as integer! ps/3
							c3: c3 + (dx2y2 * as float32! ti)
							ti: as integer! ps/4
							c4: c4 + (dx2y2 * as float32! ti)
							ti: as integer! c1
							pd/1: as byte! ti
							ti: as integer! c2
							pd/2: as byte! ti
							ti: as integer! c3
							pd/3: as byte! ti
							ti: as integer! c4
							pd/4: as byte! ti
						][
							;-- simple transform
							di: j * rect.w + i + 1
							si: y1 * sw + x1 + 1
							rgba/di: src/si
						]
					]
				]
				i: i + 1
			]
			j: j + 1
		]

		rgba
	]

	resize: func [
		src			[int-ptr!]
		sw			[integer!]		;-- width
		sh			[integer!]		;-- height
		dw			[integer!]		;-- width
		dh			[integer!]		;-- height
		return:		[int-ptr!]
		/local
			vertex	[TRANS-VERTEX! value]
			w		[integer!]
			h		[integer!]
			x		[integer!]
			y		[integer!]
			p		[int-ptr!]
	][
		vertex/v1x: as float32! 0.0
		vertex/v1y: as float32! 0.0
		vertex/v2x: as float32! dw
		vertex/v2y: as float32! 0.0
		vertex/v3x: as float32! dw
		vertex/v3y: as float32! dh
		vertex/v4x: as float32! 0.0
		vertex/v4y: as float32! dh
		w: 0 h: 0 x: 0 y: 0
		p: transform src sw sh :vertex :x :y :w :h
		if null? p [return null]
		if any [
			w <> dw
			h <> dh
		][
			free as byte-ptr! p
			return null
		]
		p
	]

	#define YUYV_K1	91881
	#define YUYV_K2 46792
	#define YUYV_K3 21889
	#define YUYV_K4 116129

	#define YUYV_saturate(value min-val max-val) [
		case [
			value < min-val [value: min-val]
			value > max-val [value: max-val]
			true [0]
		]
	]

	YUYV-to-RGB32: func [
		width		[integer!]
		height		[integer!]
		src			[byte-ptr!]
		out			[int-ptr!]
		/local
			x y		[integer!]
			p		[byte-ptr!]
			uf vf	[integer!]
			R G B	[integer!]
			Y1 U Y2 V [integer!]
	][
		p: src
		y: 0
		while [y < height][
			x: 0
			while [x < width][
				Y1: as-integer p/1
				U:  as-integer p/2
				Y2: as-integer p/3
				V:  as-integer p/4

				uf: U - 128
				vf: V - 128

				R: Y1 + (YUYV_K1 * vf >> 16)
				G: Y1 - (YUYV_K2 * vf >> 16) - (YUYV_K3 * uf >> 16)
				B: Y1 + (YUYV_K4 * uf >> 16)

				YUYV_saturate(R 0 255)
				YUYV_saturate(G 0 255)
				YUYV_saturate(B 0 255)

				out/value: B << 16 or (G << 8) or R or FF000000h
				out: out + 1

				R: Y2 + (YUYV_K1 * vf >> 16)
				G: Y2 - (YUYV_K2 * vf >> 16) - (YUYV_K3 * uf >> 16)
				B: Y2 + (YUYV_K4 * uf >> 16)

				YUYV_saturate(R 0 255)
				YUYV_saturate(G 0 255)
				YUYV_saturate(B 0 255)

				out/value: B << 16 or (G << 8) or R or FF000000h
				out: out + 1
				p: p + 4
				x: x + 2
			]
			y: y + 1
		]
	]
]
