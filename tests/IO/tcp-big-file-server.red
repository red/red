Red [
    title: "Basic Secure TCP test server"
]

debug: :print
;debug: :comment

data: make binary! 1000
ending: to-binary "61842c0e-5631-46cb-9748-b390a5da5256"

process-data: func [port] [
	;debug ["port data:" port/data]
	debug "process-data enter"
    append data port/data
	debug length? data
	either ending = skip tail data 0 - length? ending [
		write/part/binary %tcp-big-file-server-received.data data (length? data) - length? ending
		insert port "Good!"
	][
    	copy port
	]
	debug "process-data exit"
]

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [process-data event/port]
        wrote [close event/port]
    ]
]

n: 0
new-client: func [port] [
	debug ["=== New client ===" n]
    n: n + 1
    clear data
    port/awake: :new-event
    copy port
]

server: open tcp://:8223

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
]

print "Secure TCP server: waiting for client to connect"
if unset? :gui-console-ctx [
	wait server
	print "done"
]
