Red [
    title: "Basic UDP test server"
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
        clear port/data
        insert port #{0f}
        count: count + 1
        total: total + len + 4
        debug [count round (total / 1024 / 1024) "MB"]
    ]
	debug "process-data exit"
]

server: open udp://:8180

server/awake: func [event] [
    switch event/type [
        read  [process-data event/port]
        wrote [copy event/port]
        close [close event/port return true]
    ]
    false
]

copy server		;-- perform a recv action

print "TCP server: waiting for client to connect"
if none? system/view [
	wait server
	print "done"
	close server
]

]

