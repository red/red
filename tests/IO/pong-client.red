Red []

print "Ping pong client"

ping-count: 0

client: open tcp://127.0.0.1:8083

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

if unset? :gui-console-ctx [
	wait client
]