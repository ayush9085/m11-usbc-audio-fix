# 14 - Rollback & Restoration Procedure

If you need to return the device to its pre-fix state without wiping user data:

## Automated Rollback
Run the included uninstaller script from your host machine:
```bash
./scripts/uninstall.sh
```

## Manual Step-by-Step Rollback

### 1. Remount Partitions Read-Write
```bash
adb root
adb remount
# If adb remount fails:
adb shell "mount -o remount,rw /system && mount -o remount,rw /vendor"
```

### 2. Terminate Running Daemons
```bash
adb shell killall -q usb_audio_daemon.sh inotifyd || true
```

### 3. Remove System Binaries and Init Scripts
```bash
adb shell rm -f /system/bin/usb_audio_event.sh
adb shell rm -f /system/bin/usb_audio_daemon.sh
adb shell rm -f /system/etc/init/usb_audio.rc
adb shell rm -f /dev/.usb_audio_state
adb shell rm -f /dev/.usb_audio_lock
```

### 4. Restore Vendor Audio Policy
```bash
adb shell "if [ -f /vendor/etc/audio_policy_configuration.xml.bak ]; then
    mv /vendor/etc/audio_policy_configuration.xml.bak /vendor/etc/audio_policy_configuration.xml
else
    sed -i '/usb_audio_policy_configuration.xml/d' /vendor/etc/audio_policy_configuration.xml
fi"
```

### 5. Reboot Audioserver or Device
```bash
adb shell killall audioserver
# Or perform a complete system reboot:
adb reboot
```
The device will now function in its default stock state.

