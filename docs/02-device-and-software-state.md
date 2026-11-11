# 02 - Device and Software State

## Target Device Specifications
- **Brand / Model**: Samsung Galaxy M11 (`SM-M115F`)
- **Board Codename**: `m11q` (Qualcomm SDM450 / MSM8953 family)
- **SoC Architecture**: Octa-core ARM Cortex-A53, 64-bit ARMv8 (`aarch64`)
- **Partition Layout**: Non-A/B (single system, vendor, boot, and recovery slots)
- **Baseband / Bootloader Version**: `M115FXXS5CWK3` (Bootloader Revision 5)
- **OEM Unlock Status**: Unlocked (`ro.boot.flash.locked = 0`, `sys.oem_unlock_allowed = 1`)

## Host Workstation Environment
- **Platform**: Apple Silicon Mac (ARM64 architecture)
- **Flashing Utility**: Heimdall v2.2.2 (compiled natively against `libusb 1.0.27` from source)
- **Bridge Tool**: Android Debug Bridge (`adb`) version 1.0.41

## Software Baseline
- **Recovery**: TWRP 3.7.0_12-smiley
- **Operating System**: LineageOS 19.1 Unofficial (`eng.admin.20260305.060523`, Android 12)
- **Google Apps Package**: BiTGApps ARM64 12.1.0 Mini
- **Vendor Fingerprint**: `samsung/m11qnsxx/m11q:11/RP1A.200720.012/M115FXXU3BVD1:user/release-keys`
- **Initial Kernel**: `4.9.305-gdacf5f26bb9c-dirty`
- **Final Kernel**: `4.9.319-ifoodplayer+ #4 SMP PREEMPT`

## Target Audio Peripheral
- **Brand / Model**: JBL TUNE 310C USB-C Earphones
- **Audio Controller**: KTMICRO High-Resolution Audio DAC/ADC
- **USB Vendor ID (VID)**: `0ecb`
- **USB Product ID (PID)**: `20f6`
- **Capabilities**: Dual-channel 24-bit 96 kHz PCM DAC, single-channel 16/24-bit 48/96 kHz ADC, USB HID in-line remote buttons

