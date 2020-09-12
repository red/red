Red []

recycle/off

debug: :print
;debug: :comment

data: to-binary mold system/words
print length? data
print "TLS client"

client: open tls://127.0.0.1:8123

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port data]
        read [probe length? port/data close port]
        wrote [copy port]
    ]
]

if none? system/view [
	wait client
]
