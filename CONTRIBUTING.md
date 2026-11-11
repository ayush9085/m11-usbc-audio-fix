# Contributing Guidelines

Contributions to this project are welcome to help improve USB audio compatibility across Qualcomm MSM8953 / SDM450 devices running Android 12+.

## Contribution Workflow
1. Fork this repository and create a descriptive feature or bugfix branch.
2. Ensure changes maintain compatibility with Android 12 init structure and SELinux requirements.
3. Validate shell scripts against POSIX / Android toybox sh standards (avoid non-standard Bash extensions).
4. Verify that state locks, atomic transactions, and idempotency guarantees remain intact.
5. Provide detailed commit messages including relevant device logs, ALSA card descriptors, or Binder traces.
6. Submit a Pull Request with a clear description of hardware tested.

## Testing Checklist
- [ ] USB audio peripheral hotplug (plug in while media is playing).
- [ ] USB audio peripheral cold boot (booting with headset connected).
- [ ] Peripheral unplug during active media playback (graceful failover to internal speaker).
- [ ] Microphone input recording test (`dumpsys media.audio_flinger` capture stream).
- [ ] Sleep / deep-sleep battery drain verification (no busy-waiting or wake-locks held).
