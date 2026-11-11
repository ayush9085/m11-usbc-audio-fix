# 05 - ALSA Subsystem Verification

With kernel `4.9.319-ifoodplayer+` running and the JBL headset connected, ALSA layer verification was performed.

## ALSA Card Listing
```bash
adb shell cat /proc/asound/cards
```
**Output:**
```text
 0 [USBC           ]: USB-Audio - JBL TUNE 310C USB-C
                      KTMICRO JBL TUNE 310C USB-C at usb-xhci-hcd.0.auto-1, full speed
 1 [msm8953sndcardm]: msm8953-snd-car - msm8953-snd-card-mtp
                      msm8953-snd-card-mtp
```
Note that ALSA assigned Card 0 (`USBC`) to the external USB-C headset, while the SoC audio hardware occupied Card 1.

## Stream Format Capabilities
Querying `/proc/asound/card0/stream0`:
```text
Playback:
  Format: S24_3LE (24-bit PCM)
  Channels: 2 (Stereo)
  Rates: 44100, 48000, 88200, 96000 Hz

Capture:
  Format: S16_LE (16-bit PCM)
  Channels: 1 (Mono)
  Rates: 48000, 96000 Hz
```

## Direct Hardware Playback Test
To determine whether ALSA could drive the hardware independently of the Android audio framework, raw PCM data was piped directly to the ALSA device node:
```bash
adb shell "tinyplay /data/local/tmp/test.wav -D 0 -d 0"
```
**Result:** Audio played clearly and distortion-free directly through the JBL earphones. This proved conclusively that:
1. Physical USB Type-C host signaling and power delivery were fully functional.
2. The Linux kernel `snd-usb-audio` driver was operating correctly.
3. The hardware DAC in the JBL earphones was operational.
4. The remaining failure was located entirely in the higher-level Android audio framework and HAL.

