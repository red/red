Red [
    title: "Basic Secure TCP test server"
]

do [

debug: :print
;debug: :comment

total: 0.0
count: 0

process-data: func [port /local len] [
	;debug ["port data:" port/data]
	debug "process-data enter"
    unless empty? port/data [
        len: length? port/data
        debug ["--- packet:" length? port/data "of" len]
        probe to-string port/data
        insert port to-binary "hello Red from server"
    ]
	debug "process-data exit"
]

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [process-data event/port]
        wrote [copy event/port]
        close [close event/port return true]
    ]
    false
]

new-client: func [port /local data] [
	debug ["=== New client ==="]
    port/awake: :new-event
    copy port
]

server: open tls://:8123

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
    false
]

print "Secure TCP server: waiting for client to connect"
if none? system/view [
	wait server
	print "done"
	close server
]

]

