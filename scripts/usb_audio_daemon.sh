#!/system/bin/sh
# usb_audio_daemon.sh
# Background listener monitoring /dev/snd via toybox inotifyd.
# Initiates state check at startup, then blocks waiting on kernel device nodes.

/system/bin/usb_audio_event.sh init

while true; do
    # inotifyd flags: 'n' (CREATE), 'd' (DELETE)
    toybox inotifyd /system/bin/usb_audio_event.sh /dev/snd:nd
    sleep 2
done

