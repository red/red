Red [
	Title:   "Para/align testing script"
	Author:  "WiseGenius"
	File: 	 %align-test.red
	Needs:	 'View
]

txt: {Hello, World!^/I left this right to write it left.^M^/The quick brown fox jumps over the lazy dog.^M^/Χαῖρε, κόσμε!}
sze: 144x89
view [
	group-box [
		group-box [
			a1: area txt sze
			f1: field txt sze
			t1: text txt sze
		]
		return
		group-box [
			text {align: }
			r1: radio {none}   [p1/align: none]
			r2: radio {left}   [p1/align: 'left]
			r3: radio {center} [p1/align: 'center]
			r4: radio {right}  [p1/align: 'right]
			return
			c1: check {wrap?}   [p1/wrap?: face/data]
		]
	]
	return
	group-box [
		group-box [
			a2: area txt sze
			f2: field txt sze
			t2: text txt sze
		]
		return
		group-box [
			text {align: }
			r5: radio {none}   [p2/align: none]
			r6: radio {left}   [p2/align: 'left]
			r7: radio {center} [p2/align: 'center]
			r8: radio {right}  [p2/align: 'right]
			return
			c2: check {wrap?}   [p2/wrap?: face/data]
		]
	]
    do [
    	a1/para: f1/para: t1/para: p1: make para! [align: 'right]
    	a2/para: f2/para: t2/para: p2: make para! []
    	r4/data: on
    	r5/data: on
    ]
]