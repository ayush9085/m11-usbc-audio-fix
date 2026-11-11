#!/bin/bash
# uninstall.sh
# Rollback script to cleanly remove USB-C audio automation and restore stock vendor configurations.

set -euo pipefail

echo "=== M11 USB-C Audio Fix: Rollback & Uninstaller ==="

if [ -f "/system/bin/sh" ] && [ "$(id -u)" -eq 0 ]; then
    IS_DEVICE=1
else
    IS_DEVICE=0
fi

if [ "$IS_DEVICE" -eq 0 ]; then
    if ! command -v adb >/dev/null 2>&1; then
        echo "[-] Error: 'adb' not found in PATH."
        exit 1
    fi

    echo "[*] Requesting root ADB..."
    adb root || true
    sleep 1

    echo "[*] Remounting partitions..."
    adb remount || adb shell "mount -o remount,rw /system && mount -o remount,rw /vendor"

    echo "[*] Stopping and terminating daemon processes..."
    adb shell "killall -q usb_audio_daemon.sh inotifyd || true"

    echo "[*] Removing installed system binaries and init scripts..."
    adb shell "rm -f /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh /system/etc/init/usb_audio.rc /dev/.usb_audio_state /dev/.usb_audio_lock"

    echo "[*] Restoring vendor audio policy configuration from backup if present..."
    adb shell "if [ -f /vendor/etc/audio_policy_configuration.xml.bak ]; then
        mv /vendor/etc/audio_policy_configuration.xml.bak /vendor/etc/audio_policy_configuration.xml
        echo '[+] Restored audio_policy_configuration.xml from backup.'
    else
        echo '[!] No backup file found; manually removing include tag if present...'
        sed -i '/usb_audio_policy_configuration.xml/d' /vendor/etc/audio_policy_configuration.xml || true
    fi"

    echo "[+] Rollback complete. Rebooting audioserver or device is recommended."
    echo "[*] To reboot now: adb reboot"
else
    killall -q usb_audio_daemon.sh inotifyd || true
    rm -f /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh /system/etc/init/usb_audio.rc /dev/.usb_audio_state /dev/.usb_audio_lock
    if [ -f /vendor/etc/audio_policy_configuration.xml.bak ]; then
        mv /vendor/etc/audio_policy_configuration.xml.bak /vendor/etc/audio_policy_configuration.xml
        echo "[+] Restored audio_policy_configuration.xml from backup."
    fi
    echo "[+] Rollback complete on device."
fi
