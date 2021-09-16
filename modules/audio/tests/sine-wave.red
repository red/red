Red [Needs: audio]

port: open audio://
ring: make audio-codecs/audio! [channels: 2 bits: 32 sample-type: float!]

N_FRAMES: 100000
N_CHANNELS: ring/channels

freq: 880.0
pi: 3.141593
rate: to float! ring/rate
delta: freq * pi / rate
phase: 0.0
n: 1

data: make vector! compose [float! 32 (N_FRAMES * N_CHANNELS)]
loop N_FRAMES [
	nsample: 0.2 * sin phase
	phase: mod phase + delta 2.0 * pi
	loop N_CHANNELS [
		poke data n nsample
		n: n + 1
	]
]
ring/data: data

insert port ring
wait port
close port