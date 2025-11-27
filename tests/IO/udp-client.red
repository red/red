Red [
    title: "Basic UDP test client"
]

do [

debug: :print
;debug: :comment

max-count: 300000
count: 49
total: 0.0
msg: to-binary "Hello from Client "

print "UDP client"

udp-port: open udp://127.0.0.1:58180

udp-port/awake: func [event /local port] [
    ;debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        read [
	        probe "client read done"
	        probe to-string port/data
	        insert port rejoin [msg count]
	        count: count + 1
        ]
        wrote [
	        probe "client write done"
	        copy port
		]
    ]
    false
]

insert udp-port msg		;-- perform a send action

if none? system/view [
	wait udp-port
	close udp-port
	print "Done"
]
]
