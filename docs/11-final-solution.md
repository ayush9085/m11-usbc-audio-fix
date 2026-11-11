# 11 - Final Solution Architecture

## Engineering Requirements
The permanent solution had to satisfy the following constraints:
1. **Zero User Data Loss**: No wipes, partition erasures, or factory resets.
2. **Framework Stability**: Avoid modifying precompiled ODEX/ART bytecode or replacing `services.jar`.
3. **Zero Polling Overhead**: No busy-waiting loops (`sleep 1`) that prevent the Snapdragon 450 CPU from entering low-power deep sleep (C-states).
4. **Bidirectional Hotplug**: Automatic routing upon plug-in, and instant fallback to built-in speaker upon unplug.
5. **Persistence Across Reboots**: Automatic startup on system boot via Android init.

## System Components

### 1. Inode Event Monitor (`usb_audio_daemon.sh`)
Instead of a polling loop, the daemon utilizes the Android `toybox inotifyd` utility to monitor the Linux kernel's character device directory `/dev/snd/`:
```bash
#!/system/bin/sh
/system/bin/usb_audio_event.sh init

while true; do
    toybox inotifyd /system/bin/usb_audio_event.sh /dev/snd:nd
    sleep 2
done
```
- `inotifyd` blocks in the kernel via `epoll_wait()` or `read()` on an inotify file descriptor, consuming **0% CPU** while idle.
- Mask `:nd` monitors node creation (`n`) and deletion (`d`).

### 2. Event Dispatcher & Lock Manager (`usb_audio_event.sh`)
When a node in `/dev/snd` changes:
- `usb_audio_event.sh` filters out unrelated event noise (acting only on `pcm*` and `control*` nodes).
- Acquires an atomic directory mutex lock (`/dev/.usb_audio_lock`) to serialize concurrent node events emitted during driver probing.
- Parses `/proc/asound/cards` using `cat /proc/asound/cards | grep "USB-Audio"` (bypassing a toybox procfs `st_size == 0` stat issue).
- Introduces a calibrated **0.5-second settle delay** on connect, allowing `snd-usb-audio` to fully initialize all ALSA control and mixer nodes.
- Dispatches Binder transaction 71 to `IAudioService` for both output (`67108864`) and microphone input (`-2113929216`).
- Writes state to `/dev/.usb_audio_state`.

### 3. Init Service Definition (`usb_audio.rc`)
Placed in `/system/etc/init/usb_audio.rc` to launch the daemon after boot completes:
```rc
service usb_audio_daemon /system/bin/usb_audio_daemon.sh
    class late_start
    user root
    group root audio system
    disabled
    seclabel u:r:su:s0

on property:sys.boot_completed=1
    start usb_audio_daemon
```
