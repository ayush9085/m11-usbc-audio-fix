#!/bin/bash
# install.sh
# Deployment script for USB-C audio routing automation on Samsung Galaxy M11 (m11q).
# Can be executed from the host machine with ADB, or pushed directly to the device.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== M11 USB-C Audio Fix: Automated Installer ==="

# Detect execution environment (host vs device)
if [ -f "/system/bin/sh" ] && [ "$(id -u)" -eq 0 ]; then
    IS_DEVICE=1
    echo "[*] Running directly on target Android device (root shell)."
else
    IS_DEVICE=0
    echo "[*] Running from host workstation via ADB."
fi

if [ "$IS_DEVICE" -eq 0 ]; then
    # Verify adb availability
    if ! command -v adb >/dev/null 2>&1; then
        echo "[-] Error: 'adb' command not found in PATH."
        exit 1
    fi

    # Verify root access over adb
    echo "[*] Requesting root ADB access..."
    adb root || { echo "[-] Failed to restart adbd as root"; exit 1; }
    sleep 1

    echo "[*] Remounting system and vendor partitions read-write..."
    adb remount || {
        echo "[!] 'adb remount' failed, attempting manual partition remount..."
        adb shell "mount -o remount,rw /system && mount -o remount,rw /vendor"
    }

    echo "[*] Backing up vendor audio policy configuration..."
    adb shell "if [ ! -f /vendor/etc/audio_policy_configuration.xml.bak ]; then cp /vendor/etc/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml.bak; fi"

    echo "[*] Checking and updating vendor audio policy configuration..."
    adb shell "if ! grep -q 'usb_audio_policy_configuration.xml' /vendor/etc/audio_policy_configuration.xml; then
        sed -i '/<xi:include href=\"r_submix_audio_policy_configuration.xml\"\/>/a \    <xi:include href=\"usb_audio_policy_configuration.xml\"\/>' /vendor/etc/audio_policy_configuration.xml
    fi"

    echo "[*] Deploying scripts to /system/bin/..."
    adb push "${ROOT_DIR}/scripts/usb_audio_event.sh" /system/bin/usb_audio_event.sh
    adb push "${ROOT_DIR}/scripts/usb_audio_daemon.sh" /system/bin/usb_audio_daemon.sh
    adb shell "chmod 755 /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh"
    adb shell "chown root:shell /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh"

    echo "[*] Deploying init service configuration to /system/etc/init/..."
    adb push "${ROOT_DIR}/init/usb_audio.rc" /system/etc/init/usb_audio.rc
    adb shell "chmod 644 /system/etc/init/usb_audio.rc"
    adb shell "chown root:root /system/etc/init/usb_audio.rc"

    echo "[*] Initializing daemon process..."
    adb shell "killall -q usb_audio_daemon.sh inotifyd || true"
    adb shell "/system/bin/usb_audio_event.sh init"
    adb shell "nohup /system/bin/usb_audio_daemon.sh >/dev/null 2>&1 &"

    echo "[+] Installation complete. Verifying running daemon..."
    adb shell "ps -ef | grep -E 'usb_audio|inotifyd' | grep -v grep" || true

else
    # On-device installation path
    echo "[*] Backing up vendor audio policy configuration..."
    if [ ! -f /vendor/etc/audio_policy_configuration.xml.bak ]; then
        cp /vendor/etc/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml.bak
    fi

    echo "[*] Checking vendor audio policy..."
    if ! grep -q 'usb_audio_policy_configuration.xml' /vendor/etc/audio_policy_configuration.xml; then
        sed -i '/<xi:include href=\"r_submix_audio_policy_configuration.xml\"\/>/a \    <xi:include href=\"usb_audio_policy_configuration.xml\"\/>' /vendor/etc/audio_policy_configuration.xml
    fi

    echo "[*] Copying binaries..."
    cp "${ROOT_DIR}/scripts/usb_audio_event.sh" /system/bin/usb_audio_event.sh
    cp "${ROOT_DIR}/scripts/usb_audio_daemon.sh" /system/bin/usb_audio_daemon.sh
    chmod 755 /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh
    chown root:shell /system/bin/usb_audio_event.sh /system/bin/usb_audio_daemon.sh

    echo "[*] Copying init configuration..."
    cp "${ROOT_DIR}/init/usb_audio.rc" /system/etc/init/usb_audio.rc
    chmod 644 /system/etc/init/usb_audio.rc
    chown root:root /system/etc/init/usb_audio.rc

    killall -q usb_audio_daemon.sh inotifyd || true
    /system/bin/usb_audio_event.sh init
    nohup /system/bin/usb_audio_daemon.sh >/dev/null 2>&1 &

    echo "[+] Installation complete on device."
fi

