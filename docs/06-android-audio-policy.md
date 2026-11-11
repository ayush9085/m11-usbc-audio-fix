# 06 - Android Audio Policy Configuration

## Vendor Audio Policy Inspection
Android's `AudioPolicyManager` relies on declarative XML configuration files to discover which hardware modules (HALs) to load and which audio devices they support.

Inspecting `/vendor/etc/audio_policy_configuration.xml`:
```bash
adb shell cat /vendor/etc/audio_policy_configuration.xml
```
Analysis of the `<modules>` block revealed:
- `primary`: Included (`primary_audio_policy_configuration.xml`) for internal speakers, mics, and 3.5mm jack.
- `a2dp`: Included (`a2dp_audio_policy_configuration.xml`) for Bluetooth audio.
- `r_submix`: Included (`r_submix_audio_policy_configuration.xml`) for audio screen casting and virtualization.
- **`usb`**: MISSING.

Because Samsung Galaxy M11 stock firmware historically targeted an analog 3.5mm headphone jack, the stock vendor image omitted `<xi:include href="usb_audio_policy_configuration.xml"/>`.

## Patching Vendor Policy
To allow `AudioPolicyManager` to bind to the standard AOSP USB Audio HAL (`android.hardware.audio@7.0-impl` or `audio.usb.default.so`), the XML file was patched:

```bash
adb root
adb remount
# Backup original vendor configuration
adb shell cp /vendor/etc/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml.bak

# Append the USB audio policy include
adb shell "sed -i '/<xi:include href=\"r_submix_audio_policy_configuration.xml\"\/>/a \    <xi:include href=\"usb_audio_policy_configuration.xml\"\/>' /vendor/etc/audio_policy_configuration.xml"
```

## Policy Verification
Restarting `audioserver` triggered XML re-parsing:
```bash
adb shell killall audioserver
adb shell dumpsys media.audio_policy | grep "HW Module"
```
**Output:**
```text
  - HW Module 1: "primary"
  - HW Module 2: "a2dp"
  - HW Module 3: "usb"
```
`AudioPolicyManager` now successfully registered the USB HAL module and declared support for `AUDIO_DEVICE_OUT_USB_HEADSET` and `AUDIO_DEVICE_IN_USB_HEADSET`.

However, plugging in the headset still resulted in no audio output through USB.
