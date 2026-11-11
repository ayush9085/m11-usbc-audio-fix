# 08 - System Server Investigation

## USB Audio Detection Architecture in Android 12
Within `system_server`, USB audio devices are handled through a coordinated pipeline:
1. **`UsbHostManager`**: Listens for kernel netlink uevents on USB device attachment (`/dev/bus/usb/xxx/xxx`).
2. **`UsbAlsaManager`**: Triggered by `UsbHostManager.usbDeviceAdded(UsbDevice)`.
3. **`AlsaCardsParser`**: Parses `/proc/asound/cards` and correlates the Linux USB bus/device path with ALSA sound cards via `/proc/asound/cardX/usbbus`.
4. **`AudioService`**: Called by `UsbAlsaManager.selectDevice()` to notify native audio policy of the new wired peripheral.

## Live Logcat Tracing
Tracing system logcat while inserting the JBL headset revealed the exact break in the pipeline:
```text
I UsbHostManager: Added device UsbDevice[mName=/dev/bus/usb/001/002,mVendorId=3787,mProductId=8438,mManufacturerName=KTMICRO,mProductName=JBL TUNE 310C USB-C...]
D UsbAlsaManager: usbDeviceAdded(): UsbDevice[mName=/dev/bus/usb/001/002...]
D AlsaCardsParser: scan(): Scanning ALSA cards...
D AlsaCardsParser: scan(): Reading /proc/asound/cards
W AlsaCardsParser: scan(): Card 0 /proc/asound/card0/usbbus not found or empty!
D AlsaCardsParser: scan(): Found 0 ALSA devices matching USB address 001/002
W UsbAlsaManager: No ALSA device found for UsbDevice /dev/bus/usb/001/002
D UsbAlsaManager: UsbDevice /dev/bus/usb/001/002 not handled. Aborting audio route update.
```

## Anatomy of the Race Condition
- `UsbHostManager` received the USB enumeration uevent immediately when the USB PHY reported configuration.
- It immediately invoked `AlsaCardsParser.scan()`.
- However, the Linux kernel's `snd-usb-audio` driver populates `/proc/asound/card0/usbbus` asynchronously, roughly 250–350 milliseconds after the USB device node is created.
- At the millisecond `AlsaCardsParser` executed, `usbbus` was not yet populated on disk.
- Finding 0 matching cards, `AlsaCardsParser` returned an empty list.
- Because `UsbAlsaManager` only reacts to uevents and does not schedule retries or monitor `/proc/asound/` for changes, the framework permanently abandoned the device.

