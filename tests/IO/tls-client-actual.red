Red [
    title: "Basic Secure TCP test client"
]

protos: [
	sslv3	0300h
	tls1.0	0301h
	tls1.1	0302h
	tls1.2	0303h
	tls1.3	0304h
]

do [

;debug: :print
debug: :comment

max-count: 300000
count: 0
total: 0.0

print "Secure TCP client"

client: open tls://127.0.0.1:8123
;client: open tls://192.168.1.15:8123

client/extra: compose/deep [
    ;domain: "bitbegin.com"
    accept-invalid-cert: (false)
    disable-builtin-roots: (false)
    min-protocol: (protos/tls1.2)
    max-protocol: (protos/tls1.2)
]

start: now/precise
mbps: "?"

b: to-binary "Hello Red"

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port b]
        read [
	        probe length? port/data
	        probe to-string port/data
	        insert port b
        ]
        wrote [copy port]
    ]
    false
]
if unset? :gui-console-ctx [
	wait client
	close client
	print "Done"
]
]
