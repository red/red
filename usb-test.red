usb: open usb://VID=1209&PID=53C1&MI=00&COL=00&SN=EF3ADD96F01D8B1975B6FE11
probe usb
buffer: make binary! 64
append buffer #{3F}
append/dup buffer #{FF} 63

first?: true

usb/awake: func [event /local port] [
    print ["=== usb event:" event/type]
    port: event/port
    switch event/type [
        lookup [open port]
        connect [print "connect" copy port insert port buffer]
        accept [print "accept" insert port buffer]
        read [
            probe "usb read done"
            probe port/data
            copy port
        ]
        wrote [
            probe "usb write done"
            if first? [
                first?: false
                clear buffer
                append buffer #{3F2323}
                append/dup buffer #{00} 61
                insert port buffer
                copy port
            ]
        ]
    ]
    false
]
wait usb
close usb