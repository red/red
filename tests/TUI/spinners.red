Red [
	Needs: 'View
	Config: [GUI-engine: 'terminal]
]

spinners: [
	Line [
		["|" "/" "-" "\"]		;-- style
		10						;-- rate
	]
	Dot [
		["⣾ " "⣽ " "⣻ " "⢿ " "⡿ " "⣟ " "⣯ " "⣷ "]
		10
	]
	MiniDot [
		["⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"]
		12
	]
	Jump [
		["⢄" "⢂" "⢁" "⡁" "⡈" "⡐" "⡠"]
		10
	]
	Pulse [
		["█" "▓" "▒" "░"]
		8
	]
	Points [
		["∙∙∙" "●∙∙" "∙●∙" "∙∙●"]
		7
	]
	Globe [
		["🌍" "🌎" "🌏"]
		4
	]
	Moon [
		["🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘"]
		8
	]
	Monkey [
		["🙈" "🙉" "🙊"]
		3
	]
	Meter [
		[
			"▱▱▱"
			"▰▱▱"
			"▰▰▱"
			"▰▰▰"
			"▰▰▱"
			"▰▱▱"
			"▱▱▱"
		]
		7
	]
	Hamburger [
		["☱" "☲" "☴" "☲"]
		3
	]
]

spinner: 0
frame: 0

view [
	on-key [
		spinner-n: (length? spinners) / 2
		switch event/key [
			left	[spinner: either zero? spinner [spinner-n - 1][spinner - 1]]
			right	[spinner: spinner + 1 % spinner-n]
		]
		b/rate: second pick spinners spinner + 1 * 2
		b/font/color: random 255.255.255
	]
	b: box 6x2 font-color sky rate 10 on-time [
		frames: first pick spinners spinner + 1 * 2
		face/text: pick frames (frame % length? frames) + 1
		frame: frame + 1
	] return
	text font-color gray "<-/->: change spinner"
]
