Red []

protos: [
	sslv3	0300h
	tls1.0	0301h
	tls1.1	0302h
	tls1.2	0303h
	tls1.3	0304h
]

debug: :print
;debug: :comment

state: 'none
ending: "61842c0e-5631-46cb-9748-b390a5da5256"

data: read/binary %/d/conan-win-64.exe
print length? data
print "TLS client"

client: open tls://127.0.0.1:8123

client/extra: compose [
    accept-invalid-cert: #[true]
    min-protocol: (protos/tls1.1)
    max-protocol: (protos/tls1.3)
]

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
