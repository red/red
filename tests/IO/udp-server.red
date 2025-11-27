Red [
    title: "Basic UDP test server"
]

do [

debug: :print
;debug: :comment

total: 0.0
count: 49
msg: to-binary "Hello from Server "

server: open udp://:58180

server/awake: func [event /local port] [
    debug ["=== Event:" event/type]
    port: event/port
    switch event/type [
        read  [
	        probe "read done"
	        probe to-string port/data
	        insert port rejoin [msg count]
	        count: count + 1
        ]
        wrote [
	        if count < 58 [copy port]
	    ]
        close [close port return true]
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

