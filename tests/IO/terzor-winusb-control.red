usb: open usb://VID=1209&PID=53C1&MI=00&COL=00&SN=EF3ADD96F01D8B1975B6FE11
probe usb
buffer: make binary! 64
append buffer #{8006000100004000}

usb/state/pipe: 0
usb/state/read-size: 64
usb/awake: func [event /local port] [
    print ["=== usb event:" event/type]
    port: event/port
    switch event/type [
        lookup [open port]
        connect [
            print "connect"
            insert port buffer
        ]
        wrote [
            probe "usb write done"
            probe port/data
        ]
    ]
    false
]
wait usb
close usb