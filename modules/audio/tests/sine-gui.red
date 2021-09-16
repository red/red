Red [needs: [view audio]]

;-- init globals

port: open audio://
wave: make audio-codecs/audio! [
	rate:        44100
	channels:    2
	bits:        32
	sample-type: float!
]
rate: wave/rate

chunk-ms:      50										;-- size of single audio buffer refill; affects latency
buffer-ms:     1001 + chunk-ms
chunk-samples: (to integer! chunk-ms / 1000 * rate) * 2
n-frames:      to integer! buffer-ms / 1000 * rate


;-- prepare a 'periods' vector of 0 0 2pi 2pi 4pi 4pi 6pi 6pi...
;-- and a 'noise' vector of white noise

periods: make vector! reduce [
	to word! wave/sample-type
	wave/bits
	n-frames * 2
]
noise: copy periods

repeat i n-frames [
	change/dup
		skip periods j: i - 1 * 2
		i - 1 * 2 * pi
		2
	change/dup
		skip noise   j
		-1 + random 2.0
		2
]


;-- wave processing funcs

r: reactor [freq: 0 tone-vol: 0.0 noise-vol: 0.0 balance: 0.0]

rebalance: function [data] [
	if r/balance = 0 [return data]
	p: r/balance + 1 * pi / 4
	bal: reduce [cos p sin p]
	v: make vector! reduce [to word! wave/sample-type wave/bits n: length? data]
	change/dup v bal to integer! round/ceiling n / 2
	data: data * v
]

phase: 0.0 offset: 0
refill: function [/extern phase offset] [
	; exhausted?: (length? port) < (chunk-samples / 2)		NOT WORKING
	exhausted?: yes
	unless exhausted? [exit]

	noise-chunk:   (copy/part  skip noise   offset  chunk-samples)
	v: tone-chunk: (copy/part  skip periods offset  chunk-samples) * (r/freq / rate)
	repeat i length? v [v/:i: sin v/:i]					;-- render the sine wave

	v: wave/data: add
		tone-chunk  * (10.0 ** (r/tone-vol  / 20))
		noise-chunk * (10.0 ** (r/noise-vol / 20))

	wave/data: rebalance wave/data
	append port wave

	offset: offset + chunk-samples % (rate * 2)
	phase:  offset / rate * r/freq % 1.0
]


;-- init GUI

view [
	panel 3 [
		text "Frequency:" freq-slider:
		slider 500 data 0.5 focus
			react [r/freq: to integer! 1000 ** (1.0 * face/data) * 20]
		text react [face/text: rejoin [r/freq " Hz"]]
		
		text "Volume:"
		slider 500 data 0.8
			react [r/tone-vol:  negate 1.0 - face/data * 100]
		text react [face/text: rejoin [r/tone-vol " dB"]]

		text "Dithering:"
		slider 500 data 0.04
			react [r/noise-vol: negate 1.0 - face/data * 100]
		text react [face/text: rejoin [r/noise-vol " dB"]]

		text "L/R balance:"
		slider 500 data 0.5
			react [r/balance: face/data * 2 - 1]
		text react [
			face/text: case [
				r/balance = 0.0 ["C"]
				r/balance < 0 [rejoin [to integer! -100 * r/balance "% L"]]
				'positive     [rejoin [to integer!  100 * r/balance "% R"]]
			]
		]

		button "Quit" [unview] rate 100 on-time [refill]
	]
	do [
		set-focus freq-slider
		react [r/freq r/balance r/tone-vol r/noise-vol  refill]
	]
]

close port
