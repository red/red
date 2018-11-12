Red [
	Needs: 'View
]


view [
	button "<" 20 [s1/data: s1/data - 0.05]
	button ">" 20 [s1/data: s1/data + 0.05]
	text "0.0" react later [face/data: s1/data]
	
	button "^^" 20 [s2/data: s2/data - 0.05]
	button "v"  20 [s2/data: s2/data + 0.05]
	text "0.0" react later [face/data: s2/data]
	return
	
	button "<" 20 [s1/selected: s1/selected - 5%]
	button ">" 20 [s1/selected: s1/selected + 5%]
	t1: text "10%" react later [face/data: s1/selected]
	
	button "^^" 20 [s2/selected: s2/selected - 0.05]
	button "v"  20 [s2/selected: s2/selected + 0.05]
	text "10%" react later [face/data: s2/selected]
	return
	
	s1: scroller
	s2: scroller 20x200 with [steps: .3]
]
