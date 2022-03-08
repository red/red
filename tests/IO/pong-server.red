Red []

print "Ping pong server"

server: open tcp://:8083

server/awake: func [event /local client] [
    if event/type = 'accept [
        client: event/port
        client/awake: func [event] [
            switch event/type [
                read [
                    print ["Client said:" to-string event/port/data]
                    insert event/port "pong!"
                ]
                wrote [
                    print "Server sent pong to client"
                    copy event/port
                ]
            ]
        ]
        copy client
    ]
]

wait 2