;usb: open usb://VID=1209&PID=53C1&MI=00&COL=00&SN=EF3ADD96F01D8B1975B6FE11
usb: open usb://VID=1209&PID=53C1&MI=01&COL=00&SN=EF3ADD96F01D8B1975B6FE11
probe usb
buffer: make binary! 65

first?: true

usb/awake: func [event /local port] [
    print ["=== usb event:" event/type]
    port: event/port
    switch event/type [
        lookup [open port]
        connect [
            print "connect"
            clear buffer
            append buffer #{00FFFFFF FF860008 A98250A6 71EDB3B2}
            append/dup buffer #{00} 65 - 16
            insert port buffer
        ]
        read [
            probe "usb read done"
            probe port/data
        ]
        wrote [
            probe "usb write done"
            copy port
        ]
    ]
    false
]
wait usb
close usb