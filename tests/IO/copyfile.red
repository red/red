Red [
    title: "Copy File"
    Needs: View
]

file-src: none
file-dst: none
port-src: none
port-dst: none

total-size: 0.0
read-cnt: 0.0
amount: 0.0

select-src: func [face event][
	if file-src: request-file [
		f1/text: to-local-file file-src
		total-size: to float! size? file-src
		file-src: rejoin [file:// file-src]
	]
]

select-dst: func [face event][
	if file-dst: request-file/save [
		f2/text: to-local-file file-dst
		file-dst: rejoin [file:// file-dst]
	]
]

view [
	text "Source File: " f1: field 300 button "Select" :select-src return
	text "Destination: " f2: field 300 button "Select" :select-dst return
	base 160.160.160 460x1 return
	prog: progress hidden 390x23 button "Copy" [
		if any [not file-src not file-dst][exit]
		prog/data: 0.0
		read-cnt: 0.0
		amount: 0.0
		port-dst: open/write/new file-dst
		port-src: open file-src
		port-src/awake: func [event /local port][
			port: event/port
			switch event/type [
				connect	[copy port]
				read [
					read-cnt: read-cnt + length? port/data
					insert port-dst	port/data
				]
				error [			;-- end of file
					close port
					close port-dst
					prog/visible?: no
				]
			]
		]
		port-dst/awake: func [event /local r][
			if event/type = 'wrote [
				r: read-cnt / total-size
				if r - amount >= 0.005 [
					prog/data: r
					amount: r
				]
				copy port-src
			]
		]
		prog/visible?: yes
	]
]
