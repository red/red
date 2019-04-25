usb: open usb://VID=1209&PID=53C1&SN=EF3ADD96F01D8B1975B6FE11&MI=00
probe usb
buffer: make binary! 64
append/dup buffer #{00} 64

usb/awake: func [event /local port] [
    debug ["=== usb event:" event/type]
    port: event/port
    switch event/type [
        lookup [open port]
        connect [insert port b]
        read [
	        probe "usb read done"
	        probe port/data
        ]
        wrote [probe "usb write done" copy port]
    ]
    false
]
insert usb buffer
wait usb
close usb