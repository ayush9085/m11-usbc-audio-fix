# System Architecture

The following diagram illustrates the complete audio stack on the Samsung Galaxy M11 (`m11q`) running LineageOS 19.1 (Android 12), from the physical USB-C port to the Android application framework, and where the fix integrates.

```mermaid
flowchart TD
    subgraph Physical [Physical Layer]
        USB_PORT["USB-C Port (Type-C OTG)"]
        HEADSET["JBL TUNE 310C Headset (0ecb:20f6)"]
        HEADSET <--> USB_PORT
    end

    subgraph Kernel [Linux Kernel 4.9.319-ifoodplayer+]
        DWC3["Qualcomm DWC3 OTG Controller"]
        SND_USB["snd-usb-audio Driver"]
        ALSA_CORE["ALSA Subsystem Core (/dev/snd/*)"]
        USB_PORT <--> DWC3
        DWC3 --> SND_USB
        SND_USB --> ALSA_CORE
    end

    subgraph Automation [Event Daemon (Fix Layer)]
        INOTIFYD["toybox inotifyd (/dev/snd)"]
        EVENT_HANDLER["usb_audio_event.sh"]
        ALSA_CORE -.->|inode change| INOTIFYD
        INOTIFYD -->|trigger| EVENT_HANDLER
    end

    subgraph Native [Native Daemons & HAL]
        AUDIOSERVER["audioserver Process"]
        AUDIO_HAL["android.hardware.audio@7.0-impl"]
        AUDIO_POLICY_CONF["/vendor/etc/audio_policy_configuration.xml"]
        ALSA_CORE <--> AUDIO_HAL
        AUDIO_POLICY_CONF --> AUDIO_HAL
        AUDIO_HAL <--> AUDIOSERVER
    end

    subgraph Framework [Android 12 system_server]
        BINDER_SVC["IAudioService (service audio)"]
        AUDIO_POLICY_MGR["AudioPolicyManager"]
        AUDIO_FLINGER["AudioFlinger"]
        EVENT_HANDLER -->|"service call audio 71 (IPC)"| BINDER_SVC
        BINDER_SVC --> AUDIO_POLICY_MGR
        AUDIO_POLICY_MGR --> AUDIO_FLINGER
        AUDIO_FLINGER <--> AUDIOSERVER
    end

    subgraph Applications [User Space Applications]
        APP["Media Players / YouTube / Phone"]
        APP <--> Framework
    end
```

## Layer Descriptions
1. **Physical Layer**: Type-C CC pin configuration and digital audio streaming through KTMICRO USB DAC.
2. **Kernel Layer**: Host controller enumeration, `snd-usb-audio` driver binding, and node creation in `/dev/snd/pcmC0D0p`.
3. **Automation Layer**: Non-polling file monitor invoking Binder transaction 71 upon device node creation.
4. **Native Layer**: Hardware abstraction loading standard Qualcomm and USB audio policy specifications.
5. **Framework Layer**: Android audio routing decision engine and hardware stream management.

