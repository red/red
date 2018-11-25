Red [
    title: "Basic TCP test client"
]

debug: :print
;debug: :comment

max-count: 100000
count: 0
total: 0

print "TCP client"

client: open tcp://127.0.0.1:8000

b: make binary! size: 10000
loop size [append b random 255]
insert b skip (to binary! length? b) 4

start: now/precise
mbps: "?"

client/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        lookup [open port]
        connect [write port b]
        read [
            if port/data/2 [
                print ["ERROR in response" total]
                close port
                return true
            ]
            either port/data = #{0f} [
                ++ count
                total: total + size + 4
                if count // 1000 = 0 [
                    t: to decimal! difference now/precise start
                    mbps: round (total / t * 10 / 1024 / 1024)
                ]
                print [count round (total / 1024 / 1024) "MB" mbps "Mbps"]
                either count < max-count [
                    write port b
                ][
                    close port
                    return true
                ]
            ][
                read port
            ]
        ]
        wrote [read port]
    ]
    false
]

wait client
close client
print "Done"

