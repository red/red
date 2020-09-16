Red [
    title: "Basic TCP test client"
]

debug: :print
;debug: :comment

max-count: 300000
count: 0
total: 0.0

print "TLS client"

client: open tls://127.0.0.1:58123

b: #{61626364}

start: now/precise
mbps: "?"

;-- send, read then close
client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [insert port b]
        read [probe port/data close port]
        wrote [copy port]
    ]
]

if none? system/view [
	wait client
	print "1st Done"
	repeat n 2 [
		?? n
        wait 0.1
		open client
		wait client
	]
]
