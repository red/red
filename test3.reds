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
strings: as usb-windows/STRING-DESC-NODE! 0
next: as usb-windows/STRING-DESC-NODE! 0
child-list: as list-entry! 0
child-entry: as list-entry! 0
child: as usb-windows/INTERFACE-INFO-NODE! 0
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    print-line "desc-name:"
    dump-hex pNode/desc-name
    print-line pNode/desc-name-len
    print-line "dev-path:"
    print-line as c-string! :pNode/detail-data/DevicePath
    ;print-line "driver-name:"
    ;dump-hex pNode/driver-name
    ;print-line pNode/driver-name-len
    print-line "port:"
    print-line pNode/port
    print-line pNode/vid
    print-line pNode/pid
    print-line pNode/serial-num
    print-line pNode/hub-path
    dump-hex pNode/device-desc
    dump-hex pNode/config-desc
    print-line "string id:"
    strings: pNode/strings
    while [strings <> null][
        next: strings/next
        dump-hex as byte-ptr! strings/string-desc
        strings: next
    ]
    print-line "end"
    child-list: pNode/interface-entry
    print-line "child:"
    child-entry: child-list/next
    while [child-entry <> child-list][
        child: as usb-windows/INTERFACE-INFO-NODE! child-entry
        print-line as c-string! child/device-id
        if child/path <> null [
            print-line as c-string! child/path
        ]
        child-entry: child-entry/next
    ]
    entry: entry/next
]
