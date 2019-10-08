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

client: open tls://192.168.87.128:8123

start: now/precise
mbps: "?"

b: to-binary "Hello Red"

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port b]
        read [
	        probe length? port/data
	        probe to-string port/data
        ]
        wrote [copy port]
    ]
    false
]
if none? system/view [
	wait client
	close client
	print "Done"
]
]
