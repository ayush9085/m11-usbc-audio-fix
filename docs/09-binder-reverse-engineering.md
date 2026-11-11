# 09 - Binder Reverse Engineering

To confirm the hypothesis and bypass the `UsbAlsaManager` race condition without needing to recompile the Android framework, the Binder IPC interface of `IAudioService` was reverse engineered.

## Method Identification in AOSP Framework
In Android 12 (`android-12.1.0_r1`), the method responsible for notifying wired headset state is defined in `android.media.IAudioService`:
```java
void setWiredDeviceConnectionState(int type, int state, String address, String name, String caller);
```

## Extracting Transaction Code via DEX Disassembly
Using Python `androguard` to analyze `services.jar` and `framework.jar` directly from the ROM build:
- Target Interface Descriptor: `android.media.IAudioService`
- Target Method: `setWiredDeviceConnectionState`
- **Assigned Transaction Code**: `71`

## Device Type Bitmasks (AudioSystem.java)
The audio device bitmasks for USB audio in Android 12 are defined as:
- **`AUDIO_DEVICE_OUT_USB_HEADSET`**:
  - Hex: `0x04000000`
  - Signed 32-bit Integer: `67108864`
- **`AUDIO_DEVICE_IN_USB_HEADSET`**:
  - Hex: `0x82000000`
  - Signed 32-bit Integer: `-2113929216`

## Parameter Structure
1. `type` (`i32`): Device mask (`67108864` for output, `-2113929216` for input mic).
2. `state` (`i32`): `1` for connected, `0` for disconnected.
3. `address` (`s16`): String specifying ALSA card and device, formatted as `"card=0;device=0"`.
4. `name` (`s16`): Descriptive device name, e.g., `"JBL TUNE 310C USB-C"`.
5. `caller` (`s16`): Calling component identifier, e.g., `"UsbAlsaDevice"`.

## Proof-of-Concept Binder Injection
Executing the transaction directly from an elevated shell:
```bash
adb shell service call audio 71 i32 67108864 i32 1 s16 "card=0;device=0" s16 "JBL TUNE 310C USB-C" s16 "UsbAlsaDevice"
```
**Result:**
```text
Result: Parcel(00000000   '....')
```
- Exit code 0 (success).
- Within 50 milliseconds, `AudioFlinger` opened output handle 13 (`AudioOut_D`).
- Sample rate locked to 96,000 Hz, 24-bit PCM.
- Audio in active media apps immediately routed to the JBL USB-C headset.
- When injecting state `0`, audio routed back to the loudspeaker smoothly without crashing.
