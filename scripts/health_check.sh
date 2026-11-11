#!/bin/bash
# health_check.sh
# Verification utility to inspect each layer of the USB-C audio subsystem.
# Returns PASS / FAIL / WARN for every diagnostic probe.

set -u

RUN_CMD=""

if [ -f "/system/bin/sh" ] && [ "$(id -u)" -eq 0 ]; then
    RUN_CMD="eval"
else
    if ! command -v adb >/dev/null 2>&1; then
        echo "[-] Error: 'adb' command not found."
        exit 1
    fi
    RUN_CMD="adb shell"
fi

echo "========================================================"
echo "    Samsung Galaxy M11 (m11q) USB Audio Health Check   "
echo "========================================================"

passes=0
fails=0
warns=0

check() {
    local desc="$1"
    local cmd="$2"
    local expected="$3"

    printf "%-50s " "$desc"
    local output
    output=$($RUN_CMD "$cmd" 2>/dev/null || true)

    if echo "$output" | grep -qE "$expected"; then
        echo "[ PASS ]"
        passes=$((passes + 1))
    else
        echo "[ FAIL ]"
        fails=$((fails + 1))
        echo "    Output: $output"
    fi
}

check_warn() {
    local desc="$1"
    local cmd="$2"
    local expected="$3"

    printf "%-50s " "$desc"
    local output
    output=$($RUN_CMD "$cmd" 2>/dev/null || true)

    if echo "$output" | grep -qE "$expected"; then
        echo "[ PASS ]"
        passes=$((passes + 1))
    else
        echo "[ WARN ]"
        warns=$((warns + 1))
        echo "    Note: $output"
    fi
}

# 1. Kernel Layer
check "Kernel supports OTG (4.9.319-ifoodplayer+)" \
    "uname -r" \
    "4\.9\.319"

# 2. ALSA Subsystem
check "ALSA procfs available" \
    "test -f /proc/asound/cards && echo ok" \
    "ok"

check_warn "USB audio device connected at ALSA layer" \
    "cat /proc/asound/cards" \
    "USB-Audio"

# 3. Vendor Audio Policy Configuration
check "Vendor audio policy includes USB XML" \
    "grep -c 'usb_audio_policy_configuration.xml' /vendor/etc/audio_policy_configuration.xml" \
    "[1-9]"

# 4. Binary and Script Installation
check "Event script installed (/system/bin)" \
    "test -x /system/bin/usb_audio_event.sh && echo ok" \
    "ok"

check "Daemon script installed (/system/bin)" \
    "test -x /system/bin/usb_audio_daemon.sh && echo ok" \
    "ok"

check "Init service definition installed" \
    "test -f /system/etc/init/usb_audio.rc && echo ok" \
    "ok"

# 5. Process Monitoring
check "Daemon / inotifyd process active" \
    "ps -ef | grep -E 'usb_audio|inotifyd' | grep -v grep" \
    "inotifyd|usb_audio_daemon"

# 6. Audio HAL & Routing Telemetry
check_warn "AudioPolicyManager USB module loaded" \
    "dumpsys media.audio_policy | grep -A 5 'HW Module 5'" \
    "usb|USB"

check_warn "Active AudioFlinger USB sink/proxy" \
    "dumpsys media.audio_flinger | grep -iE 'usb_headset|pcmC0D0'" \
    "usb_headset|pcmC0D0"

echo "========================================================"
echo "Summary: $passes passed, $fails failed, $warns warnings"
if [ "$fails" -eq 0 ]; then
    echo "Subsystem Status: HEALTHY"
    exit 0
else
    echo "Subsystem Status: ATTENTION REQUIRED"
    exit 1
fi

