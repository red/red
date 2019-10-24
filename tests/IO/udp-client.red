Red [
    title: "Basic UDP test client"
]

do [

debug: :print
;debug: :comment

max-count: 300000
count: 0
total: 0.0

print "UDP client"

udp-port: open udp://127.0.0.1:58180
;b: make binary! size: 80000
;loop size [append b random 255]
;insert b skip (to binary! length? b) 4

start: now/precise
mbps: "?"

b: to-binary "hello udp 123 client"
udp-port/awake: func [event /local port] [
    ;debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        read [
	        probe "client read done"
	        probe to-string port/data
        ]
        wrote [
	        probe "client write done"
	        copy port
		]
    ]
    false
]

insert udp-port b		;-- perform a send action

if none? system/view [
	wait udp-port
	close udp-port
	print "Done"
]
]
