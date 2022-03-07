Red []

debug: :print
;debug: :comment

state: 'none
ending: "61842c0e-5631-46cb-9748-b390a5da5256"

data: read/binary %/d/conan-win-64.exe
print length? data

client: open tcp://127.0.0.1:8223

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [state: 'send insert port data]
        read [state: 'none probe to-string port/data close port]
        wrote [
	        case [
	        	state = 'send [state: 'sent insert port ending]
	        	state = 'sent [copy port]
        	]
		]
    ]
]

if none? system/view [
	wait client
]
