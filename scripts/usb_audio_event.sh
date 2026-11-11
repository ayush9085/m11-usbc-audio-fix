#!/system/bin/sh
# usb_audio_event.sh
# Event handler for USB-C audio peripheral hotplug events on Android 12.
# Dispatched by usb_audio_daemon.sh via toybox inotifyd.

STATE_FILE="/dev/.usb_audio_state"
LOCK_DIR="/dev/.usb_audio_lock"

acquire_lock() {
    local count=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 0.1
        count=$((count + 1))
        if [ "$count" -ge 20 ]; then
            rmdir "$LOCK_DIR" 2>/dev/null
            break
        fi
    done
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null
}

EVENT="$1"
DIR="$2"
FILE="$3"

# Filter irrelevant node changes when called via inotify
if [ "$EVENT" != "init" ] && [ "$EVENT" != "force" ]; then
    case "$FILE" in
        pcm*|control*) ;;
        *) exit 0 ;;
    esac
fi

acquire_lock

CURRENT_STATE=0
CURRENT_CARD=""
CURRENT_NAME=""

if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(head -n 1 "$STATE_FILE" 2>/dev/null)
    CURRENT_CARD=$(sed -n '2p' "$STATE_FILE" 2>/dev/null)
    CURRENT_NAME=$(sed -n '3p' "$STATE_FILE" 2>/dev/null)
fi

# Detect active USB audio card from ALSA procfs
USB_LINE=$(cat /proc/asound/cards 2>/dev/null | grep "USB-Audio" | head -n 1)

if [ -n "$USB_LINE" ]; then
    CARD_NUM=$(echo "$USB_LINE" | awk '{print $1}')
    CARD_NAME=$(echo "$USB_LINE" | sed 's/.*USB-Audio - //' | tr -d '\r\n')

    # Register only on fresh attachment or card index change
    if [ "$CURRENT_STATE" != "1" ] || [ "$CURRENT_CARD" != "$CARD_NUM" ]; then
        # Settle delay ensuring procfs and sysfs entries are fully initialized
        sleep 0.5

        # Binder transaction 71: setWiredDeviceConnectionState(type, state, address, name, caller)
        # AUDIO_DEVICE_OUT_USB_HEADSET: 0x04000000 = 67108864
        service call audio 71 i32 67108864 i32 1 s16 "card=${CARD_NUM};device=0" s16 "${CARD_NAME}" s16 "UsbAlsaDevice" >/dev/null 2>&1

        # AUDIO_DEVICE_IN_USB_HEADSET: 0x82000000 = -2113929216
        service call audio 71 i32 -2113929216 i32 1 s16 "card=${CARD_NUM};device=0" s16 "${CARD_NAME}" s16 "UsbAlsaDevice" >/dev/null 2>&1

        printf "1\n%s\n%s\n" "$CARD_NUM" "$CARD_NAME" > "$STATE_FILE"
        log -p i -t UsbAudioDaemon "Plugged in: card=${CARD_NUM} name=${CARD_NAME}"
    fi
else
    # Disconnect if previously registered
    if [ "$CURRENT_STATE" = "1" ]; then
        service call audio 71 i32 67108864 i32 0 s16 "card=${CURRENT_CARD};device=0" s16 "${CURRENT_NAME}" s16 "UsbAlsaDevice" >/dev/null 2>&1
        service call audio 71 i32 -2113929216 i32 0 s16 "card=${CURRENT_CARD};device=0" s16 "${CURRENT_NAME}" s16 "UsbAlsaDevice" >/dev/null 2>&1

        printf "0\n\n\n" > "$STATE_FILE"
        log -p i -t UsbAudioDaemon "Unplugged: card=${CURRENT_CARD} name=${CURRENT_NAME}"
    fi
fi

release_lock
