Red/System [
	Title: "Red/System ARM64 global pointer layout smoke test"
]

#if target = 'ARM64 [
	pA: declare pointer! [integer!]
	pB: declare pointer! [integer!]
	pA: declare pointer! [integer!]
	pB: declare pointer! [integer!]
	ppc: declare pointer! [pointer!]
	ppc: as pointer! [pointer!] :pA
	print-line [
		"pA-slot=" :pA
		" pB-slot=" :pB
		" ppc1=" ppc/1
		" pA=" pA
		" ppc3=" ppc/3
		" pB=" pB
	]
]
