Red [
    title: "Basic TCP test server"
]

do [

debug: :print
;debug: :comment

total: 0.0
count: 0

process-data: func [port /local len] [
	;debug ["port data:" port/data]
	probe "process-data enter"
    unless empty? port/data [
        len: length? port/data
        debug ["--- packet:" length? port/data "of" len]
        clear port/data
        insert port #{0f}
        count: count + 1
        total: total + len + 4
        print [count round (total / 1024 / 1024) "MB"]
    ]
	probe "process-data exit"
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

server: open tcp://:8123

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
    false
]

print "TCP server: waiting for client to connect"
wait server
print "done"
close server

]

