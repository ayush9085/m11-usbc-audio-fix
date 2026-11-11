# 10 - Root Cause Analysis

## Synthesis of Findings
The failure of USB-C audio peripherals to operate on the Samsung Galaxy M11 (`m11q`) under LineageOS 19.1 was caused by three cumulative defects across separate layers of the device stack:

```text
+-------------------------------------------------------------------+
| Layer 3: Framework Synchronization Race                           |
| UsbAlsaManager reads /proc/asound/ before snd-usb-audio finishes  |
+-------------------------------------------------------------------+
                                  ^
                                  |
+-------------------------------------------------------------------+
| Layer 2: Vendor Audio HAL Declarative Configuration               |
| Missing usb_audio_policy_configuration.xml in audio_policy.xml    |
+-------------------------------------------------------------------+
                                  ^
                                  |
+-------------------------------------------------------------------+
| Layer 1: Kernel DWC3 USB Host PHY Controller                      |
| Stock kernel 4.9.305 had broken OTG VBUS / Host Mode negotiation  |
+-------------------------------------------------------------------+
```

### 1. Kernel Layer (Qualcomm SDM450 DWC3 OTG)
The stock `4.9.305` kernel failed to negotiate USB host mode when an audio accessory was inserted, keeping the controller in a suspended state. This was fixed by adopting the community `4.9.319-ifoodplayer+` kernel which incorporated the corrected OTG PHY transceiver sequence.

### 2. Vendor Layer (Audio Policy XML)
Stock Samsung Galaxy M11 firmware relied exclusively on an analog 3.5mm headset jack and Qualcomm audio codec. The vendor configuration `/vendor/etc/audio_policy_configuration.xml` omitted the standard USB HAL declaration (`usb_audio_policy_configuration.xml`), causing `AudioPolicyManager` to reject any USB routing requests.

### 3. Framework Layer (Asynchronous Timing Race)
When a USB audio peripheral was plugged in, `UsbHostManager` in `system_server` caught the initial USB device attachment uevent and synchronously invoked `AlsaCardsParser.scan()`. Because the kernel's `snd-usb-audio` driver populates `/proc/asound/cardX/usbbus` asynchronously after USB enumeration, the procfs entry was not yet present when `scan()` ran. Finding no cards, `UsbAlsaManager` aborted without retrying, leaving the framework oblivious to the newly attached audio device.
