# 13 - Troubleshooting Guide

## Diagnostic Matrix

| Symptom | Probable Cause | Verification & Remediation |
| :--- | :--- | :--- |
| **No USB card in `/proc/asound/cards`** | Kernel OTG issue or faulty cable/adapter | Verify kernel with `uname -r`. Must be `4.9.319-ifoodplayer+` or equivalent with OTG fix. Check `/dev/bus/usb/`. |
| **Audio continues through speaker despite ALSA card 0 present** | Vendor audio policy missing USB module or daemon inactive | Run `scripts/health_check.sh`. Verify `<xi:include href="usb_audio_policy_configuration.xml"/>` exists in `/vendor/etc/audio_policy_configuration.xml`. |
| **Daemon not running after boot** | SELinux denial or init script permissions | Run `adb shell ps -ef \| grep inotifyd`. Check logcat: `adb logcat -s init \| grep usb_audio`. Ensure `seclabel u:r:su:s0` is present in `/system/etc/init/usb_audio.rc`. |
| **Audio plays but crackles or stutters** | Clock synchronization or buffer underrun | Inspect `dumpsys media.audio_flinger`. Ensure output thread sample rate matches peripheral supported rates (48000 or 96000 Hz). |
| **Microphone not recording in voice apps** | Input device mask omitted | Ensure Binder transaction 71 with mask `-2113929216` (`AUDIO_DEVICE_IN_USB_HEADSET`) was dispatched. |

## Quick Diagnostic Commands
```bash
# 1. Check live daemon state
adb shell cat /dev/.usb_audio_state

# 2. Check running daemon processes
adb shell "ps -ef | grep -E 'usb_audio|inotifyd' | grep -v grep"

# 3. View daemon logcat output
adb logcat -s UsbAudioDaemon:I

# 4. Force manual registration override
adb shell /system/bin/usb_audio_event.sh force
```

