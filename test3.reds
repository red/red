Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-windows.reds

usb-windows/init
usb-windows/enum-host-controllers usb-windows/tree-list

print-line "devices:"
pNode: as usb-windows/DEVICE-INFO-NODE! 0
list: usb-windows/device-list/list-head
entry: list/next
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    ;dump-hex pNode/desc-name
    print-line pNode/desc-name-len
    ;dump-hex pNode/driver-name
    print-line pNode/driver-name-len
    entry: entry/next
]

print-line "hubs:"
list: usb-windows/hub-list/list-head
entry: list/next
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    ;dump-hex pNode/desc-name
    print-line pNode/desc-name-len
    ;dump-hex pNode/driver-name
    print-line pNode/driver-name-len
    entry: entry/next
]

print-line "hosts:"
pHost: as usb-windows/USB-HOST-CONTROLLER-INFO! 0
list: usb-windows/tree-list
entry: list/next
while [entry <> list][
    pHost: as usb-windows/USB-HOST-CONTROLLER-INFO! entry
    ;dump-hex pHost/driver-key-name
    print-line pHost/driver-key-len
    if pHost/usb-dev-properties <> null [
        print pHost/usb-dev-properties/device-id-len
        print pHost/usb-dev-properties/device-desc-len
    ]
    entry: entry/next
]
