Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-windows.reds

usb-windows/init
usb-windows/enum-devices-with-guid usb-windows/device-list usb-windows/GUID_DEVINTERFACE_USB_DEVICE

list: usb-windows/device-list/list-head
entry: list/next
pNode: as usb-windows/DEVICE-INFO-NODE! 0
while [entry <> list][
    print-line "X"
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    print-line pNode/desc-name
    print-line pNode/driver-name
    entry: entry/next
]
