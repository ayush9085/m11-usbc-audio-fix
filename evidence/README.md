# Diagnostic Evidence & Verification Logs

This directory contains raw, sanitized terminal logs and dumpsys captures gathered directly from the target Samsung Galaxy M11 (`m11q`) during the debugging and verification phases.

All identifiers have been sanitized:
- Local host usernames and absolute workstation paths are generalized.
- Wireless network IP addresses and ADB communication ports are obfuscated.
- Device hardware serial numbers are replaced with standard placeholders.

## Evidence File Index
1. `usb-detection.txt`: Sysfs and kernel dmesg traces showing USB enumeration of the JBL TUNE 310C (`0ecb:20f6`) peripheral under the 4.9.319-ifoodplayer+ kernel.
2. `alsa.txt`: ALSA procfs tree, sound cards list, PCM stream capabilities, and mixer controls.
3. `audio-policy.txt`: `dumpsys media.audio_policy` extracts demonstrating HW Module 5 (USB Audio HAL) loading and device registration.
4. `audio-flinger.txt`: `dumpsys media.audio_flinger` extracts demonstrating the active output proxy stream at 96 kHz, 24-bit PCM.
5. `usb-framework.txt`: Logcat traces of `UsbHostManager` and `UsbAlsaManager` capturing the initial race condition.
6. `hotplug.txt`: Live execution log of `usb_audio_daemon.sh` and `usb_audio_event.sh` across plug, playback, and unplug cycles.

