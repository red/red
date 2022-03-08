Red []

protos: [
    sslv3   0300h
    tls1.0  0301h
    tls1.1  0302h
    tls1.2  0303h
    tls1.3  0304h
]

print "Ping pong client"

ping-count: 0

client: open tls://127.0.0.1:8085

client/extra: compose/deep [
    accept-invalid-cert: (true)
    disable-builtin-roots: (false)
    min-protocol: (protos/tls1.2)
    max-protocol: (protos/tls1.2)
]

client/awake: func [event /local port] [
    port: event/port
    switch event/type [
        connect [insert port "ping!"]
        wrote [
            print "Client sent ping to server"
            copy port
        ]
        read [
            print ["Server said:" to-string port/data]
            ping-count: ping-count + 1
            either ping-count > 50 [
                close port  ;-- close itself
            ][
                insert port "ping!"
            ]
        ]
    ]
]

wait 3