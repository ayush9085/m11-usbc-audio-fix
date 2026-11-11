# Failure Path Analysis

This diagram visualizes the dual-layer failure mode observed prior to the fix: first at the Linux kernel OTG level, and second at the Android framework synchronization level.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant HW as USB-C Port
    participant Kernel as Linux Kernel (4.9.305)
    participant Hal as Audio HAL (Vendor)
    participant FW as UsbAlsaManager (system_server)
    participant AF as AudioFlinger

    Note over User,AF: Layer 1 Failure: Stock Kernel (4.9.305)
    User->>HW: Connects USB-C Headset (JBL TUNE 310C)
    HW->>Kernel: DWC3 PHY interrupt / VBUS detection
    Kernel-->>Kernel: OTG state machine fails; enters immediate suspend
    Note over Kernel: /dev/bus/usb is empty<br/>snd-usb-audio does NOT load<br/>No ALSA card created
    User->>AF: Plays media
    AF->>User: Audio routes only through internal speaker

    Note over User,AF: Layer 2 Failure: Framework Timing Race (Kernel 4.9.319)
    User->>HW: Connects USB-C Headset
    HW->>Kernel: Hardware enumeration succeeds (4.9.319-ifoodplayer+)
    Kernel->>Kernel: snd-usb-audio loads, creates /dev/snd/pcmC0D0p
    Kernel->>FW: Broadcasts USB attach uevent
    FW->>FW: UsbHostManager triggers UsbAlsaManager.usbDeviceAdded()
    FW->>Kernel: AlsaCardsParser reads /proc/asound/cards & usbbus
    Note over FW,Kernel: RACE: Kernel driver has not yet populated usbbus!<br/>Parser finds 0 matching cards and aborts.
    Note over FW: UsbAlsaManager never calls<br/>AudioService.setWiredDeviceConnectionState()
    User->>AF: Plays media
    AF->>User: Media continues playing through phone speaker
```

## Root Cause Summary
- **Kernel Failure**: Downstream Qualcomm USB PHY driver regression caused host-mode negotiation failure.
- **Framework Race**: `AlsaCardsParser.scan()` executed synchronously upon the initial USB device attachment event, prior to the asynchronous creation of ALSA card metadata files in `/proc/asound/`. Because the scan was not repeated upon card creation, the framework permanently ignored the attached USB audio peripheral.
