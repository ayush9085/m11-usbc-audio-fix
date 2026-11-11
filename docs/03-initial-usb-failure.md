# 03 - Initial USB Failure Analysis

## Symptoms on Stock LineageOS 19.1 Kernel (4.9.305)
Upon initial testing of the newly installed LineageOS 19.1 image, connecting the JBL TUNE 310C USB-C headset produced no response:
- Audio continued playing through the device's internal loudspeaker.
- No system UI notification appeared indicating USB headset connection.
- No volume slider icon change occurred.

## Low-Level Investigation

### 1. USB Bus Inspection
Checking the Linux USB filesystem revealed an unexpected absence of host-controller activity:
```bash
adb shell ls -la /dev/bus/usb
```
**Output:** Directory was empty or contained only the root hub (`001/001`). No child device nodes were instantiated.

### 2. Sysfs USB OTG State
Inspecting the Qualcomm Android USB state:
```bash
adb shell cat /sys/class/android_usb/android0/state
```
**Output:** `DISCONNECTED`

### 3. ALSA Sound Card Registration
Querying the Advanced Linux Sound Architecture (ALSA) subsystem:
```bash
adb shell cat /proc/asound/cards
```
**Output:**
```text
 0 [msm8953sndcardm]: msm8953-snd-car - msm8953-snd-card-mtp
```
Only the Qualcomm internal SoC sound card was registered. No secondary card or `snd-usb-audio` driver was active.

### 4. Kernel Dmesg Analysis
Reviewing kernel ring-buffer logs immediately after inserting the peripheral:
```text
dwc3 7000000.dwc3: otg: ID pin status unchanged
dwc3 7000000.dwc3: entering low-power suspend mode
```
The Qualcomm DWC3 driver failed to detect the OTG host-mode transition. The driver treated the attachment as an idle bus state and remained suspended. Consequently, the USB audio device never received power or enumeration commands.
