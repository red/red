Red [
    title: "Basic UDP test server"
]

do [

debug: :print
;debug: :comment

total: 0.0
count: 0

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [
	        probe "read done"
	        probe to-string event/port/data
        ]
        wrote [copy event/port]
        close [close event/port return true]
    ]
    false
]

new-client: func [port /local data] [
	debug ["=== New client ==="]
    port/awake: :new-event
    insert port "Hello UDP from Red"
]

server: open udp://:58180

server/awake: func [event] [
    if event/type = 'accept [
	    probe to-string event/port/data
	    new-client event/port
	]
    false
]

print "UDP server: waiting for client"
if none? system/view [
	wait server
	print "done"
	close server
]

]

