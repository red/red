Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-windows.reds

usb-windows/init
usb-windows/enum-all-devices

print-line "devices:"
pNode: as usb-windows/DEVICE-INFO-NODE! 0
list: usb-windows/device-list/list-head
entry: list/next
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    print-line "desc-name:"
    dump-hex pNode/desc-name
    print-line pNode/desc-name-len
    ;print-line "driver-name:"
    ;dump-hex pNode/driver-name
    ;print-line pNode/driver-name-len
    ;print-line "port:"
    ;print-line pNode/port
    print-line pNode/vid
    print-line pNode/pid
    print-line pNode/serial-num
    print-line pNode/hub-path
    dump-hex pNode/device-desc
    dump-hex pNode/config-desc
    print-line "string id:"
    print-line as integer! pNode/device-desc/15
    print-line as integer! pNode/device-desc/16
    print-line as integer! pNode/device-desc/17
    if pNode/strings <> null [
        dump-hex as byte-ptr! pNode/strings
    ]
    entry: entry/next
]
