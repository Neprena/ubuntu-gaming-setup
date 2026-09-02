# Ubuntu 26.04 Gaming Setup — Design

## Goal

Turn a clean Ubuntu 26.04 desktop installation into a maintainable gaming and game-streaming workstation tailored to this machine: NVIDIA GeForce RTX 4080, GNOME on Wayland, Secure Boot enabled, Alienware 3440×1440 240 Hz OLED, and Vibeshine/Moonlight streaming.

The system must remain a normal mutable Ubuntu installation. Native Ubuntu packages are preferred; Flatpak is used only when it is the materially better distribution channel.

## Scope

The project has two independently usable deliverables:

1. **Ubuntu Gaming Core** — NVIDIA/Vulkan, Steam/Proton, compatibility tooling, launchers, controllers, diagnostics.
2. **Streaming Extension** — Vibeshine plus an experimental GNOME/Wayland virtual-display workflow that can turn the physical OLED off during a remote session and restore it afterward.

The gaming core must never depend on the streaming or virtual-display components.

## Platform constraints

- Ubuntu 26.04 LTS desktop.
- GNOME, Wayland only; Xorg is not a supported target.
- NVIDIA GeForce RTX 4080.
- Secure Boot remains enabled.
- NVIDIA driver is selected through Ubuntu's supported driver mechanism (`ubuntu-drivers`) rather than a hard-coded branch, NVIDIA `.run` installer, or third-party driver PPA.
- APT/native packages have priority.
- No custom gaming kernel, speculative scheduler tuning, blanket sysctl tweaks, Mesa PPA, or other cargo-cult performance changes.
- HDR is out of scope.

## Architecture

The repository uses a small modular Bash installer rather than one monolithic script or Ansible. `setup.sh` is an orchestrator; focused modules own individual concerns and are designed to be safely re-runnable.

Planned structure:

```text
ubuntu-gaming-setup/
├── setup.sh
├── lib/
│   └── common.sh
├── modules/
│   ├── system.sh
│   ├── nvidia.sh
│   ├── gaming-stack.sh
│   ├── steam.sh
│   ├── proton.sh
│   ├── launchers.sh
│   ├── controllers.sh
│   ├── vibeshine.sh
│   └── virtual-display.sh
├── scripts/
│   ├── diagnostics.sh
│   ├── stream-start.sh
│   └── stream-stop.sh
├── config/
│   └── defaults.conf
├── tests/
└── docs/
```

`lib/common.sh` provides logging, command/package checks, privilege handling and shared guards. Modules expose a consistent entry point and avoid hidden cross-module state.

## Installer behavior

`setup.sh` performs preflight checks before making changes. It verifies Ubuntu 26.04, GNOME, a Wayland-capable target, expected architecture, Secure Boot state and NVIDIA hardware. A mismatch that would make the installation unsafe fails clearly rather than attempting to coerce the host into the expected configuration.

The installer supports a complete run as well as explicitly selecting/re-running modules. Re-running a completed module must converge on the intended state rather than duplicating repositories, configuration or downloads.

Operations requiring root privileges use `sudo`; user-scoped configuration is performed as the invoking desktop user rather than accidentally populating root's home directory.

## NVIDIA and graphics stack

The NVIDIA module enables the supported Ubuntu packaging path and invokes Ubuntu's driver selection instead of pinning a driver version. It must tolerate a reboot being required and report that state clearly.

The gaming stack installs both 64-bit and i386 Vulkan/OpenGL dependencies required by Steam/Proton. Diagnostics verify actual Vulkan functionality rather than merely checking that package names exist.

Secure Boot is not disabled by the installer. If driver enrollment or a reboot is required, the installer explains the required user action and stops at a safe boundary.

## Gaming stack

The core prepares:

- Steam using the native Ubuntu/Debian packaging route rather than Snap.
- Proton and support for GE-Proton, with ProtonUp-Qt used where appropriate for managing compatibility-tool releases.
- Protontricks, Wine and Winetricks.
- GameMode and MangoHud.
- Gamescope, but without globally wrapping games in it; it remains an opt-in tool because NVIDIA/Wayland combinations can have game-specific regressions.
- Common controller/udev support.

No global launch options are injected into every Steam title. Performance overlays and Gamescope remain user/game selectable.

## Third-party launchers

The machine should be ready for Steam, EA App, Battle.net and other common Windows game launchers.

Lutris, Heroic and Bottles are installed/prepared using the most appropriate maintained package channel available for Ubuntu 26.04, with APT preferred where the package is current and suitable. Flatpak is acceptable when it is the upstream-supported or operationally superior distribution route.

The installer does not embed brittle EA App or Battle.net installer URLs. Those launchers are installed later through maintained Lutris/Bottles recipes/runners so upstream installer changes do not break the base setup script.

## Vibeshine

Vibeshine is isolated in its own module. At installation time the module resolves the **latest stable** upstream release, excluding prereleases, and selects an appropriate Linux artifact for the host architecture. It validates that an expected artifact was found before installing anything.

The version is not permanently hard-coded. A re-run can therefore update Vibeshine to a newer stable release while preserving user configuration where supported.

The module also prepares the Linux permissions/capabilities required for capture and hardware encoding and diagnostics verify that the RTX 4080/NVENC path is usable.

## Virtual display and OLED protection

Linux Vibeshine does not provide the Windows native virtual-display driver. Virtual-display support is therefore an explicit experimental GNOME/Wayland module, not a hidden prerequisite of streaming.

The preferred design is dynamic: the stream hooks consume Sunshine/Vibeshine client variables such as client width, height and FPS rather than assuming one fixed client resolution. The primary expected client is a MacBook display around 3024×1964 at up to 120 Hz, while the local Alienware remains 3440×1440 at up to 240 Hz.

`stream-start.sh` is responsible for capturing the current physical display state, preparing/selecting the streaming output, applying the requested SDR mode and disabling the physical OLED only after a viable streaming output exists. `stream-stop.sh` restores the captured local display state, including the Alienware mode, and removes transient streaming state.

The physical display must never be disabled first and then followed by best-effort virtual-display creation. Failure to establish the streaming output leaves the local monitor enabled.

Because Mutter/GNOME virtual-output facilities are less mature than KWin's ecosystem, the exact backend is encapsulated behind these scripts. It may use a supported Mutter/DisplayConfig mechanism or a proven helper compatible with Ubuntu 26.04; changing that backend must not affect the gaming core or Vibeshine installation.

HDR is deliberately unsupported. The target is reliable SDR, high refresh rate where the backend permits it, headless-like remote operation, and OLED protection.

## State and failure recovery

Transient stream state is stored in a runtime/user-state location rather than in repository files. Start/stop hooks are defensive and idempotent.

If a stream-start operation fails, it rolls back changes it already made. If a previous session terminated uncleanly, a later stop/recovery operation can restore the physical display without requiring the virtual output to still exist.

Installer failures identify the failing module and leave already completed independent modules intact.

## Diagnostics

`scripts/diagnostics.sh` provides a human-readable pass/warn/fail report. Checks include:

- Ubuntu release and architecture.
- GNOME/Wayland target.
- Secure Boot state.
- NVIDIA kernel driver and GPU detection.
- Vulkan 64-bit and 32-bit readiness.
- Steam and compatibility tooling.
- GameMode.
- MangoHud/Gamescope availability.
- Wine/launcher tooling.
- Vibeshine installation/service state when installed.
- NVIDIA hardware-encoding/NVENC prerequisites.
- Virtual-display backend readiness when that optional module is enabled.

A missing optional component is a warning; a broken mandatory gaming-core component is a failure.

## Testing strategy

Shell behavior is tested without modifying the developer host. Tests exercise detection, argument parsing, package-selection logic, stable-release filtering, architecture/artifact selection, idempotent configuration helpers and stream state transitions using command stubs/fixtures.

Static shell validation (`bash -n`, and ShellCheck where available) covers every script. Integration verification on the real Ubuntu machine is exposed through diagnostics rather than making CI pretend it has an RTX 4080, Secure Boot, GNOME compositor or NVENC device.

The virtual-display module has explicit dry-run/diagnostic behavior so its command sequence can be inspected before allowing it to disable a real monitor.

## Non-goals

This project is not a general-purpose Ubuntu gaming distribution, multi-distro installer, KDE setup, HDR stack, NVIDIA driver manager, kernel-tuning framework, or automatic per-game optimizer. It targets this single Ubuntu 26.04 GNOME/Wayland RTX 4080 workstation and favors maintainability over accumulating tweaks.

## Success criteria

After a clean Ubuntu 26.04 installation, the gaming-core installer can be run repeatedly without damage; the NVIDIA/Vulkan stack and common gaming tools pass diagnostics; Steam/Proton and common launcher workflows are ready; and no unsupported system-wide performance tweaks are required.

Streaming can be installed independently. Vibeshine uses the current stable upstream release. When the optional virtual-display backend is available, a remote session can establish an SDR streaming display using client dimensions/refresh, turn off the Alienware OLED for the session, and reliably restore the local 3440×1440 high-refresh desktop afterward.