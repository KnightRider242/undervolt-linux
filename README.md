# ThrottleStop undervolt profile for Linux

A portable Linux conversion of the supplied Windows ThrottleStop configuration. It uses [`intel-undervolt`](https://github.com/kitsunyan/intel-undervolt) because CoreCtrl does not apply Intel FIVR voltage offsets.

> [!WARNING]
> Undervolting and package-power changes can cause crashes, data corruption, boot loops, or hardware problems. Test manually before enabling at boot. These exact values are specific to the laptop from which the ThrottleStop configuration was exported.

## Hardware scope

This project is for compatible **x86-64 Intel CPUs**. It is not an AMD undervolting tool. Firmware, microcode, or Intel Undervolt Protection may block voltage changes even when the scripts install correctly. Upstream documents support for Haswell and newer, while some newer platforms and locked BIOS configurations may not accept offsets.

## Linux distribution support

`install.sh` detects the available package manager and supports:

- Fedora, Nobara, and related `dnf` systems
- Arch Linux, Manjaro, EndeavourOS, and related `pacman` systems
- Debian, Ubuntu, Linux Mint, Pop!_OS, and related `apt` systems
- openSUSE and related `zypper` systems
- Void Linux (`xbps`)
- Alpine Linux (`apk`)
- Gentoo (`emerge`)
- Solus (`eopkg`)
- Other distributions through the official-source fallback when `gcc`, `make`, `git`, and `pkg-config` are available

The installer prefers a native `intel-undervolt` package. When none is available, it builds the official upstream source and enables the appropriate build integration for systemd, OpenRC, or elogind.

Automatic boot application is supported for **systemd** and **OpenRC**. Other init systems can still use the manual profile scripts.

## Converted values

### Performance

- CPU core: **-135.74 mV**
- CPU cache: **-135.74 mV**
- PL1 / sustained package limit: **45 W**
- PL2 / short package limit: **55 W**

### Battery

- CPU core: **-135.74 mV**
- CPU cache: **-130.86 mV**
- PL1 / sustained package limit: **40 W**
- PL2 / short package limit: **45 W**

ThrottleStop also stored an approximately **-135.74 mV iGPU Unslice** offset. `intel-undervolt` does not expose that separate sixth ThrottleStop voltage plane, so it is omitted. The ThrottleStop Internet/Game profiles contained unusually high 95 W / 162 W package limits and were intentionally excluded.

## Install

```bash
chmod +x *.sh
./install.sh
```

The installer backs up an existing `/etc/intel-undervolt.conf`, installs the Performance configuration, and deliberately does **not** enable it at boot.

Check detected support at any time:

```bash
./check-support.sh
```

## Test manually

Test Performance:

```bash
./apply-performance.sh
```

Test Battery:

```bash
./apply-battery.sh
```

After applying a profile, verify that `intel-undervolt read` reports values close to the requested offsets. A reading of `0.00 mV`, `Values do not equal`, permission/MSR errors, or a locked mailbox usually means firmware or platform protection is blocking the change.

Stress-test sustained load, short boost, idle, suspend/resume, video playback, and AC/battery transitions before making the setting persistent.

## Enable at boot

Only after the profile is stable:

```bash
./enable-at-boot.sh
```

The script enables `intel-undervolt.service` or `intel-undervolt-loop.service` on systemd, and `intel-undervolt-loop` on OpenRC.

## Disable and reset

```bash
./disable-and-reset.sh
```

This disables known boot services, writes zero voltage offsets, applies the reset, and leaves power-limit restoration to firmware/reboot where necessary.

## CoreCtrl

CoreCtrl can still be used for monitoring and the CPU/GPU controls exposed by your hardware. Do not expect a `.ccpro` profile to reproduce these Intel voltage offsets. Avoid having CoreCtrl, TLP, tuned, auto-cpufreq, and power-profiles-daemon all write the same power-policy settings.

## Files

- `install.sh` — cross-distribution installer
- `check-support.sh` — hardware/init/tool diagnostics
- `apply-performance.sh` — apply the Performance profile manually
- `apply-battery.sh` — apply the Battery profile manually
- `enable-at-boot.sh` — enable persistence on systemd or OpenRC
- `disable-and-reset.sh` — disable persistence and reset offsets
- `intel-undervolt-performance.conf` — Performance values
- `intel-undervolt-battery.conf` — Battery values
