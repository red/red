Red [
    title: "Basic TCP test client"
]

do [

recycle/off

;debug: :print
debug: :comment

max-count: 300000
count: 0
total: 0.0

print "TCP client"

client: open tcp://127.0.0.1:8123

;b: make binary! size: 80000
;loop size [append b random 255]
;insert b skip (to binary! length? b) 4

b: #{61626364}

start: now/precise
mbps: "?"

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

	
	repeat n 120 [
		?? n
		open client
		wait client
	]
]

]
