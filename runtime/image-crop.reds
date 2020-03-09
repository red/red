Red/System [
	Title:	"image-crop"
	Author: "bitbegin"
	File: 	%image-crop.reds
	Note:	"useful functions for image!"
	Tabs: 	4
	Rights: "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %vector2d.reds

CROP-VERTEX!: alias struct! [
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

image-crop: context [

	on-plane?: func [
		vertex	[CROP-VERTEX!]
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
		sw			[integer!]		;-- width
		sh			[integer!]		;-- height
		x			[integer!]		;-- start.x
		y			[integer!]		;-- start.y
		dw			[integer!]		;-- width
		dh			[integer!]		;-- height
		dst			[byte-ptr!]
		return:		[logic!]
		/local
			ss		[integer!]		;-- stride
			ds		[integer!]		;-- stride
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
			x + dw >= sw
			y + dh >= sh
		][
			return false
		]
		offset: y * ss + x * 4
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
		sw			[integer!]		;-- width
		sh			[integer!]		;-- height
		vertex		[CROP-VERTEX!]
		dx			[int-ptr!]
		dy			[int-ptr!]
		dw			[int-ptr!]		;-- width
		dh			[int-ptr!]		;-- height
		return:		[int-ptr!]
		/local
			xmin	[float32!]
			ymin	[float32!]
			xmax	[float32!]
			ymax	[float32!]
			p		[pointer! [float32!]]
			rect.x	[integer!]
			rect.y	[integer!]
			rect.w	[integer!]
			rect.h	[integer!]
			size	[integer!]
			AB		[VECTOR2D! value]
			BC		[VECTOR2D! value]
			CD		[VECTOR2D! value]
			DA		[VECTOR2D! value]
			src.w	[float!]
			src.h	[float!]
			rgba	[int-ptr!]
			i		[integer!]
			j		[integer!]
			fi		[float32!]
			fj		[float32!]
			v		[VECTOR2D! value]
			dab		[float!]
			dbc		[float!]
			dcd		[float!]
			dda		[float!]
			fx		[float!]
			fy		[float!]
			ix		[integer!]
			iy		[integer!]
			si		[integer!]
			di		[integer!]
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
		if rect.w < 0 [rect.w: 0 - rect.w]
		if rect.h < 0 [rect.h: 0 - rect.h]
		size: rect.w * rect.h * 4
		rgba: as int-ptr! allocate size
		set-memory as byte-ptr! rgba null-byte size
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
					fx: src.w * (dda / (dda + dbc))
					fy: src.h * (dab / (dab + dcd))
					ix: as integer! fx
					iy: as integer! fy
					if all [
						ix >= 0
						ix < sw
						iy >= 0
						iy < sh
					][
						di: j * rect.w + i + 1
						si: iy * src.w + ix + 1
						rgba/di: src/si
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
			vertex	[CROP-VERTEX! value]
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
]
