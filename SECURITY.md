# Security Policy

## Supported Releases
Only the latest release on the primary branch is actively maintained.

## Scope & Device Security
This project introduces system-level modifications on unlocked devices:
- Modifications are scoped strictly to audio routing automation and vendor policy configuration.
- The init service runs under `root` with the `u:r:su:s0` SELinux domain as required by custom ROM environments to interact with `service call audio`.
- Scripts do not expose network ports, store secrets, or alter persistent cryptographic partitions.
- All IPC calls use standard Android Binder interfaces exposed by `IAudioService`.

## Reporting Vulnerabilities
If you discover a security issue or privilege escalation flaw within the provided scripts or configurations, please open a private security advisory or contact the maintainers directly through GitHub.
