Red [
    title: "Basic TCP echo server"
]

debug: :print
;debug: :comment

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [
	        probe to-string event/port/data
	        close event/port
	    ]
    ]
]

new-client: func [port /local data] [
	debug ["=== New client ==="]
    port/awake: :new-event
    copy port
]

server1: open tcp://:8123
server2: open tcp://:8124

server1/awake: func [event] [
	debug "server 1"
    if event/type = 'accept [new-client event/port]
    false
]

server2/awake: func [event] [
	debug "server 2"
    if event/type = 'accept [new-client event/port]
    false
]

print "TCP server: waiting for client to connect"
if none? system/view [
	wait -1
]