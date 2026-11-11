# 04 - Kernel Investigation & Replacement

## Kernel Upstream OTG Regression
Analysis of the `4.9.305-gdacf5f26bb9c-dirty` kernel source tree indicated an upstream regression in the Qualcomm MSM8953 / SDM450 DWC3 USB controller glue code. A commit refactoring the OTG transceiver power sequencing had inadvertently disabled automatic VBUS boost on type-C digital accessories.

## Boot Partition Preservation
Before flashing alternative kernel images, a raw bit-level backup of the original boot partition was extracted:
```bash
adb shell 'dd if=/dev/block/by-name/boot of=/tmp/boot-4.9.305.img bs=4096'
adb pull /tmp/boot-4.9.305.img ./backup/boot-4.9.305.img
```
- **Backup Size**: 67,108,864 bytes (64 MB)
- **SHA-256 Checksum**: `2f42d289295b4442fda0e8f6b5dc262e739e1ec1fd44b79d2cd1e569fd1ead74`

## Flashing Patched Community Kernel
A community kernel build designed specifically for Samsung SDM450 devices was identified:
- **Package**: `Kernel_for_a11q_ARM64.zip`
- **Release Version**: `v1.1.1`
- **Kernel String**: `4.9.319-ifoodplayer+ #4 SMP PREEMPT`
- **Package SHA-256**: `ea69c34119d92173ccd8567b3f3d236bb72436190f79923c080f1826331eabde`
- **Release Note**: "Fixed USB OTG issue caused by kernel upstream."

The package was installed through TWRP recovery using the integrated AnyKernel3 packaging script, patching only the kernel zImage while preserving the vendor ramdisk.

## Post-Flash Verification
Following reboot, kernel version verification confirmed:
```bash
$ uname -a
Linux localhost 4.9.319-ifoodplayer+ #4 SMP PREEMPT Mon May 18 18:59:56 UTC 2026 aarch64
```
Upon plugging in the JBL TUNE 310C headset:
- VBUS power engaged immediately.
- The USB controller transitioned to host mode.
- Kernel logcat and dmesg reported successful enumeration of device `0ecb:20f6`.
- `snd-usb-audio` driver initialized successfully.
