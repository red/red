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

client: open tls://127.0.0.1:8123
;client: open tls://192.168.1.15:8123

client/extra: [
    domain: "red-lang.org"
    ;-- temporary
    min-protocol: 0302h             ;-- min protocol sslv3,
    max-protocol: 0303h             ;-- max protocol tls1.2
]

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
	        insert port b
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
