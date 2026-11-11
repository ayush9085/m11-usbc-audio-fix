#!/system/bin/sh
# manual_register.sh
# Diagnostic and manual override utility for USB audio routing.
# Usage:
#   manual_register.sh plug [card_number] [device_name]
#   manual_register.sh unplug [card_number] [device_name]
#   manual_register.sh status

ACTION="${1:-status}"
CARD="${2:-0}"
NAME="${3:-USB-Audio Headset}"

# Binder constants
TYPE_OUT=67108864     # AUDIO_DEVICE_OUT_USB_HEADSET (0x04000000)
TYPE_IN=-2113929216   # AUDIO_DEVICE_IN_USB_HEADSET  (0x82000000)

case "$ACTION" in
    plug|connect|1)
        echo "[+] Registering USB audio peripheral (card=$CARD, name=$NAME)..."
        service call audio 71 i32 $TYPE_OUT i32 1 s16 "card=${CARD};device=0" s16 "$NAME" s16 "UsbAlsaDevice"
        service call audio 71 i32 $TYPE_IN i32 1 s16 "card=${CARD};device=0" s16 "$NAME" s16 "UsbAlsaDevice"
        printf "1\n%s\n%s\n" "$CARD" "$NAME" > /dev/.usb_audio_state
        echo "[+] Registration transaction dispatched."
        ;;
    unplug|disconnect|0)
        echo "[-] Deregistering USB audio peripheral (card=$CARD, name=$NAME)..."
        service call audio 71 i32 $TYPE_OUT i32 0 s16 "card=${CARD};device=0" s16 "$NAME" s16 "UsbAlsaDevice"
        service call audio 71 i32 $TYPE_IN i32 0 s16 "card=${CARD};device=0" s16 "$NAME" s16 "UsbAlsaDevice"
        printf "0\n\n\n" > /dev/.usb_audio_state
        echo "[-] Deregistration transaction dispatched."
        ;;
    status)
        echo "=== USB Audio System Status ==="
        echo -n "State file: "
        if [ -f /dev/.usb_audio_state ]; then
            cat /dev/.usb_audio_state | tr '\n' ' '
            echo ""
        else
            echo "Not created"
        fi
        echo "--- ALSA Cards ---"
        cat /proc/asound/cards
        echo "--- Daemon Process ---"
        ps -ef 2>/dev/null | grep -E "usb_audio|inotifyd" | grep -v grep
        ;;
    *)
        echo "Usage: $0 {plug|unplug|status} [card_number] [device_name]"
        exit 1
        ;;
esac

