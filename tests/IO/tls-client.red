Red [
    title: "Basic Secure TCP test client"
]

do [

;debug: :print
debug: :comment

max-count: 300000
count: 0
total: 0.0

print "Secure TCP client"

client: open tls://127.0.0.1:49503

start: now/precise
mbps: "?"

b: to-binary "Hello Red"

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port b]
        read [
        ]
        wrote []
    ]
    false
]
if none? system/view [
	wait client
	close client
	print "Done"
]
]
