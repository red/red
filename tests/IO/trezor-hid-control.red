usb: open usb://VID=1209&PID=53C1&MI=01&SN=EF3ADD96F01D8B1975B6FE11
probe usb
buffer: make binary! 65

first?: true

usb/state/pipe: 0
usb/state/read-size: 65
usb/state/feature: no
step: 0
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
            usb/state/feature: 'set-report
            insert port buffer
        ]
        read [
            probe "usb read done"
            probe port/data
        ]
        wrote [
            probe "usb write done"
            if step < 3 [
                usb/state/feature: 'get-report
                insert port #{00}
                probe port/data
            ]
            step: step + 1
        ]
    ]
    false
]
wait usb
close usb