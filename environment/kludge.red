Red [Note: "Ad-hoc loader for money! datatype."]

forge: routine [
	sign    [integer!]
	amount1 [integer!]
	amount2 [integer!]
	amount3 [integer!]
][
	stack/set-last as red-value! money/push sign amount1 amount2 amount3
]

coin: function [
	string [string!]
	/local
		sign integral fractional
][
	digit:     charset [#"0" - #"9"]
	precision: 22
	scale:     05
	digits:    precision - scale
		
	either parse string [
		set sign opt [#"-" | #"+"]
		#"$" [
			some #"0" end (integral: #"0")
			| any #"0" copy integral [1 digits digit]
			  opt [[dot | comma] copy fractional [1 scale digit]]
			  end
		]
	][
		string: rejoin [
			pad/left/with integral digits #"0"
			pad/with any [fractional copy ""] scale #"0"
		]
		
		sign:   select [#"-" 1 #"+" 0 #[none] 0] sign		
		binary: debase/base string 16
		
		insert binary 0 ; placeholder for currency index
		slice'n'dice: [loop 3 [keep to integer! reverse take/part binary 4]] ; little-endian order
		
		do compose [forge sign (collect slice'n'dice)]
	][
		make error! "Cannot load this."
	]
]
