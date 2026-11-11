# USB-C Digital Audio Subsystem Fix for Samsung Galaxy M11

A robust, production-grade fix and engineering case study resolving USB-C digital audio routing failures on the Samsung Galaxy M11 (`m11q`) running unofficial LineageOS 19.1 (Android 12).

---

## Overview

When running unofficial LineageOS 19.1 (Android 12) on the Samsung Galaxy M11, external USB-C digital audio peripherals (such as USB-C DAC headsets) fail to output sound. Even when the peripheral is enumerated by the operating system kernel and registered as an ALSA sound card, media audio continues routing exclusively through the phone's internal loudspeaker.

This repository provides:
1. **Root Cause Analysis**: Detailed technical breakdown across the Linux USB host controller, vendor audio HAL, and Android framework layers.
2. **Automated Hotplug Daemon**: An event-driven, zero-polling background monitor that detects audio peripheral attachments via filesystem inotify events and synchronizes the Android `AudioService` via Binder IPC.
3. **Deployment & Verification Tooling**: Production-tested installation, rollback, diagnostic, and health-check scripts.

---

## Problem & Architecture Breakdown

The audio routing failure was determined to be a compound issue across three separate system layers:

```
+--------------------------------------------------------------------------+
| Layer 3: Framework Timing Race (system_server)                           |
| UsbAlsaManager scans /proc/asound/ before snd-usb-audio finishes init.   |
| Scan aborts with 0 devices found and is never retried.                   |
+--------------------------------------------------------------------------+
                                     ^
                                     |
+--------------------------------------------------------------------------+
| Layer 2: Vendor Audio Policy Declarative Config                          |
| /vendor/etc/audio_policy_configuration.xml omitted the USB HAL module.   |
+--------------------------------------------------------------------------+
                                     ^
                                     |
+--------------------------------------------------------------------------+
| Layer 1: Kernel DWC3 USB Host PHY Controller                             |
| Stock ROM kernel had a broken OTG state machine; failed USB enumeration.  |
+--------------------------------------------------------------------------+
```

### The Fix Strategy
Rather than modifying and recompiling core Android framework JARs on disk, the solution uses a modular, non-destructive approach:
- **Kernel Layer**: A community kernel with corrected OTG power sequencing is used to restore USB host-mode enumeration.
- **Vendor Layer**: The vendor audio policy XML is updated to declare support for the standard USB Audio HAL.
- **Framework Synchronization**: A lightweight background daemon monitors `/dev/snd` using `toybox inotifyd`. Upon peripheral attachment, it waits for ALSA nodes to settle (500 ms) and directly invokes `IAudioService.setWiredDeviceConnectionState` via Android Binder transaction 71.

This ensures instantaneous audio routing on connect, clean fallback to the built-in speaker on disconnect, zero idle CPU consumption, and preservation of deep-sleep power states.

---

## Repository Structure

```
.
├── README.md               # Main documentation & architecture summary
├── LICENSE                 # MIT License
├── CHANGELOG.md            # Release history & technical milestones
├── CONTRIBUTING.md         # Guidelines for testing & patches
├── SECURITY.md             # Security scope & privilege disclosure
├── config/
│   └── audio_policy_configuration.xml.example  # Sample patched vendor audio policy
├── diagrams/
│   ├── architecture.md     # Full stack architecture diagram
│   ├── failure-path.md     # Dual-layer failure sequence diagram
│   └── final-path.md       # Event-driven resolution sequence diagram
├── docs/
│   ├── 01-project-overview.md
│   ├── 02-device-and-software-state.md
│   ├── 03-initial-usb-failure.md
│   ├── 04-kernel-investigation.md
│   ├── 05-alsa-verification.md
│   ├── 06-android-audio-policy.md
│   ├── 07-audioflinger-investigation.md
│   ├── 08-system-server-investigation.md
│   ├── 09-binder-reverse-engineering.md
│   ├── 10-root-cause.md
│   ├── 11-final-solution.md
│   ├── 12-verification.md
│   ├── 13-troubleshooting.md
│   └── 14-rollback.md
├── evidence/
│   ├── README.md           # Sanitized log telemetry index
│   ├── alsa.txt            # ALSA stream capabilities & procfs output
│   ├── audio-flinger.txt   # Dumpsys audio_flinger active stream traces
│   ├── audio-policy.txt    # Dumpsys audio_policy HW module extracts
│   ├── hotplug.txt         # Live daemon hotplug logcat traces
│   ├── usb-detection.txt   # USB sysfs device enumeration dumps
│   └── usb-framework.txt   # UsbAlsaManager race condition logcat
├── init/
│   └── usb_audio.rc        # Android init service configuration
└── scripts/
    ├── health_check.sh     # Comprehensive subsystem verification tool
    ├── install.sh          # Automated installer (runs via ADB or on-device)
    ├── manual_register.sh  # Diagnostic tool for manual Binder routing
    ├── uninstall.sh        # Complete rollback & uninstaller
    ├── usb_audio_daemon.sh # Inode monitor (toybox inotifyd)
    └── usb_audio_event.sh  # Event handler & Binder transaction dispatcher
```

---

## Quick Start & Deployment

### Prerequisites
- Samsung Galaxy M11 (`m11q`) running LineageOS 19.1 (or compatible Android 12 ROM).
- Working root access via ADB (`adb root`).
- Kernel supporting USB OTG host mode (see [04-kernel-investigation.md](docs/04-kernel-investigation.md)).

### 1. Automated Installation
Connect the device to your computer via USB (or wireless ADB) and run:

```bash
git clone https://github.com/<owner>/m11-usbc-audio-fix.git
cd m11-usbc-audio-fix
./scripts/install.sh
```

The installer will:
1. Remount `/system` and `/vendor` partitions read-write.
2. Back up `/vendor/etc/audio_policy_configuration.xml`.
3. Inject the `<xi:include href="usb_audio_policy_configuration.xml"/>` directive if missing.
4. Deploy `usb_audio_event.sh` and `usb_audio_daemon.sh` to `/system/bin/`.
5. Deploy `usb_audio.rc` to `/system/etc/init/`.
6. Start the background monitor service.

### 2. Verify Subsystem Health
Run the automated diagnostic health check:

```bash
./scripts/health_check.sh
```

Every layer (Kernel, ALSA, Vendor Policy, Binaries, Daemon, and Audio HAL) is probed and evaluated with `PASS`, `WARN`, or `FAIL`.

### 3. Rollback
To restore the device to its unmodified state at any time:

```bash
./scripts/uninstall.sh
```

---

## Technical Documentation Index

For complete step-by-step engineering records and reverse engineering analysis:
- [01 - Project Overview](docs/01-project-overview.md)
- [02 - Device & Software State](docs/02-device-and-software-state.md)
- [03 - Initial USB Failure Analysis](docs/03-initial-usb-failure.md)
- [04 - Kernel Investigation & Replacement](docs/04-kernel-investigation.md)
- [05 - ALSA Subsystem Verification](docs/05-alsa-verification.md)
- [06 - Android Audio Policy Configuration](docs/06-android-audio-policy.md)
- [07 - AudioFlinger Stream Investigation](docs/07-audioflinger-investigation.md)
- [08 - System Server Framework Investigation](docs/08-system-server-investigation.md)
- [09 - Binder IPC Reverse Engineering](docs/09-binder-reverse-engineering.md)
- [10 - Root Cause Analysis](docs/10-root-cause.md)
- [11 - Final Solution Architecture](docs/11-final-solution.md)
- [12 - Verification & Telemetry](docs/12-verification.md)
- [13 - Troubleshooting Guide](docs/13-troubleshooting.md)
- [14 - Rollback Procedure](docs/14-rollback.md)

---

## License

This project is licensed under the terms of the [MIT License](LICENSE).
