# 07 - AudioFlinger Investigation

## Investigating Active Audio Tracks
With the USB audio module recognized by `AudioPolicyManager`, media was started in YouTube and other applications.

Inspecting `dumpsys media.audio_flinger`:
```bash
adb shell dumpsys media.audio_flinger
```
**Findings:**
1. **Active Playback Threads**: Only `AudioOut_0` (primary output thread) was open.
2. **Target Device**: `AUDIO_DEVICE_OUT_SPEAKER` (`0x2`).
3. **USB Audio Output**: Completely absent. No thread existed for `AUDIO_DEVICE_OUT_USB_HEADSET` (`0x04000000`).
4. **Stream State**: AudioFlinger was mixing application audio and dispatching it to Qualcomm MSM8953 primary codec pins, ignoring the attached USB card entirely.

## Diagnostic Hypothesis
Why would `AudioPolicyManager` know about USB audio capabilities, yet never instruct `AudioFlinger` to open a stream on the USB card?

In the Android audio architecture:
- `AudioFlinger` does not decide routing; it executes instructions received from `AudioPolicyManager`.
- `AudioPolicyManager` does not monitor USB ports directly; it waits for events from Java framework services inside `system_server`.
- Specifically, `AudioService.setWiredDeviceConnectionState()` must be called to inform the native policy manager that a physical peripheral has been attached to a specific card and device address.

This directed the investigation upward into `system_server`.
