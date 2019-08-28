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

udp-port: open udp://127.0.0.1:8180

b: make binary! size: 80000
loop size [append b random 255]
insert b skip (to binary! length? b) 4

start: now/precise
mbps: "?"

udp-port/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        read [
	        ;probe "client read done"
            either port/data/1 = 15 [
                count: count + 1
                total: total + size + 4
                if count // 1000 = 0 [
                    t: to float! difference now/precise start
                    mbps: round (total / t * 8 / 1024 / 1024)
                ]
                debug [count round (total / 1024 / 1024) "MB" mbps "Mbps"]
                either count < max-count [
                    insert port b
                ][
                    close port
                    return true
                ]
            ][
                copy port
            ]
        ]
        wrote [copy port]
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
