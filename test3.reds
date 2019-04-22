Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-windows.reds

usb-windows/init
usb-windows/enum-all-devices

print-line "devices:"
pNode: as usb-windows/DEVICE-INFO-NODE! 0
list: usb-windows/device-list
entry: list/next
strings: as usb-windows/STRING-DESC-NODE! 0
next: as usb-windows/STRING-DESC-NODE! 0
child-list: as list-entry! 0
child-entry: as list-entry! 0
child: as usb-windows/INTERFACE-INFO-NODE! 0
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    print-line "dev-path:"
    print-line pNode/path
    ;print-line "port:"
    ;print-line pNode/port
    ;print-line pNode/vid
    ;print-line pNode/pid
    print-line "serial num:"
    print-line pNode/serial-num
    ;print-line pNode/hub-path
    dump-hex pNode/device-desc
    dump-hex pNode/config-desc
    print-line "string id:"
    strings: pNode/strings
    while [strings <> null][
        next: strings/next
        dump-hex as byte-ptr! strings/string-desc
        strings: next
    ]
    print-line "string end"
    child-list: pNode/interface-entry
    print-line "child:"
    child-entry: child-list/next
    while [child-entry <> child-list][
        child: as usb-windows/INTERFACE-INFO-NODE! child-entry
        print-line child/path
        child-entry: child-entry/next
    ]
    print-line "child end"
    print-line ""
    entry: entry/next
]
