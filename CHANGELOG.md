# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-11-11

### Initial Release
- **Kernel USB Layer**: Identified and resolved Qualcomm SDM450 DWC3 OTG driver failure by transitioning from stock kernel 4.9.305 to 4.9.319-ifoodplayer+, restoring Linux USB enumeration and ALSA sound card exposure.
- **Vendor Audio HAL**: Added USB audio policy configuration reference to `/vendor/etc/audio_policy_configuration.xml` to enable `android.hardware.audio@7.0` USB HAL module loading.
- **Framework Analysis**: Reverse engineered Android 12 `services.jar` and `framework.jar` to locate the `UsbAlsaManager` timing race where `AlsaCardsParser.scan()` executed prior to kernel `/proc/asound/card0/usbbus` population.
- **Binder IPC Automation**: Implemented low-latency hotplug handler using Binder transaction code 71 (`IAudioService.setWiredDeviceConnectionState`) for both `AUDIO_DEVICE_OUT_USB_HEADSET` (`67108864`) and `AUDIO_DEVICE_IN_USB_HEADSET` (`-2113929216`).
- **Init Daemon**: Integrated `usb_audio_daemon.sh` and `usb_audio.rc` with `toybox inotifyd` file-descriptor monitoring on `/dev/snd` to automate plug and unplug events with zero idle CPU overhead.
- **Verification**: Validated 96 kHz / 24-bit PCM stereo playback and mono microphone capture on external USB-C digital audio peripherals (tested with JBL TUNE 310C).

