# 01 - Project Overview

## Objective
This project documents the root cause analysis, reverse engineering, and implementation of a permanent fix for USB-C digital audio peripheral routing on a Samsung Galaxy M11 (`SM-M115F` / `m11q`) running unofficial LineageOS 19.1 (Android 12).

## Background
The user upgraded a Samsung Galaxy M11 from its stock Android 11 OEM firmware to an unofficial LineageOS 19.1 build. Following the upgrade, external USB-C digital audio peripherals (specifically a JBL TUNE 310C USB-C headset featuring a KTMICRO USB audio controller, VID:PID `0ecb:20f6`) failed to output audio. Media continued to play exclusively through the phone's internal loudspeaker.

## Technical Challenge Summary
The failure spanned multiple distinct layers of the software and firmware stack:
1. **Low-Level USB Host Controller / OTG Layer**: The stock ROM kernel (`4.9.305`) suffered from a broken USB OTG state machine that suspended the Qualcomm DWC3 controller upon peripheral attachment, failing to enumerate any USB devices in `/dev/bus/usb`.
2. **Vendor Audio Hardware Abstraction Layer**: The vendor audio configuration (`/vendor/etc/audio_policy_configuration.xml`) omitted the USB Audio HAL module definition, preventing `AudioPolicyManager` from initializing USB hardware routing endpoints.
3. **Android 12 Framework Synchronization Layer**: Even after repairing the kernel and vendor configuration, `system_server` exhibited a race condition: `UsbAlsaManager` attempted to scan ALSA card identifiers before the kernel driver asynchronously populated `/proc/asound/card0/usbbus`. Because the scan aborted and was never retried, Android never issued device attachment events to `AudioService`.

## Solution Scope
The issue was resolved cleanly without wiping user data, without replacing the ROM, and without patching Java framework binaries on disk:
- Deployed the `4.9.319-ifoodplayer+` community kernel to resolve the Qualcomm SDM450 DWC3 OTG driver regression.
- Injected `<xi:include href="usb_audio_policy_configuration.xml"/>` into the vendor audio policy XML.
- Implemented an event-driven background service utilizing `toybox inotifyd` to observe `/dev/snd` inode creation, settle ALSA procfs data, and directly invoke `IAudioService.setWiredDeviceConnectionState` via Binder transaction code 71.

