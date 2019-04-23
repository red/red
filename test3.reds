Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-win32.reds

usb-device/init
usb-device/enum-all-devices

print-line "devices:"
pNode: as usb-device/DEVICE-INFO-NODE! 0
list: usb-device/device-list
entry: list/next
strings: as usb-device/STRING-DESC-NODE! 0
next: as usb-device/STRING-DESC-NODE! 0
child-list: as list-entry! 0
child-entry: as list-entry! 0
child: as usb-device/INTERFACE-INFO-NODE! 0
while [entry <> list][
    pNode: as usb-device/DEVICE-INFO-NODE! entry
    print "dev-path: "
    print-line pNode/path
    ;print-line "port:"
    ;print-line pNode/port
    ;print-line pNode/vid
    ;print-line pNode/pid
    if pNode/serial-num <> null [
        print "serial num: "
        print-line pNode/serial-num
    ]
    ;print-line pNode/hub-path
    ;dump-hex pNode/device-desc
    ;dump-hex pNode/config-desc
    ;print-line "string id:"
    ;strings: pNode/strings
    ;while [strings <> null][
    ;    next: strings/next
    ;    dump-hex as byte-ptr! strings/string-desc
    ;    strings: next
    ;]
    ;print-line "string end"
    print "service: "
    print-line pNode/properties/service
    child-list: pNode/interface-entry
    print-line "child:"
    child-entry: child-list/next
    while [child-entry <> child-list][
        child: as usb-device/INTERFACE-INFO-NODE! child-entry
        if child/properties/service <> null [
            print "service: "
            print-line child/properties/service
        ]
        print "path: "
        print-line child/path
        if child/interface-num <> 255 [
            print "interface num: "
            print-line child/interface-num
        ]
        if child/collection-num <> 255 [
            print "collection num: "
            print-line child/collection-num
        ]
        if all [
            pNode/vid = 1209h
            pNode/pid = 53C1h
        ][
            if 0 = compare-memory as byte-ptr! child/properties/device-id as byte-ptr! "USB\" 4 [
                usb-device/open-inteface child
                print-line child/bulk-in
                print-line child/bulk-out
                print-line child/interrupt-in
                print-line child/interrupt-out
                usb-device/close-interface child
            ]
        ]
        child-entry: child-entry/next
    ]
    print-line "child end"
    print-line ""
    entry: entry/next
]

#if debug? = yes [
    print-line "asdfsad"
]