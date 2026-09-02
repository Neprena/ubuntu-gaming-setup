# Ubuntu Gaming Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a rerunnable Ubuntu 26.04 GNOME/Wayland installer for an RTX 4080 gaming workstation, with a separately gated Vibeshine streaming extension and experimental virtual-display automation.

**Architecture:** `setup.sh` is a thin orchestrator over focused Bash modules. Shared command, privilege, package, logging, and detection helpers live in `lib/common.sh`; each module owns one subsystem and is independently rerunnable. Streaming is deliberately split from the gaming core: Vibeshine installation is stable-release driven, while GNOME virtual-display handling is experimental and accessed only through a backend interface used by safe start/restore scripts.

**Tech Stack:** Bash 5, Ubuntu APT/dpkg, Flatpak where justified, ubuntu-drivers, systemd user services where applicable, Bats, ShellCheck, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-02-ubuntu-gaming-setup-design.md`

## Global Constraints

- Target Ubuntu 26.04 LTS on x86_64.
- GNOME with Wayland only; do not design an Xorg fallback.
- Primary GPU is NVIDIA RTX 4080.
- Secure Boot remains enabled.
- Install NVIDIA through Ubuntu-supported `ubuntu-drivers`; never use NVIDIA `.run` installers and never pin a driver branch.
- Prefer Ubuntu APT/native packages; use Flatpak only where it is the maintained or materially safer delivery path.
- Do not add random PPAs, custom kernels, scheduler/sysctl/swappiness gaming tweaks, or Mesa PPAs.
- Steam must use the native Ubuntu APT/deb path, not Snap.
- HDR is out of scope.
- EA App and Battle.net support is prepared through maintained launcher tooling; do not hard-code brittle vendor installer URLs.
- Vibeshine resolves the latest stable upstream release at execution time and rejects drafts/prereleases.
- Virtual-display automation is experimental, opt-in, and must never disable the physical OLED until a viable streaming output has been established.
- The physical Alienware restore target is 3440x1440 at 240 Hz; streaming dimensions and refresh come from Sunshine/Vibeshine client variables when available.
- Installer modules are rerunnable and use `sudo` only around privileged operations; desktop-user configuration runs as the invoking user.

## File Structure

- `setup.sh`: CLI, preflight invocation, module selection and execution order.
- `config/defaults.conf`: non-secret defaults and experimental feature flags.
- `lib/common.sh`: logging, command checks, invoking-user handling, APT/dpkg helpers, download helpers and shared detection.
- `modules/system.sh`: Ubuntu repositories, i386 architecture and baseline packages.
- `modules/nvidia.sh`: Ubuntu-managed NVIDIA installation and Secure Boot boundary reporting.
- `modules/gaming-stack.sh`: Vulkan, GameMode, MangoHud and optional Gamescope.
- `modules/steam.sh`: native Steam installation.
- `modules/proton.sh`: Protontricks and maintained GE-Proton management tooling.
- `modules/launchers.sh`: Wine/Winetricks, Lutris, Heroic and Bottles.
- `modules/controllers.sh`: controller/udev support.
- `modules/vibeshine.sh`: stable-release discovery, Linux asset selection and installation.
- `modules/virtual-display.sh`: feature gate and backend dispatch only.
- `lib/display/gnome.sh`: GNOME/Mutter display backend isolated from orchestration.
- `scripts/diagnostics.sh`: pass/warn/fail workstation diagnostics.
- `scripts/stream-start.sh`: transactional stream display setup; physical OLED disabled last.
- `scripts/stream-stop.sh`: state restoration and recovery.
- `tests/test_helper.bash`: fixtures, temporary command stubs and assertions.
- `tests/*.bats`: behavior tests for helpers, preflight, modules, release selection and streaming transactions.
- `.github/workflows/ci.yml`: non-destructive Bats, syntax and ShellCheck CI.
- `README.md`: supported environment, install/use instructions, Secure Boot/MOK notes and experimental streaming caveats.

---

### Task 1: Test Harness, Common Helpers, and CLI Skeleton

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `tests/test_helper.bash`
- Create: `tests/common.bats`
- Create: `tests/setup.bats`
- Create: `lib/common.sh`
- Create: `config/defaults.conf`
- Create: `setup.sh`

**Interfaces:**
- Produces: `log_info`, `log_warn`, `log_error`, `die`, `command_exists`, `is_dry_run`, `run_privileged`, `apt_install`, `invoking_user`, `load_defaults`; `setup.sh --dry-run [--modules csv]`.

- [ ] **Step 1: Add CI and failing Bats tests** proving dry-run command rendering, invoking-user resolution, defaults loading, unknown CLI option rejection, and module-list parsing. CI installs `bats` and `shellcheck`, runs `bash -n` over all shell files, then ShellCheck and Bats. Tests must stub `sudo`/APT rather than mutate the runner.
- [ ] **Step 2: Verify RED** by observing the GitHub Actions run fail because `lib/common.sh` and `setup.sh` do not exist.
- [ ] **Step 3: Implement minimal helpers and CLI** with `set -Eeuo pipefail`, repo-root-relative sourcing, explicit dry-run, and no root-only execution requirement.
- [ ] **Step 4: Verify GREEN** in GitHub Actions; syntax, ShellCheck and Bats all pass.
- [ ] **Step 5: Commit** as `feat: add installer foundation and test harness`.

### Task 2: Ubuntu/GNOME/Wayland Preflight and System Foundation

**Files:**
- Create: `tests/preflight.bats`
- Create: `tests/system.bats`
- Modify: `lib/common.sh`
- Create: `modules/system.sh`
- Modify: `setup.sh`

**Interfaces:**
- Produces: `detect_ubuntu_version`, `detect_arch`, `detect_desktop`, `detect_session_type`, `secure_boot_state`, `preflight_check`, `enable_i386`, `install_system_foundation`.

- [ ] **Step 1: Write failing tests** for Ubuntu `26.04`, `x86_64`, GNOME detection, Wayland success, TTY/non-Wayland warning behavior, unsupported release failure, and idempotent `dpkg --add-architecture i386`.
- [ ] **Step 2: Verify RED** in CI for missing detection/system functions.
- [ ] **Step 3: Implement minimal preflight and system module.** Read `/etc/os-release`; use `dpkg --print-architecture`/`--print-foreign-architectures`; detect GNOME from environment/installed session; treat an active non-Wayland graphical session as failure and a TTY invocation with GNOME installed as warning; report Secure Boot with `mokutil` without attempting MOK enrollment.
- [ ] **Step 4: Verify GREEN** and rerun the full suite.
- [ ] **Step 5: Commit** as `feat: add Ubuntu 26.04 preflight and system setup`.

### Task 3: NVIDIA and Core Gaming Stack

**Files:**
- Create: `tests/nvidia.bats`
- Create: `tests/gaming-stack.bats`
- Create: `modules/nvidia.sh`
- Create: `modules/gaming-stack.sh`
- Modify: `setup.sh`

**Interfaces:**
- Produces: `install_nvidia_driver`, `install_gaming_stack`; consumes `apt_install`, `run_privileged`, `is_dry_run`.

- [ ] **Step 1: Write failing tests** proving NVIDIA installation invokes `ubuntu-drivers install` rather than a pinned package, never invokes a `.run` installer, and gaming-stack installation includes 64/32-bit Vulkan runtime support plus GameMode/MangoHud with Gamescope independently toggleable.
- [ ] **Step 2: Verify RED** for missing modules.
- [ ] **Step 3: Implement minimal modules** using Ubuntu repositories and the exact Ubuntu 26.04 package names verified immediately before implementation. Secure Boot enrollment remains an explicit reboot/user interaction boundary.
- [ ] **Step 4: Verify GREEN** with all commands stubbed in CI.
- [ ] **Step 5: Commit** as `feat: install Ubuntu NVIDIA and gaming stack`.

### Task 4: Steam, Proton, Launchers, and Controllers

**Files:**
- Create: `tests/steam.bats`
- Create: `tests/proton.bats`
- Create: `tests/launchers.bats`
- Create: `tests/controllers.bats`
- Create: `modules/steam.sh`
- Create: `modules/proton.sh`
- Create: `modules/launchers.sh`
- Create: `modules/controllers.sh`
- Modify: `setup.sh`

**Interfaces:**
- Produces: `install_steam`, `install_proton_tools`, `install_launchers`, `install_controller_support`.

- [ ] **Step 1: Write failing tests** proving Steam uses Ubuntu APT/deb and not Snap, GE-Proton management uses a maintained ProtonUp-Qt path, launcher setup never downloads EA/Battle.net executables directly, and controller support installs the current Ubuntu udev/device package.
- [ ] **Step 2: Verify RED** in CI.
- [ ] **Step 3: Implement minimal modules** after verifying current Ubuntu 26.04 package names and maintained Flatpak application IDs. Use Flatpak only for applications whose Ubuntu-native delivery is absent or materially stale; keep Wine/Winetricks on supported Ubuntu packages unless current compatibility evidence requires otherwise.
- [ ] **Step 4: Verify GREEN** and full-suite regression.
- [ ] **Step 5: Commit** as `feat: add Steam Proton launchers and controllers`.

### Task 5: Diagnostics

**Files:**
- Create: `tests/diagnostics.bats`
- Create: `scripts/diagnostics.sh`

**Interfaces:**
- Produces: executable diagnostic command with `PASS`, `WARN`, `FAIL` records and nonzero exit only for blocking failures.

- [ ] **Step 1: Write failing tests** for release, Wayland, Secure Boot, NVIDIA (`nvidia-smi`), Vulkan 64-bit, 32-bit Vulkan readiness, Steam, GameMode, MangoHud, Gamescope, Wine, launchers, Vibeshine, NVENC and virtual-display readiness. Tests distinguish package presence from actual runtime validation.
- [ ] **Step 2: Verify RED** for missing diagnostics script.
- [ ] **Step 3: Implement diagnostics** with machine-readable prefixes and human-readable explanations. Use `vulkaninfo --summary` for native Vulkan and clearly label 32-bit loader/package validation as readiness unless a functional 32-bit probe is available; use `ffmpeg -encoders` plus NVIDIA state for NVENC readiness.
- [ ] **Step 4: Verify GREEN** under fixtures for healthy, warning and failure states.
- [ ] **Step 5: Commit** as `feat: add gaming workstation diagnostics`.

### Task 6: Vibeshine Stable-Release Installer

**Files:**
- Create: `tests/vibeshine.bats`
- Create: `modules/vibeshine.sh`
- Modify: `config/defaults.conf`
- Modify: `setup.sh`

**Interfaces:**
- Produces: `resolve_vibeshine_release`, `select_vibeshine_asset`, `install_vibeshine`; consumes a JSON release document through an injectable fetch helper so tests remain offline.

- [ ] **Step 1: Write failing tests** with release fixtures containing stable, draft and prerelease entries and mixed architectures. Assert that only the newest non-draft/non-prerelease release is selected and that x86_64/amd64 Linux package selection rejects ambiguous or unsupported assets.
- [ ] **Step 2: Verify RED** for missing resolver.
- [ ] **Step 3: Implement stable resolution and installation** against `Nonary/vibeshine` GitHub releases, preferring an upstream Linux package format appropriate to Ubuntu. Preserve existing user configuration; validate a published checksum when upstream supplies one, otherwise state that transport integrity is HTTPS-only rather than inventing verification.
- [ ] **Step 4: Verify GREEN** with offline fixtures plus shell checks.
- [ ] **Step 5: Commit** as `feat: add stable Vibeshine installer`.

### Task 7: Experimental GNOME Virtual-Display Backend

**Files:**
- Create: `tests/virtual-display.bats`
- Create: `tests/fixtures/display/`
- Create: `modules/virtual-display.sh`
- Create: `lib/display/gnome.sh`
- Modify: `config/defaults.conf`
- Modify: `setup.sh`

**Interfaces:**
- Produces: `display_backend_available`, `display_capture_state`, `display_prepare_stream WIDTH HEIGHT FPS STATE_FILE`, `display_disable_physical STATE_FILE`, `display_restore STATE_FILE`.

- [ ] **Step 1: Re-verify GNOME 50/Mutter tooling** immediately before coding: current `gdctl`/DisplayConfig capabilities, Ubuntu 26.04 behavior, and the current `starlight-display` approach. Record the chosen backend and its limitations in comments/docs; do not claim software virtual-output creation if the API cannot actually provide it.
- [ ] **Step 2: Write failing tests** for feature gating, client-mode validation, state capture, backend-unavailable refusal, physical-display disable ordering, and restore command generation. All display mutation is stubbed; provide `--dry-run` behavior.
- [ ] **Step 3: Verify RED** for missing backend.
- [ ] **Step 4: Implement the smallest verified GNOME backend.** If GNOME still lacks a reliable software virtual-output API, implement the verified existing/dummy-output path and return a clear unsupported status when no streaming connector exists rather than using an unsafe DRM hack.
- [ ] **Step 5: Verify GREEN** and ensure the module is disabled by default.
- [ ] **Step 6: Commit** as `feat: add experimental GNOME streaming display backend`.

### Task 8: Transactional Stream Start/Stop

**Files:**
- Create: `tests/stream.bats`
- Create: `scripts/stream-start.sh`
- Create: `scripts/stream-stop.sh`

**Interfaces:**
- Consumes: `SUNSHINE_CLIENT_WIDTH`, `SUNSHINE_CLIENT_HEIGHT`, `SUNSHINE_CLIENT_FPS`; calls the Task 7 display interface.
- Produces: safe stream lifecycle scripts and a per-user state file under `${XDG_STATE_HOME:-$HOME/.local/state}/ubuntu-gaming-setup/`.

- [ ] **Step 1: Write failing tests** proving defaults/validation for client variables, state is captured before mutation, streaming output is prepared before the OLED is disabled, any preparation failure leaves the physical display enabled, and stop/EXIT recovery restores 3440x1440@240 when captured state cannot be reused.
- [ ] **Step 2: Verify RED** in CI.
- [ ] **Step 3: Implement transactional scripts** with lock/state handling and traps. `stream-start.sh` must abort before disabling the Alienware if backend readiness cannot be confirmed. `stream-stop.sh` must be safe when invoked repeatedly.
- [ ] **Step 4: Verify GREEN** including injected failures between each transition.
- [ ] **Step 5: Commit** as `feat: add safe streaming display lifecycle`.

### Task 9: Documentation and Integration Verification

**Files:**
- Create: `README.md`
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/diagnostics.sh` if integration checks reveal a tested defect.

**Interfaces:**
- Produces: documented clean-install procedure and reproducible verification commands.

- [ ] **Step 1: Write documentation acceptance assertions** in a Bats test that checks README contains Ubuntu 26.04, GNOME/Wayland, Secure Boot/MOK, RTX/NVIDIA, Steam APT, Vibeshine, experimental virtual display, dry-run, diagnostics, and rollback/restore instructions.
- [ ] **Step 2: Verify RED** because README does not yet exist.
- [ ] **Step 3: Write README** with `git clone`, `./setup.sh --dry-run`, normal core installation, optional streaming installation, post-reboot NVIDIA checks, diagnostics, Moonlight/Vibeshine preparation command integration, and explicit dummy-output fallback caveat if required by Task 7 research.
- [ ] **Step 4: Run final CI verification**: `bash -n`, ShellCheck and every Bats test. Inspect the feature-branch diff against `main`; verify no Snap Steam, NVIDIA `.run`, pinned NVIDIA branch, HDR setup, random PPA, or destructive CI command slipped in.
- [ ] **Step 5: Commit** as `docs: add installation and recovery guide`.
- [ ] **Step 6: Open a pull request** from `feature/ubuntu-gaming-setup` to `main`; do not merge without explicit user approval.

## Self-Review

Spec coverage maps to Tasks 1-9: modular rerunnable installer and privilege boundary (1-4), Ubuntu/GNOME/Wayland/Secure Boot (2), Ubuntu-managed NVIDIA and gaming stack (3), Steam/Proton/launchers/controllers (4), pass/warn/fail diagnostics (5), latest stable Vibeshine (6), explicitly experimental GNOME backend (7), client-variable-driven OLED-safe lifecycle and restoration (8), documentation and end-to-end CI (9). HDR and unsupported tuning remain excluded globally. No implementation placeholder is permitted: where external package/API state is time-sensitive, the plan explicitly requires verification immediately before the corresponding implementation and defines the safe fallback behavior.