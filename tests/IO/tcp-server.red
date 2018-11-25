Red [
    title: "Basic TCP test server"
]

debug: :print
;debug: :comment

total: 0
count: 0

process-data: func [port /local len] [
    if parse port/data [copy len 4 skip any skip] [
        len: to integer! len
        debug ["--- packet:" length? port/data "of" len]
        either len <= length? port/data [
            clear port/data
            write port #{0f}
            count: count + 1
            total: total + len + 4
            print [count round (total / 1024 / 1024) "MB"]
        ][
            read port
        ]
    ]
]

new-event: func [event] [
    debug ["=== Subport event:" event/type]
    switch event/type [
        read  [process-data event/port]
        wrote [read event/port]
        close [close event/port return true]
    ]
    false
]

new-client: func [port /local data] [
    port/awake: :new-event
    read port
]

server: open tcp://:8000

server/awake: func [event] [
    if event/type = 'accept [new-client event/port]
    false
]

print "TCP server: waiting for client to connect"
wait server
print "done"
close server


