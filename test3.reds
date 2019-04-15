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
        dump-hex pHost/usb-dev-properties/device-id
        print-line pHost/usb-dev-properties/device-id-len
        dump-hex pHost/usb-dev-properties/device-desc
        print-line pHost/usb-dev-properties/device-desc-len
        print-line "host id:"
        print-line pHost/vendor-id
        print-line pHost/device-id
        print-line pHost/subsys-id
        print-line pHost/revision
        print-line "bus function:"
        print-line pHost/bus-dev-func-valid
        print-line pHost/bus-number
        print-line pHost/bus-device
        print-line pHost/bus-function
        print-line "controller info:"
        print-line pHost/controller-info/pci-vendor-id
        print-line pHost/controller-info/pci-device-id
        print-line pHost/controller-info/pci-revision
        print-line pHost/controller-info/num-root-ports
        print-line pHost/controller-info/controller-flavor
        print-line pHost/controller-info/hc-feature-flags
    ]
    entry: entry/next
]
